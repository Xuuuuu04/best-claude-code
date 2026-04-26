---
name: bcc-fix-bug
description: Bug 修复流水线。用于错误、异常行为和回归问题修复。
argument-hint: "<bug 描述：症状 + 复现步骤 + 期望行为>"
disable-model-invocation: true
---

# Bug 修复流水线

`$ARGUMENTS` 是 bug 描述。目标链路是：**定位 → 影响分析 → 范围锁定（小 bug 可跳过架构）→ 实现 → 代码审查 → 安全审计（如适用）→ 回归验证 → 视觉验证（UI bug）**。

调度真源：`rules/_global/dispatch-table.md`。若本 Skill 与调度表冲突，以调度表为准。

---

## 预备：Task ID

生成 `bug-YYYYMMDD-NN`。

---

## Phase 1: 定位与影响分析

### 1.1 派遣 `repo-researcher`

```text
任务：定位以下 bug 的可能根因和相关代码位置。
Bug 描述：{$ARGUMENTS}

请写入 .claude/artifacts/repo-research-{task-id}.md：
- 可能的根因
- 涉及文件与行号
- 相关调用者
- 如无法复现或无法定位，明确说明
```

### 1.2 派遣 `product-analyst`

```text
任务：基于 repo research，分析该 bug 的影响范围、修复优先级和验收标准。
Task ID: {task-id}
调研报告：.claude/artifacts/repo-research-{task-id}.md

请写入 .claude/artifacts/requirements-{task-id}.md。
```

### 1.3 派遣 `requirements-reviewer`

审查修复后的 requirements 是否可复现、可验证。

---

## Phase 2: 修复方案与范围锁定

### 2.1 派遣 `architect`

简单 bug（单文件 ≤20 行、无高风险、根因明确）可跳过 `architect`，直接进入 `scope-planner`。否则派遣 `architect`：

```text
任务：为 bug 设计最小化修复方案。
需求文档：.claude/artifacts/requirements-{task-id}.md
研究报告：.claude/artifacts/repo-research-{task-id}.md

请写入 .claude/artifacts/architecture-{task-id}.md。
要求明确：
- 根因
- 修复思路
- 风险
- 不变量
```

### 2.2 派遣 `scope-planner`

```text
任务：基于 architecture 产出 bug 修复 scope-lock。
若跳过 architect，则基于 requirements + repo-research 产出 scope-lock。
特别要求：
- 先写一个能复现 bug 的失败测试
- 再修复代码让测试通过
```

### 2.3 审查架构与范围

简单 bug（单文件 ≤20 行、无高风险）可跳过架构审查；否则派遣 `architecture-reviewer`。

---

## Phase 3: 实现

### 3.1 派遣 implementer

根据 scope-lock 技术栈选择执行者：

- `frontend` → `implementer-frontend`
- `backend` → `implementer-backend`
- `mobile` → `implementer-mobile`
- `miniprogram` → `miniprogram-dev`
- `database` → `database-engineer`
- `ml` → `ml-engineer`

同一 Batch 内只有满足 `dispatch-table.md` 的 `S2` 条件才允许并发；bug 修复默认串行，除非 scope-lock 明确无依赖且白名单无交集。

任务提示必须强调：

```text
步骤：
1. 先编写能复现 bug 的失败测试
2. 运行确认失败（red）
3. 最小改动修复代码
4. 运行确认通过（green）
5. 跑相关回归测试
```

### 3.2 派遣 `code-reviewer`

重点检查：
- 是否真的修复根因，而不只是掩盖症状
- scope 是否越界
- 回归测试是否真覆盖原 bug

### 3.3 派遣 `security-auditor`（按需）

如 bug 涉及认证、权限、输入验证、敏感数据、日志、配置、依赖，必须追加安全审计。

---

## Phase 4: 回归验证

### 4.1 派遣 `functional-tester`

运行完整测试或关键回归测试，确认 bug 消失且没有引入新问题。

### 4.2 派遣 `visual-tester`（仅 UI 可见 bug）

若 bug 为可见界面缺陷、交互缺陷或状态渲染错误，则追加视觉验证。

### 4.3 派遣 `test-lead`（发布前 / 里程碑 bug）

若 bug 位于发布阻塞、客户验收、生产事故修复或安全敏感路径，必须派遣 `test-lead` 汇总裁决。

---

## Phase 5: 完成

### 5.1 提交

```text
fix({scope}): {短描述}

{根因说明 + 修复方式}

Refs: .claude/artifacts/requirements-{task-id}.md
```

### 5.2 汇报

```markdown
## Bug 已修复：{标题}

**Task ID**: {task-id}
**根因**: {一句话}
**修复方式**: {一句话}
**回归测试**: {N} 个
**安全审计**: ✓ / 不适用
**视觉验证**: ✓ / 不适用
**最终裁决**: ✓ / 不适用
```
