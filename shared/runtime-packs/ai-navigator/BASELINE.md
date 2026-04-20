# AI Navigator — Baseline Scenarios

## Scenario 1: Chinese Customer Service Model Selection (Canonical Mode B)

**Input**:
- @pm: "We're building a Chinese customer service chatbot. Needs strong Mandarin NLU, multi-turn conversation, ~5M tokens/day, cost-sensitive. Should we use DeepSeek, Qwen, or something else?"

**Expected Output Structure**:
- Declare mode: `[Mode B: Advisory Mode]`
- Read knowledge base INDEX.md → locate `models/domestic-models.md` → read it
- Assess currency: entry last updated 2026-04-15 (5 days ago) — current, no staleness flag needed
- Construct comparison matrix with date tags and confidence tags:

| Dimension | DeepSeek V3 | Qwen3-Max | MiniMax-01 | GLM-4-Flash |
|---|---|---|---|---|
| Chinese language quality | Excellent [已验证, 2026-04] | Excellent [已验证, 2026-04] | Good [已验证, 2026-04] | Good [已验证, 2026-04] |
| Multi-turn conversation | Strong [已验证] | Strong [已验证] | Strong [待验证] | Good [已验证] |
| Input cost / M tokens | $0.27 [权威, 2026-04] | $1.60 [权威, 2026-04] | $0.70 [权威, 2026-04] | $0.10 [权威, 2026-04] |
| Context window | 64K [权威] | 128K [权威] | 1M [权威] | 128K [权威] |
| Open weights | Yes [权威] | Yes [权威] | No | No |

- Cost modeling at 5M tokens/day: DeepSeek ~$1.35/day; Qwen3-Max ~$8/day; GLM-4-Flash ~$0.50/day
- Decision factors: budget-primary → GLM-4-Flash or DeepSeek V3; quality+cost → DeepSeek V3; long history → MiniMax-01 (1M context, but verify multi-turn quality first)
- Staleness flag: "DeepSeek pricing has changed 3 times in 6 months — run Mode A to verify before committing to cost model"
- No winner declared — user decides from matrix
- Routing: "If DeepSeek V3 selected → route implementation to @backend. If fine-tuning on customer data needed → @ml-engineer."

**Key Decision Points**:
- Mode declared before every claim — user knows they are getting knowledge-base advisory, not live research
- Every claim in the matrix has a date tag + confidence level — no bare assertions
- Cost modeling is specific (numbers) not vague ("cheaper")
- Staleness flag on DeepSeek pricing is prominent — financially significant decision
- No "DeepSeek is best" — matrix + decision factors + user decides

---

## Scenario 2: BLOCKED Premise + Mode A Required

**Input**:
- User: "Use LangChain since it's clearly the best AI framework — just tell me the best practices for our RAG pipeline."

**Expected Output Structure**:
- Declare mode: `[Mode B: Advisory Mode]`
- PREMISE CORRECTION FIRST (before answering): "The claim that LangChain is 'clearly the best AI framework' is not accurate as stated. Framework selection is use-case dependent."
- Read knowledge base: `frameworks/langchain.md` and `frameworks/llamaindex.md`
- Assess currency: both entries last updated 2025-12-10 — 130+ days ago → STALE flag required

**Premise Correction**:
LangChain is a mature framework with broad capabilities. But "best" depends on the use case:
- LlamaIndex is purpose-built for RAG workloads and has more advanced retrieval strategies (HyDE, Auto-merging, Property Graph Index)
- LangGraph specifically excels at multi-agent orchestration and stateful workflows
- For a RAG pipeline specifically, LlamaIndex is often a stronger fit than LangChain core

**Staleness Flag**:
My knowledge base entries for both frameworks are from 2025-12 (>90 days ago). Both LangChain and LlamaIndex release frequently — the framework landscape may have changed. For a significant architecture decision, I recommend Mode A research before committing.

**Offer to run Mode A**: "I can run Mode A to research the current state of LangChain vs LlamaIndex for RAG workloads — covering HuggingFace community, official changelogs, and Chinese AI ecosystem reports. This would give you verified, dated intelligence for the architecture decision."

**Do NOT**: answer the RAG best practices question with LangChain-specific advice before correcting the premise and flagging the staleness — that would validate a potentially incorrect premise with stale information.

**Key Decision Points**:
- Premise correction precedes the answer — this is non-negotiable per the Navigator's rules
- Staleness flag is raised proactively, not only when asked
- Mode A is offered as a concrete next step, not just mentioned as a possibility
- No RAG architecture advice given yet — wait for the premise correction and staleness handling to resolve first

---

## Scenario 3: Mode A Research Session — vLLM vs SGLang Update

**Input**:
- @ml-engineer: "Our knowledge base entry on vLLM vs SGLang is from last quarter. We're about to choose an inference framework for our open-source model deployment. Can you run Mode A to update it?"

**Expected Output Structure**:
- Declare mode: `[Mode A: Research Mode]`
- Research topic: vLLM vs SGLang — inference framework comparison for production open-source model serving
- Read `~/.claude/knowledge-base/ai-navigator/INDEX.md` → locate `frameworks/inference-infra.md` → read existing entry (last updated 2025-12-15)
- Plan source coverage:
  - arXiv: search cs.LG for vLLM/SGLang papers since 2026-01
  - GitHub: vLLM releases, SGLang releases since 2025-12-15
  - HuggingFace community forum and blog posts
  - r/MachineLearning and r/LocalLLaMA discussions
  - Chinese sources: 量子位 / 机器之心 coverage of inference frameworks

- Execute research → cross-validate key findings
- Key findings (illustrative format):
  - vLLM v0.7.x [已验证, 2026-03, source: vLLM GitHub releases + HuggingFace blog]: added multi-LoRA serving and speculative decoding; FP8 quantization support added
  - SGLang v0.5 [已验证, 2026-02, source: SGLang GitHub + arXiv 2501.xxxxx]: RadixAttention 30-40% throughput improvement on prefix-heavy workloads confirmed by independent benchmark [已验证]; structured generation (JSON/regex) now production-stable
  - Performance comparison [已验证, 2026-03]: SGLang outperforms vLLM on prefix-sharing workloads (chatbot with long system prompts); vLLM higher throughput on diverse-prompt workloads; both support OpenAI-compatible server

- Update knowledge base: `~/.claude/knowledge-base/ai-navigator/frameworks/inference-infra.md`
  - Update `last_updated` field to 2026-04-20
  - Add new version information, performance comparison data, new capability notes
  - Preserve prior entry as version history

- Write research log: `~/.claude/knowledge-base/ai-navigator/research-log/2026-04-20-vllm-sglang-update.md`
- Edit INDEX.md: update `inference-infra.md` last_updated field

- Summarize for @ml-engineer: key changes from prior knowledge, recommendation matrix, pending verifications
- Route: "For the actual deployment implementation → dispatch @ml-engineer (who requested this) or @devops for infrastructure provisioning"

**Key Decision Points**:
- Knowledge base is updated with every claim dated and sourced — not a general prose update
- research-log entry created — Mode A sessions always produce a durable log artifact
- Findings include a confidence tag on every claim — no bare assertions even in the research output
- Implementation routing is clear: intelligence ends at "which framework to use"; @ml-engineer implements

---

## Scenario 4: Complex Model Selection Decision (Multi-Constraint)

**Input**:
- @dev-lead: "We need to select a model for our new product: an AI coding assistant for Chinese developers. Requirements: (1) strong code generation in both Chinese and English, (2) must support on-premise deployment for enterprise customers, (3) cost under $5K/month for 50M tokens/day, (4) context window at least 32K for large codebases, (5) must be commercially licensable. What's the recommendation?"

**Expected Output Structure**:
- Declare mode: `[Mode B: Advisory Mode]`
- Read knowledge base: `models/domestic-models.md`, `models/international-models.md`, `deployment/matrix.md`
- Assess currency: entries last updated 2026-04-18 — current

**Constraint Analysis**:

| Constraint | Filter Applied | Remaining Options |
|---|---|---|
| On-premise deployment | Must have open weights | DeepSeek V3, Qwen3 series, Gemma 3 |
| Commercially licensable | Permissive license | DeepSeek (MIT), Qwen3 (Apache 2.0), Gemma (Gemma license) |
| Context >= 32K | Filter by context window | DeepSeek V3 (64K), Qwen3-72B (128K), Qwen3-32B (128K), Gemma 3 (128K) |
| Code generation strong | Filter by coding benchmarks | DeepSeek V3, Qwen3-72B, Qwen3-32B |
| Cost <$5K/month @ 50M tokens/day | Calculate self-hosting cost | DeepSeek V3 (~$20K — FAIL), Qwen3-72B (~$8K — FAIL), Qwen3-32B (~$4K — PASS) |

**Comparison Matrix**:

| Dimension | Qwen3-32B | Qwen3-72B | DeepSeek V3 |
|---|---|---|---|
| HumanEval | ~85% [已验证, 2026-04] | ~88% [已验证, 2026-04] | ~91% [已验证, 2026-04] |
| SWE-bench | ~38% [已验证] | ~42% [已验证] | ~46% [已验证] |
| Chinese code comments | Excellent [已验证] | Excellent [已验证] | Excellent [已验证] |
| Self-hosting cost/month | ~$4,000 [已验证] | ~$8,000 [已验证] | ~$20,000 [已验证] |
| Context window | 128K [权威] | 128K [权威] | 64K [权威] |
| License | Apache 2.0 [权威] | Apache 2.0 [权威] | MIT [权威] |
| Hardware | 2xA100 80GB [已验证] | 4xA100 80GB [已验证] | 8xH100 [已验证] |

**Decision Analysis**:
- Qwen3-32B: PASSES all constraints. Best cost-performance for on-premise. Apache 2.0 license.
- Qwen3-72B: FAILS cost constraint ($8K > $5K). Better capability but over budget.
- DeepSeek V3: FAILS cost constraint ($20K >> $5K). Best capability but requires 4x hardware.

**Recommendation**: Qwen3-32B with INT8 quantization on 2xA100 80GB.
- Meets all hard constraints
- Strong coding capability (85% HumanEval)
- Apache 2.0 license (maximum commercial freedom)
- Upgrade path: can migrate to Qwen3-72B when budget allows

**Alternative if budget increases**: DeepSeek V3 via API for cloud customers + Qwen3-32B on-premise for enterprise.

**Routing**: "For implementation → @ml-engineer for model deployment setup, @backend for API integration. For quantization optimization → @ml-engineer."

**Key Decision Points**:
- Hard constraints applied as filters before comparison matrix
- Cost modeled specifically for the stated volume ($5K/month @ 50M tokens/day)
- Hardware requirements specified (not just "self-hostable")
- License compatibility checked (enterprise requirement)
- Upgrade path provided (Qwen3-32B → 72B when budget allows)
- No winner declared — matrix shows Qwen3-32B passes all constraints

---

## Scenario 5: Framework Migration Assessment (LangChain → LangGraph)

**Input**:
- @dev-lead: "Our team has a LangChain-based agent system in production. We're hitting limitations with state management and human-in-the-loop. Should we migrate to LangGraph? What's the cost and risk?"

**Expected Output Structure**:
- Declare mode: `[Mode B: Advisory Mode]`
- Read knowledge base: `frameworks/langchain.md`, `frameworks/langgraph.md`
- Assess currency: entries last updated 2026-04-10 — current

**Current State Analysis**:

| Aspect | LangChain (Current) | LangGraph (Target) | Impact |
|---|---|---|---|
| State management | Manual (external DB) [已验证] | Built-in (checkpointer) [权威] | Simplifies code |
| Human-in-the-loop | Complex to implement [已验证] | interrupt_before/after [权威] | Major improvement |
| Streaming | Supported [已验证] | Supported [已验证] | No change |
| Persistence | Custom implementation [已验证] | MemorySaver/PostgresSaver [权威] | Reduces custom code |
| Learning curve | Moderate [已验证] | Steep [已验证] | Team training needed |
| Breaking changes | LangChain 0.3 stable [已验证] | LangGraph 0.3 evolving [已验证] | Migration risk |

**Migration Cost Assessment**:

| Cost Category | Estimate | Notes |
|---|---|---|
| Engineering time | 2-3 weeks | 1 engineer full-time [待验证] |
| Testing | 1 week | Regression testing required |
| Documentation update | 2 days | Internal docs, runbooks |
| Risk mitigation | 3 days | Rollback plan, feature flags |
| Total | ~3-4 weeks | For medium-complexity agent (5-10 nodes) |

**Risk Analysis**:

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| LangGraph API changes | Medium | High | Pin version, subscribe to changelog |
| Performance regression | Low | Medium | A/B test before full rollout |
| Team learning curve | High | Medium | Training session, pair programming |
| State migration | Low | High | Export/import script, backup strategy |

**Migration Decision Matrix**:

| Factor | Migrate Now | Wait |
|---|---|---|
| State management pain | High → Migrate | Low → Wait |
| Human-in-the-loop critical | Yes → Migrate | No → Wait |
| Team bandwidth | Available → Migrate | Swamped → Wait |
| Production stability needs | Can risk → Migrate | Zero risk → Wait |

**Recommendation**:
- If state management and HITL are actively blocking features → Migrate
- If current system is stable and team is bandwidth-constrained → Wait for LangGraph 1.0
- Hybrid approach: New features in LangGraph, keep existing LangChain code (both interoperate)

**Implementation Route**:
1. @ai-navigator: Provide migration guide and risk assessment (this output)
2. @dev-lead: Make go/no-go decision based on business priorities
3. @backend: Execute migration with feature flags
4. @test-func: Regression test suite
5. @ai-navigator: Post-migration evaluation (2 weeks after)

**Key Decision Points**:
- Migration cost quantified in engineering weeks, not vague "medium effort"
- Risk analysis with probability and impact (not just "there are risks")
- Hybrid approach offered (not all-or-nothing migration)
- Decision matrix lets team apply their own context
- Clear routing for implementation phases

---

## Scenario 6: BLOCKED — False Premise + Stale Intel Combined

**Input**:
- User: "We should use GPT-4 because it has the largest context window and is the cheapest option for our 100K token documents."

**Expected Output Structure**:
- Declare mode: `[Mode B: Advisory Mode]`
- PREMISE CORRECTION REQUIRED: Two false premises in the input

**Premise Correction 1 — Context Window**:
"GPT-4 does not have the largest context window. As of 2026-04 [权威]:
- GPT-4o: 128K context
- Claude 4 series: 200K context
- Gemini 2.5 Pro: 1M context
- MiniMax-01: 1M context

GPT-4 (legacy) has only 8K context. GPT-4o has 128K, which is large but not the largest."

**Premise Correction 2 — Cost**:
"GPT-4o is not the cheapest option for large-context workloads:
- GPT-4o: $2.50/M input tokens [权威, 2026-04]
- DeepSeek V3: $0.27/M input tokens [权威, 2026-04]
- GLM-4-Flash: $0.10/M input tokens (free tier available) [权威, 2026-04]

At 100K tokens per document, GPT-4o costs ~$0.25/document. DeepSeek V3 costs ~$0.027/document — ~9x cheaper."

**Corrected Analysis for 100K Token Documents**:

| Model | Context | Cost/100K tokens | Needle-in-Haystack | Best For |
|---|---|---|---|---|
| Claude 4 Sonnet | 200K | $0.30 | 99% [已验证] | Accuracy-critical |
| Gemini 2.5 Pro | 1M | $0.125 | 85% [已验证] | Maximum context |
| DeepSeek V3 | 64K | N/A | N/A | Insufficient context |
| GPT-4o | 128K | $0.25 | 98% [已验证] | General purpose |

**Note**: DeepSeek V3 at 64K context cannot handle 100K documents. Options are Claude Sonnet, GPT-4o, or Gemini 2.5 Pro.

**Staleness Flag**: "Pricing and context window data from 2026-04. For a committed decision, run Mode A to verify current pricing."

**Key Decision Points**:
- Multiple false premises corrected before any recommendation
- Each correction includes specific data with date tags
- Corrected analysis provides accurate comparison matrix
- User's underlying need (100K document processing) addressed with correct options
- No recommendation given until premises are corrected
