# 数据库工程师 — Baseline Scenarios

## Scenario 1: New Table Design — User Invitation System (Canonical)

**Input**:
- @dev-lead scheme: "Implement invitation system for workspaces. Invitations have: inviter (workspace member), invitee email, role to assign, status (pending/accepted/expired/revoked), expiry (7 days). Read queries: list pending invitations for a workspace. Write: create invitation, update status. Expected scale: <100K rows total. PostgreSQL 16, Alembic migrations."

**Expected Output Structure**:
- Collect business requirements: entity lifecycle (pending → accepted/expired/revoked), read/write ratio (~5:1 read-heavy), projected rows (<100K, no large-table risk), PII presence (invitee email = L1 direct identifier)
- Model entity before DDL: Invitation entity has identity (id), relationships (workspace_id, invited_by), PII (invitee_email), state machine (status), temporal (expires_at, created_at, updated_at)
- Data governance baseline applied:
  - Money fields: none
  - Time fields: TIMESTAMPTZ for expires_at, created_at, updated_at
  - Primary key: ULID (time-ordered, distributed-safe, B-tree friendly) — documented rationale
  - Foreign keys: ON DELETE RESTRICT for workspace_id and invited_by
  - Status: CHECK constraint `status IN ('pending','accepted','expired','revoked')`
- PII classification: invitee_email = L1 direct identifier → AES-256-GCM encryption + HMAC-SHA256 hash for equality search; key stored in Vault; retention 30 days post-expiry
- Index design: one index on (workspace_id, status) WHERE status='pending' — partial B-tree; query justified, high composite selectivity, low write overhead
- Migration: idempotent up (IF NOT EXISTS on both CREATE TABLE and CREATE INDEX), complete down (DROP INDEX + DROP TABLE), backward compatible (new table, any deploy order safe)
- PII classification table included in deliverable
- Next steps: @backend (data layer ready), @security-auditor (L1 PII fields for compliance review)

**Key Decision Points**:
- ULID chosen over UUID v4: time-ordered preserves index locality, documented rationale
- Two columns for email (encrypted + hash): encrypt for storage, hash for equality search
- Partial index not full index: only pending invitations are queried, 90% of rows excluded
- Status as CHECK constraint, not application-only validation — enforced at DB level
- Down script written before deliverable submitted, not as afterthought

---

## Scenario 2: BLOCKED — PII Classification and Topology Decision Required

**Input**:
- @backend: "We need to store health records for patients in the new telemedicine feature. I'm thinking we add a health_records table to the main PostgreSQL database."

**Expected Output Structure**:

**Block 1 — Compliance framework not specified for L3 PII:**
"Health records are L3 Sensitive Business Data (highest tier). Before I can design this schema, I need:
1. Which compliance framework applies? HIPAA (requires BAA with cloud providers, PHI handling rules), GDPR Article 9 (special category health data), or PIPL Article 28 (sensitive personal information)?
2. What is the data retention policy? HIPAA requires 6-year retention for certain medical records.
Route: @security-auditor must define compliance framework and protection requirements before schema design."

**Block 2 — Topology decision required:**
"Adding health records to the main PostgreSQL database is a topology decision. Health data isolation has significant implications: separate database for L3 PII isolation, separate encryption key management, separate backup policy, separate audit log pipeline. Whether to isolate health records in their own database instance vs. a separate schema with Row-Level Security vs. a shared table is @architect's decision.
Route: @architect must confirm data isolation topology before schema design."

**Status**: BLOCKED — two prerequisites before any migration can be written.
**Unblock conditions**: (1) @security-auditor provides compliance framework; (2) @architect confirms data topology.

**Key Decision Points**:
- Two distinct block conditions identified separately
- Block 1 routes to @security-auditor (compliance authority)
- Block 2 routes to @architect (topology authority)
- No schema DDL written speculatively while blocked

---

## Scenario 3: Migration for Existing Table — Two-Phase NOT NULL Column Addition

**Input**:
- @dev-lead: "The orders table needs a new `currency_code` column (ISO 4217 code like 'USD', 'CNY'). It's required — every order must have a currency. The orders table currently has 4.2M rows in production (PostgreSQL). Using Alembic."

**Expected Output Structure**:
- Classify change type: NOT NULL column on existing table with 4.2M rows → requires two-phase addition + online DDL assessment
- Large-table risk assessment: 4.2M rows exceeds 1M threshold → must include online DDL strategy
  - `ALTER TABLE orders ADD COLUMN currency_code VARCHAR(3) NOT NULL` without DEFAULT would take AccessExclusiveLock on full table
  - Solution: Phase 1 adds nullable column; Phase 2 after backfill adds NOT NULL constraint

**Phase 1 migration** (safe to deploy before backfill):
```python
def upgrade():
    op.add_column('orders',
        sa.Column('currency_code', sa.String(3), nullable=True,
                  comment='ISO 4217 currency code (USD, CNY, EUR). NOT NULL enforced in Phase 2 after backfill.'))

def downgrade():
    op.drop_column('orders', 'currency_code')
```

**Backfill script** (separate runbook step, not in migration):
```sql
-- Backfill in batches of 10,000 to avoid long-running transactions
UPDATE orders
SET currency_code = workspaces.default_currency
FROM workspaces
WHERE orders.workspace_id = workspaces.id
  AND orders.currency_code IS NULL
LIMIT 10000;
-- Repeat until 0 rows updated
```

**Phase 2 migration** (deploy after backfill completes + verified 0 NULL rows):
```python
def upgrade():
    op.alter_column('orders', 'currency_code', nullable=False)

def downgrade():
    op.alter_column('orders', 'currency_code', nullable=True)
```

- Online DDL note: no pt-osc or gh-ost required for column addition in PostgreSQL 12+ — two-phase approach avoids table rewrite
- Backward compatibility: Phase 1 compatible with all current app versions; Phase 2 requires app code to always provide currency_code
- BLOCK triggered on backfill logic: "Confirm backfill value for existing orders before running"

**Key Decision Points**:
- Two-phase pattern applied — single-phase would lock 4.2M rows
- Backfill script provided as separate runbook step, not embedded in migration
- BLOCK on backfill business logic: database engineer cannot decide "all old orders are USD"
- Phase 2 backward compatibility declared: app must be updated before Phase 2 runs

---

## Scenario 4: Partition Strategy for Time-Series Data

**Input**:
- @dev-lead: "We need to store IoT sensor readings — 1M rows/day, query pattern is always time-range based. PostgreSQL 16."

**Expected Output Structure**:
- Evaluate partitioning options: range (by day/month), hash (by sensor_id), list (by region)
- Select range partitioning by `recorded_at` — matches query pattern perfectly
- Design:
```sql
CREATE TABLE sensor_readings (
    id BIGSERIAL,
    sensor_id UUID NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    temperature DECIMAL(5, 2),
    humidity DECIMAL(5, 2),
    metadata JSONB
) PARTITION BY RANGE (recorded_at);

-- Monthly partitions
CREATE TABLE sensor_readings_2026_04 PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE sensor_readings_2026_05 PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

-- Indexes on each partition
CREATE INDEX idx_sensor_readings_time ON sensor_readings (recorded_at DESC);
CREATE INDEX idx_sensor_readings_sensor_time ON sensor_readings (sensor_id, recorded_at DESC);
```

- Partition pruning verification:
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM sensor_readings
WHERE recorded_at >= '2026-04-15' AND recorded_at < '2026-04-16';
-- Expected: "Partition Ref: sensor_readings_2026_04" only
```

- Maintenance strategy: pg_partman for automatic partition creation, 3-month retention with DETACH + DROP
- Index rationale: time index for range queries, composite for sensor-specific time queries
- Large-table assessment: 30M rows/month → partitions keep individual tables < 1M rows, no online DDL needed for partition operations
- Status: READY-FOR-NEXT

**Key Decision Points**:
- Range partitioning chosen over hash — query pattern is time-range, not sensor-ID lookup
- Monthly granularity — 1M rows/day = 30M rows/month, manageable partition size
- pg_partman for automation — manual partition creation is error-prone at scale
- DETACH + DROP for retention — faster than DELETE, no vacuum bloat
