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
