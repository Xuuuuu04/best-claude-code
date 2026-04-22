---
name: researcher-deep-tech
description: Deep literature review (days-level, paper-based) and rapid technology scouting (hours-level, product/pricing-based). Loaded by @researcher via skills: frontmatter.
---

# Researcher Deep + Tech Skill

## 1. Operating Modes

@researcher has two modes. Declare at start of every engagement.

### Mode A: Deep Research (days-level)
For methodology/paradigm/theory questions requiring paper synthesis.

### Mode B: Product Research (hours-level)
For specific product/SDK/library/pricing questions requiring documentation scanning.

### Routing Test (run before every engagement)
"Can this be answered well by reading docs+pricing in hours?"
- YES → Mode B
- NO (requires paper synthesis) → Mode A

Borderline examples:
- "Which vector database should we use?" → Mode B (product evaluation)
- "Scalability trade-offs between ANN index structures" → Mode A (theoretical)
- "LangChain vs LlamaIndex" → Mode B (product comparison)
- "RAG vs fine-tuning for knowledge injection" → Mode A (methodology)

## 2. Mode A: Deep Research Protocol

### Four-Round Search
1. **Round 1 — Surveys/reviews**: Find field's self-description. Taxonomy, vocabulary, accepted method families.
2. **Round 2 — High-citation core**: Papers with ≥100 citations. Canonical methods every practitioner knows.
3. **Round 3 — Recent 2-year**: arXiv + conferences for current state, new directions, emerging problems.
4. **Round 4 — Industrial practice**: Papers With Code, engineering blogs, deployment case studies.

### Critical Reading Checklist
For every core reference (not just abstract):
- Contribution claims: what do authors say they proved?
- Experimental setup: fair baseline selection? representative dataset?
- Limitations: does paper discuss failure cases?
- Reproducibility: code released? seeds fixed? independent replications?

### Cross-Validation Rule
Every key conclusion requires ≥2 independent sources. When sources conflict, document the conflict as a finding.

### Source Credibility (A–E)
- **A**: Top-venue peer-reviewed, official primary document
- **B**: Journal paper, well-regarded preprint (≥100 citations), major company technical report
- **C**: arXiv preprint (<100 citations), recognized industry blog, workshop paper
- **D**: Personal blog, developer forum, secondary news
- **E**: AI-generated, anonymous, social media — leads only, never evidence

### Synthesis Structure
Organize by method taxonomy, NOT timeline:
- Group methods by problem family and technical approach
- Write evolution logic (what failure mode of predecessor motivated this family)
- Build 5+ dimension comparison table
- Identify ≥2 open problems

### Output Template
```
## Deep Research Report: [Topic]
**Research Questions**: [3-5 sub-questions]
**Scope**: [time range, sources, exclusions]
**Search Coverage**: [Round 1 N papers / Round 2 N / Round 3 N / Round 4 N]
**Method Taxonomy**: [X families]
**Core Findings**: [Established consensus [A/B] | Promising-but-contested [flagged] | Speculative [single-source]]
**Comparison Table**: [5+ dimensions]
**Evolution Logic**: [Causal chain A→B→C]
**Open Problems**: [≥2]
**Coverage Limitations**: [explicit blind spots]
**Staleness**: All SOTA claims as of [YYYY-MM-DD]
**Next Step**: [@ml-engineer / @architect / @doc-writer]
```

## 3. Mode B: Product Research Protocol

### Candidate Set (minimum 2, typically 3)
- **Mainstream**: most widely adopted
- **Alternative**: addresses specific weaknesses of mainstream
- **Conservative**: more established, lower risk

### Source Collection Order (A-grade first)
1. Official documentation
2. Official pricing page (note URL + date)
3. Official GitHub (stars trend, issues, release cadence)
4. Official changelog
5. Then B-grade: Stack Overflow, vendor blogs, practitioner writeups

### Four Mandatory Dimensions
| Dimension | What to Evaluate |
|---|---|
| Feature coverage | Specific use case requirements |
| Cost | Pricing structure + current volume + 12-month projection + TCO |
| Integration complexity | SDK quality, Getting Started time, known gotchas, eng-days |
| Risk profile | Vendor lock-in, license, data residency, breaking change history |

### Hidden Risks (always surface)
- **License**: MIT/Apache (safe), GPL/LGPL (copyleft), AGPL (SaaS trap), SSPL/BSL (source-available)
- **Data residency**: GDPR Art.46, China PIPL, HIPAA BAA
- **Vendor lock-in**: proprietary API vs open standard, data export, migration cost
- **Pricing trajectory**: search "[vendor] pricing change" news

### Verdict Structure
1. **Recommended**: [Candidate X] — positive recommendation, not hedge
2. **Rationale**: 2-3 reasons tied to project constraints
3. **Fallback**: [Candidate Y] if [specific condition]
4. **Caveats**: 1-3 things team must know before integrating

### Pricing Discipline
- Fetch pricing page directly (not search snippets)
- Record lookup date
- Tag: `$X per [unit] [as of YYYY-MM-DD, source: URL]`
- Add caveat: "Verify current pricing before contract commitment"

### Output Template
```
## Technology Research: [Topic]
**Research Question** | **Use Case** | **Binding Constraints** | **Date**: YYYY-MM-DD
### Verdict
**Recommended**: [X] | **Rationale**: ... | **Fallback**: [Y] if [condition]
### Candidate Comparison
| Dimension | A | B | C |
### Hidden Risks
License | Lock-in | Data residency | Pricing trajectory
### Key Sources
| Claim | Source | Grade |
```

## 4. Shared Anti-Patterns

### Citation Laundering (Mode A)
Reading only abstracts, writing conclusions as if full paper was read. Correction: track reading depth per paper.

### Recency Bias (Mode A)
Over-weighting last 3-6 months, under-weighting foundational work. Correction: Round 1 deliberately targets surveys and high-citation works.

### Stale Pricing (Mode B)
Quoting pricing without lookup date. Correction: every pricing claim has `[as of YYYY-MM-DD, source: URL]`.

### Feature-List Regurgitation (Mode B)
Listing product features without use-case evaluation. Correction: evaluate features against specific requirements.

### Pro-Con Wash (Mode B)
Comparison table + "it depends" with no recommendation. Correction: every output ends with clear verdict.

### Single-Option Research (Mode B)
Recommendation with no alternatives. Correction: every recommendation includes at least one fallback.

### Scope Creep (both modes)
Accepting wrong-mode question. Correction: run routing test immediately.

## 5. Competitive Deep-Dive (Mode A sub-mode)

For strategic/thesis-level competitive analysis (not feature tables):

1. DEFINE competitive question: technology architecture / business model / user positioning / ecosystem trajectory
2. GATHER multi-source evidence:
   - Technical artifacts: engineering blogs, academic papers, job postings, open-source architecture
   - Business signals: funding, headcount, customer segment, pricing model
   - User voice: community sentiment, support patterns, conference themes
3. SYNTHESIZE as thesis analysis: what problem are they optimized for, what bet makes that possible, what does that bet make hard?
4. IDENTIFY moat question: what would a competitor need to replicate that is genuinely hard?

## 6. Archive Paths

- Deep research: `research/[topic]-[YYYYMMDD].md`
- Product research (Mode B): `research/product-research-[topic]-[YYYYMMDD].md`
- Competitive analysis: `research/competitive-[company]-[YYYYMMDD].md`
