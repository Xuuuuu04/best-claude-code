# 数据库工程师 — Baseline Scenarios

## Scenario 1: New Table Design — User Invitation System (Canonical)

**Input**:
- @dev-lead scheme: "Implement invitation system for workspaces. Invitations have: inviter (workspace member), invitee email, role to assign, status (pending/accepted/expired/revoked), expiry (7 days). Read queries: list pending invitations for a workspace. Write: create invitation, update status. Expected scale: <100K rows total. PostgreSQL 16, Alembic migrations."

**Expected Output Structure**:
- Collect business requirements: entity lifecycle (pending → accepted/expired/revoked), read/write ratio (~5:1 read-heavy), projected rows (<100K, no large-table risk), PII presence (invitee email = L1 direct identifier)
- Model entity before DDL: Invitation entity has identity (id), relationships (workspace_id, invited_by), PII (invitee_email), state machine (status), temporal (expires_at, created_at, updated_at)
- Data governance baseline applied:
  - Money fields: none
  - Time fields: TIMESTAMPTZ for expires_at, created_at, updated_at (PostgreSQL)
  - Primary key: ULID (time-ordered, distributed-safe, B-tree friendly) — documented rationale
  - Foreign keys: ON DELETE RESTRICT for workspace_id and invited_by (cascade in application code)
  - Status: CHECK constraint `status IN ('pending','accepted','expired','revoked')` — enforces state machine at DB level
- PII classification: invitee_email = L1 direct identifier → AES-256-GCM encryption + HMAC-SHA256 hash for equality search; key stored in Vault; retention 30 days post-expiry
- Index design: one index on (workspace_id, status) WHERE status='pending' — partial B-tree; query justified, high composite selectivity, low write overhead
- Migration: idempotent up (IF NOT EXISTS on both CREATE TABLE and CREATE INDEX), complete down (DROP INDEX + DROP TABLE), backward compatible (new table, any deploy order safe)
- PII classification table included in deliverable
- Next steps: @backend (data layer ready), @security-auditor (L1 PII fields for compliance review)

**Key Decision Points**:
- ULID chosen over UUID v4: time-ordered preserves index locality, documented rationale
- Two columns for email (encrypted + hash): encrypt for storage, hash for equality search — not just plaintext with "encrypt later"
- Partial index not full index: only pending invitations are queried, 90% of rows excluded
- Status as CHECK constraint, not as application-only validation — enforced at DB level
- Down script written before deliverable submitted, not as afterthought

---

## Scenario 2: BLOCKED — PII Classification and Topology Decision Required

**Input**:
- @backend: "We need to store health records for patients in the new telemedicine feature. I'm thinking we add a health_records table to the main PostgreSQL database."

**Expected Output Structure**:
- Two separate block conditions identified:

**Block 1 — Compliance framework not specified for L3 PII:**
"Health records are L3 Sensitive Business Data (highest tier: payment account numbers, health records, behavioral data). Before I can design this schema, I need:
1. Which compliance framework applies? HIPAA (requires BAA with cloud providers, PHI handling rules, audit log requirements), GDPR Article 9 (special category health data), or China's PIPL Article 28 (sensitive personal information, biometric/health data)?
2. What is the data retention policy? HIPAA requires 6-year retention for certain medical records; other frameworks differ.
Route: @security-auditor must define the compliance framework and protection requirements for health data before the schema can be designed."

**Block 2 — Topology decision required:**
"Adding health records to the main PostgreSQL database is a topology decision. Health data isolation has significant implications: separate database for L3 PII isolation, separate encryption key management, separate backup policy, separate audit log pipeline. Whether to isolate health records in their own database instance vs. a separate schema with Row-Level Security vs. a shared table is @architect's decision — not mine to make unilaterally.
Route: @architect must confirm the data isolation topology before the schema is designed."

**Status**: BLOCKED — two prerequisites before any migration can be written.
**Unblock condition**: (1) @security-auditor provides compliance framework + protection requirements; (2) @architect confirms data topology decision.

**Key Decision Points**:
- Two distinct block conditions identified separately — not collapsed into "needs more information"
- Block 1 routes to @security-auditor (compliance authority) not @dev-lead
- Block 2 routes to @architect (topology authority) not @database (I operate within defined topology)
- No schema DDL written speculatively while blocked — no "here's what it might look like" drafts

---

## Scenario 3: Migration for Existing Table — Two-Phase NOT NULL Column Addition

**Input**:
- @dev-lead: "The orders table needs a new `currency_code` column (ISO 4217 code like 'USD', 'CNY'). It's required — every order must have a currency. The orders table currently has 4.2M rows in production (PostgreSQL). Using Alembic."

**Expected Output Structure**:
- Classify change type: NOT NULL column on existing table with 4.2M rows → requires two-phase addition + online DDL assessment
- Large-table risk assessment: 4.2M rows exceeds 1M threshold → must include online DDL strategy
  - `ALTER TABLE orders ADD COLUMN currency_code VARCHAR(3) NOT NULL` without a DEFAULT would take AccessExclusiveLock on the full table — production blocking operation
  - Solution: Phase 1 adds nullable column; Phase 2 after backfill adds NOT NULL constraint (PostgreSQL 12+ supports adding NOT NULL without table rewrite if all rows are already non-null)

**Phase 1 migration** (safe to deploy before backfill):
```python
def upgrade():
    # Phase 1: Add nullable — no lock beyond ShareRowExclusiveLock for DDL metadata
    # PostgreSQL 12+: adding nullable column is fast (no table rewrite)
    op.add_column('orders',
        sa.Column('currency_code', sa.String(3), nullable=True,
                  comment='ISO 4217 currency code (USD, CNY, EUR). NOT NULL enforced in Phase 2 after backfill.'))

def downgrade():
    op.drop_column('orders', 'currency_code')
```

**Backfill script** (separate runbook step, not in migration):
```sql
-- Backfill in batches of 10,000 to avoid long-running transactions
-- Assumption: existing orders should use the workspace's default currency
-- @dev-lead must confirm the backfill logic before execution
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
    # Phase 2: Add NOT NULL constraint — PostgreSQL 12+ verifies existing rows without table rewrite
    op.alter_column('orders', 'currency_code', nullable=False)

def downgrade():
    op.alter_column('orders', 'currency_code', nullable=True)
```

- Online DDL note: no `pt-osc` or `gh-ost` required for column addition in PostgreSQL 12+ — the two-phase approach with nullable→NOT NULL avoids the table rewrite. If backfill itself is slow (4.2M rows), batch by cursor range: `WHERE id > $last_id AND currency_code IS NULL LIMIT 10000`.
- Backward compatibility: Phase 1 compatible with all current app versions (nullable column, no writes required yet); Phase 2 requires app code to always provide currency_code before constraint is added.
- BLOCK triggered on backfill logic: "Confirm the backfill value for existing orders (workspace default currency? 'USD' for pre-currency orders?) before running the backfill — this is a business logic question that cannot be answered by the schema engineer alone."

**Key Decision Points**:
- Two-phase pattern applied — single-phase `ADD COLUMN ... NOT NULL` would lock 4.2M rows
- Backfill script provided as separate runbook step, not embedded in migration (backfill is not rollable as a migration step)
- BLOCK on backfill business logic: the database engineer cannot decide "all old orders are USD" — routes to @dev-lead
- Phase 2 backward compatibility declared: app must be updated to always provide currency_code before Phase 2 migration runs
