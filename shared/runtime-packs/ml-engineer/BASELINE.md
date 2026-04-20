# ML Engineer — Baseline Scenarios

## Scenario 1: Text Classification with Baseline-First (Canonical)

**Input**:
- Task: 工单分类 (ticket classification), 12 categories
- Data: 50,000 labeled tickets
- Acceptance: Macro F1 ≥ 0.85
- Constraint: P99 inference < 200ms on CPU

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Baseline: TF-IDF + LogisticRegression → Macro F1: 0.76
- Baseline failure analysis: 25 examples, taxonomy: boundary (40%), label noise (25%), rare class (35%)
- Candidate 1: Fine-tuned BERT-base-chinese → Macro F1: 0.88 (beats threshold)
- Final evaluation: 0.88 F1 (95% CI: [0.86, 0.90]) on test set (evaluated once)
- ONNX export: 34ms P99 on CPU (INT8 quantization)
- Reproducibility: seed=42, config=config/clf_v1.yaml, data=sha256:abc123, env=requirements.txt

**Key Decision Points**:
- Baseline mandatory before fine-tuning, even if user suggests skipping
- CPU inference requirement: ruled out GPU-only models (vLLM)
- INT8 quantization acceptable: 0.87 vs 0.88 F1 trade-off documented

---

## Scenario 2: LLM QLoRA Fine-Tuning (Complex)

**Input**:
- Base model: Qwen3-7B
- Task: Customer service response generation
- Data: 10,000 high-quality QA pairs
- Hardware: 1× A100 80GB

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Training config: QLoRA r=16 α=32, lr=2e-4, 3 epochs, batch=16 (4×4 gradient accumulation)
- GPU memory: 42GB peak (8GB for base model in 4-bit + 15GB for LoRA activations + 19GB gradient/optimizer)
- Training time: ~4 hours on A100
- Evaluation: ROUGE-L 0.42, BERTScore-F1 0.87, LLM-as-Judge (GPT-4o) 4.2/5.0
- Failure analysis: 20 examples — tone inconsistency (40%), factual hallucination (30%), OOD queries (30%)
- Model limitations: unreliable on technical product queries outside training domain
- Reproducibility: all 4 components documented

**Key Decision Points**:
- QLoRA vs. full fine-tuning: QLoRA chosen for memory efficiency; performance parity confirmed in ablation
- LLM-as-Judge calibration: 50 human-judged examples as calibration set, inter-rater κ=0.82

---

## Scenario 3: Missing Acceptance Criterion (Blocked)

**Input**:
- Task: "Build a classifier to predict customer churn"
- No acceptance criterion specified
- No test data format provided
- Data available: 6 months of customer activity logs

**Expected Output Structure**:
- Status: BLOCKED
- Blocked on: Numeric acceptance criterion not defined
- Blocked by: User / @pm / business stakeholder
- Rationale: Without an acceptance criterion (e.g., "Recall ≥ 0.80 with Precision ≥ 0.60"),
  there is no basis for model selection, no stopping condition for iteration,
  and no criteria for the @test-lead verdict. Building a classifier toward an
  unknown standard guarantees rework.
- What I need:
  1. Primary metric + threshold (e.g., Recall ≥ 0.80)
  2. Secondary constraints (e.g., Precision ≥ 0.60 to limit false positive interventions)
  3. Inference latency requirement (batch scoring overnight vs. real-time API)
  4. Definition of "churned": 30-day inactive? Cancelled subscription?

**Key Decision Points**:
- BLOCK is not rejection — it is a prerequisite for productive work
- Specific missing items named, not generic "need more information"
- Each missing item tied to a downstream consequence (model selection, stopping condition, test verdict)
