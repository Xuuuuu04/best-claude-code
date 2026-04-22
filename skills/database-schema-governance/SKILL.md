---
name: database-schema-governance
description: Schema design, migration engineering, index strategy, and PII classification methodology for the Harness team. Covers data modeling, precision types, multi-tenant partitioning, migration idempotency, online DDL, and L1/L2/L3 PII tiers. Loaded by @database via skills: frontmatter.
type: skill
---

# Database Schema Governance Skill

## 1. Data Governance Baseline

Every schema MUST pass this checklist before DDL is written:
- **Money fields**: DECIMAL(precision, scale) — never FLOAT/DOUBLE. Integer minor-units (cents/fen) acceptable with documented unit.
- **Time fields**: TIMESTAMPTZ (PostgreSQL) or DATETIME + explicit UTC policy (MySQL)
- **Audit trail**: `created_at` + `updated_at` on every table
- **Soft delete**: `deleted_at TIMESTAMPTZ NULL` when required by business
- **NULL policy**: each column NULL/NOT NULL set by business semantics, not default
- **PK strategy**: document choice (BIGSERIAL / UUID v4 / ULID / snowflake) with rationale

## 2. Data Modeling

### Three Schema Candidates
For every new entity, evaluate:
- **Normalized (3NF)**: write-friendly, enforces consistency, queries require JOINs
- **Denormalized**: read-friendly, consistency requires application-level coordination
- **Hybrid**: normalized core with redundant hot-read columns — usually optimal for production

### Modeling Order
1. Model business objects in plain English before DDL
2. Define entity identity, attributes, relationships, state transitions
3. Then translate to schema

## 3. Migration Engineering

### Idempotency
Every migration MUST be safely runnable twice:
- Use `IF NOT EXISTS` for CREATE statements
- Use `ON CONFLICT DO NOTHING` for data backfill
- Use conditional `ALTER TABLE` patterns

### Up + Down Pair
Every `up` has a corresponding `down` that restores the previous state exactly. A migration without rollback is a one-way door into a production incident.

### Change Type Classification
| Change Type | Compatibility | Strategy |
|-------------|---------------|----------|
| Add nullable column / new table | Backward-compatible | Direct |
| Add NOT NULL column | Breaking | Two-phase: add NULLABLE → backfill → add constraint |
| Rename column | Breaking | Two-phase: add new → dual-write → migrate reads → drop old |
| Change column type | Evaluated | Data conversion safety check; may require two-phase |
| Drop column | Breaking | Two-phase: stop reads/writes → drop in next sprint |
| Add index | Safe | Online creation (CONCURRENTLY in PostgreSQL) |

### Large-Table Safety
Any `ALTER TABLE` on table projected to exceed 1M rows requires explicit online DDL strategy:
- MySQL: `pt-online-schema-change` or `gh-ost`
- PostgreSQL: `pg_repack` or native online DDL

## 4. Index Strategy

### Three Questions (mandatory before adding any index)
1. Which specific queries need this index?
2. What is the field cardinality (selectivity > 0.1 threshold)?
3. What is the write overhead impact?

### Index Types
| Type | Best For | Notes |
|------|----------|-------|
| B-tree | Equality and range queries | Default; composite follows leftmost prefix rule |
| GIN | PostgreSQL array, JSONB | Higher write cost than B-tree |
| BRIN | Large append-only tables | Tiny size, minimal maintenance |
| Partial | Soft-delete exclusion, filtered queries | Only indexes rows matching predicate |
| Composite | Multi-column queries | Column order matters; covering indexes eliminate table access |

### Redundant Index Detection
Regularly audit for indexes where one is a leftmost prefix of another.

## 5. PII Classification (L1/L2/L3)

Every column in every new table MUST be evaluated before schema ships:

| Tier | Definition | Protection Strategy | Example |
|------|-----------|---------------------|---------|
| **L1** | Direct identifiers | AES-256-GCM + HMAC hash | email, phone, ID number |
| **L2** | Quasi-identifiers | Masking, range generalization | birth date, zip code, gender |
| **L3** | Sensitive business data | Field-level encryption + audit log | salary, health records, financials |

Default policy: unclassified until explicitly evaluated. "No PII" requires explicit justification.

## 6. Multi-Tenant Models

| Model | When to Use | Trade-off |
|-------|-------------|-----------|
| Shared table + RLS | <1000 tenants, simple isolation | Single schema, RLS overhead |
| Schema-per-tenant | 1000-10000 tenants, strong isolation | Schema proliferation, connection pool pressure |
| Database-per-tenant | >10000 tenants, regulatory separation | Highest overhead, strongest isolation |

## 7. Anti-Patterns

**Down-less Migration**: migration without rollback script. Correction: every up has a down.
**Float for Money**: FLOAT/DOUBLE for monetary values. Correction: DECIMAL or integer minor-units.
**Index Everything**: adding indexes "just in case." Correction: three-question protocol.
**ORM-Schema Drift**: ORM model becomes source of truth instead of migration. Correction: migrations are the single source of truth.
**PII Without Tiering**: column ships without L1/L2/L3 classification. Correction: evaluate every column before schema ships.
**Partition Blindness**: partitioning without query pattern analysis. Correction: partition key must align with query filters.
**Two-Phase Neglect**: making breaking schema changes in single phase. Correction: backward-compatible first, then stricter.
