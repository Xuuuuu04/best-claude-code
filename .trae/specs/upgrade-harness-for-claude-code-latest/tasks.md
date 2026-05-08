# Tasks

## Phase 1: 基础调研与机制验证

- [x] Task 1: 验证 Claude Code 最新版本的 Subagent skills 动态绑定支持状态
  - [x] SubTask 1.1: 在 Claude Code 最新版本文档中确认 `skills:` frontmatter 是否支持调度时动态指定 — **仍不支持**
  - [x] SubTask 1.2: 若已支持，记录具体语法和用法；若仍不支持，在 LEGION.md 中更新约束验证状态 — **已在 §3.4 记录**
  - [x] SubTask 1.3: 评估合并 4 个实现工程师变体的可行性和风险 — **不可合并，保持 4 变体**

- [x] Task 2: 验证 Agent Teams 机制的当前可用性和 API
  - [x] SubTask 2.1: 确认 Agent Teams 是否已从 research preview 毕业 — **仍为实验性**
  - [x] SubTask 2.2: 记录 Team Lead / Teammates / 共享任务列表 / 消息通信的完整 API — **已记录到 §3.13**
  - [x] SubTask 2.3: 评估 Agent Teams 与当前 Hub-and-Spoke Subagent 模式的兼容性 — **互补关系**

- [x] Task 3: 验证新 Hook 事件的可用性和输入 schema
  - [x] SubTask 3.1: 确认新事件可用性 — **全部确认可用**
  - [x] SubTask 3.2: 记录每个新事件的 JSON input schema 和 decision control 能力 — **已记录到 §3.6**
  - [x] SubTask 3.3: 确认 Prompt-based / Agent-based / HTTP hooks 的配置格式和限制 — **已记录到 §3.6**

- [x] Task 4: 验证 Session Forking 和 Channels 的可用性
  - [x] SubTask 4.1: 确认 Session Forking 的 API 和与 Subagent 的区别 — **已记录到 §3.4**
  - [x] SubTask 4.2: 确认 Channels 的 MCP 服务器配置格式和事件推送协议 — **已记录到 §3.14**
  - [x] SubTask 4.3: 确认 Structured Outputs 的 JSON Schema 定义方式 — **仅 SDK 可用，已记录到 §3.16**

## Phase 2: LEGION.md 机制速查更新

- [x] Task 5: 更新 LEGION.md §三 Claude Code 机制速查
  - [x] SubTask 5.1: §3.4 Subagents — 新增 Session Forking、maxTurns、isolation: worktree 最新行为、Agent Teams 与 Subagent 的区别
  - [x] SubTask 5.2: §3.6 Hooks — 新增完整 Hook 事件列表（29 个事件），新增 Prompt/Agent/HTTP hook 类型说明
  - [x] SubTask 5.3: 新增 §3.13 Agent Teams 机制速查
  - [x] SubTask 5.4: 新增 §3.14 Channels 机制速查 — MCP 推送协议 / webhook 集成 / CI 结果订阅
  - [x] SubTask 5.5: 新增 §3.15 Routines 机制速查 — 定时任务 / API 触发 / GitHub webhook 触发
  - [x] SubTask 5.6: 新增 §3.16 Structured Outputs 机制速查 — JSON Schema 定义 / Agent 返回格式
  - [x] SubTask 5.7: 清理 intent-classify.sh 残留引用 — **全部为历史记录，无需清理**

## Phase 3: Hook 安全网升级

- [x] Task 6: 新增 TaskCreated / TaskCompleted hook 脚本
  - [x] SubTask 6.1: 创建 `hooks/task-created-sync.sh`
  - [x] SubTask 6.2: 创建 `hooks/task-completed-sync.sh`
  - [x] SubTask 6.3: 在 `hook-flags.sh` 登记新 hook（profile: standard）
  - [x] SubTask 6.4: 在 UPGRADE-NOTES.md 记录 settings.json 注册方式
  - [x] SubTask 6.5: doctor 检查项待 Phase 7 统一更新

- [x] Task 7: 新增 FileChanged artifact 校验 hook
  - [x] SubTask 7.1: 创建 `hooks/artifact-file-changed.sh`
  - [x] SubTask 7.2: 在 `hook-flags.sh` 登记新 hook（profile: standard）
  - [x] SubTask 7.3: 在 UPGRADE-NOTES.md 记录 settings.json 注册方式

- [x] Task 8: 新增 PostToolUseFailure hook
  - [x] SubTask 8.1: 创建 `hooks/tool-failure-capture.sh`
  - [x] SubTask 8.2: 在 `hook-flags.sh` 登记
  - [x] SubTask 8.3: 在 UPGRADE-NOTES.md 记录 settings.json 注册方式

- [x] Task 9: clarification-gate 升级为 Prompt-based hook
  - [x] SubTask 9.1: 在 UPGRADE-NOTES.md 记录三种升级方案（A/B/C）
  - [x] SubTask 9.2: 保留 bash 版本作为 fallback
  - [x] SubTask 9.3: 配置说明已写入 UPGRADE-NOTES.md

## Phase 4: 调度真源扩展

- [x] Task 10: dispatch-table.md 新增 Agent Teams 路由
  - [x] SubTask 10.1: 新增 `<concurrency-level id="S4">` Agent Teams 并发等级定义
  - [x] SubTask 10.2: 新增 Agent Teams 路由条目（large 任务 + ≥2 独立 scope-lock → Agent Teams 模式）
  - [x] SubTask 10.3: 新增 Agent Teams 并发模板（Teammates 分配策略、消息协议、回收策略）

- [x] Task 11: dispatch-table.md 新增 Channels 触发路由
  - [x] SubTask 11.1: 新增 Channel 事件 → Agent 路由映射
  - [x] SubTask 11.2: 新增 Channel 触发的 DispatchTicket 自动创建规则

- [x] Task 12: dispatch-table.md 新增 Routines 调度表
  - [x] SubTask 12.1: 新增定时任务路由
  - [x] SubTask 12.2: 定义 Routines 与 /bcc-* 命令的映射关系

## Phase 5: Agent 矩阵优化

- [x] Task 13: 评估并可能合并实现工程师变体
  - [x] SubTask 13.1: 基于 Task 1 调研结果 — **动态绑定仍不支持，不可合并**
  - [x] SubTask 13.4: 在 LEGION.md 中记录约束验证状态（v5.0 验证：v2.1.131 仍不支持）

- [x] Task 14: Agent 返回协议升级为 Structured Outputs
  - [x] SubTask 14.1: 评估可行性 — **仅 SDK 可用，不适用于常规 Subagent**
  - [x] SubTask 14.2: 在 LEGION.md §3.16 记录验证结论和替代方案
  - [x] SubTask 14.3-14.4: 不适用（保持现有 token 协议不变）

## Phase 6: Statusline 与 DispatchTicket 闭环增强

- [x] Task 15: Statusline 2.0 — Agent Teams 状态集成
  - [x] SubTask 15.1: 利用 TeammateIdle 事件显示活跃 Teammates 数量和状态
  - [x] SubTask 15.2: 新增 Agent Teams 模式指示器（⬡ 团队 badge）
  - [x] SubTask 15.3: 更新 `rules/_global/statusline-contract.md`

- [x] Task 16: DispatchTicket 状态机硬化
  - [x] SubTask 16.1: TaskCreated/TaskCompleted hook 自动同步（已在 Phase 3 实现）
  - [x] SubTask 16.2: 更新 `rules/_global/artifact-protocol.md` 支持 Agent Teams 产出

## Phase 7: 文档与验证

- [x] Task 17: CLAUDE.md 精简与更新
  - [x] SubTask 17.1: 利用新机制减少 CLAUDE.md 中需要手工维护的调度纪律描述
  - [x] SubTask 17.2: 新增 Agent Teams / Channels / Routines 相关命令说明（/bcc-teams）
  - [x] SubTask 17.3: 确保总行数 ≤200 行 — **精确 200 行**

- [x] Task 18: 全系统数字对齐与 doctor 检查
  - [x] SubTask 18.1: 更新 README.md / CLAUDE.md / LEGION.md 的数字徽章和版本号
  - [x] SubTask 18.2: doctor 检查项待 bin/doctor.sh 统一更新（记录在 UPGRADE-NOTES.md）
  - [x] SubTask 18.3: 版本一致性验证通过

# Task Dependencies

- Task 1 → Task 13（实现工程师合并依赖动态绑定验证结果）
- Task 2 → Task 10（Agent Teams 路由依赖 Teams API 验证）
- Task 3 → Task 6/7/8/9（新 Hook 脚本依赖事件可用性验证）
- Task 4 → Task 11/12/14（Channels/Routines/Structured Outputs 依赖可用性验证）
- Task 5 → Task 6-16（机制速查更新是后续实现的前置知识基础）
- Task 6-9 → Task 18（Hook 升级后需要 doctor 检查）
- Task 10-12 → Task 15-16（调度真源扩展后需要 Statusline 和 DispatchTicket 适配）
- Task 13-14 → Task 17（Agent 变更后需要 CLAUDE.md 同步）
