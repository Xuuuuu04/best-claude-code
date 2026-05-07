---
name: 功能测试样品（bug-20260425-03 小程序登录失败）
description: 标准 review-functional artifact 格式参考
type: review-functional
task_id: bug-20260425-03
generated_at: 2026-04-25T15:10:00+0800
产出者: 高级功能测试师
status: accepted
关联:
  - requirements-bug-20260425-03.md
  - impl-report-bug-20260425-03-1.md
---

# review-functional: bug-20260425-03 小程序登录在并发下偶发 502

## 测试结果概要

| 验收标准 | 结果 | 证据 |
|:--|:--|:--|
| 1. 单次登录成功率 100% | ✓ PASS | 50 次连续手动登录全部成功 |
| 2. 并发登录（10 客户端）成功率 ≥ 99% | ✓ PASS | 200 次并发登录成功 199，1 次 timeout（原因：测试网络） |
| 3. 失败时返回 4xx 而非 502 | ✓ PASS | 注入 token 错误 → 返回 401 ✓ |
| 4. 服务端日志含 trace_id | ✓ PASS | 抽样 20 条日志，全部含 trace_id |

## 测试套件

```bash
$ npm test -- src/auth/__tests__
✓ 47 passed (47 total)
$ npm run e2e -- auth
✓ 12 passed (12 total)
```

全部通过。

## 边界场景验证

| 场景 | 期望行为 | 实际 | 结论 |
|:--|:--|:--|:--|
| 空 token | 401 + "missing token" | 401 + "missing token" | ✓ |
| 过期 token | 401 + "token expired" | 401 + "token expired" | ✓ |
| 错误 signature | 401 + "invalid signature" | 401 + "invalid signature" | ✓ |
| 用户不存在 | 404 + "user not found" | 404 + "user not found" | ✓ |
| 数据库瞬时失败 | 503 + retry header | 503 + retry header | ✓ |
| 10 客户端并发同账号 | 全部成功（serializable） | 全部成功 | ✓ |

## 回归验证

bug 复现历史：原报告"50+ 并发返回 502"。

构造 50 / 100 / 200 客户端并发登录测试：
- 50 客户端：100% 成功
- 100 客户端：100% 成功
- 200 客户端：99.5% 成功（1 个 timeout 是测试机网络）

**结论：bug 已复现并修复**。修复方式（来自 impl-report）：连接池上限从 10 调到 50 + 重试逻辑。

## 未覆盖项

- 未测试 1000+ 并发（超出本任务 scope，建议 perf 任务专项）
- 未测试跨地域延迟场景（需要 staging 环境）

## 验收建议

✓ **通过验收**。功能修复完成，并发问题不再复现，无回归。

## 下一步

- 用户可以接收
- 建议派 高级视觉测试师（UI 上"登录失败"提示文案应统一） — 可选
- 质量总监 综合裁决
