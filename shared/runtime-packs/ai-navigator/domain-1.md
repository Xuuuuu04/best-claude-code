---
title: "AI Navigator — Domain 1: Model Selection Decision Tree"
source: core.md §Domain 1
---

# Domain 1: Model Selection Decision Tree

## 1.1 Chinese Model Capability Matrix

| Dimension | DeepSeek V3 | Qwen3-Max | MiniMax-01 | Kimi k1.5 | GLM-4 | HunYuan |
|---|---|---|---|---|---|---|
| Chinese NLU | Excellent | Excellent | Good | Excellent | Good | Good |
| Code (HumanEval) | ~91% | ~85% | ~80% | ~88% | ~82% | ~78% |
| Math (GSM8K) | ~92% | ~90% | ~85% | ~91% | ~86% | ~83% |
| Context window | 64K | 128K | 1M | 200K | 128K | 32K |
| Input cost/M | $0.27 | $1.60 | $0.70 | $1.20 | $0.10* | $0.80 |
| Open weights | Yes | Yes | No | No | No | No |
| API stability | High | High | Medium | High | High | Medium |

*GLM-4-Flash free tier available

## 1.2 Model Selection Decision Tree

```
Start: What is your primary constraint?
├── Cost-sensitive ( <$5/day for 5M tokens)
│   ├── Need open weights → DeepSeek V3
│   └── API-only acceptable → GLM-4-Flash
├── Quality-first (enterprise customer service)
│   ├── Chinese language critical → Qwen3-Max or DeepSeek V3
│   └── Long context needed (>100K) → MiniMax-01 or Kimi
├── On-premise deployment required
│   └── DeepSeek V3 or Qwen3 (Apache 2.0 license)
└── Code generation primary use case
    ├── Agentic coding (SWE-bench) → DeepSeek V3 or Claude
    └── Simple function generation → Any top-tier model
```

## 1.3 Framework Selection Matrix

| Dimension | LangChain | LangGraph | LlamaIndex | DSPy | CrewAI |
|---|---|---|---|---|---|
| Primary strength | General orchestration | Stateful workflows | RAG | Prompt optimization | Multi-agent roles |
| Learning curve | Moderate | Steep | Gentle | Moderate | Gentle |
| Production maturity | High | Medium | High | Medium | Low |
| Observability | LangSmith | LangSmith | Limited | Limited | Limited |
| Chinese docs | Moderate | Limited | Moderate | Limited | Limited |
| Best for | General AI apps | Complex state machines | Document Q&A | Systematic prompt tuning | Role-based teams |

## 1.4 Prompt Paradigm Evolution

| Generation | Technique | Use Case | Example |
|---|---|---|---|
| Zero-shot | Direct instruction | Simple tasks | "Translate to French: {text}" |
| Few-shot | Examples in context | Pattern matching | "Examples: A→B, C→D. Now: E→?" |
| CoT | Step-by-step reasoning | Multi-step problems | "Let's think step by step..." |
| ReAct | Reason + Act + Observe | Tool use | "Thought: I need to search. Action: search('...')" |
| Reflection | Self-critique + retry | Quality improvement | "Review your answer for errors..." |
| Reasoning models | RL-trained CoT | Complex math/logic | o1, R1 (internal reasoning chain) |

## 1.5 Context Engineering Patterns

### RAG Architecture Decision Tree
```
Start: What is your document type and query pattern?
├── Structured documents (manuals, specs)
│   └── Hierarchical chunking (parent-child) + metadata filtering
├── Conversational history
│   └── Sliding window with summary + entity extraction
├── Multi-modal (text + image + table)
│   └── Multi-vector index (text embeddings + image CLIP + table metadata)
└── Real-time data (prices, status)
    └── Hybrid: vector search + structured DB query
```

### Prompt Caching Economics

| Provider | Cache discount | Min tokens | TTL | Best for |
|---|---|---|---|---|
| Anthropic | 90% | 1024 | 5 min | Stable system prompts |
| OpenAI | 50% | 1024 | Auto | Reusable prefixes |
| DeepSeek | 90% | 1024 | 5 min | Long context apps |

Caching ROI calculation:
```python
def cache_roi(hit_rate, prefix_tokens, cost_per_1k):
    """Calculate savings from prompt caching."""
    uncached_cost = prefix_tokens / 1000 * cost_per_1k
    cached_cost = uncached_cost * (1 - discount)
    savings_per_request = uncached_cost - cached_cost
    daily_savings = savings_per_request * requests_per_day * hit_rate
    return daily_savings
```
