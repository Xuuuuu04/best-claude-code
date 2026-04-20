# 深度研究员 — Domain 3: Competitive Research and Gap Analysis

## 3.1 Competitive Research Methodology

### Technical Artifact Analysis

**Reverse Architecture Inference**:
- Read engineering blog posts for infrastructure choices
- Read job postings for technology stack signals
- Read open-source code for design patterns
- Analyze API documentation for capability boundaries

**Research Capability Mapping**:
- What does the company's published research tell us about technical depth?
- Is the research applied (evaluating existing techniques) or foundational (producing new capabilities)?
- Count of peer-reviewed papers vs. blog posts vs. patents

**Moat Analysis**:

Distinguish surface-level from structural advantages:

| Surface-Level Advantage | Structural Advantage |
|------------------------|---------------------|
| More features | Proprietary data at scale |
| Lower price | Network effects |
| Better marketing | Switching costs |
| Faster release cycle | Foundational IP (patents, trade secrets) |
| Larger team | Data flywheel (product usage improves product) |

**Moat Question**: What would a competitor need to replicate that is genuinely hard to replicate?

### Business Signal Analysis

**Growth Trajectory Signals**:
- GitHub star growth rate (accelerating? decelerating?)
- Funding rounds and investor quality
- Headcount growth curve from LinkedIn
- Developer community health (StackOverflow questions, GitHub issues, Discord activity)

**Positioning Thesis Extraction**:

From public materials, extract:
1. What specific customer problem are they claiming unique ability to solve?
2. Why do they claim uniqueness?
3. What does that uniqueness depend on?

**Example**:
```
LangChain positioning thesis:
- Problem: Building LLM applications requires too much boilerplate integration
- Uniqueness claim: 200+ integrations out of the box
- Dependency: Continuous engineering effort to maintain integrations
- Vulnerability: Provider consolidation reduces integration value
```

**Failure Case Research**:
- Public post-mortems
- User complaints that reveal systematic limitations
- Competitive transitions (customers who left publicly and said why)

## 3.2 Citation Graph Analysis

### Influence Mapping

Identify papers that are cited across multiple subfields (bridge papers) vs. papers cited only within a narrow niche.

**Bridge papers** often indicate foundational methodological contributions that enabled new research directions.

**Niche papers** may be technically sound but have limited influence.

### Citation Context Analysis

Not just counting citations — understanding WHAT the citing paper says:

| Citation Type | Meaning | Weight |
|---------------|---------|--------|
| Supportive | Citing paper builds on this work | High |
| Critical | Citing paper challenges this work | High (identifies limitations) |
| Extending | Citing paper improves this work | Medium |
| Mentioning | Citing paper references in passing | Low |

**Method**: Read the citation context in 3-5 citing papers to understand how the field interprets a work.

### Intellectual Debt Tracing

Map which methods build on which theoretical foundations:

```
Transformer (Vaswani et al., 2017)
├── BERT (Devlin et al., 2019) — bidirectional encoding
│   ├── RoBERTa — training optimization
│   └── ALBERT — parameter reduction
├── GPT (Radford et al., 2018) — autoregressive generation
│   ├── GPT-2 — scale
│   ├── GPT-3 — few-shot learning
│   └── GPT-4 — multimodal, RLHF
└── T5 (Raffel et al., 2020) — text-to-text framework
    └── BART — denoising autoencoder
```

**Orphan methods**: Papers that are cited but not built upon. Suggests limited influence or failed approach.

## 3.3 Research Gap Identification

### Methodological Gap Detection

Areas where existing methods fail on specific problem types but no new method has been proposed.

**Example**:
```
Gap: Long-document RAG
- Current methods chunk documents into fixed-size passages
- Chunking breaks cross-page dependencies and long-range coherence
- No widely-adopted method maintains document-level context in retrieval
- Promising but unverified: hierarchical retrieval, summary-then-retrieve
```

### Evaluation Gap Detection

Benchmarks that don't capture real-world deployment conditions:

**Example**:
```
Gap: Dynamic knowledge evaluation
- All major QA benchmarks use static corpora
- Production systems need hourly/daily index updates
- No benchmark evaluates retrieval quality during corpus updates
- Consequence: methods that work on static benchmarks may fail in production
```

### Theoretical Gap Detection

Assumptions that underpin current methods but lack formal justification:

**Example**:
```
Gap: Retrieval density assumption
- Dense retrieval assumes semantic similarity correlates with answer relevance
- No formal proof that this holds across domains
- Empirical evidence mixed: works well for Wikipedia, poorly for technical manuals
- Theoretical framework for when dense retrieval is appropriate: missing
```

### Gap Prioritization Framework

Not all gaps are equally important. Prioritize by:

1. **Impact**: How many practitioners does this gap affect?
2. **Tractability**: Is there a plausible approach to addressing it?
3. **Urgency**: Is the gap blocking current deployments?
4. **Novelty**: Has this gap been identified before?

```
Gap scoring matrix:
| Gap | Impact | Tractability | Urgency | Novelty | Score |
|-----|--------|--------------|---------|---------|-------|
| Long-document RAG | High | Medium | High | Medium | 3.25 |
| Dynamic knowledge eval | Medium | Low | Medium | High | 2.50 |
| Retrieval density theory | Low | Low | Low | High | 1.75 |
```
