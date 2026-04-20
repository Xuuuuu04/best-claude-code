# 深度研究员 — Domain 1: Academic Search and Critical Reading

## 1.1 Search Strategy

### Four-Round Search Protocol

**Round 1 — Survey and Review Papers**
- Goal: Find the field's self-description
- Sources: Annual Review, Foundations and Trends, survey papers from top venues
- Output: Standard subfield taxonomy, accepted method families, community vocabulary
- Time allocation: 20% of total search time

**Round 2 — High-Citation Core Papers**
- Goal: Identify canonical methods every practitioner knows
- Criterion: ≥100 citations or recognized as foundational by survey papers
- Output: Landmark papers, baseline methods, key failure modes
- Time allocation: 35% of total search time

**Round 3 — Recent 2-Year Papers**
- Goal: Current state, new directions, emerging open problems
- Sources: arXiv, recent conference proceedings
- Output: SOTA numbers, new method variants, contested findings
- Time allocation: 25% of total search time

**Round 4 — Industrial Practice**
- Goal: Practitioner perspective on what works outside controlled conditions
- Sources: Engineering blogs, deployment case studies, PwC leaderboards
- Output: Production friction, cost realities, reliability data
- Time allocation: 20% of total search time

### arXiv Structured Search

```
Field queries:
  ti:"retrieval augmented generation"       # title contains exact phrase
  abs:"dense retrieval" AND abs:"QA"      # abstract contains both terms
  au:"Lewis" AND au:"Riedel"              # specific authors
  submittedDate:[20230101 TO 20241231]     # date range
  cat:cs.CL OR cat:cs.LG                   # category scope

Boolean construction:
  (ti:"RAG" OR ti:"retrieval augmented") AND abs:"knowledge" ANDNOT abs:"image"
```

### Citation Network Navigation

**Backward citation chasing**: Read what a paper cites to understand its intellectual foundations.

**Forward citation chasing**: Find papers that cite a core work to track its influence and identify critiques or extensions.

**Semantic Scholar "highly influential citations"**: Papers that cite AND build on a work (not just mention it).

**Citation context**: What does the citing paper say about the cited work? Supportive? Critical? Extending? Merely mentioning?

## 1.2 Critical Reading

### Baseline Selection Auditing

The most common form of misleading experimental design is cherry-picked baselines.

**Questions to ask**:
- Were the baselines given the same hyperparameter tuning budget as the proposed method?
- Are the baselines the actual best-performing prior work, or weaker versions?
- Did the authors exclude a well-known baseline without justification?

**Red flags**:
- Baseline is from 3+ years ago when newer methods exist
- Baseline uses default hyperparameters while proposed method uses tuned ones
- Baseline is evaluated on a different dataset split

### Dataset Scope Limitations

**Questions to ask**:
- Is the evaluation dataset representative of the deployment environment?
- Has the benchmark been over-fit to (benchmark saturation)?
- Are there known distribution shift issues between benchmark and real data?

**Red flags**:
- Single dataset evaluation for a general method
- Dataset created by the same authors as the method
- No evaluation on out-of-domain data

### Reproducibility Assessment

**Checklist**:
- [ ] Code released? Is it the same code used for experiments?
- [ ] Random seeds fixed?
- [ ] Hyperparameters documented?
- [ ] Papers With Code shows independent replications?
- [ ] Dataset publicly available?

**Reproducibility scoring**:
- Full: Code + data + seeds + hyperparameters all available
- Partial: Code available but missing seeds or hyperparameters
- None: No code or insufficient documentation

## 1.3 Source Credibility System (A–E)

### A-Level Sources

- Top-venue peer-reviewed papers (NeurIPS, ICML, ICLR, ACL, CVPR, ICCV, ECCV)
- Official primary technical documents (government policy text, official standards)
- Official company technical reports from named credible authors

**Usage**: Can support established consensus claims.

### B-Level Sources

- Peer-reviewed journal papers
- Well-regarded preprints (≥100 citations, no major retractions)
- Major company technical reports (Google Research, Meta AI, DeepMind, Microsoft Research)
- Recognized industry technical blogs (research.google.com, ai.meta.com)

**Usage**: Can support findings, but flag if single-source.

### C-Level Sources

- arXiv preprints (<100 citations)
- Conference workshop papers
- Recognized practitioner blogs

**Usage**: Use as leads or for emerging directions. Flag as pending verification.

### D-Level Sources

- Personal blog posts
- Developer forums
- Secondary news coverage

**Usage**: Use as leads only. Never cite as primary evidence.

### E-Level Sources

- AI-generated content
- Social media posts
- Anonymous sources

**Usage**: Never cite as research basis. May be used as search leads only.

### Credibility Labeling in Reports

```
"Dense retrieval consistently outperforms sparse retrieval on open-domain QA benchmarks 
[Lewis et al., 2020 A; Karpukhin et al., 2020 A]."

"Recent results suggest adaptive retrieval reduces latency by 30% [Smith et al., 2025 C], 
but this finding comes from a single preprint and has not been independently replicated 
[as of 2026-04-20]."

"[SINGLE SOURCE, PENDING VERIFICATION] — one arXiv preprint [Jones et al., 2025 C] 
claims state space models outperform Transformers on long-context tasks."
```
