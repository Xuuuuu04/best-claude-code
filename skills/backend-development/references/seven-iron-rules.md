# 后端 7 条铁律 + 3 层架构

> **来源 attribution**：本文档内容综合自以下 MIT 许可的开源 skill：
> - [MiniMax-AI/skills · fullstack-dev](https://github.com/MiniMax-AI/skills/tree/main/skills/fullstack-dev) — MIT
> - 《The Twelve-Factor App》(12factor.net)
> - 《Clean Architecture》Robert C. Martin
> - 《Patterns of Enterprise Application Architecture》Martin Fowler
> - Google SRE Handbook
>
> 本文档保留方法论与"7 Iron Rules"原则，已根据 Agent Legion 高级后端工程师 工作流改写。

适用：高级后端工程师 在搭建新服务、改造既有服务、code review 时。

---

## 7 条铁律

```
1. ✅ 按 FEATURE 组织目录，不按技术 layer
2. ✅ Controller 永远不含业务逻辑
3. ✅ Service 永远不引入 HTTP 请求/响应类型
4. ✅ 所有配置从 env 读，启动时验证，fail fast
5. ✅ 每个错误都是 typed、被记录、返回一致格式
6. ✅ 所有输入在边界处验证——绝不信任来自客户端的数据
7. ✅ 结构化 JSON 日志 + request ID——不用 console.log
```

---

## 3 层架构

```
Controller (HTTP) → Service (业务逻辑) → Repository (数据访问)
```

| 层 | 职责 | ❌ 绝不 |
|:--|:--|:--|
| Controller | 解析请求、验证、调 service、格式化响应 | 业务逻辑、DB 查询 |
| Service | 业务规则、编排、事务管理 | HTTP 类型 (req/res)、直接 DB |
| Repository | DB 查询、外部 API | 业务逻辑、HTTP 类型 |

---

## Feature-First 目录组织

```
✅ Feature-first              ❌ Layer-first
src/                          src/
  orders/                       controllers/
    order.controller.ts           order.controller.ts
    order.service.ts              user.controller.ts
    order.repository.ts         services/
    order.dto.ts                  order.service.ts
    order.test.ts                 user.service.ts
  users/                        repositories/
    user.controller.ts            order.repository.ts
    user.service.ts               user.repository.ts
  shared/
    database/
    middleware/
```

理由：feature-first 让一个功能的所有代码集中在一个目录——重构、删除整个 feature 都简单。layer-first 让你为改一个 feature 跳 5 个目录。

---

## 依赖注入（跨语言一致）

### TypeScript
```typescript
class OrderService {
  constructor(
    private readonly orderRepo: OrderRepository,    // ✅ 注入接口
    private readonly emailService: EmailService,
  ) {}
}
```

### Python
```python
class OrderService:
    def __init__(self, order_repo: OrderRepository, email_service: EmailService):
        self.order_repo = order_repo
        self.email_service = email_service
```

### Go
```go
type OrderService struct {
    orderRepo    OrderRepository    // ✅ 接口
    emailService EmailService
}
func NewOrderService(repo OrderRepository, email EmailService) *OrderService {
    return &OrderService{orderRepo: repo, emailService: email}
}
```

理由：DI 让单元测试能用 mock，让实现可替换。**不要直接 import 具体实现**——import 接口。

---

## 新服务启动 Checklist

- [ ] 项目按 **feature-first** 结构搭好
- [ ] 配置**集中**，env vars 启动时验证（**fail fast**）
- [ ] **typed error 层级**已定义（不是泛 `Error`）
- [ ] **全局错误处理** middleware 在位
- [ ] **结构化 JSON 日志** + request ID 透传
- [ ] DB **migrations** 设置、**connection pooling** 配置
- [ ] 所有端点有**输入验证**（Zod / Pydantic / Go validator）
- [ ] **认证中间件**在位
- [ ] **健康检查**端点（`/health`、`/ready`）
- [ ] 优雅停机（**SIGTERM**）
- [ ] **CORS** 配显式 origins（不是 `*`）
- [ ] 安全 headers（helmet 或等价）
- [ ] `.env.example` 提交（无真实 secret）

## Frontend-Backend 集成 Checklist

- [ ] **API 客户端**配置（typed fetch wrapper / React Query / tRPC / OpenAPI generated）
- [ ] **base URL** 来自环境变量（不硬编码）
- [ ] **auth token** 自动附加（拦截器 / middleware）
- [ ] **错误处理**——API 错误映射到用户可见消息
- [ ] **loading state** 处理（skeleton / spinner，不是空白屏）
- [ ] **类型安全**跨边界（共享类型 / OpenAPI / tRPC）
- [ ] **CORS** 生产用显式 origins（不是 `*`）
- [ ] **refresh token** 流程（httpOnly cookie + 401 透明重试）

---

## 错误处理：typed 层级

错误：
```ts
// ✗ throw new Error('something wrong')
// ✗ throw 'order not found'
```

正确：
```ts
class DomainError extends Error { /* 基类 */ }
class OrderNotFoundError extends DomainError {}
class InsufficientStockError extends DomainError {}
class ExternalServiceError extends DomainError {}
class ValidationError extends DomainError {}

// service 层
if (!order) throw new OrderNotFoundError(`order ${id}`);

// 全局错误中间件
if (err instanceof OrderNotFoundError) return res.status(404).json({...});
if (err instanceof ValidationError)    return res.status(422).json({...});
if (err instanceof DomainError)         return res.status(400).json({...});
return res.status(500).json({code: 'INTERNAL_ERROR'}); // 兜底
```

---

## 配置：fail fast

```ts
// config.ts —— 启动时立刻验证
import { z } from 'zod';

const ConfigSchema = z.object({
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  REDIS_URL: z.string().url().optional(),
});

export const config = ConfigSchema.parse(process.env);
// ↑ 缺 / 不合法 → 立刻退出，不要运行半截
```

---

## 日志：结构化 + 请求 ID

```ts
// ✗ console.log("user " + userId + " bought " + orderId);

// ✓ 结构化 JSON
logger.info({
  event: 'order.created',
  userId,
  orderId,
  amount: order.total,
  requestId: req.id,    // ← 关键，跨服务追踪
}, 'Order created');
```

请求 ID 由 middleware 生成（uuid），透传到所有下游服务（HTTP header、DB query、queue message）。

---

## 输入验证（边界处）

每个 API 端点入口都验证：

```ts
const CreateOrderSchema = z.object({
  productId: z.string().uuid(),
  quantity: z.number().int().positive().max(1000),
  shippingAddress: z.object({ ... })
});

router.post('/orders', (req, res) => {
  const dto = CreateOrderSchema.parse(req.body);   // ← 不合法直接 throw
  const order = await orderService.createOrder(dto);
  res.json(order);
});
```

理由：service 层从此可以**信任**输入。所有"防御性编程"集中在边界。

---

## 生产硬化清单

- [ ] 优雅停机：捕获 SIGTERM，关 server / drain 连接 / flush logs
- [ ] DB pool：配 max connections、idle timeout、acquire timeout
- [ ] Rate limiting：按 IP / API key / user
- [ ] Circuit breaker（外部依赖）
- [ ] Retry with exponential backoff（幂等操作）
- [ ] Health check 区分 liveness vs readiness
- [ ] Metrics 暴露（Prometheus / DataDog）
- [ ] Sentry / Bugsnag 错误上报（含 sourcemap）
- [ ] APM trace（Datadog / New Relic / OpenTelemetry）
- [ ] DB query 超过 1s 告警

---

## 反模式（拒绝列表）

- ✗ Controller 里写业务逻辑
- ✗ Service 里 import `Request, Response`
- ✗ 直接 `process.env.X`（无验证）
- ✗ 用 `console.log` 当生产日志
- ✗ 用泛 `Error`（catch 时无法判断类型）
- ✗ CORS `'*'` 在生产
- ✗ N+1 查询（用 dataloader / join）
- ✗ 在 Controller 里直接 SQL
- ✗ 在 Service 里 `new Repository()`（破坏 DI）
- ✗ 共享单例的 stateful service
