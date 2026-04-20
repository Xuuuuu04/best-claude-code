---
source: agents/data-engineer.md
copied: 2026-04-21
note: Batch processing and Spark optimization domain knowledge.
---

# Data Engineer — Batch Processing Domain

## Spark Job Optimization

### Join Strategy Selection

| Join Type | When to Use | Memory Impact | Shuffle? |
|-----------|-------------|---------------|----------|
| Broadcast Hash Join | Small table < 10MB | Driver memory | No |
| Shuffle Hash Join | Medium table, no sort needed | Executor memory | Yes |
| Sort-Merge Join | Large tables, sorted keys | Minimal | Yes |
| Cartesian Join | Cross join (avoid if possible) | Extreme | Yes |

```python
from pyspark.sql.functions import broadcast

# Force broadcast join for small dimension table
result = large_df.join(broadcast(small_df), "join_key")

# Config: increase broadcast threshold (default 10MB)
spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "200MB")

# Verify join strategy
result.explain()
# Look for: "BroadcastHashJoin" (good) or "SortMergeJoin" (default for large)
```

### Data Skew Handling

```python
from pyspark.sql.functions import col, lit, rand, concat, floor

# Detection
skew_df = orders_df.groupBy("user_id").count().orderBy(col("count").desc())
skew_df.show(10)
# If top 10 user_ids have >10x average count = skew detected

# Solution 1: Salt the skewed key
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

# Solution 2: Adaptive Query Execution (Spark 3.0+)
spark.conf.set("spark.sql.adaptive.enabled", "true")
spark.conf.set("spark.sql.adaptive.skewJoin.enabled", "true")
spark.conf.set("spark.sql.adaptive.skewJoin.skewedPartitionFactor", "5")
spark.conf.set("spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes", "256MB")
```

### Partition Tuning

```python
# Default shuffle partitions (often too high for small data, too low for large)
# Rule: 2-3 tasks per CPU core, or ~128MB per partition

total_input_gb = 500  # Estimate
target_partition_mb = 128
shuffle_partitions = int((total_input_gb * 1024) / target_partition_mb)

spark.conf.set("spark.sql.shuffle.partitions", str(shuffle_partitions))
spark.conf.set("spark.default.parallelism", str(shuffle_partitions))

# Coalesce before writing (reduce small files)
df.coalesce(50).write.parquet("/output/path")

# Repartition by key for sorted output
df.repartition("date").sortWithinPartitions("timestamp").write.parquet("/output/path")
```

---

## Delta Lake Operations

### Table Optimization

```python
from delta.tables import DeltaTable

# Get Delta table
delta_table = DeltaTable.forPath(spark, "/data/dwd/orders")

# File compaction (merge small files)
delta_table.optimize().executeZOrderBy("user_id", "created_at")

# Clean old snapshots
spark.sql("VACUUM dwd_orders RETAIN 168 HOURS")  # 7 days

# Describe history
spark.sql("DESCRIBE HISTORY dwd_orders").show()

# Time travel query
spark.read.format("delta").option("versionAsOf", 42).load("/data/dwd/orders")
spark.read.format("delta").option("timestampAsOf", "2026-04-21T00:00:00Z").load("/data/dwd/orders")
```

### Merge (Upsert) Pattern

```python
from delta.tables import DeltaTable

# Idempotent merge: insert new, update existing
delta_table.alias("target").merge(
    updates_df.alias("source"),
    "target.order_id = source.order_id AND target.dt = source.dt"
).whenMatchedUpdateAll() \
 .whenNotMatchedInsertAll() \
 .execute()

# Conditional merge: only update if version is newer
delta_table.alias("target").merge(
    updates_df.alias("source"),
    "target.order_id = source.order_id"
).whenMatchedUpdateAll(
    condition="source._version > target._version"
).whenNotMatchedInsertAll() \
 .execute()
```

---

## dbt Project Structure

### Recommended Directory Layout

```
models/
  staging/           # 1:1 with source tables, minimal transformation
    stg_orders.sql
    stg_users.sql
  intermediate/      # Business logic, joins, aggregations
    int_orders_enriched.sql
    int_user_metrics.sql
  marts/             # Final models for consumers
    fct_orders.sql
    dim_users.sql
    rpt_daily_revenue.sql
  sources.yml        # Source definitions
  schema.yml         # Tests and documentation

seeds/               # Static reference data (CSV)
  country_codes.csv

snapshots/           # SCD Type 2
  snap_users.sql

tests/               # Custom data tests
  assert_positive_revenue.sql

macros/              # Reusable SQL
  cents_to_dollars.sql
  generate_schema_name.sql

dbt_project.yml      # Project config
packages.yml         # Dependencies
```

### dbt Model Configuration

```sql
-- models/marts/fct_orders.sql
{{ config(
    materialized='incremental',
    unique_key='order_id',
    partition_by={
      "field": "created_at",
      "data_type": "timestamp",
      "granularity": "day"
    },
    cluster_by=["status", "user_id"]
) }}

SELECT
    order_id,
    user_id,
    amount,
    status,
    created_at,
    updated_at
FROM {{ ref('int_orders_enriched') }}

{% if is_incremental() %}
WHERE created_at >= (SELECT MAX(created_at) FROM {{ this }})
{% endif %}
```

### dbt Tests

```yaml
# models/schema.yml
version: 2

models:
  - name: fct_orders
    columns:
      - name: order_id
        tests:
          - unique
          - not_null
      - name: amount
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: ">= 0"
      - name: status
        tests:
          - accepted_values:
              values: ['pending', 'completed', 'cancelled', 'refunded']
      - name: user_id
        tests:
          - relationships:
              to: ref('dim_users')
              field: user_id

  - name: dim_users
    columns:
      - name: user_id
        tests:
          - unique
          - not_null
```

---

## Data Quality Framework

### Great Expectations Suite

```python
import great_expectations as gx

context = gx.get_context()

# Create expectation suite
suite = context.add_expectation_suite("orders_suite")

# Add expectations
datasource = context.get_datasource("my_datasource")
batch = datasource.get_batch(batch_request={"datasource_name": "my_datasource", "data_asset_name": "orders"})

validator = context.get_validator(
    batch_request={"datasource_name": "my_datasource", "data_asset_name": "orders"},
    expectation_suite=suite
)

validator.expect_column_values_to_not_null("order_id")
validator.expect_column_values_to_be_unique("order_id")
validator.expect_column_values_to_be_between("amount", min_value=0)
validator.expect_column_values_to_be_in_set("status", ["pending", "completed", "cancelled"])
validator.expect_table_row_count_to_be_between(min_value=1000, max_value=10000000)

# Save suite
validator.save_expectation_suite(discard_failed_expectations=False)

# Run checkpoint
context.add_checkpoint(
    name="orders_checkpoint",
    validator=validator,
    action_list=[
        {"name": "store_validation_result", "action": {"class_name": "StoreValidationResultAction"}},
        {"name": "update_data_docs", "action": {"class_name": "UpdateDataDocsAction"}},
    ]
)
result = context.run_checkpoint(checkpoint_name="orders_checkpoint")
```

### Custom Quality Gate (Python)

```python
from dataclasses import dataclass
from typing import List, Dict

@dataclass
class QualityCheck:
    name: str
    query: str
    threshold: float
    operator: str  # '>', '<', '==', '!='

def run_quality_gate(conn, checks: List[QualityCheck]) -> Dict:
    """Run quality checks and return PASS/FAIL results."""
    results = {}
    all_passed = True
    
    for check in checks:
        result = conn.execute(check.query).scalar()
        passed = eval(f"{result} {check.operator} {check.threshold}")
        results[check.name] = {
            "value": result,
            "threshold": check.threshold,
            "passed": passed
        }
        if not passed:
            all_passed = False
    
    return {
        "all_passed": all_passed,
        "checks": results,
        "timestamp": datetime.utcnow().isoformat()
    }

# Usage
checks = [
    QualityCheck("null_rate", "SELECT AVG(CASE WHEN amount IS NULL THEN 1.0 ELSE 0.0 END) FROM dwd_orders", 0.01, "<"),
    QualityCheck("duplicate_rate", "SELECT COUNT(*) - COUNT(DISTINCT order_id) FROM dwd_orders", 0, "=="),
    QualityCheck("freshness", "SELECT EXTRACT(EPOCH FROM (NOW() - MAX(created_at))) / 3600 FROM dwd_orders", 1, "<"),
]
```

---

## Airflow DAG Patterns

### Idempotent Batch DAG

```python
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator
from airflow.sensors.external_task import ExternalTaskSensor
from datetime import datetime, timedelta

default_args = {
    'owner': 'data-engineering',
    'depends_on_past': False,
    'email_on_failure': True,
    'email': ['data-alerts@company.com'],
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'daily_etl_pipeline',
    default_args=default_args,
    description='Daily ETL: ODS → DWD → ADS',
    schedule_interval='0 2 * * *',  # 2 AM daily
    start_date=datetime(2026, 1, 1),
    catchup=False,
    max_active_runs=1,
    tags=['etl', 'daily'],
) as dag:

    # Wait for upstream data readiness
    wait_for_upstream = ExternalTaskSensor(
        task_id='wait_for_source_data',
        external_dag_id='source_data_load',
        external_task_id='load_complete',
        timeout=3600,
        poke_interval=300,
    )

    # ODS → DWD transformation
    dwd_transform = BashOperator(
        task_id='dwd_transform',
        bash_command='''
            spark-submit \
              --master yarn \
              --deploy-mode cluster \
              --conf spark.sql.shuffle.partitions=200 \
              /opt/jobs/dwd_transform.py \
              --date {{ ds }}
        ''',
    )

    # Data quality check
    quality_check = BashOperator(
        task_id='quality_check',
        bash_command='''
            python /opt/jobs/quality_check.py \
              --table dwd_orders \
              --date {{ ds }}
        ''',
    )

    # DWD → ADS aggregation
    ads_aggregate = BashOperator(
        task_id='ads_aggregate',
        bash_command='''
            dbt run \
              --models marts.daily_revenue \
              --vars '{"execution_date": "{{ ds }}"}'
        ''',
    )

    # Task dependencies
    wait_for_upstream >> dwd_transform >> quality_check >> ads_aggregate
```

### Dynamic Task Mapping (Airflow 2.3+)

```python
from airflow.decorators import task, dag
from datetime import datetime

@dag(start_date=datetime(2026, 1, 1), schedule=None, catchup=False)
def backfill_partitions():

    @task
    def get_partitions():
        """Return list of partition dates to process."""
        from datetime import datetime, timedelta
        start = datetime(2026, 3, 1)
        end = datetime(2026, 3, 30)
        return [(start + timedelta(days=i)).strftime('%Y-%m-%d') 
                for i in range((end - start).days + 1)]

    @task
    def process_partition(partition_date: str):
        """Process a single partition."""
        import subprocess
        subprocess.run([
            'dbt', 'run',
            '--models', 'staging.orders',
            '--vars', f'{{"partition_date": "{partition_date}"}}'
        ], check=True)
        return f"Processed {partition_date}"

    partitions = get_partitions()
    process_partition.expand(partition_date=partitions)

backfill_dag = backfill_partitions()
```
