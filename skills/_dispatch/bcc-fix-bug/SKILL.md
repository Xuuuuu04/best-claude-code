---
name: bcc-fix-bug
description: Bug 修复流水线（简化版）。当用户报告 bug、错误或异常行为时使用。
disable-model-invocation: true
---

# Bug 修复流水线

`$ARGUMENTS` 是 bug 描述。执行以下简化流水线——相比新功能流水线，bug 修复通常范围更小、流程更短。

---

## 预备：生成 Task ID

形如 `bug-YYYYMMDD-NN`。

---

## Phase 1: 定位与分析

### 1.1 派遣 explorer 调研

```
任务：调研以下 bug 的可能原因和代码位置。
Bug 描述：{$ARGUMENTS}

请使用 git log / grep / 文件阅读定位到具体文件和行号。
如无法复现或无法定位，明确说明。
```

### 1.2 派遣 product-analyst 确认影响

```
任务：基于 explorer 的调研报告，分析该 bug 的影响范围和修复优先级。
调研报告：{explorer 的 artifact 路径}
Task ID: {task-id}

请产出简化版需求文档：
- 受影响的功能
- 修复后的验收标准（必须有可复现的测试用例）
- 优先级判断
- 是否需要同时修复关联问题

写入 .claude/artifacts/requirements-{task-id}.md。
```

---

## Phase 2: 架构与范围锁定

### 2.1 派遣 architect

```
任务：为以下 bug 设计修复方案。
需求文档：.claude/artifacts/requirements-{task-id}.md
Explorer 调研：{路径}

请产出：
- 根因分析（在 architecture-{task-id}.md 中）
- 修复方案（最小化改动，不顺便重构）
- scope-lock 文件（通常一个 bug 对应 1 个 scope-lock）

特别重要：scope-lock 中必须要求先写一个**能复现 bug 的失败测试**，再修复代码让测试通过（TDD）。
```

### 2.2 审查（可选快速路径）

对于简单 bug（<=20 行改动），可以跳过 quality-guardian 的架构审查，直接进入实现。对于涉及安全、并发、数据完整性的 bug，**必须**审查。

---

## Phase 3: 实现

### 3.1 派遣对应 implementer

根据 scope-lock 技术栈选择。注意 scope-lock 应包含 TDD 要求：

```
任务：按 TDD 方式修复 bug。
Scope Lock: .claude/artifacts/scope-lock-{task-id}-1.md

步骤：
1. 先编写能复现 bug 的失败测试
2. 运行测试确认它失败（red）
3. 最小改动修复代码
4. 运行测试确认它通过（green）
5. 运行完整测试套件确认无回归
```

### 3.2 代码审查

派遣 quality-guardian 做 code-review，**特别关注**：
- 是否真正修复了根因而不只是掩盖症状
- 是否有回归风险（其他场景可能被影响）
- 测试是否真的能复现原 bug

---

## Phase 4: 回归验证

派遣 quality-guardian 做 functional-test：
- 运行完整测试套件
- 设计可能被影响的相关场景用例
- 确认 bug 确实已消失

---

## Phase 5: 完成

### 5.1 更新 changelog（如项目维护）

在变更日志中记录此次修复，便于追踪。

### 5.2 提交

```
fix({scope}): {短描述}

{根因说明 + 修复方式}

Fixes: {bug 报告/Issue ID，如有}
Refs: .claude/artifacts/requirements-{task-id}.md
```

### 5.3 向用户报告

```markdown
## Bug 已修复：{Bug 标题}

**Task ID**: {task-id}
**根因**: {一句话}
**修复方式**: {一句话}
**添加的回归测试**: {N} 个

### 变更摘要
{列出修改的文件}

### 潜在影响
{可能被影响的相关场景，如已验证则说明}
```

---

## 何时升级到 new-feature 流水线

如果在 Phase 1 或 Phase 2 发现：
- bug 根因涉及架构缺陷，修复会连带改动多个模块
- 修复需要 >3 个 scope-lock
- 需要 schema 变更

则停止当前流水线，向用户建议"这不是简单 bug，建议以功能迭代方式处理"，并可运行 `/bcc-new-feature` 流水线。

## 异常处理

- **explorer 无法定位**：要求用户提供更多信息（重现步骤、日志、环境）
- **bug 无法复现**：向 quality-guardian 明确说明，它会在功能测试中尝试构造复现
- **修复引入回归**：退回到 Phase 3，要求 implementer 重新设计修复方案
