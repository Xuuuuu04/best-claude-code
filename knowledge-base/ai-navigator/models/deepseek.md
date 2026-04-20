# DeepSeek — 全景知识

> last_updated: 2026-04-18
> 状态：[权威] 官方 pricing + changelog + HF card 全抓到

---

## 1. 模型矩阵

来源：[权威] `https://api-docs.deepseek.com/quick_start/pricing`、HF `deepseek-ai/*`

### 当前生产主线：DeepSeek-V3.2（2025-12-01）

API 路由：
- `deepseek-chat` → DeepSeek-V3.2 **non-thinking mode**
- `deepseek-reasoner` → DeepSeek-V3.2 **thinking mode**
- `base_url`: `https://api.deepseek.com`
- **Context length**: 128K
- Max output — non-thinking 默认 4K / 最大 8K；thinking 默认 32K / 最大 64K
- 特性：JSON Output / Tool Calls / Chat Prefix Completion (β) / FIM Completion (β; 仅 non-thinking)

### 关键模型家族演进

| 模型 | 发布 | 下载量 | 要点 |
|---|---|---|---|
| `deepseek-ai/DeepSeek-OCR-2` | 2026-01-27 | 1.34M | OCR 专项迭代 |
| **`deepseek-ai/DeepSeek-V3.2`** | 2025-12-01 | **10.19M** | 当前生产模型 |
| `DeepSeek-V3.2-Speciale` | 2025-11-28 | 19K | 高算力变体，技术报告声称"匹配 Gemini-3.0-Pro 推理水平，超过 GPT-5" |
| `DeepSeek-Math-V2` | 2025-11-27 | 2.8K | 数学 |
| `DeepSeek-OCR` | 2025-10-17 | 2.03M | OCR 初代 |
| `DeepSeek-V3.2-Exp` | 2025-09-29 | 189K | V3.2 实验版 |
| `DeepSeek-V3.1-Terminus` | 2025-09-22 | 4.2K | 中英混杂修复 / Code Agent & Search Agent 优化 |
| `DeepSeek-V3.1` | 2025-08-21 | 150K | 首次 hybrid reasoning（一模双模）/ SWE-bench Verified 66.0 / Terminal-bench 31.3 |
| `DeepSeek-R1-0528` | 2025-05-28 | 778K | R1 大升级：AIME 2025 70.0→87.5, GPQA 71.5→81.0 |
| `DeepSeek-V3-0324` | 2025-03-24 | 581K | V3 迭代 |

### V3.2 技术亮点（[权威] HF card）

1. **DeepSeek Sparse Attention (DSA)**：新注意力机制，长上下文场景大幅降 cost
2. **Scalable RL Framework**：RL 协议 + 后训练扩展，V3.2 综合水平"与 GPT-5 相当"；**V3.2-Speciale 高算力版超过 GPT-5，推理能力匹配 Gemini-3.0-Pro**
3. **Large-Scale Agentic Task Synthesis Pipeline**：系统性合成 Agentic 训练数据
4. **成就**：2025 IMO 金牌 / IOI 金牌 / ICPC World Finals / CMO 均有最终提交 release，可二次验证

---

## 2. 官方定价（[权威]，以 per 1M tokens 计，USD）

| 模型端点 | Input cache hit | Input cache miss | Output |
|---|---|---|---|
| `deepseek-chat` / `deepseek-reasoner` | **$0.028** | **$0.28** | **$0.42** |

**对比意义**：
- Input cache hit 价位在同代模型里极具竞争力（$0.028 vs Claude Opus 4.7 cache-read $0.50 ≈ **18× 便宜**）
- 同一 API 路由 chat+reasoner，切换仅切换 thinking mode
- DeepSeek 已成**开源生态最主要**的成本参考锚点

---

## 3. 2025-2026 Changelog 精华

| 日期 | 事件 |
|---|---|
| 2025-12-01 | DeepSeek-V3.2 正式替换 chat/reasoner |
| 2025-12-15 前 | `DeepSeek-V3.2-Speciale` 经临时 endpoint 提供（同 V3.2 定价，无 tool calls） |
| 2025-09-29 | V3.2-Exp 上线 |
| 2025-09-22 | V3.1-Terminus（中英混杂修复）|
| 2025-08-21 | V3.1 首次 hybrid reasoning |
| 2025-05-28 | R1-0528 大升级 |
| 2025-03-24 | V3-0324 |
| 2025-01-20 | R1 正式发布 |
| 2025-01-15 | DeepSeek APP 上架 |

---

## 4. API 特性

- **Anthropic API 兼容**层已开放（[权威] docs 有专章）— 可用 Anthropic SDK 直接切 base_url 使用 DeepSeek
- OpenAI 兼容层持续支持
- Tool Calls / JSON Output / Context Caching / FIM / Prefix Completion

---

## 5. 官方资源

- API docs：`https://api-docs.deepseek.com/`
- 定价：`https://api-docs.deepseek.com/quick_start/pricing`
- Changelog：`https://api-docs.deepseek.com/updates`
- HF：`https://huggingface.co/deepseek-ai`
- 官方网站：`https://www.deepseek.com`
- APP：独立 iOS / Android / Web

## 6. 下轮研究

- [ ] DeepSeek-V3.2-Speciale 的公开技术报告是否有 permanent endpoint
- [ ] Math-V2 的具体 AIME/MATH/Putnam 分数
- [ ] OCR-2 vs Qwen-OCR / Kimi-OCR 对比
- [ ] 与 Claude Haiku 4.5 / Gemini 2.5 Flash-Lite 在相同任务上的 $/task 对比
