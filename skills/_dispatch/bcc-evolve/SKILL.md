---
name: bcc-evolve
description: 系统进化引擎。分析 Auto Memory 和 Agent Memory，将积累的学习固化为 Rules、Skills 或 Agent 改进。应每 1-2 周运行。
disable-model-invocation: true
---

# 系统进化

这是 Agent Legion 的核心飞轮。它实现"观察 → 反思 → 进化 → 验证"的闭环。

此 Skill 会修改配置文件（Rules、Skills、Agent 定义），**必须**经用户审批才能生效。

---

## Phase 1: 审计（在隔离上下文中进行）

由于需要读取大量文件，此 Phase 应通过派遣 explorer 完成：

```
任务：全面审计 Agent Legion 系统的记忆和配置。

请读取并分析以下内容：

1. **Auto Memory**
   - ~/.claude/projects/*/memory/MEMORY.md
   - ~/.claude/projects/*/memory/*.md

2. **Agent Memory（用户级）**
   - ~/.claude/agent-memory/product-analyst/MEMORY.md
   - ~/.claude/agent-memory/architect/MEMORY.md
   - ~/.claude/agent-memory/quality-guardian/MEMORY.md
   - ~/.claude/agent-memory/devops/MEMORY.md
   - （以及每个 Agent Memory 下的主题文件）

3. **Agent Memory（项目级）**
   - .claude/agent-memory/implementer-*/MEMORY.md
   - .claude/agent-memory/explorer/MEMORY.md

4. **现有配置**
   - 所有 ~/.claude/agents/*.md
   - 所有 ~/.claude/skills/**/*.md
   - 所有 ~/.claude/rules/**/*.md
   - ~/.claude/CLAUDE.md

5. **进化日志**
   - .claude/artifacts/evolve-log-*.md（如存在）

请将审计结果写入 .claude/artifacts/evolve-audit-{timestamp}.md，包含：
- Memory 内容按主题归类
- 现有配置清单
- 上次进化的时间和内容（如有）
```

---

## Phase 2: 分析（调度器自己完成）

读取审计报告，识别四类进化机会：

### 机会类型 1：反复出现的纠正 → 新 Rule

**判定标准**：Memory 中同类错误被提及 ≥2 次

**产出**：在 `.claude/rules/` 或 `~/.claude/rules/` 下新增 Rule
- 项目特定的 → 项目级 `.claude/rules/`
- 通用的 → 用户级 `~/.claude/rules/`

**路径限定**：如果错误只在特定文件类型出现，使用 `paths` frontmatter

### 机会类型 2：频繁使用的工作流 → 新 Workflow Skill

**判定标准**：Memory 中多次记录"先 X 再 Y 再 Z"的操作序列

**产出**：新 Skill 在 `_domain/` 或 `_dispatch/` 下
- 供 Agent 预加载的 → `_domain/`
- 供调度器触发的 → `_dispatch/`

### 机会类型 3：领域知识积累 → 新 Knowledge Skill

**判定标准**：Memory 中某一主题的条目 ≥5 条

**产出**：在 `_domain/` 或 `_reference/` 下新增 Skill
- Agent 专属的 → `_domain/`
- 可复用参考的 → `_reference/`

### 机会类型 4：冗余或冲突 → 合并/清理

**判定标准**：多个 Rules/Skills 对同一场景给出指导

**产出**：合并相关文件，删除冗余

---

## Phase 3: 生成提案

将每个进化机会表达为结构化提案。所有提案汇总到 `.claude/artifacts/evolve-proposals-{timestamp}.md`：

```markdown
# 进化提案 {timestamp}

## 提案 1: 新增 Rule — API 错误响应格式

**类型**: 新增 Rule（机会类型 1）
**触发原因**:
- Memory 条目 1: quality-guardian/MEMORY.md: "3 次审查发现 implementer-backend 使用了不一致的错误格式"
- Memory 条目 2: implementer-backend/MEMORY.md: "修正了错误响应的格式为 { error: { code, message } }"

**具体变更**:
- 新建文件: `.claude/rules/_framework/api-error-format.md`
- 路径限定: `paths: ["src/api/**/*.ts"]`
- 内容概要: 要求所有 API 错误响应使用统一格式

**预期收益**: 减少 implementer 的格式不一致，减轻 quality-guardian 的重复审查

**风险**: 如果项目存在历史遗留的不一致，可能触发大量 warning——建议仅对新代码生效

---

## 提案 2: ...

## 提案 3: 清理冗余 — ...

## 统计
- 新增 Rule: N
- 新增 Skill: M
- 合并: K
- 删除: L
- 预计节省的 Memory 条目: P
```

---

## Phase 4: 用户审批

使用 AskUserQuestion 向用户展示提案，请求逐一审批：

```
本轮进化识别了 {N} 个改进机会。

请审批每一条（可以批量批准/拒绝/选择性执行）：

提案 1: 新增 Rule - API 错误响应格式 [批准 / 拒绝 / 修改后批准]
提案 2: ...
提案 3: ...
```

对于"修改后批准"的提案，进入对话修订具体内容。

---

## Phase 5: 执行

对用户批准的提案：

1. **创建/修改文件**：按提案内容执行文件操作
2. **清理 Memory**：对于已经被固化为 Rule/Skill 的知识，从对应 Memory 文件中删除相关条目（同时更新 MEMORY.md 索引）
3. **记录进化日志**：追加到 `.claude/artifacts/evolve-log.md`：

```markdown
# 进化日志

## {timestamp}

### 已执行的变更
- [NEW] .claude/rules/_framework/api-error-format.md （来自提案 1）
- [NEW] .claude/skills/_domain/pagination-patterns/SKILL.md （来自提案 3）
- [MERGE] 合并 _lang/typescript.md 和 _lang/typescript-strict.md （来自提案 5）
- [CLEAN] 清理 ~/.claude/agent-memory/quality-guardian/error-patterns.md 中 8 条已固化的条目

### 跟踪指标
- 新 Rule 预期触发频率: 待观察
- 进化前 Memory 总行数: {N} → 进化后: {M}

### 下次审查时机
建议 {1-2 周后} 再次运行 /bcc-evolve。
```

---

## Phase 6: 向用户汇报

```markdown
## 系统进化完成

**批准执行**: {N} / {M} 个提案
**新增 Rule**: {k}
**新增 Skill**: {k}
**合并/清理**: {k}
**Memory 瘦身**: 从 {N} 行 → {M} 行

### 后续观察建议
1. 下次使用 Agent Legion 时留意新 Rule 是否按预期触发
2. 如发现新 Rule 过于严格或误触发，可手动调整或在下次 /bcc-evolve 时反馈

### 下次进化
建议时间: 约 1-2 周后，或积累 ≥10 条新 Memory 后
```

---

## 原则

- **人在回路中**：绝对不绕过用户审批直接修改配置
- **渐进而非激进**：每轮进化产出 3-7 个变更较合理，>10 个说明分析过于激进
- **偏保守**：宁可少进化一条，也不要错误固化一条（错误的 Rule 会持续产生噪音）
- **可追溯**：每条变更必须有明确的 Memory 证据支撑
- **可回退**：进化日志让用户能够追踪和回退每一条变更

---

## 异常

- **Memory 为空或接近空**：汇报"暂无足够数据进化"，建议积累使用后再试
- **提案冲突**：如发现两个提案指向同一文件的冲突修改，标记为"需人工合并"
- **缺乏 git 保护**：如 `.git` 不存在或 `.claude/` 未纳入版本控制，警告用户无法回退
