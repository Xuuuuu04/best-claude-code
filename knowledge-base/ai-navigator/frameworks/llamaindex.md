# LlamaIndex — 框架知识

> last_updated: 2026-04-18

---

## 1. 版本状态

| 包 | 最新版 | 日期 |
|---|---|---|
| **llama-index (core)** | **v0.14.20** | 2026-04-03 |
| v0.14.19 | — | 2026-03-25 |
| v0.14.18 | — | 2026-03-16 |

节奏：约每周 / 双周迭代 minor。

## 2. 核心能力

### 索引 / Index

- `VectorStoreIndex` — 经典向量检索
- `SummaryIndex` — 摘要型
- `PropertyGraphIndex` — 属性图索引（GraphRAG 方向）
- `KnowledgeGraphIndex` — 知识图谱
- `KeywordTableIndex` / `TreeIndex` — 传统

### RAG Pipeline

- `QueryEngine` / `RetrieverQueryEngine`
- **Advanced RAG**：
  - HyDE（Hypothetical Document Embeddings）
  - Sentence Window Retrieval
  - Auto-merging Retrieval
  - Recursive Retrieval
  - Re-ranking（Cohere / BGE / ColBERT）

### Workflow（重点）

- `@step` 装饰器 + 事件驱动
- `Context` 对象在 step 间传递
- 并发步骤
- 与 LangGraph StateGraph 功能相近，但更 Pythonic

### Agent

- ReAct Agent / Function Calling Agent
- `AgentWorkflow` — 新一代 agent 抽象
- Tools / ToolSpec

## 3. 生态

- **LlamaHub**：`https://llamahub.ai/` — 社区 ~300+ data loader / tool / pack
- **LlamaParse**：商业级 PDF/复杂文档解析（SaaS）
- **LlamaCloud**：托管版

## 4. 对比 LangChain

| 维度 | LlamaIndex | LangChain |
|---|---|---|
| 起源 | RAG / Data 导向 | Chain 导向 |
| 抽象 | Index + Workflow | LCEL + Graph |
| 文档解析 | 强（LlamaParse） | 弱（需组合）|
| Agent | 有（AgentWorkflow）| 主打（LangGraph）|
| 社区规模 | 中 | 大 |
| 选型建议 | 重 RAG、文档密集场景 | 重 agent 编排、多 provider |

## 5. 官方资源

- GitHub：`https://github.com/run-llama/llama_index`
- Docs：`https://docs.llamaindex.ai/`
- LlamaHub：`https://llamahub.ai/`
- LlamaCloud：`https://cloud.llamaindex.ai/`

## 6. 下轮研究

- [ ] v0.14.20 具体 changelog
- [ ] PropertyGraphIndex 与 Neo4j / GraphRAG (Microsoft) 对比
- [ ] LlamaParse Plus 最新能力
- [ ] AgentWorkflow 稳定性评估
