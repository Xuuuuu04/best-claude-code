---
name: bcc-refactor
description: 重构流水线。行为不变、测试前后必须完全一致通过。
disable-model-invocation: true
---

# 重构流水线

`$ARGUMENTS` 是重构目标。重构要求“行为不变、结构变好”。

调度真源：`rules/_global/dispatch-table.md`。重构默认串行；只有 `scope-plan` 明确同 Batch 且白名单无交集时，才允许按 `S2` 并发。

## 核心纪律

1. Tests before = Tests after
2. 禁止顺便修 bug
3. 禁止改对外接口
4. 小步快走

## Phase 1: 基线建立

### 1.1 派遣 `repo-researcher`

产出 `.claude/artifacts/refactor-basis-{task-id}.md`，包含涉及文件、调用者、测试覆盖与风险。

### 1.2 测试基线

重构前必须运行完整测试套件并记录基线。

## Phase 2: 方案设计

### 2.1 派遣 `architect`

产出 architecture 文档，明确“不变量清单”。

### 2.2 派遣 `scope-planner`

产出 scope-lock，明确：
- 禁止改接口
- 禁止引入新依赖
- 测试前后状态必须一致

### 2.3 派遣 `architecture-reviewer`

重点审“是否真的只是重构”。

## Phase 3: 实现

派遣 implementer，并强调：
- 对照基线验证
- 发现 bug 只记录，不顺手修
- 同一 Batch 内并发前必须确认文件白名单无交集、测试命令互不污染

## Phase 4: 验证

### 4.1 `code-reviewer`

检查 scope 合规与重构边界。

### 4.2 `functional-tester`

做等价性验证：测试通过/失败状态必须与基线完全一致。

## Phase 5: 汇报

汇报修改文件数、测试前后是否一致、不变量是否保持。
