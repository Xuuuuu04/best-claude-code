# 数据工程师 — Baseline Scenarios

## Scenario 1: Flink CDC Pipeline (Canonical)

**Input**:
- Source: MySQL 8.0 orders table (5M rows/day growth)
- Sink: ClickHouse cluster (analytics)
- Latency SLA: < 1 minute P99
- Task: Real-time CDC pipeline with deduplication

**Expected Output Structure**:
- CLARIFY: MySQL binlog enabled + GTID mode confirmed, ClickHouse cluster topology defined (3 shards, 2 replicas)
- SELECT architecture: Flink 1.17 + Flink CDC 2.4 (Debezium-based) → Kafka → Flink processing → ClickHouse
- DESIGN layer structure:
  - ODS: Kafka topic `ods_orders_raw` (raw CDC events)
  - DWD: ClickHouse `dwd_orders` (deduplicated, ReplacingMergeTree)
  - ADS: ClickHouse `ads_daily_summary` (pre-aggregated, SummingMergeTree)
- DESIGN idempotency:
  - Flink exactly-once with checkpointing (60s interval, RocksDB backend)
  - ClickHouse ReplacingMergeTree with `version` column for dedup
- PLACE quality gates:
  - CDC lag gate: consumer lag < 1000 messages
  - DWD freshness: `max(created_at)` within 5 min of now
  - DWD dedup: duplicate `order_id` count = 0
- PII: customer_email masked at DWD layer with SHA-256 + salt
- SLA measurement: Flink job latency metric, ClickHouse ingestion lag
- Status: READY-FOR-NEXT

**Key Decision Points**:
- Flink CDC: Debezium-based, requires MySQL binlog enabled + GTID
- ClickHouse sink: ReplacingMergeTree + `version` column for deduplication (not FINAL query — FINAL is expensive)
- Checkpoint interval: 60s with RocksDB backend for large state
- Kafka as buffer: decouples CDC source from ClickHouse sink, handles backpressure

**BLOCK Condition**: If MySQL binlog is not enabled or GTID mode is off; if ClickHouse cluster topology is not defined.

---

## Scenario 2: Spark Skew Diagnosis (Complex)

**Input**:
- Spark job: join orders (10B rows) with users (1M rows)
- Symptom: 95th percentile task takes 45 minutes, median is 30 seconds
- Task: Diagnose and fix the skew

**Expected Output Structure**:
- DIAGNOSE: analyze stage in Spark UI — one task has 99% of shuffle read
  - Root cause: skewed join key (user_id has ~5% null values + 10% concentration in top 100 users)
- MEASURE baseline: P95 = 45min, P50 = 30s, max task input = 8GB vs median = 50MB
- OPTIMIZE:
  - Fix 1: broadcast users table (1M × 100 bytes = ~100MB, fits broadcast default 10MB with config change to 200MB)
  - Fix 2: if broadcast not feasible — salt user_id on orders side: `concat(user_id, floor(rand()*50))`
- VERIFY: re-run job, P95 task time < 2 minutes
- DOCUMENT: update pipeline comments with skew fix and monitoring query
- Status: READY-FOR-NEXT

**Key Decision Points**:
- Broadcast threshold check: `spark.sql.autoBroadcastJoinThreshold` (default 10MB)
- Trade-off: broadcast saves join overhead but increases driver memory pressure
- If null user_ids are expected: handle separately before join (filter nulls or coalesce to sentinel value)
- Add monitoring: log skew metrics per job run for early detection

**BLOCK Condition**: If data access to production Spark cluster is not available and query plans cannot be analyzed.

---

## Scenario 3: dbt Pipeline with PII and Compliance Gate (Blocked)

**Input**:
- Task: Build DWD layer for user activity with GDPR compliance
- Data contains: email, full name, IP address, purchase history
- Request: "just build the wide table with all fields"

**Expected Output Structure**:
- Status: BLOCKED
- Blocked on: PII classification and erasure path not defined
- Blocked by: User / @security-auditor / legal team
- What I have: ODS schema mapped, partition strategy designed (daily partitions on `event_time`)
- What I need:
  1. Approval from data governance on which PII fields to include in DWD vs. masked only
  2. Erasure implementation path: when user requests deletion, how are their rows handled? (hard delete, soft delete + anonymization, or partition drop?)
  3. Retention policy: how long do we keep historical PII in the warehouse?
- Rationale: Building a wide table with raw PII without an erasure path violates GDPR Article 17 (right to erasure). A table that cannot be corrected post-build is worse than no table.

**Key Decision Points**:
- BLOCK immediately — do not build "with all fields" and "fix PII later"
- Document what is ready (ODS mapping, partition design) to show progress
- Provide options for erasure path: (a) soft delete + periodic hard delete job, (b) partition-based deletion for time-series data, (c) full anonymization

---

## Scenario 4: Delta Lake Table Optimization (Complex)

**Input**:
- Delta Lake table: `dwd_orders`, 500GB, 10,000 files
- Symptom: Query performance degrading, small files problem
- Task: Optimize table for query performance

**Expected Output Structure**:
- DIAGNOSE: `DESCRIBE HISTORY dwd_orders` — 10,000 files, average size 50MB (too small for optimal Parquet)
  - Root cause: frequent small appends without compaction
- OPTIMIZE:
  ```sql
  -- File compaction
  OPTIMIZE dwd_orders;
  -- ZORDER for data locality on common filter columns
  OPTIMIZE dwd_orders ZORDER BY (user_id, created_at);
  -- Clean old snapshots
  VACUUM dwd_orders RETAIN 168 HOURS;  -- 7 days
  ```
- VERIFY: post-OPTIMIZE file count = ~500 files (1GB each), query time reduced 80%
- DOCUMENT: add scheduled OPTIMIZE job to pipeline (weekly)
- Status: READY-FOR-NEXT

**Key Decision Points**:
- OPTIMIZE frequency: weekly for append-heavy tables, monthly for stable tables
- ZORDER columns: choose columns most frequently used in WHERE clauses
- VACUUM retention: 7 days minimum (Delta Lake time travel protection), longer for compliance
- Monitor: track file count and average file size as leading indicators

---

## Scenario 5: Airflow DAG Design with Dynamic Task Mapping

**Input**:
- Task: Process daily partitions for 30 days of backfill
- Source: S3 Parquet files, one per day
- Transform: dbt models, one per partition
- Constraint: Must complete within 2 hours (SLA)

**Expected Output Structure**:
- DESIGN DAG:
  ```python
  from airflow import DAG
  from airflow.decorators import task
  from airflow.operators.bash import BashOperator
  from datetime import datetime, timedelta

  with DAG(
      "daily_partition_backfill",
      start_date=datetime(2026, 3, 1),
      end_date=datetime(2026, 3, 30),
      schedule=None,  # Manual trigger only
      catchup=False,
  ) as dag:

      @task
      def get_partitions():
          return [f"2026-03-{day:02d}" for day in range(1, 31)]

      @task
      def process_partition(partition_date: str):
          # Run dbt for specific partition
          return f"dbt run --vars '{{partition_date: {partition_date}}}'"

      partitions = get_partitions()
      process_partition.expand(partition_date=partitions)
  ```
- SLA: 30 partitions × 3 minutes each = 90 minutes (with 5 parallel tasks = 18 minutes wall time), well within 2-hour SLA
- Idempotency: each dbt run uses `is_incremental()` with partition filter — re-run safe
- Quality gate: dbt test after each partition — failures block that partition only
- Status: READY-FOR-NEXT

**Key Decision Points**:
- Dynamic task mapping (Airflow 2.3+) vs. traditional for-loop: mapping provides better UI visibility and individual task retry
- Parallelism limit: 5 concurrent tasks to avoid overwhelming source database
- Catchup=False: prevents accidental backfill on DAG enable
