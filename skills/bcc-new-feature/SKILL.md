---
name: bcc-new-feature
description: 完整的新功能开发流水线，从需求分析到代码提交。当用户要求实现一个新功能、新页面、新接口或新模块时使用。
disable-model-invocation: true
---

# 新功能开发流水线

`$ARGUMENTS` 是用户的需求描述。执行以下五阶段流水线，你作为调度器不直接写任何代码。

---

## 预备：生成 Task ID

1. 使用 `date +%Y%m%d` 获取当前日期
2. 扫描 `.claude/artifacts/` 看今天是否已有 task-id
3. 生成形如 `feat-YYYYMMDD-NN`（NN 是当天序号）

---

## Phase 1: 需求分析

### 1.1 派遣 product-analyst

向用户简短说明"开始需求分析"，然后派遣：

```
任务：分析以下需求并产出结构化需求文档。
Task ID: {task-id}
原始需求：{$ARGUMENTS}

请将分析结果写入 .claude/artifacts/requirements-{task-id}.md。
如遇关键决策不明，使用 AskUserQuestion 向用户确认。
```

### 1.2 审查需求

派遣 quality-guardian：

```
审查类型：requirements-review
审查对象：.claude/artifacts/requirements-{task-id}.md

请检查需求文档的完整性、可测试性和边界覆盖。
将审查结果写入 .claude/artifacts/review-requirements-{task-id}.md。
```

### 1.3 处理审查结果

- **通过**：向用户展示需求拆分摘要，使用 AskUserQuestion 确认进入架构阶段
- **需修改**：将 Critical/Warning 反馈给 product-analyst 修订，然后重新审查
- **驳回**：停止流水线，向用户汇报并请求调整需求

---

## Phase 2: 架构设计

### 2.1 派遣 architect

```
任务：基于需求文档产出架构设计和范围锁定。
需求文档：.claude/artifacts/requirements-{task-id}.md

请产出：
- 架构设计文档：.claude/artifacts/architecture-{task-id}.md
- 每个 Task 对应一个 scope-lock：.claude/artifacts/scope-lock-{task-id}-{n}.md
- 在 architecture 文档末尾标注 scope-lock 间的并行关系
```

### 2.2 审查架构

派遣 quality-guardian：

```
审查类型：architecture-review
审查对象：.claude/artifacts/architecture-{task-id}.md 和所有 .claude/artifacts/scope-lock-{task-id}-*.md

请特别检查 scope-lock 的精确度和禁止事项完整性。
将审查结果写入 .claude/artifacts/review-architecture-{task-id}.md。
```

### 2.3 处理审查结果

- **通过**：向用户展示架构方案和 scope-lock 清单，确认后进入实现
- **需修改 / 驳回**：反馈给 architect 修订

---

## Phase 3: 实现

### 3.1 解析并行执行图

从 architecture 文档读取 scope-lock 间的依赖关系，构建执行批次：

```
Batch 1（可并行）：scope-lock-{task-id}-1, scope-lock-{task-id}-2
Batch 2（依赖 Batch 1）：scope-lock-{task-id}-3
Batch 3（依赖 Batch 2）：scope-lock-{task-id}-4, scope-lock-{task-id}-5
```

### 3.2 为每个 scope-lock 选择 implementer

根据 scope-lock 中的 `技术栈` 字段选择：
- `frontend` → `implementer-frontend`
- `backend` → `implementer-backend`
- `mobile` → `implementer-mobile`
- `infra` → `devops`

### 3.3 按批次派遣（前台优先）

**默认前台阻塞**派遣——一次一个 implementer，等它完成并产出 artifact 后再派下一个，用户可以实时看到每个 Agent 的工作过程。

仅在以下情况考虑并行派遣该批次所有 implementer：
- 同批次有 ≥3 个无依赖的 Task
- 用户明确同意并行（不同意则串行）

并行时仍建议**每次最多 2-3 个**后台任务，不要一次性全丢。

```
任务：实现 scope-lock 中定义的范围。
Scope Lock: .claude/artifacts/scope-lock-{task-id}-{n}.md

请严格遵循 scope-lock 的白名单、禁止事项和接口契约。
完成后将实现报告写入 .claude/artifacts/impl-report-{task-id}-{n}.md。
```

### 3.4 每个 implementer 完成后，派遣代码审查

```
审查类型：code-review
实现报告：.claude/artifacts/impl-report-{task-id}-{n}.md
关联 scope-lock：.claude/artifacts/scope-lock-{task-id}-{n}.md

请特别验证 scope 合规性和安全性。
将审查结果写入 .claude/artifacts/review-code-{task-id}-{n}.md。
```

### 3.5 处理代码审查结果

- **通过**：进入下一批次
- **需修改**：反馈给原 implementer，不扩大 scope（遗留问题记在 report 中）
- **驳回**：停止该 scope 的工作，评估是否需要回到 Phase 2 调整架构

---

## Phase 4: 集成测试

所有 scope-lock 完成并通过代码审查后，派遣 quality-guardian：

```
审查类型：functional-test
审查对象：所有 impl-report-{task-id}-*.md
关联需求：.claude/artifacts/requirements-{task-id}.md

请运行完整测试套件，并设计边界用例验证所有 Task 的验收标准。
将测试报告写入 .claude/artifacts/review-functional-{task-id}.md。
```

如功能测试发现 Task 未满足验收标准，定位到对应 scope-lock 并派 implementer 修复，然后重新走代码审查 + 功能测试。

---

## Phase 5: 完成

### 5.1 更新项目知识

静默派遣 update-project Skill 刷新 project-knowledge（避免 CLAUDE.md 和 project-knowledge Skill 信息过期）。

### 5.2 提交

使用 `git add` + `git commit`（HEREDOC 格式）提交所有变更。提交信息格式：

```
{type}({scope}): {短描述}

{详细描述，引用 task-id}

Refs: .claude/artifacts/requirements-{task-id}.md
```

### 5.3 向用户报告

```markdown
## 任务完成：{需求标题}

**Task ID**: {task-id}
**实现的 scope-lock 数量**: {N}
**修改的文件**: {M}
**新增测试用例**: {K}
**审查通过**: ✓ 需求 / ✓ 架构 / ✓ 代码（N 轮）/ ✓ 功能测试

### 变更摘要
{列出主要变更}

### 后续建议
- {如果 quality-guardian 报告了 Warning 或 Suggestion，在这里列出}
- {如果有 impl-report 中标注的遗留问题，在这里列出}
```

---

## 异常处理

- **用户中途取消**：保留所有 artifact 文件，向用户确认是否保留或清理
- **某阶段反复审查失败**：3 次修订仍未通过 → 停止流水线，向用户汇报并请求干预
- **Subagent 调用失败**：捕获错误，向用户汇报具体阶段和失败原因
- **上下文压缩**：PostCompact hook 会注入恢复提示，确认你仍是调度器身份

## 并行化的边界

Claude Code 支持后台 Subagent，但本流水线**默认前台串行**——让用户看到每一步的实时进度。只有在用户明确同意、且同批次有多个无依赖 Task 时才启用并行，并且一次最多 2-3 个，不一口气丢所有。

这是为了保证：
- 用户可以及时打断或纠偏
- 单 Agent 失败容易定位
- 调度器自己不会在状态混乱中失控
