# xAI / Grok — 全景知识

> last_updated: 2026-04-18
> 状态：[权威] 模型页抓取完整；定价数字需 JS 渲染，[待验证]

---

## 1. Grok 模型矩阵

来源：[权威] `https://docs.x.ai/docs/models`

### Grok 4.20（当前旗舰，2026-03 系）

- `grok-4.20` / `grok-4.20-0309` / `grok-4.20-non-reasoning` / `grok-4.20-reasoning`
- Beta 线：`grok-4.20-beta`、`grok-4.20-beta-0309` 及 reasoning/non-reasoning 变体
- 实验线：`grok-4.20-experimental-beta-0304`
- **公告语**：「行业领先速度 + agentic tool calling；市场最低幻觉率 + 严格 prompt adherence」
- **Context window：2,000,000**（2M token）[权威]
- 能力：function calling / structured outputs / reasoning / lightning fast

### Grok 4.1（Fast 线）

- `grok-4-1-fast` / `-fast-reasoning` / `-fast-non-reasoning`
- `grok-4-1-fast-reasoning-latest` / `-non-reasoning-latest`

### Grok 4

- `grok-4`（原生 reasoning 模型，无 non-reasoning 模式）
- `grok-4-0709`（2025-07-09 日期版本）
- `grok-4-fast` / `grok-4-fast-reasoning` / `-non-reasoning`
- `grok-4-latest`
- **注意事项**（[权威]）：
  - Grok 4 是纯 reasoning 模型，没有 non-reasoning 模式
  - **不支持** `presencePenalty` / `frequencyPenalty` / `stop` 参数
  - **不支持** `reasoning_effort` 参数（传入会报错）
  - 从 `grok-3-mini` 迁移到 `grok-4` 需注意这些差异

### Grok 3（维护中）

- `grok-3` / `grok-3-beta` / `grok-3-fast` / `grok-3-fast-beta`
- `grok-3-mini` / `grok-3-mini-fast` / `grok-3-mini-beta` 等变体
- 均带 `-latest` 别名

---

## 2. Grok 语音与音频（[权威] `docs.x.ai`）

- **Voice Agent API**：$0.05/min ($3/hr)，100 CST
- **Text to Speech**：$4.20 / 1M characters；3,000 rpm / 50 rps
- **Speech to Text**：$0.10/hr ... $0.20（某行）；600 rpm / 10 rps

---

## 3. 定价（[待验证]）

- 定价页面 `https://docs.x.ai/docs/models/models-and-pricing` 表格为 JS 渲染，curl 未拿到
- [待验证] Grok 4.20 / 4-1-fast / 4-fast 的具体 $/MTok
- 建议下轮通过浏览器抓图或 mcp 爬虫

---

## 4. API 特性

- REST + gRPC 均支持
- Regional endpoints（数据驻留）
- MCP 支持（docs 中有 MCP 章节）
- 支持 function calling / structured outputs / files & collections
- Images / Video / Audio 均有 endpoint

---

## 5. 官方资源

- 文档：`https://docs.x.ai/docs/models`
- 定价：`https://docs.x.ai/docs/models/models-and-pricing`
- API：`https://api.x.ai/v1`

## 6. 下轮研究

- [ ] 逐模型 $/MTok 表格（需浏览器）
- [ ] Grok 4.20 的编码 benchmark（SWE-bench / LiveCodeBench）
- [ ] 与 Claude / GPT / Gemini 3.1 Pro 的幻觉率横评
- [ ] "lightning fast" 实测 tokens/sec
