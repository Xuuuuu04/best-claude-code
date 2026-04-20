# Data Engineer — Baseline Scenarios

## Scenario 1: Flink CDC Pipeline (Canonical)

**Input**:
- Source: MySQL 8.0 orders table (5M rows/day growth)
- Sink: ClickHouse cluster (analytics)
- Latency SLA: < 1 minute P99
- Task: Real-time CDC pipeline with deduplication

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Engine: Flink 1.17 + Flink CDC connector
- Idempotency: exactly-once with Flink checkpointing + ClickHouse ReplacingMergeTree
- SLA measurement: Flink job latency metric, ClickHouse ingestion lag
- Layer design: ODS (raw CDC events) → DWD (deduped orders) → ADS (per-customer summary)
- Data quality gate at DWD: not_null on order_id, amount >= 0
- PII: customer_email masked at DWD layer with SHA-256 + salt

**Key Decision Points**:
- Flink CDC: Debezium-based, requires MySQL binlog enabled + GTID
- ClickHouse sink: use ReplacingMergeTree + FINAL query for deduplication
- Checkpoint interval: 60s with RocksDB backend for large state

**BLOCK Condition**: If MySQL binlog is not enabled or GTID mode is off; if ClickHouse cluster topology is not defined.

---

## Scenario 2: Spark Skew Diagnosis (Complex)

**Input**:
- Spark job: join orders (10B rows) with users (1M rows)
- Symptom: 95th percentile task takes 45 minutes, median is 30 seconds
- Task: Diagnose and fix the skew

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Diagnosis: skewed join key (user_id has ~5% null values + 10% concentration in top 100 users)
- Fix 1: broadcast users table (1M × 100 bytes = ~100MB, fits broadcast default 10MB with config change)
- Fix 2: if broadcast not feasible — salt user_id on orders side: `concat(user_id, floor(rand()*50))`
- Memory Impact: broadcast adds 100MB to each executor driver heap
- Code diff: before/after Spark job with fix applied
- Post-fix SLA estimate: P95 task time < 2 minutes

**Key Decision Points**:
- Broadcast threshold check: `spark.sql.autoBroadcastJoinThreshold` (default 10MB)
- Trade-off: broadcast saves join overhead but increases driver memory pressure
- If null user_ids are expected: handle separately before join

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
- What I have: ODS schema mapped, partition strategy designed
- What I need:
  1. Approval from data governance on which PII fields to include in DWD vs. masked only
  2. Erasure implementation path: when user requests deletion, how are their rows handled?
  3. Retention policy: how long do we keep historical PII in the warehouse?
- Rationale: Building a wide table with raw PII without an erasure path violates GDPR.
  A table that cannot be corrected post-build is worse than no table.
