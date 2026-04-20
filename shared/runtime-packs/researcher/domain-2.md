# 深度研究员 — Domain 2: Synthesis and Framework Construction

## 2.1 Method Taxonomy Design

### Subfield Partitioning

Identify the research community's accepted subfield divisions (not invented by the researcher):

**Principles**:
- Distinguish genuinely orthogonal research directions from renamings of the same problem
- Follow the taxonomy used by survey papers in the field
- Note when different communities use different terms for the same concept

**Example — RAG Taxonomy**:
```
Retrieval-Augmented Generation
├── By retrieval mechanism
│   ├── Sparse retrieval (BM25, TF-IDF)
│   ├── Dense retrieval (DPR, ANCE, Contriever)
│   └── Hybrid retrieval (sparse + dense fusion)
├── By generation strategy
│   ├── Single-step (retrieve once, generate)
│   ├── Iterative (retrieve → generate → retrieve → ...)
│   └── Adaptive (retrieve only when needed)
└── By knowledge source
    ├── Static corpus (Wikipedia, pre-built KB)
    ├── Dynamic corpus (search engine, real-time data)
    └── Structured (knowledge graphs, databases)
```

### Technical Route Classification

Classify methods by their fundamental technical approach:

| Dimension | Categories | Decision Relevance |
|-----------|-----------|-------------------|
| Parametric vs. Non-parametric | Fine-tuning vs. retrieval | Knowledge update frequency |
| Discriminative vs. Generative | Classifier vs. language model | Output type needed |
| End-to-end vs. Pipeline | Joint training vs. modular | Debuggability, maintenance |
| Supervised vs. Self-supervised | Labeled data vs. unlabeled | Data availability |
| Deterministic vs. Stochastic | Rule-based vs. sampling | Reproducibility requirements |

### Evolution Logic Writing

The key discipline: not "method A was published in 2019, method B in 2022" but:

```
Method A had failure mode X on problem type Y (with evidence).
This motivated Method B's design decision Z.
Method B solved X but introduced new limitation W.
Method C addresses W by design decision V.
```

**Example**:
```
Sparse retrieval (BM25) failed on semantic matching — "king" and "monarch" 
are treated as unrelated. This motivated dense retrieval (DPR, 2020), which 
learns semantic representations. DPR solved semantic matching but introduced 
distribution shift — embeddings trained on Wikipedia underperform on medical 
text. This motivated domain-adaptive dense retrieval (ADAPT-RETRIEVE, 2022) 
and hybrid approaches that combine sparse and dense signals.
```

## 2.2 Structured Comparison Output

### Comparison Table Design

Select 5+ dimensions for decision relevance:

| Dimension | What to Measure | Why It Matters |
|-----------|----------------|----------------|
| Performance profile | Accuracy/F1 on specific benchmarks | Does it solve YOUR problem? |
| Compute cost | Training FLOPs, inference latency | Can you afford to run it? |
| Data requirements | Quantity, quality, annotation needs | Do you have the data? |
| Theoretical assumptions | IID, smoothness, convexity | Do assumptions hold in your domain? |
| Known failure modes | Distribution shift, adversarial, edge cases | What will break in production? |
| Production friction | Deployment complexity, monitoring, debugging | Can your team operate it? |

**Example Comparison Table**:
```
| Method | NQ EM | Latency | Data needed | Failure mode | Production friction |
|--------|-------|---------|-------------|--------------|---------------------|
| BM25 + BERT | 32.1 | 50ms | Large corpus | Vocabulary mismatch | Low |
| DPR + BART | 41.5 | 120ms | Corpus + QA pairs | Distribution shift | Medium |
| Hybrid | 42.1 | 200ms | Both above | Latency spikes | High |
| Iterative RAG | 48.2 | 450ms | Corpus + reasoning | Error propagation | Very high |
```

### Open Problems Identification

For each identified open problem, state:

1. **What the current best methods fail to do**
2. **Why the failure is fundamental** (not just "more data/compute needed")
3. **What a solution would look like**
4. **Whether there is promising recent work**

**Example**:
```
Open Problem: Multi-hop error propagation

1. Current best (Self-RAG) achieves 48.2% on HotpotQA but drops to 31% on 
   questions requiring >3 hops. Iterative retrieval compounds errors at each step.

2. Fundamental: each retrieval step is conditionally independent in current 
   architectures. There's no mechanism to backtrack or verify intermediate results.

3. A solution would require: (a) explicit reasoning state tracking, 
   (b) backtracking capability, (c) confidence calibration for each hop.

4. Promising work: Corrective RAG (2024) uses reflection but adds 3× latency. 
   Tree-of-Thoughts (2023) explores multiple paths but not integrated with retrieval.
```

### Industrial vs. Academic Perspective Reconciliation

Academic papers evaluate under controlled conditions. Industrial deployments face:

| Factor | Academic | Industrial |
|--------|----------|------------|
| Data | Clean, curated benchmarks | Messy, shifting, incomplete |
| Distribution | IID test set | Constant distribution shift |
| Latency | Not a primary concern | P95 < 200ms often required |
| Cost | Unlimited compute for paper | Budget-constrained |
| Reliability | Single-run evaluation | 99.9% uptime required |
| Maintenance | One-time experiment | Continuous monitoring, updates |

**Synthesis requirement**: For every method, explicitly state the gap between academic claims and industrial reality.

## 2.3 Domain-Specific Knowledge

### AI/ML Field Structure

Understand distinct research communities:

| Community | Dominant Venues | Key Researchers | Evaluation Norms |
|-----------|----------------|-----------------|------------------|
| ML Theory | COLT, ALT | Various | PAC bounds, regret analysis |
| Deep Learning Systems | MLSys, OSDI | Various | Throughput, memory, scalability |
| NLP | ACL, EMNLP, NAACL | Various | BLEU, ROUGE, human eval |
| Vision | CVPR, ICCV, ECCV | Various | mAP, FID, human preference |
| Multimodal | NeurIPS, ICML | Various | Cross-modal retrieval, generation |
| RL | ICML, NeurIPS, ICLR | Various | Cumulative reward, sample efficiency |

### Industry Research Ecosystem

Distinguish reliability profiles:

| Source Type | Reliability | Latency | Use Case |
|-------------|-------------|---------|----------|
| Top AI lab research blog | High | Months before paper | Early signals, implementation details |
| University lab preprint | Medium | Immediate | Novel methods, unverified claims |
| Startup technical blog | Variable | Immediate | Product-specific insights |
| Conference proceedings | High | 6-12 months delay | Verified, peer-reviewed results |

### Regulatory and Standards Research

Primary document retrieval:

| Regulation | Source | Key Articles |
|------------|--------|--------------|
| EU AI Act | EUR-Lex | Art. 6 (classification), Art. 9 (risk management), Art. 13 (transparency) |
| GDPR | Official Journal of the EU | Art. 5 (principles), Art. 25 (PbD), Art. 32 (security) |
| NIST AI RMF | NIST website | Govern, Map, Measure, Manage functions |
| ISO/IEC 42001 | ISO website | AI management system requirements |

**Rule**: Always read the primary document, not media summaries. Flag legal interpretations as [PENDING LEGAL VERIFICATION].
