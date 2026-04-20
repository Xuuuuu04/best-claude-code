---
title: "ML Engineer — Domain 1: Data Engineering & Traditional ML"
source: core.md §Domain 1-2
---

# Domain 1: Data Engineering (ML-Specific)

## 1.1 Data Quality Audit

Every ML project starts with a data quality audit. No exceptions.

### Null Rate Analysis
```python
def audit_data_quality(df: pd.DataFrame) -> pd.DataFrame:
    """Comprehensive data quality audit."""
    report = pd.DataFrame({
        'column': df.columns,
        'dtype': df.dtypes,
        'null_count': df.isnull().sum(),
        'null_rate': df.isnull().sum() / len(df),
        'unique_count': df.nunique(),
        'memory_mb': df.memory_usage(deep=True) / 1024 / 1024
    })
    return report.sort_values('null_rate', ascending=False)
```

### Label Quality (Cohen's Kappa)
```python
from sklearn.metrics import cohen_kappa_score

def check_label_agreement(annotator1: List, annotator2: List) -> float:
    """Measure inter-annotator agreement. Kappa > 0.8 = excellent, 0.6-0.8 = good."""
    kappa = cohen_kappa_score(annotator1, annotator2)
    print(f"Cohen's Kappa: {kappa:.3f}")
    if kappa < 0.6:
        print("WARNING: Low agreement — review annotation guidelines")
    return kappa
```

## 1.2 Leakage Prevention

### GroupKFold for Grouped Data
```python
from sklearn.model_selection import GroupKFold

# Time-series or customer-grouped data: prevent future leakage
gkf = GroupKFold(n_splits=5)
for fold, (train_idx, val_idx) in enumerate(gkf.split(X, y, groups=customer_ids)):
    X_train, X_val = X.iloc[train_idx], X.iloc[val_idx]
    y_train, y_val = y.iloc[train_idx], y.iloc[val_idx]
    # Train and evaluate...
```

### Test Set Isolation Protocol
```python
from sklearn.model_selection import train_test_split

# Split ONCE, at project start, and do not touch until final evaluation
X_train_val, X_test, y_train_val, y_test = train_test_split(
    X, y, test_size=0.1, random_state=SEED, stratify=y
)

# NEVER:
# - Tune hyperparameters on X_test
# - Inspect X_test to design features
# - Re-split after seeing test results
```

## 1.3 Data Versioning with DVC

```bash
# Initialize DVC
dvc init

# Add dataset to DVC tracking
dvc add data/train.csv data/test.csv

# Push to remote (S3)
dvc remote add -d myremote s3://ml-data-bucket/datasets/
dvc push

# Reproduce from any commit
git checkout v1.2.0
dvc pull  # retrieves the exact dataset version
```

## 1.4 Feature Engineering

### Target Encoding with Smoothing
```python
import pandas as pd

def target_encode(train_df, val_df, col, target, smoothing=10):
    """Target encoding with smoothing to prevent overfitting."""
    global_mean = train_df[target].mean()
    agg = train_df.groupby(col)[target].agg(['mean', 'count'])
    counts = agg['count']
    means = agg['mean']
    smooth = (counts * means + smoothing * global_mean) / (counts + smoothing)

    val_df = val_df.copy()
    val_df[f'{col}_te'] = val_df[col].map(smooth)
    val_df[f'{col}_te'] = val_df[f'{col}_te'].fillna(global_mean)
    return val_df
```

---

# Domain 2: Traditional ML

## 2.1 LightGBM with Optuna

```python
import lightgbm as lgb
import optuna

def objective(trial):
    params = {
        'n_estimators': trial.suggest_int('n_estimators', 100, 2000),
        'learning_rate': trial.suggest_float('learning_rate', 1e-4, 0.1, log=True),
        'max_depth': trial.suggest_int('max_depth', 3, 10),
        'num_leaves': trial.suggest_int('num_leaves', 15, 300),
        'min_child_samples': trial.suggest_int('min_child_samples', 5, 100),
        'subsample': trial.suggest_float('subsample', 0.5, 1.0),
        'colsample_bytree': trial.suggest_float('colsample_bytree', 0.5, 1.0),
        'reg_alpha': trial.suggest_float('reg_alpha', 1e-8, 10.0, log=True),
        'reg_lambda': trial.suggest_float('reg_lambda', 1e-8, 10.0, log=True),
        'objective': 'binary',
        'metric': 'auc',
        'random_state': SEED,
        'n_jobs': -1,
        'verbosity': -1,
    }
    model = lgb.LGBMClassifier(**params)
    model.fit(
        X_train, y_train,
        eval_set=[(X_val, y_val)],
        callbacks=[
            lgb.early_stopping(50, verbose=False),
            optuna.integration.LightGBMPruningCallback(trial, 'auc')
        ]
    )
    return model.best_score_['valid_0']['auc']

study = optuna.create_study(
    direction='maximize',
    sampler=optuna.samplers.TPESampler(seed=SEED),
    pruner=optuna.pruners.MedianPruner()
)
study.optimize(objective, n_trials=100, timeout=3600)
```

## 2.2 Model Calibration

```python
from sklearn.calibration import CalibratedClassifierCV

# Platt scaling (sigmoid calibration)
calibrated = CalibratedClassifierCV(base_estimator, method='sigmoid', cv=5)
calibrated.fit(X_train, y_train)

# Isotonic regression (non-parametric)
calibrated_iso = CalibratedClassifierCV(base_estimator, method='isotonic', cv=5)
calibrated_iso.fit(X_train, y_train)

# Evaluate calibration
from sklearn.calibration import calibration_curve
prob_true, prob_pred = calibration_curve(y_test, y_proba, n_bins=10)
ece = np.mean(np.abs(prob_true - prob_pred))
print(f"Expected Calibration Error: {ece:.4f}")
```

## 2.3 SHAP Feature Importance

```python
import shap

explainer = shap.TreeExplainer(model)
shap_values = explainer.shap_values(X_val)

# Summary plot
shap.summary_plot(shap_values, X_val, feature_names=feature_names)

# Force plot for single prediction
shap.force_plot(explainer.expected_value, shap_values[0], X_val.iloc[0])
```
