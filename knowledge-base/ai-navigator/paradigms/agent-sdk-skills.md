# Agent SDK & Skills 范式 — 2026 最新思考

> last_updated: 2026-04-18
> 核心观点：2026 Q1-Q2 三大厂商同时押注"Skills + Sandbox workspace + MCP"的三段式架构

---

## 1. 三段式架构趋势（[已验证]）

```
┌──────────────────────────────────────────────────┐
│        编排层（Orchestrator / Graph / Crew）       │
│    LangGraph / AutoGen / Agents SDK / CrewAI     │
├──────────────────────────────────────────────────┤
│         运行时（Workspace / Sandbox）              │
│ Claude Code / OpenAI SandboxAgent / Cline        │
├──────────────────────────────────────────────────┤
│          能力层（Skills + MCP Tools）              │
│ Claude Skills / Codex Catalog / MCP Servers      │
└──────────────────────────────────────────────────┘
```

**2026 Q2 共识**：
- "Tools" 太细粒度 → 抽象为 **Skills**（多 tool + 配置 + 指南 + prompt 封装）
- "Chat" 太散 → 抽象为 **Workspace / Sandbox**（持久化文件系统 + git + env）
- "Private integration" 太定制 → 抽象为 **MCP Server**（协议标准化）

---

## 2. Claude Skills（Anthropic 最早提出）

[权威] `https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview`

### 定义

Skill = 一个可被 Claude 自动发现与调用的**技能包**，包含：
- 指南（`SKILL.md`）
- 触发条件（何时用）
- 参数 schema
- 实际执行体（bash / Python / 外部 API / MCP）

### 调用方式

在 `ClaudeAgentOptions`（Agent SDK v0.1.62+）：

```python
from claude_agent_sdk import ClaudeAgentOptions

options = ClaudeAgentOptions(
    skills="all",          # 启用所有已发现 skill
    # skills=["powerpoint", "excel-analytics"],  # 或命名列表
    # skills=[],           # 或显式禁用
)
```

### Skills 公开仓

- `anthropics/skills`（2026-04-16 公开）
- 知识工作类：`anthropics/knowledge-work-plugins`（2026-04-17）
- Excel / Word / PowerPoint / 各类文档 skill

### 与传统 Tools 差异

| 维度 | Tool | Skill |
|---|---|---|
| 粒度 | 单函数 | 任务型（多 tool + 流程） |
| 元数据 | JSON schema | Markdown 指南 + schema |
| 发现 | 显式传入 | 自动索引 |
| 复用 | 跨项目需手动拷贝 | 公开仓 / 目录 |
| 组合 | 难 | 可链式 |

---

## 3. OpenAI Codex Skills Catalog

[权威] 2026-04 活跃

- 对标 Claude Skills，形态类似
- 绑定 Codex CLI
- 社区贡献 / 官方精选
- [待验证] 是否跨 model（ChatGPT / API）统一

---

## 4. Sandbox Agents 范式（OpenAI v0.14.0）

### 核心概念

| 概念 | 含义 |
|---|---|
| `Manifest` | workspace 声明（files / dirs / Git repos / env / users / mounts） |
| `SandboxAgent` | 带 sandbox 默认的 Agent class |
| `SandboxRunConfig` | per-run sandbox 配置 |
| Snapshots | 跨运行 resume |
| Capabilities | sandbox 授予的细粒度权限 |

### 与 Claude Code 对比

- **Claude Code**：CLI 形态，workspace 是当前 cwd
- **OpenAI SandboxAgent**：SDK 形态，workspace 由 Manifest 声明
- **本质相同**：agent 获得持久化文件系统 + 可执行 shell + 可操作 git

---

## 5. MCP 作为协议层（详见 `frameworks/mcp.md`）

- 三大模型厂商（Anthropic / Google / xAI）原生支持
- OpenAI 通过 `mcp-proxy` 桥接
- Claude in Excel (2026-04) 让非技术用户也能用 MCP connectors

---

## 6. 新兴概念（2026-Q2 HF Papers）

### 1. "Don't Retrieve, Navigate" — Distilling Enterprise Knowledge into Navigable Agent Skills

[权威] HF paper (2026-04)

- 不再用 RAG 检索，而是把企业知识**蒸馏为 navigable skills**
- 结构化导航优于文本检索
- 对 RAG 现有方案构成挑战

### 2. "Dive into Claude Code: The Design Space of Today's and Future AI Agent Systems"

[权威] HF paper (2026-04)

- 系统性分析 Claude Code 设计空间
- 提出 agent system 设计维度分类
- 学界开始把 Claude Code 作为研究对象

### 3. Agent Swarm（Kimi K2.5）

[权威] Moonshot `Kimi-K2.5` model card

- 单 agent → 自主协调的 **swarm-like 执行**
- 任务分解为并行 sub-task
- 动态实例化 domain-specific agent
- 对标 Multi-Agent Debate / Supervisor pattern 的下一代

---

## 7. 设计原则总结

1. **Skill-first**：把能力以"技能包"形式发布，比直接传 tool list 优
2. **Workspace-persistent**：agent 需要跨运行的文件系统和状态
3. **Protocol-over-integration**：用 MCP 接外部，避免每家一套
4. **Swarm > Single agent**：复杂任务用 swarm 分解，但需要好的 supervisor
5. **Time travel + HITL**：interrupt / approval gate 成为标配（LangGraph 领先）
6. **Tracing**：W3C trace context 贯穿（Claude Agent SDK v0.1.60 已落地）

---

## 8. 下轮研究

- [ ] Claude Skills、OpenAI Catalog、MCP 之间的互操作（能否把 MCP server 打包为 skill）
- [ ] Agent Swarm 实测（Kimi K2.5 vs LangGraph Supervisor pattern）
- [ ] "Navigate don't retrieve" 论文细节
- [ ] Sandbox Agent 在企业合规场景的数据驻留
- [ ] Skills marketplace / App Store 化
