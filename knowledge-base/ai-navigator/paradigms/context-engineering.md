# Context Engineering — 2026 最新实践

> last_updated: 2026-04-18

---

## 1. 概念演进

**Context Engineering**（Andrej Karpathy 2024-Q4 推广的术语，2026 行业主流）：
> 不是 prompt engineering（写提示词），而是"填充 LLM 窗口的工程学"——如何选、切、排、压、换上下文。

子问题：
1. **Retrieval**：怎么选（RAG / Navigate / Skills / Tools）
2. **Chunking**：怎么切
3. **Compression**：怎么压（summary / prune / compaction）
4. **Caching**：怎么换（prompt caching / context caching）
5. **Ordering**：怎么排（lost-in-the-middle 对抗）

---

## 2. 2026 Q2 关键进展

### A. 1M context 成为 **Tier 1 模型门票**

| 厂商 | 1M+ context 模型 | 注 |
|---|---|---|
| Anthropic | Claude Sonnet 4.6（beta） | [权威] 公告 |
| xAI | Grok 4.20 | **2,000,000** (2M) [权威] |
| Google | Gemini 2.5 Flash / 3.x 系 | 1M+ |
| OpenAI | GPT-5.x 系列 | [待验证] 400K 输入报告 |
| Kimi | K2.5 128K （产品侧 200万字） | |

**观察**：1M 是底线，Grok 把 2M 推为差异化；"整个代码库 / 数十篇论文 / 多小时会议转写一次传入"已成可能。

### B. Prompt Caching 成熟

| 厂商 | 模式 | 节省 |
|---|---|---|
| Anthropic | 5m / 1h 两种写入；读命中 = 输入价的 10% | Haiku 4.5 读命中 $0.10/M |
| DeepSeek | cache hit $0.028/M vs miss $0.28/M | **10× 折扣** |
| Gemini | Context Caching + storage $1/M/hr | 按小时计费 |
| OpenAI | 透明 caching（自动） | [待验证] 比率 |

**新兴做法**：在 Claude Agent SDK 中给系统 prompt 打 cache block → 多轮对话显著降本。

### C. Context Compaction（压缩）

- Sonnet 4.6 **context compaction (beta)**：旧上下文自动摘要，延长有效 context
- Claude Code 内置 `/compact` 命令，SDK 也暴露
- 工程意义：避免 1M 一次性消耗；把不常用 context 用摘要换出

### D. Adaptive Thinking（推理预算自适应）

- Claude Sonnet 4.6 支持 **adaptive thinking + extended thinking** 并存
- Gemini 2.5 Flash **thinking budgets**
- Grok 4.20 **reasoning/non-reasoning 分路由**（`-reasoning` / `-non-reasoning` 后缀）
- GPT-5 系列 effort 参数

**工程含义**：context engineering 包含"给 agent 多少思考 token 预算"这一维度，不能只控输出。

### E. Tokenizer 变化

- Claude Opus 4.7 **新分词器**：同文本 token 数 1.0-1.35× 于前代
- **含义**：上游 context 成本可能涨 20-30%，但 effort 自控下净改善

---

## 3. RAG vs Navigate 之争（2026-Q2 论文）

### 传统 RAG

1. Embed 文档 / 查询
2. 向量检索 top-k
3. Re-rank
4. 拼接到 context
5. 生成

痛点：
- Chunk 切分丢失结构
- Re-ranking 难
- 混入噪声
- 长文档效果差

### Navigate / Structured Retrieval

[HF papers 2026-04] "Don't Retrieve, Navigate: Distilling Enterprise Knowledge into Navigable Agent Skills"

- 把知识**蒸馏为可导航的 skill**（有 hierarchy / index）
- agent 像用户浏览 docs 一样**逐步下钻**
- 更准，且可解释
- 与 Anthropic Skills 思想自然接轨

### GraphRAG / Property Graph

- LlamaIndex `PropertyGraphIndex`、Microsoft GraphRAG 2024-2025 成熟
- 2026 趋势：**混合**向量 + 图 + skill 导航

---

## 4. Embedding 新进展

| 模型 | 发布 | 要点 |
|---|---|---|
| **Gemini embedding-2-preview** | 2026-03-10 | 首个官方**多模态 embedding**（text/image/video/audio/PDF 统一） |
| `BAAI/bge-m3` | 持续 | 中英双语 SOTA |
| `Codestral Embed` (Mistral) | 25.05 | 代码 embedding |
| OpenAI text-embedding-3-large | 维护 | |

HF 下载 top：
- `sentence-transformers/all-MiniLM-L6-v2`（2 亿下载）仍是工业界默认
- `BAAI/bge-m3`（16M）中英场景首选
- `BAAI/bge-small-en-v1.5` 轻量英文
- `openai/clip-vit-*` 视觉

---

## 5. 向量数据库现状（2026）

| DB | 定位 |
|---|---|
| **pgvector (+ pgvectorscale)** | 事实标准，生产首选 |
| **Qdrant** | Rust，performance/filter 强 |
| **Milvus / Zilliz** | 企业级大规模 |
| **Weaviate** | hybrid search 强 |
| **Pinecone** | SaaS，开发最快 |
| **Chroma** | Python 原型首选 |
| **LanceDB** | 列式，embedded |

趋势：**pgvector 一家独大**，新项目不额外引入独立 VDB 成为主流建议。

---

## 6. 工程清单（Context Engineering 实操）

1. 系统 prompt → **始终开 prompt cache**
2. 工具 schema / skill 列表 → **单独 cache block**
3. 对话历史 → **periodic compaction**（接近窗口时触发）
4. 文档入窗 → **Navigate / Skills > 直接 RAG**
5. 视觉输入 → **先 downsample**（Opus 4.7 默认高分辨，注意 token 涨）
6. 推理任务 → 先 low effort 预判，再升 high effort（成本曲线）
7. Multi-turn agent → **Subagent + transcript 外存**，避免主窗口爆炸

---

## 7. 下轮研究

- [ ] "Navigate" 论文具体方法
- [ ] Gemini embedding-2 vs BGE-M3 实测
- [ ] Claude Sonnet 4.6 compaction 在 Agent SDK 中的触发条件
- [ ] 1h cache 在长 agent session 中的经济性
- [ ] pgvector 大规模（1B+ 向量）实战
