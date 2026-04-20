# Agent SDK 横向对比 — Claude / OpenAI / LangGraph / CrewAI / AutoGen

> last_updated: 2026-04-18

---

## 1. 最新版本矩阵（2026-04-18）

| SDK | 最新版 | 日期 | 模型绑定 |
|---|---|---|---|
| **claude-agent-sdk-python** | v0.1.63 | 2026-04-18 | Claude only |
| **openai-agents-python** | v0.14.2 | 2026-04-18 | OpenAI 为主 + LiteLLM |
| **langgraph** | 1.1.8 | 2026-04-17 | 任意 |
| **crewai** | 1.14.2 | 2026-04-17 | 任意 |
| **autogen** (python-v0.7.5) | 0.7.5 | 2025-09-30 | 任意 |
| **dspy** | 3.1.3 | 2026-02-05 | 任意 |

---

## 2. Claude Agent SDK（[权威] Anthropic）

### v0.1.62 (2026-04-17)

- **顶层 `skills` 参数**（`ClaudeAgentOptions`）
  - `skills="all"` — 启用所有已发现 skills
  - `skills=["skill-a", "skill-b"]` — 命名列表
  - `skills=[]` — 显式禁用
  - 取代之前手动配置 `allowed_tools` + `setting_sources`

### v0.1.60 (2026-04-16)

- **Subagent transcript helpers**：`list_subagents()` / `get_subagent_messages()`
- **Distributed tracing**：W3C TRACEPARENT/TRACESTATE 贯穿 CLI 子进程；`pip install claude-agent-sdk[otel]`
- **Cascading session deletion**：`delete_session()` 联动删除 subagent transcript 目录
- Bug：`setting_sources=[]` 不再被静默忽略

### 与 Claude Code 的关系

- Agent SDK **bundle 了 Claude CLI**（v2.1.114）；写 Python 的同时获得 terminal 能力
- Claude Code 本身是"参考实现"，SDK 让外部开发者复用同一运行时

---

## 3. OpenAI Agents SDK（[权威] OpenAI）

### v0.14.0（2026-04-15）— Sandbox Agents

**Beta 新表面**：运行 agent 时带 persistent isolated workspace

- `SandboxAgent`：带 sandbox 默认的 `Agent`
  - `default_manifest` / sandbox instructions / capabilities / `run_as`
- `Manifest`：workspace 合约
  - files / directories / local_files / local_directories / **Git repos** / env / users / groups / mounts
- `SandboxRunConfig`：per-run sandbox 配置（client creation 等）
- **Snapshots + Resume**：agent 可以**跨运行续接工作**
- Agent 可以处理真实文件、运行命令、编辑 repo、生成 artifact

### v0.14.1/0.14.2（2026-04-15/18）

- Sandbox extra path grants
- **MongoDB session backend**
- LiteLLM / 工具来源元数据持久化
- Sandbox compaction model parsing 放宽

### 与 Claude Code workspace 对比

| 维度 | Claude Code | OpenAI SandboxAgent |
|---|---|---|
| 运行时 | Node CLI 二进制 | Python SDK |
| Workspace | 当前 cwd / project dir | Manifest 声明 |
| Git repos | 依赖 host | Manifest 原生支持 |
| 跨运行 resume | Session file | Snapshots |
| 用户切换 | host 账号 | `run_as` 参数 |

---

## 4. LangGraph（多 provider）

详见 `frameworks/langchain-langgraph.md`

**差异化**：
- 唯一提供 **time travel（跳回 interrupt 节点）** 的 agent 框架
- 最成熟的 **checkpointer** 生态（memory/sqlite/postgres）
- 最灵活的图结构

---

## 5. CrewAI v1.14.2（2026-04-17）

- **Role-based multi-agent**：定义角色、任务、工具、crew
- 适合"团队协作"心智模型；学习曲线最低
- 支持任意 provider（OpenAI / Anthropic / local / Ollama）
- 有 **CrewAI Studio** 可视化
- 持续活跃（1.14.2rc1 在 2026-04-15、1.14.2a5 在 2026-04-15 迭代）

---

## 6. Microsoft AutoGen（v0.7.5，2025-09-30）

- **Multi-agent conversation**：agent 自然语言互相调度
- `AgentChat` 高级 API + `Core` 低级 API
- **Note：2025-Q4 后 release 节奏明显放缓**（v0.7.5 后 5 个月无 minor），[待验证] 是否被 AutoGen 2.0 / AG2 替代
- [待验证] 社区分叉 "AG2" 的相对热度

---

## 7. DSPy v3.1.3（2026-02-05）

- **Prompt Programming**：用 `Signature` + `Module` 声明式写 prompt
- **Optimizer**：`BootstrapFewShot` / `MIPROv2` 自动优化
- Stanford NLP 维护；学界接受度高
- 3.1.x 系列稳定

---

## 8. 选型矩阵（2026-04 基于上述）

| 场景 | 推荐 |
|---|---|
| Claude 独用 + 最小代码 | **Claude Agent SDK** |
| OpenAI 独用 + workspace 持久化 | **OpenAI Agents SDK + SandboxAgent** |
| 跨 provider + 复杂图 + HITL | **LangGraph** |
| 多 agent 协作（角色模型） | **CrewAI** |
| RAG 重 / 文档密集 | **LlamaIndex AgentWorkflow** |
| 需要 prompt 自动优化 | **DSPy** |
| 研究性多 agent 对话 | AutoGen（但要警惕维护状态） |

---

## 9. 下轮研究

- [ ] AutoGen 是否已被替换；AG2 / Autogen 2.0 路线图
- [ ] `Haystack 2` 最新版在 Agent 领域的定位
- [ ] **Letta (MemGPT)** / **Mem0** 记忆层框架最新版
- [ ] **Pydantic AI** 官方发布后的热度
- [ ] **LlamaIndex AgentWorkflow** vs CrewAI 实测
