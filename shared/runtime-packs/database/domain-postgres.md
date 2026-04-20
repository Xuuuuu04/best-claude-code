---
source: agents/database.md
copied: 2026-04-21
note: PostgreSQL-specific deep knowledge for database engineer.
---

# Database Engineer — PostgreSQL Domain

## Index Strategy Deep Dive

### Index Type Selection Matrix

| Query Pattern | Index Type | Use Case | Caveat |
|--------------|-----------|----------|--------|
| Equality (`=`) | B-tree | Primary keys, unique constraints | Default, always available |
| Range (`<`, `>`, `BETWEEN`) | B-tree | Timestamps, numeric ranges | Keep index on query-side column |
| Text search (`LIKE 'prefix%'`) | B-tree | Prefix matching | `text_pattern_ops` for `COLLATE` issues |
| Full-text search (`@@`) | GIN | Document search, log search | Large index size, slow writes |
| Array containment (`@>`, `<@`) | GIN | Tag arrays, category lists | Prefer `jsonb` arrays over `text[]` |
| JSONB containment | GIN | JSONB queries | `jsonb_path_ops` for `@>` queries |
| Geospatial | GiST/SP-GiST | Location queries | PostGIS required |
| Ordered range queries | BRIN | Very large, naturally ordered tables | Useless for random-access data |

### Composite Index Ordering Rule

```sql
-- Rule: Most selective equality columns first, then range columns
-- BAD — low selectivity first
CREATE INDEX idx_orders_status_created ON orders (status, created_at);
-- status has 3 values (0.33 selectivity), created_at is range

-- GOOD — range column after high-selectivity equality
CREATE INDEX idx_orders_user_created ON orders (user_id, created_at DESC);
-- user_id is highly selective (near-unique), created_at is range

-- EVEN BETTER — partial index for hot query
CREATE INDEX idx_orders_user_pending ON orders (user_id, created_at DESC)
WHERE status = 'pending';
-- Only pending orders indexed: smaller, faster, more selective
```

### Index Verification Commands

```sql
-- Check if index is used
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE user_id = 'uuid' AND status = 'pending';
-- Look for: "Index Scan using idx_orders_user_pending"
-- Avoid: "Seq Scan" or "Index Scan using wrong_index"

-- Check index size
SELECT schemaname, tablename, indexname, pg_size_pretty(pg_relation_size(indexname::regclass))
FROM pg_indexes
WHERE tablename = 'orders';

-- Check index usage stats (since last stats reset)
SELECT schemaname, relname, indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE relname = 'orders'
ORDER BY idx_scan DESC;
-- idx_scan = 0 for months → candidate for removal

-- Find duplicate/overlapping indexes
SELECT t.tablename, i.indexname, i.indexdef
FROM pg_indexes i
JOIN pg_indexes t ON i.tablename = t.tablename AND i.indexname != t.indexname
WHERE i.tablename = 'orders'
  AND (
    i.indexdef LIKE '%(user_id)%' AND t.indexdef LIKE '%(user_id)%'
    OR i.indexdef LIKE '%(created_at)%' AND t.indexdef LIKE '%(created_at)%'
  );
```

---

## Partitioning Strategies

### Range Partitioning (Time-Series)

```sql
-- Parent table
CREATE TABLE sensor_readings (
    id BIGSERIAL,
    sensor_id UUID NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL,
    temperature DECIMAL(5, 2),
    humidity DECIMAL(5, 2),
    metadata JSONB,
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

-- Monthly partitions
CREATE TABLE sensor_readings_2026_04 PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE sensor_readings_2026_05 PARTITION OF sensor_readings
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

-- Indexes on partitions (inherited automatically)
CREATE INDEX idx_sensor_readings_time ON sensor_readings (recorded_at DESC);
CREATE INDEX idx_sensor_readings_sensor_time ON sensor_readings (sensor_id, recorded_at DESC);

-- Partition pruning verification
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM sensor_readings
WHERE recorded_at >= '2026-04-15' AND recorded_at < '2026-04-16';
-- Expected: "Partition Ref: sensor_readings_2026_04" only
```

### Partition Maintenance with pg_partman

```sql
-- Install extension
CREATE EXTENSION pg_partman;

-- Create automated partition management
SELECT partman.create_parent('public.sensor_readings', 'recorded_at', 'native', 'monthly');

-- Create partitions for next 3 months
SELECT partman.run_maintenance();

-- Scheduled maintenance (run via cron/pg_cron)
SELECT cron.schedule('partition-maintenance', '0 1 * * *', 
    'SELECT partman.run_maintenance()');

-- Retention: drop partitions older than 12 months
SELECT partman.create_parent('public.sensor_readings', 'recorded_at', 'native', 'monthly',
    p_premake := 3, p_retention := '12 months', p_retention_keep_table := false);
```

### Partitioning Decision Matrix

| Data Pattern | Partition Type | Granularity | When to Use |
|-------------|---------------|-------------|-------------|
| Time-series, time-range queries | Range (time) | Day/Month | >10M rows, mostly recent queries |
| Multi-tenant, tenant isolation | Range/List | Per tenant | Tenant data must be isolated |
| Even distribution needed | Hash | 16-64 partitions | No natural range, uniform access |
| Hot/cold data separation | Range (time) | Month | Different storage for old data |

---

## Online DDL Operations

### PostgreSQL 12+ Online DDL

```sql
-- Adding column with DEFAULT (PostgreSQL 11+ does NOT rewrite table)
ALTER TABLE orders ADD COLUMN currency_code VARCHAR(3) NOT NULL DEFAULT 'USD';
-- Fast: only catalog update, existing rows get default at read time

-- Adding column without DEFAULT (instant since PG 11)
ALTER TABLE orders ADD COLUMN notes TEXT;

-- Adding NOT NULL after backfill (instant — only catalog check)
ALTER TABLE orders ALTER COLUMN currency_code SET NOT NULL;

-- Creating index concurrently (no table lock)
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders (user_id);
-- Safe on production, but slower and cannot run in transaction

-- Dropping column (instant — catalog only, space reclaimed by VACUUM)
ALTER TABLE orders DROP COLUMN IF EXISTS temp_column;
```

### Operations That DO Lock (Require Online DDL Tool)

| Operation | Lock Level | Duration | Tool |
|-----------|-----------|----------|------|
| `ALTER TABLE ... ADD COLUMN ... NOT NULL` (no DEFAULT, pre-PG 11) | AccessExclusiveLock | Full table scan | pt-osc / gh-ost |
| `ALTER TABLE ... ALTER COLUMN TYPE` | AccessExclusiveLock | Full table rewrite | pt-osc / gh-ost |
| `ALTER TABLE ... DROP COLUMN` (pre-PG 11 with dependent objects) | AccessExclusiveLock | Variable | pt-osc / gh-ost |
| `CREATE INDEX` (without CONCURRENTLY) | ShareLock | Index build time | `CREATE INDEX CONCURRENTLY` |
| `VACUUM FULL` | AccessExclusiveLock | Full table rewrite | pg_repack |

### pt-online-schema-change Example

```bash
# Add column to large table with pt-osc
pt-online-schema-change \
  --alter "ADD COLUMN currency_code VARCHAR(3) NULL" \
  --execute \
  --max-load Threads_running=25 \
  --critical-load Threads_running=50 \
  --chunk-size=1000 \
  D=mydb,t=orders

# How it works:
# 1. Creates empty shadow table with new schema
# 2. Adds triggers to capture changes on original table
# 3. Copies data in chunks
# 4. Swaps tables atomically
# 5. Drops old table
```

---

## Row-Level Security (RLS)

```sql
-- Enable RLS on table
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Policy: users can only see their own documents
CREATE POLICY document_owner_policy ON documents
    FOR ALL
    TO app_user
    USING (owner_id = current_setting('app.current_user_id')::BIGINT);

-- Set user context before query
SET LOCAL app.current_user_id = '42';
SELECT * FROM documents;  -- Only returns documents where owner_id = 42

-- Bypass RLS for admin (use with caution)
ALTER TABLE documents FORCE ROW LEVEL SECURITY;
-- Superuser bypasses by default; FORCE requires explicit bypass
```

---

## Connection Pool Tuning

### PgBouncer Configuration

```ini
[databases]
mydb = host=localhost port=5432 dbname=mydb

[pgbouncer]
listen_port = 6432
listen_addr = 127.0.0.1
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

; Pool settings
pool_mode = transaction        ; transaction-level pooling (recommended for web apps)
max_client_conn = 10000
default_pool_size = 25
reserve_pool_size = 5
reserve_pool_timeout = 3

; Timeouts
server_idle_timeout = 600
server_lifetime = 3600
client_idle_timeout = 0
client_login_timeout = 60
```

### Pool Mode Selection

| Mode | When to Use | Caveat |
|------|-------------|--------|
| `session` | Long-running connections, prepared statements, temporary tables | One server conn per client conn |
| `transaction` | Web applications, short requests | Prepared statements don't work across transactions |
| `statement` | Highest concurrency, simple queries | No multi-statement transactions |

---

## Backup and Recovery

### pgBackRest Configuration

```ini
[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2
repo1-retention-diff=4
start-fast=y
stop-auto=y

[mydb]
pg1-path=/var/lib/postgresql/16/main
pg1-port=5432
pg1-user=postgres

# Full backup weekly
# pgbackrest --stanza=mydb backup --type=full

# Diff backup daily
# pgbackrest --stanza=mydb backup --type=diff

# Point-in-time recovery
# pgbackrest --stanza=mydb restore --type=time --target="2026-04-21 14:30:00"
```

### Logical Replication (for migrations)

```sql
-- Publisher (source)
CREATE PUBLICATION mydb_pub FOR TABLE orders, users, products;

-- Subscriber (target)
CREATE SUBSCRIPTION mydb_sub
    CONNECTION 'host=source-db port=5432 dbname=mydb user=replicator'
    PUBLICATION mydb_pub;

-- Monitor replication lag
SELECT client_addr, state, sent_lsn, write_lsn, flush_lsn, replay_lsn,
       pg_size_pretty(pg_wal_lsn_diff(sent_lsn, replay_lsn)) AS lag
FROM pg_stat_replication;
```
