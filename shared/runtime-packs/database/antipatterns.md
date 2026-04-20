# 数据库工程师 — Anti-Patterns Reference

## Named Anti-Patterns

---

### Anti-Pattern 1: Down-less Migration (CRITICAL)

**Definition**: A migration script that contains an `up` function but no `down` function, or a `down` function that raises `NotImplementedError`.

**Manifestations**:
```python
# BAD — FORBIDDEN: no down script
from alembic import op
import sqlalchemy as sa

def upgrade():
    op.add_column('users', sa.Column('phone', sa.String(20), nullable=False))

def downgrade():
    pass  # FORBIDDEN
```

```sql
-- BAD — FORBIDDEN: no rollback
-- V20240421__add_phone_column.sql (Flyway)
ALTER TABLE users ADD COLUMN phone VARCHAR(20) NOT NULL;
-- No corresponding undo file
```

**Why it's dangerous**: Every production deployment is a bet that the migration will work correctly. When that bet is wrong — performance regression, data corruption, application incompatibility — the only recovery without a down script is a database restore, which is slower, riskier, and more disruptive than rolling back a clean migration.

**Correction**: Write the down script before submitting the migration for review.

```python
# GOOD — complete down script
def upgrade():
    op.add_column('users', sa.Column('phone_e164', sa.String(20), nullable=True,
                  comment='L1 PII: stored AES-256 encrypted, see vault path: secret/users/phone-key'))

def downgrade():
    op.drop_column('users', 'phone_e164')
```

```sql
-- GOOD — Flyway with undo
-- V20240421__add_phone_column.sql
ALTER TABLE users ADD COLUMN phone_e164 VARCHAR(20) NULL;

-- U20240421__add_phone_column.sql (undo)
ALTER TABLE users DROP COLUMN phone_e164;
```

---

### Anti-Pattern 2: Float for Money (CRITICAL)

**Definition**: Using FLOAT, DOUBLE, or REAL for monetary value storage.

**Manifestations**:
```sql
-- BAD — FORBIDDEN: FLOAT for money
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    amount FLOAT NOT NULL,  -- 0.1 + 0.2 = 0.30000000000000004
    tax FLOAT NOT NULL
);
```

```python
# BAD — FORBIDDEN: Python float for calculation
total = order.amount + order.tax  # Precision loss
```

**Why it's wrong**: IEEE 754 floating-point arithmetic cannot represent most decimal fractions exactly. `0.1 + 0.2 ≠ 0.3` in floating-point. Financial calculations that accumulate floating-point error produce cent-off totals, failed payment reconciliation, and incorrect financial statements.

**Correction**: Use exact decimal arithmetic.

```sql
-- GOOD — DECIMAL for exact arithmetic
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    amount DECIMAL(10, 2) NOT NULL,  -- Exact decimal, 2 decimal places
    tax DECIMAL(10, 2) NOT NULL,
    total DECIMAL(10, 2) GENERATED ALWAYS AS (amount + tax) STORED,
    CONSTRAINT orders_amount_positive CHECK (amount >= 0)
);
```

```sql
-- GOOD — BIGINT minor units (cents)
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    amount_cents BIGINT NOT NULL,  -- Value * 100, no decimal
    CONSTRAINT orders_amount_positive CHECK (amount_cents >= 0)
);
-- Display: amount_cents / 100.0 (application layer)
```

---

### Anti-Pattern 3: Index Everything (HIGH)

**Definition**: Adding an index to every column "just in case" queries against it in the future.

**Manifestations**:
```sql
-- BAD — FORBIDDEN: 10 indexes on 12-column table, none justified
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    status VARCHAR(20),
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    role VARCHAR(20),
    department VARCHAR(50),
    phone VARCHAR(20),
    country VARCHAR(2)
);

CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_name ON users (name);      -- No query uses this
CREATE INDEX idx_users_status ON users (status);  -- Low selectivity (3 values)
CREATE INDEX idx_users_created ON users (created_at);
CREATE INDEX idx_users_updated ON users (updated_at);  -- No query uses this
CREATE INDEX idx_users_login ON users (last_login_at);
CREATE INDEX idx_users_role ON users (role);      -- Low selectivity
CREATE INDEX idx_users_dept ON users (department);  -- No query uses this
CREATE INDEX idx_users_country ON users (country);  -- Low selectivity (50 values)
```

**Why it's wrong**: Every index consumes: storage space, write I/O on every INSERT/UPDATE/DELETE (the database must maintain the index), vacuum/autovacuum time (PostgreSQL), and query planner decision-making overhead. An oversaturated index set can make write-heavy workloads dramatically slower.

**Correction**: Answer the three index questions before adding any index.

```sql
-- GOOD — justified indexes only
-- Query: SELECT * FROM users WHERE email = $1 (login, password reset)
-- Selectivity: ~1.0 (unique), write overhead: LOW
CREATE UNIQUE INDEX idx_users_email ON users (email);

-- Query: SELECT * FROM users WHERE status = 'active' ORDER BY created_at DESC
-- Selectivity: status ~0.3, composite with created_at improves sort
CREATE INDEX idx_users_status_created ON users (status, created_at DESC);

-- Query: SELECT * FROM users WHERE last_login_at < NOW() - INTERVAL '1 year'
-- Selectivity: ~0.1, range query benefits from index
CREATE INDEX idx_users_last_login ON users (last_login_at);

-- Total: 3 indexes (vs 9), all with documented justification
```

---

### Anti-Pattern 4: ORM-Schema Drift (HIGH)

**Definition**: Allowing the application ORM model to diverge from the actual database schema.

**Manifestations**:
```bash
# BAD — FORBIDDEN: ORM sync in production
npx prisma db push  # Bypasses migration history!
```

```python
# BAD — FORBIDDEN: SQLAlchemy create_all in production
Base.metadata.create_all(engine)  # No migration history, no rollback
```

**Why it's wrong**: ORM sync operations are not idempotent, not versioned, and not rollable. They produce schema changes with no migration history, no down path, and no audit trail. Future migrations may generate incorrect diffs because the migration tool cannot understand the history.

**Correction**: Migrations are the single source of truth.

```bash
# GOOD — generate migration from ORM diff, then review
npx prisma migrate dev --name add_phone_column
# Review generated SQL before applying!
```

```bash
# GOOD — Alembic autogenerate with review
alembic revision --autogenerate -m "add phone column"
# Edit generated migration to add idempotency guards, comments, down script
alembic upgrade head
```

---

### Anti-Pattern 5: PII Without Tiering (CRITICAL)

**Definition**: Storing personal data fields without classification, encryption strategy, or retention policy.

**Manifestations**:
```sql
-- BAD — FORBIDDEN: plaintext PII, no classification
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255),           -- L1 PII in plaintext!
    phone VARCHAR(20),            -- L1 PII in plaintext!
    full_name VARCHAR(255),       -- L2 PII unmasked!
    id_number VARCHAR(18),        -- L1 PII in plaintext!
    health_record TEXT,           -- L3 PII unencrypted!
    created_at TIMESTAMPTZ
    -- No retention policy
    -- No audit logging
);
```

**Why it's wrong**: Unclassified PII is a compliance violation waiting to be discovered. Under GDPR, CCPA, HIPAA, and most national data protection laws, personal data must be handled according to its sensitivity level. Discovering this after launch means migrating a live production table with user data in it.

**Correction**: Every column containing personal data must be identified, classified, and protected before the migration ships.

```sql
-- GOOD — classified and protected PII
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    -- L1: direct identifier — encrypted + hashed for search
    email_encrypted BYTEA NOT NULL,     -- AES-256-GCM
    email_hash CHAR(64) NOT NULL,       -- HMAC-SHA256 for equality search
    
    -- L1: direct identifier — encrypted + hashed
    phone_encrypted BYTEA,
    phone_hash CHAR(64),
    
    -- L2: quasi-identifier — masked for display
    full_name_masked VARCHAR(255),      -- "张**三" stored, full in encrypted
    full_name_encrypted BYTEA,
    
    -- L3: sensitive business data — encrypted + audit log
    health_record_encrypted BYTEA,      -- Field-level encryption
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Retention: 30 days after account closure, then anonymize
    deleted_at TIMESTAMPTZ
);

-- Audit table for L3 access
CREATE TABLE pii_access_log (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    resource_type VARCHAR(50) NOT NULL,
    field_accessed VARCHAR(50) NOT NULL,
    accessed_by VARCHAR(100) NOT NULL,
    accessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    access_reason TEXT
);
```

---

### Anti-Pattern 6: Partition Blindness (HIGH)

**Definition**: Creating partitioned tables without partition pruning verification, maintenance strategy, or query awareness.

**Manifestations**:
```sql
-- BAD — FORBIDDEN: partitioned but queries don't prune
CREATE TABLE events (
    id BIGSERIAL,
    event_type VARCHAR(50),
    created_at TIMESTAMPTZ
) PARTITION BY RANGE (created_at);

-- Query that doesn't prune — scans ALL partitions
SELECT * FROM events WHERE EXTRACT(YEAR FROM created_at) = 2026;
-- Function on partition key prevents pruning!
```

**Why it's wrong**: Partitioning without pruning is worse than no partitioning — you pay the overhead of partition management with none of the query benefits. Queries that scan all partitions are slower than queries on a single unpartitioned table due to partition overhead.

**Correction**: Verify partition pruning and maintain partitions.

```sql
-- GOOD — query that prunes
SELECT * FROM events 
WHERE created_at >= '2026-04-01' 
  AND created_at < '2026-05-01';
-- PostgreSQL planner: "Partition Ref: events_2026_04" — only one partition scanned

-- GOOD — automatic partition maintenance
SELECT partman.create_parent('public.events', 'created_at', 'native', 'monthly');
SELECT partman.run_maintenance();  -- Create next month's partition
```

**Partition pruning verification**:
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM events 
WHERE created_at >= '2026-04-01' 
  AND created_at < '2026-04-15';

-- Expected output should show:
-- "Partition Ref: events_2026_04"
-- Not: "Partition Ref: ALL"
```

---

### Anti-Pattern 7: Two-Phase Neglect (CRITICAL)

**Definition**: Adding a NOT NULL column to an existing table with data in a single migration step, causing a full table lock.

**Manifestations**:
```python
# BAD — FORBIDDEN: single-phase NOT NULL on existing table
def upgrade():
    # This takes AccessExclusiveLock on the entire table!
    # All queries block until migration completes
    op.add_column('orders', sa.Column('currency_code', sa.String(3), nullable=False))
    # On 4.2M row table: 5-30 minutes of downtime

def downgrade():
    op.drop_column('orders', 'currency_code')
```

**Why it's wrong**: `ALTER TABLE ... ADD COLUMN ... NOT NULL` without a DEFAULT on an existing table requires rewriting the entire table to populate the new column. On PostgreSQL < 11, this takes an AccessExclusiveLock that blocks all reads and writes. On any version, it's a long-running operation that risks statement timeout failures.

**Correction**: Two-phase addition with backfill.

```python
# GOOD — Phase 1: add nullable (safe, minimal lock)
def upgrade():
    op.add_column('orders',
        sa.Column('currency_code', sa.String(3), nullable=True,
                  comment='ISO 4217 code. NOT NULL enforced in Phase 2 after backfill.'))

def downgrade():
    op.drop_column('orders', 'currency_code')
```

```sql
-- Backfill script (separate, not in migration)
-- Run in batches to avoid long transactions
UPDATE orders
SET currency_code = workspaces.default_currency
FROM workspaces
WHERE orders.workspace_id = workspaces.id
  AND orders.currency_code IS NULL
LIMIT 10000;
-- Repeat until 0 rows updated
```

```python
# GOOD — Phase 2: add NOT NULL after backfill (PostgreSQL 12+)
def upgrade():
    # PostgreSQL 12+ verifies existing rows without table rewrite
    op.alter_column('orders', 'currency_code', nullable=False)

def downgrade():
    op.alter_column('orders', 'currency_code', nullable=True)
```

---

### Anti-Pattern 8: Migration Without Compatibility Declaration (MEDIUM)

**Definition**: Delivering a migration without stating which application code versions are compatible with the new schema.

**Manifestations**:
```sql
-- BAD — FORBIDDEN: no compatibility note
-- Migration adds NOT NULL column
ALTER TABLE users ADD COLUMN phone VARCHAR(20) NOT NULL DEFAULT '';
-- Old app code that doesn't provide phone will fail on INSERT
```

**Why it's wrong**: Deployment ordering deadlocks. If the migration requires new code but old code is still running, INSERT/UPDATE operations fail. If the code is deployed first but the migration hasn't run, code fails on missing columns.

**Correction**: Explicit backward compatibility declaration.

```sql
-- GOOD — compatibility declaration in migration header
-- BACKWARD COMPATIBLE WITH: app v2.1.0+
-- DEPLOY ORDER: 1. Run this migration (adds nullable column)
--               2. Deploy app v2.1.0 (writes to new column)
--               3. Run Phase 2 migration (adds NOT NULL constraint)
-- NOT COMPATIBLE WITH: app v2.0.x and earlier (does not provide phone)

ALTER TABLE users ADD COLUMN phone_e164 VARCHAR(20) NULL;
```
