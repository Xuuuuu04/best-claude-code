# 推理与部署 — vLLM / SGLang / Ollama / llama.cpp / 推理服务商

> last_updated: 2026-04-18

---

## 1. 开源推理引擎（2026-04-18）

| 引擎 | 最新版 | 日期 | 定位 |
|---|---|---|---|
| **vLLM** | v0.19.1 | 2026-04-18 | 生产级 GPU 推理 |
| **SGLang** | v0.5.10.post1 | 2026-04-09 | 结构化 + 长程推理 |
| **llama.cpp** | b8838 | 2026-04-18 | CPU / Apple Silicon / 量化 |
| **Ollama** | v0.21.0 | 2026-04-16 | 本地最易用 |

### vLLM v0.19.x 亮点（[权威] release notes）

**v0.19.0（2026-04-03）— 448 commits / 197 contributors / 54 new**

- **Gemma 4 全量支持**：MoE / multimodal / reasoning / tool-use（需 transformers>=5.5.0）；官方 `vllm/vllm-openai:gemma4` docker
- **Zero-bubble async scheduling + speculative decoding**：吞吐量显著提升（#32951）
- **Model Runner V2 成熟**：piecewise CUDA graphs for pipeline parallel / spec decode rejection sampler / multi-modal embeddings for spec decode / streaming inputs / EPLB 支持
- **ViT Full CUDA Graphs**：视觉 encoder 全量 CUDA graph capture
- **General CPU KV cache offloading**：通用 V1 版本
- **DBO (Dual-Batch Overlap)** 泛化到任意模型
- **NVIDIA B300/GB300 (SM 10.3) 支持**：Allreduce fusion 默认开启
- Transformers v5 兼容

**v0.19.1（2026-04-18）— 补丁**

- Gemma 4 streaming tool call 一系列 bug 修复
- **Kimi K2.5 media placeholder token id 修复**（#39344）
- Gemma 4 Eagle3 支持
- 升级 transformers v5.5.4

### SGLang v0.5.10（2026-04-06）

- RadixAttention 持续优化
- Speculative decoding
- `sgl.function` 程序化生成
- Omni 多阶段 Pipeline（industry-watch 提到 "SGLang Omni"）

### Ollama v0.21.0（2026-04-16）

- 模型库持续扩展
- 支持 agent / tool calling 原生 API
- 关键之争：**Ollama 仍是"本地 LLM 最简单起步"事实标准**
- macOS / Linux / Windows 三端

### llama.cpp b8838（2026-04-18）

- 每日 build 节奏
- GGUF 格式标配
- 量化：Q4_K_M / Q5_K_M / Q6_K / Q8_0 / IQ3_XXS / IQ4_NL 等
- Metal / CUDA / CPU / Vulkan / ROCm 后端

---

## 2. 新兴推理引擎（行业观察）

[权威] industry-watch 记录：

| 项目 | 定位 |
|---|---|
| **rvLLM** | Rust 版 vLLM 替代品 |
| **SGLang Omni** | Omni 模型多阶段 pipeline |
| **TurboQuant** | 3-bit keys / 2-bit values KV cache 量化 |
| **RotorQuant** | 块对角旋转 KV 压缩，优于 TurboQuant |
| **omlx** | Apple Silicon 推理服务器，连续批处理 + SSD 缓存 |
| **NVIDIA FastGen** | 扩散模型快速生成 |
| **NVIDIA NemoClaw** | OpenClaw 安全运行环境 |
| **TensorRT-LLM** | NVIDIA 官方极致优化（[待验证] 最新版本） |

---

## 3. 商业推理服务商

### Groq（极速硬件）

[权威] `https://console.groq.com/docs/models`

- 核心卖点：**~500 tps (GPT-OSS-120B)**、**~450 tps (Groq Compound)**
- 模型池：OpenAI GPT-OSS 120B / Llama 3.x / DeepSeek-R1 / Qwen / 国产开源
- **Groq Compound**：智能选择 built-in tools（web search / code execution / wolfram / browser）
- Service Tiers：Performance / Flex Processing / Batch
- Tool Use：Web Search / Visit Website / Browser Automation / Code Execution / Wolfram Alpha / **MCP Connectors**
- 编码集成：Factory Droid / OpenCode / Kilo Code / Roo Code / Cline

### Fireworks AI

- 多模型 serverless；支持 fine-tuning LoRA
- Mixture-of-Agents 官方范本
- [待验证] 最新定价

### Together AI

- Open-weight 推理主力供应商
- 支持 DeepSeek / Qwen / Llama / Mixtral 全矩阵
- Batch / Dedicated endpoints

### Cerebras

- 晶圆级芯片；对某些模型 tps 破 1800+
- 与 Perplexity、Meta 合作

### SambaNova / AWS Bedrock / Azure AI Foundry / Vertex AI

- 大厂托管推理
- Bedrock / Foundry / Vertex 均已上 Claude Opus 4.7、Sonnet 4.6、Haiku 4.5

---

## 4. 本地部署选型

| 场景 | 推荐 |
|---|---|
| Mac 本地研究 | Ollama + `llama-3.3-70b` / Qwen3.5-9B |
| Mac 极致性能 | **omlx** / **llama.cpp** + Metal |
| 单卡 GPU | **vLLM** + FP8 模型 |
| 多卡生产 | **vLLM** + tensor parallel + speculative decoding |
| 结构化输出密集 | **SGLang** |
| 开发调试 | **Ollama** + REST API |

## 5. 下轮研究

- [ ] TensorRT-LLM 最新版与 vLLM 性能对比
- [ ] **MLC LLM** / **mistral.rs** 动态
- [ ] omlx 官方 benchmark
- [ ] RotorQuant vs AWQ / GPTQ / EXL2 精度损失
- [ ] Groq / Cerebras 对新模型（Qwen3.6 / DeepSeek-V3.2）的覆盖时间
