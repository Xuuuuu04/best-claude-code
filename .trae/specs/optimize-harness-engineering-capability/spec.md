# Harness Engineering 能力极致优化 Spec

## Why

当前 Agent Legion 系统虽已形成 39 Agents / 58 Skills / 53 Rules / 20 Hooks 的成熟体系，但在 Claude Code 平台机制利用、信息传递效率、Agent 矩阵合理性、Skill/Rules 分层设计上存在结构性不足。核心问题：Subagent 调度时信息丢失严重、Skills 作为"共有提示词封装"未发挥 Claude Code 原生 Skill 机制的全部能力、Rules 全局展开浪费 context 且缺乏精细路径门控、Agent 矩阵存在职责重叠和关键角色缺失。本 Spec 旨在系统性解决这些问题，让每个模块彻底灵活结合、配合默契，实现顶尖 Harness Engineering 能力。

## What Changes

### A. 信息传递体系重构（解决 Subagent 信息丢失）

- **上下文摘要协议**：定义标准化的 Subagent 调度上下文传递格式，主会话在调度时通过指令显式传递核心要点（需求摘要、约束条件、验收标准、关键决策）
- **Artifact 文件中转强化**：将 PRD 等完整信息写入 artifact 文件，Subagent 通过 Read 工具按需读取
- **混合模式落地**：摘要通过调度指令传递核心要点，完整信息通过 artifact 文件传递，Subagent 先读摘要理解大局、需要细节时读文件
- **Subagent 系统提示模板升级**：每个 Agent 的系统提示增加"上下文获取协议"段落，指导 Agent 如何主动获取所需信息

### B. Skills 机制深度适配

- **Skill 分层重构**：将当前"共有提示词封装"的 Skill 重新分类为三类：
  - **知识型 Skill**（reference）：领域知识、API 规范、代码风格——作为参考资料按需加载
  - **流程型 Skill**（procedure）：多步骤操作流程——`disable-model-invocation: true`，仅用户 `/bcc-*` 触发
  - **能力型 Skill**（capability）：`context: fork`，在隔离上下文中执行复杂任务
- **Skill paths 门控**：为知识型 Skill 添加 `paths:` frontmatter，仅在操作匹配文件时自动加载，减少 context 浪费
- **Skill 支持文件利用**：将大段参考文档从 SKILL.md 移入 `references/` 子目录，SKILL.md 只保留导航索引，Claude 按需读取
- **BCC 命令体系扩展**：基于现有 BCC 设计哲学，新增关键缺失命令

### C. Rules 精细门控

- **全局 Rules 审计**：审计 `_global/` 下所有 Rule，将可路径门控的规则添加 `paths:` frontmatter
- **Rules 分层策略**：
  - 会话级（无 paths）：仅保留真正全局性的规则（调度纪律、安全约束、返回协议）
  - 路径级（有 paths）：技术栈规范、文件格式约定、测试策略等按文件类型/目录触发
- **Rule 去重与合并**：消除 CLAUDE.md / Rules / Skills 之间的重复内容

### D. Agent 矩阵优化

- **职责重叠合并**：识别职责高度重叠的 Agent 并合并
- **关键角色新增**：识别缺失的通用场景并新增专门 Agent
- **Agent 系统提示标准化**：统一信息获取协议、返回协议、Artifact 协议段落
- **Agent Skills 绑定优化**：基于 Skill 分层重构结果，优化每个 Agent 的 `skills:` 绑定

### E. BCC 命令体系扩展

- **设计哲学文档化**：记录 BCC 命令的设计原则（快捷入口、流程编排、质量门控）
- **缺失命令补全**：新增关键 BCC 命令覆盖常见开发场景

## Impact

- Affected specs: Skills 体系、Rules 体系、Agent 矩阵、调度真源、BCC 命令体系
- Affected code: `skills/` 全部目录结构、`rules/` 全部文件、`agents/` 全部定义、`commands/` 全部命令、`CLAUDE.md`、`LEGION.md`

## ADDED Requirements

### Requirement: Subagent 上下文传递协议

系统 SHALL 定义标准化的 Subagent 调度上下文传递格式，确保主会话向 Subagent 传递信息时零丢失。

#### Scenario: 大型 PRD 调度实现工程师

- **WHEN** 主会话接收大量 PRD 信息后调度实现工程师
- **THEN** 主会话通过调度指令传递核心摘要（需求目标、关键约束、验收标准、技术决策），同时将完整 PRD 写入 `requirements-*.md` artifact
- **AND** 实现工程师系统提示包含"上下文获取协议"段落，指导 Agent 先读摘要、需要细节时 `Read` artifact 文件
- **AND** 调度指令中包含 artifact 文件路径引用

#### Scenario: Code Review 调度审查师

- **WHEN** 实现工程师完成实现后调度代码审查师
- **THEN** 主会话传递实现摘要 + impl-report artifact 路径 + scope-lock artifact 路径
- **AND** 审查师系统提示包含"审查上下文获取协议"，指导 Agent 读取 impl-report 和 scope-lock

### Requirement: Skill 三层分类体系

系统 SHALL 将所有 Skill 按知识型/流程型/能力型三层分类，并采用不同的加载策略。

#### Scenario: 知识型 Skill 按需加载

- **WHEN** Skill 为知识型（如 `frontend-development`、`backend-development`）
- **THEN** 添加 `paths:` frontmatter 限制自动加载范围
- **AND** 大段参考文档移入 `references/` 子目录，SKILL.md 只保留导航索引
- **AND** Subagent 绑定此类 Skill 时，全量注入（因为 Subagent 无法按需读取 references/）

#### Scenario: 流程型 Skill 仅用户触发

- **WHEN** Skill 为流程型（如 `bcc-doctor`、`bcc-fast-fix`）
- **THEN** 设置 `disable-model-invocation: true`
- **AND** 仅通过 `/bcc-*` 命令触发
- **AND** SKILL.md 包含完整操作流程，不需要 references/

#### Scenario: 能力型 Skill 隔离执行

- **WHEN** Skill 为能力型（需要独立上下文执行的复杂任务）
- **THEN** 设置 `context: fork`
- **AND** 可指定 `agent:` 使用特定 Subagent 类型
- **AND** 适用于需要大量探索但不污染主会话上下文的场景

### Requirement: Rules 精细门控

系统 SHALL 对所有 Rules 实施精细的路径门控，减少 context 浪费。

#### Scenario: 全局 Rules 最小化

- **WHEN** Rule 内容为真正全局性的约束（调度纪律、安全红线、返回协议）
- **THEN** 保持无 `paths:` frontmatter，会话启动时加载
- **AND** 全局 Rules 总数控制在 5 个以内

#### Scenario: 技术栈 Rules 路径门控

- **WHEN** Rule 内容为特定技术栈规范（前端规范、后端规范、测试策略）
- **THEN** 添加 `paths:` frontmatter 限制触发范围
- **AND** 仅在操作匹配文件时加载，减少无关 context

#### Scenario: Rule 去重

- **WHEN** Rule 内容与 CLAUDE.md 或 Skill 内容重复
- **THEN** 保留最合适的单一来源，其他改为引用
- **AND** 原则：事实性约束 → CLAUDE.md，流程性指导 → Skill，条件性规范 → Rule with paths

### Requirement: Agent 矩阵优化

系统 SHALL 对 Agent 矩阵进行合并、拆分和新增，消除职责重叠、补全关键角色。

#### Scenario: 职责重叠 Agent 合并

- **WHEN** 两个 Agent 的职责高度重叠（描述相似、技能绑定相同、产出 artifact 类型相同）
- **THEN** 合并为一个 Agent，通过系统提示中的条件分支处理差异

#### Scenario: 关键角色新增

- **WHEN** 存在常见开发场景但无专门 Agent 覆盖
- **THEN** 新增专门 Agent，遵循现有 Agent 定义规范

#### Scenario: Agent 系统提示标准化

- **WHEN** 更新任何 Agent 定义
- **THEN** 系统提示包含标准化段落：角色定义、上下文获取协议、返回协议、Artifact 协议、工具使用策略

### Requirement: BCC 命令体系扩展

系统 SHALL 基于现有 BCC 设计哲学扩展命令体系。

#### Scenario: BCC 设计哲学

- **WHEN** 设计新 BCC 命令
- **THEN** 遵循原则：快捷入口（一键触发复杂流程）、流程编排（多步骤自动化）、质量门控（强制检查点）
- **AND** 命名规范：`bcc-{action}-{target}` 或 `bcc-{workflow}`

#### Scenario: 缺失命令补全

- **WHEN** 识别到常见开发场景缺少快捷入口
- **THEN** 新增对应 BCC 命令 Skill

## MODIFIED Requirements

### Requirement: Skills 体系

当前 58 个 Skill SHALL 按三层分类重构，每个 Skill 的 SKILL.md 添加分类标签和对应的 frontmatter 优化（paths、disable-model-invocation、context）。支持文件（references/） SHALL 用于存放大段参考文档，SKILL.md 只保留导航索引和核心指令。

### Requirement: Agent 系统提示

所有 Agent 的系统提示 SHALL 新增标准化段落：上下文获取协议（如何主动获取所需信息）、返回协议（token 格式）、Artifact 协议（产出规范）。当前各 Agent 提示中分散的协议描述 SHALL 统一收敛到这些标准化段落。

### Requirement: Rules 体系

当前 53 条 Rules SHALL 审计并重新分类：全局级（无 paths，≤5 条）、路径级（有 paths，按文件类型/目录触发）。与 CLAUDE.md 和 Skills 重复的内容 SHALL 去重，保留最合适的单一来源。

## REMOVED Requirements

无。本 Spec 不移除任何现有功能，仅优化和扩展。
