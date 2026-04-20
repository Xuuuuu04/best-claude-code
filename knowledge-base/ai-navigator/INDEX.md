# AI Navigator 知识库索引（global · 真源）

> last_updated: 2026-04-18
> 维护者：ai-navigator Agent（模式 A）
> 位置（真源）：`~/.claude/knowledge-base/ai-navigator/`

---

## 使用说明

- 本文件是所有读写操作的**唯一起点**
- 每个条目含最后更新 + 状态：`[骨架]` / `[部分]` / `[完整]`
- 所有 AI 事实 MUST 带来源链接 + 日期
- 置信度：`[待验证]` / `[已验证]` / `[权威]`

---

## 📂 models/ — 模型厂商全景

| 文件 | 覆盖 | 状态 | 关键亮点 |
|---|---|---|---|
| `models/anthropic.md` | Claude 全矩阵 + 定价 + Skills + SDK | **[完整]** | Opus 4.7 GA (2026-04-18) + 定价表抓完整 |
| `models/openai.md` | GPT-5.4 / o 系列 / Codex / Sandbox Agents | [部分] | Pricing 需浏览器；其余完整 |
| `models/google.md` | Gemini 3.1 + 2.5 + Gemma 4 + 定价 + changelog | **[完整]** | 当前旗舰 3.1 Pro；changelog 完整到 4-15 |
| `models/xai.md` | Grok 4.20 (2M ctx) + 4.1 / 4 / 3 | [部分] | 定价 JS 渲染未抓 |
| `models/deepseek.md` | V3.2 + R1 + OCR + 定价 | **[完整]** | cache hit $0.028/M |
| `models/qwen.md` | Qwen3.6 / 3.5 全梯度 + 百炼 | **[完整]** | 3.6-35B-A3B (2026-04-15) |
| `models/kimi.md` | K2.5 (1T MoE) + VL + Audio + Linear | **[完整]** | 首个原生多模态 Agentic 开源 |
| `models/minimax.md` | M2.7 + Hailuo + Speech + Music | [部分] | 多模态最全，API 价待验证 |
| `models/glm.md` | 智谱 GLM 系列 | [部分] | 待深挖最新 |
| `models/hunyuan.md` | 腾讯混元系列 | [部分] | HY-World 2.0 |
| `models/misc-chinese.md` | 豆包 / 百度 / 讯飞 / 其他 | [部分] | — |
| `models/mistral-meta-others.md` | Mistral / Meta Llama / AI2 / Cohere / NVIDIA | **[完整]** | Mistral Large 3 + Leanstral + NVIDIA 优化矩阵 |

---

## 📂 frameworks/ — 框架与 SDK

| 文件 | 覆盖 | 状态 | 最新版本 |
|---|---|---|---|
| `frameworks/langchain-langgraph.md` | LangChain + LangGraph + LangSmith | **[完整]** | core 1.3.0 / langgraph 1.1.8 |
| `frameworks/langchain.md` | LangChain 专项 | [部分] | 历史版（保留） |
| `frameworks/langgraph.md` | LangGraph 专项 | [部分] | 历史版（保留） |
| `frameworks/llamaindex.md` | LlamaIndex + LlamaParse + LlamaHub | [部分] | v0.14.20 |
| `frameworks/agent-sdks-comparison.md` | Claude / OpenAI / LangGraph / CrewAI / AutoGen / DSPy | **[完整]** | 6 SDK 横评 |
| `frameworks/mcp.md` | MCP 协议 + servers + 框架生态 | **[完整]** | 2026.1.26 registry |
| `frameworks/code-agents.md` | Claude Code / Codex / Cline / Aider / Cursor | **[完整]** | 日发版对比 |
| `frameworks/hermes.md` / `openclaw.md` / `_other-oss.md` | 其他 OSS agent | [部分] | 保留 |

---

## 📂 tools/ — 推理与部署

| 文件 | 覆盖 | 状态 |
|---|---|---|
| `tools/inference-and-deployment.md` | vLLM / SGLang / Ollama / llama.cpp + Groq / Together / Fireworks / Cerebras | **[完整]** |

---

## 📂 paradigms/ — 工程范式

| 文件 | 覆盖 | 状态 | 关键观点 |
|---|---|---|---|
| `paradigms/skill-engineering.md` | Claude Skills / Codex Catalog / Gemini built-in tools | **[完整]** | 三家共识 |
| `paradigms/agent-sdk-skills.md` | Skills + Sandbox + MCP 三段式 | **[完整]** | 2026 Q2 架构趋势 |
| `paradigms/agent-design-patterns.md` | Agent 设计模式集合 | [部分] | 保留 |
| `paradigms/context-engineering.md` | 1M context / Caching / Compaction / Navigate vs RAG | **[完整]** | Embedding / VDB 现状 |
| `paradigms/harness-engineering.md` | Harness 定义 / 模式 / 反模式 / v23 映射 | **[完整]** | 与本团队铁律对齐 |

---

## 📂 industry-watch/ — 行业全景

| 文件 | 覆盖 | 状态 |
|---|---|---|
| `industry-watch/2026-Q1-Q2-overview.md` | 2026 Q1-Q2 全季度时间线 + 定价 + 拐点 | **[完整]** |
| `industry-watch/2026-Q2.md` | 4-17/18 增量事件 | [部分] |

---

## 📂 research-log/ — 研究记录

| 文件 | 说明 |
|---|---|
| `research-log/2026-04-18-full-scan.md` | 本轮全景扫描记录 |

---

## 🎯 关键事实速查（新人最先读这里）

### 2026-04-18 当前旗舰对照

| 厂商 | 旗舰模型 | 输入 | 输出 | 上下文 |
|---|---|---|---|---|
| Anthropic | Claude Opus 4.7 | $5/M | $25/M | 200K (1M 在 Sonnet 4.6 beta) |
| Anthropic | Claude Sonnet 4.6 | $3/M | $15/M | **1M beta** |
| Anthropic | Claude Haiku 4.5 | $1/M | $5/M | 200K |
| OpenAI | GPT-5.4 (mini/nano) | [待验证] | [待验证] | 400K 报告 |
| Google | Gemini 3.1 Pro | $2/M (<200K) | $12/M | 未知上限 |
| Google | Gemini 2.5 Flash-Lite | $0.10/M | $0.40/M | 1M |
| xAI | Grok 4.20 | [待验证] | [待验证] | **2M** |
| DeepSeek | V3.2 (chat/reasoner) | $0.28/$0.028 | $0.42/M | 128K |
| Kimi | K2.5 | [待验证] | [待验证] | 128K |

### 2026-04-18 最新 SDK 版本

- anthropic-sdk-python **v0.96.0**
- claude-agent-sdk-python **v0.1.63**
- Claude Code **v2.1.114**
- openai-python **v2.32.0**
- openai-agents-python **v0.14.2** (含 SandboxAgent)
- Codex rust **v0.122.0-alpha.10**
- langchain-core **v1.3.0**
- langgraph **v1.1.8**
- llama_index **v0.14.20**
- vLLM **v0.19.1**
- SGLang **v0.5.10.post1**
- Ollama **v0.21.0**
- llama.cpp **b8838**

---

## 📖 常见问题路由

| 问题类型 | 去哪个文件 |
|---|---|
| "哪个模型最便宜 / 最强 / 最长 context" | `industry-watch/2026-Q1-Q2-overview.md` + `models/*.md` |
| "LangChain vs LlamaIndex vs 别的" | `frameworks/agent-sdks-comparison.md` |
| "RAG 现在该怎么做" | `paradigms/context-engineering.md` |
| "MCP 是什么 / 用哪个 server" | `frameworks/mcp.md` |
| "代码 agent 选哪个" | `frameworks/code-agents.md` |
| "本地部署怎么做" | `tools/inference-and-deployment.md` |
| "Skills 范式是什么" | `paradigms/skill-engineering.md` + `paradigms/agent-sdk-skills.md` |
| "Harness 怎么设计" | `paradigms/harness-engineering.md` |

---

## 🔄 更新节奏建议

- **每周**：检查 Claude Code / Codex / Claude Agent SDK 版本（日发版极频繁）
- **双周**：Anthropic / OpenAI / Google 官方 news
- **月度**：HuggingFace 榜、官方模型矩阵
- **季度**：完整全景扫描（本轮形式）
- **即时**：重大发布（旗舰模型 / 定价变化）立即刷新

---

## 📦 迁移记录

- **2026-04-18**：本轮扫描产出最初误写入 `~/.claude/projects/-Users-mumuxsy-Desktop/knowledge-base/ai-navigator/`（会话存储目录），已整体迁移至当前全局正确路径；原错路径已清理；迁移前快照保留在 `~/.claude/knowledge-base/ai-navigator.backup-2026-04-18/`。
