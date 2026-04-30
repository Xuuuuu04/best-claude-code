---
name: bcc-loop-dev
description: 顶级团队自主开发模式。全部 Agent 团队自动循环迭代，人工仅在安全漏洞和生产部署等不可逆操作时介入。自动 git commit+push，智能自适应并发，以最大轮次和最高代价持续迭代直到世界级严正交付。
argument-hint: "<任务描述> (完整功能需求)"
disable-model-invocation: true
---

# 顶级团队自主开发模式

## 核心原则

- **人工仅在安全 + 不可逆时介入**（生产部署、DB schema 变更、API 密钥变更、安全漏洞）
- **自动 git**：每 scope-lock 通过完整流水线后 auto commit + push；失败时 auto revert 到上一个 commit
- **自适应并发**：优先标准并发（S0-S3），遭遇 agent 失败/限流时动态降级，恢复后自动尝试升回高并发
- **token 驱动路由**：收 IMPL_DONE → 派 code-reviewer；收 REVIEW_REJECT → redeliberation；收 VERDICT_PASS → 提交+下一 scope
- **自我修复**：redeliberation 自动循环 + pm 穷尽升级 + reviewer 漏审反馈写入 agent-memory

## 启动

1. 项目已有 `.claude/CLAUDE.md`（如无，先跑 `/bcc-init-project`）
2. `bash ~/.claude/bin/doctor.sh` 通过
3. 确认当前分支干净（`git status --porcelain` 为空或仅含 `.claude/` 下文件）
4. 向用户确认任务描述和成功标准

## 工作循环（4 阶段）

```
┌─ 阶段 1：规划 ───────────────────────────────┐
│ 派 product-analyst → 产出 requirements        │
│   → requirements-reviewer（含对抗性压力测试）   │
│ 派 architect → 产出 architecture               │
│   → architecture-reviewer（含断点分析）         │
│ 派 scope-planner → 产出 scope-lock[] +        │
│   scope-plan（含集成风险标记 + 并行批次规划）    │
└───────────────────────────────────────────────┘
                      ↓
┌─ 阶段 2：实现（按 Batch 推进，自适应并发）─────┐
│ for each Batch:                               │
│   并发派 implementer-*（attempt S2 并发）       │
│   收集 IMPL_DONE token                         │
│   如某 implementer 失败/超时 → 降级：           │
│     - 该 Batch 改为串行                         │
│     - 之后 3 个 Batch 保持低并发                │
│     - 3 Batch 无失败 → 尝试恢复到标准并发       │
│   串行派 code-reviewer（6 维审查含对抗性）       │
│   REVIEW_REJECT → redeliberation（max 3 轮）    │
│   REVIEW_PASS → 继续                            │
└───────────────────────────────────────────────┘
                      ↓
┌─ 阶段 3：验证 ───────────────────────────────┐
│ 如涉后端/认证/支付：派 security-auditor        │
│   （OWASP + 7 维业务逻辑攻击）                  │
│ 派 functional-tester（验收+边界+回归）          │
│ 如涉 UI：派 visual-tester（5 状态截图证据）    │
└───────────────────────────────────────────────┘
                      ↓
┌─ 阶段 4：裁决与交付 ─────────────────────────┐
│ scope-lock ≥3 → test-lead 含跨 scope 一致性    │
│ test-lead 汇总 functional+visual+security       │
│   + 一致性 + reviewer 质量反馈                  │
│ VERDICT_PASS → git commit+push → 下一 scope    │
│ VERDICT_CONDITIONAL → 人工确认                  │
│ VERDICT_BLOCKED → 回到阶段 1 修复               │
└───────────────────────────────────────────────┘
```

### Git 自动化

每个 scope-lock 的完整流水线通过后（VERDICT_PASS）：
```bash
git add -A
git commit -m "feat({scope-name}): {scope 描述} — 通过 code-reviewer+security+test+verdict"
git push
```

如后续 scope 失败需要回滚：
```bash
git revert <commit> --no-edit
git push
```

### 自适应并发策略

| 状态 | 并发等级 | 触发条件 |
|:--|:--|:--|
| **标准** | S2（同 Batch scope-lock 全部并行） | 默认 |
| **降级** | S0（同 Batch 全部串行） | 任意 Agent 返回异常/超时/连续 2 次 REVIEW_REJECT |
| **恢复试探** | S1（同 Batch 2 个并行） | 降级后连续 3 Batch 无异常 |
| **恢复标准** | S2 | S1 稳定后再 3 Batch 无异常 |

并发变更只影响后续 Batch，不中断正在运行的 Agent。

## 决策边界

### 自动（不问人）
- 所有非生产的技术决策
- staging 部署
- scope-lock 拆分和 Agent 选择
- 代码审查-修复循环
- git commit + push
- 自适应并发调整

### 暂停 AskUserQuestion
- 生产部署
- DB schema 变更
- API 密钥/endpoint 变更
- `SECURITY_REJECT` — 立即暂停
- `git push --force` / 删除分支/tag/云资源
- 引入新语言/框架

到达决策点时：描述当前状态 + 为什么需要决策 + 推荐选项及后果 → 等待回复。

## 交付标准

| 层级 | 标准 | 不满足时 |
|:--|:--|:--|
| 代码审查 | 所有 scope-lock REVIEW_PASS | 继续 redeliberation |
| 对抗性 | code-reviewer 维度 6 全部 [通过] | 退回 implementer |
| 安全 | 涉后端/认证/支付 → SECURITY_PASS + 业务逻辑攻击 7 维全 [通过] | 退回 implementer |
| 功能 | TEST_PASS，含边界/回归/并发 | 退回 implementer |
| 视觉 | UI 变更 → VISUAL_PASS + 5 状态截图 | 退回 implementer |
| 跨 scope | scope-lock ≥3 → 一致性检查 PASS | 退回 architect/scope-planner |
| 测试覆盖 | 新增代码 ≥85% | 退回 implementer 补测试 |
| 文档 | 受影响 CLAUDE.md 变更日志已更新 | 补文档 |
| 裁决 | test-lead VERDICT_PASS | 继续迭代 |

**任一不满足 → 继续。**

## 循环安全阀

| 条件 | 动作 |
|:--|:--|
| 同一 scope-lock 迭代 ≥5 轮仍未 PASS | 暂停，报告用户——scope 可能有根本缺陷 |
| 连续 3 个 scope-lock 均 BLOCKED | 退回 architect 重新设计 |
| 总派遣次数 ≥100 | 暂停，汇报进度+消耗，请用户确认继续 |
| test-lead 连续 2 次 CONDITIONAL PASS | 视为 PASS（条件已足够轻微） |
| 连续 5 次 Agent 派遣全部异常 | 暂停，系统性故障 |
| 安全漏洞发现 | 立即暂停，等用户决策 |

## 进度报告

每 scope-lock 完成：
```
[loop-dev] {n}/{total} scope 完成
  git: {commit hash} — {commit message}
  消耗: {本次派遣数} 派遣 / {累计} 累计
```

每 20 次派遣汇报 token 消耗。

## 健康自检（每轮循环后）

- 近 10 次派遣失败率 >30% → 暂停诊断
- 连续 3 次 redeliberation 穷尽 → 暂停
- 同类型驳回 pattern 重复 ≥3 次 → 标记 + 写 agent-memory
- scope-lock 平均 turns >30 → 提醒 scope-planner 粒度偏大
- 自适应并发当前状态 → 汇报

## 停止与续跑

中断后可通过描述续跑。loop-dev 自动扫描 artifact 状态，跳过已 accepted 的 scope，从断点继续。续跑时恢复自适应并发状态为"标准"，让系统重新试探。
