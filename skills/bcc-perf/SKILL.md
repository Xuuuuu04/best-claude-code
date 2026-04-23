---
name: bcc-perf
description: 性能优化流水线。测量先行、假设驱动、验证优先。禁止"凭感觉优化"和"顺手改其他东西"。
disable-model-invocation: true
---

# 性能优化流水线

`$ARGUMENTS` 是优化目标描述，如：
- "首页 P95 延迟从 1.2s 降到 400ms 以下"
- "订单列表 API 响应时间优化"
- "Docker 构建时间过长"

性能优化的特殊纪律：**没有测量就没有优化**。凭感觉改代码 80% 是负优化或无效优化。本流水线强制"测量 → 假设 → 修改 → 验证"闭环。

---

## 核心纪律

1. **先 baseline 再改代码**：不测量当前性能就开始改 = 自欺欺人
2. **具体指标，非模糊表述**：不接受"更快一点"，要"P95 < 400ms"、"冷启动 < 2s"、"内存峰值 < 512MB"
3. **一次一个假设**：同时改 N 个东西无法归因。每次只变动一个维度，测量，再决定下一步
4. **验证必须覆盖回归**：改 A 让 A 快了但 B 慢了 = 没改
5. **禁止"顺便重构"**：性能优化中发现代码不好但与性能无关 → 记下来 → 另起 `/bcc-refactor`

---

## Phase 1: 基线测量

### 1.1 派遣 researcher 确定优化目标和测量方法

```
任务：为性能优化任务确定可测量的指标和 baseline。
优化目标：{$ARGUMENTS}

请产出 .claude/artifacts/perf-baseline-{task-id}.md：

1. 量化目标
   - 指标名：如 P95 latency / memory peak / build time / bundle size
   - 目标值：具体数字
   - 允许波动：如 ±5%

2. 测量方法
   - 工具：profiler / benchmark / load test
   - 命令或脚本：可复现的执行方式
   - 环境：dev / staging / production-like
   - 样本量 / 时长：确保统计显著性

3. Baseline 数据
   - 当前 P50 / P95 / P99
   - 或当前构建耗时、bundle 大小等

4. 瓶颈初判
   - 从 baseline 数据看，瓶颈最可能在哪里？
   - 需要进一步 profile 确认的猜测
```

**如果 baseline 已经达标** → 停止流水线，汇报用户"目标已达成，无需优化"。

---

## Phase 2: 瓶颈定位与方案

### 2.1 派遣 researcher 做深度 profile

```
任务：用 profiler 定位瓶颈，产出证据。
baseline：.claude/artifacts/perf-baseline-{task-id}.md

请使用项目可用的工具（按领域）：
- 前端：Chrome DevTools Performance、Lighthouse、bundle analyzer
- 后端：APM (Datadog/NewRelic/...)、pprof、py-spy、CPU/memory profiler
- DB：EXPLAIN ANALYZE、慢查询日志
- 构建：--profile flag、webpack-bundle-analyzer

产出 .claude/artifacts/perf-profile-{task-id}.md：

1. 瓶颈热点（前 3-5 个）
   - 位置：具体文件:行号 / 具体查询 / 具体资源
   - 占比：该热点消耗总耗时/资源的百分比
   - 证据：profile 截图或原始数据引用

2. 假设清单
   - 假设 1：{瓶颈原因} → {修复方向}
   - 假设 2：...
   按"预期收益 × 修改难度"排序

3. 假设外的观察（不一定要改，但值得记录）
```

### 2.2 派遣 architect 设计优化方案

```
任务：基于 profile 设计优化方案，一次只针对一个假设。
profile：.claude/artifacts/perf-profile-{task-id}.md

选择排名第 1 的假设进行方案设计。产出 architecture + scope-lock：

- 改动范围最小化（只改 profile 指出的热点，不扩展）
- scope-lock 中必须写"验证方式"：执行什么命令测量改动后的指标
- 如假设 1 效果不好会回退，请明确回退路径

如需同时针对多个假设，拆成独立的 scope-lock 顺序执行（**不并行**——无法归因）。
```

### 2.3 quality-guardian 审查（性能专属模式）

```
审查类型：perf-architecture-review
对象：perf-profile + architecture + scope-lock

检查：
- 是否基于真实 profile 数据而非猜测
- 改动范围是否聚焦于瓶颈
- 是否引入功能/接口改动（perf 流水线不允许）
- 有无明显的正确性风险（比如缓存带来的一致性问题）
```

---

## Phase 3: 实现 + 单点测量

派遣对应 implementer。**任务提示特别强调**：

```
额外约束（性能优化模式）：
- 仅改动 scope-lock 指定热点
- 实现后立即用 .claude/artifacts/perf-baseline 中定义的命令重新测量
- 将测量结果追加到实现报告中
- 如果改动后指标**没有改善**或改善 <5%，报告"假设不成立"，**不要**自行扩大改动
```

---

## Phase 4: 等价性 + 性能验证（双重）

### 4.1 功能等价性

派遣 quality-guardian 做 `functional-test`（复用 review-protocol Skill 的标准模式）：**测试全部通过**，无行为变更。

### 4.2 性能验证

```
审查类型：perf-verify
对象：
- .claude/artifacts/perf-baseline-{task-id}.md
- impl-report 中的新测量数据

验证：
- 指标达成目标？（差距在允许波动内）
- 其他相关指标无退化？（P50 快了但 P99 反而慢 = 问题）
- 样本量足够？单次测量不算数
- 结果可复现？至少跑 3 次结果一致

判定：
- 达成 → 通过
- 改善但未达目标 → 需修改（回 Phase 2 选下一假设）
- 无改善或退化 → 驳回改动，恢复代码
```

---

## Phase 5: 完成

### 5.1 提交

```
perf({scope}): {描述}

Metric: P95 1200ms → 380ms (68% reduction)
Verified against baseline 3 runs, consistent.

Refs:
- .claude/artifacts/perf-baseline-{task-id}.md
- .claude/artifacts/perf-profile-{task-id}.md
```

### 5.2 向用户汇报

```
✓ 性能优化完成
  └ 目标：{...}
  └ 达成：{before} → {after} ({改善百分比})
  └ 验证：3 次运行一致 ✓ / 功能测试全通过 ✓
  └ 假设：{哪一条成立}
  └ 其他假设：{列出未验证但有潜力的，供后续}
```

### 5.3 如未达目标

汇报"本轮优化假设 X 成立但不足以达成目标，已达成 {X}%"。建议：
- 继续下一个假设 → 另起 `/bcc-perf`
- 或接受当前改善 → 记录达成进度

---

## 不适合走 `/bcc-perf` 的场景

- 基线明显就达标，用户只是想"更快一点"——先问清具体指标
- 性能问题源于架构缺陷（如 N+1 查询，根本解决要改架构）→ 先走 `/bcc-refactor` 或 `/bcc-new-feature`
- 硬件/基础设施瓶颈（CPU 不够、网络慢）→ devops 处理
- 没有测量工具的环境 → 先给用户建议"加一个 profiler"，不强行优化
