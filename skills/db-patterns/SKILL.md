---
name: db-patterns
description: 数据库设计模式参考。在设计 schema、选择索引、处理迁移或优化查询时提供查询的参考资料。
when_to_use: 当 资深数据库工程师 / 高级后端工程师 设计 schema、加索引、写迁移脚本、排查慢查询、做分库分表时；用户提"加表"、"改字段"、"加索引"、"迁移"、"慢查询"、"主键设计"时自动加载。
---

<skill name="db-patterns">

<identity>
这是查询用的参考资料。项目特有的 schema 细节在 `project-knowledge` Skill。
</identity>

<knowledge domain="schema-design">

<knowledge domain="naming-conventions">
<convention name="table">复数名词（`users`, `orders`）</convention>
<convention name="column">蛇形小写（`created_at`, `user_id`）</convention>
<convention name="primary-key">`id`（或 `{table}_id` 作为外键）</convention>
<convention name="boolean">`is_` / `has_` 前缀（`is_active`, `has_verified`）</convention>
<convention name="timestamp">`_at` 后缀（`created_at`, `updated_at`, `deleted_at`）</convention>
<convention name="foreign-key">`{ref_table_singular}_id`（`user_id` 引用 `users.id`）</convention>
</knowledge>

<knowledge domain="data-types">
<reference>
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
</reference>
<rule type="critical">**禁止**用 `FLOAT` 存金额（精度问题）。</rule>
</knowledge>

<knowledge domain="constraints">
<checklist>
  <item>**NOT NULL** 默认，除非真的允许空</item>
  <item>**UNIQUE** 业务唯一性（用户名、邮箱）</item>
  <item>**FOREIGN KEY** 引用完整性（`ON DELETE` 策略明确）</item>
  <item>**CHECK** 值范围（`age >= 0`）</item>
</checklist>
</knowledge>

<knowledge domain="primary-key-strategies">
<convention name="auto-increment">简单、紧凑、排序友好；但分布式生成困难、暴露规模</convention>
<convention name="uuid-v4">分布式友好、不暴露信息；但存储开销、B-tree 局部性差</convention>
<convention name="uuid-v7-ulid" recommended="true">包含时间戳、有序、分布式友好；需要较新的工具支持</convention>
</knowledge>

</knowledge>

<knowledge domain="indexing">

<knowledge domain="when-to-index">
<checklist>
  <item>WHERE 子句频繁使用的列</item>
  <item>JOIN 的连接列（外键列）</item>
  <item>ORDER BY / GROUP BY 的列</item>
  <item>范围查询的列</item>
</checklist>
</knowledge>

<knowledge domain="when-not-to-index">
<checklist>
  <item>极小表（<1000 行），全表扫描更快</item>
  <item>极低基数列（如 `gender`），选择性差</item>
  <item>频繁更新的列，索引维护开销大</item>
</checklist>
</knowledge>

<knowledge domain="composite-index-order">
<principle>等于条件在前、范围条件在后</principle>
<example>
-- 查询：WHERE user_id = ? AND created_at > ?
-- 索引：(user_id, created_at)
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at);
</example>
</knowledge>

<knowledge domain="covering-index">
<principle>将查询用到的列都包含在索引中，避免回表</principle>
<example>
CREATE INDEX idx_orders_user_status ON orders(user_id, status) INCLUDE (total);
</example>
</knowledge>

</knowledge>

<knowledge domain="migration">

<knowledge domain="safe-vs-destructive">
<convention name="safe">安全（无需多步）：新增表、新增可空列、新增索引（非阻塞索引，PG: `CONCURRENTLY`）、重命名索引</convention>
<convention name="destructive">破坏（需多步）：删除列、修改列类型（特别是缩小范围）、修改非空约束、重命名列或表</convention>
</knowledge>

<knowledge domain="destructive-change-workflow">
<principle>破坏性变更的多步流程</principle>
<checklist>
  <item seq="1">新增新列</item>
  <item seq="2">双写：代码同时写入新旧列</item>
  <item seq="3">数据迁移：分批进行</item>
  <item seq="4">双读：代码优先读新列，fallback 到旧列</item>
  <item seq="5">停止写旧列</item>
  <item seq="6">删除旧列，重命名新列</item>
</checklist>
</knowledge>

<knowledge domain="migration-tools">
<item name="Prisma Migrate">自动生成 SQL，支持 reset</item>
<item name="Flyway / Liquibase">SQL 版本化</item>
<item name="Alembic">Python</item>
<item name="Rails Migrations">Ruby</item>
<item name="golang-migrate">Go</item>
</knowledge>

<convention name="migration-requirements">
  <item>每个 up 必须有 down</item>
  <item>Migration 应幂等（重复执行不报错）</item>
  <item>大数据迁移分批（避免长事务、锁表）</item>
  <item>生产 migration 先在 staging 验证</item>
</convention>

</knowledge>

<knowledge domain="transactions">

<knowledge domain="acid">
<principle name="Atomicity">全部成功或全部失败</principle>
<principle name="Consistency">事务前后数据满足约束</principle>
<principle name="Isolation">并发事务互不干扰（按隔离级别）</principle>
<principle name="Durability">提交后永久保存</principle>
</knowledge>

<knowledge domain="isolation-levels">
<reference>
| 级别 | 脏读 | 不可重复读 | 幻读 |
|:--|:--|:--|:--|
| READ UNCOMMITTED | ✓ | ✓ | ✓ |
| READ COMMITTED | ✗ | ✓ | ✓ |
| REPEATABLE READ | ✗ | ✗ | ✓ |
| SERIALIZABLE | ✗ | ✗ | ✗ |
</reference>
<convention>默认：PG/MySQL 是 READ COMMITTED / REPEATABLE READ</convention>
<convention name="selection">大多数场景：默认级别；财务核算、库存：REPEATABLE READ 或 SERIALIZABLE；需要最新数据：显式锁（FOR UPDATE）</convention>
</knowledge>

<convention name="transaction-principles">
  <item>**短事务**：尽快提交</item>
  <item>**禁止事务内 I/O**：外部 HTTP、文件写入</item>
  <item>**顺序加锁**：多表操作按固定顺序加锁，避免死锁</item>
  <item>**重试机制**：遇到死锁或冲突自动重试（有上限）</item>
</convention>

</knowledge>

<knowledge domain="concurrency-control">

<knowledge domain="optimistic-lock">
<principle>版本号或时间戳</principle>
<example>
UPDATE orders
SET status = 'paid', version = version + 1
WHERE id = ? AND version = ?;
</example>
<convention>更新失败（affected rows = 0）说明版本冲突。适用：读多写少、冲突少</convention>
</knowledge>

<knowledge domain="pessimistic-lock">
<example>
SELECT * FROM orders WHERE id = ? FOR UPDATE;
</example>
<convention>适用：写多、冲突多、需要强一致</convention>
</knowledge>

<knowledge domain="distributed-lock">
<convention>Redis（redlock）、DB 行锁（SELECT FOR UPDATE）、Zookeeper / etcd</convention>
<trap name="lock-timeout">锁持有期超时保护（防止持有者崩溃永久锁）</trap>
<trap name="lock-renewal">续期机制（长任务）</trap>
</knowledge>

</knowledge>

<knowledge domain="query-optimization">

<knowledge domain="identify-slow-queries">
<checklist>
  <item>**EXPLAIN / EXPLAIN ANALYZE**：查看执行计划</item>
  <item>慢查询日志（`log_min_duration_statement`）</item>
  <item>APM 工具（Datadog APM, New Relic）</item>
</checklist>
</knowledge>

<knowledge domain="common-optimizations">
<checklist>
  <item>添加缺失索引</item>
  <item>消除 SELECT *（只查需要的列）</item>
  <item>JOIN 大小表时小表在前（MySQL）</item>
  <item>用 EXISTS 替代 IN + 大子查询</item>
  <item>分页用 cursor 而非 offset</item>
  <item>避免 N+1：batch 查询或 JOIN</item>
</checklist>
</knowledge>

<knowledge domain="execution-plan">
<convention name="Seq-Scan">全表扫描，小表可接受，大表是问题</convention>
<convention name="Index-Scan">索引扫描，好</convention>
<convention name="Nested-Loop-vs-Hash-Join">数据量决定</convention>
<convention name="rows">预估行数，与实际偏差大说明统计信息过时</convention>
</knowledge>

</knowledge>

<knowledge domain="common-pitfalls">
<trap name="null-three-valued">NULL 的三值逻辑：`NULL = NULL` 是 `UNKNOWN` 而非 `TRUE`</trap>
<trap name="timezone">时区混乱：存 UTC，避免存本地时间</trap>
<trap name="charset">字符集/编码：使用 UTF-8，警惕旧系统的 latin1</trap>
<trap name="text-index">大 VARCHAR 无索引：`TEXT` 列无法普通索引</trap>
<trap name="cascade-delete">外键级联删除：`ON DELETE CASCADE` 可能意外删除大量数据</trap>
<trap name="read-then-write">更新依赖读：先读后写有竞态，用 `UPDATE ... WHERE id = ? AND version = ?`</trap>
</knowledge>

<knowledge domain="denormalization-and-caching">

<knowledge domain="denormalization">
<convention>冗余存储避免 JOIN</convention>
<convention>适合读多写少</convention>
<convention>需要同步机制（触发器、应用层双写、CDC）</convention>
</knowledge>

<knowledge domain="caching-strategies">
<convention name="cache-aside">读缓存，未命中读 DB 并回填</convention>
<convention name="write-through">写时同步更新</convention>
<convention name="write-behind">异步更新（最终一致）</convention>
</knowledge>

<knowledge domain="cache-invalidation">
<convention>TTL 兜底</convention>
<convention>显式失效（在写入后主动清除缓存）</convention>
<convention>标签失效（相关条目集中清除）</convention>
</knowledge>

</knowledge>

<knowledge domain="backup-and-recovery">
<checklist>
  <item>**全量备份 + 增量备份**（binlog / WAL）</item>
  <item>**定期恢复演练**（备份不演练 = 没备份）</item>
  <item>**跨区域复制**（关键系统）</item>
  <item>**Point-in-time Recovery**：恢复到任意时刻</item>
</checklist>
</knowledge>

</skill>
