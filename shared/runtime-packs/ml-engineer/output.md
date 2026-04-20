# ML Engineer — Output Contract

## Standard Output Template

```
## ML Engineering Output

**Task ID**: [ID] | **Type**: [Training/Fine-Tuning/Evaluation/Deployment]
**Status**: READY-FOR-NEXT | BLOCKED | FAILED

**Business Objective**: [one sentence]
**Acceptance Criterion**: [specific numeric threshold]

**Baseline**: [model + metric]
**Final**: [model + metric + relative improvement %]

**Evaluation**:
- Primary metric: [value] (95% CI: [lower, upper])
- Test set evaluated: [date — once only]
- Failure analysis: [N examples] → Error taxonomy: [Type A: N cases | Type B: N cases]
- Limitations: [2+ conditions]

**Reproducibility**:
- Seed: [value]
- Config: [path]
- Data: [SHA256/DVC ref]
- Environment: [requirements.txt path]

**Inference** (deployment only):
- P50: [ms] | P99: [ms]
- QPS: [N]
- GPU memory: [GB]
- SLA: [PASS/FAIL]

**Recommended Next Step**: @[agent] — [one sentence]
```

## Filled Example — Text Classification

```
## ML Engineering Output

**Task ID**: T-042 | **Type**: Training
**Status**: READY-FOR-NEXT

**Business Objective**: Classify customer support tickets into 12 categories for routing
**Acceptance Criterion**: Macro F1 >= 0.85, P99 inference < 200ms on CPU

**Baseline**: TF-IDF + LogisticRegression → Macro F1: 0.76
**Final**: Fine-tuned BERT-base-chinese → Macro F1: 0.88 (+15.8% vs baseline)

**Evaluation**:
- Primary metric: 0.88 (95% CI: [0.86, 0.90])
- Test set evaluated: 2026-04-21 (once only)
- Failure analysis: 25 examples → Error taxonomy:
  - Boundary cases (near decision threshold): 10 cases (40%)
  - Label noise (ambiguous ground truth): 6 cases (24%)
  - Rare class confusion (categories with < 100 training examples): 5 cases (20%)
  - Domain shift (technical jargon not in training): 4 cases (16%)
- Limitations:
  1. Unreliable on tickets with mixed-language content (Chinese + English technical terms)
  2. Performance degrades on tickets longer than 512 tokens (truncation loses context)

**Reproducibility**:
- Seed: 42
- Config: configs/ticket_clf_v1.yaml
- Data: dvc://datasets/tickets/v1.2.0 (sha256:abc123def456)
- Environment: requirements.txt (torch==2.1.0, transformers==4.35.0)

**Inference**:
- P50: 45ms | P99: 180ms
- QPS: 120
- GPU memory: N/A (CPU inference via ONNX INT8)
- SLA: PASS (P99 < 200ms)

**Recommended Next Step**: @code-review — audit training code for data leakage and preprocessing consistency
```

## Filled Example — LLM Fine-Tuning (QLoRA)

```
## ML Engineering Output

**Task ID**: T-055 | **Type**: Fine-Tuning
**Status**: READY-FOR-NEXT

**Business Objective**: Fine-tune Qwen3-7B for customer service response generation
**Acceptance Criterion**: ROUGE-L >= 0.40, BERTScore-F1 >= 0.85, LLM-as-Judge >= 4.0/5.0

**Baseline**: Zero-shot Qwen3-7B-Instruct → ROUGE-L: 0.28, BERTScore: 0.72
**Final**: QLoRA fine-tuned Qwen3-7B → ROUGE-L: 0.42 (+50%), BERTScore: 0.87 (+20.8%)

**Evaluation**:
- Primary metrics:
  - ROUGE-L: 0.42 (95% CI: [0.40, 0.44])
  - BERTScore-F1: 0.87 (95% CI: [0.86, 0.88])
  - LLM-as-Judge (GPT-4o): 4.2/5.0 (inter-rater kappa: 0.82)
- Test set evaluated: 2026-04-20 (once only)
- Failure analysis: 20 examples → Error taxonomy:
  - Tone inconsistency (too formal for casual queries): 8 cases (40%)
  - Factual hallucination (product specs not in training): 6 cases (30%)
  - Out-of-domain queries (technical troubleshooting): 4 cases (20%)
  - Overly verbose responses: 2 cases (10%)
- Limitations:
  1. Unreliable on technical product queries outside training domain
  2. May generate outdated product information (training data cutoff: 2025-12)
  3. Struggles with multi-turn context beyond 3 exchanges

**Reproducibility**:
- Seed: 42
- Config: configs/qwen3_7b_qlora_v2.yaml
- Data: dvc://datasets/cs_qa/v2.1.0 (sha256:def789abc012)
- Environment: requirements.txt (torch==2.1.0, transformers==4.35.0, peft==0.7.0, trl==0.8.0)

**Training Details**:
- Method: QLoRA (r=16, alpha=32, target_modules=all linear)
- GPU: 1x A100 80GB
- Peak memory: 42GB
- Training time: ~4 hours
- Effective batch size: 16 (4 per device x 4 gradient accumulation)

**Recommended Next Step**: @ml-engineer (self) — deploy via vLLM with AWQ quantization for production serving, or @devops for GPU infrastructure provisioning
```

## Filled Example — Inference Deployment (vLLM)

```
## ML Engineering Output

**Task ID**: T-060 | **Type**: Deployment
**Status**: READY-FOR-NEXT

**Business Objective**: Deploy fine-tuned Qwen3-7B for production customer service API
**Acceptance Criterion**: P99 < 500ms, QPS >= 50, GPU memory < 48GB

**Baseline**: N/A (deployment task)
**Final**: vLLM serving with AWQ 4-bit quantization

**Evaluation**:
- Primary metric: N/A (deployment task)
- Test set evaluated: N/A

**Inference**:
- P50: 120ms | P99: 420ms
- QPS: 65 (sustained), 80 (burst)
- GPU memory: 38GB peak
- SLA: PASS (all metrics within threshold)

**Deployment Configuration**:
- Framework: vLLM 0.4.0
- Model: Qwen/Qwen3-7B-Instruct (AWQ 4-bit)
- Tensor parallel: 1
- GPU memory utilization: 0.85
- Max model length: 4096
- Quantization: AWQ
- Batch size: dynamic (continuous batching)

**Reproducibility**:
- Config: configs/vllm_serve.yaml
- Environment: requirements.txt (vllm==0.4.0, fastapi==0.109.0)
- Docker image: ml-serve:v1.2.0

**Health Checks**:
- /health: liveness probe (200 OK)
- /ready: readiness probe (model loaded, GPU available)
- /metrics: Prometheus metrics (latency, QPS, GPU utilization)

**Recommended Next Step**: @backend — integrate vLLM endpoint into product API gateway with rate limiting and fallback
```

## BLOCKED Output Template

```
## ML Engineering Output

**Task ID**: [ID] | **Type**: [Training/Fine-Tuning/Evaluation/Deployment]
**Status**: BLOCKED

**Business Objective**: [one sentence]
**Acceptance Criterion**: [specific numeric threshold]

**Blocked On**: [specific missing item]
**Blocked By**: [who can unblock]

**Rationale**: [why this blocks implementation]

**What I Need**:
1. [specific item 1]
2. [specific item 2]
3. [specific item 3]

**Recommended Next Step**: @[agent] — [one sentence]
```

## Filled Example — BLOCKED (Missing Acceptance Criterion)

```
## ML Engineering Output

**Task ID**: T-058 | **Type**: Training
**Status**: BLOCKED

**Business Objective**: Build a classifier to predict customer churn
**Acceptance Criterion**: NOT DEFINED

**Blocked On**: Numeric acceptance criterion not defined
**Blocked By**: User / @pm / business stakeholder

**Rationale**: Without an acceptance criterion (e.g., "Recall >= 0.80 with Precision >= 0.60"),
there is no basis for model selection, no stopping condition for iteration,
and no criteria for the @test-lead verdict. Building a classifier toward an
unknown standard guarantees rework.

**What I Need**:
1. Primary metric + threshold (e.g., Recall >= 0.80)
2. Secondary constraints (e.g., Precision >= 0.60 to limit false positive interventions)
3. Inference latency requirement (batch scoring overnight vs. real-time API)
4. Definition of "churned": 30-day inactive? Cancelled subscription?

**Recommended Next Step**: @pm — define acceptance criteria before model development begins
```
