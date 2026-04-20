# LangChain / LangGraph — 框架知识

> last_updated: 2026-04-18
> 状态：[权威] GitHub releases API 抓取最新版

---

## 1. 版本状态（2026-04-18）

### LangChain

| 包 | 最新版 | 日期 |
|---|---|---|
| **langchain-core** | **1.3.0** | 2026-04-17 |
| **langchain-anthropic** | **1.4.1** | 2026-04-17 |
| **langchain-openai** | **1.1.14** | 2026-04-16 |
| **langchain-text-splitters** | **1.1.2** | 2026-04-16 |

### LangGraph

| 包 | 最新版 | 日期 |
|---|---|---|
| **langgraph** | **1.1.8** | 2026-04-17 |
| **langgraph-prebuilt** | **1.0.10** | 2026-04-17 |
| **langgraph-cli** | **0.4.23** | 2026-04-17 |
| **langgraph-checkpoint** | **4.0.2** | — |

---

## 2. LangChain 近期关键变化

### langchain-core 1.3.0（2026-04-17）

- Add chat model + LLM invocation params to traceable metadata
- Restore cloud metadata IPs + link-local range in **SSRF policy**
- Harden private **SSRF utilities**（多次强化，安全加固主线）
- 流式 metadata 性能优化
- 依赖 bump：pytest 9.0.3 / pygments 2.20（CVE-2026-4539）

### langchain-anthropic 1.4.1（2026-04-17）

- **Support Opus 4.7 features** (#36847) — 关键新特性
- **Support adaptive thinking mode** (#36293) — Sonnet 4.6 新能力支持
- Strip null `encrypted_content` from compaction blocks — **context compaction** 兼容
- langsmith bump 到 0.7.31

### langchain-openai 1.1.14（2026-04-16）

- 用 **SSRF-safe transport** 做 image token counting（安全）

### langchain-text-splitters 1.1.2（2026-04-16）

- `split_text_from_url` 使用 SSRF-safe transport
- `RecursiveJsonSplitter` 修复空 dict 值静默数据丢失
- 支持 spacy tests with Python 3.14

---

## 3. LangGraph 核心（1.1.x 稳定系列）

### 1.1.8（2026-04-17）

- 修复：`add_handler` 严格类型检查阻断 OTel instrumentation
- CLI / prebuilt / checkpoint 同步更新

### 1.1.7（2026-04-17）

- **Time travel 修复**：回到 interrupt 节点时行为正确

### 1.0.10 prebuilt

- Handle injected `NotRequired` keys（TypedDict 注入兼容）

### 关键能力（1.1 系列持续演进）

1. **StateGraph / MessageGraph**：状态机 + 条件边
2. **Checkpointers**：`MemorySaver` / `SqliteSaver` / `PostgresSaver` 持久化
3. **Interrupt / Human-in-the-loop**：interrupt 节点支持 time travel
4. **Streaming**：节点级流式输出
5. **Multi-agent patterns**：Supervisor / Swarm / Hierarchical
6. **OpenTelemetry tracing**：W3C trace context 支持

---

## 4. 与 Anthropic / OpenAI Agent SDK 的定位差异

| 维度 | LangGraph | Claude Agent SDK | OpenAI Agents SDK |
|---|---|---|---|
| 抽象层级 | 低（手搓图） | 高（bundle 了 CLI） | 中 |
| 多模型 | ✅ 任意 Provider | ❌ 只 Claude | ❌ 只 OpenAI |
| 持久化 | ✅ Checkpointer 成熟 | ✅ session + subagent transcript | ✅ SQLAlchemy/Mongo session |
| HITL | ✅ interrupt + time travel | 部分（hooks） | 有 guardrail |
| Tracing | LangSmith + OTel | OTel（v0.1.60+） | OpenAI tracing + OTel |
| Sandbox | ❌（交由用户） | ✅ Claude Code 内置 | ✅ v0.14.0 SandboxAgent |

**调度建议**：
- 需要多 provider 混用、自己定义图：LangGraph
- 只用 Claude、要最小样板：Claude Agent SDK
- 只用 OpenAI、要 workspace 持久化：OpenAI Agents SDK SandboxAgent

---

## 5. LangSmith（配套 Tracing / Eval）

- 活跃：langsmith 0.7.31（2026-04）
- LangChain / LangGraph 均已默认发送 trace
- Dataset / prompt hub / evaluation 全套

---

## 6. 官方资源

- LangChain：`https://github.com/langchain-ai/langchain`
- LangGraph：`https://github.com/langchain-ai/langgraph`
- 文档：`https://python.langchain.com/` / `https://langchain-ai.github.io/langgraph/`
- LangSmith：`https://smith.langchain.com/`

## 7. 下轮研究

- [ ] langchain-core 2.0 roadmap
- [ ] LangGraph Cloud（托管版）定价
- [ ] LangGraph Studio 最新能力
- [ ] LangServe 是否仍维护
