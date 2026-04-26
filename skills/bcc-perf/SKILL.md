---
name: bcc-perf
description: 性能优化流水线。测量先行、假设驱动、验证优先。
argument-hint: "<性能目标：当前指标 → 目标指标，例 'API p99 800ms → 200ms'>"
disable-model-invocation: true
---

# 性能优化流水线

`$ARGUMENTS` 是优化目标。要求闭环：**baseline → profile → 方案 → 实现 → 功能验证 → 性能验证**。

调度真源：`rules/_global/dispatch-table.md`。性能优化默认串行，不并发多个性能假设；只读 profile / research 可按 `S1` 并发。

## Phase 1: 基线测量

派遣 `repo-researcher`：
- 定义指标、目标值、测量方法
- 记录 baseline 数据

如目标已达标，直接停止并汇报。

## Phase 2: 瓶颈定位与方案

### 2.1 `repo-researcher`

产出 `perf-profile-{task-id}.md`，给出热点、占比和证据。

### 2.2 `architect`

只针对最高优先级假设设计优化方案。

### 2.3 `scope-planner`

把优化方案拆成单一热点 scope-lock，不并行多个假设。

### 2.4 `architecture-reviewer`

审查性能方案是否基于真实 profile，而不是拍脑袋。

## Phase 3: 实现

派遣 implementer：
- 只改目标热点
- 改完立即重新测量
- 若改善 <5% 或退化，不允许擅自扩大范围

## Phase 4: 验证

### 4.1 `code-reviewer`

检查 scope 合规与实现质量。

### 4.2 `functional-tester`

验证无行为回归。

### 4.3 性能验证

由 `repo-researcher` 或调度器对照 baseline 做 3 次复测，确认结果可复现。

## Phase 5: 汇报

汇报指标从 `{before}` 到 `{after}` 的变化、改善幅度、以及下一条未验证假设。
