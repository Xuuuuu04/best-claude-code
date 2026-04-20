# Domain: AI Workflow Platforms (Dify / Coze / LangFlow / Flowise)

## 1. Dify DSL YAML Structure

### 1.1 Complete DSL Example

```yaml
app:
  mode: chatflow
  name: Customer Support RAG Bot
  description: Answers product questions with knowledge base retrieval

environment_variables:
  - name: SLACK_ESCALATION_WEBHOOK
    value: ""
  - name: OPENAI_API_KEY
    value: ""

conversation_variables:
  - name: session_id
    value: ""
  - name: escalation_count
    value: 0

graph:
  nodes:
    - id: start
      type: start
      data:
        variables:
          - name: query
            type: string
            required: true

    - id: knowledge_retrieval
      type: knowledge-retrieval
      data:
        query: "{{#start.query#}}"
        knowledge_base_id: product_kb
        retrieval_mode: hybrid
        top_k: 5
        score_threshold: 0.65

    - id: check_confidence
      type: if-else
      data:
        conditions:
          - operator: ">"
            left: "{{#knowledge_retrieval.score#}}"
            right: "0.65"

    - id: llm_answer
      type: llm
      data:
        model:
          provider: openai
          name: gpt-4o-mini
          mode: chat
        prompt_template:
          system: "You are a helpful support agent. Use the provided context to answer."
          user: |
            Context: {{#knowledge_retrieval.context#}}
            Question: {{#start.query#}}
        temperature: 0.7
        max_tokens: 500

    - id: slack_escalation
      type: http-request
      data:
        method: POST
        url: "{{#env.SLACK_ESCALATION_WEBHOOK#}}"
        headers:
          Content-Type: application/json
        body:
          text: "Escalation: {{#start.query#}} (Session: {{#conversation.session_id#}})"

    - id: end_high_confidence
      type: end
      data:
        outputs:
          - name: answer
            value: "{{#llm_answer.text#}}"

    - id: end_low_confidence
      type: end
      data:
        outputs:
          - name: answer
            value: "Your question has been escalated to our support team."

  edges:
    - source: start
      target: knowledge_retrieval

    - source: knowledge_retrieval
      target: check_confidence

    - source: check_confidence
      target: llm_answer
      condition: true

    - source: check_confidence
      target: slack_escalation
      condition: false

    - source: llm_answer
      target: end_high_confidence

    - source: slack_escalation
      target: end_low_confidence
```

### 1.2 Node Types Reference

| Node Type | Purpose | Key Parameters |
|---|---|---|
| `start` | Entry point | variables (input schema) |
| `llm` | LLM inference | model, prompt_template, temperature, max_tokens |
| `knowledge-retrieval` | RAG retrieval | knowledge_base_id, query, retrieval_mode, top_k, score_threshold |
| `if-else` | Conditional branch | conditions (operator, left, right) |
| `http-request` | External API call | method, url, headers, body |
| `code` | Custom logic | language (python/javascript), code |
| `iteration` | Loop over array | input_array, output_variable |
| `variable-assigner` | Set variables | variables (name, value) |
| `template-transform` | Text transformation | template (Jinja2) |
| `end` | Exit point | outputs |

### 1.3 Prompt Template Syntax

```jinja2
{# System message with context #}
You are a helpful assistant. Use the following context to answer:
{{#context#}}

{# User message with query #}
User question: {{#query#}}

{# Conditional logic in prompt #}
{% if language == "zh" %}
请用中文回答。
{% else %}
Please answer in English.
{% endif %}

{# Loop over retrieved chunks #}
{% for chunk in chunks %}
[{{ loop.index }}] {{ chunk.content }}
{% endfor %}
```

---

## 2. Coze Bot Platform

### 2.1 Bot Composition

```json
{
  "bot": {
    "name": "Customer Support Bot",
    "description": "Answers product questions and escalates complex issues",
    "persona": "You are a helpful customer support agent for our SaaS product...",
    "knowledge": [
      {
        "id": "product_docs",
        "type": "document",
        "description": "Product documentation and FAQs"
      }
    ],
    "skills": [
      {
        "id": "escalate_to_human",
        "type": "plugin",
        "description": "Escalates conversation to human support team"
      }
    ],
    "opening": {
      "message": "Hi! I'm your support assistant. How can I help you today?",
      "suggested_questions": [
        "How do I reset my password?",
        "What pricing plans do you offer?",
        "How do I integrate with Slack?"
      ]
    },
    "variables": {
      "bot": {
        "company_name": "Acme Corp"
      },
      "user": {
        "plan_tier": "{{user.plan_tier}}",
        "signup_date": "{{user.signup_date}}"
      }
    }
  }
}
```

### 2.2 Workflow Triggers

| Trigger Type | Configuration | Use Case |
|---|---|---|
| `scheduled` | cron expression | Daily report generation |
| `api` | REST endpoint | External system integration |
| `webhook` | HTTP callback | Real-time event processing |
| `conversation` | Chat message | Interactive bot responses |

### 2.3 Plugin Integration

**Custom OpenAPI Plugin**:
```yaml
openapi: 3.0.0
info:
  title: Order Service API
  version: 1.0.0
paths:
  /orders/{id}:
    get:
      operationId: getOrder
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Order details
          content:
            application/json:
              schema:
                type: object
                properties:
                  id: { type: string }
                  status: { type: string }
                  total: { type: number }
```

Coze generates tool descriptions from OpenAPI schema for function calling.

---

## 3. LangFlow

### 3.1 Component Wiring

```python
# LangFlow flow structure (simplified)
flow = {
    "nodes": [
        {
            "id": "chat_input",
            "type": "ChatInput",
            "params": {
                "input_value": "{{input}}",
                "sender": "User",
                "sender_name": "User"
            }
        },
        {
            "id": "prompt_template",
            "type": "PromptComponent",
            "params": {
                "template": "Answer based on context:\n{context}\n\nQuestion: {question}",
                "context": "{{retriever.output}}",
                "question": "{{chat_input.message}}"
            }
        },
        {
            "id": "llm",
            "type": "OpenAIModel",
            "params": {
                "model": "gpt-4o-mini",
                "temperature": 0.7,
                "api_key": "{{OPENAI_API_KEY}}"
            }
        },
        {
            "id": "chat_output",
            "type": "ChatOutput",
            "params": {
                "message": "{{llm.response}}",
                "sender": "AI",
                "sender_name": "Assistant"
            }
        }
    ],
    "edges": [
        {"source": "chat_input", "target": "prompt_template"},
        {"source": "prompt_template", "target": "llm"},
        {"source": "llm", "target": "chat_output"}
    ]
}
```

### 3.2 RAG Pipeline in LangFlow

```
[Chat Input] → [Text Splitter] → [Vector Store]
     ↓
[Embedding Model] ← [Document Loader]
     ↓
[Retriever] → [Prompt Template] → [LLM] → [Chat Output]
```

**Key components**:
- `DocumentLoader`: Load files (PDF, TXT, MD)
- `TextSplitter`: Chunk documents (RecursiveCharacter, Token)
- `EmbeddingModel`: Convert text to vectors (OpenAI, HuggingFace)
- `VectorStore`: Store and search vectors (Chroma, Pinecone, Weaviate)
- `Retriever`: Fetch relevant chunks based on query

---

## 4. Flowise

### 4.1 Chain Composition

```json
{
  "nodes": [
    {
      "id": "llm_chain",
      "type": "llmChain",
      "parameters": {
        "prompt": "{{prompt_template.output}}",
        "llm": "{{openai_model.output}}"
      }
    },
    {
      "id": "router_chain",
      "type": "multiPromptChain",
      "parameters": {
        "promptDescriptions": [
          {"name": "technical", "description": "For technical questions about API and integration"},
          {"name": "billing", "description": "For questions about pricing and payments"}
        ],
        "defaultChain": "{{llm_chain.output}}"
      }
    }
  ]
}
```

### 4.2 Agent Configuration

```json
{
  "agent": {
    "type": "openAIFunctionAgent",
    "llm": "{{openai_model}}",
    "tools": [
      {
        "type": "customTool",
        "name": "getOrderStatus",
        "description": "Get the status of an order by ID",
        "schema": {
          "type": "object",
          "properties": {
            "orderId": {"type": "string", "description": "The order ID"}
          },
          "required": ["orderId"]
        },
        "code": "const response = await fetch(`${BASE_URL}/orders/${orderId}`);\nreturn response.json();"
      }
    ],
    "memory": {
      "type": "bufferWindowMemory",
      "k": 5
    }
  }
}
```

---

## 5. RAG Pipeline Design

### 5.1 Chunking Strategy Selection

| Strategy | Chunk Size | Best For | Trade-off |
|---|---|---|---|
| Fixed-size | 256-512 tokens | General documents | May split mid-sentence |
| Paragraph | Variable | Articles, essays | Preserves semantic units |
| Markdown section | Per heading | Documentation | Structure-aware splitting |
| Code-aware | Function/class | Source code | Respects code boundaries |
| Recursive | 100-1000 tokens | Mixed content | Hierarchical splitting |

### 5.2 Retrieval Quality Tuning

```python
# Retrieval parameters
retrieval_config = {
    "top_k": 5,              # Number of chunks to retrieve
    "score_threshold": 0.65,  # Minimum similarity score
    "retrieval_mode": "hybrid",  # semantic | keyword | hybrid
    "reranker": {
        "enabled": True,
        "model": "cohere-rerank",
        "top_n": 3            # Re-rank top_k to top_n
    }
}
```

**Score threshold guidance**:
- 0.50-0.60: Broad recall, may include irrelevant chunks
- 0.65-0.75: Balanced precision/recall (recommended starting point)
- 0.80-0.90: High precision, may miss relevant chunks

### 5.3 Hybrid Retrieval Formula

```
hybrid_score = α * semantic_score + (1 - α) * keyword_score

# Default: α = 0.7 (70% semantic, 30% keyword)
# For technical queries with specific terms: α = 0.5
# For conceptual queries: α = 0.8
```

---

## 6. Error Handling in AI Platforms

### 6.1 Dify Error Handling Pattern

```yaml
# Retry loop for HTTP request
nodes:
  - id: http_request
    type: http-request
    # ... config ...

  - id: check_error
    type: if-else
    data:
      conditions:
        - operator: ">="
          left: "{{#http_request.status_code#}}"
          right: "500"

  - id: retry_count
    type: variable-assigner
    data:
      variables:
        - name: retry_count
          value: "{{#conversation.retry_count# | default(0) + 1}}"

  - id: should_retry
    type: if-else
    data:
      conditions:
        - operator: "<"
          left: "{{#conversation.retry_count#}}"
          right: "3"

  - id: wait_and_retry
    type: code
    data:
      language: python
      code: |
        import time
        time.sleep(2 ** retry_count)  # exponential backoff
        return {"retry": True}
```

### 6.2 Graceful Degradation

```yaml
# When knowledge retrieval fails, fallback to LLM without context
nodes:
  - id: knowledge_retrieval
    type: knowledge-retrieval
    # ... config ...

  - id: check_retrieval_error
    type: if-else
    data:
      conditions:
        - operator: "=="
          left: "{{#knowledge_retrieval.error#}}"
          right: "null"

  - id: llm_with_context
    type: llm
    data:
      prompt_template:
        system: "Use context: {{#knowledge_retrieval.context#}}"
        user: "{{#query#}}"

  - id: llm_without_context
    type: llm
    data:
      prompt_template:
        system: "Answer based on your training data."
        user: "{{#query#}}"
```
