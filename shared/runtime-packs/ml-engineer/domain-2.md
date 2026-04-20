---
title: "ML Engineer — Domain 2: Deep Learning & LLM Fine-Tuning"
source: core.md §Domain 3-4
---

# Domain 3: Deep Learning

## 3.1 PyTorch Training Loop (Production-Grade)

```python
import torch
from torch.cuda.amp import autocast, GradScaler
from torch.optim import AdamW
from torch.optim.lr_scheduler import CosineAnnealingLR

class TrainingConfig:
    lr: float = 2e-5
    batch_size: int = 16
    epochs: int = 3
    max_grad_norm: float = 1.0
    warmup_ratio: float = 0.1
    seed: int = 42

def train_epoch(model, dataloader, optimizer, scheduler, scaler, device):
    model.train()
    total_loss = 0

    for batch in dataloader:
        optimizer.zero_grad()

        with autocast(dtype=torch.float16):
            outputs = model(**batch)
            loss = outputs.loss

        scaler.scale(loss).backward()
        scaler.unscale_(optimizer)
        torch.nn.utils.clip_grad_norm_(model.parameters(), config.max_grad_norm)
        scaler.step(optimizer)
        scaler.update()
        scheduler.step()

        total_loss += loss.item()

    return total_loss / len(dataloader)

# Initialize
scaler = GradScaler()
optimizer = AdamW(model.parameters(), lr=config.lr)
scheduler = CosineAnnealingLR(optimizer, T_max=total_steps)
```

## 3.2 Distributed Training (DDP)

```python
import torch.distributed as dist
from torch.nn.parallel import DistributedDataParallel as DDP

def setup_ddp():
    dist.init_process_group("nccl")
    local_rank = int(os.environ["LOCAL_RANK"])
    torch.cuda.set_device(local_rank)
    return local_rank

model = create_model().to(local_rank)
model = DDP(model, device_ids=[local_rank])

# DataLoader with DistributedSampler
from torch.utils.data.distributed import DistributedSampler
sampler = DistributedSampler(dataset)
dataloader = DataLoader(dataset, batch_size=16, sampler=sampler)
```

## 3.3 DeepSpeed ZeRO Configuration

```json
{
  "train_batch_size": "auto",
  "train_micro_batch_size_per_gpu": "auto",
  "gradient_accumulation_steps": "auto",
  "zero_optimization": {
    "stage": 2,
    "offload_optimizer": {
      "device": "cpu",
      "pin_memory": true
    },
    "allgather_partitions": true,
    "allgather_bucket_size": 2e8,
    "overlap_comm": true,
    "reduce_scatter": true
  },
  "fp16": {
    "enabled": true,
    "loss_scale": 0,
    "loss_scale_window": 1000,
    "initial_scale_power": 16
  }
}
```

---

# Domain 4: LLM Fine-Tuning

## 4.1 QLoRA Setup (Qwen3-7B Example)

```python
from transformers import AutoModelForCausalLM, BitsAndBytesConfig
from peft import LoraConfig, get_peft_model, TaskType

# 4-bit quantization config
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.bfloat16,
    bnb_4bit_use_double_quant=True
)

model = AutoModelForCausalLM.from_pretrained(
    "Qwen/Qwen3-7B",
    quantization_config=bnb_config,
    device_map="auto",
    trust_remote_code=True
)

# LoRA configuration
lora_config = LoraConfig(
    r=16,                    # rank: 8-64 (higher = more parameters)
    lora_alpha=32,           # alpha = 2*r is common starting point
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                    "gate_proj", "up_proj", "down_proj"],
    lora_dropout=0.05,
    bias="none",
    task_type=TaskType.CAUSAL_LM
)

model = get_peft_model(model, lora_config)
model.print_trainable_parameters()
# Expected: trainable params ~40M || all params ~7.2B || trainable% ~0.55%
```

## 4.2 SFT Training with TRL

```python
from trl import SFTTrainer, SFTConfig
from datasets import load_dataset

# Load and format dataset
dataset = load_dataset("json", data_files="train.jsonl")

def formatting_func(example):
    """Format instruction-following data."""
    return f"### Instruction:\n{example['instruction']}\n\n### Response:\n{example['output']}"

training_args = SFTConfig(
    output_dir="./output",
    num_train_epochs=3,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,      # effective batch = 16
    learning_rate=2e-4,
    warmup_ratio=0.03,
    lr_scheduler_type="cosine",
    logging_steps=10,
    save_strategy="epoch",
    bf16=True,
    max_seq_length=2048,
    dataset_text_field="text",
    packing=True,                        # pack multiple short examples
)

trainer = SFTTrainer(
    model=model,
    train_dataset=dataset["train"],
    eval_dataset=dataset.get("validation"),
    args=training_args,
    formatting_func=formatting_func,
)

trainer.train()
trainer.save_model("./final_model")
```

## 4.3 DPO (Direct Preference Optimization)

```python
from trl import DPOTrainer, DPOConfig
from peft import PeftModel

# DPO requires preference pairs: chosen (good) vs rejected (bad)
# Dataset format:
# {
#   "prompt": "User query...",
#   "chosen": "Good response...",
#   "rejected": "Bad response..."
# }

dpo_config = DPOConfig(
    output_dir="./dpo_output",
    beta=0.1,                          # DPO temperature: 0.1-0.5
    learning_rate=5e-7,                # Lower LR than SFT
    per_device_train_batch_size=2,
    gradient_accumulation_steps=8,
    num_train_epochs=1,
    logging_steps=10,
    bf16=True,
)

# Load SFT-tuned model as base
base_model = AutoModelForCausalLM.from_pretrained("./sft_model")
ref_model = AutoModelForCausalLM.from_pretrained("./sft_model")

dpo_trainer = DPOTrainer(
    model=base_model,
    ref_model=ref_model,
    args=dpo_config,
    train_dataset=preference_dataset,
    tokenizer=tokenizer,
)

dpo_trainer.train()
```

## 4.4 Dataset Construction Best Practices

### Quality Filtering
```python
from transformers import pipeline
import numpy as np

perplexity_scorer = pipeline("text-generation", model="gpt2")

def filter_by_perplexity(texts, max_perplexity=100):
    """Remove low-quality examples by perplexity threshold."""
    filtered = []
    for text in texts:
        # Compute perplexity
        inputs = tokenizer(text, return_tensors="pt")
        with torch.no_grad():
            outputs = model(**inputs, labels=inputs["input_ids"])
            perplexity = torch.exp(outputs.loss).item()
        if perplexity <= max_perplexity:
            filtered.append(text)
    return filtered
```

### Deduplication with MinHash
```python
from datasketch import MinHash, MinHashLSH

def deduplicate_texts(texts, threshold=0.8, num_perm=128):
    """Remove near-duplicate texts using MinHash LSH."""
    lsh = MinHashLSH(threshold=threshold, num_perm=num_perm)
    unique_texts = []

    for text in texts:
        m = MinHash(num_perm=num_perm)
        for word in text.split():
            m.update(word.encode('utf8'))

        if not lsh.query(m):
            lsh.insert(text, m)
            unique_texts.append(text)

    return unique_texts
```

## 4.5 Base Model Selection Matrix

| Model | Size | License | Chinese | Code | Context | Best For |
|-------|------|---------|---------|------|---------|----------|
| Qwen3-7B | 7B | Apache 2.0 | Excellent | Good | 128K | General Chinese tasks, on-premise |
| Qwen3-72B | 72B | Apache 2.0 | Excellent | Excellent | 128K | High-quality generation, complex reasoning |
| DeepSeek-V3 | 671B (MoE) | MIT-like | Excellent | Excellent | 64K | Cost-sensitive API, reasoning |
| Llama-3-8B | 8B | Llama 3 | Good | Good | 8K | English-centric, commercial use |
| Mistral-7B | 7B | Apache 2.0 | Fair | Good | 32K | European languages, fine-tuning |
| Gemma-2-9B | 9B | Gemma | Good | Good | 8K | Google ecosystem, research |
