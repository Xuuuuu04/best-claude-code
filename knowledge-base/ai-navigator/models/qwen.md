# 阿里 Qwen（通义千问）— 全景知识

> last_updated: 2026-04-18
> 状态：[权威] HF 官方 Author listing + Qwen3.6 card 抓取

---

## 1. Qwen3.6（当前最新，2026-04-15 首发）

来源：[权威] `https://huggingface.co/Qwen/Qwen3.6-35B-A3B`

### Qwen3.6-35B-A3B 要点

- **MoE 架构**：35B 总参 / 3B 激活 / 40 层
- Hidden Dim 2048；Embedding 248320（padded）
- **混合注意力/SSM 布局**：10× (3× (Gated DeltaNet → MoE) → 1× (Gated Attention → MoE))
  - Gated DeltaNet：V 头 32 / QK 头 16；head dim 128
  - Gated Attention：Q 头 16 / KV 头 2；head dim 256；RoPE 维度 64
- 训练：Pre-training + Post-training；Causal LM + Vision Encoder
- FP8 变体 `Qwen3.6-35B-A3B-FP8` 同步发布

### 关键新特性（与 Qwen3.5 对比）

1. **Agentic Coding 大升级**：前端工作流 / 仓库级推理更流畅
2. **Thinking Preservation**：新选项可保留历史消息的 reasoning 上下文，减少重复思考
3. 与 HF Transformers / vLLM / SGLang / KTransformers 兼容
4. 原生提供 Qwen-Agent + Qwen Code 集成路径
5. 支持 Chat Completions API（OpenAI 兼容）

---

## 2. Qwen3.5 线（2026-02~03 广泛部署）

下载量排行：

| 模型 | 发布 | 下载量 |
|---|---|---|
| `Qwen/Qwen3.5-9B` | 2026-02-27 | 6.35M |
| `Qwen/Qwen3.5-4B` | 2026-02-27 | 3.01M |
| `Qwen/Qwen3.5-0.8B` | 2026-02-28 | 2.69M |
| `Qwen/Qwen3.5-35B-A3B-FP8` | 2026-02-25 | 1.82M |
| `Qwen/Qwen3.5-2B` | 2026-02-28 | 1.48M |
| `Qwen/Qwen3.5-35B-A3B-GPTQ-Int4` | 2026-03-03 | 646K |
| `Qwen/Qwen3.5-122B-A10B-GPTQ-Int4` | 2026-03-03 | 296K |
| `Qwen/Qwen3.5-27B-GPTQ-Int4` | 2026-03-03 | 265K |
| `Qwen/Qwen3.5-397B-A17B-GPTQ-Int4` | 2026-03-03 | 25K |

Qwen3.5 尺寸梯度：0.8B / 2B / 4B / 9B / 27B / 35B-A3B（MoE）/ 122B-A10B / 397B-A17B（MoE 超大）

---

## 3. 仍保持热度的旧版

- `Qwen/Qwen3-VL-2B-Instruct`（HF 全站下载量 Top 4，40M）— 视觉语言
- `Qwen/Qwen3-0.6B` — 15.6M
- `Qwen/Qwen2.5-7B-Instruct` — 12.5M
- NVIDIA 优化版：`Qwen3-VL-235B-A22B-NVFP4`（2026-04-07，MLPerf 推理优化）

---

## 4. 生态定位

- **开源策略**：持续 Apache-2.0 / Qwen LICENSE，权重 + 训练细节全公开
- **模型覆盖最全**：从 0.6B 端侧到 397B MoE 全梯度；文本/VL/代码/数学/OCR/Audio 多模态线
- **商业 API**：百炼平台（DashScope）提供 Qwen API 服务
- Qwen-Agent / Qwen-Code：官方 agent 框架

---

## 5. API 与云服务

- 百炼 / DashScope：`https://bailian.aliyun.com/` [权威]
- OpenAI 兼容 endpoint 可用
- 国内合规：已完成备案
- HuggingFace：`https://huggingface.co/Qwen`

## 6. 下轮研究

- [ ] Qwen3.6 的基准评测（vs DeepSeek-V3.2、Claude Opus 4.7）
- [ ] 百炼平台最新价格
- [ ] Qwen3.6 VL 版本是否发布（公告未见）
- [ ] Qwen Code CLI 与 Claude Code 对比
