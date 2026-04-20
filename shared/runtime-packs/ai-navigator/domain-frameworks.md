---
title: "AI Navigator — Domain: AI Framework Deep Dive"
source: core.md §Domain 2
---

# Domain: AI Framework Deep Dive

## 1. Framework Architecture Comparison

### 1.1 Core Philosophy Matrix

| Framework | Core Abstraction | Primary Paradigm | Learning Curve | Best For |
|-----------|-----------------|------------------|----------------|----------|
| LangChain | Runnable / LCEL | Pipeline composition | Moderate | General AI apps, quick prototyping [已验证, 2026-04] |
| LangGraph | StateGraph | Stateful workflows | Steep | Complex multi-step agents, persistence [已验证, 2026-04] |
| LlamaIndex | Index / QueryEngine | Retrieval-centric | Gentle | RAG systems, document Q&A [已验证, 2026-04] |
| DSPy | Signature / Module / Optimizer | Programmatic prompts | Moderate | Systematic prompt optimization [已验证, 2026-04] |
| CrewAI | Agent / Task / Crew | Role-based multi-agent | Gentle | Team simulation, role delegation [已验证, 2026-04] |
| AutoGen | ConversableAgent | Conversational agents | Moderate | Research prototyping, agent debate [已验证, 2026-04] |

### 1.2 Architecture Deep Dive

**LangChain — LCEL (LangChain Expression Language)**

```python
from langchain_core.runnables import RunnablePassthrough, RunnableParallel
from langchain_openai import ChatOpenAI
from langchain_core.prompts import ChatPromptTemplate

# LCEL pipeline: pipe operator for composable chains
prompt = ChatPromptTemplate.from_template("""
Answer based on context:
{context}

Question: {question}
""")

model = ChatOpenAI(model="gpt-4o")

# Simple chain
chain = prompt | model

# Parallel execution
parallel_chain = RunnableParallel(
    context=lambda x: retrieve(x["question"]),
    question=lambda x: x["question"]
) | prompt | model

# With fallback
fallback_chain = chain.with_fallbacks([alternative_chain])
```

Key concepts [权威, LangChain docs, 2026-04]:
- `Runnable` interface: everything is a runnable component
- `|` operator: pipe for composing runnables
- `RunnablePassthrough`: pass through inputs
- `RunnableParallel`: execute branches in parallel
- Streaming: `.stream()` for token-by-token output

**LangGraph — Stateful Agent Workflows**

```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, Annotated
import operator

class AgentState(TypedDict):
    messages: Annotated[list, operator.add]
    next_step: str

# Define nodes
graph = StateGraph(AgentState)

def retrieve(state):
    """Retrieve relevant documents."""
    docs = vector_store.similarity_search(state["messages"][-1].content)
    return {"messages": [{"role": "system", "content": f"Context: {docs}"}]}

def generate(state):
    """Generate response."""
    response = llm.invoke(state["messages"])
    return {"messages": [response], "next_step": END}

def route(state):
    """Conditional routing."""
    if needs_retrieval(state["messages"][-1]):
        return "retrieve"
    return "generate"

# Build graph
graph.add_node("retrieve", retrieve)
graph.add_node("generate", generate)
graph.set_entry_point("retrieve")
graph.add_conditional_edges("retrieve", route, {
    "retrieve": "retrieve",
    "generate": "generate"
})
graph.add_edge("generate", END)

# Compile with persistence
app = graph.compile(checkpointer=MemorySaver())

# Run with thread_id for persistence
result = app.invoke(
    {"messages": [{"role": "user", "content": "What is RAG?"}]},
    config={"configurable": {"thread_id": "thread-1"}}
)
```

Key concepts [权威, LangGraph docs, 2026-04]:
- `StateGraph`: define workflow as state machine
- Nodes: functions that transform state
- Edges: transitions between nodes
- Conditional edges: dynamic routing based on state
- `checkpointer`: persistence for long-running conversations
- `interrupt_before`/`interrupt_after`: human-in-the-loop

**LlamaIndex — Retrieval-Centric Architecture**

```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core.workflow import Workflow, Event, StartEvent, StopEvent
from llama_index.core.postprocessor import SentenceTransformerRerank

# Basic RAG pipeline
 documents = SimpleDirectoryReader("./data").load_data()
index = VectorStoreIndex.from_documents(documents)
query_engine = index.as_query_engine(
    similarity_top_k=10,
    node_postprocessors=[SentenceTransformerRerank(top_n=3)]
)
response = query_engine.query("What is the main topic?")

# Workflow (event-driven)
class RetrieveEvent(Event):
    query: str

class GenerateEvent(Event):
    context: str
    query: str

class RAGWorkflow(Workflow):
    @step
    async def retrieve(self, ev: StartEvent) -> RetrieveEvent:
        nodes = await self.retriever.aretrieve(ev.query)
        context = "\n".join([n.text for n in nodes])
        return RetrieveEvent(query=ev.query, context=context)
    
    @step
    async def generate(self, ev: RetrieveEvent) -> StopEvent:
        response = await self.llm.acomplete(
            f"Context: {ev.context}\n\nQuestion: {ev.query}"
        )
        return StopEvent(result=response.text)

workflow = RAGWorkflow(timeout=60)
result = await workflow.run(query="What is RAG?")
```

Key concepts [权威, LlamaIndex docs, 2026-04]:
- `Index`: various index types (VectorStore, Summary, PropertyGraph)
- `QueryEngine`: abstraction for query processing
- `Workflow`: event-driven async pipeline
- `NodePostprocessor`: reranking, filtering, transformation
- `AgentWorker`: agent-based query execution

**DSPy — Programmatic Prompt Optimization**

```python
import dspy

# Define signature
class AnswerQuestion(dspy.Signature):
    """Answer questions based on context."""
    context = dspy.InputField(desc="Relevant passages")
    question = dspy.InputField()
    answer = dspy.OutputField(desc="Concise answer")

# Define module
class RAG(dspy.Module):
    def __init__(self, num_passages=3):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=num_passages)
        self.generate = dspy.ChainOfThought(AnswerQuestion)
    
    def forward(self, question):
        context = self.retrieve(question).passages
        return self.generate(context=context, question=question)

# Compile with optimizer
from dspy.teleprompt import BootstrapFewShot

teleprompter = BootstrapFewShot(metric=answer_correctness)
optimized_rag = teleprompter.compile(RAG(), trainset=trainset)

# Use
result = optimized_rag("What is RAG?")
```

Key concepts [权威, DSPy docs, 2026-04]:
- `Signature`: input/output contract
- `Module`: composable components
- `Predict`: basic LLM call
- `ChainOfThought`: CoT reasoning
- ` teleprompter`: automatic prompt optimization
- `compile()`: optimize prompts and weights on training data

---

## 2. Framework Selection Decision Tree

```
Start: What is your primary use case?
|
├── RAG (Retrieval-Augmented Generation)
│   ├── Need simple document Q&A → LlamaIndex (gentlest learning curve)
│   ├── Need complex retrieval strategies → LlamaIndex (HyDE, Auto-merging, GraphRAG)
│   ├── Need agentic RAG with tool use → LangChain + LangGraph
│   └── Need systematic prompt optimization → DSPy
│
├── Agent Orchestration
│   ├── Single agent with tools → LangChain (AgentExecutor)
│   ├── Multi-agent state machine → LangGraph (StateGraph)
│   ├── Role-based team simulation → CrewAI
│   ├── Research/agent debate → AutoGen
│   └── Need human-in-the-loop → LangGraph (interrupt_before/after)
│
├── Prompt Engineering / Optimization
│   ├── Need systematic prompt tuning → DSPy (teleprompter)
│   ├── Need prompt versioning → LangChain + LangSmith
│   └── Need A/B testing → LangSmith
│
├── Production Observability
│   ├── Need tracing/evaluation → LangSmith (LangChain ecosystem)
│   ├── Need open-source observability → Phoenix (Arize)
│   └── Need minimal setup → Built-in callbacks
│
└── Quick Prototyping
    ├── RAG prototype → LlamaIndex (5-line setup)
    ├── Agent prototype → LangChain (pre-built agents)
    └── Custom pipeline → LangChain LCEL
```

---

## 3. Feature Matrix

### 3.1 RAG Capabilities

| Feature | LangChain | LangGraph | LlamaIndex | DSPy |
|---------|-----------|-----------|------------|------|
| Basic vector retrieval | Yes [权威] | Yes [权威] | Yes [权威] | Yes [权威] |
| Hybrid search (sparse + dense) | Yes [已验证] | Yes [已验证] | Yes [已验证] | Limited [已验证] |
| HyDE | Manual [已验证] | Manual [已验证] | Built-in [权威] | Manual [已验证] |
| Auto-merging | Manual [已验证] | Manual [已验证] | Built-in [权威] | No [已验证] |
| GraphRAG | Via integration [已验证] | Via integration [已验证] | PropertyGraphIndex [权威] | No [已验证] |
| Reranking | Via integration [已验证] | Via integration [已验证] | Built-in [权威] | Via module [已验证] |
| Multi-modal RAG | Limited [已验证] | Limited [已验证] | Yes [已验证] | No [已验证] |

### 3.2 Agent Capabilities

| Feature | LangChain | LangGraph | CrewAI | AutoGen |
|---------|-----------|-----------|--------|---------|
| Tool use | Yes [权威] | Yes [权威] | Yes [权威] | Yes [权威] |
| Multi-agent | Limited [已验证] | Yes [权威] | Yes [权威] | Yes [权威] |
| Stateful persistence | No [已验证] | Yes [权威] | Limited [已验证] | Limited [已验证] |
| Human-in-the-loop | Limited [已验证] | Yes [权威] | No [已验证] | Yes [已验证] |
| Streaming | Yes [权威] | Yes [权威] | Limited [已验证] | Yes [已验证] |
| Async | Yes [权威] | Yes [权威] | Limited [已验证] | Yes [已验证] |

### 3.3 Observability & Evaluation

| Feature | LangSmith | Phoenix | Weights & Biases | Custom |
|---------|-----------|---------|------------------|--------|
| Tracing | Excellent [权威] | Good [已验证] | Good [已验证] | Manual |
| Evaluation datasets | Yes [权威] | Yes [已验证] | Yes [已验证] | Manual |
| A/B testing | Yes [权威] | Limited [已验证] | Yes [已验证] | Manual |
| Cost tracking | Yes [权威] | Yes [已验证] | Limited [已验证] | Manual |
| Open source | No [权威] | Yes [权威] | Partial [已验证] | Yes |

---

## 4. Production Maturity Assessment (as of 2026-04)

| Framework | Version | Release Cadence | Breaking Changes | Enterprise Adoption | Verdict |
|-----------|---------|----------------|------------------|---------------------|---------|
| LangChain | 0.3.x | Weekly | Frequent (0.1→0.2→0.3) | High [已验证] | Mature, stable for production |
| LangGraph | 0.3.x | Weekly | Moderate | Growing [已验证] | Production-ready for stateful agents |
| LlamaIndex | 0.12.x | Weekly | Moderate | High [已验证] | Mature for RAG workloads |
| DSPy | 2.5.x | Monthly | Low | Niche [已验证] | Stable for prompt optimization |
| CrewAI | 0.100.x | Weekly | High (pre-1.0) | Low [已验证] | Wait for 1.0 for production |
| AutoGen | 0.4.x | Monthly | High (0.2→0.4 rewrite) | Research [已验证] | Research/prototyping only |

**Maturity warnings [待验证, 2026-04]:**
- CrewAI is pre-1.0 with frequent breaking changes — use for experimentation, not production
- AutoGen had a major rewrite (0.2→0.4) — ecosystem still recovering
- LangChain 0.3 is stable — 0.1/0.2 migration was painful

---

## 5. Code Examples: Common Patterns

### 5.1 RAG Pipeline Comparison

**LangChain RAG:**
```python
from langchain import hub
from langchain_community.vectorstores import Chroma
from langchain_core.output_parsers import StrOutputParser
from langchain_core.runnables import RunnablePassthrough
from langchain_openai import OpenAIEmbeddings, ChatOpenAI

# Load, chunk, index
vectorstore = Chroma.from_documents(documents, OpenAIEmbeddings())
retriever = vectorstore.as_retriever()

# Prompt
prompt = hub.pull("rlm/rag-prompt")

# Chain
rag_chain = (
    {"context": retriever | format_docs, "question": RunnablePassthrough()}
    | prompt
    | ChatOpenAI(model="gpt-4o")
    | StrOutputParser()
)

rag_chain.invoke("What is Task Decomposition?")
```

**LlamaIndex RAG:**
```python
from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core.postprocessor import SentenceTransformerRerank

# Load and index (one-liner)
documents = SimpleDirectoryReader("data").load_data()
index = VectorStoreIndex.from_documents(documents)

# Query with reranking
query_engine = index.as_query_engine(
    similarity_top_k=10,
    node_postprocessors=[
        SentenceTransformerRerank(top_n=3, model="BAAI/bge-reranker-base")
    ]
)
response = query_engine.query("What is Task Decomposition?")
```

**DSPy RAG:**
```python
import dspy
from dspy.retrieve.chromadb_rm import ChromadbRM

# Set up retriever
retriever = ChromadbRM('collection_name', 'db_path')
dspy.settings.configure(rm=retriever, lm=dspy.OpenAI(model='gpt-4o'))

# Define module
class GenerateAnswer(dspy.Signature):
    """Answer questions with short factoid answers."""
    context = dspy.InputField(desc="may contain relevant facts")
    question = dspy.InputField()
    answer = dspy.OutputField(desc="often between 1 and 5 words")

class RAG(dspy.Module):
    def __init__(self, num_passages=3):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=num_passages)
        self.generate_answer = dspy.ChainOfThought(GenerateAnswer)
    
    def forward(self, question):
        context = self.retrieve(question).passages
        return self.generate_answer(context=context, question=question)

# Use
rag = RAG()
result = rag("What is Task Decomposition?")
```

### 5.2 Multi-Agent Pattern Comparison

**LangGraph Multi-Agent:**
```python
from langgraph.graph import StateGraph, END
from typing import TypedDict

class State(TypedDict):
    messages: list
    next: str

# Researcher agent
researcher_prompt = """You are a researcher. Find information about the topic."""
# Writer agent
writer_prompt = """You are a writer. Summarize the research."""

graph = StateGraph(State)
graph.add_node("researcher", lambda state: {"messages": [llm.invoke(researcher_prompt + state["messages"][-1].content)]})
graph.add_node("writer", lambda state: {"messages": [llm.invoke(writer_prompt + state["messages"][-1].content)]})
graph.add_edge("researcher", "writer")
graph.add_edge("writer", END)
graph.set_entry_point("researcher")

app = graph.compile()
result = app.invoke({"messages": [{"role": "user", "content": "AI safety"}]})
```

**CrewAI Multi-Agent:**
```python
from crewai import Agent, Task, Crew

researcher = Agent(
    role='Researcher',
    goal='Find comprehensive information',
    backstory='Expert researcher with 10 years experience',
    verbose=True
)

writer = Agent(
    role='Writer',
    goal='Create engaging content',
    backstory='Professional writer',
    verbose=True
)

research_task = Task(
    description='Research AI safety trends',
    agent=researcher,
    expected_output='Comprehensive report'
)

write_task = Task(
    description='Write blog post based on research',
    agent=writer,
    expected_output='Blog post markdown',
    context=[research_task]
)

crew = Crew(agents=[researcher, writer], tasks=[research_task, write_task])
result = crew.kickoff()
```

---

## 6. Migration Guide

### 6.1 LangChain 0.1 → 0.3 Migration

Key changes [权威, LangChain migration guide, 2026-04]:
- `langchain` package split into `langchain-core`, `langchain-community`, provider packages
- `BaseModel` → `BaseChatModel` for chat models
- `LLMChain` deprecated in favor of LCEL
- `AgentExecutor` → LangGraph for complex agents

```python
# OLD (0.1)
from langchain import OpenAI, LLMChain, PromptTemplate

# NEW (0.3)
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from langchain_core.output_parsers import StrOutputParser

# OLD chain
llm = OpenAI()
template = PromptTemplate(template="Answer: {question}", input_variables=["question"])
chain = LLMChain(llm=llm, prompt=template)

# NEW chain
prompt = ChatPromptTemplate.from_template("Answer: {question}")
chain = prompt | ChatOpenAI() | StrOutputParser()
```

### 6.2 AutoGen 0.2 → 0.4 Migration

Major rewrite [权威, AutoGen docs, 2026-04]:
- `ConversableAgent` → `AssistantAgent` / `UserProxyAgent`
- `GroupChat` → `RoundRobinGroupChat` / `SelectorGroupChat`
- New event-driven architecture
- Async-first design

**Recommendation [已验证, 2026-04]:** If using AutoGen 0.2, consider migrating to LangGraph for production or staying on 0.2 until 0.4 stabilizes.

---

## 7. Chinese Ecosystem Integration

| Framework | Chinese Docs | Chinese Community | Domestic Model Support | Notes |
|-----------|-------------|-------------------|------------------------|-------|
| LangChain | Moderate [已验证] | Large [已验证] | Good (Qwen, DeepSeek via community) | Most popular internationally |
| LangGraph | Limited [已验证] | Growing [已验证] | Good [已验证] | Part of LangChain ecosystem |
| LlamaIndex | Moderate [已验证] | Medium [已验证] | Good (BAAI embeddings) [已验证] | Strong RAG focus |
| DSPy | Limited [已验证] | Small [已验证] | Via OpenAI-compatible API [已验证] | Niche but powerful |
| CrewAI | Limited [已验证] | Small [已验证] | Via OpenAI-compatible API [已验证] | Pre-1.0 |

**Chinese model integration examples:**

```python
# LangChain with DeepSeek
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="deepseek-chat",
    api_key="your-key",
    base_url="https://api.deepseek.com/v1"
)

# LangChain with Qwen (via DashScope)
from langchain_community.chat_models import ChatTongyi

llm = ChatTongyi(
    model="qwen3-max",
    dashscope_api_key="your-key"
)

# LlamaIndex with BAAI embeddings
from llama_index.embeddings.huggingface import HuggingFaceEmbedding

embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-large-zh-v1.5")
```

---

## 8. Performance Benchmarks

### 8.1 RAG Pipeline Latency (as of 2026-04) [待验证]

| Framework | Indexing (1000 docs) | Query (single) | Query (concurrent 10) | Memory |
|-----------|---------------------|----------------|----------------------|--------|
| LangChain + Chroma | 12s | 450ms | 2.1s | 1.2GB |
| LlamaIndex + Chroma | 10s | 380ms | 1.8s | 1.1GB |
| LlamaIndex + Milvus | 15s | 220ms | 0.9s | 2.5GB |
| DSPy + Chroma | 12s | 520ms | 2.4s | 1.3GB |

### 8.2 Agent Orchestration Overhead

| Framework | Single Agent | 3-Agent Workflow | 10-Agent Workflow | Persistence |
|-----------|-------------|------------------|-------------------|-------------|
| LangChain | 50ms | 150ms | 500ms | No |
| LangGraph | 60ms | 180ms | 600ms | Yes (checkpointer) |
| CrewAI | 80ms | 250ms | 800ms | Limited |
| AutoGen | 70ms | 200ms | 700ms | Limited |

**Notes [待验证, 2026-04]:**
- Latency excludes LLM call time (varies by model)
- Concurrent query tests on 8-core machine
- Memory measured for in-process vector stores

---

## 9. Selection Quick Reference

| If you need... | Choose | Avoid |
|----------------|--------|-------|
| Production RAG today | LlamaIndex | CrewAI (pre-1.0) |
| Complex stateful agents | LangGraph | LangChain (limited state) |
| Systematic prompt optimization | DSPy | Manual prompt engineering |
| Quick AI prototype | LangChain LCEL | AutoGen (complexity) |
| Role-based multi-agent | CrewAI | LangGraph (overkill) |
| Research/experimentation | AutoGen | CrewAI (less flexible) |
| Maximum observability | LangChain + LangSmith | DSPy (limited tracing) |
| Open-source everything | LlamaIndex + Phoenix | LangSmith (proprietary) |
