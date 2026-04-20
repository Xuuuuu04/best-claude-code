# AI领航大师 — Baseline Scenarios

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
