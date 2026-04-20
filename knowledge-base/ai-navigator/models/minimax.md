# MiniMax — 全景知识

> last_updated: 2026-04-18
> 状态：[权威] HF + 官网 nav 抓取

---

## 1. 模型矩阵

来源：[权威] `https://huggingface.co/MiniMaxAI`、`https://www.minimaxi.com/`

### 文本模型

| 模型 | 发布 | 下载量 | 状态 |
|---|---|---|---|
| **MiniMaxAI/MiniMax-M2.7** | **2026-04-09** | **258K** | [权威] **当前旗舰** |
| MiniMax-M2.5 | 2026-02-12 | 921K | 前代，HF 下载量最高 |
| MiniMax-M2-Her | — | — | 变体 |
| MiniMax-M2.1 | 2025-12-20 | 37K | |
| MiniMax-M2 | 2025-10-22 | 64K | |
| MiniMax-M1-40k / -80k | 2025-06-13 / 07-01 | 24K / 0.7K | M1 系 |
| MiniMax-Text-01-hf | 2025-06-03 | 19.6K | |

### VTP 系列（视觉）

- VTP-Small / Base / Large -f16d64（2025-12-16，共 ~560 下载）— 视觉预训练

### SynLogic（逻辑推理）

- SynLogic-7B / 32B / Mix-3-32B（2025-05-30 / 06-03）

### 语音 / 视频 / 音乐（官网 nav）

| 类型 | 最新 |
|---|---|
| 语音 | **MiniMax Speech 2.8** (NEW) / 2.6 / 2.5 |
| 视频 | **MiniMax Hailuo 2.3** / 2.3 Fast (NEW) / Hailuo 02 |
| 音乐 | **MiniMax Music 2.6** (NEW) / 2.5+ (NEW) / 2.5 / 2.0 / 1.5 |

---

## 2. 产品矩阵

- **MiniMax Agent**（NEW 2026）— AI 原生应用，agentic
- **海螺视频**（Hailuo）— 消费视频生成
- **MiniMax 语音**
- **星野**（AI 社交/角色）
- **开放平台**：`https://www.minimaxi.com/` → 文档中心 / Token Plan / 产品定价

## 3. API 要点（[待验证] 具体价格）

- 文档中心：`https://www.minimaxi.com/document/guides/chat-model/pro/api`
- 模型 endpoint：MiniMax-M2.7 API 已上架
- 支持 OpenAI / Anthropic 兼容 [待验证]

## 4. 差异化定位

- **多模态最全**（文本/语音/视频/音乐）— 在国内厂商中覆盖最广
- **国际化**：官网有 EN 版，面向全球
- **星野/海螺**：消费级产品带动 API 调用量
- 文本与视频双线发展

## 5. 官方资源

- 官网：`https://www.minimaxi.com/`
- 新闻：`https://www.minimaxi.com/news`
- HF：`https://huggingface.co/MiniMaxAI`
- API 文档：`https://www.minimaxi.com/document/`

## 6. 下轮研究

- [ ] MiniMax-M2.7 技术报告 / benchmark（官方 blog 需二次访问）
- [ ] Hailuo 2.3 与 Veo 3.1 / Kling 2 视频对比
- [ ] Music 2.6 与 Suno v5 / Udio 对比
- [ ] Speech 2.8 TTS vs ElevenLabs / OpenAI realtime
- [ ] API 具体 per-1M-token 定价
