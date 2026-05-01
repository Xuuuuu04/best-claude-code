---
paths:
  - "**/*.sql"
---

<rule>
  <!-- ====== 命名 ====== -->
  <convention>表：复数名词 `users`、`orders`（或按项目约定统一）</convention>
  <convention>列：`snake_case`</convention>
  <convention>主键：`id`</convention>
  <convention>外键：`{ref}_id`（`user_id`）</convention>
  <convention>索引：`idx_{table}_{column}` 或 `idx_{table}_{col1}_{col2}`</convention>
  <convention>唯一：`uniq_{table}_{column}`</convention>
  <convention>约束：`chk_{table}_{rule}`</convention>

  <!-- ====== 格式 ====== -->
  <convention>SQL 关键字大写（`SELECT`, `FROM`, `WHERE`）</convention>
  <convention>标识符小写（表、列）</convention>
  <convention>每个子句独立一行：</convention>
  <pattern>

```sql
SELECT u.id, u.name
FROM users u
JOIN orders o ON o.user_id = u.id
WHERE u.status = 'active'
  AND o.created_at > '2026-01-01'
ORDER BY u.created_at DESC
LIMIT 20;
```

  </pattern>

  <!-- ====== 查询 ====== -->
  <constraint severity="blocker">避免 `SELECT *`（明确需要的列）</constraint>
  <constraint severity="blocker">JOIN 必明确类型：`INNER JOIN` / `LEFT JOIN` 等</constraint>
  <convention>JOIN 条件放 `ON`，筛选放 `WHERE`</convention>
  <convention>`IN (...)` 列表短；长列表用临时表或 JOIN</convention>

  <!-- ====== 索引 ====== -->
  <convention>高频 WHERE、JOIN、ORDER BY 列加索引</convention>
  <convention>复合索引顺序：等值条件在前、范围条件在后</convention>
  <convention>覆盖索引：把查询用到的字段都包含进索引</convention>
  <constraint severity="warning">不在低基数列（如 boolean）单独建索引</constraint>
  <constraint severity="warning">不过度索引（写入开销 + 存储）</constraint>

  <!-- ====== DDL ====== -->
  <convention>`CREATE TABLE IF NOT EXISTS` 幂等</convention>
  <convention>每列显式 NOT NULL 或允许 NULL（不默认）</convention>
  <convention>外键显式 `ON DELETE` / `ON UPDATE` 策略</convention>
  <convention>`CHECK` 约束保障不变量</convention>

  <!-- ====== DML ====== -->
  <constraint severity="blocker">禁止 `UPDATE` / `DELETE` 无 WHERE</constraint>
  <convention>批量操作分页：`LIMIT` + 循环</convention>
  <convention>`INSERT ... ON CONFLICT` (Postgres) / `INSERT ... ON DUPLICATE KEY` (MySQL) 幂等写入</convention>

  <!-- ====== 事务 ====== -->
  <convention>显式 `BEGIN` / `COMMIT` / `ROLLBACK`</convention>
  <constraint severity="blocker">事务内禁止慢操作（外部 HTTP、长计算）</constraint>
  <convention>锁范围最小化</convention>

  <!-- ====== 迁移（Migration） ====== -->
  <convention>每个 up 有对应 down</convention>
  <convention>破坏性变更分多步（见 `_reference/db-patterns`）</convention>
  <convention>生产大表变更：`ALTER` 阻塞评估，必要时用在线 DDL 工具（`pt-online-schema-change`, `gh-ost`）</convention>

  <!-- ====== 性能 ====== -->
  <convention>`EXPLAIN` / `EXPLAIN ANALYZE` 分析计划</convention>
  <constraint severity="warning">避免全表扫描（除非小表）</constraint>
  <convention>避免 `NOT IN` 大子查询（用 `NOT EXISTS` 或 LEFT JOIN）</convention>
  <convention>深翻页用游标而非 `OFFSET`</convention>

  <!-- ====== 安全 ====== -->
  <constraint severity="blocker">禁止字符串拼接构造 SQL（参数化查询）</constraint>
  <constraint severity="blocker">最小权限：应用账号仅授予所需权限</constraint>
  <convention>审计：敏感表操作记录</convention>
  <convention>备份：定期验证可恢复</convention>

  <!-- ====== 可读性 ====== -->
  <convention>复杂查询拆为 CTE（Common Table Expression）：</convention>
  <pattern>

```sql
WITH active_users AS (
    SELECT id FROM users WHERE status = 'active'
), recent_orders AS (
    SELECT user_id, COUNT(*) as cnt FROM orders
    WHERE created_at > NOW() - INTERVAL '30 days'
    GROUP BY user_id
)
SELECT u.name, r.cnt
FROM active_users u
JOIN recent_orders r ON r.user_id = u.id;
```

  </pattern>

  <!-- ====== 常见陷阱 ====== -->
  <constraint severity="warning">`NULL` 的三值逻辑：`NULL = NULL` 是 `UNKNOWN`，用 `IS NULL`</constraint>
  <convention>时区：存 UTC（`TIMESTAMPTZ` / `TIMESTAMP WITH TIME ZONE`）</convention>
  <convention>`DATE` vs `DATETIME` vs `TIMESTAMP`：按需选择</convention>
  <convention>整数 vs 字符串 vs UUID 主键的权衡</convention>
  <constraint severity="warning">字符集 / 排序规则：统一 UTF-8（MySQL 用 `utf8mb4`，不用 `utf8`）</constraint>

</rule>
