# Harness Engineering — 2026 最新形态

> last_updated: 2026-04-18
> 注：本条目与 Harness 团队自身治理对齐，涵盖通用理论 + 团队落地

---

## 1. 定义

**Harness Engineering**：把多 agent / 多工具 / 多模型 **编排在可控框架**中的工程方法学。
- 上游：Prompt Engineering（单 LLM 输入）
- 本层：Harness（多 agent 协作 / 调度 / 资源 / 安全）
- 下游：Production（部署 / 监控 / SLA）

---

## 2. 2026 主流 Harness 产品形态

### A. CLI / 终端形 Harness

- **Claude Code**（Anthropic 官方，v2.1.114，2026-04-18）
- **OpenAI Codex CLI**（Rust，v0.122.0-alpha.10）
- **Cline**（VS Code extension）
- **Aider**（CLI）

### B. SDK 形 Harness（库内编排）

- **claude-agent-sdk-python** v0.1.63
- **openai-agents-python** v0.14.2
- **langgraph** 1.1.8
- **crewai** 1.14.2

### C. 社区 Harness 项目（[权威] industry-watch GitHub 热榜）

| 项目 | Stars | 定位 |
|---|---|---|
| `everything-claude-code` | 160K | Agent harness 性能优化系统 |
| `oh-my-claudecode` | 30K | Claude Code **多 Agent 编排** harness |
| `zeroclaw` | 30K | 全自主个人助理基础设施 |
| `CLI-Anything` | 31K | 让任意软件 agent-native |
| `nanobot` | 40K | 超轻量个人 agent |

**关键信号**：**Claude Code 已成为 harness 开发的"反应堆"**，社区二次封装数量远超 OpenAI Codex 侧。

---

## 3. Harness 核心设计维度

### 调度（Scheduling）

| 维度 | 选项 |
|---|---|
| 串行 / 并行 | 串行稳、并行快但易打架 |
| 显式图 vs 隐式对话 | LangGraph 图 vs AutoGen conversation |
| 时序模型 | 同步、异步、事件驱动 |
| HITL 节点 | interrupt / approval gate |

### 工具使用（Tool Use）

- Tool schema（JSON schema / Pydantic）
- **Skills 抽象**（包含多 tool 的任务包）
- **MCP 协议**（跨 host 标准化）

### 记忆（Memory）

- 短期：对话历史
- 中期：session 级 checkpoint（SQLite / Postgres）
- 长期：semantic memory / knowledge graph / **Letta (MemGPT)**
- 人格：system prompt + 用户偏好持久化

### 人机协作（Human-in-the-Loop）

- interrupt 节点（LangGraph）
- approval gate（工具执行前弹确认）
- hooks（Claude Code）
- **time travel**（LangGraph 1.1.7 修复：回到 interrupt 节点行为正确）

### 安全 / 权限

- 沙箱（Claude Code sandbox / OpenAI SandboxAgent）
- 能力最小化（Manifest capabilities）
- SSRF / 出站控制（LangChain core 1.3.0 强化 SSRF policy）
- 密钥扫描（git commit 前 gitleaks）
- Prompt injection 防护（Claude Sonnet 4.6 公告强调 major improvement）

### 观测 / Tracing

- W3C TRACEPARENT/TRACESTATE（Agent SDK v0.1.60 原生支持）
- LangSmith
- OpenAI tracing
- OpenTelemetry 统一

---

## 4. 多 Agent 模式（2026 主流）

| 模式 | 代表 |
|---|---|
| **Supervisor**（主控 + worker） | LangGraph 官方 examples / CrewAI Crew |
| **Swarm**（自主协调） | Kimi K2.5 Agent Swarm / OpenAI Swarm |
| **Hierarchical**（多层 sub-agent） | Claude Code subagent / Harness Team Role 体系 |
| **Debate / Reflection** | 多 agent 互评 |
| **Pipeline / Assembly Line** | 顺序流水线 |
| **Mixture-of-Agents (MoA)** | Together AI 等推的多模型投票 |

---

## 5. Harness 反模式（社区共识）

1. **并行派工调度过度**：agent 互相冲突，不如串行
2. **工具列表过长**：>30 个 tool 模型选不准
3. **记忆不分层**：啥都塞长期，污染上下文
4. **无 interrupt 节点**：全自主跑飞
5. **日志不结构化**：事后无法复现

---

## 6. 与 Harness 团队 v23 铁律的映射

本团队 `/Users/mumuxsy/.claude/CLAUDE.md` 的铁律：

| 铁律 | 行业实践依据 |
|---|---|
| 严禁并行执行子代理 | **industry consensus：串行 > 并行**（避免 agent 互搏） |
| 严禁 SendMessage 恢复停止 Agent | **transcript 可读但不可越权唤醒** — 参考 Claude Agent SDK subagent 设计 |
| 每次调度前后 ★ Insight | **observability principle** — OTel trace 的"用户可见版" |
| Agent prompt 修改经 prompt-engineer | **change management** — 与 LangSmith Prompt Hub 思路一致 |
| 质量闭环不可跳过 | **HITL + guardrail 标配** |

本团队做法与 2026 业界 Harness 主流方向**高度一致**。

---

## 7. Hooks 范式（Claude Code v2 / Harness v23 独创部分）

Harness v23 通过 settings.json hooks 在 CLI 层插入物理约束：

- `PreToolUse` 拒绝直改核心文件
- `PostToolUse(WebSearch)` 失败时软注入 fallback
- `PreCompact` 保存铁律快照
- `UserPromptSubmit` 注入协议
- `Stop` 校验 ★ Insight / 播放 done 音
- `PreToolUse(Agent)` 物理拦截并行派

这是**"不信任 LLM 自律"** 的 harness 思想的前沿实现——**LLM 无法绕开 shell 级约束**。

---

## 8. 下轮研究

- [ ] `everything-claude-code` 的 harness 优化具体技术
- [ ] Harness v23 hooks 与 Claude Code 官方 hooks 的关系
- [ ] OpenAI SandboxAgent 的 capabilities 在 harness 安全模型中的位置
- [ ] Agent Swarm（Kimi K2.5）vs Supervisor（LangGraph）实测
