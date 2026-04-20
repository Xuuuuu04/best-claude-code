# 月之暗面 Kimi（Moonshot）— 全景知识

> last_updated: 2026-04-18
> 状态：[权威] HF 作者 listing + K2.5 card 抓取

---

## 1. Kimi 模型矩阵

来源：[权威] `https://huggingface.co/moonshotai`

### Kimi K2.5（2026-01-01，当前旗舰）

HF：`moonshotai/Kimi-K2.5`（下载 **5.27M**，是 Moonshot 所有公开模型中最高）

关键特性（[权威] model card）：
- **原生多模态 Agentic 模型**：在 Kimi-K2-Base 上继续预训练约 **15 万亿 mixed vision-text tokens**
- **MoE 架构**：**1T 总参 / 32B 激活**；61 层（1 个 dense）；attention hidden 7168
- **Native INT4 Quantization**：原生 INT4 支持
- **Key Features**：
  - Native Multimodality：视觉-语言原生预训练
  - Coding with Vision：可从 UI 设计 / 视频 workflow 直接生成代码
  - **Agent Swarm**：从单 agent scaling 转向**自主协调的群体执行**；任务分解为并行 sub-task，由动态实例化的 domain-specific agent 执行
  - Interleaved Thinking + Multi-Step Tool Call
  - Instant & Thinking 双模
- 2026-01-29 修复：默认 system prompt 移除；`<|media_start|>` 改为 `<|media_begin|>`

### Kimi K2 系列

| 模型 | 发布 | 下载 | 要点 |
|---|---|---|---|
| `Kimi-K2-Thinking` | 2025-11-04 | 87K | K2 thinking 版 |
| `Kimi-Linear-48B-A3B-Base` / `-Instruct` | 2025-10-30 | 0.8K / 62K | **Linear attention** 版 |
| `Kimi-K2-Instruct-0905` | 2025-09-03 | 368K | K2 9-05 迭代 |
| `Kimi-K2-Instruct` | 2025-07-11 | 242K | K2 初始版 |
| `Kimi-K2-Base` | 2025-07-03 | 9K | |

### Kimi-VL 系列

- `Kimi-VL-A3B-Thinking-2506` (2025-06-21, 38K)
- `Kimi-VL-A3B-Thinking` (2025-04-09, 103K)
- `Kimi-VL-A3B-Instruct` (2025-04-09, 280K)
- `MoonViT-SO-400M` (2025-04-10, 6.7K) — vision backbone

### Kimi-Audio + Dev

- `Kimi-Audio-7B-Instruct` (2025-04-25, 41K)
- `Kimi-Dev-72B` (2025-06-16, 2.3K) — coding 专项
- `Moonlight-16B-A3B-Instruct` (2025-02-22, 74K) — Moonlight 系

---

## 2. NVIDIA 优化版

- `Kimi-K2.5-NVFP4`（2026-04-07，**922K 下载**）— NVIDIA 官方 NVFP4 优化版，MLPerf 推理优化

---

## 3. 平台 / API

- Kimi Chat：`https://kimi.com` / `https://kimi.moonshot.cn`
- 平台开发：`https://platform.moonshot.cn`
- **K2.5 多模态已在 API 平台发布**（中文 "🎉 Kimi K2.5 多模态模型现已发布！支持多模态理解与处理"）
- 定价 / Token Plan 可在平台查看（[待验证] 具体价格表需 JS 渲染）
- 上下文窗口：K2.5 支持 **128K token**（Moonshot 平台历史强项）

## 4. 能力亮点

- **超长上下文**：Moonshot 是国内最早将长上下文做成产品（2024 即 200W 字）
- **原生多模态 Agent Swarm**：K2.5 声称**将单 agent 扩展到自主 agent swarm**（中文社区热议）
- **开源 vLLM 修复**：vLLM v0.19.1 (2026-04-18) 专门修复了 `kimi_k25` 的 media placeholder token id 问题（`#39344`）

## 5. 下轮研究

- [ ] Kimi K2.5 官方 API 具体 per-1M-token 定价
- [ ] K2.5 vs DeepSeek-V3.2 在 Agent 基准（AgentBench / BrowseComp）对比
- [ ] Kimi-Linear 架构细节（线性注意力）
- [ ] Kimi Chat 免费用户的 K2.5 使用限额
