# 数据库工程师 — Output Contract Reference

## Standard Output Format

```
## Database Design Output: [Feature Name]

**Change Type**: [New table / Field change / Index optimization / Data backfill / Partition]
**Database**: [PostgreSQL / MySQL / SQLite / MongoDB / Redis]
**Migration Tool**: [Alembic / Prisma Migrate / Flyway / golang-migrate / Knex]
**Target Environment**: [dev / staging / production]

### Schema Change Description
[For each new or modified table: field type selection rationale, constraint justification, primary key strategy with explanation]

### Migration Files
**Up script** (path): [idempotent DDL with IF NOT EXISTS guards + query-justification comments]
**Down script**: [complete reversal of every up step]

### PII Classification Table
| Column | Table | PII Tier | Protection Strategy | Retention Period |

### Index Rationale
| Index Name | Columns | Type | Justification (query + selectivity + write overhead) |

### Partition Strategy (if applicable)
| Partition Type | Key | Granularity | Expected Partitions |

### Large-Table Safety Assessment
[Table projected > 1M rows? If yes: online DDL strategy + estimated time + tool]

### Backward Compatibility Declaration
[Compatible app versions + deploy sequencing]

### Rollback Procedure
[Command + verify + compensating steps]

### Next Steps
[@backend / @devops / @security-auditor]
```

## Filled Example — User Invitation System

```
## Database Design Output: User Invitation System

**Change Type**: New table (invitations) + index
**Database**: PostgreSQL 16
**Migration Tool**: Alembic
**Target Environment**: dev → staging → production

### Schema Change Description

New table `invitations`. ULID primary key for time-sortable distributed-safe IDs.
`invitee_email` is L1 PII — stored as AES-256-GCM ciphertext + HMAC hash for equality search.
`expires_at` uses TIMESTAMPTZ. Status CHECK constraint enforces state machine at DB level.

### Migration Files

Up script (migrations/20260421_142300_add_invitations_table.py):
```python
def upgrade():
    op.create_table('invitations',
        sa.Column('id', sa.CHAR(26), nullable=False, default=gen_ulid()),
        sa.Column('workspace_id', sa.UUID(), nullable=False),
        sa.Column('invited_by', sa.UUID(), nullable=False),
        sa.Column('invitee_email_encrypted', sa.LargeBinary(), nullable=False),
        sa.Column('invitee_email_hash', sa.CHAR(64), nullable=False),
        sa.Column('role', sa.String(20), nullable=False),
        sa.Column('status', sa.String(20), nullable=False, server_default='pending'),
        sa.Column('expires_at', sa.TIMESTAMP(timezone=True), nullable=False),
        sa.Column('created_at', sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('updated_at', sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.text('NOW()')),
        sa.PrimaryKeyConstraint('id'),
        sa.CheckConstraint("status IN ('pending','accepted','expired','revoked')"),
        sa.ForeignKeyConstraint(['workspace_id'], ['workspaces.id'], ondelete='RESTRICT'),
        sa.ForeignKeyConstraint(['invited_by'], ['users.id'], ondelete='RESTRICT')
    )
    
    op.create_index('idx_invitations_workspace_status', 'invitations',
                    ['workspace_id', 'status'],
                    postgresql_where=sa.text("status = 'pending'"))

def downgrade():
    op.drop_index('idx_invitations_workspace_status')
    op.drop_table('invitations')
```

### PII Classification Table

| Column | Table | PII Tier | Protection Strategy | Retention Period |
|---|---|---|---|---|
| invitee_email_encrypted | invitations | L1 | AES-256-GCM, key in Vault | Delete 30 days after expiry/revocation |
| invitee_email_hash | invitations | L1 | HMAC-SHA256 for equality search | Same as encrypted field |

### Index Rationale

| Index | Columns | Type | Justification |
|---|---|---|---|
| idx_invitations_workspace_status | (workspace_id, status) WHERE status='pending' | B-tree partial | Primary query: list pending invitations. Partial index excludes ~90% of rows. Write overhead minimal. |

### Large-Table Safety Assessment

Expected < 100K rows. Regular ALTER TABLE safe. No online DDL strategy required.

### Backward Compatibility Declaration

New table only — no existing tables modified. Any deploy order safe.
Compatible with all app versions.

### Rollback Procedure

1. `alembic downgrade -1`
2. Verify: `SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'invitations'` → 0
3. No application-side changes needed

### Next Steps

[@backend — migration complete; use invitee_email_hash for lookups, invitee_email_encrypted for display]
[@security-auditor — L1 PII fields flagged for compliance review before production]
```

## BLOCKED Output Format

```
## Database Design Output: [Feature Name]

**Status**: BLOCKED

**Blocked on**: [specific missing item]
**Blocked by**: [@role or user]
**Rationale**: [why this blocks schema design]

**What I have done**: [completed work despite block]
**What I need**: [specific unblock condition]
```

## Filled Example — BLOCKED on PII + Topology

```
## Database Design Output: Health Records Storage

**Status**: BLOCKED

**Blocked on**: Two prerequisites

**Block 1 — Compliance framework not specified for L3 PII:**
"Health records are L3 Sensitive Business Data. Before designing this schema, I need:
1. Which compliance framework applies? HIPAA, GDPR Article 9, or PIPL Article 28?
2. What is the data retention policy?
Route: @security-auditor must define compliance framework before schema design."

**Block 2 — Topology decision required:**
"Adding health records to the main PostgreSQL database is a topology decision with isolation implications. Whether to isolate in separate database instance, separate schema with RLS, or shared table is @architect's decision.
Route: @architect must confirm data isolation topology before schema design."

**What I have done**: Identified data entities and relationships from requirements document.
**What I need**: (1) Compliance framework from @security-auditor; (2) Topology decision from @architect.
```
