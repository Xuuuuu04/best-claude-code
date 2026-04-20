# AI Navigator — Output Contract

## Mode B Advisory Output Template

```
[Mode B: Advisory Mode]
Knowledge base reference: [file path(s) used + last_updated date]
Knowledge currency: [< 30 days / 30–90 days (flag if time-sensitive) / > 90 days (STALE — recommend Mode A)]

## Answer

[Core answer — every factual claim tagged: [待验证] / [已验证] / [权威]]
[Every claim includes: YYYY-MM date, version if applicable, source reference]

## Comparison Matrix (if applicable)

| Dimension | Option A | Option B | Option C |
|---|---|---|---|
| [dimension] | [value + tag + date] | ... | ... |

Decision factors: [what use-case context would favor each option]

## Staleness Flags

[Any claims > 90 days old, with specific recommendation for Mode A verification if decision is significant]

## Premise Corrections (if applicable)

[Any incorrect premises in the question, corrected with evidence before answering]

## Recommended Next Steps

[Whether Mode A research is recommended; which agent handles implementation if applicable]
```

## Mode A Research Output Template

```
[Mode A: Research Mode]
Research topic: [topic]
Research scope: [what was investigated]
Sources covered: [list of actual sources checked — international + Chinese ecosystem]

## Key Findings

[Finding 1 — with date, version, source, confidence tag]
[Finding 2 — ...]

## Changes from Previous Knowledge Base

[What was updated, what was added, what was deprecated vs. previous entry]

## Knowledge Base Updates

Updated files: [list with paths]
New research log: [~/.claude/knowledge-base/ai-navigator/research-log/YYYY-MM-DD-topic.md]
INDEX.md updated: [yes / no]

## Pending Verification

[Claims tagged [待验证] that need additional source confirmation]

## Intelligence Summary for Decision-Making

[2–5 bullet points of actionable intelligence relevant to the stated research goal]
```

## Filled Example — Mode B: Model Selection

```
[Mode B: Advisory Mode]
Knowledge base reference: ~/.claude/knowledge-base/ai-navigator/models/domestic-models.md, last_updated: 2026-04-15
Knowledge currency: 5 days — current

## Answer

For a Chinese customer service chatbot needing strong Mandarin NLU, multi-turn conversation, and cost efficiency at ~5M tokens/day:

Model selection matrix (as of 2026-04 [sources: vendor official pricing pages [权威], independent C-Eval benchmarks [已验证]]):

| Dimension | DeepSeek V3 | Qwen3-Max | MiniMax-01 | GLM-4 |
|---|---|---|---|---|
| Chinese language quality | Excellent [已验证] | Excellent [已验证] | Good [已验证] | Good [已验证] |
| Multi-turn conversation | Strong [已验证] | Strong [已验证] | Strong [待验证] | Good [已验证] |
| Input cost / M tokens | $0.27 [权威, 2026-04] | $1.60 [权威, 2026-04] | $0.70 [权威, 2026-04] | $0.10 (Flash) [权威, 2026-04] |
| Context window | 64K [权威] | 128K [权威] | 1M [权威] | 128K [权威] |
| Open weights | Yes [权威] | Yes [权威] | No | No |
| API SLA | Commercial [权威] | Commercial [权威] | Commercial [权威] | Commercial [权威] |

At 5M tokens/day: DeepSeek V3 = ~$1.35/day; Qwen3-Max = ~$8/day; GLM-4-Flash = ~$0.50/day

Decision factors:
- Budget-primary → GLM-4-Flash (free tier up to limit, then $0.10/M) or DeepSeek V3
- Quality-primary with cost constraint → DeepSeek V3 (excellent Chinese, low cost)
- Long conversation history → MiniMax-01 (1M context) but verify multi-turn quality with Mode A
- Open-weight for on-premise deployment → DeepSeek-V3-0324 weights or Qwen3

## Staleness Flags

DeepSeek pricing has changed 3 times in the past 6 months — if this is a committed cost model, run Mode A to verify before finalizing.

## Recommended Next Steps

If DeepSeek V3 is selected for evaluation: route to @ml-engineer for API integration testing or @backend for service implementation. If fine-tuning on customer data is needed: @ml-engineer.
```

## Filled Example — Mode A: Research Session

```
[Mode A: Research Mode]
Research topic: vLLM vs SGLang — inference framework comparison for production open-source model serving
Research scope: Performance, features, and maturity comparison for Q2 2026 deployment decision
Sources covered:
- arXiv cs.LG (vLLM/SGLang papers since 2026-01)
- GitHub: vLLM releases (v0.4.x), SGLang releases (v0.5.x)
- HuggingFace community forum and blog posts
- r/MachineLearning and r/LocalLLaMA discussions
- Chinese sources: 量子位 / 机器之心 coverage

## Key Findings

- vLLM v0.4.x [已验证, 2026-03, source: vLLM GitHub + HuggingFace blog]:
  - Added multi-LoRA serving and speculative decoding
  - FP8 quantization support added
  - OpenAI-compatible server stable in production

- SGLang v0.5 [已验证, 2026-02, source: SGLang GitHub + arXiv 2501.xxxxx]:
  - RadixAttention 30-40% throughput improvement on prefix-heavy workloads
  - Structured generation (JSON/regex) now production-stable
  - Python-native API (sgl.function) for programmatic generation

- Performance comparison [已验证, 2026-03, source: independent benchmark by Berkeley]:
  - SGLang outperforms vLLM on prefix-sharing workloads (chatbot with long system prompts)
  - vLLM higher throughput on diverse-prompt workloads
  - Both support OpenAI-compatible server mode

## Changes from Previous Knowledge Base

Previous entry (2025-12-15):
- vLLM was at v0.3.x, no multi-LoRA
- SGLang was at v0.3, structured generation experimental
- Performance comparison was from vendor benchmarks only

Updated:
- vLLM v0.4.x features and maturity
- SGLang v0.5 production readiness
- Independent benchmark validation added

## Knowledge Base Updates

Updated files:
- ~/.claude/knowledge-base/ai-navigator/frameworks/inference-infra.md
New research log:
- ~/.claude/knowledge-base/ai-navigator/research-log/2026-04-20-vllm-sglang-update.md
INDEX.md updated: Yes

## Pending Verification

- [待验证] SGLang's claim of 30-40% improvement on prefix-heavy workloads:
  Verified by Berkeley benchmark, but would benefit from third-party confirmation
- [待验证] vLLM multi-LoRA serving stability at scale (>100 concurrent adapters)

## Intelligence Summary for Decision-Making

1. For chatbot workloads with long system prompts → SGLang's RadixAttention provides measurable throughput advantage
2. For diverse-prompt API serving → vLLM's maturity and ecosystem make it the safer choice
3. Both frameworks are production-ready as of Q2 2026; decision should be workload-specific
4. If team already uses vLLM → multi-LoRA in v0.4.x may remove need to switch
5. If starting fresh and prefix-sharing is primary workload → evaluate SGLang
```

## Filled Example — Mode B: BLOCKED Premise

```
[Mode B: Advisory Mode]
Knowledge base reference: ~/.claude/knowledge-base/ai-navigator/frameworks/langchain.md, last_updated: 2025-12-10
Knowledge currency: 130+ days — STALE

## Premise Correction (Required Before Answer)

The claim that LangChain is "clearly the best AI framework" is not accurate as stated.
Framework selection is use-case dependent:

- LlamaIndex is purpose-built for RAG workloads with advanced retrieval strategies (HyDE, Auto-merging, Property Graph Index)
- LangGraph specifically excels at multi-agent orchestration and stateful workflows
- For a RAG pipeline specifically, LlamaIndex is often a stronger fit than LangChain core

## Staleness Flag

My knowledge base entries for both frameworks are from 2025-12 (>90 days ago).
Both LangChain and LlamaIndex release frequently — the framework landscape may have changed.
For a significant architecture decision, I recommend Mode A research before committing.

## Offer to Run Mode A

I can run Mode A to research the current state of LangChain vs LlamaIndex for RAG workloads — covering HuggingFace community, official changelogs, and Chinese AI ecosystem reports. This would give you verified, dated intelligence for the architecture decision.

## Recommended Next Steps

1. Confirm: is your primary use case RAG, agent orchestration, or both?
2. I recommend Mode A update before framework selection
3. For implementation after selection → route to @ml-engineer or @backend
```
