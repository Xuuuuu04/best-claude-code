---
title: "ML Engineer — Domain 3: Evaluation & Inference Deployment"
source: core.md §Domain 5-6
---

# Domain 5: Evaluation

## 5.1 Failure Analysis (Required: ≥20 Examples)

```python
def analyze_failures(model, test_dataset, tokenizer=None, n_examples=50):
    """
    Comprehensive failure analysis with error taxonomy.
    Required: at least 20 failure examples with categorized taxonomy.
    """
    failures = []

    for example in test_dataset:
        if tokenizer:
            inputs = tokenizer(example['input'], return_tensors="pt")
            with torch.no_grad():
                outputs = model(**inputs)
            pred = torch.argmax(outputs.logits, dim=-1).item()
        else:
            pred = model.predict([example['input']])[0]

        if pred != example['label']:
            failures.append({
                'input': example['input'],
                'true_label': example['label'],
                'predicted_label': pred,
                'confidence': get_confidence(model, example['input'])
            })

    # Error taxonomy
    taxonomy = {
        'boundary_cases': [],      # Input near decision boundary
        'domain_shift': [],        # Input from different distribution
        'label_noise': [],         # Possibly mislabeled training example
        'model_limitation': [],    # Systematic failure on certain patterns
        'ambiguous_input': []      # Input genuinely ambiguous
    }

    for failure in failures[:n_examples]:
        category = classify_failure(failure)
        taxonomy[category].append(failure)

    # Print summary
    print("=== Failure Analysis Summary ===")
    total = sum(len(v) for v in taxonomy.values())
    for category, items in taxonomy.items():
        pct = len(items) / total * 100 if total > 0 else 0
        print(f"  {category}: {len(items)} cases ({pct:.1f}%)")

    return failures, taxonomy

def classify_failure(failure: dict) -> str:
    """Classify a single failure into taxonomy category."""
    confidence = failure.get('confidence', 1.0)
    if confidence < 0.6:
        return 'boundary_cases'
    # Add more heuristics based on domain...
    return 'model_limitation'
```

## 5.2 Bootstrap Confidence Intervals

```python
from scipy import stats
import numpy as np

def bootstrap_ci(y_true, y_pred, metric_fn, n_bootstrap=10000, ci=0.95):
    """Bootstrap confidence interval for any metric."""
    n = len(y_true)
    bootstrap_scores = []

    for _ in range(n_bootstrap):
        idx = np.random.choice(n, n, replace=True)
        score = metric_fn(y_true[idx], y_pred[idx])
        bootstrap_scores.append(score)

    alpha = (1 - ci) / 2
    lower = np.percentile(bootstrap_scores, 100 * alpha)
    upper = np.percentile(bootstrap_scores, 100 * (1 - alpha))
    return lower, upper

# Usage:
from sklearn.metrics import f1_score
lower, upper = bootstrap_ci(
    y_test, y_pred,
    lambda yt, yp: f1_score(yt, yp, average='macro'),
    n_bootstrap=10000
)
print(f"Macro F1: {f1_score(y_test, y_pred, average='macro'):.4f} "
      f"(95% CI: [{lower:.4f}, {upper:.4f}])")
```

## 5.3 LLM-as-Judge with Calibration

```python
def llm_as_judge(responses, reference_answers, judge_model="gpt-4o"):
    """
    Use LLM as judge with calibration set.
    Required: human-judged calibration set with inter-rater agreement check.
    """
    from openai import OpenAI
    client = OpenAI()

    scores = []
    for response, reference in zip(responses, reference_answers):
        prompt = f"""Rate the following response on a scale of 1-5:
        Criteria: Accuracy, Completeness, Clarity, Helpfulness

        Reference Answer: {reference}
        Response to Evaluate: {response}

        Provide score (1-5) and brief justification."""

        completion = client.chat.completions.create(
            model=judge_model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.0
        )
        score = extract_score(completion.choices[0].message.content)
        scores.append(score)

    return np.mean(scores), scores

# Calibration: human judges rate same subset
# Compute Cohen's Kappa between human and LLM judge
# Kappa > 0.7 = acceptable for automated evaluation
```

## 5.4 Model Card Template

```markdown
# Model Card: [Model Name]

## Model Details
- Architecture: [e.g., BERT-base-chinese]
- Fine-tuning method: [e.g., QLoRA r=16]
- Training data: [description + version]
- Training date: [YYYY-MM-DD]

## Intended Use
- Primary use case: [description]
- Expected input: [format, length, language]
- Expected output: [format]

## Limitations
1. [Specific condition where model performs poorly]
2. [Domain shift sensitivity]
3. [Input length constraints]

## Evaluation Results
- Primary metric: [value] (95% CI: [lower, upper])
- Test set: [description, size, date]
- Failure analysis: [N examples, taxonomy summary]

## Ethical Considerations
- [Bias assessment results]
- [Sensitive data handling]
```

---

# Domain 6: Inference Deployment

## 6.1 vLLM Production Serving

```python
from vllm import LLM, SamplingParams

# Model loading with quantization
llm = LLM(
    model="Qwen/Qwen3-7B-Instruct",
    quantization="awq",                # AWQ 4-bit quantization
    tensor_parallel_size=1,            # Number of GPUs
    gpu_memory_utilization=0.85,       # Leave 15% for overhead
    max_model_len=4096,
    dtype="float16"
)

# Performance measurement
import time
params = SamplingParams(temperature=0.7, max_tokens=512)

start = time.perf_counter()
outputs = llm.generate(["测试提示词"] * 100, params)
elapsed = time.perf_counter() - start

latencies = sorted([o.metrics.finished_time - o.metrics.arrival_time for o in outputs])
p50 = latencies[len(latencies) // 2]
p99 = latencies[int(len(latencies) * 0.99)]

print(f"P50 latency: {p50:.3f}s")
print(f"P99 latency: {p99:.3f}s")
print(f"Throughput: {len(outputs) / elapsed:.1f} requests/s")
```

### vLLM OpenAI-Compatible Server

```bash
# Start vLLM server with OpenAI-compatible API
python -m vllm.entrypoints.openai.api_server \
    --model Qwen/Qwen3-7B-Instruct \
    --quantization awq \
    --tensor-parallel-size 1 \
    --gpu-memory-utilization 0.85 \
    --max-model-len 4096 \
    --port 8000

# Test with curl
curl http://localhost:8000/v1/completions \
    -H "Content-Type: application/json" \
    -d '{
        "model": "Qwen/Qwen3-7B-Instruct",
        "prompt": "Hello,",
        "max_tokens": 100
    }'
```

## 6.2 ONNX Export and Optimization

```python
import torch
from transformers import AutoModelForSequenceClassification

model = AutoModelForSequenceClassification.from_pretrained("./fine-tuned-model")
model.eval()

# Create dummy input
dummy_input = (
    torch.ones(1, 128, dtype=torch.long),    # input_ids
    torch.ones(1, 128, dtype=torch.long)     # attention_mask
)

# Export to ONNX
torch.onnx.export(
    model,
    dummy_input,
    "model.onnx",
    input_names=["input_ids", "attention_mask"],
    output_names=["logits"],
    dynamic_axes={
        "input_ids": {0: "batch_size", 1: "sequence_length"},
        "attention_mask": {0: "batch_size", 1: "sequence_length"},
        "logits": {0: "batch_size"}
    },
    opset_version=14,
    do_constant_folding=True
)

# Verify numerical equivalence
import onnxruntime as ort
session = ort.InferenceSession("model.onnx")
ort_inputs = {
    "input_ids": dummy_input[0].numpy(),
    "attention_mask": dummy_input[1].numpy()
}
ort_outputs = session.run(None, ort_inputs)

# Compare PyTorch and ONNX outputs
torch_outputs = model(*dummy_input).logits.detach().numpy()
np.testing.assert_allclose(torch_outputs, ort_outputs[0], rtol=1e-4, atol=1e-4)
print("ONNX export verified: outputs match within tolerance")
```

### ONNX Runtime Quantization (INT8)

```python
from onnxruntime.quantization import quantize_dynamic, QuantType

# Dynamic quantization (weights to INT8, activations stay FP32)
quantize_dynamic(
    model_input="model.onnx",
    model_output="model_int8.onnx",
    weight_type=QuantType.QInt8
)

# Benchmark
import time
session_int8 = ort.InferenceSession("model_int8.onnx")
start = time.time()
for _ in range(100):
    session_int8.run(None, ort_inputs)
print(f"INT8 inference time: {(time.time() - start) / 100 * 1000:.2f}ms")
```

## 6.3 TensorRT Optimization

```python
import tensorrt as trt
import pycuda.driver as cuda
import pycuda.autoinit

def build_tensorrt_engine(onnx_path, engine_path, fp16=True, max_batch=8):
    """Build TensorRT engine from ONNX model."""
    logger = trt.Logger(trt.Logger.WARNING)
    builder = trt.Builder(logger)
    network = builder.create_network(
        1 << int(trt.NetworkDefinitionCreationFlag.EXPLICIT_BATCH)
    )
    parser = trt.OnnxParser(network, logger)

    with open(onnx_path, 'rb') as f:
        parser.parse(f.read())

    config = builder.create_builder_config()
    config.max_workspace_size = 4 * 1024 * 1024 * 1024  # 4GB
    if fp16:
        config.set_flag(trt.BuilderFlag.FP16)

    profile = builder.create_optimization_profile()
    profile.set_shape("input_ids", (1, 128), (4, 128), (max_batch, 128))
    config.add_optimization_profile(profile)

    engine = builder.build_engine(network, config)
    with open(engine_path, 'wb') as f:
        f.write(engine.serialize())

    return engine
```

## 6.4 FastAPI Serving Wrapper

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import torch
import time

app = FastAPI(title="ML Inference Service")

class InferenceRequest(BaseModel):
    text: str
    max_length: int = 512

class InferenceResponse(BaseModel):
    prediction: str
    confidence: float
    latency_ms: float

# Load model at startup
model = None
tokenizer = None

@app.on_event("startup")
def load_model():
    global model, tokenizer
    model = AutoModelForSequenceClassification.from_pretrained("./model")
    tokenizer = AutoTokenizer.from_pretrained("./model")
    model.eval()

@app.get("/health")
def health():
    return {"status": "healthy", "model_loaded": model is not None}

@app.get("/ready")
def ready():
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    return {"status": "ready"}

@app.post("/predict", response_model=InferenceResponse)
def predict(request: InferenceRequest):
    start = time.time()

    inputs = tokenizer(request.text, return_tensors="pt", truncation=True,
                       max_length=request.max_length)

    with torch.no_grad():
        outputs = model(**inputs)
        probs = torch.softmax(outputs.logits, dim=-1)
        pred_id = torch.argmax(probs, dim=-1).item()
        confidence = probs[0][pred_id].item()

    latency = (time.time() - start) * 1000

    return InferenceResponse(
        prediction=model.config.id2label[pred_id],
        confidence=confidence,
        latency_ms=latency
    )

# Graceful shutdown
@app.on_event("shutdown")
def shutdown():
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
```

## 6.5 Quantization Decision Matrix

| Method | Compression | Quality Loss | Speedup | Best For |
|--------|-------------|--------------|---------|----------|
| FP16 | 2x | Negligible | 1.5-2x | GPU inference, general use |
| INT8 (dynamic) | 4x | 1-2% | 2-3x | CPU inference, latency-sensitive |
| INT8 (static) | 4x | 0.5-1% | 2-3x | CPU, calibrated on representative data |
| AWQ 4-bit | 4x | 2-3% | 2-3x | LLM serving, GPU memory constrained |
| GPTQ 4-bit | 4x | 3-5% | 2-3x | LLM serving, maximum compression |
| Q4_K_M (GGUF) | 4x | 5-10% | 2-4x | llama.cpp, edge deployment |

## 6.6 Benchmark Design Checklist

- [ ] Define primary metric aligned with business objective
- [ ] Define secondary metrics (latency, memory, fairness)
- [ ] Establish baseline before complex approaches
- [ ] Use held-out test set (evaluate once)
- [ ] Compute confidence intervals (bootstrap)
- [ ] Report per-subgroup performance
- [ ] Include failure analysis (≥20 examples)
- [ ] Document hardware/environment
- [ ] Pin all dependencies (requirements.txt)
- [ ] Set random seeds for reproducibility
