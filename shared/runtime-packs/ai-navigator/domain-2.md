---
title: "AI Navigator — Domain 2: RAG Architecture & Skill Engineering"
source: core.md §Domain 2-3
---

# Domain 2: RAG Architecture Deep Dive

## 2.1 Full RAG Pipeline

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core.node_parser import SentenceWindowNodeParser
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
from llama_index.llms.openai import OpenAI
from llama_index.core.postprocessor import MetadataReplacementPostProcessor

# 1. Load documents
documents = SimpleDirectoryReader("./data").load_data()

# 2. Chunking strategy: Sentence Window
node_parser = SentenceWindowNodeParser.from_defaults(
    window_size=3,
    window_metadata_key="window",
    original_text_metadata_key="original_text",
)
nodes = node_parser.get_nodes_from_documents(documents)

# 3. Embedding model selection
embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-large-zh-v1.5")

# 4. Build index
index = VectorStoreIndex(nodes, embed_model=embed_model)

# 5. Retrieval with reranking
retriever = index.as_retriever(similarity_top_k=10)

# 6. Query engine with post-processing
query_engine = index.as_query_engine(
    llm=OpenAI(model="gpt-4o"),
    node_postprocessors=[
        MetadataReplacementPostProcessor(target_metadata_key="window")
    ],
    similarity_top_k=10,
)

# 7. Evaluation
from llama_index.core.evaluation import FaithfulnessEvaluator, RelevancyEvaluator
faithfulness_evaluator = FaithfulnessEvaluator()
relevancy_evaluator = RelevancyEvaluator()
```

## 2.2 Advanced RAG Strategies

### HyDE (Hypothetical Document Embeddings)
```python
# Generate hypothetical answer, then embed for retrieval
hyde_prompt = """Given the question, generate a hypothetical document that would answer it.
Question: {query}
Hypothetical Document:"""

hypothetical_doc = llm.complete(hhyde_prompt.format(query=user_query)).text
# Embed hypothetical_doc and retrieve similar real documents
```

### Auto-Merging Retrieval
```python
from llama_index.core.node_parser import HierarchicalNodeParser

# Parse into hierarchy: parent (large) → children (small)
node_parser = HierarchicalNodeParser.from_defaults(
    chunk_sizes=[2048, 512, 128]
)
# Retrieve children, merge back to parent if threshold met
```

### GraphRAG
```python
from llama_index.core import PropertyGraphIndex
from llama_index.core.indices.property_graph import SchemaLLMPathExtractor

# Extract entities and relationships
index = PropertyGraphIndex.from_documents(
    documents,
    llm=llm,
    embed_model=embed_model,
    kg_extractors=[SchemaLLMPathExtractor(llm=llm)],
)
# Query traverses entity-relationship graph
```

## 2.3 Skill Engineering

### Skill Registration Pattern
```python
from typing import Callable, Dict, Any

class SkillRegistry:
    """Capability-as-skill registration system."""

    def __init__(self):
        self._skills: Dict[str, Callable] = {}

    def register(self, name: str, description: str):
        """Decorator to register a skill."""
        def decorator(func: Callable) -> Callable:
            self._skills[name] = {
                "func": func,
                "description": description,
                "signature": self._extract_signature(func)
            }
            return func
        return decorator

    def get_skill(self, name: str) -> Dict[str, Any]:
        return self._skills.get(name)

    def list_skills(self) -> Dict[str, str]:
        return {k: v["description"] for k, v in self._skills.items()}

# Usage
registry = SkillRegistry()

@registry.register("weather_lookup", "Get current weather for a location")
def get_weather(location: str, date: str = "today") -> str:
    """Fetch weather data."""
    ...

@registry.register("calculate", "Perform mathematical calculations")
def calculate(expression: str) -> float:
    """Evaluate math expression."""
    ...
```

### Skill Composition
```python
class ComposedSkill:
    """Compose multiple skills into a workflow."""

    def __init__(self, registry: SkillRegistry):
        self.registry = registry

    def execute(self, plan: List[Dict]) -> Any:
        """Execute a plan: list of {skill_name, args}."""
        context = {}
        for step in plan:
            skill = self.registry.get_skill(step["skill"])
            # Resolve args from context if needed
            args = {k: context.get(v, v) for k, v in step["args"].items()}
            result = skill["func"](**args)
            context[step["output_key"]] = result
        return context
```

---

# Domain 3: AI Industry Dynamics

## 3.1 Chinese AI Regulatory Environment

| Regulation | Scope | Requirement | Penalty |
|---|---|---|---|
| 大模型备案 | Generative AI services | File with CAC before public release | Service suspension |
| 算法备案 | Recommendation algorithms | File algorithm details | Fines |
| 数据出境 | Cross-border data transfer | Security assessment for important data | Fines, suspension |
| 生成式AI管理办法 | All generative AI | Content moderation, user verification | Fines, license revocation |

## 3.2 Inference Optimization Trends

| Technique | Mechanism | Speedup | Quality Impact |
|---|---|---|---|
| Quantization (INT8/FP8) | Lower precision weights | 2-4x | 1-5% degradation |
| Speculative Decoding | Draft model + verification | 2-3x | None |
| KV Cache Optimization | Reuse attention states | 1.5-2x | None |
| Continuous Batching | Dynamic batch assembly | 5-10x throughput | None |
| Distillation | Small model mimics large | 3-5x | 5-15% degradation |

## 3.3 Cost Modeling Template

```python
def estimate_monthly_cost(
    daily_input_tokens: int,
    daily_output_tokens: int,
    input_price_per_1m: float,
    output_price_per_1m: float,
    cache_hit_rate: float = 0.0,
    cache_discount: float = 0.9
) -> Dict[str, float]:
    """Estimate monthly API cost with caching."""
    daily_input_cost = (daily_input_tokens / 1e6) * input_price_per_1m
    daily_output_cost = (daily_output_tokens / 1e6) * output_price_per_1m

    # Apply cache discount to cached portion
    cached_input = daily_input_tokens * cache_hit_rate
    uncached_input = daily_input_tokens * (1 - cache_hit_rate)
    cached_cost = (cached_input / 1e6) * input_price_per_1m * (1 - cache_discount)
    uncached_cost = (uncached_input / 1e6) * input_price_per_1m
    daily_input_cost = cached_cost + uncached_cost

    monthly = (daily_input_cost + daily_output_cost) * 30

    return {
        "daily_input_cost": daily_input_cost,
        "daily_output_cost": daily_output_cost,
        "monthly_total": monthly,
        "monthly_savings_from_cache": daily_input_tokens * cache_hit_rate / 1e6 * input_price_per_1m * cache_discount * 30
    }
```
