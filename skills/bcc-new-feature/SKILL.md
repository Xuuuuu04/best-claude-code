---
name: bcc-new-feature
description: 完整的新功能开发流水线，从需求分析到代码提交。适用于新功能、新页面、新接口和新模块。
disable-model-invocation: true
---

# 新功能开发流水线

`$ARGUMENTS` 是用户需求。执行完整链路：**需求分析 → 需求审查 → 架构设计 → 范围规划 → 架构审查 → 实现 → 代码审查 → 安全审计（如适用）→ 功能测试 → 视觉测试（如适用）→ 最终裁决（里程碑 / 上线前）**。

调度真源：`rules/_global/dispatch-table.md`。若本 Skill 与调度表冲突，以调度表为准。

---

## 预备 A：续传判断

如果 `$ARGUMENTS` 以 `resume ` 开头（如 `resume feat-20260423-01`），进入续传模式：

1. 扫描 `.claude/artifacts/*-{task-id}*.md`
2. 读取头部 `状态` 字段，结合 artifact 类型判断进度
3. 若卡在某个 reviewer/tester 环节，从该环节继续，而不是从头重跑

续传判定优先级：
- 仅 `requirements accepted` → 从架构阶段开始
- 有 `architecture accepted` 无 `scope-lock` → 从范围规划开始
- `scope-lock accepted` 无 `impl-report` → 从实现阶段开始
- `impl-report` 有、`review-code` 无 → 从代码审查开始
- `review-code` 有、`review-security` / `review-functional` 无 → 从对应门控阶段开始

---

## 预备 B：Task ID

生成 `feat-YYYYMMDD-NN`。

---

## Phase 1: 需求分析

### 1.1 派遣 `product-analyst`

```text
任务：分析以下需求并产出结构化 requirements 文档。
Task ID: {task-id}
原始需求：{$ARGUMENTS}

请写入 .claude/artifacts/requirements-{task-id}.md。
如存在关键决策不明，使用 AskUserQuestion 追问用户。
```

### 1.2 派遣 `requirements-reviewer`

```text
任务：审查 requirements 文档的完整性、可测试性、边界和风险。
对象：.claude/artifacts/requirements-{task-id}.md

请写入 .claude/artifacts/review-requirements-{task-id}.md。
```

### 1.3 处理审查结果

- 通过：进入架构阶段
- 需修改：反馈给 `product-analyst` 修订，再重审
- 驳回：停止流水线，向用户汇报缺口

---

## Phase 2: 架构设计与范围规划

### 2.1 派遣 `architect`

```text
任务：基于 requirements 产出系统设计。
需求文档：.claude/artifacts/requirements-{task-id}.md

请写入 .claude/artifacts/architecture-{task-id}.md。
重点给出：
- 技术选型
- 模块划分
- 接口契约摘要
- 数据流
- 异常与边界
- ADR
```

### 2.2 派遣 `scope-planner`

```text
任务：基于 requirements + architecture 产出 scope-lock 和执行依赖图。
需求文档：.claude/artifacts/requirements-{task-id}.md
架构文档：.claude/artifacts/architecture-{task-id}.md

请产出：
- .claude/artifacts/scope-lock-{task-id}-{n}.md
- 如需汇总批次，写 .claude/artifacts/scope-plan-{task-id}.md
```

### 2.3 派遣 `architecture-reviewer`

```text
任务：审查 architecture 与 scope-lock 的完整性、边界和可执行性。
对象：
- .claude/artifacts/architecture-{task-id}.md
- .claude/artifacts/scope-lock-{task-id}-*.md
- 可选：.claude/artifacts/scope-plan-{task-id}.md

请写入 .claude/artifacts/review-architecture-{task-id}.md。
```

### 2.4 处理审查结果

- 通过：进入实现阶段
- 需修改 / 驳回：反馈给 `architect` 或 `scope-planner`，按责任归属修订

---

## Phase 3: 实现

### 3.1 解析执行批次

从 `scope-plan-{task-id}.md` 或 scope-lock 依赖说明中构建批次，例如：

```text
Batch 1: scope-lock-{task-id}-1, scope-lock-{task-id}-2
Batch 2: scope-lock-{task-id}-3（依赖 Batch 1）
```

并发只允许发生在同一 Batch 内，且必须满足调度表 `S2` 硬规则：scope-lock 白名单文件无交集、输出 `impl-report-*` 路径唯一、验证命令可独立运行、不共享会被改写的数据库 / 浏览器 session / 部署目标。并发启动前必须向用户说明并发对象、互不冲突依据和回收顺序。

### 3.2 派遣对应 implementer

根据 scope-lock 中的技术栈字段选择：
- `frontend` → `implementer-frontend`
- `backend` → `implementer-backend`
- `mobile` → `implementer-mobile`
- `miniprogram` → `miniprogram-dev`
- `database` → `database-engineer`
- `ml` → `ml-engineer`
- `infra` → `devops`

派遣提示至少包含：

```text
任务：实现 scope-lock 中定义的范围。
Scope Lock: .claude/artifacts/scope-lock-{task-id}-{n}.md

请严格遵循：
- 白名单
- 禁止事项
- 接口契约
- 验证命令

完成后写入 .claude/artifacts/impl-report-{task-id}-{n}.md。
```

### 3.3 代码审查

每个 implementer 完成后，派遣 `code-reviewer`：

```text
任务：做代码审查。
实现报告：.claude/artifacts/impl-report-{task-id}-{n}.md
关联 scope-lock：.claude/artifacts/scope-lock-{task-id}-{n}.md

请写入 .claude/artifacts/review-code-{task-id}-{n}.md。
```

多个 `impl-report` 的代码审查可按调度表 `S1` 并发，但必须保证每个审查输出文件唯一，且输入实现报告已冻结。

### 3.4 安全审计（按需强制）

满足以下任一条件，必须派遣 `security-auditor`：
- 后端/API/DB/认证/权限相关改动
- 配置、部署、依赖、环境变量相关改动
- 处理敏感数据、日志、外部输入

```text
任务：对本次实现做安全专项审计。
对象：
- .claude/artifacts/impl-report-{task-id}-{n}.md
- .claude/artifacts/review-code-{task-id}-{n}.md
- 相关代码文件

请写入 .claude/artifacts/review-security-{task-id}.md。
```

### 3.5 处理审查结果

- 通过：进入下一批次或测试阶段
- 需修改：反馈给原 implementer，不扩大 scope
- 驳回：停止该 scope，必要时退回架构或范围规划阶段

---

## Phase 4: 测试与验收

### 4.1 派遣 `functional-tester`

```text
任务：验证 requirements 的验收标准，并做回归测试。
需求文档：.claude/artifacts/requirements-{task-id}.md
实现报告：所有 .claude/artifacts/impl-report-{task-id}-*.md

请写入 .claude/artifacts/review-functional-{task-id}.md。
```

### 4.2 派遣 `visual-tester`（仅 UI 可见变更）

若本次改动涉及用户可见界面，派遣：

```text
任务：验证用户可见界面的布局、状态和关键交互。
需求文档：.claude/artifacts/requirements-{task-id}.md
实现报告：相关 impl-report

请写入 .claude/artifacts/review-visual-{task-id}.md。
```

### 4.3 处理测试结果

- 通过：进入完成阶段
- 需修改：定位到对应 scope-lock，退回实现 → 代码审查 → 安全审计（如适用）→ 测试
- 驳回：停止流程并向用户汇报阻塞项

### 4.4 派遣 `test-lead`（里程碑 / 上线前）

若本功能属于里程碑、发布前、客户交付前或用户明确询问“能否验收/上线”，必须派遣 `test-lead`：

```text
任务：基于功能、视觉和安全证据做最终裁决。
输入：
- .claude/artifacts/review-functional-{task-id}.md
- .claude/artifacts/review-visual-{task-id}.md（如有 UI）
- .claude/artifacts/review-security-{task-id}.md（如适用）

请写入 .claude/artifacts/verdict-{task-id}.md。
```

---

## Phase 5: 完成

### 5.1 更新项目知识

静默调用 `/bcc-update-project` 刷新项目知识。

### 5.2 提交

```text
{type}({scope}): {短描述}

{详细描述，引用 task-id}

Refs: .claude/artifacts/requirements-{task-id}.md
```

### 5.3 向用户汇报

```markdown
## 任务完成：{需求标题}

**Task ID**: {task-id}
**scope-lock 数量**: {N}
**实现文件数**: {M}
**代码审查**: ✓
**安全审计**: ✓ / 不适用
**功能测试**: ✓
**视觉测试**: ✓ / 不适用
**最终裁决**: ✓ / 不适用

### 变更摘要
- ...

### 后续建议
- ...
```
