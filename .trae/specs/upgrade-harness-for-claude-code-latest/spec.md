# Agent Legion Harness 升级迭代 Spec

## Why

当前 harness 系统（v4.7）基于 Claude Code v2.1.59+ 的扩展机制构建，经过 v1→v4.7 共 7 轮进化，已形成 39 Agents / 58 Skills / 53 Rules / 17 Hooks 的成熟体系。但 Claude Code 自 2025 年底以来经历了重大版本更新，引入了 Agent Teams、Channels、Routines、新 Hook 事件、Prompt/Agent-based Hooks、Session Forking、Agent SDK、Structured Outputs 等全新机制。当前系统未利用这些新能力，存在显著的升级空间。同时，系统在实战中暴露的架构瓶颈（如 Subagent 静态 skills 绑定、Hub-and-Spoke 拓扑限制、手工调度开销）可通过新机制获得结构性改善。

## What Changes

### A. 机制层升级（利用 Claude Code 新特性）

- **Agent Teams 集成**：利用原生 Agent Teams 机制替代当前纯 Hub-and-Spoke 调度模式，支持 Team Lead + Teammates 并行协作、共享任务列表和消息通信
- **新 Hook 事件利用**：集成 `TaskCreated` / `TaskCompleted` / `FileChanged` / `CwdChanged` / `PostToolBatch` / `PostToolUseFailure` / `StopFailure` / `TeammateIdle` 等新事件，增强确定性保障
- **Prompt-based / Agent-based Hooks**：将当前纯 bash hook 中需要语义判断的逻辑迁移到 prompt/agent hooks，减少关键词正则误判
- **Session Forking 支持**：利用 session forking 替代部分 Subagent 调度场景，降低冷启动开销
- **Channels 集成**：支持外部事件（CI 结果、Webhook、监控告警）推送到运行中的会话
- **Structured Outputs**：Agent 返回结构化 JSON 而非自由文本 token，提高解析可靠性

### B. 架构层优化（解决实战瓶颈）

- **Subagent 动态 Skill 绑定**：研究 Claude Code 最新版本是否已解除 `skills:` 静态绑定限制，若已解除则合并 4 个实现工程师变体为 1 个通用实现工程师
- **DispatchTicket 状态机硬化**：利用 `TaskCreated` / `TaskCompleted` hook 事件自动同步 DispatchTicket 状态，减少手工更新遗漏
- **Statusline 2.0**：利用 `TeammateIdle` 事件和 Agent Teams 状态 API 增强 statusline 信息密度
- **Artifact 校验增强**：利用 `FileChanged` hook 实时校验 artifact 写入合规性，替代当前 PostToolUse 延迟校验

### C. 文档与机制对齐

- **LEGION.md §三 机制速查更新**：同步 Claude Code 最新版本的机制变化（新 hook 事件、新 frontmatter 字段、Agent Teams API 等）
- **dispatch-table.md 扩展**：新增 Agent Teams 并发模式、Channels 触发路由、Routines 定时任务调度表
- **CLAUDE.md 精简**：利用新机制减少 CLAUDE.md 中需要手工维护的调度纪律描述

## Impact

- Affected specs: 调度真源（dispatch-table）、Hook 安全网、Agent 矩阵、Statusline 协议、Artifact 协议
- Affected code: `hooks/` 全部脚本、`agents/` 全部定义、`output-styles/legion-dispatch.md`、`statusline.sh`、`bin/doctor.sh`、`CLAUDE.md`、`LEGION.md`、`rules/_global/` 全局规则

## ADDED Requirements

### Requirement: Agent Teams 集成

系统 SHALL 支持基于 Claude Code 原生 Agent Teams 机制的并行协作模式，作为当前 Hub-and-Spoke Subagent 调度的补充。

#### Scenario: 大型功能开发使用 Agent Teams

- **WHEN** 任务档位为 large 且涉及 ≥2 个独立 scope-lock
- **THEN** 主会话可选择启用 Agent Teams 模式，spawn Teammates 分别负责不同 scope，Team Lead 负责整合
- **AND** Teammates 之间通过 message/broadcast 通信，共享任务列表
- **AND** 并发安全约束仍由 dispatch-table 的 S0-S3 等级控制

#### Scenario: 小型任务保持 Subagent 模式

- **WHEN** 任务档位为 small/medium
- **THEN** 保持当前 Subagent 调度模式不变，不引入 Agent Teams 开销

### Requirement: 新 Hook 事件集成

系统 SHALL 利用 Claude Code 新增的 Hook 事件增强确定性保障。

#### Scenario: TaskCreated/TaskCompleted 自动同步 DispatchTicket

- **WHEN** Agent Teams 创建或完成任务
- **THEN** `TaskCreated` / `TaskCompleted` hook 自动更新 `legion-session.json` 的 gate_status 和 evidence
- **AND** 无需主会话手工写入状态更新

#### Scenario: FileChanged 实时校验 artifact

- **WHEN** `.claude/artifacts/` 下的文件被修改
- **THEN** `FileChanged` hook 触发 `validate-artifacts.sh` 实时校验
- **AND** 校验失败时通过 `additionalContext` 注入警告

#### Scenario: PostToolUseFailure 审计工具失败

- **WHEN** 任何工具调用失败
- **THEN** `PostToolUseFailure` hook 记录失败详情到 `logs/tool-failure-audit.jsonl`
- **AND** 替代当前 `tool-failure-audit.sh` 的 `PostToolUse` matcher 方案

### Requirement: Prompt/Agent-based Hooks 语义判断

系统 SHALL 将当前纯 bash 关键词正则 hook 中需要语义判断的逻辑迁移到 prompt/agent hooks。

#### Scenario: clarification-gate 语义升级

- **WHEN** 用户提交 prompt
- **THEN** clarification-gate 使用 prompt-based hook 进行语义判断（而非关键词正则）
- **AND** 误判率显著低于当前 bash 方案

#### Scenario: review-gate 保持 bash

- **WHEN** review-gate 只需计数比对（实现工程师数 vs 高级代码审查师数）
- **THEN** 保持 bash 实现，因为纯数值比较不需要语义判断

### Requirement: Session Forking 支持

系统 SHALL 支持 Session Forking 作为 Subagent 调度的轻量替代。

#### Scenario: 只读研究任务使用 Fork

- **WHEN** 任务为只读研究（代码库研究员 / 技术调研专家）
- **THEN** 可使用 session forking 替代 Subagent 调度
- **AND** fork 共享父会话上下文，减少冷启动 token 消耗

#### Scenario: 写入任务保持 Subagent

- **WHEN** 任务涉及文件写入
- **THEN** 保持 Subagent 隔离模式，避免 fork 污染主会话上下文

### Requirement: Channels 外部事件集成

系统 SHALL 支持 Channels 机制接收外部事件推送。

#### Scenario: CI 结果自动推送

- **WHEN** CI pipeline 完成
- **THEN** 通过 Channel 推送结果到运行中的会话
- **AND** 高级功能测试师 可基于 CI 结果自动调整测试策略

#### Scenario: Webhook 触发调度

- **WHEN** GitHub PR 事件触发
- **THEN** 通过 Channel 推送到会话，自动启动 code-review 流水线

### Requirement: Structured Outputs

系统 SHALL 支持 Agent 返回结构化 JSON 输出。

#### Scenario: 返回 token 升级为结构化 JSON

- **WHEN** Agent 完成任务
- **THEN** 返回结构化 JSON（包含 token、artifact 路径、严重/一般/轻微计数、duration 等）
- **AND** 主会话和 hook 可直接 `jq` 解析，无需正则匹配自由文本 token

### Requirement: Subagent 动态 Skill 绑定研究

系统 SHALL 研究 Claude Code 最新版本是否已解除 `skills:` 静态绑定限制。

#### Scenario: 动态绑定已支持

- **WHEN** Claude Code 支持 Subagent 的 `skills:` 字段在调度时动态指定
- **THEN** 合并 4 个实现工程师变体为 1 个通用实现工程师，通过调度时动态加载技术栈 Skill
- **AND** 减少维护 4 个几乎相同的 Agent 定义

#### Scenario: 动态绑定仍不支持

- **WHEN** Claude Code 仍限制 `skills:` 为静态绑定
- **THEN** 保持当前 4 变体设计，但在 LEGION.md 中记录此约束的最新验证状态

## MODIFIED Requirements

### Requirement: Hook 安全网

当前 17 个主 hook + 3 个 `_lib` 辅助脚本 SHALL 扩展支持新 Hook 事件类型。`hook-flags.sh` 的 `_HOOK_MIN_PROFILE` 数组 SHALL 登记所有新增 hook。`bin/doctor.sh` SHALL 新增对应检查项。

### Requirement: 调度真源

`dispatch-table.md` SHALL 新增 Agent Teams 并发模式路由、Channels 触发路由、Routines 定时任务调度表。并发等级定义 SHALL 扩展覆盖 Agent Teams 场景。

### Requirement: Statusline 协议

`statusline.sh` SHALL 利用 `TeammateIdle` 事件和 Agent Teams 状态 API 增强信息密度，显示活跃 Teammates 数量和状态。

### Requirement: LEGION.md 机制速查

§三 SHALL 同步 Claude Code 最新版本的机制变化，包括新 Hook 事件完整列表、Agent Teams API、Session Forking 用法、Channels 协议、Structured Outputs 格式、新 frontmatter 字段等。

## REMOVED Requirements

### Requirement: intent-classify.sh bash 分类器

**Reason**: v3.9 已删除，但 LEGION.md 仍有残留引用。彻底清理所有残留引用，确保文档一致性。

**Migration**: 已由模型自判替代，无需额外迁移。
