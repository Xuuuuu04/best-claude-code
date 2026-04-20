# 其他热点开源 AI 框架

> 状态：[部分] 核心事实已模式 A 验证（2026-04-18）
> 创建日期：2026-04-18
> 最后更新：2026-04-18

---

## 结构化生成

### DSPy
- GitHub：[待验证] https://github.com/stanfordnlp/dspy
- 核心：`Signature`、`Module`、`Optimizer`（BootstrapFewShot / MIPROv2）
- 状态：[待验证] 本轮未抓到最新动态

### Instructor
- GitHub：[待验证] https://github.com/jxnl/instructor
- 核心：`response_model`、Pydantic 结构化输出、流式 `Partial`
- 状态：[待验证] 本轮未抓到最新动态

### Outlines / Guidance
- Outlines：[待验证] https://github.com/dottxt-ai/outlines
- Guidance：[待验证] https://github.com/guidance-ai/guidance
- 状态：[待验证] 本轮未抓到最新动态

---

## Multi-Agent 框架

### CrewAI
- GitHub：[待验证] https://github.com/crewAIInc/crewAI
- 核心：Role-playing agents、Task orchestration
- 状态：[待验证] 本轮未抓到最新动态

### AutoGen（Microsoft）
- GitHub：[待验证] https://github.com/microsoft/autogen
- 核心：`ConversableAgent`、Group Chat
- 状态：[待验证] 本轮未抓到最新动态

### Haystack
- GitHub：[待验证] https://github.com/deepset-ai/haystack
- 核心：Pipeline 组件化、RAG pipeline
- 状态：[待验证] 本轮未抓到最新动态

### Semantic Kernel（Microsoft）
- GitHub：[待验证] https://github.com/microsoft/semantic-kernel
- 核心：Plugin、Memory、Planner
- 状态：[待验证] 本轮未抓到最新动态

---

## 推理与部署（2026 年最新动态）

### vLLM
- GitHub：[权威] https://github.com/vllm-project/vllm
- 核心：PagedAttention、continuous batching
- **2026 年新动态**：
  - [权威] `vllm-turboquant`：集成 TurboQuant KV 缓存量化
  - [权威] `1Cat-vLLM`：Tesla V100 (SM70) 支持 + AWQ 4-bit
  - [权威] 原生支持 Mistral Small-4 / Large-3（vLLM 标签）
  - [权威] 社区 patch 支持 GLM-4.7-Flash (`glm4_moe_lite`)

### SGLang
- GitHub：[权威] https://github.com/sgl-project/sglang
- 核心：RadixAttention、speculative decoding
- **2026 年新动态**：
  - [权威] `sglang-omni`：多阶段 Pipeline 框架，Omni 模型支持（212 stars）
  - [权威] 持续支持 DeepSeek MLA 架构

### llama.cpp
- GitHub：[权威] https://github.com/ggerganov/llama.cpp
- 核心：GGUF 格式、量化、CPU/Metal/CUDA
- **2026 年新动态**：
  - [权威] Qwen3.6-35B-A3B GGUF 版本 442K+ 下载
  - [权威] 社区支持 GLM-4.7-Flash
  - [权威] Gemma-4 系列 GGUF 衍生活跃

### 新兴推理框架

| 框架 | Stars | 说明 | 来源 |
|------|-------|------|------|
| **rvLLM** | 432 | Rust 实现，vLLM 替代品 | [权威] GitHub |
| **omlx** | 10.6K | Apple Silicon 推理服务器，连续批处理 + SSD 缓存 | [权威] GitHub |
| **quant.cpp** | 382 | 纯 C 实现，7x 更长上下文，无损 KV 压缩 | [权威] GitHub |
| **nano-vllm** | 192 | 教育版 vLLM 实现 | [权威] GitHub |
| **sparkrun** | 131 | NVIDIA DGX Spark 上的 LLM 推理管理 | [权威] GitHub |

---

## 量化与压缩（2026 年新方法）

| 方法 | 说明 | 来源 |
|------|------|------|
| **TurboQuant** | 3-bit keys / 2-bit values KV 缓存量化 | [权威] GitHub |
| **RotorQuant** | 块对角旋转 KV 压缩，PPL 6.91 vs TurboQuant 7.07 | [权威] GitHub |
| **NVFP4** | NVIDIA 官方 4-bit 浮点量化（Kimi/DeepSeek/Gemma/Qwen 均已支持） | [权威] HF |
| **moe-compress** | MoE 模型自动化压缩（REAP/量化/基准测试） | [权威] GitHub |

---

## 向量数据库（2026 年动态）

| 项目 | Stars | 说明 | 来源 |
|------|-------|------|------|
| **OpenViking** | 22.5K | 专为 AI Agent 设计的开源上下文数据库 | [权威] GitHub |
| **memory-lancedb-pro** | 4.2K | OpenClaw 的 LanceDB 增强记忆插件 | [权威] GitHub |
| **endee** | 1.3K | 单节点 10 亿向量高性能向量数据库 | [权威] GitHub |
| **turbovec** | 333 | 基于 TurboQuant 的 Rust 向量索引 | [权威] GitHub |

---

## Fine-tuning 工具（2026 年动态）

| 工具 | 说明 | 来源 |
|------|------|------|
| **mlx-tune** | Apple Silicon 上 SFT/DPO/GRPO/Vision/TTS 全功能微调 | [权威] GitHub |
| **unsloth-buddy** | Claude Code skill，零摩擦 LLM 微调 | [权威] GitHub |
| **llmfit** | 一键查找硬件可运行的模型 | [权威] GitHub |
| **Soup** | 一键式 LLM 微调工作流 | [权威] GitHub |

---

## 下一轮研究重点

- [ ] DSPy / Instructor / Outlines 2026 年版本更新
- [ ] CrewAI / AutoGen 与 OpenClaw 生态的竞合
- [ ] vLLM vs SGLang vs rvLLM 性能基准对比
- [ ] 向量数据库选型矩阵（Pinecone/Weaviate/Milvus/Qdrant/LanceDB）

---

*2026-04-18 模式 A 验证：推理框架领域呈现"vLLM 主流 + SGLang 追赶 + Rust 新 entrants"格局；量化领域 TurboQuant/RotorQuant/NVFP4 三足鼎立；向量数据库向 Agent-Native 方向演进。*
