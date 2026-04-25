---
name: 代码审查样品（feat-20260425-01 用户登录 OAuth）
description: 标准 review-code artifact 格式参考
type: review-code
task_id: feat-20260425-01
generated_at: 2026-04-25T14:30:00+0800
产出者: code-reviewer
status: accepted
关联:
  - scope-lock-feat-20260425-01-1.md
  - impl-report-feat-20260425-01-1.md
---

# review-code: feat-20260425-01 OAuth 登录实现审查

## 审查概要

| 维度 | 结果 | Critical | Warning | Suggestion |
|:--|:--|:-:|:-:|:-:|
| 1. Scope 合规 | 通过 | 0 | 0 | 0 |
| 2. 代码质量 | 需改进 | 0 | 2 | 1 |
| 3. 测试 | 通过 | 0 | 0 | 1 |
| 4. 接口契约 | 通过 | 0 | 0 | 0 |

**总计**：0 Critical / 2 Warning / 2 Suggestion → **建议合并**（修 Warning 后）

## 1. Scope 合规

✓ 修改文件 100% 在 scope-lock 白名单内：
- `src/auth/oauth/google.ts`（白名单 ✓）
- `src/auth/oauth/github.ts`（白名单 ✓）
- `src/auth/oauth/__tests__/`（白名单 ✓）

✓ 未触碰禁止事项（数据库 schema / `src/payment/`）
✓ 无未授权依赖（`googleapis` 已在 architecture artifact 批准）

## 2. 代码质量

### Warning-1: 错误处理吞异常

**位置**：`src/auth/oauth/google.ts:42`

```ts
try {
  const profile = await googleClient.getProfile(token);
} catch (e) {
  return null;  // ⚠ 静默吞异常
}
```

**问题**：吞异常会掩盖 Google API 错误（如 token 过期 / 速率限制），下游只看到 `null` 不知道为何失败。
**建议**：分类处理——`TokenExpiredError` 重新登录；`RateLimitError` 重试；其他抛出。

### Warning-2: 日志含 PII

**位置**：`src/auth/oauth/github.ts:78`

```ts
logger.info('OAuth callback', { email, profile });  // ⚠ 含完整 profile
```

**建议**：日志只记 `userId` + `provider`，不记 email/profile。

### Suggestion-1: 提取常量

`src/auth/oauth/google.ts:15` 和 `github.ts:18` 都有 hardcoded `'https://api.example.com/auth/callback'`，建议提到 `src/auth/oauth/constants.ts`。

## 3. 测试

✓ 覆盖 scope-lock 指定的 happy path（Google / GitHub 登录成功）
✓ 覆盖边界（无效 token / 网络失败 / 用户拒绝授权）
✓ Mock 隔离了第三方调用

### Suggestion-2: 缺并发测试

未测试"同一用户同时从两端 OAuth 登录"的并发场景。建议补 1 个 race condition 测试。

## 4. 接口契约

✓ `OAuthProvider` 接口与 architecture-feat-20260425-01.md 定义一致
✓ 返回类型 `Result<UserSession, AuthError>` 正确使用
✓ 没有破坏现有 `/auth/login` 端点

## 下一步

- 派 implementer-backend 修 Warning-1 + Warning-2（Suggestion 可后续单 task）
- 完成后 → security-auditor（OAuth 是安全敏感路径）
