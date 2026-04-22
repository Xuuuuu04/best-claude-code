---
paths:
  - "**/*.sql"
---

# SQL 编码规范

## 命名

- 表：复数名词 `users`、`orders`（或按项目约定统一）
- 列：`snake_case`
- 主键：`id`
- 外键：`{ref}_id`（`user_id`）
- 索引：`idx_{table}_{column}` 或 `idx_{table}_{col1}_{col2}`
- 唯一：`uniq_{table}_{column}`
- 约束：`chk_{table}_{rule}`

## 格式

- SQL 关键字**大写**（`SELECT`, `FROM`, `WHERE`）
- 标识符小写（表、列）
- 每个子句独立一行：
  ```sql
  SELECT u.id, u.name
  FROM users u
  JOIN orders o ON o.user_id = u.id
  WHERE u.status = 'active'
    AND o.created_at > '2026-01-01'
  ORDER BY u.created_at DESC
  LIMIT 20;
  ```

## 查询

- **避免** `SELECT *`（明确需要的列）
- JOIN 必明确类型：`INNER JOIN` / `LEFT JOIN` 等
- JOIN 条件放 `ON`，筛选放 `WHERE`
- `IN (...)` 列表短；长列表用临时表或 JOIN

## 索引

- 高频 WHERE、JOIN、ORDER BY 列加索引
- 复合索引顺序：等值条件在前、范围条件在后
- 覆盖索引：把查询用到的字段都包含进索引
- **不**在低基数列（如 boolean）单独建索引
- **不**过度索引（写入开销 + 存储）

## DDL

- `CREATE TABLE IF NOT EXISTS` 幂等
- 每列显式 NOT NULL 或允许 NULL（不默认）
- 外键显式 `ON DELETE` / `ON UPDATE` 策略
- `CHECK` 约束保障不变量

## DML

- **禁止** `UPDATE` / `DELETE` 无 WHERE
- 批量操作分页：`LIMIT` + 循环
- `INSERT ... ON CONFLICT` (Postgres) / `INSERT ... ON DUPLICATE KEY` (MySQL) 幂等写入

## 事务

- 显式 `BEGIN` / `COMMIT` / `ROLLBACK`
- 事务内禁止慢操作（外部 HTTP、长计算）
- 锁范围最小化

## 迁移（Migration）

- 每个 up 有对应 down
- 破坏性变更分多步（见 `_reference/db-patterns`）
- 生产大表变更：`ALTER` 阻塞评估，必要时用在线 DDL 工具（`pt-online-schema-change`, `gh-ost`）

## 性能

- `EXPLAIN` / `EXPLAIN ANALYZE` 分析计划
- 避免全表扫描（除非小表）
- 避免 `NOT IN` 大子查询（用 `NOT EXISTS` 或 LEFT JOIN）
- 深翻页用游标而非 `OFFSET`

## 安全

- **禁止** 字符串拼接构造 SQL（参数化查询）
- 最小权限：应用账号仅授予所需权限
- 审计：敏感表操作记录
- 备份：定期验证可恢复

## 可读性

- 复杂查询拆为 CTE（Common Table Expression）：
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

## 常见陷阱

- `NULL` 的三值逻辑：`NULL = NULL` 是 `UNKNOWN`，用 `IS NULL`
- 时区：存 UTC（`TIMESTAMPTZ` / `TIMESTAMP WITH TIME ZONE`）
- `DATE` vs `DATETIME` vs `TIMESTAMP`：按需选择
- 整数 vs 字符串 vs UUID 主键的权衡
- 字符集 / 排序规则：统一 UTF-8（MySQL 用 `utf8mb4`，不用 `utf8`）
