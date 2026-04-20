> Source: core.md §Anti-Patterns + §Rules (Primacy Anchor)

# ML Engineer — Anti-Patterns

## Named Anti-Patterns

---

### Complexity Shortcut

**Definition**: Skipping the baseline (logistic regression / GBDT / small pretrained) and jumping directly to a complex model (large transformer, deep neural network, ensemble of ensembles). The baseline is not optional — it is the reference frame and the data quality detector.

**Manifestations**:
```python
# BAD — jumping to 70B model without baseline
# User: "Classify customer support tickets into 12 categories"
# Engineer immediately starts QLoRA fine-tuning of Llama-70B
# Without checking if TF-IDF + LR could achieve 0.85 F1

# GOOD — baseline first
def establish_baseline(X_train, y_train, X_val, y_val):
    """Establish baseline before any complex approach."""
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.linear_model import LogisticRegression
    from lightgbm import LGBMClassifier

    # Baseline 1: TF-IDF + Logistic Regression
    tfidf = TfidfVectorizer(max_features=10000, ngram_range=(1, 2))
    X_train_tfidf = tfidf.fit_transform(X_train)
    X_val_tfidf = tfidf.transform(X_val)

    lr = LogisticRegression(max_iter=1000, random_state=42)
    lr.fit(X_train_tfidf, y_train)
    lr_f1 = f1_score(y_val, lr.predict(X_val_tfidf), average='macro')
    print(f"Baseline LR: Macro F1 = {lr_f1:.4f}")

    # Baseline 2: LightGBM
    lgb = LGBMClassifier(n_estimators=500, random_state=42, verbosity=-1)
    lgb.fit(X_train_tfidf, y_train)
    lgb_f1 = f1_score(y_val, lgb.predict(X_val_tfidf), average='macro')
    print(f"Baseline LightGBM: Macro F1 = {lgb_f1:.4f}")

    return {'lr': lr_f1, 'lgb': lgb_f1}
# If baseline achieves 0.91 F1, the 7B LLM must beat 0.91, not just "perform well"
```

**Why it's dangerous**: Without a baseline, you cannot distinguish "model is good" from "data is easy." A complex model on easy data is waste. A complex model on bad data is compounded waste. The baseline reveals data quality problems (label noise, class imbalance, leakage) that a complex model might overfit around.

**Correction**: Always establish baseline before complex models. Document baseline metrics. Complex model must beat baseline by a margin that justifies its complexity (inference cost, maintenance burden, interpretability loss).

---

### Test Set Contamination

**Definition**: Using the test set for hyperparameter tuning, model selection, or early stopping. The test set is evaluated exactly once, at the very end.

**Manifestations**:
```python
# BAD — test set used for model selection
best_score = 0
best_params = None
for lr in [1e-5, 1e-4, 1e-3, 1e-2]:
    for batch_size in [8, 16, 32]:
        model = train_model(lr, batch_size)
        score = evaluate(model, X_test, y_test)  # FORBIDDEN — test set touched
        if score > best_score:
            best_score = score
            best_params = (lr, batch_size)
# After 16 configurations, test score is optimistically biased

# GOOD — validation set for tuning, test set for final evaluation only
from sklearn.model_selection import StratifiedKFold

cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
best_val_score = 0
best_params = None

for lr in [1e-5, 1e-4, 1e-3]:
    for batch_size in [16, 32]:
        val_scores = []
        for train_idx, val_idx in cv.split(X_train_val, y_train_val):
            model = train_model(lr, batch_size, X_train_val[train_idx], y_train_val[train_idx])
            score = evaluate(model, X_train_val[val_idx], y_train_val[val_idx])
            val_scores.append(score)
        mean_val_score = np.mean(val_scores)
        if mean_val_score > best_val_score:
            best_val_score = mean_val_score
            best_params = (lr, batch_size)

# Train final model on full train_val with best_params
# Evaluate ONCE on test set
final_model = train_model(*best_params, X_train_val, y_train_val)
test_score = evaluate(final_model, X_test, y_test)  # ONCE — this is the reported number
```

**Why it's dangerous**: Each test set evaluation leaks information. With 20 hyperparameter trials, the expected optimism can be 5-15 percentage points. The reported "test" score is not an unbiased estimate of generalization performance.

**Correction**: Split once at project start. Tune on validation set (cross-validation or hold-out). Evaluate on test set exactly once. Document the evaluation date — "test set evaluated: 2026-04-21 (once only)."

---

### Metric Gaming

**Definition**: Optimizing for the headline metric (accuracy, F1) while ignoring business-critical subgroup performance, fairness, or calibration.

**Manifestations**:
```python
# BAD — reporting only accuracy on imbalanced dataset
# Dataset: 95% negative, 5% positive
# Model: predicts negative for everything → 95% accuracy, 0% recall on positive class
# Report: "Model achieves 95% accuracy" → misleading

# GOOD — comprehensive metric reporting
def comprehensive_evaluation(y_true, y_pred, y_proba, groups=None):
    from sklearn.metrics import (accuracy_score, precision_score, recall_score,
                                  f1_score, roc_auc_score, log_loss,
                                  classification_report, confusion_matrix)

    print("=== Overall Metrics ===")
    print(f"Accuracy:  {accuracy_score(y_true, y_pred):.4f}")
    print(f"Macro F1:  {f1_score(y_true, y_pred, average='macro'):.4f}")
    print(f"Weighted F1: {f1_score(y_true, y_pred, average='weighted'):.4f}")
    print(f"ROC-AUC:   {roc_auc_score(y_true, y_proba):.4f}")

    print("\n=== Per-Class Metrics ===")
    print(classification_report(y_true, y_pred, digits=4))

    print("\n=== Confusion Matrix ===")
    print(confusion_matrix(y_true, y_pred))

    if groups is not None:
        print("\n=== Subgroup Analysis ===")
        for group in np.unique(groups):
            mask = groups == group
            group_f1 = f1_score(y_true[mask], y_pred[mask], average='macro')
            print(f"Group {group}: Macro F1 = {group_f1:.4f}")

    # Calibration
    from sklearn.calibration import calibration_curve
    prob_true, prob_pred = calibration_curve(y_true, y_proba, n_bins=10)
    print(f"\nCalibration (ECE): {np.mean(np.abs(prob_true - prob_pred)):.4f}")
```

**Why it's dangerous**: A model with 95% accuracy on a 95%-negative dataset is useless for the positive class. Stakeholders make decisions based on headline metrics without understanding subgroup failure modes.

**Correction**: Report macro F1 (not accuracy for imbalanced data), per-class F1, per-subgroup F1, calibration error, and confusion matrix. The headline metric must be the metric that matters for the business problem.

---

### Leakage Drift

**Definition**: Feature built from data that is not available at prediction time in production. Common in time-series: using future information to predict the past.

**Manifestations**:
```python
# BAD — leakage in time-series feature engineering
# Predicting churn at time T, but feature includes "days_since_last_purchase"
# which is computed at T+30 (30 days after prediction time)
def leaky_features(df):
    df['future_avg_spend'] = df.groupby('customer_id')['amount'].rolling('30D').mean()
    # This uses 30 days of FUTURE data — LEAKAGE
    return df

# GOOD — strict temporal feature engineering
def temporal_features(df, as_of_date):
    """Features as of a specific prediction date."""
    mask = df['date'] <= as_of_date
    historical = df[mask]

    features = historical.groupby('customer_id').agg({
        'amount': ['sum', 'mean', 'count'],
        'date': 'max'
    })
    features['days_since_last_purchase'] = (
        as_of_date - features[('date', 'max')]
    ).dt.days
    # All features computed from data available AT prediction time
    return features
```

**Why it's dangerous**: Leakage produces unrealistically high performance in development that collapses in production. The model learned to use information it won't have at inference time.

**Correction**: For every feature, ask: "Will this exact data be available at the moment of prediction?" If the answer involves any future data, it is leakage. Use temporal cross-validation (GroupKFold by time window).

---

### Serving Gap

**Definition**: Model achieves high performance in the training environment but significantly lower performance in the serving environment due to preprocessing, tokenization, or feature encoding mismatches.

**Manifestations**:
```python
# BAD — different preprocessing in training vs serving
# Training:
train_texts = [text.lower().strip() for text in raw_texts]  # lowercased
# Serving:
# API receives raw text, passes directly to model without lowercasing
# → token distribution mismatch → performance drop

# GOOD — unified preprocessing with unit test
class TextPreprocessor:
    """Shared preprocessor: same code path for training and serving."""

    def __init__(self, max_length: int = 512):
        self.max_length = max_length
        self.tokenizer = AutoTokenizer.from_pretrained("bert-base-chinese")

    def __call__(self, texts: List[str]) -> Dict[str, torch.Tensor]:
        texts = [t.lower().strip() for t in texts]
        return self.tokenizer(
            texts,
            padding=True,
            truncation=True,
            max_length=self.max_length,
            return_tensors="pt"
        )

# Unit test: verify training and serving produce identical preprocessing
preprocessor = TextPreprocessor()
train_output = preprocessor(["Hello World"])
serving_output = preprocessor(["Hello World"])
assert torch.equal(train_output['input_ids'], serving_output['input_ids'])
```

**Why it's dangerous**: The serving gap is invisible until production. Training metrics look great. Production metrics are poor. Root cause investigation is difficult because the mismatch is subtle (different tokenizer settings, different normalization, different padding).

**Correction**: (1) Use the exact same preprocessing code path for training and serving. (2) Unit test that training preprocessing and serving preprocessing produce identical output for the same input. (3) Log preprocessing output in serving for debugging.

---

### No Reproducibility

**Definition**: Training run without fixed random seeds, without config files, without data versioning, or with unpinned dependencies. The result cannot be reproduced by anyone else or by the same person six months later.

**Manifestations**:
```python
# BAD — non-reproducible training
import torch
import numpy as np
import random

# No seeds set — different results every run
model = MyModel()
optimizer = AdamW(model.parameters(), lr=1e-4)  # lr hardcoded, not in config
# Data loaded from "latest" — version not tracked
# requirements.txt has "torch>=2.0" — different versions on different machines

# GOOD — reproducible training
def set_seed(seed: int = 42):
    """Set all random seeds for reproducibility."""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False

# Config file (YAML) — all hyperparameters externalized
# config.yaml:
#   seed: 42
#   model: bert-base-chinese
#   lr: 2e-5
#   batch_size: 16
#   epochs: 3
#   data_version: dvc://datasets/v1.2.0

# requirements.txt with exact versions
torch==2.1.0
transformers==4.35.0
datasets==2.14.0
scikit-learn==1.3.0
lightgbm==4.1.0
optuna==3.4.0

# Reproducibility verification
print(f"Seed: {config.seed}")
print(f"Data: {config.data_version} (SHA256: {compute_sha256(config.data_path)})")
print(f"Environment: requirements.txt pinned")
```

**Why it's dangerous**: Science depends on reproducibility. Engineering depends on reproducibility. A non-reproducible result cannot be validated, cannot be iterated upon, and cannot be deployed with confidence.

**Correction**: Four components mandatory: (1) random seed set in all frameworks, (2) config file with all hyperparameters, (3) data version (DVC or SHA256), (4) environment freeze (requirements.txt with == versions).
