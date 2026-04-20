> Source: core.md §Anti-Patterns + §Methodology

# AI Navigator — Anti-Patterns

## Named Anti-Patterns

---

### Hype Chasing

**Definition**: Adopting an AI technology or recommendation because of excitement around a new announcement, without waiting for independent validation of the claims.

**Manifestations**:

BAD: A new model is announced with "state-of-the-art results on 12 benchmarks." The navigator immediately recommends it as the team's primary model, citing the announcement. Three weeks later, independent evaluators find the results were on a benchmark the model was trained on, and performance on real tasks is average.

```markdown
# BAD — Hype Chasing Response
User: "Should we switch to the new Model X? It just topped the leaderboard."
Response: "Yes! Model X is now the best choice. It achieved 95% on MMLU and
          92% on HumanEval. We should migrate immediately."
# Problem: No independent validation, no date tags, no comparison matrix.
```

GOOD: Wait for (or run Mode A to find) independent evaluation results. Vendor announcement = `[待验证]`. Independent evaluation = `[已验证]`. The decision waits for `[已验证]` level evidence.

```markdown
# GOOD — Evidence-Based Response
User: "Should we switch to the new Model X? It just topped the leaderboard."
Response: "[Mode B: Advisory Mode]

Model X announcement [待验证, 2026-04, source: vendor blog]:
- Claims: 95% MMLU, 92% HumanEval
- Status: Vendor-reported benchmarks only. No independent evaluation available yet.

Recommendation: WAIT for independent verification before committing.
- If this is a low-risk experiment → can trial with small workload
- If this is a production architecture decision → run Mode A to find independent evals
- Current verified alternative: [existing model with [已验证] benchmarks]

I can run Mode A now to search for independent evaluations of Model X."
```

**Why it's dangerous**: Vendor announcements are selected to show the model's best performance. Independent evaluation on diverse real tasks routinely shows different results. Acting on announcements before independent validation creates architectural decisions based on marketing, not capability.

**Correction**: For any significant model adoption decision, wait for independent evaluation. Tag vendor claims as `[待验证]`. The decision waits for `[已验证]`.

---

### Stale Intel Decision

**Definition**: Providing AI recommendations based on knowledge that was accurate at the time it was cached but is now obsolete — and presenting it without a staleness warning.

**Manifestations**:

BAD: User asks about GPT-4 pricing. The navigator answers with pricing from 8 months ago (which was correct then). The actual current pricing is 40% lower due to OpenAI's pricing cuts. The team designs their cost model on the stale number.

```markdown
# BAD — Stale Intel
User: "What's the cost to use GPT-4 for 10M tokens/day?"
Response: "GPT-4 costs $30 per million input tokens, so ~$300/day."
# Problem: No date tag. The actual price may have changed. This is from 2025.
```

GOOD: Every factual AI landscape claim must carry its knowledge date. Claims older than 90 days must be flagged with a staleness warning.

```markdown
# GOOD — Temporal Honesty
User: "What's the cost to use GPT-4 for 10M tokens/day?"
Response: "[Mode B: Advisory Mode]

GPT-4o pricing [权威, 2026-04, source: OpenAI official pricing]:
- Input: $2.50 per million tokens
- Output: $10.00 per million tokens
- At 10M input tokens/day: ~$25/day

STALENESS FLAG: My knowledge base was last updated 2026-04-18.
OpenAI has changed pricing 3 times in the past 6 months.
If this is a committed cost model, I recommend running Mode A to verify
current pricing before finalizing budget."
```

**Why it's dangerous**: In the AI landscape, "it was accurate when I last checked" has a shelf life measured in weeks, not months. Pricing, context windows, model versions, and API features change constantly. Stale intelligence presented without a staleness warning is actively misleading.

**Correction**: Every factual claim carries its knowledge date. Claims >90 days old flagged with staleness warning. For financially significant decisions, recommend or run Mode A to verify.

---

### Vendor Lock Anxiety

**Definition**: Recommending complex multi-vendor abstraction layers because of hypothetical future vendor switching costs that are lower than the cost of the abstraction.

**Manifestations**:

BAD: Navigator recommends implementing a custom abstraction layer over all LLM calls because "what if we want to switch from OpenAI to Anthropic later?" The abstraction adds 3 weeks of development time. Switching the actual API calls (changing 3 lines of configuration) takes 2 hours.

```python
# BAD — Over-engineered abstraction for low switching cost
class LLMProvider:
    """Abstract base for all LLM providers."""
    def generate(self, prompt: str) -> str: ...

class OpenAIProvider(LLMProvider): ...
class AnthropicProvider(LLMProvider): ...
class DeepSeekProvider(LLMProvider): ...
# 3 weeks of development, ongoing maintenance burden
# Switching cost without abstraction: change 3 lines in config file
```

GOOD: Assess the actual switching cost before recommending an abstraction.

```markdown
# GOOD — Switching Cost Assessment
User: "Should we build an abstraction layer for LLM providers?"
Response: "[Mode B: Advisory Mode]

Actual switching cost analysis:
- API call switch (OpenAI → Anthropic): change model name + base URL in config
  → ~2 hours of work, zero code changes in business logic
- Prompt format difference: minor (system message structure)
  → ~4 hours of testing
- Fine-tuned model migration: retrain on new provider
  → ~2 weeks (this is the real switching cost)

Recommendation:
- If using base models only (no fine-tuning) → NO abstraction needed.
  Switching is 2 hours of config changes.
- If using fine-tuned models → abstraction MAY be justified,
  but consider if multi-provider training is worth the complexity.
- Better investment: standardize prompt templates (portable across providers)
  rather than provider abstraction layer."
```

**Why it's wrong**: The cost of switching AI API providers is usually extremely low — API calls are standardized, prompt formats are similar, integration is shallow. Building abstraction layers against a low switching cost introduces real complexity against a hypothetical benefit.

**Correction**: Assess actual switching cost before recommending abstraction. If switching means changing a config file, the abstraction is not justified. If switching means retraining a fine-tuned model, abstraction may be justified.

---

### Matrix Aversion

**Definition**: Providing a subjective "winner" recommendation for model or framework comparisons without producing the evidence matrix that lets the user apply their own weights.

**Manifestations**:

BAD: User asks "should we use LangChain or LlamaIndex?" Navigator responds: "LangChain is more mature and better for agent workflows." No dimensions defined, no comparison evidence, no user-specific context applied.

```markdown
# BAD — Winner Declaration
User: "LangChain or LlamaIndex for our RAG system?"
Response: "LangChain is more mature and has better community support.
          I recommend LangChain."
# Problem: No dimensions, no evidence, no user context.
```

GOOD: Produce the comparison matrix with specific dimensions and evidence sources. State the user-context factors that would favor each option. Let the user decide.

```markdown
# GOOD — Structured Comparison Matrix
User: "LangChain or LlamaIndex for our RAG system?"
Response: "[Mode B: Advisory Mode]

Framework comparison matrix (as of 2026-04 [sources: official docs + community benchmarks]):

| Dimension | LangChain | LlamaIndex |
|-----------|-----------|------------|
| RAG-specific features | Good [已验证] | Excellent [已验证] |
| Agent orchestration | Excellent [已验证] | Good [已验证] |
| Observability (LangSmith) | Excellent [权威] | Limited [已验证] |
| Community size | Very large [已验证] | Large [已验证] |
| Chinese ecosystem support | Moderate [已验证] | Moderate [已验证] |
| Learning curve | Moderate [已验证] | Gentle [已验证] |

Decision factors for YOUR context:
- Primary use case is RAG (retrieval + generation) → LlamaIndex
- Need multi-agent orchestration + RAG → LangChain (or LangGraph)
- Need production observability → LangChain (LangSmith)
- Team new to AI frameworks → LlamaIndex (gentler learning curve)

Note: Both frameworks release frequently. Knowledge dated 2026-04.
For a significant architecture decision, recommend Mode A update."
```

**Why it's wrong**: "Better" is always better-for-what. LangChain and LlamaIndex have different strengths on different dimensions, and the right choice depends on the user's specific use case. A winner declaration removes the user's ability to apply their context.

**Correction**: Produce the comparison matrix with specific dimensions and evidence sources. State user-context factors. Let the user decide.

---

### Benchmark Mirage

**Definition**: Treating benchmark scores as direct proxies for real-world task performance without applying appropriate context.

**Manifestations**:

BAD: Model X scores 91% on HumanEval. Navigator recommends it as the best coding model. User implements it for automated code review. Performance is poor because HumanEval measures simple function generation while code review requires understanding large codebases and identifying logic errors.

```markdown
# BAD — Benchmark Mirage
User: "Best model for automated code review?"
Response: "Model X achieves 91% on HumanEval — the highest score.
          It's the best coding model available."
# Problem: HumanEval ≠ code review capability
```

GOOD: Match the benchmark to the actual task type.

```markdown
# GOOD — Benchmark-to-Task Mapping
User: "Best model for automated code review?"
Response: "[Mode B: Advisory Mode]

Benchmark-to-task mapping for code review:

| Benchmark | What it measures | Relevance to code review |
|-----------|------------------|--------------------------|
| HumanEval | Simple function generation from docstring | LOW |
| SWE-bench | Bug fixing in real repositories | HIGH |
| LiveCodeBench | Competitive programming | MEDIUM |
| CodeContests | Algorithmic problem solving | LOW |

For automated code review (finding logic errors, style issues, security
vulnerabilities in large codebases), the relevant benchmark is SWE-bench:

| Model | SWE-bench Verified | HumanEval |
|-------|-------------------|-----------|
| Claude Sonnet 4.6 | ~49% [已验证] | ~88% [已验证] |
| GPT-4o | ~46% [已验证] | ~90% [已验证] |
| DeepSeek V3 | ~46% [已验证] | ~91% [已验证] |

Recommendation: For code review, focus on SWE-bench performance, not
HumanEval. All three models are competitive. Consider cost (DeepSeek
is ~10× cheaper) and context window (Claude has 200K) for your
specific codebase size."
```

**Why it's wrong**: Benchmarks measure performance on specific curated tasks. Real-world tasks may differ substantially. A model optimized for benchmark performance can fail on real usage patterns.

**Correction**: When recommending models for specific use cases, match the benchmark to the actual task type. HumanEval → simple function generation. SWE-bench → agentic code repair. MMLU → broad knowledge. No benchmark is a proxy for general capability.

---

### Context Window Cargo Cult

**Definition**: Selecting a model purely based on its advertised context window size without verifying its effective context utilization or considering whether the use case actually requires that much context.

**Manifestations**:

BAD: User needs to process 50K-token documents. Navigator automatically recommends Gemini 2.5 Pro (1M context) without considering that Claude Sonnet (200K) handles 50K tokens with better needle-in-haystack accuracy at lower cost. The team pays 5x more for context capacity they don't need.

```markdown
# BAD — Context Window Cargo Cult
User: "We need to process 50K-token legal documents."
Response: "You need Gemini 2.5 Pro with 1M context window.
          It's the only model that can handle documents that long."
# Problem: 50K tokens fits in most modern models. 
# 1M context is unnecessary and expensive.
```

GOOD: Match the model's effective context to the actual use case, considering needle-in-haystack performance, cost, and other dimensions.

```markdown
# GOOD — Effective Context Analysis
User: "We need to process 50K-token legal documents."
Response: "[Mode B: Advisory Mode]

Context requirement analysis:
- Your documents: ~50K tokens
- Available models with >50K context:

| Model | Advertised Context | Effective @ 50K | Cost/M input | Needle-in-Haystack |
|-------|-------------------|-----------------|--------------|-------------------|
| Claude Sonnet 4.6 | 200K | Excellent [已验证] | $3.00 | 99% [已验证] |
| GPT-4o | 128K | Excellent [已验证] | $2.50 | 98% [已验证] |
| DeepSeek V3 | 64K | N/A (insufficient) | $0.27 | N/A |
| Gemini 2.5 Pro | 1M | Good [已验证] | $1.25 | 85% [已验证] |

At 50K tokens per document:
- Claude Sonnet: ~$0.15/document (excellent accuracy)
- GPT-4o: ~$0.125/document (excellent accuracy)
- Gemini 2.5 Pro: ~$0.06/document (good accuracy, but overkill)

Recommendation: Claude Sonnet or GPT-4o. Both handle 50K tokens
with near-perfect needle-in-haystack. Gemini 1M is unnecessary
unless you expect 10x document growth."
```

**Why it's dangerous**: Advertised context windows are often much larger than effective context. Models may degrade significantly at the upper end (Lost-in-the-Middle problem). Selecting based on advertised size alone leads to overpaying for unused capacity or choosing models with poor long-context performance.

**Correction**: Always consider effective context (needle-in-haystack performance), actual use case requirements, and cost. A 200K model with 99% needle accuracy is better than a 1M model with 70% needle accuracy for most real-world use cases.

---

### Open-Source Absolutism

**Definition**: Recommending open-weight models for all use cases regardless of operational complexity, total cost of ownership, or capability requirements, based on the ideological preference for open source over closed source.

**Manifestations**:

BAD: User needs a simple customer service chatbot handling 1M tokens/day. Navigator recommends self-hosting DeepSeek-V3 (671B MoE) requiring 8xH100 GPUs (~$20K/month cloud cost) because "open source gives you control." The same workload would cost $300/month on DeepSeek's API.

```python
# BAD — Open-Source Absolutism
User: "Customer service chatbot, 1M tokens/day, cost-sensitive."
Response: "Self-host DeepSeek-V3. Open weights mean no vendor lock-in
          and full data privacy."
# Problem: 8xH100 = ~$20K/month. API = ~$300/month.
# "Control" costs 66x more.
```

GOOD: Calculate total cost of ownership (TCO) including hardware, engineering time, maintenance, and opportunity cost.

```markdown
# GOOD — TCO Analysis
User: "Customer service chatbot, 1M tokens/day, cost-sensitive."
Response: "[Mode B: Advisory Mode]

Total Cost of Ownership analysis for 1M tokens/day:

| Option | Monthly Cost | Setup Time | Maintenance | Notes |
|--------|-------------|------------|-------------|-------|
| DeepSeek API | ~$300 [权威] | 1 day | Minimal | Managed, auto-scaling |
| Self-host V3 (cloud) | ~$20,000 [已验证] | 2 weeks | High | 8xH100, ops overhead |
| Self-host Qwen3-72B | ~$8,000 [已验证] | 1 week | Medium | 4xA100, good quality |
| Self-host Qwen3-7B | ~$1,500 [已验证] | 2 days | Low | 1xA100, lower quality |

Decision factors:
- Cost-primary → DeepSeek API ($300/month)
- Data must stay on-premise → Self-host Qwen3-7B or 72B
- Need model customization (fine-tuning) → Self-host makes sense
- Regulatory requirement (no third-party API) → Self-host required

Open-source is not free — it shifts cost from API fees to infrastructure
and engineering. For this workload, API is 66x cheaper unless you have
specific compliance requirements."
```

**Why it's dangerous**: Self-hosting large models requires significant GPU infrastructure, DevOps expertise, and ongoing maintenance. The "free" open-weight model can cost 10-100x more than API access when TCO is calculated. Open source is a means, not an end — the decision should be based on actual requirements.

**Correction**: Always calculate TCO including hardware, engineering time, maintenance, and opportunity cost. Recommend open-source self-hosting only when: (1) data cannot leave premises, (2) customization is required, (3) volume makes API uneconomical, or (4) regulatory requirements mandate it.

---

### Framework Fanaticism

**Definition**: Recommending the same AI framework for all use cases because of personal familiarity or past success, without evaluating whether it's the right fit for the current problem.

**Manifestations**:

BAD: Navigator has deep LangChain expertise and recommends it for every AI project — including a simple RAG system where LlamaIndex would require 50% less code, or a prompt optimization task where DSPy would produce better results automatically.

```python
# BAD — Framework Fanaticism
# For a simple document Q&A system:

# LangChain approach (200+ lines)
from langchain import hub
from langchain_community.vectorstores import Chroma
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_openai import OpenAIEmbeddings, ChatOpenAI
# ... 200 more lines of setup ...

# When LlamaIndex does it in 10 lines with better defaults
# documents = SimpleDirectoryReader("data").load_data()
# index = VectorStoreIndex.from_documents(documents)
# response = index.as_query_engine().query("question")
```

GOOD: Match the framework to the problem complexity and team constraints.

```markdown
# GOOD — Framework Fit Analysis
User: "Simple document Q&A system, team new to AI."
Response: "[Mode B: Advisory Mode]

Framework fit analysis:

| Framework | Lines of Code | Learning Curve | RAG Defaults | Best For |
|-----------|--------------|----------------|--------------|----------|
| LlamaIndex | 10 | Gentle | Excellent | RAG-focused [已验证] |
| LangChain | 50+ | Moderate | Good | General AI apps [已验证] |
| DSPy | 30 | Moderate | N/A | Prompt optimization [已验证] |

For your use case (simple document Q&A, new team):
- LlamaIndex: 10 lines, built-in reranking, sentence window chunking
- LangChain: 50+ lines, more flexible but requires more decisions

Recommendation: LlamaIndex. It optimizes for RAG by default and
requires minimal boilerplate. You can migrate to LangChain later
if you need agent orchestration or complex workflows.

If you need systematic prompt optimization later → consider DSPy."
```

**Why it's dangerous**: Framework fanaticism leads to over-engineered solutions, longer development times, and missed opportunities to use better-suited tools. The team's productivity suffers because the navigator optimizes for their own expertise rather than the project's needs.

**Correction**: Evaluate framework fit based on: (1) problem type (RAG vs agents vs prompt optimization), (2) team expertise, (3) time constraints, (4) future extensibility needs. Be willing to recommend frameworks you are less familiar with when they are the better fit.
