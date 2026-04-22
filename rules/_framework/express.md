---
paths:
  - "src/api/**"
  - "src/routes/**"
  - "src/middleware/**"
  - "src/controllers/**"
---

# Express / Node.js 后端规范

## 项目结构

- 路由、控制器、服务、数据访问分层
- 不在 Controller 写业务逻辑（Controller 负责 HTTP 转换，Service 负责业务）

## 中间件

### 顺序

1. 请求日志 / trace ID
2. CORS
3. Body parser
4. 速率限制
5. 认证
6. 业务路由
7. 错误处理（最后）

### 错误处理中间件

```ts
app.use((err, req, res, next) => {
  logger.error({ err, path: req.path }, 'Request failed');
  const status = err.statusCode || 500;
  res.status(status).json({
    error: { code: err.code || 'INTERNAL_ERROR', message: err.publicMessage || 'Internal error' }
  });
});
```

## 路由

- RESTful：`/users`, `/users/:id`, `/users/:id/orders`
- 动词用 HTTP method 表达，不放 URL
- Router 模块化：每个资源一个 router 文件
- 不在路由定义中写业务（委托给 controller/handler）

## 输入验证

**每个端点必须验证输入**：

```ts
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email(),
  age: z.number().int().min(18).max(120),
});

router.post('/users', async (req, res, next) => {
  const parseResult = CreateUserSchema.safeParse(req.body);
  if (!parseResult.success) {
    return res.status(422).json({
      error: { code: 'VALIDATION_FAILED', details: parseResult.error.issues }
    });
  }
  // ...
});
```

Zod / Joi / express-validator 任选其一。

## 认证 & 授权

- 认证中间件统一：JWT / session
- 授权在业务逻辑**之前**：`requirePermission('user:write')`
- `req.user` 类型扩展（TypeScript）

## 异步错误

Express 4 不自动捕获 async 错误，必须：

```ts
const asyncHandler = fn => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

router.get('/', asyncHandler(async (req, res) => {
  // ...
}));
```

Express 5 原生支持。

## 数据库

- 连接池（pg、mysql2、mongoose）
- 每个请求不手动管理连接（中间件或 ORM 管理）
- 事务：显式 begin/commit/rollback，放 Service 层

## 日志

- 结构化（pino / winston）
- 每个请求有 trace ID（`req.id`）
- 不记录敏感字段（password、token）

## 安全

- `helmet` 设置安全 header
- `cors` 限定 origin
- rate-limit 限流
- CSRF 保护（如使用 cookie 认证）
- SQL 参数化（禁止字符串拼接）

## 配置

- 环境变量（`process.env`）
- `dotenv` 加载 .env
- **.env 不进 git**
- 启动时验证必需的环境变量（缺失立即失败）

## 错误类

```ts
class HttpError extends Error {
  constructor(public statusCode: number, public code: string, message: string, public details?: any) {
    super(message);
  }
}

class NotFoundError extends HttpError {
  constructor(resource: string, id: string) {
    super(404, 'NOT_FOUND', `${resource} ${id} not found`);
  }
}
```

## 测试

- supertest 做集成测试
- Vitest / Jest 单元测试
- 测试用独立数据库实例

## 健康检查

```ts
app.get('/health', async (req, res) => {
  // 检查关键依赖
  const checks = { db: await pingDb(), redis: await pingRedis() };
  const healthy = Object.values(checks).every(Boolean);
  res.status(healthy ? 200 : 503).json({ healthy, checks });
});
```
