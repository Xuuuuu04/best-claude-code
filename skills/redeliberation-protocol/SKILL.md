---
name: redeliberation-protocol
description: "再审议协议。当 implementer 同一 scope-lock 被 code-reviewer 驳回 ≥2 次，或 test-lead 因实现问题裁定 BLOCKED 时自动加载。实现 A-B 审议迭代闭环（implementer ↔ reviewer），judge 判定终止，max 3 轮。"
when_to_use: "实现被驳回 ≥2 次 / test-lead BLOCKED / 同一 scope 反复返工 / code-reviewer 多次 REJECT"
---

## 框架概述

本协议实现「A-B 审议迭代」闭环：当 implementer 的同一 scope-lock 被反复驳回时，将隐式返工显式化为有计数器、有上限、有历史记录的受控循环。

```
组件A = implementer（执行实现，产出 impl-report）
组件B = code-reviewer（审查实现，产出 review-code）
judge = test-lead 或主会话（判定终止或重试）
```

循环最多 3 轮。每轮 A → B → judge，judge 判定 PASS 则结束，RETRY 则进入下一轮。

## 触发条件

以下任一条件命中时加载本协议：

- code-reviewer 对同一 scope-lock 返回 `REVIEW_REJECT` 这是第 2 次
- test-lead 返回 `VERDICT_BLOCKED` 且阻塞原因指向实现质量
- implementer 的 impl-report 被同一 reviewer 驳回 ≥2 次
- 主会话检测到同一 scope-lock 的 `review-code-*` 文件 ≥2 个且最新为 REJECT

**不触发**：安全审计驳回（那是 security-auditor 的独立 gate，不走实现迭代）。

## 调用参数

- **`scope_lock`**（必填）— scope-lock 文件路径
- **`impl_report`**（必填）— 最近一次 impl-report 路径
- **`review_code`**（必填）— 最近一次 review-code 路径（含驳回原因）
- **`max_rounds`**（可选）— 最大迭代轮次，默认 3

## 文件约定

在 `scope-lock` 同目录下追加迭代文件：

| 文件 | 维护者 |
|------|--------|
| `{scope-lock 同目录}/redelib_v{M}.md` | 主会话，记录每轮判定 |

代码修改直接覆盖原文件（同 scope-lock 白名单路径），不创建额外分支。

## 编排流程

### 1. 初始化

- 读取 scope-lock，确认白名单和完成标准
- 读取最近一次 review-code，提取严重和一般问题清单
- 初始化轮次计数器 M = 1，max_rounds = 3

### 2. 审议循环（最多 max_rounds 轮）

每轮依次执行：

**步骤 A — 启动 implementer（定向修订）**

调度器派遣 implementer，prompt 中传入：

- scope-lock 路径
- 上一轮 review-code 的严重/一般问题清单（仅问题摘要，不传全文）
- 当前轮次 M / max_rounds

implementer 仅修改有问题的文件，产出 impl-report-{task-id}-{seq}_r{M}.md。

**步骤 B — 启动 code-reviewer（专项审查）**

调度器派遣 code-reviewer，prompt 中传入：

- scope-lock 路径
- 新 impl-report 路径
- 上一轮 review-code 路径（对照检查问题是否真修复）

code-reviewer 返回 `REVIEW_PASS` 或 `REVIEW_REJECT:{严重数}blocker:{一般数}issue`。

**步骤 C — 判定**

- 返回 `REVIEW_PASS` → 循环结束，进入步骤 3
- 返回 `REVIEW_REJECT` 且 M < max_rounds → M++，回到步骤 A
- 返回 `REVIEW_REJECT` 且 M ≥ max_rounds → 循环结束，进入步骤 3（标记为 BLOCKED）

### 3. 向用户返回结果

- 通过时：`再审议通过，最终产出：{impl-report 路径}，共 {M} 轮`
- 未通过时：`再审议未通过（{max_rounds} 轮后仍驳回），最终阻塞问题：{严重数}blocker {一般数}issue，建议人工介入`

## 异常处理

- implementer 连续 2 次异常（无产出/超时）→ 终止循环，标记 BLOCKED
- code-reviewer 连续 2 次异常 → 终止循环，以最后 impl-report 为最终产出
- scope-lock 文件缺失 → 终止，退回 scope-planner

## 与其他协议的关系

- 本协议包装 implementer + code-reviewer 的交互，不替代它们
- 安全审计仍独立执行，security-auditor 的 `SECURITY_REJECT` 不触发本协议
- test-lead 在本协议中承担 judge 角色，或在循环结束后做最终裁决
- 与 implementation-protocol 互补：implementation-protocol 管单次实现纪律，本协议管多次迭代纪律

## 穷尽升级（max_rounds 耗尽时）

再审议 3 轮后仍被驳回时，**不直接上报用户**。先派遣 `pm` 做根因分析：

1. pm 读取 scope-lock + 全部 impl-report + 全部 review-code
2. pm 判断阻塞根因：
   - **scope-lock 缺陷**（白名单遗漏、接口契约不清）→ 退回 `scope-planner` 修订 scope-lock，重新开始
   - **architecture 缺陷**（设计不可行）→ 退回 `architect`，重新设计
   - **implementer 能力边界**（确实做不到）→ 上报用户，建议人工介入或拆更小 scope
3. pm 产出 `dispatch-{date}-redelib-{task-id}.md`

仅在 pm 也判断为"需人工介入"时才上报用户。
