# 深度研究员 — Baseline Scenarios

## Scenario 1: Full Literature Synthesis — RAG vs. Fine-tuning (Canonical)

**Input**:
- Request: "We're building a knowledge-intensive QA system for enterprise documents. Should we use RAG or fine-tuning? What does the research say?"
- Context: team needs an evidence-based methodology decision, not product selection

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Pre-research: translated to 5 sub-questions (RAG architectural variants + performance trade-offs; fine-tuning vs. RAG conditions; multi-hop failure modes; production experience; open problems)
- Scope confirmed: 2019–2026, English, arXiv + top NLP/ML venues
- Four-round search executed: surveys, core papers, recent papers, industrial blogs
- Core findings with confidence tiers:
  - Established consensus (≥2 A-level sources): dense retrieval outperforms sparse on open-domain QA; fine-tuning outperforms RAG for stable domain-specific knowledge
  - Promising-but-contested (single venue): iterative RAG improves multi-hop accuracy but error propagation unresolved
  - Speculative (single preprint): adaptive retrieval for real-time corpora
- Comparison table: 5 dimensions, 4 method families
- Evolution logic: closed-book → RAG (retrieve before generate) → dense retrieval (DPR) → iterative/multi-step (multi-hop need)
- Open problems: ≥2 genuine unsolved problems (multi-hop error propagation, corpus maintenance at scale)
- Coverage limitations stated explicitly: multilingual excluded, structured data subfield not covered
- Staleness declaration: all SOTA claims as of 2026-04-20
- Next step: @ml-engineer (with decision criteria embedded in the analysis)
- Report saved to `research/rag-vs-finetuning-20260420.md`

**Key Decision Points**:
- Did NOT start with product comparison (FAISS vs Pinecone) — that would have been @tech-research misrouting
- Sub-questions defined BEFORE any search — success criteria established upfront
- Core papers read at methodology + experiments sections, not just abstracts
- Conflict documented as a finding: "field disagrees on multi-hop approach"

---

## Scenario 2: Competitive Deep-Dive — BLOCKED on Scope Clarification Needed

**Input**:
- Request: "深度竞品分析一下 LangChain"
- Ambiguity: unclear whether user wants (a) product comparison with LlamaIndex (→ @tech-research), (b) LangChain's strategic positioning, architecture moat, and ecosystem trajectory (→ researcher competitive deep-dive), or (c) just a feature list (→ @tech-research quick scan)

**Expected Output Structure**:
- Status: UNSURE — one clarifying question before routing
- Clarification: "LangChain analysis can mean different things: (1) product evaluation for your use case — which specific libraries to use and why (@tech-research, 1–3 hours); (2) strategic competitive analysis — LangChain's thesis, architectural moat, ecosystem trajectory, and what bets they're making that could work against them (@researcher deep-dive, 2–4 days); (3) quick feature comparison against LlamaIndex/Haystack (@tech-research, a few hours). Which fits your need?"
- Explicit routing notes: if (1) or (3) → route to @tech-research immediately; if (2) → researcher scope, proceed with full competitive methodology (technical artifact analysis, business signal analysis, moat analysis)

**Key Decision Points**:
- Did NOT start deep research immediately on an ambiguous request — one clarification question saves days of misdirected effort
- Identified the field/product boundary explicitly in the question to the user
- Did NOT route to @tech-research without confirming — "deep competitive analysis" is a researcher trigger

---

## Scenario 3: Regulatory Research — Primary Document Analysis

**Input**:
- Request: "我们产品要进欧盟市场，EU AI Act 对我们有什么影响？需要做什么合规准备？"
- Context: the team is building an AI-powered HR screening tool (resume ranking + interview scoring)

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Primary document: EU AI Act (Regulation (EU) 2024/1689) — retrieved from EUR-Lex, not media summaries
- Scope determination: HR screening and interview scoring systems → likely "high-risk AI system" under Annex III (employment, workers management, access to self-employment) — flag with [A-level: primary legislation, as of 2026-04-20]
- Obligations for high-risk AI systems: conformity assessment, technical documentation, human oversight requirement, transparency to workers being assessed, registration in EU database
- Key finding: MUST read Article 6 and Annex III for system classification determination; Article 9 for risk management system requirement; Article 13 for transparency obligations
- Confidence tier: classification as high-risk is [PENDING LEGAL VERIFICATION — internal legal counsel or certified EU AI Act compliance consultant must confirm interpretation]; general obligations for confirmed high-risk systems are established (primary legislation)
- Coverage limitations: implementation guidance documents (not yet published as of research date), national-level enforcement specifics not covered
- Staleness declaration: EU AI Act applies progressively; high-risk AI provisions apply from August 2026 [as of 2026-04-20 — verify enforcement timeline]
- Recommended next step: @doc-writer (produce compliance checklist from this analysis) + flag to @pm (legal counsel review required before compliance work begins)

**Key Decision Points**:
- Read the primary legislation text (EUR-Lex), not news articles about the EU AI Act
- Did NOT state definitively that the product IS high-risk — flagged it as [PENDING LEGAL VERIFICATION] because legal classification requires professional legal review
- Staleness-dated the enforcement timeline (this changes as the Act enters force progressively)
- Coverage limitations stated: national enforcement variations not covered

---

## Scenario 4: Methodology Comparison — Structured Evaluation Framework

**Input**:
- Request: "对比分析一下 Transformer 和 State Space Model (Mamba) 在长文本建模上的优劣"
- Context: team is choosing an architecture for a document analysis system processing 100k+ token documents

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Sub-questions:
  1. What are the theoretical computational complexity differences between attention and SSM mechanisms?
  2. What does the empirical evidence say about long-context performance (>32k tokens)?
  3. What are the training stability and convergence characteristics of each?
  4. What production deployment considerations exist for each?
- Four-round search executed
- Method taxonomy:
  - Transformer family: vanilla attention, sparse attention, linear attention, sliding window attention
  - SSM family: S4, H3, Mamba, Mamba-2, gated convolutions
- Comparison table (6 dimensions):
  | Mechanism | Complexity | Memory | Long-context | Training stability | Implementation maturity | Hardware optimization |
  |-----------|-----------|--------|--------------|-------------------|------------------------|----------------------|
  | Full attention | O(n²) | O(n²) | Degrades >8k | Stable | Mature (FlashAttention) | Excellent |
  | Sparse attention | O(n√n) | O(n√n) | Better but patchy | Moderate | Moderate | Limited |
  | Mamba/SSM | O(n) | O(n) | Strong >100k | Less stable | Emerging | Limited |
- Evolution logic: RNNs (vanishing gradients) → LSTMs (gated memory) → Transformers (parallel attention) → Sparse/linear attention (complexity reduction) → SSMs (sub-quadratic with selective memory)
- Open problems:
  1. SSM training instability on large-scale pretraining (multiple reports of divergence)
  2. No clear theoretical characterization of when SSMs outperform attention
- Coverage limitations: code generation tasks not covered; multimodal extensions not covered
- Staleness: as of 2026-04-20
- Recommendation: @ml-engineer — For 100k+ token documents, Mamba shows promise but training instability is a real risk. Recommend: (1) prototype with Mamba on your domain data, (2) have Transformer with sparse attention as fallback, (3) evaluate on your specific task before committing.

**Key Decision Points**:
- Comparison is structured by dimensions relevant to the deployment context (not just accuracy)
- Evolution logic explains WHY the field moved from attention to SSMs (quadratic complexity bottleneck)
- Open problems are genuine — not "needs more research" but specific unresolved technical challenges
- Recommendation is conditional — does not make a binding architectural decision

---

## Scenario 5: Citation Graph Analysis — Research Lineage Mapping

**Input**:
- Request: "梳理一下 Retrieval-Augmented Generation 这个方向的研究脉络，看看哪些工作是奠基性的，哪些是衍生工作"
- Context: team wants to understand which papers are truly foundational vs. incremental

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Citation network analysis:
  - Bridge papers (cited across multiple subfields):
    - Lewis et al. (2020) "Retrieval-Augmented Generation" — cited by QA, generation, and efficiency subfields
    - Karpukhin et al. (2020) "Dense Passage Retrieval" — cited by retrieval, QA, and open-domain QA
  - Niche papers (cited within narrow community only):
    - Domain-specific RAG variants (medical, legal) — high quality but limited cross-field influence
  - Orphan papers (cited but not built upon):
    - Several 2021-2022 papers proposing alternative retrieval architectures that were not adopted
- Intellectual debt tracing:
  ```
  BM25 (Robertson, 1994) — classical IR foundation
  └── Neural IR (2017-2019) — learned representations
      ├── DPR (Karpukhin et al., 2020) — dense retrieval
      │   ├── ANCE (Xiong et al., 2021) — adversarial training
      │   ├── Contriever (Izacard et al., 2022) — unsupervised pretraining
      │   └── Adaptive retrieval (2024) — conditional retrieval
      └── RAG (Lewis et al., 2020) — generator + retriever
          ├── FiD (Izacard & Grave, 2021) — fusion-in-decoder
          ├── REPLUG (Shi et al., 2023) — plug-and-play retrieval
          └── Iterative RAG (2023-2024) — multi-step reasoning
  ```
- Influence analysis:
  - DPR has 2000+ citations, built upon by 50+ subsequent methods
  - RAG framework has 3000+ citations, but many are "mentioning" rather than "building upon"
  - Key insight: DPR is more foundational than RAG — DPR changed how retrieval is done; RAG changed how generation uses retrieval
- Coverage limitations: citation counts as of Semantic Scholar 2026-04-20; does not include papers published after 2025-12
- Recommended next step: @architect — Use DPR and RAG as foundational references. For implementation, prioritize methods with >500 citations AND code availability. Avoid orphan methods (cited but not built upon) unless they specifically address your domain.

**Key Decision Points**:
- Distinguishes bridge papers from niche papers from orphan papers
- Intellectual debt tracing shows causal lineage, not just chronology
- Identifies DPR as more foundational than RAG — a non-obvious finding from citation context analysis
- Recommendation is actionable for architecture decisions
