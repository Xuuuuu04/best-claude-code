# MCP Tool Design Template

设计 MCP 工具时的标准模板。每个新工具按此结构填空，避免遗漏。

## Tool Definition Schema

```typescript
{
  name: "kebab-case-action-noun",  // 例: "send-slack-message"
  description: "动词开头，说明做什么 + 何时用 + 边界",
  inputSchema: {
    type: "object",
    properties: {
      param_name: {
        type: "string" | "number" | "boolean" | "array" | "object",
        description: "参数说明 + 例子",
        enum?: [...],
        pattern?: "regex",
        minLength?: number,
        maxLength?: number,
      }
    },
    required: ["..."],
    additionalProperties: false  // 严格模式
  }
}
```

## 命名规范

### 工具名

- ❌ `getData`、`process`、`handle` —— 太泛
- ❌ `myFunc`、`utilA` —— 无意义
- ✅ `send-email`、`fetch-github-issue`、`run-sql-query`

### 参数名

- ❌ `data`、`info`、`thing` —— 太泛
- ❌ `usr`、`msg`、`tmp` —— 缩写歧义
- ✅ `recipient_email`、`issue_number`、`query_string`

## Description 模板

```
{动词} {对象} {限定词}.

When to use: {3 个具体触发场景}

NOT for: {3 个常被误用的场景}

Returns: {返回值类型 + 关键字段}

Example: {1 个真实调用示例}
```

实例：

```yaml
name: send-slack-message
description: |
  Posts a message to a Slack channel via the bot user.

  When to use:
  - User asks to "notify the team in Slack"
  - User asks to share a deploy status / alert
  - Confirming a long-running task completion

  NOT for:
  - Sending DMs (use send-slack-dm instead)
  - Reading messages (use read-slack-channel)
  - Formatting Slack-specific markdown (call format-slack-text first)

  Returns: { ok: boolean, message_ts: string, channel: string }
```

## 输入验证模板

```typescript
// Channel
{
  channel: {
    type: "string",
    pattern: "^(#[a-z0-9_-]+|C[A-Z0-9]+)$",
    description: "Slack channel name (e.g. '#deploys') or ID"
  }
}

// Email
{
  recipient_email: { type: "string", format: "email" }
}

// URL: HTTPS only
{
  webhook_url: { type: "string", pattern: "^https://" }
}

// 命令白名单
{
  action: {
    type: "string",
    enum: ["read", "list", "search"]  // 不允许 write/delete
  }
}
```

## 返回值规范

### 成功

```typescript
{
  ok: true,
  data: {...},
  meta: { request_id, timestamp }
}
```

### 失败

```typescript
{
  ok: false,
  error: {
    code: "RATE_LIMITED" | "INVALID_INPUT" | "AUTH_FAILED" | ...,
    message: "Human-readable explanation",
    retry_after?: number
  }
}
```

不要 throw exception。返回结构化错误。

## 安全清单

详见 `security-checklist.md`。每个工具上线前确认：

- [ ] 凭据来自 env，不在代码 / 日志 / 输出
- [ ] 输入验证拒绝注入字符（SQL / 命令 / 路径遍历）
- [ ] 写操作支持 dry-run
- [ ] 危险操作（删除 / 发送外部消息）有二次确认
- [ ] 错误消息不泄露内部细节

## 审计日志

每次工具调用记录（脱敏后）：
- 工具名
- 入参
- 调用方（agent / user）
- 时间戳
- 返回状态（success / error）
- 耗时

## 测试矩阵

| 测试类型 | 必须覆盖 |
|:--|:--|
| Happy path | 正常输入 → 期望输出 |
| Boundary | 空字符串、最大长度、零、负数、UTF-8 emoji |
| Invalid input | 非 JSON、缺必需字段、类型错误 |
| Auth fail | 错误 token / 过期 / 无权限 |
| Rate limit | 短时间多次调用 |
| Network error | 超时、连接拒绝、DNS 失败 |
| Server error | 5xx 响应 |
| Concurrent | 并发请求顺序 |

## 文档清单

每个工具的 README 必须有：

- 用途与受众
- 完整参数说明（含例子）
- 返回值类型 + 字段含义
- 错误码表
- 凭据获取流程
- 调用示例（curl + Claude Code 中的 prompt 例子）
- 限流说明
- 已知限制 / 不支持的场景

## 版本管理

签名变更：
- ✅ 新增可选参数 → 兼容
- ✅ 增加返回字段 → 兼容
- ❌ 删除参数 → 破坏
- ❌ 改参数类型 → 破坏
- ❌ 改 enum 值 → 破坏

破坏性变更：发布新工具名（如 `send-email-v2`），保留旧版 30 天后退役。

## 元数据建议

```typescript
{
  name: "...",
  description: "...",
  annotations: {
    title: "Send Slack Message",
    readOnlyHint: false,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: true
  }
}
```

## 完整模板（填空）

```yaml
name: <kebab-case-name>
description: |
  <一句话动作>

  When to use:
  - <场景 1>
  - <场景 2>

  NOT for:
  - <误用 1>

  Returns: <返回结构>

inputSchema:
  type: object
  properties:
    <param_1>:
      type: <type>
      description: <说明 + 例子>
      <约束>
  required:
    - <param_1>
  additionalProperties: false
```

参考 Anthropic MCP 官方规范 + Claude Code skills/mcp-builder。详见 `security-checklist.md`。
