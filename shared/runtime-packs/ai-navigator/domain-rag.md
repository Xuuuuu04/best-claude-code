---
title: "AI Navigator — Domain: RAG Full Pipeline Deep Dive"
source: core.md §Domain 3.2
---

# Domain: RAG Full Pipeline Deep Dive

## 1. Pipeline Overview

```
Documents → Load → Chunk → Embed → Index → Retrieve → Rerank → Generate → Evaluate
   ↑                                                    ↓
   └────────────── Feedback Loop ───────────────────────┘
```

Each stage has critical decisions that impact retrieval quality, latency, and cost.

---

## 2. Chunking Strategies

### 2.1 Fixed-Size Chunking

**Definition:** Split documents into chunks of fixed token/character count with optional overlap.

```python
from langchain.text_splitter import RecursiveCharacterTextSplitter

# Fixed-size with overlap
splitter = RecursiveCharacterTextSplitter(
    chunk_size=512,        # tokens per chunk
    chunk_overlap=50,      # overlap between chunks
    length_function=len,
    separators=["\n\n", "\n", " ", ""]  # Priority order
)

chunks = splitter.split_documents(documents)
```

**Pros [已验证, 2026-04]:**
- Simple, predictable
- Easy to implement
- Consistent chunk sizes for batching

**Cons:**
- May split mid-sentence or mid-paragraph
- Loses document structure
- Context fragmentation

**Best for:** Uniform documents (logs, transcripts), quick prototyping.

### 2.2 Token-Based Chunking

```python
from langchain.text_splitter import TokenTextSplitter

splitter = TokenTextSplitter(
    chunk_size=256,      # tokens
    chunk_overlap=20     # tokens
)

chunks = splitter.split_documents(documents)
```

**Pros:**
- Exact token count (important for embedding model limits)
- Consistent with embedding model tokenization

**Cons:**
- Same structure issues as fixed-size
- Tokenizer-dependent

### 2.3 Sentence-Based Chunking

```python
import nltk
from langchain.text_splitter import NLTKTextSplitter

splitter = NLTKTextSplitter(
    separator="\n",
    chunk_size=1000,
    chunk_overlap=0
)

chunks = splitter.split_documents(documents)
```

**Pros [已验证, 2026-04]:**
- Preserves sentence boundaries
- Natural reading units
- Better for semantic coherence

**Cons:**
- Variable chunk sizes
- May miss cross-sentence context

**Best for:** Articles, reports, any prose documents.

### 2.4 Semantic Chunking

**Definition:** Group sentences by semantic similarity rather than fixed size.

```python
from langchain_experimental.text_splitter import SemanticChunker
from langchain_openai import OpenAIEmbeddings

# Semantic chunking based on embedding similarity
splitter = SemanticChunker(
    OpenAIEmbeddings(),
    breakpoint_threshold_type="percentile",
    breakpoint_threshold_amount=95  # Split when similarity drops below 95th percentile
)

chunks = splitter.split_documents(documents)
```

**Pros [已验证, 2026-04]:**
- Respects semantic boundaries
- Reduces context fragmentation
- Better retrieval accuracy

**Cons:**
- More expensive (requires embeddings)
- Variable chunk sizes
- Threshold tuning required

**Best for:** Heterogeneous documents, mixed content types.

### 2.5 Hierarchical / Parent-Child Chunking

```python
from llama_index.core.node_parser import HierarchicalNodeParser

# Parent chunks (large) contain children (small)
node_parser = HierarchicalNodeParser.from_defaults(
    chunk_sizes=[2048, 512, 128],  # Parent, child, grandchild
    chunk_overlaps=[0, 20, 10]
)

nodes = node_parser.get_nodes_from_documents(documents)
```

**Pros [已验证, 2026-04]:**
- Retrieve small chunks, return large context
- Preserves hierarchy
- Better for structured documents

**Cons:**
- Complex implementation
- Storage overhead

**Best for:** Technical documentation, manuals, legal documents.

### 2.6 Chunking Strategy Selection Matrix

| Document Type | Recommended Strategy | Chunk Size | Overlap |
|--------------|---------------------|------------|---------|
| Code | Semantic / AST-based | 200-500 tokens | 20-50 |
| Legal contracts | Hierarchical | 512-1024 parent, 128 child | 50-100 |
| Academic papers | Sentence-based | 3-5 sentences | 1 sentence |
| Chat logs | Fixed-size | 256-512 tokens | 20-50 |
| Product manuals | Hierarchical | 1024 parent, 256 child | 50 |
| News articles | Sentence-based | 2-4 sentences | 0-1 |
| Mixed content | Semantic | Variable | 0 |

---

## 3. Embedding Model Selection

### 3.1 English Embedding Models

| Model | Dimensions | Context | MTEB Avg | Size | Best For |
|-------|-----------|---------|----------|------|----------|
| text-embedding-3-large | 3072 | 8192 | 64.6% [已验证] | API | General purpose [权威] |
| text-embedding-3-small | 1536 | 8192 | 62.3% [已验证] | API | Cost-sensitive [权威] |
| BGE-large-en-v1.5 | 1024 | 512 | 64.2% [已验证] | 1.3GB | Open-source leader [已验证] |
| GTE-large | 1024 | 512 | 63.1% [已验证] | 0.7GB | Fast inference [已验证] |
| E5-mistral-7b-instruct | 4096 | 32768 | 66.6% [已验证] | 14GB | Long documents [已验证] |

### 3.2 Chinese Embedding Models

| Model | Dimensions | Context | C-MTEB Avg | Size | Best For |
|-------|-----------|---------|------------|------|----------|
| BAAI/bge-large-zh-v1.5 | 1024 | 512 | 69.1% [已验证] | 1.3GB | Chinese general [已验证] |
| BAAI/bge-m3 | 1024 | 8192 | 71.2% [已验证] | 2.2GB | Multilingual + long [已验证] |
| Tao8/embed-zh-v1 | 768 | 512 | 67.5% [已验证] | 0.4GB | Lightweight Chinese [已验证] |
| acge_text_embedding | 1792 | 512 | 70.3% [已验证] | 1.1GB | Chinese enterprise [已验证] |

### 3.3 Multilingual Embedding Models

| Model | Dimensions | Context | Languages | Best For |
|-------|-----------|---------|-----------|----------|
| BAAI/bge-m3 | 1024 | 8192 | 100+ | Multilingual RAG [已验证] |
| intfloat/multilingual-e5-large | 1024 | 512 | 100+ | Cross-lingual [已验证] |
| text-embedding-3-large | 3072 | 8192 | 80+ | API-based multilingual [权威] |

### 3.4 Embedding Selection Decision Tree

```
Start: What is your content language?
|
├── Primarily Chinese
│   ├── Need long context (>512 tokens) → BAAI/bge-m3
│   ├── Need lightweight deployment → Tao8/embed-zh-v1
│   └── General purpose → BAAI/bge-large-zh-v1.5
│
├── Primarily English
│   ├── Using OpenAI API → text-embedding-3-large
│   ├── Self-hosting, general → BGE-large-en-v1.5
│   ├── Self-hosting, fast → GTE-large
│   └── Long documents → E5-mistral-7b-instruct
│
└── Multilingual
    ├── Self-hosting → BAAI/bge-m3
    └── API → text-embedding-3-large
```

---

## 4. Vector Store Selection

| Store | Persistence | Filtering | Hybrid Search | Scaling | Best For |
|-------|------------|-----------|---------------|---------|----------|
| Chroma | Local/Server | Metadata | No | Single node | Prototyping [已验证] |
| Pinecone | Cloud | Metadata | Yes | Auto | Production [权威] |
| Weaviate | Cloud/Self-host | GraphQL | Yes | Cluster | Enterprise [已验证] |
| Milvus/Zilliz | Cloud/Self-host | Rich | Yes | Cluster | Large scale [已验证] |
| Qdrant | Self-host | Payload | Yes | Cluster | Rust ecosystem [已验证] |
| pgvector | PostgreSQL | SQL | No | Read replicas | Existing Postgres [已验证] |
| Redis | In-memory | Redis | No | Cluster | Low-latency [已验证] |

**Selection guide [已验证, 2026-04]:**
- Prototyping → Chroma (zero setup)
- Production, no ops team → Pinecone (managed)
- Enterprise, complex queries → Weaviate
- Large scale (>100M vectors) → Milvus
- Existing PostgreSQL → pgvector
- Ultra-low latency → Redis

---

## 5. Retrieval Strategies

### 5.1 Basic Similarity Search

```python
# LangChain
retriever = vectorstore.as_retriever(
    search_type="similarity",
    search_kwargs={"k": 5}
)

# LlamaIndex
retriever = index.as_retriever(similarity_top_k=5)
```

### 5.2 MMR (Maximal Marginal Relevance)

```python
# Balance relevance with diversity
retriever = vectorstore.as_retriever(
    search_type="mmr",
    search_kwargs={"k": 5, "fetch_k": 20, "lambda_mult": 0.5}
)
```

**Parameters [已验证, 2026-04]:**
- `fetch_k`: Number of documents to fetch before MMR filtering
- `lambda_mult`: Tradeoff between relevance (1.0) and diversity (0.0)
- Best for: queries where diverse perspectives are valuable

### 5.3 Multi-Query Retrieval

```python
from langchain.retrievers.multi_query import MultiQueryRetriever

# Generate multiple query variations
multi_query_retriever = MultiQueryRetriever.from_llm(
    retriever=base_retriever,
    llm=llm,
    prompt=QUERY_PROMPT  # Custom prompt for query generation
)
```

**Best for:** Queries that might not match document vocabulary.

### 5.4 Contextual Compression

```python
from langchain.retrievers.document_compressors import LLMChainExtractor
from langchain.retrievers import ContextualCompressionRetriever

# Compress retrieved documents to relevant parts
compressor = LLMChainExtractor.from_llm(llm)
compression_retriever = ContextualCompressionRetriever(
    base_compressor=compressor,
    base_retriever=retriever
)
```

**Best for:** Long documents where only small portions are relevant.

---

## 6. Reranking Strategies

### 6.1 Cross-Encoder Reranking

```python
from sentence_transformers import CrossEncoder

# Load cross-encoder reranker
reranker = CrossEncoder('BAAI/bge-reranker-large')

# Rerank retrieved documents
pairs = [[query, doc.page_content] for doc in retrieved_docs]
scores = reranker.predict(pairs)

# Sort by score
ranked = sorted(zip(retrieved_docs, scores), key=lambda x: x[1], reverse=True)
top_docs = [doc for doc, score in ranked[:5]]
```

**Pros [已验证, 2026-04]:**
- More accurate than bi-encoder (embedding) similarity
- Captures query-document interaction

**Cons:**
- Slower (O(n) forward passes)
- Higher compute cost

### 6.2 LLM-Based Reranking

```python
def llm_rerank(query: str, docs: list, top_k: int = 3) -> list:
    """Use LLM to score relevance."""
    
    scores = []
    for doc in docs:
        prompt = f"""
Rate the relevance of the following document to the query:
Query: {query}
Document: {doc.page_content[:500]}

Relevance score (0-10):"""
        
        response = llm.invoke(prompt)
        score = extract_score(response)
        scores.append((doc, score))
    
    return [doc for doc, score in sorted(scores, key=lambda x: x[1], reverse=True)[:top_k]]
```

**Best for:** When cross-encoder is insufficient and LLM cost is acceptable.

### 6.3 Reranking Selection Matrix

| Method | Speed | Accuracy | Cost | Best For |
|--------|-------|----------|------|----------|
| No reranking | Fastest | Baseline | Free | Prototyping |
| Cross-encoder | Medium | +15-25% | Low | Production standard |
| LLM-based | Slow | +20-35% | High | High-stakes retrieval |
| ColBERT | Fast | +10-20% | Medium | Large-scale retrieval |

---

## 7. Advanced RAG Strategies

### 7.1 HyDE (Hypothetical Document Embeddings)

```python
def hyde_retrieve(query: str, llm, retriever) -> list:
    """Hypothetical Document Embeddings retrieval."""
    
    # Step 1: Generate hypothetical answer
    hyde_prompt = f"""
Given the question, write a short passage that would answer it:
Question: {query}

Passage:"""
    
    hypothetical_doc = llm.invoke(hyde_prompt)
    
    # Step 2: Retrieve using hypothetical document
    docs = retriever.similarity_search(hypothetical_doc, k=10)
    
    # Step 3: Rerank with original query
    reranked = rerank_with_query(query, docs)
    
    return reranked
```

**When to use [已验证, 2026-04]:**
- Query is a question, not keywords
- Query-document vocabulary mismatch
- Short queries that lack specificity

**Tradeoffs:**
- Extra LLM call per query (cost)
- Can introduce hallucination into retrieval
- Best when combined with reranking

### 7.2 GraphRAG

```python
from llama_index.core import PropertyGraphIndex
from llama_index.core.indices.property_graph import SchemaLLMPathExtractor

# Build knowledge graph index
index = PropertyGraphIndex.from_documents(
    documents,
    llm=llm,
    embed_model=embed_model,
    kg_extractors=[
        SchemaLLMPathExtractor(
            llm=llm,
            possible_entities=["Person", "Organization", "Product", "Technology"],
            possible_relations=["works_at", "developed", "competes_with", "uses"]
        )
    ]
)

# Query traverses the graph
query_engine = index.as_query_engine(
    include_text=True,  # Include source text
    similarity_top_k=5
)

response = query_engine.query("What technologies did Google develop?")
```

**When to use [已验证, 2026-04]:**
- Documents with rich entity relationships
- Multi-hop reasoning required
- Structured knowledge extraction

**Tradeoffs:**
- Expensive to build (LLM calls for extraction)
- Requires schema definition
- Best for: technical documentation, research papers, knowledge bases

### 7.3 Multi-Vector Retrieval

```python
from llama_index.core import MultiModalVectorStoreIndex

# Index different modalities separately
index = MultiModalVectorStoreIndex.from_documents(
    documents,
    image_documents=image_docs,
    store_image_vectors=True
)

# Retrieve across modalities
retriever = index.as_retriever(
    vector_store_query_mode="default",
    similarity_top_k=5
)
```

**When to use:** Documents contain images, tables, or charts alongside text.

### 7.4 Fusion Retrieval (Multi-Vector + Reranking)

```python
def fusion_retrieve(query: str, retrievers: list, weights: list = None) -> list:
    """Combine multiple retrieval strategies with reciprocal rank fusion."""
    
    if weights is None:
        weights = [1.0] * len(retrievers)
    
    # Collect results from each retriever
    all_results = []
    for retriever, weight in zip(retrievers, weights):
        docs = retriever.retrieve(query)
        all_results.append([(doc, rank) for rank, doc in enumerate(docs)])
    
    # Reciprocal Rank Fusion
    scores = {}
    for results in all_results:
        for doc, rank in results:
            doc_id = doc.id_
            if doc_id not in scores:
                scores[doc_id] = 0
            scores[doc_id] += 1.0 / (rank + 60)  # RRF formula
    
    # Sort by fused score
    ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    return [doc_map[doc_id] for doc_id, score in ranked]
```

**When to use:** Multiple retrieval strategies complement each other (e.g., keyword + semantic + graph).

---

## 8. Generation Optimization

### 8.1 Prompt Templates for RAG

```python
# Basic RAG prompt
BASIC_RAG_PROMPT = """
Use the following context to answer the question:

Context:
{context}

Question: {question}

Answer:"""

# Advanced RAG with citation
CITATION_RAG_PROMPT = """
Answer the question based on the provided context. Cite the source document for each fact.

Context:
{context}

Question: {question}

Instructions:
1. Answer using only the provided context
2. Cite the source document name for each fact
3. If the context doesn't contain the answer, say "I don't have enough information"

Answer:"""

# Multi-document synthesis
SYNTHESIS_PROMPT = """
Synthesize information from multiple sources to answer the question.

Sources:
{context}

Question: {question}

Instructions:
1. Identify agreements and disagreements between sources
2. Provide a balanced answer
3. Note when sources conflict

Answer:"""
```

### 8.2 Context Window Management

```python
def build_context(docs: list, max_tokens: int = 4000) -> str:
    """Build context string within token limit."""
    
    context_parts = []
    current_tokens = 0
    
    for doc in docs:
        doc_text = f"[Source: {doc.metadata.get('source', 'Unknown')}]\n{doc.page_content}\n\n"
        doc_tokens = estimate_tokens(doc_text)
        
        if current_tokens + doc_tokens > max_tokens:
            break
        
        context_parts.append(doc_text)
        current_tokens += doc_tokens
    
    return "\n".join(context_parts)
```

---

## 9. Evaluation Framework

### 9.1 Retrieval Metrics

| Metric | Definition | Target | How to Measure |
|--------|-----------|--------|----------------|
| Hit Rate | % queries with relevant doc in top-k | >90% @ k=5 | Manual judgment |
| MRR | Mean Reciprocal Rank | >0.7 | Manual judgment |
| NDCG | Normalized Discounted Cumulative Gain | >0.8 | Graded relevance |
| Precision@K | Relevant docs / K | >0.6 @ k=5 | Manual judgment |

### 9.2 Generation Metrics

| Metric | Definition | Target | How to Measure |
|--------|-----------|--------|----------------|
| Faithfulness | Answer supported by context | >0.9 | LLM judge |
| Answer Relevance | Answer addresses question | >0.9 | LLM judge |
| Context Precision | Retrieved context relevant | >0.8 | LLM judge |
| Context Recall | All relevant context retrieved | >0.8 | LLM judge |

### 9.3 Evaluation Code

```python
from llama_index.core.evaluation import (
    FaithfulnessEvaluator,
    RelevancyEvaluator,
    RetrieverEvaluator,
    generate_question_context_pairs
)

# Generate evaluation dataset
qa_dataset = generate_question_context_pairs(
    nodes=nodes,
    llm=llm,
    num_questions_per_chunk=2
)

# Evaluate retriever
retriever_evaluator = RetrieverEvaluator.from_metric_names(
    ["mrr", "hit_rate"],
    retriever=retriever
)
retriever_results = retriever_evaluator.evaluate(qa_dataset)

# Evaluate response
faithfulness_evaluator = FaithfulnessEvaluator(llm=llm)
relevancy_evaluator = RelevancyEvaluator(llm=llm)

for query, expected in qa_dataset:
    response = query_engine.query(query)
    
    faithfulness = faithfulness_evaluator.evaluate(
        query=query,
        response=response.response,
        contexts=[c.text for c in response.source_nodes]
    )
    
    relevancy = relevancy_evaluator.evaluate(
        query=query,
        response=response.response,
        contexts=[c.text for c in response.source_nodes]
    )
```

---

## 10. Production Checklist

### 10.1 Pre-Deployment

- [ ] Chunking strategy validated on representative documents
- [ ] Embedding model selected and benchmarked
- [ ] Vector store sized for expected data volume
- [ ] Retrieval strategy tested (k values, search type)
- [ ] Reranking evaluated (with/without comparison)
- [ ] Prompt template optimized for use case
- [ ] Evaluation metrics defined and baselined
- [ ] Latency targets met (p50, p95, p99)
- [ ] Cost per query calculated and approved

### 10.2 Monitoring

- [ ] Retrieval accuracy tracked over time
- [ ] Query distribution monitored (common queries, failures)
- [ ] Latency metrics collected
- [ ] Cost per query tracked
- [ ] User feedback collected (thumbs up/down)
- [ ] Document drift detected (new docs, outdated docs)

### 10.3 Maintenance

- [ ] Regular re-indexing schedule
- [ ] Embedding model updates tracked
- [ ] Chunking strategy reviewed quarterly
- [ ] Evaluation dataset refreshed
- [ ] Prompt template A/B tested

---

## 11. Cost Modeling

### 11.1 RAG Cost Components

| Component | Cost Driver | Typical Range |
|-----------|------------|---------------|
| Embedding | Tokens in documents | $0.10-0.50 per 1M tokens [权威] |
| Vector storage | Number of vectors | $0.02-0.10 per 1K vectors/month [权威] |
| Retrieval | Compute | Negligible (local) or $0.001/query (cloud) |
| Reranking | Model inference | $0.001-0.01 per query |
| Generation | Output tokens | $0.10-15.00 per 1M tokens (model dependent) |

### 11.2 Cost Optimization Strategies

1. **Caching:** Cache frequent queries and their retrieved contexts
2. **Hybrid search:** Use keyword search first, then semantic for hard queries
3. **Smaller models:** Use GPT-4o-mini or Haiku for generation when possible
4. **Batch embedding:** Embed documents in batches for API efficiency
5. **Pruning:** Remove outdated or low-quality documents from index

```python
# Caching example
from functools import lru_cache
import hashlib

@lru_cache(maxsize=1000)
def cached_rag_query(query_hash: str):
    """Cache RAG responses by query hash."""
    query = query_cache[query_hash]
    return rag_pipeline(query)

def rag_with_cache(query: str):
    query_hash = hashlib.md5(query.encode()).hexdigest()
    if query_hash in response_cache:
        return response_cache[query_hash]
    
    response = rag_pipeline(query)
    response_cache[query_hash] = response
    return response
```
