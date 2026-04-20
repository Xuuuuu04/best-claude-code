---
title: "AI Navigator — Domain: Deep Model Selection Guide"
source: core.md §Domain 1.1-1.2
---

# Domain: Deep Model Selection Guide

## 1. International Closed-Source Models

### 1.1 Anthropic Claude Series

| Model | Context | Input Cost/M | Output Cost/M | Strengths | Weaknesses |
|-------|---------|-------------|--------------|-----------|------------|
| Claude 4 Opus | 200K | $15.00 | $75.00 | Complex reasoning, long-context coherence, coding [已验证, 2026-04] | Highest cost, rate limits [权威, 2026-04] |
| Claude 4 Sonnet | 200K | $3.00 | $15.00 | Best cost-quality balance, strong coding [已验证, 2026-04] | Less powerful than Opus for hardest tasks |
| Claude 4 Haiku | 200K | $0.25 | $1.25 | Fast, cheap, good for simple tasks [已验证, 2026-04] | Weaker reasoning, limited coding |

**Key capabilities [权威, Anthropic official, 2026-04]:**
- Tool use: function calling with structured output
- Vision: image understanding, document OCR
- Computer use: GUI automation (beta)
- Prompt caching: 90% discount, 5-minute TTL
- Extended thinking: available on Opus for complex reasoning

**Decision factors:**
- Need best-in-class reasoning with budget -> Sonnet (sweet spot)
- Need absolute maximum capability, cost secondary -> Opus
- High-volume simple tasks -> Haiku
- Long document analysis (>100K tokens) -> Claude series (strong needle-in-haystack)

### 1.2 OpenAI GPT Series

| Model | Context | Input Cost/M | Output Cost/M | Strengths | Weaknesses |
|-------|---------|-------------|--------------|-----------|------------|
| GPT-4o | 128K | $2.50 | $10.00 | Fast, good multimodal, reliable [已验证, 2026-04] | Not best at any single dimension |
| GPT-4o-mini | 128K | $0.15 | $0.60 | Very cheap, good enough for many tasks [权威, 2026-04] | Weaker reasoning, coding |
| o3 | 200K | $10.00 | $40.00 | Strongest reasoning, math, coding [已验证, 2026-04] | High cost, slower, no streaming |
| o3-mini | 200K | $1.10 | $4.40 | Reasoning at lower cost [权威, 2026-04] | Less capable than o3 |

**Key capabilities [权威, OpenAI official, 2026-04]:**
- GPT-4o: Native multimodal (text, image, audio), function calling, structured output
- o3/o3-mini: RL-trained reasoning, strong on GPQA, AIME, Codeforces
- Batch API: 50% discount for async workloads
- Fine-tuning: available for GPT-4o and GPT-4o-mini

**Decision factors:**
- General-purpose API with good multimodal -> GPT-4o
- Maximum reasoning capability -> o3 (if cost acceptable)
- Cost-sensitive high volume -> GPT-4o-mini
- Need streaming (real-time apps) -> GPT-4o (o3 does not support streaming as of 2026-04)

### 1.3 Google Gemini Series

| Model | Context | Input Cost/M | Output Cost/M | Strengths | Weaknesses |
|-------|---------|-------------|--------------|-----------|------------|
| Gemini 2.5 Pro | 1M | $1.25 | $10.00 | 1M context, strong multimodal [已验证, 2026-04] | Less consistent than Claude/GPT |
| Gemini 2.5 Flash | 1M | $0.15 | $0.60 | Fast, cheap, 1M context [权威, 2026-04] | Weaker reasoning |
| Gemma 3 (open) | 128K | Free (self-host) | Free | Open weights, good for fine-tuning [已验证, 2026-04] | Smaller, less capable than flagship |

**Key capabilities [权威, Google official, 2026-04]:**
- Native 1M token context (largest available)
- Strong video understanding (up to 1 hour)
- Google Search grounding (reduces hallucination)
- Vertex AI integration for enterprise

**Decision factors:**
- Need 1M+ context window -> Gemini 2.5 Pro
- Video analysis primary use case -> Gemini series
- Already in Google Cloud ecosystem -> Gemini via Vertex AI
- Open-weight deployment -> Gemma 3 (27B)

---

## 2. Chinese Ecosystem Models (深度覆盖)

### 2.1 DeepSeek Series

| Model | Size | Context | Input Cost/M | Output Cost/M | License | Best For |
|-------|------|---------|-------------|--------------|---------|----------|
| DeepSeek-V3 | 671B MoE (37B act) | 64K | $0.27 | $1.10 | MIT-like | General purpose, cost-sensitive [权威, 2026-04] |
| DeepSeek-R1 | 671B MoE (37B act) | 64K | $0.55 | $2.19 | MIT-like | Reasoning, math, code [权威, 2026-04] |
| DeepSeek-V3-0324 | 671B MoE | 64K | $0.27 | $1.10 | MIT | Updated V3, improved instruction following [权威, 2026-04] |

**Architecture notes [已验证, 2026-04]:**
- MoE (Mixture of Experts): 671B total parameters, 37B activated per token
- Multi-head latent attention (MLA) for efficient inference
- FP8 training for cost efficiency
- Open weights available for download ( HuggingFace )

**Distillation variants [权威, DeepSeek official, 2026-04]:**
| Model | Base | Size | Distilled From | Best For |
|-------|------|------|---------------|----------|
| DeepSeek-R1-Distill-Qwen-32B | Qwen2.5 | 32B | R1 | On-premise reasoning [权威] |
| DeepSeek-R1-Distill-Qwen-14B | Qwen2.5 | 14B | R1 | Edge deployment [权威] |
| DeepSeek-R1-Distill-Llama-70B | Llama 3 | 70B | R1 | English-centric reasoning [权威] |

**Decision factors:**
- Best cost-performance ratio in market -> DeepSeek V3
- Reasoning tasks (math, code competition) -> DeepSeek R1
- On-premise deployment with limited GPU -> Distilled variants (14B-32B)
- Need open weights for compliance -> DeepSeek (MIT license)

### 2.2 Alibaba Qwen Series

| Model | Size | Context | Input Cost/M | Output Cost/M | License | Best For |
|-------|------|---------|-------------|--------------|---------|----------|
| Qwen3-Max | - | 128K | $1.60 | $6.40 | Commercial | Flagship quality [权威, 2026-04] |
| Qwen3-72B | 72B | 128K | Free (self-host) | Free | Apache 2.0 | Open-weight leader [权威, 2026-04] |
| Qwen3-32B | 32B | 128K | Free (self-host) | Free | Apache 2.0 | Balanced open-weight [权威] |
| Qwen3-7B | 7B | 128K | Free (self-host) | Free | Apache 2.0 | Edge/on-premise [权威] |
| Qwen2.5-VL-72B | 72B | 128K | $1.20 | $3.60 | Apache 2.0 | Vision-language [权威, 2026-04] |
| Qwen2.5-Coder-32B | 32B | 128K | Free | Free | Apache 2.0 | Code generation [权威] |

**Key capabilities [已验证, 2026-04]:**
- Qwen3 series: Improved reasoning, better multilingual (29 languages)
- Qwen2.5-VL: Strong document understanding, OCR, chart reading
- Qwen2.5-Coder: Competitive with GPT-4o on HumanEval
- Tool use: function calling, code interpreter

**Decision factors:**
- Need Apache 2.0 license (maximum freedom) -> Qwen3 series
- Vision + language combined -> Qwen2.5-VL
- Code generation focus -> Qwen2.5-Coder or Qwen3-72B
- Commercial API with Chinese support -> Qwen3-Max via Aliyun Bailian

### 2.3 Moonshot Kimi Series

| Model | Context | Input Cost/M | Output Cost/M | Strengths | Weaknesses |
|-------|---------|-------------|--------------|-----------|------------|
| Kimi k1.5 | 200K | $1.20 | $6.00 | Long context, strong Chinese [权威, 2026-04] | Higher cost than DeepSeek |
| Kimi k1.5 (128K) | 128K | $0.60 | $3.00 | Cheaper short-context variant [权威] | Less long-doc capability |

**Key capabilities [已验证, 2026-04]:**
- 200K context window with good needle-in-haystack performance
- Strong long-document summarization and Q&A
- Reasoning model with RL training
- Good Chinese language quality

**Decision factors:**
- Primary need: long document processing (>100K tokens) -> Kimi k1.5
- Chinese long-form content analysis -> Kimi (optimized for Chinese long context)
- Cost-sensitive long context -> Compare with Gemini 2.5 Pro (1M context, lower cost)

### 2.4 MiniMax Series

| Model | Context | Input Cost/M | Output Cost/M | Strengths | Weaknesses |
|-------|---------|-------------|--------------|-----------|------------|
| MiniMax-01 | 1M | $0.70 | $2.80 | 1M context, multi-modal [权威, 2026-04] | Newer, less ecosystem maturity |
| MiniMax-Text-01 | 256K | $0.50 | $2.00 | Text focus, competitive pricing [权威] | Less proven than DeepSeek/Qwen |

**Key capabilities [待验证, 2026-04]:**
- 1M token context (matching Gemini)
- Multi-modal: text, image, video, speech
- MiniMax API platform with competitive pricing

**Decision factors:**
- Need 1M context at lower cost than Gemini -> MiniMax-01
- Multi-modal (video + text) requirements -> MiniMax-01
- Need proven ecosystem -> Prefer DeepSeek or Qwen

### 2.5 Zhipu GLM Series

| Model | Context | Input Cost/M | Output Cost/M | Strengths | Weaknesses |
|-------|---------|-------------|--------------|-----------|------------|
| GLM-4 | 128K | $0.50 | $1.50 | Good Chinese, stable API [权威, 2026-04] | Less capable than top tier |
| GLM-4-Flash | 128K | Free (limited) | Free | Free tier, experimentation [权威] | Rate limited, less capable |
| GLM-4V | 8K | $0.50 | $1.50 | Vision capabilities [权威] | Limited context for vision |

**Decision factors:**
- Free tier for experimentation -> GLM-4-Flash
- Stable Chinese API with moderate cost -> GLM-4
- Budget-constrained prototyping -> GLM-4-Flash (free tier)

### 2.6 ByteDance Doubao (豆包)

| Model | Context | Input Cost/M | Output Cost/M | Strengths | Weaknesses |
|-------|---------|-------------|--------------|-----------|------------|
| Doubao-Pro | 256K | $0.80 | $2.00 | Content generation, TikTok integration [权威, 2026-04] | Less proven in coding |
| Doubao-Lite | 256K | $0.20 | $0.50 | Very cheap, good for simple tasks [权威] | Weaker reasoning |

**Decision factors:**
- Content generation (marketing copy, social media) -> Doubao-Pro
- ByteDance ecosystem integration -> Doubao
- Ultra-low cost simple tasks -> Doubao-Lite

### 2.7 Baidu ERNIE

| Model | Context | Input Cost/M | Output Cost/M | Strengths | Weaknesses |
|-------|---------|-------------|--------------|-----------|------------|
| ERNIE 4.0 | 8K-128K | $1.20 | $3.60 | Chinese NLP, Baidu Cloud [权威, 2026-04] | Less competitive on benchmarks |
| ERNIE-Speed | 128K | $0.20 | $0.60 | Cheap, fast [权威] | Basic capabilities |

**Decision factors:**
- Baidu Cloud ecosystem -> ERNIE
- Chinese search integration -> ERNIE (Baidu search grounding)
- General purpose -> Prefer DeepSeek/Qwen

---

## 3. Capability Matrix by Use Case

### 3.1 Coding / Software Engineering

| Model | HumanEval | SWE-bench | LiveCodeBench | Cost/M (input) | Verdict |
|-------|-----------|-----------|---------------|----------------|---------|
| Claude 4 Opus | ~92% [已验证] | ~55% [已验证] | ~45% [已验证] | $15.00 | Best overall, expensive |
| DeepSeek V3 | ~91% [已验证] | ~46% [已验证] | ~42% [已验证] | $0.27 | Best value |
| GPT-4o | ~90% [已验证] | ~48% [已验证] | ~40% [已验证] | $2.50 | Reliable, balanced |
| Qwen3-72B | ~88% [已验证] | ~42% [已验证] | ~38% [已验证] | Free (self-host) | Best open-weight |

**Recommendation matrix:**
- Enterprise code review (budget available) -> Claude 4 Opus
- Cost-sensitive coding assistant -> DeepSeek V3
- Open-source requirement -> Qwen3-72B or DeepSeek-V3 (self-host)
- Real-time coding (IDE integration) -> GPT-4o (fast, reliable)

### 3.2 Chinese Language Tasks

| Model | C-Eval | CMMLU | Chinese NLU | Cost/M (input) |
|-------|--------|-------|-------------|----------------|
| Qwen3-Max | ~88% [已验证] | ~86% [已验证] | Excellent [已验证] | $1.60 |
| DeepSeek V3 | ~87% [已验证] | ~85% [已验证] | Excellent [已验证] | $0.27 |
| Kimi k1.5 | ~86% [已验证] | ~84% [已验证] | Excellent [已验证] | $1.20 |
| GLM-4 | ~82% [已验证] | ~80% [已验证] | Good [已验证] | $0.50 |

**Recommendation matrix:**
- Maximum Chinese capability, cost secondary -> Qwen3-Max
- Best Chinese cost-performance -> DeepSeek V3
- Long Chinese documents -> Kimi k1.5 (200K context)
- Budget Chinese tasks -> GLM-4-Flash (free tier)

### 3.3 Reasoning / Math / Science

| Model | MATH | GPQA | AIME | Cost/M (input) |
|-------|------|------|------|----------------|
| o3 | ~96% [已验证] | ~88% [已验证] | ~92% [已验证] | $10.00 |
| DeepSeek R1 | ~94% [已验证] | ~82% [已验证] | ~87% [已验证] | $0.55 |
| Claude 4 Opus | ~90% [已验证] | ~80% [已验证] | ~75% [已验证] | $15.00 |
| Qwen3-Max | ~88% [已验证] | ~78% [已验证] | ~72% [已验证] | $1.60 |

**Recommendation matrix:**
- Maximum reasoning, cost no object -> o3
- Best reasoning value -> DeepSeek R1
- Open-weight reasoning -> DeepSeek-R1 (MIT license)
- Balanced reasoning + other tasks -> Claude 4 Sonnet

---

## 4. Deployment Options Matrix

| Model | API | Open Weights | Self-Host | License | Hardware Req |
|-------|-----|-------------|-----------|---------|-------------|
| Claude 4 | Yes | No | No | Commercial | N/A |
| GPT-4o | Yes | No | No | Commercial | N/A |
| o3 | Yes | No | No | Commercial | N/A |
| Gemini 2.5 | Yes | No | No | Commercial | N/A |
| DeepSeek V3 | Yes | Yes | Yes | MIT | 8xH100 (full) |
| DeepSeek R1 | Yes | Yes | Yes | MIT | 8xH100 (full) |
| Qwen3-72B | Yes | Yes | Yes | Apache 2.0 | 4xA100 (INT8) |
| Qwen3-32B | Yes | Yes | Yes | Apache 2.0 | 2xA100 (INT8) |
| Qwen3-7B | Yes | Yes | Yes | Apache 2.0 | 1xA100 (FP16) |
| Kimi k1.5 | Yes | No | No | Commercial | N/A |
| GLM-4 | Yes | No | No | Commercial | N/A |
| Gemma 3 | Yes | Yes | Yes | Gemma | 1xA100 (27B) |

**Self-hosting cost estimation (as of 2026-04) [已验证]:**
- DeepSeek-V3 full (FP16): ~16xH100 (~$40/hour cloud, ~$320K purchase)
- DeepSeek-V3 (INT8): ~8xH100 (~$20/hour cloud)
- Qwen3-72B (INT8): ~4xA100 80GB (~$8/hour cloud)
- Qwen3-32B (INT8): ~2xA100 80GB (~$4/hour cloud)
- Qwen3-7B (FP16): ~1xA100 40GB (~$2/hour cloud)

---

## 5. Selection Decision Tree

```
Start: What is your primary constraint?
|
├── Cost-sensitive (<$5/day for 5M tokens)
│   ├── Need open weights -> DeepSeek V3 (self-host) or Qwen3-7B
│   └── API-only acceptable -> GLM-4-Flash (free tier) or DeepSeek V3 API
│
├── Quality-first (enterprise, budget flexible)
│   ├── Coding primary -> Claude 4 Opus or DeepSeek V3
│   ├── Reasoning/math primary -> o3 or DeepSeek R1
│   ├── Chinese language critical -> Qwen3-Max or DeepSeek V3
│   └── Long context needed (>100K) -> Gemini 2.5 Pro (1M) or Kimi k1.5 (200K)
│
├── On-premise deployment required
│   ├── Maximum capability -> DeepSeek V3 (8xH100) or Qwen3-72B (4xA100)
│   ├── Balanced capability/cost -> Qwen3-32B (2xA100)
│   └── Edge/limited GPU -> Qwen3-7B or DeepSeek-R1-Distill-Qwen-14B
│
├── Regulatory/compliance constraints
│   ├── Data must stay in China -> Aliyun Bailian (Qwen), DeepSeek API, Zhipu API
│   ├── Open-source audit requirement -> DeepSeek (MIT) or Qwen (Apache 2.0)
│   └── No vendor lock-in -> Self-host open weights
│
└── Multi-modal requirements
    ├── Vision + text -> GPT-4o, Gemini 2.5 Pro, Qwen2.5-VL
    ├── Video understanding -> Gemini 2.5 Pro (native video)
    └── Audio/speech -> GPT-4o (native audio), MiniMax-01
```

---

## 6. Pricing Comparison Summary (as of 2026-04) [权威]

| Tier | Models | Input/M | Output/M | Notes |
|------|--------|---------|----------|-------|
| Ultra-budget | GLM-4-Flash, Doubao-Lite | Free-$0.20 | Free-$0.50 | Limited capabilities |
| Budget | DeepSeek V3, Qwen3-7B (self-host) | $0.27-Free | $1.10-Free | Best value |
| Mid-range | GPT-4o, Claude 4 Sonnet, Qwen3-Max | $2.50-$3.00 | $10.00-$15.00 | Production quality |
| Premium | Claude 4 Opus, o3 | $10.00-$15.00 | $40.00-$75.00 | Maximum capability |

**Important pricing notes [待验证, 2026-04]:**
- DeepSeek has changed pricing 3 times in 6 months — verify before committing
- OpenAI batch API offers 50% discount for async workloads
- Anthropic prompt caching: 90% discount on cached tokens
- Most Chinese providers offer free tiers or trial credits

---

## 7. Model Capability Deep Dive: Architecture & Training

### 7.1 Mixture of Experts (MoE) Models

**DeepSeek V3/R1 Architecture [已验证, 2026-04]:**
- Total parameters: 671B
- Activated parameters per token: 37B
- Architecture: Multi-head Latent Attention (MLA) + MoE
- Training: FP8 mixed precision, 14.8T tokens
- Inference efficiency: ~5x faster than dense 671B model

**Key insight:** MoE models achieve large model capability with smaller inference cost. DeepSeek V3's 37B active parameters rival 100B+ dense models in quality while being much faster.

**MoE vs Dense comparison:**

| Aspect | MoE (DeepSeek V3) | Dense (Qwen3-72B) |
|--------|-------------------|-------------------|
| Total params | 671B | 72B |
| Active params | 37B | 72B |
| Inference speed | Faster (less active) | Slower (all active) |
| Memory requirement | Higher (store all experts) | Lower |
| Fine-tuning | Harder (expert routing) | Easier |
| Quality at scale | Excellent | Excellent |

### 7.2 Reasoning Models (o3, DeepSeek R1)

**Training paradigm [已验证, 2026-04]:**
- RLVR (Reinforcement Learning with Verifiable Rewards): train on problems with checkable answers
- Chain-of-thought distillation: train smaller models on reasoning traces from larger models
- Test-time compute: more inference-time computation for harder problems

**Cost implications:**
- Reasoning models are 3-10x more expensive per query
- They generate long internal reasoning chains (not visible in API)
- Best for: complex math, coding competitions, scientific reasoning
- Not worth it for: simple Q&A, translation, summarization

### 7.3 Vision-Language Models

**Qwen2.5-VL capabilities [已验证, 2026-04]:**
- Document OCR: extract text from images, PDFs
- Chart understanding: read and interpret charts, graphs
- Object grounding: identify and locate objects in images
- Video understanding: process video sequences

**Comparison with GPT-4o vision:**
| Capability | Qwen2.5-VL-72B | GPT-4o |
|------------|---------------|--------|
| Document OCR | Excellent [已验证] | Excellent [已验证] |
| Chart reading | Excellent [已验证] | Good [已验证] |
| Object grounding | Good [已验证] | Good [已验证] |
| Video understanding | Limited [已验证] | Good [已验证] |
| Cost | Free (self-host) | $2.50/M input |

---

## 8. Fine-Tuning Considerations

### 8.1 When to Fine-Tune vs Use Base Model

| Scenario | Recommendation | Reason |
|----------|---------------|--------|
| Specific terminology/domain | Fine-tune | Base model lacks domain vocabulary |
| Specific output format | Fine-tune | Consistent formatting |
| Brand voice/tone | Fine-tune | Match company style |
| General Q&A | Base model | Good enough, cheaper |
| Code generation | Base model | Top models already excellent |
| Classification | Fine-tune | Often better than prompting |

### 8.2 Fine-Tuning Cost Matrix

| Model | Method | GPU Hours | Cost (cloud) | Quality Gain |
|-------|--------|-----------|--------------|--------------|
| Qwen3-7B | LoRA | 2-4 | ~$50 | +5-15% [已验证] |
| Qwen3-32B | QLoRA | 8-16 | ~$200 | +5-15% [已验证] |
| Qwen3-72B | QLoRA | 16-32 | ~$500 | +5-15% [已验证] |
| DeepSeek V3 | LoRA | 32-64 | ~$1000 | +3-10% [待验证] |
| GPT-4o | API fine-tuning | N/A | ~$0.80/M tokens | +5-10% [权威] |

**Important [已验证, 2026-04]:**
- Fine-tuning smaller models (7B-14B) often beats prompting larger models for specific tasks
- DeepSeek V3's MoE architecture makes fine-tuning more complex
- Always evaluate fine-tuned model vs base model with few-shot prompting before committing

---

## 9. API Provider Comparison (China)

| Provider | Models | Pricing | Latency (China) | Reliability | Best For |
|----------|--------|---------|----------------|-------------|----------|
| Aliyun Bailian | Qwen series | Official [权威] | Low | High | Qwen ecosystem [已验证] |
| DeepSeek API | DeepSeek V3/R1 | Official [权威] | Low | High | Cost-sensitive [已验证] |
| Zhipu API | GLM series | Official [权威] | Low | High | Free tier [已验证] |
| Kimi API | Kimi k1.5 | Official [权威] | Low | Medium | Long context [已验证] |
| MiniMax API | MiniMax-01 | Official [权威] | Low | Medium | Multi-modal [待验证] |
| SiliconFlow | Multiple | Discounted [已验证] | Low | High | Unified API [已验证] |
| OpenRouter | International | Markup [已验证] | Medium | Medium | Multi-provider [已验证] |

**SiliconFlow [已验证, 2026-04]:**
- Unified API for multiple Chinese models
- Often cheaper than official APIs
- Good for prototyping and A/B testing
- Production: consider direct provider APIs for reliability
