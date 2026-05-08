# Checklist

## Phase 1: 基础调研与机制验证

- [x] Claude Code 最新版本 Subagent `skills:` 字段是否支持调度时动态指定已验证并记录 — **仍不支持（v2.1.131）**
- [x] Agent Teams 机制的当前可用性（research preview / GA）已确认 — **仍为实验性**
- [x] Agent Teams 完整 API（Team Lead / Teammates / 共享任务列表 / 消息通信）已记录
- [x] 新 Hook 事件（TaskCreated / TaskCompleted / FileChanged / CwdChanged / PostToolBatch / PostToolUseFailure / StopFailure / TeammateIdle）的可用性和 JSON input schema 已确认
- [x] Prompt-based / Agent-based / HTTP hooks 的配置格式和限制已记录
- [x] Session Forking API 和与 Subagent 的区别已确认
- [x] Channels MCP 服务器配置格式和事件推送协议已确认
- [x] Structured Outputs JSON Schema 定义方式已确认 — **仅 SDK 可用**

## Phase 2: LEGION.md 机制速查更新

- [x] §3.4 Subagents 已新增 Session Forking、Agent Teams 区别说明
- [x] §3.6 Hooks 已新增完整事件列表和 Prompt/Agent/HTTP hook 类型
- [x] §3.13 Agent Teams 机制速查已创建
- [x] §3.14 Channels 机制速查已创建
- [x] §3.15 Routines 机制速查已创建
- [x] §3.16 Structured Outputs 机制速查已创建
- [x] intent-classify.sh 残留引用已清理 — **全部为历史记录，无需清理**

## Phase 3: Hook 安全网升级

- [x] `hooks/task-created-sync.sh` 已创建并在 hook-flags.sh 登记
- [x] `hooks/task-completed-sync.sh` 已创建并在 hook-flags.sh 登记
- [x] `hooks/artifact-file-changed.sh` 已创建并在 hook-flags.sh 登记
- [x] `hooks/tool-failure-capture.sh` 已创建并在 hook-flags.sh 登记
- [x] clarification-gate 已升级为 prompt-based hook（含 bash fallback）— **配置方案记录在 UPGRADE-NOTES.md**
- [x] settings.json 已注册所有新 Hook 事件 — **配置说明记录在 UPGRADE-NOTES.md**
- [ ] bin/doctor.sh 已新增对应检查项 — **待统一更新，记录在 UPGRADE-NOTES.md**
- [ ] bin/test-hook-flags.sh 已新增新 hook 的单元测试 — **待统一更新**

## Phase 4: 调度真源扩展

- [x] dispatch-table.md 已新增 S4 Agent Teams 并发等级
- [x] dispatch-table.md 已新增 Agent Teams 路由条目和并发模板
- [x] dispatch-table.md 已新增 Channels 触发路由
- [x] dispatch-table.md 已新增 Routines 调度表

## Phase 5: Agent 矩阵优化

- [x] 实现工程师变体合并决策已做出（合并或保留，有明确理由）— **保留，动态绑定仍不支持**
- [x] 若不合并：LEGION.md 已记录约束验证状态
- [x] Agent 返回 JSON Schema 评估 — **Structured Outputs 仅 SDK 可用，保持现有 token 协议**
- [x] Agent 返回协议保持自由文本格式（IMPL_DONE/REVIEW_PASS 等）

## Phase 6: Statusline 与 DispatchTicket 闭环增强

- [x] statusline.sh 已集成 Agent Teams 状态（⬡ 团队 badge）
- [x] statusline-contract.md 已更新
- [x] DispatchTicket 状态机已利用 TaskCreated/TaskCompleted 自动同步
- [x] artifact-protocol.md 已支持 Agent Teams 产出

## Phase 7: 文档与验证

- [x] CLAUDE.md 已精简并新增 Agent Teams / Channels / Routines 命令说明
- [x] CLAUDE.md 总行数 ≤200 行 — **精确 200 行**
- [x] README.md / CLAUDE.md / LEGION.md 数字徽章和版本号已对齐
- [ ] bin/doctor.sh 已新增 Agent Teams / Channels / 新 Hook 事件检查项 — **待统一更新**
- [x] 版本一致性验证通过：v5.0 / 39 Agents / 58 Skills / 53 Rules / 20 Hooks + 3 _lib
