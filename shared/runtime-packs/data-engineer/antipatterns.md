# 数据工程师 — Anti-Patterns Reference

## Named Anti-Patterns

---

### Anti-Pattern 1: Select-Star Source Ingestion (HIGH)

**Definition**: Using `SELECT * FROM source` in ODS ingestion — breaks on source schema changes.

**Manifestations**:
```sql
-- BAD — FORBIDDEN: SELECT * breaks when source adds/drops columns
INSERT INTO ods_orders
SELECT * FROM source_db.orders;
-- Source adds 'discount_code' column → pipeline fails or loads wrong data
```

```python
# BAD — FORBIDDEN: Spark SELECT *
ods_df = spark.read.jdbc(url, "orders")
ods_df.write.mode("append").save("/data/ods/orders")
# Schema change in source → downstream jobs break
```

**Why it's dangerous**: Source schema changes (adding a column, renaming, changing types) break the pipeline or produce silently wrong data. Explicit column lists with documented schema versions enable early detection of changes.

**Correction**: Explicit column list with schema validation.

```sql
-- GOOD — explicit columns with version comment
INSERT INTO ods_orders (order_id, user_id, amount, status, created_at)
SELECT order_id, user_id, amount, status, created_at
FROM source_db.orders;
-- Schema version: orders_v3 (2026-04-15)
-- If source adds column: pipeline continues, new column ignored until explicitly added
```

```python
# GOOD — explicit schema with validation
from pyspark.sql.types import StructType, StructField, StringType, DecimalType, TimestampType

schema = StructType([
    StructField("order_id", StringType(), False),
    StructField("user_id", StringType(), False),
    StructField("amount", DecimalType(10, 2), False),
    StructField("status", StringType(), False),
    StructField("created_at", TimestampType(), False),
])

ods_df = spark.read.schema(schema).jdbc(url, "orders")
# Schema mismatch raises error immediately, not silently corrupts data
```

---

### Anti-Pattern 2: Non-Idempotent Job (CRITICAL)

**Definition**: Job appends data without deduplication — re-run produces duplicate records.

**Manifestations**:
```sql
-- BAD — FORBIDDEN: append without dedup
INSERT INTO dwd_orders
SELECT * FROM ods_orders WHERE dt = '2026-04-21';
-- Re-run = duplicate rows for 2026-04-21
```

```python
# BAD — FORBIDDEN: Spark append mode
df.write.mode("append").save("/data/dwd/orders")
# Re-run job = duplicate data
```

**Why it's dangerous**: Re-running a failed job (common in production) doubles the data. Downstream consumers see inflated counts. Recovery from duplicate data requires complex deduplication or full table rebuild.

**Correction**: Use idempotent write patterns.

```sql
-- GOOD — INSERT OVERWRITE for partition replacement
INSERT OVERWRITE TABLE dwd_orders PARTITION (dt='2026-04-21')
SELECT * FROM ods_orders WHERE dt = '2026-04-21';
-- Re-run = same result, no duplicates
```

```python
# GOOD — Delta Lake MERGE INTO
from delta.tables import DeltaTable

delta_table = DeltaTable.forPath(spark, "/data/dwd/orders")

delta_table.alias("target").merge(
    source=updates_df.alias("source"),
    condition="target.order_id = source.order_id AND target.dt = source.dt"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .execute()
# Re-run = no-op if data unchanged, updates if changed, inserts if new
```

```python
# GOOD — Spark replaceWhere for partition overwrite
df.write.format("delta") \
    .mode("overwrite") \
    .option("replaceWhere", "dt = '2026-04-21'") \
    .save("/data/dwd/orders")
```

---

### Anti-Pattern 3: Skew-Blindness (HIGH)

**Definition**: Spark job with 99% of data in one partition due to skewed join key.

**Manifestations**:
```python
# BAD — FORBIDDEN: skewed join without handling
orders_df = spark.table("orders")  # 10B rows, skewed on user_id (5% null + 10% top 100)
users_df = spark.table("users")    # 1M rows

result = orders_df.join(users_df, "user_id")  # One executor gets 99% of data
# 95th percentile task: 45 minutes; median: 30 seconds
```

**Why it's dangerous**: A single task takes orders of magnitude longer than others, causing the entire job to wait. Resource utilization is poor (one executor at 100%, others idle). Job may fail with OOM on the skewed executor.

**Correction**: Detect and mitigate skew.

```python
# GOOD — broadcast small table
from pyspark.sql.functions import broadcast

# users_df is ~100MB (1M rows * 100 bytes), fits broadcast threshold
result = orders_df.join(broadcast(users_df), "user_id")
# No shuffle on orders_df, join happens locally
```

```python
# GOOD — salt the skewed key
from pyspark.sql.functions import col, lit, rand, concat, floor

# Add salt to skewed side (orders)
SALT_BUCKETS = 50
orders_salted = orders_df.withColumn(
    "user_id_salted",
    concat(col("user_id"), lit("_"), floor(rand() * SALT_BUCKETS))
)

# Replicate small side for each salt value
from pyspark.sql.functions import explode, array

users_salted = users_df.withColumn(
    "salt",
    explode(array([lit(i) for i in range(SALT_BUCKETS)]))
).withColumn(
    "user_id_salted",
    concat(col("user_id"), lit("_"), col("salt"))
)

result = orders_salted.join(users_salted, "user_id_salted")
```

**Detection**:
```python
# Check for skew in Spark UI or via code
from pyspark.sql.functions import count

orders_df.groupBy("user_id").agg(count("*").alias("cnt")) \
    .orderBy(col("cnt").desc()) \
    .show(10)
# If top 10 user_ids have >10x average count = skew detected
```

---

### Anti-Pattern 4: Checkpoint-Neglect (CRITICAL)

**Definition**: Flink job with no checkpointing — any failure loses all processing progress.

**Manifestations**:
```java
// BAD — FORBIDDEN: no checkpointing
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
// No checkpoint configuration!

DataStream<Event> stream = env.addSource(new FlinkKafkaConsumer<>("events", schema, props));
stream.addSink(new JdbcSink<>(...));

env.execute("EventProcessor");
// TaskManager fails → all processed events lost, restart from beginning
```

**Why it's dangerous**: Without checkpoints, a TaskManager failure means reprocessing from the beginning of the Kafka topic or losing all in-flight data. For streaming jobs that run 24/7, failures are inevitable — without checkpoints, each failure is a data loss event.

**Correction**: Enable checkpointing with appropriate configuration.

```java
// GOOD — checkpointing enabled
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

// Checkpoint every 60 seconds
env.enableCheckpointing(60000);

// Checkpoint configuration
env.getCheckpointConfig().setCheckpointingMode(CheckpointingMode.EXACTLY_ONCE);
env.getCheckpointConfig().setMinPauseBetweenCheckpoints(30000);
env.getCheckpointConfig().setCheckpointTimeout(600000);
env.getCheckpointConfig().setMaxConcurrentCheckpoints(1);
env.getCheckpointConfig().enableExternalizedCheckpoints(
    ExternalizedCheckpointCleanup.RETAIN_ON_CANCELLATION
);

// State backend: RocksDB for large state
env.setStateBackend(new EmbeddedRocksDBStateBackend(true));
env.getCheckpointConfig().setCheckpointStorage("s3://bucket/checkpoints/");

DataStream<Event> stream = env.addSource(new FlinkKafkaConsumer<>("events", schema, props));
stream.addSink(JdbcSink.exactlyOnceSink(
    insertSql,
    JdbcExecutionOptions.builder()
        .withBatchSize(1000)
        .withBatchIntervalMs(200)
        .build(),
    JdbcExactlyOnceOptions.builder()
        .withTransactionPerConnection(true)
        .build(),
    () -> DriverManager.getConnection(jdbcUrl)
));
```

---

### Anti-Pattern 5: XCom-as-Queue (HIGH)

**Definition**: Airflow XCom used to pass large datasets between tasks.

**Manifestations**:
```python
# BAD — FORBIDDEN: passing DataFrame via XCom
@task
def extract():
    df = spark.read.parquet("/data/source")
    return df.toPandas().to_json()  # 100MB JSON string into XCom!

@task
def transform(data):
    df = pd.read_json(data)  # Deserialize 100MB JSON
    # ... transform ...
    return df.to_json()  # Another 100MB into XCom!
```

**Why it's dangerous**: XCom stores data in the Airflow metadata database (PostgreSQL/MySQL). Large payloads: (1) bloat the metadata DB, (2) slow down the scheduler, (3) may hit database size limits, (4) cause task failures when XCom exceeds max size.

**Correction**: Pass paths, not data.

```python
# GOOD — pass S3/path references via XCom
@task
def extract():
    df = spark.read.parquet("/data/source")
    output_path = "/data/staging/extracted"
    df.write.mode("overwrite").parquet(output_path)
    return output_path  # Small string via XCom

@task
def transform(input_path: str):
    df = spark.read.parquet(input_path)
    # ... transform ...
    output_path = "/data/staging/transformed"
    df.write.mode("overwrite").parquet(output_path)
    return output_path

@task
def load(input_path: str):
    df = spark.read.parquet(input_path)
    df.write.mode("overwrite").saveAsTable("dwd_orders")
```

---

### Anti-Pattern 6: Missing Partition Filter (CRITICAL)

**Definition**: Querying a large partitioned table without a partition filter, causing a full table scan.

**Manifestations**:
```sql
-- BAD — FORBIDDEN: no partition filter
SELECT * FROM orders WHERE status = 'completed';
-- Scans ALL partitions — 10 years of data!
```

```python
# BAD — FORBIDDEN: Spark without partition filter
spark.sql("SELECT * FROM orders WHERE user_id = '123'")
# orders is partitioned by dt — no dt filter = full scan
```

**Why it's dangerous**: Full table scan scales linearly with table growth. A query that takes 10 seconds today takes 100 seconds when data grows 10x. Production jobs fail with timeouts. Costs explode in cloud warehouses (BigQuery charges by bytes scanned).

**Correction**: Always include partition filter.

```sql
-- GOOD — partition filter included
SELECT * FROM orders
WHERE dt >= '2026-04-01' AND dt < '2026-05-01'
  AND status = 'completed';
-- Scans only April 2026 partition
```

```python
# GOOD — Spark with partition filter
spark.read \
    .format("delta") \
    .load("/data/orders") \
    .filter(col("dt") >= "2026-04-01") \
    .filter(col("dt") < "2026-05-01") \
    .filter(col("status") == "completed")
```

**Enforcement**:
```sql
-- Hive/Spark: require partition filter
SET hive.strict.checks.large.query = true;
SET hive.mapred.mode = strict;
-- Queries without partition filter are rejected
```

---

### Anti-Pattern 7: Schema Drift Blindness (HIGH)

**Definition**: Downstream consumers break when upstream schema changes without notification or compatibility assessment.

**Manifestations**:
```python
# BAD — FORBIDDEN: no schema validation at ingestion
# Source table adds 'currency_code' column
# dbt model that SELECT * silently gets new column
# Downstream BI dashboard breaks because column order changed
```

**Why it's dangerous**: Schema changes are inevitable. Without detection and notification, downstream pipelines fail silently or produce wrong results. The failure is often discovered hours or days later when stakeholders notice wrong dashboard numbers.

**Correction**: Schema validation and compatibility checks.

```python
# GOOD — schema validation at ingestion
from pyspark.sql.types import StructType, StructField

expected_schema = StructType([...])
actual_schema = df.schema

if not schema_compatible(expected_schema, actual_schema):
    raise SchemaMismatchException(
        f"Schema mismatch: expected {expected_schema}, got {actual_schema}"
    )

# dbt: explicit column selection (no SELECT *)
```

```yaml
# GOOD — dbt source freshness and schema tests
sources:
  - name: orders_db
    tables:
      - name: orders
        columns:
          - name: order_id
            tests:
              - not_null
              - unique
        freshness:
          warn_after: {count: 1, period: hour}
          error_after: {count: 2, period: hour}
```

---

### Anti-Pattern 8: Quality Gate Bypass (CRITICAL)

**Definition**: Data quality checks that warn but do not block pipeline progression.

**Manifestations**:
```python
# BAD — FORBIDDEN: warn-only quality check
result = validator.validate()
if not result["success"]:
    logger.warning("Quality check failed: %s", result)
    # Pipeline continues despite quality failure!
```

**Why it's dangerous**: A green pipeline delivering garbage data is more dangerous than a red pipeline. Downstream consumers trust the data because the pipeline succeeded. Wrong decisions are made based on corrupt data.

**Correction**: Quality gate failures must BLOCK.

```python
# GOOD — quality gate blocks pipeline
result = validator.validate()
if not result["success"]:
    raise DataQualityException(
        f"Quality gate FAILED for dwd_orders: {result}. "
        f"Downstream jobs will NOT run. Alert sent to #data-alerts."
    )
    # Pipeline stops. No downstream jobs run. Alert fired.
```

```yaml
# GOOD — dbt test failure stops execution
dbt test --select dwd_orders
# If tests fail: dbt exits with non-zero code
# CI/CD pipeline stops, deployment blocked
```
