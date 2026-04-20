# Google / Gemini — 全景知识

> last_updated: 2026-04-18
> 状态：[权威] Pricing + Changelog 均抓到完整数据

---

## 1. Gemini 模型矩阵（2026-04）

来源：[权威] `https://ai.google.dev/gemini-api/docs/models/gemini`、`https://ai.google.dev/gemini-api/docs/pricing`

### Gemini 3.x（当前旗舰）

| 模型 ID | 状态 | 发布/事件 |
|---|---|---|
| `gemini-3.1-pro-preview` | [权威] 当前旗舰 | 2026-02-19 发布；3 Pro Preview 于 2026-03-09 shut down，路由指向 3.1 Pro |
| `gemini-3.1-pro-preview-customtools` | [权威] | 为 bash+工具混合场景优化 |
| `gemini-3-flash-preview` | [权威] | 最快版，集成 search + grounding |
| `gemini-3.1-flash-live-preview` | [权威] | 2026-03-26 发布，A2A 实时语音 |
| `gemini-3.1-flash-image-preview` (Nano Banana 2) | [权威] | 2026-02-26 发布 |
| `gemini-3.1-flash-lite-preview` | [权威] | 2026-03-03 发布，Flash-Lite 首个 3 系 |
| `gemini-3.1-flash-tts-preview` | [权威] | 2026-04-15 发布，cost-efficient TTS |
| `gemini-3-pro-image-preview` 🍌 | [权威] | 原生图像生成（与 3.1 Pro 等同文本定价） |

### Gemini 2.5（稳定）

| 模型 ID | 备注 |
|---|---|
| `gemini-2.5-pro` | SOTA 多用途 |
| `gemini-2.5-flash` | 1M context，hybrid reasoning，thinking budgets |
| `gemini-2.5-flash-lite` | 最低价 |
| `gemini-2.5-computer-use-preview-10-2025` | 计算机使用专项 |
| `gemini-2.5-flash-native-audio-preview-12-2025` | 原生音频 |
| `gemini-2.5-flash-live-preview-2` | 实时对话 |

### 特化

- `gemini-robotics-er-1.6-preview`（2026-04-14）— 机器人模型，仪表读取 / 空间推理增强
- `lyria-3-clip-preview` / `lyria-3-pro-preview`（2026-03-25）— Lyria 3 音乐生成，48kHz 立体声
- `veo-3.1-lite-generate-preview`（2026-03-31）— Veo 3.1 视频生成（快速 / 高量版）
- `gemini-embedding-2-preview`（2026-03-10）— 首个**多模态 embedding**（text/image/video/audio/PDF 统一空间）

---

## 2. Gemini 定价（[权威] 2026-04-18 官网表格）

| 模型 | 输入 (<=200K) | 输入 (>200K) | 输出 | Cache | 备注 |
|---|---|---|---|---|---|
| **Gemini 3.1 Pro** | $2.00 / MTok | $4.00 / MTok | $12.00 / $18.00 | — | text+image prompts; 超 200K 加价 |
| **Gemini 3 Flash** | $0.50 (text/img/video) / $1.00 (audio) | — | $3.00 | $0.05/$0.10 + storage $1/hr/M tokens | 免费层有 |
| **Gemini 3 Pro Image** 🍌 | $2.00 (text/image ≈ $0.0011/img) | — | $12.00 (text) | — | 同 3.1 Pro 文本价 |
| **Gemini 2.5 Pro** | $1.25 / $2.50 | — | $10.00 / $15.00 | $0.125/$0.25 + $4.50/hr/M | 免费层有 |
| **Gemini 2.5 Flash** | $0.30 (text) / $1.00 (audio) | — | $2.50 | $0.03/$0.10 + $1/hr/M | — |
| **Gemini 2.5 Flash-Lite** | $0.10 / $0.30 (audio) | — | $0.40 | $0.01/$0.03 + $1/hr/M | 最低价 |

---

## 3. 2026 Q1-Q2 Changelog（[权威] AI Studio changelog）

| 日期 | 事件 |
|---|---|
| 2026-04-15 | Gemini 3.1 Flash TTS Preview 发布 |
| 2026-04-14 | `gemini-robotics-er-1.6-preview`；1.5 将在 4-30 shut down |
| 2026-04-02 | Gemma-4-26B-A4B-IT / 31B-IT 发布（Gemma 4 launch） |
| 2026-04-01 | 推出 **Flex / Priority 推理层**（成本/延迟分级） |
| 2026-03-31 | Veo 3.1 Lite Preview；2.5-flash-lite-preview-09-2025 shut down |
| 2026-03-26 | `gemini-3.1-flash-live-preview`（A2A 实时） |
| 2026-03-25 | Lyria 3（clip + pro） |
| 2026-03-23 | AI Studio 推出 Prepay/Postpay billing |
| 2026-03-18 | **Built-in Tools + Function Calling 可同 call** — 大改造；Grounding with Google Maps 对 3 系开放 |
| 2026-03-16 | 新 Usage Tiers / Billing 花费上限 |
| 2026-03-12 | 项目级 spend cap |
| 2026-03-10 | `gemini-embedding-2-preview` — 首个多模态 embedding |
| 2026-03-09 | 3 Pro Preview shut down，路由至 3.1 Pro |
| 2026-03-03 | Gemini 3.1 Flash-Lite Preview |
| 2026-02-26 | Nano Banana 2（3.1 Flash Image Preview） |
| 2026-02-19 | **Gemini 3.1 Pro Preview 发布** |

---

## 4. Gemma 开源（[权威] HF）

Gemma 4 系（2026-03 launch）：

| 模型 | 发布 | 下载量 |
|---|---|---|
| `google/gemma-4-31B-it` | 2026-03-11 | 3.78M |
| `google/gemma-4-26B-A4B-it` | 2026-03-11 | 2.78M |
| `google/gemma-4-31B` | 2026-03-12 | 294K |
| `google/gemma-4-26B-A4B` | 2026-03-12 | 101K |
| `google/gemma-4-E2B` / `E2B-it` | 2026-03-02 | 125K / 1.61M |
| `google/gemma-4-E4B` | 2026-03-02 | 142K |

2026-04-09：Google 发布 `tipsv2-*` 系列（b14/l14/g14/so400m14 及 -dpt 变体），视觉 encoder。

vLLM v0.19.0（2026-04-03）提供 Gemma 4 全量支持（MoE / multimodal / reasoning / tool-use），需 transformers>=5.5.0。

---

## 5. 官方资源

- 主页：`https://ai.google.dev/gemini-api`
- 模型：`https://ai.google.dev/gemini-api/docs/models/gemini`
- 定价：`https://ai.google.dev/gemini-api/docs/pricing`
- Changelog：`https://ai.google.dev/gemini-api/docs/changelog`
- AI Studio：`https://aistudio.google.com/`

## 6. 下轮研究

- [ ] Gemini 3.1 Pro 是否 GA 或仍 preview 状态
- [ ] Built-in Tools + Function Calling 组合在 Agent 侧的实测效果
- [ ] 与 Claude MCP 的互操作性
- [ ] Lyria 3 与 Suno / Udio 对比
