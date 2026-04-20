# 深度研究员 — Output Contract

Every research engagement delivers a structured report saved to `research/[topic]-[YYYYMMDD].md`. Omitting any required field is a defect.

---

## Standard Output Template

```
## Deep Research Report: [Topic]

**Research Questions** (3–5 sub-questions)
1. [specific, answerable sub-question]
2. [specific, answerable sub-question]
3. [specific, answerable sub-question]

**Research Scope**
- Time range: [YYYY–YYYY]
- Primary sources: [venues, databases, search engines used]
- Exclusion criteria: [what was deliberately excluded and why]

**Search Coverage Summary**
- Round 1 (surveys): N papers identified, M read in depth
- Round 2 (core): N papers, M read
- Round 3 (recent): N papers, M read
- Round 4 (practice): N sources

**Method Taxonomy**
[X method families identified]

**Core Findings** (per sub-question)
- Established consensus: [claim] [citations A/B-level]
- Promising-but-contested: [claim] [flagged]
- Speculative: [claim] [flagged, single source]

**Comparison Table** (5+ dimensions)
| Method | Performance profile | Compute cost | Data requirements | Failure modes | Production friction |

**Evolution Logic**
[Causal chain: why did the field move from A → B → C?]

**Open Problems** (≥2)

**Coverage Limitations**

**Staleness Declaration**
All SOTA claims and benchmark numbers in this report are as of [YYYY-MM-DD].

**Recommended Next Step**
[@ml-engineer / @architect / @doc-writer — with rationale]
```

---

## Filled-in READY Example

```
## Deep Research Report: RAG vs. Fine-tuning for Enterprise QA

**Research Questions**
1. What are the major architectural variants of RAG, and what are their known performance trade-offs on knowledge-intensive QA benchmarks?
2. Under what conditions does fine-tuning outperform retrieval augmentation for knowledge injection, and vice versa?
3. What are the known failure modes of RAG on long-context, multi-hop reasoning tasks?
4. What does industrial deployment experience add to the academic picture?
5. What are the open problems the field itself identifies as unsolved?

**Research Scope**
- Time range: 2019–2026
- Primary sources: arXiv, NeurIPS, ICML, ICLR, ACL, EMNLP
- Exclusion criteria: Multilingual QA excluded (focus on English); structured data retrieval (KBQA) excluded; purely generative models without retrieval excluded

**Search Coverage Summary**
- Round 1 (surveys): 8 survey papers identified, 3 read in depth
- Round 2 (core): 15 high-citation papers (≥100 citations), 8 read in depth
- Round 3 (recent): 22 papers from 2024–2025, 6 read in depth
- Round 4 (practice): 12 industrial sources (engineering blogs, case studies, PwC leaderboards)

**Method Taxonomy**
4 families identified:
1. Sparse retrieval RAG (BM25, TF-IDF + seq2seq generator)
2. Dense retrieval RAG (DPR, ANCE + generator)
3. Hybrid RAG (sparse + dense fusion)
4. Iterative/multi-hop RAG (IRRR, Self-RAG, Corrective RAG)

**Core Findings**

Q1: Architectural variants and trade-offs
- Established consensus: Dense retrieval (DPR) consistently outperforms sparse retrieval on open-domain QA benchmarks [Lewis et al., 2020 A; Karpukhin et al., 2020 A]. Hybrid approaches show marginal gains on specific datasets but increase latency by 40-60% [as of 2026-04-20].
- Promising-but-contested: Iterative retrieval improves multi-hop accuracy but error propagation remains unresolved [single venue: ICLR 2024].

Q2: Fine-tuning vs. RAG conditions
- Established consensus: RAG outperforms fine-tuning when knowledge changes frequently and retrieval corpus is representative [Lewis et al., 2020 A; Izacard et al., 2022 A]. Fine-tuning outperforms RAG when knowledge is domain-specific and not well-represented in the retrieval corpus [Meng et al., 2022 B].
- Speculative: Adaptive retrieval (retrieving only when needed) reduces latency by 30% but evaluation limited to 3 datasets [single-source preprint, as of 2026-04-20].

Q3: Failure modes
- Established: RAG fails on questions requiring synthesis across >5 documents [single-source but replicated: HotpotQA analysis].
- Established: Retrieval noise (irrelevant passages) degrades generation quality more than missing relevant passages [Shi et al., 2023 B].

Q4: Industrial experience
- Established: Production RAG requires continuous index updates (daily/hourly), which academic benchmarks do not evaluate [Google Research blog B; Meta AI blog B].
- Established: Latency constraints (P95 < 200ms) often force approximate retrieval, which academic papers rarely benchmark [Microsoft Research blog B].

Q5: Open problems
1. Multi-hop error propagation: iterative retrieval compounds errors; no robust solution exists [field consensus].
2. Corpus maintenance at scale: how to update indices without downtime or inconsistency [industrial gap].

**Comparison Table**
| Method | Performance (NQ) | Compute cost | Data requirements | Failure modes | Production friction |
|--------|-----------------|--------------|-------------------|---------------|---------------------|
| Sparse RAG | 35.0 EM | Low | Large corpus | Vocabulary mismatch | Low |
| Dense RAG | 41.5 EM | Medium | Corpus + embeddings | Distribution shift | Medium |
| Hybrid RAG | 42.1 EM | High | Both above | Latency | High |
| Iterative RAG | 48.2 EM (multi-hop) | Very high | Corpus + reasoning data | Error propagation | Very high |

**Evolution Logic**
Closed-book generation (2018) → RAG (retrieve before generate, 2020) → Dense retrieval (DPR, 2020) → Iterative/multi-hop (2023-2024). Each transition was motivated by a specific failure mode: closed-book hallucinated facts; RAG with sparse retrieval missed semantic matches; single-step RAG failed on multi-hop questions. Iterative RAG solves multi-hop but introduces error propagation, which is the current frontier.

**Open Problems**
1. Multi-hop error propagation: iterative retrieval compounds errors at each step. Current best (Self-RAG) uses reflection but adds 3× latency.
2. Corpus maintenance at scale: academic benchmarks use static corpora. Production systems need hourly updates without downtime.

**Coverage Limitations**
- Multilingual QA excluded (focus on English)
- Structured data retrieval (KBQA) excluded
- Real-time streaming corpora not covered
- Cost analysis based on US cloud pricing only

**Staleness Declaration**
All SOTA claims and benchmark numbers in this report are as of 2026-04-20.

**Recommended Next Step**
@ml-engineer: Implement dense RAG with DPR as baseline. Evaluate on your specific corpus before considering hybrid or iterative variants. If your domain knowledge is stable and not in the retrieval corpus, consider fine-tuning as alternative. Budget 2 weeks for baseline, 1 week for fine-tuning comparison.
```

---

## Filled-in BLOCKED Example

```
## Research Request: LangChain Analysis

**Status**: UNSURE — one clarifying question before routing

**Request**: "深度竞品分析一下 LangChain"

**Ambiguity Identified**: LangChain analysis can mean different things:

1. **Product evaluation for your use case** — which specific libraries to use and why
   - Scope: @tech-research, 1–3 hours
   - Output: feature comparison, pricing, integration effort

2. **Strategic competitive analysis** — LangChain's thesis, architectural moat, ecosystem trajectory
   - Scope: @researcher deep-dive, 2–4 days
   - Output: competitive positioning, moat analysis, trajectory prediction

3. **Quick feature comparison** against LlamaIndex/Haystack
   - Scope: @tech-research, a few hours
   - Output: feature matrix, recommendation

**Which fits your need?**

- If (1) or (3) → route to @tech-research immediately
- If (2) → researcher scope, proceed with full competitive methodology
```

---

## Filled-in Competitive Deep-Dive Example

```
## Competitive Deep-Dive: LangChain Strategic Positioning

**Competitive Question**: What is LangChain's strategic thesis, and what does it make genuinely hard for them?

**Technical Artifacts**
- Engineering blog analysis: LangChain optimizes for "chains" — composable LLM operations
- Open-source code: 80% of codebase is integration adapters (200+ model/provider integrations)
- Job postings: hiring for "integration engineer" roles, not "research scientist"

**Business Signals**
- Funding: $30M Series A (2023), focused on enterprise adoption
- Headcount: ~30 people, mostly engineering
- Community: 80k+ GitHub stars, high StackOverflow activity

**User Voice**
- Praise: "Easy to prototype with" (rapid integration)
- Complaint: "Hard to productionize" (abstraction overhead, debugging difficulty)
- Pattern: Users start with LangChain, migrate to custom code for production

**Thesis Analysis**
LangChain's bet: LLM applications will be built from composable, reusable components (chains). Their moat is integration breadth (200+ adapters), not technical depth.

**Moat Question**
What would a competitor need to replicate that is genuinely hard to replicate?
- Integration breadth: replicable with engineering effort (not structural)
- Community mindshare: harder to replicate, but fragile (depends on continued hype)
- NOT structural: no proprietary data, no network effects, no switching costs

**Trajectory Prediction**
LangChain is vulnerable to:
1. Framework fatigue (users outgrow abstractions)
2. Provider consolidation (OpenAI/Anthropic providing native SDKs)
3. Production-focused competitors (LlamaIndex's indexing focus, custom code)

**Recommended Next Step**
@architect: If evaluating LangChain for production use, budget for migration to custom code within 6-12 months. For prototyping, LangChain is appropriate. For long-term production systems, consider lighter abstractions or direct SDK usage.
```

---

## Self-Check Before Report Delivery

- [ ] Did I translate the request into 3–5 specific sub-questions before searching?
- [ ] Did I confirm scope (time range, language, venue priority, exclusions)?
- [ ] Did I execute four-round search (surveys → core → recent → practice)?
- [ ] Did I read methodology + experiments for every core reference (not just abstracts)?
- [ ] Did I cross-validate every key conclusion with ≥2 independent sources?
- [ ] Did I synthesize by method taxonomy (not timeline)?
- [ ] Did I apply A–E credibility labels to all citations?
- [ ] Did I include a 5+ dimension comparison table?
- [ ] Did I identify ≥2 genuine open problems?
- [ ] Did I state coverage limitations explicitly?
- [ ] Did I include staleness dates on all SOTA claims?
- [ ] Did I run the field/product routing test before beginning?
- [ ] Did I save the report to `research/[topic]-[YYYYMMDD].md`?
