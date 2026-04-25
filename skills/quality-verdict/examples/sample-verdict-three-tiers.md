---
name: 三档裁决样品（PASS / CONDITIONAL PASS / BLOCKED 各一个）
description: 标准 verdict artifact 格式参考，含三档结论的真实写法
type: doc
status: accepted
---

# Verdict 三档样品

> 这是 quality-verdict skill 的参考模板，展示同一类任务在不同质量水平下的裁决写法。

---

## 样品 A：PASS（核心功能 + UI + 安全全过）

```markdown
---
type: verdict
task_id: feat-20260425-01
status: accepted
generated_at: 2026-04-25T18:00:00+0800
产出者: test-lead
---

# verdict: feat-20260425-01 OAuth 登录

## 最终结论：**PASS** ✓

可发布。

## 三类证据汇总

| 维度 | 证据 artifact | 关键结论 |
|:--|:--|:--|
| 功能 | review-functional-feat-20260425-01.md | 47 单元 + 12 e2e 全过；并发 200 客户端 99.5% 成功 |
| 视觉 | review-visual-feat-20260425-01.md | 桌面+移动端 5 个状态截图齐；登录失败提示一致 |
| 安全 | review-security-feat-20260425-01.md | OAuth state 防 CSRF ✓；token 加密存储 ✓；无未关闭高危 |

## 为什么不是 CONDITIONAL PASS

无中低风险遗留——所有 review WARN 已在 impl-report-feat-20260425-01-2 中修复并复测。

## 为什么不是 BLOCKED

无 Critical / 无核心功能失败 / 无关键状态失真 / 无关键证据缺失。
```

---

## 样品 B：CONDITIONAL PASS（核心通过 + 中低风险遗留）

```markdown
---
type: verdict
task_id: feat-20260420-08
status: accepted
generated_at: 2026-04-22T11:00:00+0800
产出者: test-lead
---

# verdict: feat-20260420-08 数据导出 CSV

## 最终结论：**CONDITIONAL PASS** ⚠

可上线，但以下遗留必须在下个 sprint 补：

1. 大文件（>100MB）导出未充分测试 → 工单 #2034
2. 错误恢复（中断后续传）未实现 → 工单 #2035

## 三类证据

| 维度 | 关键结论 |
|:--|:--|
| 功能 | 100MB 以下全过；500MB 测试报 OOM（已加 streaming，但样本不足） |
| 视觉 | 进度条 / 失败提示 4 个状态截图齐 |
| 安全 | 无敏感字段泄漏；权限校验完备 |

## 条件性放行的理由

- 核心链路（≤100MB 用户场景占 95%）已 PASS
- 大文件场景为长尾需求，独立成 task 不阻塞主线
- 不会引入回归

## 为什么不是 PASS

500MB 边界在 staging 实测仍偶发 OOM——边界用例没全部确定性通过。

## 为什么不是 BLOCKED

核心功能可用 + 高频路径无问题 + 失败时降级清晰。
```

---

## 样品 C：BLOCKED（关键失败 / 高危未关闭）

```markdown
---
type: verdict
task_id: hotfix-20260424-02
status: accepted
generated_at: 2026-04-24T20:30:00+0800
产出者: test-lead
---

# verdict: hotfix-20260424-02 支付回调签名校验

## 最终结论：**BLOCKED** ✗

禁止发布。

## 三类证据

| 维度 | 关键结论 |
|:--|:--|
| 功能 | 主路径 PASS，但**回放攻击边界**测试失败 |
| 视觉 | N/A（仅后端） |
| 安全 | **Critical**：旧 nonce 在 5 分钟窗口内未被拒绝（review-security 第 4 节） |

## 一票否决理由

**未关闭高危安全问题**：security-auditor 报告的"重放攻击窗口 5 分钟"未修复。
该路径处理用户支付，重放可导致重复扣款。

## 修复路由

1. 派 implementer-backend：在 `src/payment/callback.ts:42` 加 nonce Redis 校验（TTL 10 分钟）
2. 完成后 → security-auditor 复审重放场景
3. 复审通过 → functional-tester 跑回归
4. 重新发起 verdict

不要批准任何"先合并后续修"的方案。

## 为什么不是 CONDITIONAL PASS

**安全高危是一票否决项**，与功能 / UI 风险性质不同——不能"先放行后修"。
```

---

## 三档关键差异速记

| 维度 | PASS | CONDITIONAL PASS | BLOCKED |
|:--|:--|:--|:--|
| 核心功能 | 全过 | 全过 | 失败或未验证 |
| 安全高危 | 0 | 0 | ≥1 未关闭 |
| 关键证据 | 齐全 | 齐全 | 缺失或失真 |
| 遗留 | 无 / 已修 | 中低风险，可独立成 task | Critical |
| 输出必须 | 自然 | **跟进 task ID** | **修复路由** |
