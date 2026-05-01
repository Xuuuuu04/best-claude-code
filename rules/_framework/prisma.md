---
paths:
  - "prisma/**"
  - "**/prisma/**"
  - "src/db/**"
---

<rule name="prisma-schema-model-naming">
  <convention>模型：PascalCase，单数（User, Order）</convention>
  <convention>字段：camelCase</convention>
  <convention>关系字段：单数 1对1/N对1；复数 1对N/N对N</convention>
  <convention>表名/列名（@@map / @map）：snake_case</convention>
</rule>

<rule name="prisma-primary-keys">
  <pattern>
    <code language="prisma">
model User {
  id        String   @id @default(cuid())
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
    </code>
  </pattern>
  <convention>优先用 cuid() 或 uuid()，除非明确需要自增。</convention>
</rule>

<rule name="prisma-indexes">
  <pattern>
    <code language="prisma">
@@index([userId])
@@unique([email])
    </code>
  </pattern>
  <constraint severity="blocker">高频查询和排序字段必须有索引。</constraint>
  <convention>复合索引顺序：等于条件在前、范围条件在后。</convention>
</rule>

<rule name="prisma-migrations">
  <constraint severity="blocker">修改已部署的 migration 文件</constraint>
  <constraint severity="blocker">删除 migration 目录</constraint>
  <constraint severity="blocker">手动修改 _prisma_migrations 表</constraint>

  <check>开发：npx prisma migrate dev --name add_user_avatar</check>
  <check>生产：npx prisma migrate deploy</check>

  <convention>破坏性变更多步流程见 _reference/db-patterns Skill 的数据库 migration 部分。</convention>
</rule>

<rule name="prisma-query-n-plus-one">
  <description>避免 N+1</description>
  <example type="bad">
    <code language="ts">
const users = await prisma.user.findMany();
for (const user of users) {
  user.posts = await prisma.post.findMany({ where: { userId: user.id } });
}
    </code>
  </example>
  <example type="good">
    <code language="ts">
const users = await prisma.user.findMany({
  include: { posts: true }
});
    </code>
  </example>
</rule>

<rule name="prisma-select-vs-include">
  <convention>select：只取指定字段（推荐，明确）</convention>
  <convention>include：取关系字段</convention>
  <convention>优先 select 显式</convention>
</rule>

<rule name="prisma-pagination">
  <pattern>
    <title>游标分页（推荐）</title>
    <code language="ts">
prisma.user.findMany({
  take: 20,
  skip: 1,
  cursor: { id: lastId },
  orderBy: { id: 'asc' },
});
    </code>
  </pattern>
  <pattern>
    <title>offset 分页（小数据集）</title>
    <code language="ts">
prisma.user.findMany({
  take: 20,
  skip: page * 20,
});
    </code>
  </pattern>
</rule>

<rule name="prisma-transactions">
  <pattern>
    <code language="ts">
await prisma.$transaction(async (tx) => {
  const user = await tx.user.create({ data: { ... } });
  await tx.order.create({ data: { userId: user.id, ... } });
});
    </code>
  </pattern>
  <constraint severity="blocker">事务内 HTTP 调用</constraint>
  <constraint severity="blocker">事务内文件 I/O</constraint>
  <constraint severity="blocker">长事务（大于5s）</constraint>
</rule>

<rule name="prisma-connection-management">
  <convention>一个 app 一个 PrismaClient 实例（单例）</convention>
  <convention>在 serverless 环境需要特殊处理（避免连接数爆炸）</convention>
</rule>

<rule name="prisma-raw-sql">
  <convention>谨慎使用，优先 query API</convention>
  <constraint severity="blocker">必须参数化</constraint>
  <example type="bad">
    <title>注入风险</title>
    <code language="ts">
prisma.$queryRawUnsafe(`SELECT * FROM users WHERE id = ${userId}`)
    </code>
  </example>
  <example type="good">
    <code language="ts">
prisma.$queryRaw`SELECT * FROM users WHERE id = ${userId}`
    </code>
  </example>
</rule>

<rule name="prisma-testing">
  <convention>测试数据库独立（DATABASE_URL 测试环境不同）</convention>
  <convention>每次测试清理：await prisma.user.deleteMany() 或 truncate + restart identity</convention>
  <convention>或使用 prisma.$transaction 回滚模式（高级）</convention>
</rule>

<rule name="prisma-soft-delete">
  <convention>Prisma 不原生支持，通过中间件实现</convention>
  <pattern>
    <code language="ts">
prisma.$use(async (params, next) => {
  if (params.action === 'delete') {
    params.action = 'update';
    params.args.data = { deletedAt: new Date() };
  }
  // ...
});
    </code>
  </pattern>
  <convention>注意：并非所有场景都适合软删除（法律合规、存储成本）。</convention>
</rule>

<rule name="prisma-performance-monitoring">
  <convention>log: ['query'] 开发环境看 SQL</convention>
  <convention>生产环境用 Prisma 指标 + APM（Datadog / New Relic）</convention>
  <convention>慢查询告警阈值大于 500ms</convention>
</rule>

<rule name="prisma-seeding">
  <convention>prisma/seed.ts 写种子数据</convention>
  <convention>种子脚本幂等（可重复运行）</convention>
  <constraint severity="blocker">用于开发 / 测试环境，不用于生产</constraint>
</rule>
