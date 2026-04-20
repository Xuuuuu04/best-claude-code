# 海外开源/半开源厂商 — Mistral / Meta / Cohere / AI2

> last_updated: 2026-04-18

---

## 1. Mistral AI（[权威] `https://docs.mistral.ai/`）

### 当前模型矩阵

| 档位 | 模型 | 版本 | 开源 |
|---|---|---|---|
| 旗舰通用多模态 | **Mistral Large 3** | 2512（675B） | [权威] Open |
| Premier | **Mistral Medium 3.1** | 2025-08 | Premier |
| 开放通用 | **Mistral Small 4** | 26.03（119B） | [权威] Open，hybrid instruct/reason/code |
| 代码 agent | **Devstral 2** | 25.12（123B / Small 24B） | Open |
| 代码补全 | **Codestral** | 25.08 | Premier |
| 推理 | **Magistral Medium 1.2** / **Magistral Small 1.2** | 25.09 | Premier / Open |
| 端侧 | **Ministral 3 14B / 8B / 3B** | 25.12 | Open |
| 语音 | **Voxtral TTS / Voxtral Mini / Voxtral Mini Transcribe / -2** | 26.03 / 25.11 / 25.07 | Open / Premier |
| Realtime | `Voxtral-Mini-4B-Realtime-2602` | 2026-01-21 | Open, 904K 下载 |
| OCR | **OCR 3** | 25.12 | Premier |
| 嵌入 | **Codestral Embed** | 25.05 | Premier |
| 形式化证明 | **Leanstral Labs** | 26.03 | Open — Lean 4 形式化证明 agent |
| 内容安全 | **Mistral Moderation 2** | — | — |

### HF 最新发布

- `mistralai/Leanstral-2603` (2026-03-11) — **Lean 4 formal proof agent** — 重磅
- `mistralai/Mistral-Small-4-119B-2603` (2026-01-23) + NVFP4 / eagle 变体
- `mistralai/Voxtral-Mini-4B-Realtime-2602` — 实时语音（2026-01）
- `mistralai/Mistral-Large-3-675B-Instruct-2512` (2025-11-28)
- `mistralai/Devstral-2-123B-Instruct-2512` (2025-11-28)
- `mistralai/Devstral-Small-2-24B-Instruct-2512` (2025-11-28)

### Deprecation 日程（[权威] `docs.mistral.ai` retirement 列表）

| 模型 | 下线日期 | 替换 |
|---|---|---|
| `mistral-large-2411` | 2026-05-31 | Mistral Large 3 |
| `pixtral-large-2411` | 2026-05-31 | Mistral Large 3 |
| `mistral-moderation-2411` | 2026-06-30 | Mistral Moderation 2 |
| `ministral-3b-2410` | 已 2025-12-31 | Ministral 3 3B |

### 战略

- 持续 **Open vs Premier** 双轨
- **Leanstral** 专门投形式化证明 — 对标 DeepMind AlphaProof / Numia
- **Voxtral Realtime** 对标 OpenAI Realtime API

---

## 2. Meta Llama

最新 HF listing（[权威] `meta-llama/*`）

- **Llama 4**（2025-04-02~04 发布）：
  - `Llama-4-Scout-17B-16E` / `-Instruct`（17B/16 experts）
  - `Llama-4-Maverick-17B-128E` / `-Instruct` / `-FP8`（17B/128 experts）
- `Llama-Guard-4-12B`（2025-04-23）— 内容安全
- `Llama-Prompt-Guard-2-86M` / `-22M`（2025-04-28）— Prompt injection guard
- `Llama-3.3-70B-Instruct`（2024-11-26，仍 495K 下载）— 企业标配

**观察**：HF 最新发布仍是 2025-04 的 Llama 4；2026-Q1~Q2 无重大开源新模型（[待验证] 是否有内部 Llama 5 或已转闭源）

## 3. Allen AI / AI2

- OLMo-3 / Molmo 2（持续更新）[权威] 行业观察记录在 `industry-2026-q2.md`
- **Dolma** 数据集继续更新
- 面向**完全开放**的训练数据 + 权重

## 4. Cohere

- Command R+ / Command A 系列（RAG 专项）
- Aya 系列（多语）
- [待验证] 2026 Q1-Q2 新模型

## 5. IBM Granite / Snowflake Arctic / Salesforce

- 企业级开源模型继续维护；未在 HF 热榜前列

## 6. NVIDIA Nemotron / Audio Flamingo / EGM

- Nemotron-3（Nano 30B-A3B / Super 120B-A12B）
- Audio Flamingo Next 系列（2026-04-05，captioner/think/base）
- EGM-4B/8B（2026-04-02，基于 Qwen3-VL）
- Nemotron-OCR-v2（2026-04-01）
- Gemma-4-31B-IT-NVFP4（2026-04-02）— Gemma 4 NVFP4 优化版
- Kimi-K2.5-NVFP4（2026-04-07）
- Qwen3-VL-235B-A22B-NVFP4（2026-04-07）

**结论**：NVIDIA 在 2026-Q2 充当**推理优化枢纽**，将他家旗舰模型 NVFP4 化做 MLPerf 推理标准

## 7. 官方资源

- Mistral：`https://docs.mistral.ai/getting-started/models/models_overview/`
- Meta Llama：`https://ai.meta.com/llama/`
- AI2：`https://allenai.org/`
- Cohere：`https://docs.cohere.com/`
- NVIDIA：`https://huggingface.co/nvidia`
