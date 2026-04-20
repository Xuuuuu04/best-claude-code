---
source: agents/database.md
copied: 2026-04-21
note: Database migration patterns and tooling deep knowledge.
---

# Database Engineer — Migration Domain

## Migration Framework Comparison

| Framework | Language | Up/Down | Idempotency | Online DDL | Best For |
|-----------|----------|---------|-------------|------------|----------|
| Alembic | Python | Yes | Manual | Via raw SQL | SQLAlchemy projects |
| Flyway | SQL/Java | Yes (undo) | No | Via callbacks | Java/Spring projects |
| Prisma Migrate | TypeScript | No (shadow db) | Yes | Via `migrate dev` | Node.js/TypeScript |
| Django Migrations | Python | No (reversible) | Partial | Via `RunSQL` | Django projects |
| Liquibase | XML/YAML/SQL | Yes (rollback) | No | Via changesets | Enterprise/Java |
| Atlas | HCL/Go | Yes | Yes | Native | Go projects, modern stacks |
| pgroll | Go | Yes (instant) | Yes | Native | PostgreSQL-only |

---

## Alembic Migration Patterns

### Project Setup

```bash
# Initialize
alembic init migrations

# Configure alembic.ini
sqlalchemy.url = postgresql+psycopg2://user:pass@localhost/dbname

# Configure env.py
target_metadata = Base.metadata  # Your SQLAlchemy Base
```

### Idempotent Migration Template

```python
"""Add user phone column

Revision ID: 20240421_add_user_phone
Revises: 20240415_create_users
Create Date: 2026-04-21

BACKWARD COMPATIBLE WITH: app v2.1.0+
DEPLOY ORDER: 1. Run migration (adds nullable column)
              2. Deploy app v2.1.0 (writes to new column)
              3. Run Phase 2 migration (adds NOT NULL constraint)
NOT COMPATIBLE WITH: app v2.0.x and earlier
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = '20240421_add_user_phone'
down_revision = '20240415_create_users'
branch_labels = None
depends_on = None


def upgrade():
    # Idempotent: check before adding
    conn = op.get_bind()
    result = conn.execute(sa.text("""
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'phone_e164'
    """))
    if result.fetchone() is None:
        op.add_column('users',
            sa.Column('phone_e164', sa.String(20), nullable=True,
                      comment='E.164 format phone number. L1 PII: encrypted storage.')
        )
        # Partial index for non-null phones only
        op.execute("""
            CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_phone
            ON users (phone_e164)
            WHERE phone_e164 IS NOT NULL
        """)


def downgrade():
    # Drop index first, then column
    op.execute("DROP INDEX IF EXISTS idx_users_phone")
    op.drop_column('users', 'phone_e164')
```

### Two-Phase NOT NULL Addition

```python
"""Phase 1: Add nullable column"""
def upgrade():
    op.add_column('orders',
        sa.Column('currency_code', sa.String(3), nullable=True,
                  comment='ISO 4217 code. NOT NULL enforced in Phase 2 after backfill.'))

def downgrade():
    op.drop_column('orders', 'currency_code')

"""Phase 2: Add NOT NULL constraint (run after backfill completes)"""
def upgrade():
    # Verify no NULLs exist first (safety check)
    conn = op.get_bind()
    result = conn.execute(sa.text("SELECT COUNT(*) FROM orders WHERE currency_code IS NULL"))
    null_count = result.scalar()
    if null_count > 0:
        raise Exception(f"Cannot add NOT NULL: {null_count} rows have NULL currency_code. Run backfill first.")
    
    op.alter_column('orders', 'currency_code', nullable=False)

def downgrade():
    op.alter_column('orders', 'currency_code', nullable=True)
```

### Backfill Script (Separate, Not in Migration)

```python
#!/usr/bin/env python
"""Backfill currency_code for existing orders.

Run in batches to avoid long transactions.
Execute AFTER Phase 1 migration, BEFORE Phase 2 migration.
"""
import sqlalchemy as sa
from sqlalchemy import create_engine

engine = create_engine("postgresql://user:pass@localhost/db")

BATCH_SIZE = 10000

with engine.begin() as conn:
    while True:
        result = conn.execute(sa.text("""
            UPDATE orders
            SET currency_code = workspaces.default_currency
            FROM workspaces
            WHERE orders.workspace_id = workspaces.id
              AND orders.currency_code IS NULL
            LIMIT :batch_size
        """), {"batch_size": BATCH_SIZE})
        
        if result.rowcount == 0:
            print("Backfill complete: all rows updated")
            break
        
        print(f"Updated {result.rowcount} rows")

# Verify
with engine.connect() as conn:
    result = conn.execute(sa.text("SELECT COUNT(*) FROM orders WHERE currency_code IS NULL"))
    assert result.scalar() == 0, "Backfill incomplete!"
    print("Verification passed: 0 NULL rows remaining")
```

---

## Prisma Migration Patterns

### Schema-First Workflow

```prisma
// schema.prisma
model User {
  id        String   @id @default(uuid())
  email     String   @unique
  phoneE164 String?  @map("phone_e164")
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")

  @@index([phoneE164])
  @@map("users")
}
```

```bash
# Generate migration from schema diff
npx prisma migrate dev --name add_phone_column

# Review generated SQL before applying!
cat prisma/migrations/*/migration.sql

# Apply to production
npx prisma migrate deploy

# Generate client
npx prisma generate
```

### Prisma Shadow Database

```bash
# Required for `migrate dev` (detects schema drift)
# Set in DATABASE_URL or separately:
export SHADOW_DATABASE_URL="postgresql://user:pass@localhost/shadow_db"

# Shadow db is created, migrated, then dropped automatically
# Never used in production — only for dev schema validation
```

---

## Migration Safety Checklist

### Before Running Any Migration

```markdown
- [ ] Migration reviewed by second engineer (or self-review with checklist)
- [ ] Up script tested on staging database with production-like data volume
- [ ] Down script tested: can it actually restore previous state?
- [ ] Idempotency verified: running up twice produces no errors
- [ ] Backward compatibility declared: which app versions are compatible?
- [ ] Large-table risk assessed: does any table exceed 1M rows?
- [ ] Online DDL strategy documented (if needed)
- [ ] Rollback procedure documented and tested
- [ ] Maintenance window scheduled (if downtime required)
- [ ] Database backup taken before migration
```

### Migration Naming Convention

| Pattern | Example | Use Case |
|---------|---------|----------|
| Timestamp + description | `202404211430_add_user_phone` | Alembic, manual |
| Version + description | `V2024.04.21.1__add_user_phone` | Flyway |
| Sequential + description | `0042_add_user_phone` | Django, hand-written |
| Semantic + description | `add_user_phone_20240421` | Prisma |

### Migration File Template

```sql
-- Migration: [name]
-- Author: [name]
-- Date: [YYYY-MM-DD]
-- Backward Compatible With: [app version]
-- Deploy Order: [step number]
-- Estimated Duration: [time on X rows]
-- Downtime Required: [yes/no, if yes: duration]

-- Safety check: verify precondition
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'users' AND column_name = 'phone') THEN
        RAISE NOTICE 'Column already exists, skipping';
        RETURN;
    END IF;
END $$;

-- Main migration
ALTER TABLE users ADD COLUMN phone VARCHAR(20) NULL;
CREATE INDEX CONCURRENTLY idx_users_phone ON users (phone) WHERE phone IS NOT NULL;

-- Post-migration verification
DO $$
DECLARE
    col_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'phone'
    ) INTO col_exists;
    
    IF NOT col_exists THEN
        RAISE EXCEPTION 'Migration failed: column not created';
    END IF;
END $$;

-- Rollback (undo script)
-- DROP INDEX IF EXISTS idx_users_phone;
-- ALTER TABLE users DROP COLUMN IF EXISTS phone;
```

---

## Schema Drift Detection

### Automated Drift Detection

```bash
# Atlas (modern approach)
atlas schema diff \
  --from "postgres://user:pass@localhost:5432/mydb" \
  --to "file://schema.sql"

# pg_dump + diff (simple approach)
pg_dump -s mydb > current_schema.sql
diff -u expected_schema.sql current_schema.sql

# Liquibase status
liquibase --changeLogFile=db.changelog.xml status
```

### Schema Version Table

```sql
-- Track migrations in database
CREATE TABLE schema_migrations (
    version VARCHAR(255) PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    checksum VARCHAR(64) NOT NULL,
    applied_by VARCHAR(100) NOT NULL DEFAULT CURRENT_USER,
    duration_ms INTEGER,
    success BOOLEAN NOT NULL DEFAULT true
);

-- Query migration history
SELECT version, applied_at, applied_by, success
FROM schema_migrations
ORDER BY applied_at DESC;

-- Detect failed migrations
SELECT * FROM schema_migrations WHERE success = false;
```
