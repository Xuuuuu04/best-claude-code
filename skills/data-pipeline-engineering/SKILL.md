---
name: data-pipeline-engineering
description: ETL/ELT pipeline engineering methodology for the Harness team. Covers data warehouse layering (ODS/DWD/DWS/ADS), idempotency patterns, quality gates, SLA design, data lineage, and architecture selection. Loaded by @data-engineer via skills: frontmatter.
type: skill
---

# Data Pipeline Engineering Skill

## 1. Pipeline Trustworthiness Triad

Every production pipeline MUST have:
1. **Idempotency**: re-running on same input produces identical output, no duplicates
2. **Quality Gates**: checks at every layer boundary that BLOCK on failure
3. **Lineage**: traceability from source to consumer at column level for critical metrics

A pipeline missing any of these three is not production-grade.

## 2. Architecture Selection

| Scale | Latency | Engine | Storage |
|-------|---------|--------|---------|
| <10 GB/day | <5 min batch | dbt + DuckDB/PostgreSQL | Native |
| >10 GB/day | Batch >5 min | Spark | Delta Lake / Iceberg |
| Any | <1 min streaming | Flink + Kafka | OLAP sink (ClickHouse/Doris) |
| Mixed | Batch + streaming | Delta Lake / Iceberg | Unified table format |

## 3. Data Warehouse Layering

### ODS — Operational Data Store
- Source fidelity, minimal transformation
- PII flagging, schema validation
- Quality gate: row count vs source, null rate, schema conformance

### DWD — Data Warehouse Detail
- Cleaned, deduplicated, SCD applied
- Business keys, referential integrity
- Quality gate: dedup verification, SCD integrity, freshness

### DWS — Data Warehouse Summary
- Pre-aggregated metrics
- Denormalized for query performance
- Quality gate: metric sanity, dimension completeness

### ADS — Application Data Store
- Consumer-specific serving layer
- SLA-bound, optimized for read patterns
- Quality gate: consumer contract validation, freshness

## 4. Idempotency Patterns

| Pattern | When to Use | Implementation |
|---------|-------------|----------------|
| INSERT OVERWRITE | Full partition replacement | Overwrite target partition |
| MERGE INTO | Upsert with deduplication | Match on business key, update or insert |
| DELETE + INSERT | Full reload of small datasets | Clear then load |
| ON CONFLICT DO NOTHING | Deduplication at sink | Skip duplicates |
| Flink exactly-once | Streaming with checkpointing | Checkpoint + 2PC sink |

Every job MUST document its re-run safety.

## 5. Quality Gates

Placed at every layer boundary. Failures BLOCK pipeline progression, not just warn.

| Check | Description | Failure Action |
|-------|-------------|----------------|
| Null rate | % NULL per column exceeds threshold | BLOCK |
| Cardinality | Distinct count within expected range | BLOCK |
| Row count | Row count vs source / vs prior run | BLOCK |
| Freshness | Data age within SLA | BLOCK |
| Schema validation | Column names/types match contract | BLOCK |
| Referential integrity | FK relationships valid | BLOCK or WARN |

## 6. SLA Design

Every pipeline MUST state SLA explicitly:
- **Batch**: completion time (e.g., "finish by 6:00 AM daily")
- **Streaming**: P50/P99 latency (e.g., "P99 < 30 seconds")

SLA is a contractual guarantee, not a hope. Design pipeline to meet it under normal load + 2x burst.

## 7. Data Lineage

Document for every critical metric:
- Source table and column
- Every transformation (job name, transformation logic)
- Target table and column
- Last verified date

Lineage enables: root cause analysis when metric is wrong, impact analysis before schema changes, compliance auditing.

## 8. PII in Analytics

NEVER write PII to analytical storage without:
- Access control documentation
- Masking/redaction strategy
- Erasure implementation path
- Retention policy

## 9. Anti-Patterns

**Select-Star**: `SELECT *` in production pipelines. Correction: explicit column lists, schema evolution-resistant.
**Non-Idempotent**: job produces duplicates on re-run. Correction: apply idempotency pattern.
**Skew-Blindness**: ignoring data skew until it causes failure. Correction: monitor skew ratio, apply salting.
**Checkpoint-Neglect**: streaming without checkpoint configuration. Correction: define checkpoint interval and state backend.
**XCom-as-Queue**: using Airflow XCom for data transfer. Correction: XCom for metadata only; data flows through storage.
**Missing-Partition-Filter**: full-table scan without partition pruning. Correction: partition filters mandatory.
**Schema-Drift**: downstream breaks silently on upstream schema change. Correction: schema contract + compatibility assessment.
**Quality-Gate-Bypass**: warnings instead of blocks on quality failure. Correction: failures BLOCK pipeline progression.
