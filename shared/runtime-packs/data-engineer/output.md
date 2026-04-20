# 数据工程师 — Output Contract Reference

## Standard Output Format

```
## Data Engineering Output

**Objective**: [one sentence describing the pipeline purpose]
**Engine**: [Spark/Flink/dbt/DuckDB]
**Orchestration**: [Airflow DAG / Dagster Job / Prefect Flow]
**Storage**: [Delta Lake/Iceberg/ClickHouse/BigQuery + table path]
**SLA**: [batch completion time or streaming P50/P99]

### Delivered Files
| File | Description |
|------|-------------|
| `dags/orders_pipeline.py` | Airflow DAG: ODS → DWD → DWS |
| `models/dwd_orders.sql` | dbt model: cleaned orders |
| `models/dws_daily_revenue.sql` | dbt model: daily aggregation |
| `tests/test_orders_quality.py` | Great Expectations suite |

### Layer Design
| Layer | Table | Partition Key | Expected Row Count |
|-------|-------|---------------|-------------------|
| ODS | `ods_orders` | `dt` (daily) | 1M/day |
| DWD | `dwd_orders` | `dt` (daily) | 1M/day |
| DWS | `dws_daily_revenue` | `dt` (daily) | 1/day |
| ADS | `ads_executive_kpis` | `dt` (daily) | 1/day |

### Idempotency Design
| Job | Pattern | Re-run Safe? |
|-----|---------|--------------|
| ODS ingestion | INSERT OVERWRITE partition | Yes |
| DWD transform | MERGE INTO upsert | Yes |
| DWS aggregate | INSERT OVERWRITE partition | Yes |
| ADS serving | INSERT OVERWRITE partition | Yes |

### Data Quality Gates
| Gate | Checks | Failure Action |
|------|--------|----------------|
| ODS ingestion | Row count vs source ±5%, null rate <1%, schema match | BLOCK pipeline |
| DWD output | Duplicate count = 0, referential integrity, SCD validity | BLOCK pipeline |
| ADS delivery | Metric sanity (revenue ≥ 0), freshness < 1h | BLOCK pipeline |

### PII Handling
| Field | Tier | Masking | Access Control |
|-------|------|---------|----------------|
| customer_email | L1 | SHA-256 hash in DWD | Role-based |
| phone_number | L1 | Excluded from ADS | Restricted |
| full_name | L2 | Masked (张**) | Standard |

### Lineage Diagram
```
source_db.orders (PostgreSQL)
  → ods_orders (Delta Lake, ODS)
    → dwd_orders (Delta Lake, DWD) [dedup, SCD Type 2]
      → dws_daily_revenue (Delta Lake, DWS) [aggregation]
        → ads_executive_kpis (BigQuery, ADS) [KPI calculation]
          → Executive Dashboard (Looker)
```

**Next Steps**: [@code-review — review dbt models and Spark code]
```

## BLOCKED Output Format

```
## Data Engineering Output

**Status**: BLOCKED

**Blocked on**: [specific missing item]
**Blocked by**: [@role or user]
**Rationale**: [why this blocks pipeline design]

**What I have done**: [completed work despite block]
**What I need**: [specific unblock condition]
```

## Filled Example — Flink CDC Pipeline

```
## Data Engineering Output

**Objective**: Real-time CDC pipeline from MySQL orders to ClickHouse analytics
**Engine**: Flink 1.17 + Flink CDC 2.4
**Orchestration**: Flink Job (continuous streaming)
**Storage**: ClickHouse cluster (3 shards, 2 replicas)
**SLA**: P99 latency < 60 seconds from MySQL commit to ClickHouse queryable

### Delivered Files
| File | Description |
|------|-------------|
| `flink/OrdersCdcJob.java` | Flink job: MySQL CDC → dedup → ClickHouse sink |
| `clickhouse/orders_distributed.sql` | Distributed table DDL |
| `clickhouse/orders_local.sql` | Local ReplicatedMergeTree DDL |
| `docker/flink-cluster.yml` | Flink JobManager + TaskManager compose |

### Layer Design
| Layer | Table | Engine | Partition Key |
|-------|-------|--------|---------------|
| ODS | `ods_orders_raw` | Kafka topic | Event time |
| DWD | `dwd_orders` | ClickHouse ReplicatedMergeTree | `toYYYYMM(created_at)` |
| ADS | `ads_order_summary` | ClickHouse SummingMergeTree | `toYYYYMM(created_at)` |

### Idempotency Design
| Job | Pattern | Re-run Safe? |
|-----|---------|--------------|
| CDC source | Flink exactly-once + Kafka transactional producer | Yes |
| ClickHouse sink | ReplacingMergeTree + `version` column | Yes (dedup on reprocessing) |

### Data Quality Gates
| Gate | Checks | Failure Action |
|------|--------|----------------|
| CDC lag | Consumer lag < 1000 messages | Alert if exceeded |
| DWD freshness | `max(created_at)` within 5 min of now | Alert if stale |
| DWD dedup | Duplicate `order_id` count = 0 | Alert if > 0 |

### PII Handling
| Field | Tier | Strategy |
|-------|------|----------|
| customer_email | L1 | SHA-256 hash in DWD, excluded from ADS |
| shipping_address | L2 | Masked in ADS, full in encrypted backup |

### Lineage Diagram
```
MySQL binlog (orders table)
  → Flink CDC Source (Debezium)
    → Kafka topic: ods_orders_raw
      → Flink Processing (dedup, transform)
        → ClickHouse: dwd_orders (ReplacingMergeTree)
          → Materialized View: ads_order_summary
            → BI Dashboard (Grafana)
```

**Next Steps**: [@code-review — review Flink job checkpoint configuration]
```
