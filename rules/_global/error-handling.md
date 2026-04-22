# 错误处理规范

适用于所有代码，不分语言。

---

## 核心原则

### 1. 失败快于继续

输入验证失败、不变量被破坏、资源不可用——立即抛错或返回错误，**不要**"尽量继续"：

```ts
// 错误
function processOrder(order) {
  if (!order.items) order.items = [];  // 掩盖问题
  // ...
}

// 正确
function processOrder(order) {
  if (!order.items || order.items.length === 0) {
    throw new ValidationError('Order must have at least one item');
  }
  // ...
}
```

### 2. 错误信息有上下文

错误消息必须让接收者能够**诊断**：

```ts
// 错误
throw new Error('Not found');

// 正确
throw new NotFoundError(`User not found: id=${userId}, tenant=${tenantId}`);
```

### 3. 异常分层

- **领域异常**：业务规则违反（`InvalidOrderStateError`）
- **基础设施异常**：外部依赖失败（`DatabaseConnectionError`）
- **验证异常**：输入不合法（`ValidationError`）
- **未知异常**：不在分类内的错误

每层异常处理方式不同：领域异常返回用户友好消息；基础设施异常重试或降级；未知异常记录完整堆栈。

### 4. 不吞异常

```ts
// 错误
try {
  doSomething();
} catch (e) {
  // 空
}

// 也错误
try {
  doSomething();
} catch (e) {
  logger.error(e);
  // 然后继续？调用方以为成功了
}

// 正确
try {
  doSomething();
} catch (e) {
  logger.error({ error: e, context: { ... } }, 'doSomething failed');
  throw new WrappedError('Processing failed', { cause: e });
}
```

### 5. 资源清理

即使在异常路径，资源也必须被释放：

```ts
// 模式 1: try-finally
const conn = await pool.getConnection();
try {
  return await doWork(conn);
} finally {
  conn.release();
}

// 模式 2: using / context manager
using resource = await acquireResource();
return await doWork(resource);

// Python
with open(path) as f:
    return process(f)
```

---

## 错误信息内容

### 应该包含

- **发生位置**：函数、文件、操作类型
- **输入上下文**：触发错误的输入（注意脱敏）
- **期望行为**：应该是什么
- **实际行为**：实际发生了什么
- **原因链**：如果是包装错误，保留原始 cause

### **不应**包含

- 密码、token、密钥
- 个人身份信息（PII）未脱敏
- 内部文件路径（对生产客户端返回的错误）
- 完整堆栈（对生产客户端返回的错误）
- 数据库结构细节
- 内部系统 URL

---

## 错误传播

### 包装错误保留原因

```ts
try {
  await db.query(...);
} catch (dbError) {
  throw new OrderProcessingError('Failed to save order', { cause: dbError });
}
```

读取 cause 链便于定位根因。

### 向上层传递适当的抽象

不要让下层细节泄露到上层：

```ts
// 错误：SQL 错误直接返回给 API 客户端
catch (e) {
  res.status(500).json({ error: e.message });  // "syntax error near ..."
}

// 正确：转换为适当抽象
catch (e) {
  logger.error({ error: e }, 'Database query failed');
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'Request could not be processed' }
  });
}
```

---

## 重试策略

### 可重试 vs 不可重试

- **可重试**：网络超时、临时不可用、限流
- **不可重试**：参数错误、权限不足、资源不存在

### 重试参数

- 最大重试次数（通常 3-5 次）
- 退避策略：指数退避 + jitter
- 超时（每次 + 总体）
- 只对幂等操作重试

```ts
async function withRetry(fn, { maxAttempts = 3, initialDelay = 1000 }) {
  let lastError;
  for (let i = 0; i < maxAttempts; i++) {
    try {
      return await fn();
    } catch (e) {
      lastError = e;
      if (!isRetryable(e) || i === maxAttempts - 1) throw e;
      const delay = initialDelay * Math.pow(2, i) + Math.random() * 1000;
      await sleep(delay);
    }
  }
}
```

---

## 熔断与降级

### 熔断

当依赖服务持续失败时，停止调用一段时间，防止级联失败。

状态：
- Closed：正常调用
- Open：失败率超阈值，快速拒绝
- Half-open：尝试恢复

### 降级

依赖失败时提供替代行为：
- 缓存的旧数据
- 默认值
- 简化的功能（如关闭推荐，但保留主流程）
- 明确的错误消息

---

## 日志与错误

- 错误在**捕获的最高抽象层**记录一次，避免重复记录
- 包含结构化上下文（JSON 字段）
- 级别：可恢复是 WARN，不可恢复是 ERROR
- 带关联 ID（trace_id、request_id）便于追踪

---

## 用户可见错误

### 前端

- 不显示技术细节（堆栈、内部错误码）
- 提供可操作的建议（重试、联系客服、检查输入）
- 保留国际化能力

### API 响应

使用统一错误格式：
```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Email format is invalid",
    "details": {
      "field": "email",
      "value": "not-an-email"
    }
  }
}
```

错误码稳定（客户端依赖），消息人类可读。

---

## 测试错误路径

测试不应只覆盖 happy path：

- 输入非法时的响应
- 依赖失败时的行为
- 超时时的行为
- 并发冲突时的行为

每个 `try/catch` 都应有对应的测试。
