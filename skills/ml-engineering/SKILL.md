---
name: ml-engineering
description: Full-chain machine learning engineering methodology for the Harness team. Covers data quality audit and leakage prevention, traditional ML (LightGBM/Optuna, ensemble, calibration), deep learning (PyTorch AMP, DDP, DeepSpeed ZeRO, FSDP), LLM fine-tuning (LoRA/QLoRA/SFT/DPO, dataset construction), evaluation (failure analysis >=20 examples, bootstrap CI, model cards), and inference deployment (vLLM, TGI, ONNX, TensorRT, FastAPI serving). Loaded by @ml-engineer via skills: frontmatter.
type: skill
---

# ML Engineering Skill

## 1. Data Engineering (ML-Specific)

**Data quality audit**: Null rate analysis, class distribution, label quality (Cohen's Kappa for multi-annotator), outlier detection, data drift monitoring.

**Leakage prevention**: GroupKFold for grouped data, time-series split for temporal data. Test set isolation protocol: split once at project start, evaluate once at the end.

**Augmentation**: Text (back-translation, paraphrase, synonym replacement); Vision (albumentations: geometric, photometric, mixing); Tabular (SMOTE, ADASYN, feature noise injection).

**Feature engineering**: Target encoding, feature crosses, embedding extraction, permutation importance, SHAP, RFE.

**Data versioning**: DVC (Git for data): init, add, push, pull, reproduce. SHA-256 content hashing for dataset integrity.

## 2. Traditional ML

**Gradient boosting**: LightGBM (leaf-wise growth, GOSS, EFB), XGBoost (regularized objective, column sampling), CatBoost (ordered boosting, native categorical handling).

**Hyperparameter optimization**: Optuna (TPE sampler, pruning, multi-objective), Ray Tune (distributed HPO, population-based training).

**Ensembles**: Stacking (meta-learner, base model diversity), Blending (hold-out validation set predictions).

**Calibration**: Platt scaling (sigmoid), Isotonic regression (non-parametric).

## 3. Deep Learning

**PyTorch training loop**: AMP (automatic mixed precision), gradient clipping, LR scheduling (cosine, warmup, plateau), checkpointing (save best, early stopping).

**Distributed training**: DDP (single-machine multi-GPU), DeepSpeed ZeRO (stage 1/2/3, CPU offload), FSDP (fully sharded data parallel).

**Debugging**: Gradient flow inspection (`torch.autograd.grad_fn`), loss curve analysis (overfit, underfit, instability).

## 4. LLM Fine-Tuning

**LoRA / QLoRA**: Rank (r), alpha (alpha), target module selection; 4-bit NF4 quantization, bitsandbytes integration; PEFT library: `get_peft_model`, `merge_and_unload`.

**SFT (Supervised Fine-Tuning)**: Instruction formats (Alpaca, ChatML, ShareGPT); TRL SFTTrainer (packing, data collator); tokenization (truncation, padding, attention mask).

**DPO (Direct Preference Optimization)**: Preference pair construction (chosen vs rejected); Beta tuning (0.1-0.5 range, dataset-dependent); Reference model (frozen vs LoRA-adapted).

**Dataset construction**: Quality filtering (perplexity, length, language detection); Deduplication (MinHash, exact match); Instruction template standardization.

## 5. Evaluation

**Metrics**: Classification (accuracy, precision, recall, F1, AUC-ROC); Text generation (ROUGE, BLEU, BERTScore); Ranking (NDCG, MRR, MAP).

**Statistical significance**: Bootstrap confidence intervals (10,000 samples, 95% CI); McNemar's test for paired comparison; Permutation test for small samples.

**Failure analysis**: At least 20 failure examples with error taxonomy (boundary, domain shift, label noise, model limitation). A score without failure analysis is not an evaluation.

**Model cards**: Intended use, limitations, out-of-distribution behavior, ethical considerations, bias assessment.

**LLM-as-Judge**: Calibration set, inter-rater agreement, explicit scoring rubric.

## 6. Inference Deployment

**vLLM**: PagedAttention, continuous batching, quantization (AWQ, GPTQ, FP8), OpenAI-compatible API server.

**TGI**: Tensor parallelism, token streaming, production serving with Docker.

**ONNX**: Export (opset selection, dynamic axes), quantization (dynamic/static INT8).

**TensorRT**: FP16/INT8 optimization, engine serialization, dynamic batch size.

**Serving infrastructure**: FastAPI wrapper, health checks, GPU memory monitoring, graceful shutdown, load balancing, auto-scaling.

**SLA measurements**: P50/P99 latency, max QPS, GPU memory footprint. "It should be fast" is not a deployment criterion.

## 7. Reproducibility Contract

Every training run must be reproducible from four components:
1. **Random seed**: set in all frameworks
2. **Config file**: YAML/JSON with all hyperparameters
3. **Data version**: DVC commit or SHA256
4. **Environment**: requirements.txt with exact versions (`==`, not `>=`)

## 8. Anti-Patterns

| Name | Symptom | Correction |
|------|---------|------------|
| **Complexity Shortcut** | Skipping baseline, jumping to complex model | Establish TF-IDF+LR / LightGBM / ResNet-50 baseline first |
| **Test Set Contamination** | Evaluating on test set during hyperparameter tuning | Tune on validation set; evaluate test set exactly once |
| **Metric Gaming** | Optimizing headline metric while ignoring subgroup performance | Report macro F1 and per-class F1 for all significant subgroups |
| **Leakage Drift** | Using t+1 features when predicting at time t | Strict temporal split, feature availability audit |
| **Serving Gap** | Different preprocessing between training and inference | Unit test inference preprocessing against training preprocessing |
| **No Reproducibility** | No fixed seed or non-deterministic operations | Seed + config + DVC + environment freeze |
