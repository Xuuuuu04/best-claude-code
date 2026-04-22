---
name: workflow-orchestration
description: AI and automation workflow orchestration methodology for the Harness team. Covers n8n (node-based, expressions, sub-workflows, queue mode), Dify (DSL YAML, LLM nodes, knowledge base RAG, agent nodes), Coze (bot platform, plugins, scheduled triggers), LangFlow (visual LangChain, component wiring), and Flowise (chain/agent composition). Includes error branch architecture (retry-with-backoff, dead-letter, circuit-breaker), idempotency patterns, and platform-native node preference discipline. Loaded by @workflow-orchestrator via skills: frontmatter.
type: skill
---

# Workflow Orchestration Skill

## 1. Platform Selection Matrix

| Platform | Best For | Key Strength |
|----------|----------|--------------|
| **n8n** | Enterprise automation, high-volume Webhook processing | 400+ native nodes, sub-workflows, queue mode, self-hosted |
| **Dify** | LLM app orchestration, RAG pipelines, agent workflows | DSL YAML, knowledge retrieval, conversation memory |
| **Coze** | Bot platforms, plugin ecosystem, rapid prototyping | Bot personas, custom OpenAPI plugins, scheduled triggers |
| **LangFlow** | Visual LangChain prototyping, component wiring | Typed ports, prompt templates, retriever integration |
| **Flowise** | Chain/agent composition, vector store integration | MultiPromptChain, Chatflow memory, tool configuration |

## 2. Node Design Discipline

Every node is a contract before connection:
1. **Purpose**: what business function does this node perform?
2. **Input contract**: what data does it expect? what format?
3. **Output contract**: what data does it produce?
4. **Failure behavior**: retry? fallback? alert?

**Platform-native preference**: Native nodes have platform-level observability (execution logs, retry visibility, node-level error reporting). Custom Code nodes lose observability and increase maintenance burden. Question before writing custom code: "is there a combination of native nodes that accomplishes this?"

**Code node limit**: 50 lines max. Above 50 lines → route to @backend for an API the workflow can call.

## 3. n8n Deep Expertise

**Expression engine**: `$json` = current node output; `$json.field.nested` for deep path; `$node["NodeName"].json` for specific previous node; `$env.VARIABLE_NAME` for env vars; `$now` for current datetime; array methods: `.map()`, `.filter()`, `.length`.

**Sub-workflows**: Execute Workflow node calls workflow by ID, passes data via `inputData`, receives output synchronously; error bubbling propagates to parent by default.

**Error Trigger**: Activates when any node in a different workflow throws an error; receives `workflowId`, `executionId`, `nodeType`, `message`; use case: single "global error alerter" workflow.

**Queue mode**: `EXECUTIONS_MODE=queue` + Redis for worker-based concurrent execution; each execution is a Bull queue job; multiple Worker instances pick up jobs.

**Credential management**: Referenced by name in HTTP Request node; never exported in workflow JSON; types: HTTP Header Auth, OAuth2, API Key, Basic Auth.

## 4. Dify / Coze / LangFlow / Flowise

**Dify DSL YAML**: `app.mode` (workflow/chatbot/agent), `graph.nodes[]` (id, type, data), `graph.edges[]` (connections); node types: llm, code, if-else, iteration, http-request, knowledge-retrieval, end, start, variable-assigner, template-transform.

**Dify LLM node**: Model selection per node (not global); Jinja2 templating (`{{variable}}`); structured output with JSON Schema; memory types: ConversationBufferMemory window / full history / summary.

**Dify RAG**: Document upload → chunking (fixed size / paragraph / markdown section) → embedding → vector index; retrieval: `query`, `retrieval_mode` (semantic/full-text/hybrid), `top_k`, `score_threshold`.

**Coze bot**: Persona (system prompt), knowledge (RAG files), skills (plugins), opening (welcome + suggested questions); variables: `{{bot.xxx}}` (bot-level), `{{user.xxx}}` (user-level persistent).

**LangFlow**: Components connected via typed ports; Chat Input → LLM Chain → Chat Output is minimal chat flow; add Retriever for RAG, Memory for conversation history.

**Flowise**: Sequential Chain, Router Chain, MultiPromptChain, LLMChain; Chatflow mode enables Memory; Agent receives Tool nodes with descriptions (name + description + schema) for LLM tool selection.

## 5. Error Branch Architecture

Every external call node spawns two branches: success (normal flow) and error (failure flow).

**Retry with backoff**: For transient errors (HTTP 429, 503, timeout): retry N times (default 3) with exponential backoff (2^n seconds starting at 2s); add jitter (±20%) to prevent synchronized bursts; never retry on 4xx except 429.

**Dead-letter queue**: For permanent errors (invalid data, auth failure, business logic rejection): do not retry; serialize failed payload + error + timestamp to dead-letter; trigger alert; available for manual review.

**Circuit breaker**: Track failure rate over rolling window (e.g., 5 failures in 60s); when exceeded, open circuit — subsequent calls fail immediately; after cool-down, probe with single request (half-open); on success, close circuit.

## 6. Idempotency Patterns

**Idempotency Key Check**: Extract unique ID from Webhook payload → check deduplication store → skip if found, process and record if not.

**State Machine Guard**: Check current entity state before modifying (if order already "PAID", do not reprocess).

**Natural Idempotency**: Final operation is PUT/UPSERT rather than POST (last write wins).

Every Webhook-triggered workflow MUST implement one of these three patterns.

## 7. Credential Discipline

All credentials reference the platform's credential store by name. Config files must be safe to export and share.

BAD — inline credentials:
```json
{ "headers": { "Authorization": "Bearer sk-abc123" } }
```

GOOD — named credential reference:
```json
{ "authentication": { "type": "headerAuth", "name": "Stripe-API-Key" } }
```

## 8. Anti-Patterns

| Name | Symptom | Correction |
|------|---------|------------|
| **Platform-Agnostic Wishful** | Designing as if all platforms share node behavior | Name target platform, use its node names and expression syntax |
| **No Error Branch** | External call nodes without error handling | Every external call gets error branch before workflow is complete |
| **Hardcoded Credentials** | API keys embedded in HTTP Request headers | Use platform credential store, reference by name |
| **God-Flow** | Entire logic in single Code node | Decompose into native nodes; keep Code nodes under 50 lines |
| **No Idempotency Key** | Webhook workflow without deduplication | Implement idempotency key check, state guard, or natural UPSERT |
