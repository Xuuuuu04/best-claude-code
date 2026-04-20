---
source: agents/data-engineer.md
copied: 2026-04-21
note: Real-time streaming pipeline domain knowledge (Flink, Kafka, CDC).
---

# Data Engineer — Streaming & CDC Domain

## Flink CDC Pipeline Architecture

### Component Topology

```
MySQL (binlog) → Flink CDC Connector → Kafka (buffer) → Flink Job → ClickHouse/Doris
                                      ↑
                               Exactly-once guarantee
                               (checkpoint + 2PC)
```

### MySQL Prerequisites

```sql
-- Enable binlog (my.cnf)
[mysqld]
server-id=1
log_bin=mysql-bin
binlog_format=ROW
binlog_row_image=FULL
gtid_mode=ON
enforce_gtid_consistency=ON

-- Create replication user
CREATE USER 'flink_cdc'@'%' IDENTIFIED BY 'password';
GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'flink_cdc'@'%';
FLUSH PRIVILEGES;

-- Verify binlog is enabled
SHOW VARIABLES LIKE 'log_bin';        -- Should be ON
SHOW VARIABLES LIKE 'binlog_format';  -- Should be ROW
```

### Flink CDC Job (Java/Scala)

```java
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import com.ververica.cdc.connectors.mysql.source.MySqlSource;
import com.ververica.cdc.debezium.JsonDebeziumDeserializationSchema;

StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

// Checkpoint configuration
env.enableCheckpointing(60000);  // 60s interval
env.getCheckpointConfig().setCheckpointingMode(CheckpointingMode.EXACTLY_ONCE);
env.getCheckpointConfig().setMinPauseBetweenCheckpoints(30000);
env.setStateBackend(new EmbeddedRocksDBStateBackend(true));
env.getCheckpointConfig().setCheckpointStorage("s3://bucket/checkpoints/");

// MySQL CDC Source
MySqlSource<String> mySqlSource = MySqlSource.<String>builder()
    .hostname("mysql-host")
    .port(3306)
    .databaseList("mydb")
    .tableList("mydb.orders")
    .username("flink_cdc")
    .password("password")
    .deserializer(new JsonDebeziumDeserializationSchema())
    .startupOptions(StartupOptions.initial())  // Full snapshot + incremental
    .build();

// Kafka Sink (buffer layer)
KafkaSink<String> kafkaSink = KafkaSink.<String>builder()
    .setBootstrapServers("kafka:9092")
    .setRecordSerializer(KafkaRecordSerializationSchema.builder()
        .setTopic("ods_orders_raw")
        .setValueSerializationSchema(new SimpleStringSchema())
        .build())
    .setDeliveryGuarantee(DeliveryGuarantee.EXACTLY_ONCE)
    .setTransactionalIdPrefix("flink-cdc-orders-")
    .build();

// Pipeline
env.fromSource(mySqlSource, WatermarkStrategy.noWatermarks(), "MySQL CDC Source")
   .sinkTo(kafkaSink);

env.execute("MySQL CDC to Kafka");
```

### Kafka → ClickHouse (Flink Processing)

```java
// Read from Kafka
KafkaSource<OrderEvent> kafkaSource = KafkaSource.<OrderEvent>builder()
    .setBootstrapServers("kafka:9092")
    .setTopics("ods_orders_raw")
    .setStartingOffsets(OffsetsInitializer.earliest())
    .setValueOnlyDeserializer(new OrderEventDeserializationSchema())
    .build();

// Deduplication with state (5-minute window)
DataStream<OrderEvent> deduplicated = env.fromSource(kafkaSource, WatermarkStrategy
    .<OrderEvent>forBoundedOutOfOrderness(Duration.ofSeconds(30))
    .withTimestampAssigner((event, timestamp) -> event.getCreatedAt().getTime()), "Kafka Source")
    .keyBy(OrderEvent::getOrderId)
    .process(new DeduplicateFunction(Duration.ofMinutes(5)));

// ClickHouse Sink (JDBC with exactly-once)
JdbcExecutionOptions executionOptions = JdbcExecutionOptions.builder()
    .withBatchSize(1000)
    .withBatchIntervalMs(200)
    .build();

JdbcExactlyOnceOptions exactlyOnceOptions = JdbcExactlyOnceOptions.builder()
    .withTransactionPerConnection(true)
    .build();

deduplicated.addSink(JdbcSink.exactlyOnceSink(
    "INSERT INTO dwd_orders (order_id, user_id, amount, status, created_at, _version) " +
    "VALUES (?, ?, ?, ?, ?, ?)",
    (ps, event) -> {
        ps.setString(1, event.getOrderId());
        ps.setString(2, event.getUserId());
        ps.setBigDecimal(3, event.getAmount());
        ps.setString(4, event.getStatus());
        ps.setTimestamp(5, new Timestamp(event.getCreatedAt().getTime()));
        ps.setLong(6, System.currentTimeMillis());
    },
    executionOptions,
    exactlyOnceOptions,
    () -> DriverManager.getConnection("jdbc:clickhouse://clickhouse:8123/mydb")
));
```

---

## Kafka Configuration for Data Pipelines

### Topic Design

```bash
# Create topic with optimal settings for CDC
kafka-topics.sh --bootstrap-server kafka:9092 --create \
  --topic ods_orders_raw \
  --partitions 12 \
  --replication-factor 3 \
  --config retention.ms=604800000 \
  --config min.insync.replicas=2 \
  --config compression.type=lz4

# Partition strategy:
# - CDC events: partition by primary key (order_id) for ordering guarantee
# - Logs/metrics: partition by hash for even distribution
# - Time-series: partition by time bucket (day/hour)
```

### Consumer Group Tuning

```java
Properties props = new Properties();
props.put("bootstrap.servers", "kafka:9092");
props.put("group.id", "flink-dwd-processor");
props.put("auto.offset.reset", "earliest");
props.put("enable.auto.commit", "false");  // Flink manages offsets
props.put("max.poll.records", 500);        // Balance latency vs throughput
props.put("fetch.min.bytes", 1048576);     // 1MB min fetch
props.put("fetch.max.wait.ms", 500);       // 500ms max wait
```

---

## Exactly-Once Semantics Checklist

```markdown
## Exactly-Once Pipeline Verification

### Source (CDC)
- [ ] MySQL binlog format = ROW
- [ ] MySQL binlog_row_image = FULL
- [ ] GTID enabled for failover consistency
- [ ] Flink CDC startup option confirmed (initial/latest)

### Buffer (Kafka)
- [ ] Topic replication factor >= 2
- [ ] min.insync.replicas >= 2
- [ ] Producer acks = all
- [ ] Enable idempotent producer
- [ ] Transactional IDs configured

### Processing (Flink)
- [ ] Checkpointing enabled with interval <= 60s
- [ ] Checkpoint mode = EXACTLY_ONCE
- [ ] State backend = RocksDB (for large state)
- [ ] Checkpoint storage = durable (S3/HDFS)
- [ ] Max concurrent checkpoints = 1
- [ ] Min pause between checkpoints >= 30s

### Sink (ClickHouse/Doris)
- [ ] JDBC exactly-once sink configured
- [ ] Transaction per connection enabled
- [ ] Batch size <= 5000 (prevent transaction timeout)
- [ ] Idempotency key in target table (_version or event_time)

### Verification Test
1. Stop Flink job mid-batch
2. Restart from latest checkpoint
3. Verify: no duplicate rows in target
4. Verify: no missing rows in target
5. Verify: Kafka consumer lag recovers to near-zero
```

---

## Streaming Pipeline Monitoring

### Key Metrics

| Metric | Alert Threshold | Meaning |
|--------|----------------|---------|
| Consumer Lag | > 10000 messages | Pipeline cannot keep up with source |
| Checkpoint Duration | > 80% of interval | Checkpoint may fail/timeout |
| Failed Checkpoints | > 0 in 5 min | Data loss risk |
| Task Backpressure | > 50% | Downstream cannot keep up |
| Records Per Second | Drop > 50% | Source or processing issue |

### Flink REST API Monitoring

```bash
# Job overview
 curl http://flink-jobmanager:8081/jobs

# Checkpoint stats
 curl http://flink-jobmanager:8081/jobs/{jobId}/checkpoints

# Task backpressure
 curl http://flink-jobmanager:8081/jobs/{jobId}/vertices/{vertexId}/backpressure

# Kafka consumer lag
kafka-consumer-groups.sh --bootstrap-server kafka:9092 \
  --describe --group flink-dwd-processor
```

---

## ClickHouse Sink Optimization

### Table Engine Selection

```sql
-- DWD layer: deduplicated events
CREATE TABLE dwd_orders (
    order_id String,
    user_id String,
    amount Decimal(10, 2),
    status String,
    created_at DateTime64(3),
    _version UInt64,
    _sign Int8 DEFAULT 1
) ENGINE = ReplacingMergeTree(_version)
PARTITION BY toYYYYMM(created_at)
ORDER BY (order_id, created_at);

-- ADS layer: pre-aggregated metrics
CREATE TABLE ads_daily_summary (
    date Date,
    status String,
    order_count UInt64,
    total_amount Decimal(18, 2)
) ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, status);

-- Materialized view for aggregation
CREATE MATERIALIZED VIEW ads_daily_summary_mv
TO ads_daily_summary
AS SELECT
    toDate(created_at) as date,
    status,
    count() as order_count,
    sum(amount) as total_amount
FROM dwd_orders
GROUP BY date, status;
```

### Bulk Insert Optimization

```python
# ClickHouse native protocol (faster than JDBC)
from clickhouse_driver import Client

client = Client('clickhouse-host', database='mydb')

# Batch insert
client.execute(
    'INSERT INTO dwd_orders (order_id, user_id, amount, status, created_at, _version) VALUES',
    batch_data,  # List of tuples
    types_check=True
)

# Async insert for high throughput
client.execute(
    'INSERT INTO dwd_orders VALUES',
    batch_data,
    settings={'async_insert': 1, 'wait_for_async_insert': 0}
)
```
