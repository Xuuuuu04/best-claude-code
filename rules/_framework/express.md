---
paths:
  - "src/api/**"
  - "src/routes/**"
  - "src/middleware/**"
  - "src/controllers/**"
---

<rule name="express-project-structure">
  <convention>路由、控制器、服务、数据访问分层</convention>
  <constraint severity="blocker">不在 Controller 写业务逻辑（Controller 负责 HTTP 转换，Service 负责业务）</constraint>
</rule>

<rule name="express-middleware">
  <description>中间件顺序</description>
  <pattern>
1. 请求日志 / trace ID
2. CORS
3. Body parser
4. 速率限制
5. 认证
6. 业务路由
7. 错误处理（最后）
  </pattern>
</rule>

<rule name="express-error-handling-middleware">
  <pattern>
    <code language="ts">
app.use((err, req, res, next) => {
  logger.error({ err, path: req.path }, 'Request failed');
  const status = err.statusCode || 500;
  res.status(status).json({
    error: { code: err.code || 'INTERNAL_ERROR', message: err.publicMessage || 'Internal error' }
  });
});
    </code>
  </pattern>
</rule>

<rule name="express-routing">
  <convention>RESTful：/users, /users/:id, /users/:id/orders</convention>
  <convention>动词用 HTTP method 表达，不放 URL</convention>
  <convention>Router 模块化：每个资源一个 router 文件</convention>
  <constraint severity="warning">不在路由定义中写业务（委托给 controller/handler）</constraint>
</rule>

<rule name="express-input-validation">
  <constraint severity="blocker">每个端点必须验证输入</constraint>
  <pattern>
    <code language="ts">
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
    </code>
  </pattern>
  <convention>Zod / Joi / express-validator 任选其一。</convention>
</rule>

<rule name="express-auth">
  <convention>认证中间件统一：JWT / session</convention>
  <convention>授权在业务逻辑之前：requirePermission('user:write')</convention>
  <convention>req.user 类型扩展（TypeScript）</convention>
</rule>

<rule name="express-async-errors">
  <constraint severity="blocker">Express 4 不自动捕获 async 错误，必须用 asyncHandler 包装或 Express 5 原生支持</constraint>
  <pattern>
    <code language="ts">
const asyncHandler = fn => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

router.get('/', asyncHandler(async (req, res) => {
  // ...
}));
    </code>
  </pattern>
  <convention>Express 5 原生支持 async 错误。</convention>
</rule>

<rule name="express-database">
  <convention>连接池（pg、mysql2、mongoose）</convention>
  <convention>每个请求不手动管理连接（中间件或 ORM 管理）</convention>
  <convention>事务：显式 begin/commit/rollback，放 Service 层</convention>
</rule>

<rule name="express-logging">
  <convention>结构化（pino / winston）</convention>
  <convention>每个请求有 trace ID（req.id）</convention>
  <constraint severity="blocker">不记录敏感字段（password、token）</constraint>
</rule>

<rule name="express-security">
  <convention>helmet 设置安全 header</convention>
  <convention>cors 限定 origin</convention>
  <convention>rate-limit 限流</convention>
  <convention>CSRF 保护（如使用 cookie 认证）</convention>
  <constraint severity="blocker">SQL 参数化（禁止字符串拼接）</constraint>
</rule>

<rule name="express-config">
  <convention>环境变量（process.env）</convention>
  <convention>dotenv 加载 .env</convention>
  <constraint severity="blocker">.env 不进 git</constraint>
  <constraint severity="blocker">启动时验证必需的环境变量（缺失立即失败）</constraint>
</rule>

<rule name="express-error-classes">
  <pattern>
    <code language="ts">
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
    </code>
  </pattern>
</rule>

<rule name="express-testing">
  <convention>supertest 做集成测试</convention>
  <convention>Vitest / Jest 单元测试</convention>
  <convention>测试用独立数据库实例</convention>
</rule>

<rule name="express-health-check">
  <pattern>
    <code language="ts">
app.get('/health', async (req, res) => {
  // 检查关键依赖
  const checks = { db: await pingDb(), redis: await pingRedis() };
  const healthy = Object.values(checks).every(Boolean);
  res.status(healthy ? 200 : 503).json({ healthy, checks });
});
    </code>
  </pattern>
</rule>
