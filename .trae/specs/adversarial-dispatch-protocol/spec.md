# 对抗调度协议 + 上下文完整性 + 质疑权 设计 Spec

## Why

当前系统存在三个结构性缺陷：

1. **对抗迭代不完整**：`redeliberation-protocol` 仅覆盖实现↔代码审查，其他审查环节（需求↔需求审查、架构↔架构审查、文档↔内容审查等）都是单次通过，没有迭代闭环。对抗精神应该是系统级默认，而非局部特例。
2. **上下文传递易丢失**：用户发送长文件或大量 bug 时，主会话摘要后调度 Subagent，信息容易遗漏或偏差。Subagent 缺乏主动获取完整上下文的强制机制，也缺乏在上下文不足时拒绝执行的能力。
3. **`.claude/` 目录权限确认**：每次编辑 `.claude/` 下文件都需要手动确认，影响效率。

## What Changes

### A. Output Style 统一对抗协议

在 `output-styles/legion-dispatch.md` 中新增 `<adversarial_protocol>` 段落：

- **对抗精神声明**：对抗是默认模式，不是异常处理。每个产出环节都应经过独立审查，审查不通过则迭代修订，直到通过或穷尽。
- **通用迭代规则**：任何 A→B 审查环节，当 B 返回 REJECT 时，自动进入迭代循环。A 修订 → B 再审 → 判定。终止条件：PASS / max_rounds / judge BLOCKED。
- **动态调度**：主会话根据返回 token 中的严重/一般数动态决定迭代策略，不写死任何环节的迭代次数。
- **max_rounds**：默认 3，quality_strategy=full 时 5。主会话可根据问题严重度灵活调整。
- **穷尽处理**：max_rounds 耗尽仍 REJECT → 派遣项目管理师做根因分析（scope 缺陷→退回范围规划师；架构缺陷→退回架构师；能力边界→上报用户）。
- **`redeliberation-protocol` Skill 降级**：从独立调度 Skill 降级为参考文档，对抗迭代的通用规则由 Output Style 定义。

### B. 上下文完整性保障

在 `output-styles/legion-dispatch.md` 中新增 `<context_integrity>` 段落：

- **intake artifact**：用户发送长文件/大量信息时，主会话先将原始输入完整写入 `intake-{task-id}.md` artifact，再做摘要路由。摘要只用于路由判断，不用于传递细节。
- **强制读取规则**：调度指令中引用的 artifact 必须被 Subagent 读取后才能开始工作。未读取 artifact 就开始产出的行为视为违规。
- **新增 `NEEDS_CONTEXT` token**：Subagent 发现调度指令缺少关键上下文时，返回 `NEEDS_CONTEXT:{缺失描述}:{需要的 artifact 或信息类型}`，而非假设推进。

### C. 质疑权协议

在 `output-styles/legion-dispatch.md` 中新增 `<challenge_protocol>` 段落：

- **质疑权**：任何 Agent 有权质疑调度指令的合理性，有权拒绝执行缺乏必要上下文的任务。
- **触发条件**：调度指令缺少关键上下文、指令与 artifact 矛盾、任务目标不明确、发现安全风险、自身能力不足。
- **新增 token**：`NEEDS_CONTEXT`、`CONTRADICTION`、`RISK_BLOCKED`、`CAPABILITY_MISMATCH`。
- **AskUserQuestion 鼓励**：Agent 遇到不确定事项时，优先使用 AskUserQuestion 向用户确认，而非自行假设。

### D. 教学式解释风格融合

在 `output-styles/legion-dispatch.md` 中新增 `<explanation_style>` 段落：

- **调度层**（主会话行为）：保持极简、结构化、指示动作——指挥官风格不变。
- **解释层**（面向用户的输出）：融入教学式风格——清晰透彻、循序渐进、主动预判困惑点、鼓励思考参与。
- **Agent 层**：每个 Agent 在其专业领域内，对用户可见的产出采用教学式风格，添加有帮助的注释解释关键步骤的思考逻辑。

### E. `.claude/` 目录权限配置

在 `hooks/UPGRADE-NOTES.md` 中新增权限配置说明：

- **settings.json 配置**：`permissions.allow` 中添加 `Edit(.claude/**)` 和 `Write(.claude/**)`。
- **VS Code 扩展**：需同时配置 `claudeCode.allowDangerouslySkipPermissions: true` 和 `claudeCode.initialPermissionMode: "bypassPermissions"`。
- **defaultMode**：建议设为 `acceptEdits`，文件编辑自动通过但 Bash 命令仍需确认。

## Impact

- Affected files: `output-styles/legion-dispatch.md`、`rules/_global/artifact-protocol.md`、`hooks/UPGRADE-NOTES.md`、`skills/redeliberation-protocol/SKILL.md`、`agents/*.md`（39 个文件的上下文获取协议段落）
- Affected behavior: 主会话调度行为、Subagent 上下文获取行为、审查迭代行为

## ADDED Requirements

### Requirement: 全环节对抗迭代

系统 SHALL 在所有 A→B 审查环节实施对抗迭代，而非仅限实现↔代码审查。

#### Scenario: 需求审查驳回后自动迭代

- **WHEN** 高级需求审查师 对 资深需求分析师 的 requirements 返回 REVIEW_REJECT
- **THEN** 主会话自动进入迭代循环：派遣资深需求分析师定向修订 → 高级需求审查师再审
- **AND** 迭代最多 max_rounds 轮（默认 3，full 时 5）
- **AND** 主会话根据严重/一般数动态决定是否需要迭代

#### Scenario: 架构审查驳回后自动迭代

- **WHEN** 高级架构审查师 对 资深系统架构师 的 architecture 返回 REVIEW_REJECT
- **THEN** 同上迭代循环

#### Scenario: 内容审查驳回后自动迭代

- **WHEN** 高级内容审查师 对 文档工程师/创意策划师 的产出返回 CONTENT_REJECT
- **THEN** 同上迭代循环

#### Scenario: 迭代穷尽处理

- **WHEN** max_rounds 耗尽仍 REJECT
- **THEN** 派遣项目管理师做根因分析
- **AND** 根据根因退回对应上游 Agent 或上报用户

### Requirement: 上下文完整性保障

系统 SHALL 确保主会话向 Subagent 传递的上下文完整无遗漏。

#### Scenario: 用户发送长文件或大量信息

- **WHEN** 用户一次性发送长文件、大量 bug 描述或截图
- **THEN** 主会话先将用户原始输入完整写入 `intake-{task-id}.md` artifact
- **AND** 调度时传递摘要 + artifact 路径引用
- **AND** Subagent 必须读取引用的 artifact 后才能开始工作

#### Scenario: Subagent 发现上下文不足

- **WHEN** Subagent 读取调度指令后发现缺少关键上下文
- **THEN** 返回 `NEEDS_CONTEXT:{缺失描述}:{需要的 artifact 或信息类型}`
- **AND** 主会话收到后补充上下文或向用户 AskUserQuestion

### Requirement: 质疑权协议

系统 SHALL 赋予每个 Agent 质疑调度指令和拒绝执行的权利。

#### Scenario: 调度指令与 artifact 矛盾

- **WHEN** Agent 发现调度指令中的要求与已读取的 artifact 内容矛盾
- **THEN** 返回 `CONTRADICTION:{矛盾点描述}`
- **AND** 主会话收到后澄清矛盾或修正调度指令

#### Scenario: 发现安全风险

- **WHEN** Agent 在执行过程中发现安全风险或不可逆操作未经用户确认
- **THEN** 返回 `RISK_BLOCKED:{风险描述}`
- **AND** 主会话收到后向用户确认

#### Scenario: 能力不匹配

- **WHEN** Agent 判断自身能力不足以完成指定任务
- **THEN** 返回 `CAPABILITY_MISMATCH:{原因}`
- **AND** 主会话收到后重新路由到合适的 Agent

### Requirement: 教学式解释风格

系统 SHALL 在面向用户的输出中采用教学式解释风格。

#### Scenario: 主会话向用户解释决策

- **WHEN** 主会话需要向用户解释调度决策或审查结果
- **THEN** 采用清晰透彻的讲解方式，循序渐进，主动预判困惑点
- **AND** 使用比较、示例和分步解释提高理解度

#### Scenario: Agent 产出面向用户的内容

- **WHEN** Agent 产出文档、报告或其他面向用户的内容
- **THEN** 添加有帮助的注释解释关键步骤的思考逻辑
- **AND** 保持专业深度同时确保可理解性

## MODIFIED Requirements

### Requirement: redeliberation-protocol Skill

当前 `redeliberation-protocol` Skill SHALL 降级为参考文档。对抗迭代的通用规则由 Output Style 定义，具体环节的审查清单仍由各协议型 Skill 提供。

### Requirement: Output Style token 协议

token 协议 SHALL 新增：`NEEDS_CONTEXT`、`CONTRADICTION`、`RISK_BLOCKED`、`CAPABILITY_MISMATCH`。

### Requirement: artifact-protocol

artifact 协议 SHALL 新增 `intake-*` artifact 类型，用于保真存储用户原始输入。

## REMOVED Requirements

无。本 Spec 不移除任何现有功能，仅扩展和优化。
