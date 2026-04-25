---
name: db-patterns
description: 数据库设计模式参考。在设计 schema、选择索引、处理迁移或优化查询时提供查询的参考资料。
when_to_use: 当 database-engineer / implementer-backend 设计 schema、加索引、写迁移脚本、排查慢查询、做分库分表时；用户提"加表"、"改字段"、"加索引"、"迁移"、"慢查询"、"主键设计"时自动加载。
---

# 数据库设计模式参考

这是查询用的参考资料。项目特有的 schema 细节在 `project-knowledge` Skill。

---

## Schema 设计

### 命名规范

- **表**：复数名词（`users`, `orders`）
- **列**：蛇形小写（`created_at`, `user_id`）
- **主键**：`id`（或 `{table}_id` 作为外键）
- **布尔**：`is_` / `has_` 前缀（`is_active`, `has_verified`）
- **时间戳**：`_at` 后缀（`created_at`, `updated_at`, `deleted_at`）
- **外键**：`{ref_table_singular}_id`（`user_id` 引用 `users.id`）

### 数据类型选择

| 场景 | 推荐类型 |
|:--|:--|
| 主键 | `UUID`（分布式） / `BIGINT`（单库） |
| 短字符串 | `VARCHAR(n)` |
| 长文本 | `TEXT` |
| 金额 | `DECIMAL(p,s)` / 整数分 |
| 布尔 | `BOOLEAN` |
| 时间戳 | `TIMESTAMP WITH TIME ZONE` |
| 枚举 | `VARCHAR` + 应用层 enum（可移植） / `ENUM`（PG 支持） |
| JSON | `JSONB`（PG）/ `JSON`（MySQL） |

**禁止**用 `FLOAT` 存金额（精度问题）。

### 约束

- **NOT NULL** 默认，除非真的允许空
- **UNIQUE** 业务唯一性（用户名、邮箱）
- **FOREIGN KEY** 引用完整性（`ON DELETE` 策略明确）
- **CHECK** 值范围（`age >= 0`）

### 主键策略

**自增整数**：
- ✓ 简单、紧凑、排序友好
- ✗ 分布式生成困难、暴露规模

**UUID v4**：
- ✓ 分布式友好、不暴露信息
- ✗ 存储开销、B-tree 局部性差

**UUID v7 / ULID**（推荐）：
- ✓ 包含时间戳、有序、分布式友好
- ✗ 需要较新的工具支持

---

## 索引

### 何时加索引

- WHERE 子句频繁使用的列
- JOIN 的连接列（外键列）
- ORDER BY / GROUP BY 的列
- 范围查询的列

### 何时**不**加索引

- 极小表（<1000 行），全表扫描更快
- 极低基数列（如 `gender`），选择性差
- 频繁更新的列，索引维护开销大

### 复合索引顺序

**等于条件在前、范围条件在后**：
```sql
-- 查询：WHERE user_id = ? AND created_at > ?
-- 索引：(user_id, created_at)
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at);
```

### 覆盖索引

将查询用到的列都包含在索引中，避免回表：
```sql
CREATE INDEX idx_orders_user_status ON orders(user_id, status) INCLUDE (total);
```

---

## Migration

### 安全变更 vs 破坏变更

**安全**（无需多步）：
- 新增表
- 新增可空列
- 新增索引（非阻塞索引，PG: `CONCURRENTLY`）
- 重命名索引

**破坏**（需多步）：
- 删除列
- 修改列类型（特别是缩小范围）
- 修改非空约束
- 重命名列或表

### 破坏性变更的多步流程

例：将 `users.email` 从 VARCHAR(100) 改为 VARCHAR(255)：

**小变更（扩大范围）**：可以直接 `ALTER COLUMN`

**大变更（改名、改类型）**：
1. 新增新列 `email_new VARCHAR(255)`
2. 双写：代码同时写入 `email` 和 `email_new`
3. 数据迁移：`UPDATE users SET email_new = email WHERE email_new IS NULL`（分批）
4. 双读：代码优先读 `email_new`，fallback 到 `email`
5. 停止写 `email`
6. 删除 `email`，重命名 `email_new` 为 `email`

### Migration 工具

- **Prisma Migrate**：自动生成 SQL，支持 reset
- **Flyway / Liquibase**：SQL 版本化
- **Alembic**（Python）
- **Rails Migrations**（Ruby）
- **golang-migrate**（Go）

### 要求

- 每个 up 必须有 down
- Migration 应幂等（重复执行不报错）
- 大数据迁移分批（避免长事务、锁表）
- 生产 migration 先在 staging 验证

---

## 事务

### ACID

- **原子性**：全部成功或全部失败
- **一致性**：事务前后数据满足约束
- **隔离性**：并发事务互不干扰（按隔离级别）
- **持久性**：提交后永久保存

### 隔离级别

| 级别 | 脏读 | 不可重复读 | 幻读 |
|:--|:--|:--|:--|
| READ UNCOMMITTED | ✓ | ✓ | ✓ |
| READ COMMITTED | ✗ | ✓ | ✓ |
| REPEATABLE READ | ✗ | ✗ | ✓ |
| SERIALIZABLE | ✗ | ✗ | ✗ |

**默认**：PG/MySQL 是 READ COMMITTED / REPEATABLE READ

**选择**：
- 大多数场景：默认级别
- 财务核算、库存：REPEATABLE READ 或 SERIALIZABLE
- 需要最新数据：显式锁（FOR UPDATE）

### 事务原则

- **短事务**：尽快提交
- **禁止事务内 I/O**：外部 HTTP、文件写入
- **顺序加锁**：多表操作按固定顺序加锁，避免死锁
- **重试机制**：遇到死锁或冲突自动重试（有上限）

---

## 并发控制

### 乐观锁

版本号或时间戳：
```sql
UPDATE orders
SET status = 'paid', version = version + 1
WHERE id = ? AND version = ?;
```
更新失败（affected rows = 0）说明版本冲突。

**适用**：读多写少、冲突少

### 悲观锁

```sql
SELECT * FROM orders WHERE id = ? FOR UPDATE;
```

**适用**：写多、冲突多、需要强一致

### 分布式锁

- Redis（redlock）
- DB 行锁（SELECT FOR UPDATE）
- Zookeeper / etcd

注意：
- 锁持有期超时保护（防止持有者崩溃永久锁）
- 续期机制（长任务）

---

## 查询优化

### 识别慢查询

- **EXPLAIN / EXPLAIN ANALYZE**：查看执行计划
- 慢查询日志（`log_min_duration_statement`）
- APM 工具（Datadog APM, New Relic）

### 常见优化

- 添加缺失索引
- 消除 SELECT *（只查需要的列）
- JOIN 大小表时小表在前（MySQL）
- 用 EXISTS 替代 IN + 大子查询
- 分页用 cursor 而非 offset
- 避免 N+1：batch 查询或 JOIN

### 执行计划关键指标

- **Seq Scan**：全表扫描，小表可接受，大表是问题
- **Index Scan**：索引扫描，好
- **Nested Loop vs Hash Join**：数据量决定
- **rows**：预估行数，与实际偏差大说明统计信息过时

---

## 常见陷阱

- **NULL 的三值逻辑**：`NULL = NULL` 是 `UNKNOWN` 而非 `TRUE`
- **时区混乱**：存 UTC，避免存本地时间
- **字符集/编码**：使用 UTF-8，警惕旧系统的 latin1
- **大 VARCHAR 无索引**：`TEXT` 列无法普通索引
- **外键级联删除**：`ON DELETE CASCADE` 可能意外删除大量数据
- **更新依赖读**：先读后写有竞态，用 `UPDATE ... WHERE id = ? AND version = ?`

---

## 反规范化与缓存

### 反规范化

- 冗余存储避免 JOIN
- 适合读多写少
- 需要同步机制（触发器、应用层双写、CDC）

### 缓存

- **Cache-aside**：读缓存，未命中读 DB 并回填
- **Write-through**：写时同步更新
- **Write-behind**：异步更新（最终一致）

### 缓存失效

- TTL 兜底
- 显式失效（在写入后主动清除缓存）
- 标签失效（相关条目集中清除）

---

## 备份与恢复

- **全量备份 + 增量备份**（binlog / WAL）
- **定期恢复演练**（备份不演练 = 没备份）
- **跨区域复制**（关键系统）
- **Point-in-time Recovery**：恢复到任意时刻
