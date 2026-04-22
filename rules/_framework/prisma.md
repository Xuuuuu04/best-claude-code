---
paths:
  - "prisma/**"
  - "**/prisma/**"
  - "src/db/**"
---

# Prisma ORM 规范

## Schema 设计

### 模型命名
- 模型：`PascalCase`，单数（`User`, `Order`）
- 字段：`camelCase`
- 关系字段：单数 1 对 1/N 对 1；复数 1 对 N/N 对 N
- 表名/列名（`@@map` / `@map`）：`snake_case`

### 主键
```prisma
model User {
  id        String   @id @default(cuid())
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

优先用 `cuid()` 或 `uuid()`，除非明确需要自增。

### 索引
```prisma
@@index([userId])
@@unique([email])
```

高频查询和排序字段必须有索引。复合索引顺序：等于条件在前、范围条件在后。

## Migration

### 绝对禁止

- **修改已部署的 migration 文件**
- 删除 migration 目录
- 手动修改 `_prisma_migrations` 表

### 正确流程

```bash
# 开发
npx prisma migrate dev --name add_user_avatar

# 生产
npx prisma migrate deploy
```

### 破坏性变更多步流程

见 `_reference/db-patterns` Skill 的数据库 migration 部分。

## 查询

### 避免 N+1

```ts
// 错误
const users = await prisma.user.findMany();
for (const user of users) {
  user.posts = await prisma.post.findMany({ where: { userId: user.id } });
}

// 正确
const users = await prisma.user.findMany({
  include: { posts: true }
});
```

### Select vs Include
- `select`：只取指定字段（推荐，明确）
- `include`：取关系字段
- 优先 `select` 显式

### 分页
```ts
// 游标分页（推荐）
prisma.user.findMany({
  take: 20,
  skip: 1,
  cursor: { id: lastId },
  orderBy: { id: 'asc' },
});

// offset 分页（小数据集）
prisma.user.findMany({
  take: 20,
  skip: page * 20,
});
```

## 事务

```ts
await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { ... } });
  await tx.order.create({ data: { userId: user.id, ... } });
});
```

### 禁止

- 事务内 HTTP 调用
- 事务内文件 I/O
- 长事务（>5s）

## 连接管理

- 一个 app 一个 PrismaClient 实例（单例）
- 在 serverless 环境需要特殊处理（避免连接数爆炸）

## Raw SQL

谨慎使用，优先 query API：

```ts
// 只在必要时
const result = await prisma.$queryRaw`SELECT * FROM users WHERE ...`;
```

**必须参数化**：
```ts
// 错误：注入风险
prisma.$queryRawUnsafe(`SELECT * FROM users WHERE id = ${userId}`)

// 正确
prisma.$queryRaw`SELECT * FROM users WHERE id = ${userId}`
```

## 测试

- 测试数据库独立（`DATABASE_URL` 测试环境不同）
- 每次测试清理：`await prisma.user.deleteMany()` 或 truncate + restart identity
- 或使用 `prisma.$transaction` 回滚模式（高级）

## 软删除

Prisma 不原生支持，通过中间件实现：

```ts
prisma.$use(async (params, next) => {
  if (params.action === 'delete') {
    params.action = 'update';
    params.args.data = { deletedAt: new Date() };
  }
  // ...
});
```

注意：并非所有场景都适合软删除（法律合规、存储成本）。

## 性能监控

- `log: ['query']` 开发环境看 SQL
- 生产环境用 Prisma 指标 + APM（Datadog / New Relic）
- 慢查询告警阈值 > 500ms

## 种子

- `prisma/seed.ts` 写种子数据
- 种子脚本幂等（可重复运行）
- 用于开发 / 测试环境，**不用于生产**
