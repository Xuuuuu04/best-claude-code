# AI编排大师 — Output Contract

## Standard Output Format

```
## Workflow Implementation Output

**Platform**: [n8n / Dify / Coze / LangFlow / Flowise]
**Workflow Name**: [name — one sentence description]
**Trigger Type**: [Webhook / Cron: schedule / Manual / API call / Conversation]
**Status**: READY-FOR-NEXT | BLOCKED | FAILED

**Deliverable Files**:
- Workflow config: [workflows/{name}.json or .yml]
- Node design doc: [docs/workflow-{name}-design.md]
- Prerequisites: [docs/workflow-{name}-prereqs.md]

**Workflow Topology** (DAG summary):
- Node count: [N total, M external call nodes, K conditional nodes]
- Critical path: [Trigger] → [Node A] → [Node B] → [Output]
- Error branches: [list each external call node and its error behavior]

**Error Handling Configuration**:
| External Call Node | Error Type | Strategy | Retry Config | Fallback |

**Idempotency Mechanism**: [Idempotency key / State guard / Natural UPSERT / N/A with rationale]

**Test Validation Results**:
- Happy path: [PASS/FAIL]
- Error path 1: [simulated failure → expected behavior → PASS/FAIL]
- Error path 2: [simulated failure → PASS/FAIL]
- Idempotency: [duplicate trigger simulation → PASS/FAIL (no duplicate created)]

**Prerequisites**:
- Credentials required: [list variable names and purpose]
- External services: [list APIs/databases/services]
- Platform setup: [any platform configuration before import]

**Next Step**: @test-func / @backend / @devops
```

---

## Filled Example: n8n Stripe Payment Fulfillment

```
## Workflow Implementation Output

**Platform**: n8n
**Workflow Name**: stripe-payment-order-fulfillment — fulfills orders when Stripe payment.succeeded fires
**Trigger Type**: Webhook (Stripe payment.succeeded event)
**Status**: READY-FOR-NEXT

**Deliverable Files**:
- Workflow config: workflows/stripe-payment-fulfillment.json
- Node design doc: docs/workflow-stripe-fulfillment-design.md
- Prerequisites: docs/workflow-stripe-fulfillment-prereqs.md

**Workflow Topology**:
- Node count: 9 total, 3 external call nodes, 2 conditional nodes
- Critical path: [Webhook] → [Idempotency Check] → [GET /orders/{id}] → [PATCH order status] → [POST /email/send] → [Respond 200]
- Error branches:
  - GET /orders: 5xx → retry 3× → dead-letter
  - PATCH order: any error → dead-letter + alert (CRITICAL)
  - POST /email: any error → log warning, continue

**Error Handling Configuration**:
| External Call Node | Error Type | Strategy | Retry Config | Fallback |
|---|---|---|---|---|
| GET /orders/{id} | HTTP 5xx | Retry | 3× / 2s,4s,8s | Dead-letter |
| UPDATE order status | DB error | Dead-letter + Alert | — | Slack alert (CRITICAL) |
| POST /email/send | HTTP error | Log warning | — | Continue (non-critical) |

**Idempotency Mechanism**: Idempotency key from `body.id` (Stripe event ID). Checked against `stripe_events` table UNIQUE constraint.

**Test Validation Results**:
- Happy path: PASS — order 123 status updated to PAID, confirmation email queued, 200 response in 1.8s
- Error path 1 (Stripe signature fails): PASS — 400 response, no processing, Slack alert
- Error path 2 (Order service 503): PASS — retried 3× (2s/4s/8s), dead-lettered, Slack alert
- Idempotency: PASS — duplicate Stripe event ID returns 200 "already processed", no duplicate DB writes

**Prerequisites**:
- Credentials: Stripe-Webhook-Secret, Order-Service-API-Key, Email-Service-Bearer, Main-DB
- External services: Stripe API, Order Service API, Email Service API
- Platform setup: n8n HTTPS endpoint for Stripe Webhook delivery; stripe_events table migration applied

**Next Step**: @test-func for end-to-end validation; @devops for production HTTPS Webhook endpoint
```

---

## Filled Example: Dify Customer Support RAG Bot

```
## Workflow Implementation Output

**Platform**: Dify
**Workflow Name**: customer-support-rag-bot — answers product questions with KB retrieval, escalates low-confidence queries
**Trigger Type**: Conversation (chat interface)
**Status**: READY-FOR-NEXT

**Deliverable Files**:
- Workflow config: workflows/customer-support-dify-dsl.yml
- Node design doc: docs/workflow-customer-support-design.md
- Prerequisites: docs/workflow-customer-support-prereqs.md

**Workflow Topology**:
- Node count: 7 total, 2 external call nodes, 2 conditional nodes
- Critical path: [Start] → [Knowledge Retrieval: product_kb] → [IF: score > 0.65]
  - High confidence → [LLM: answer with context] → [End]
  - Low confidence → [HTTP Request: Slack webhook] → [End: escalation message]
- Error branches:
  - Knowledge Retrieval failure → fallback to LLM without context
  - Slack HTTP failure → retry 2× → dead-letter + internal alert

**Error Handling Configuration**:
| External Call Node | Error Type | Strategy | Retry Config | Fallback |
|---|---|---|---|---|
| Knowledge Retrieval | Vector DB error | Graceful degradation | — | LLM without context |
| Slack HTTP Request | HTTP error | Retry | 2× / 60s | Dead-letter + alert |

**Idempotency Mechanism**: N/A — conversation flow is stateless per message; no Webhook trigger.

**Test Validation Results**:
- Happy path (common question): PASS — retrieved 3 chunks, LLM answered correctly, score 0.78
- Happy path (edge question): PASS — score 0.42, Slack escalation fired, fallback message returned
- Error path (KB down): PASS — graceful degradation, LLM answered from training data, logged warning
- Error path (Slack down): PASS — retried 2×, dead-lettered, internal alert sent

**Prerequisites**:
- Credentials: Dify OpenAI API key (for LLM node), Slack webhook URL in environment variables
- External services: OpenAI API, Slack webhook
- Platform setup: product_kb knowledge base uploaded and indexed; environment variable SLACK_ESCALATION_WEBHOOK configured

**Next Step**: @test-func for A/B testing score threshold tuning after 100 queries
```

---

## Output Component Requirements

### Workflow Topology Section

Must include:
1. **Node count**: Total nodes, external call nodes, conditional nodes
2. **Critical path**: Linear flow from trigger to output
3. **Error branches**: Per-external-call-node error behavior description
4. **Credential references**: List of credential names used

### Error Handling Configuration Table

Required columns:
- **External Call Node**: Which node can fail
- **Error Type**: What failure mode (HTTP 5xx, 4xx, timeout, auth failure)
- **Strategy**: Retry / Dead-letter / Fallback / Graceful degradation
- **Retry Config**: Count and backoff pattern (if applicable)
- **Fallback**: What happens when all retries exhausted

### Test Validation Results

Minimum 4 tests:
1. **Happy path**: Normal flow with valid data
2. **Error path 1**: Primary external API failure
3. **Error path 2**: Secondary failure or edge case
4. **Idempotency**: Duplicate trigger simulation (for Webhook workflows)

Each test must state: scenario → expected behavior → PASS/FAIL.

### Prerequisites Section

Must document:
1. **Credentials**: Name + purpose + scope (never values)
2. **External services**: API endpoints, database connections, webhooks
3. **Platform setup**: Any configuration required before import
4. **Database migrations**: If workflow reads/writes tables

---

## BLOCKED Output Format

When workflow cannot be implemented:

```
## Workflow Implementation Output

**Platform**: [n8n / Dify / Coze / LangFlow / Flowise]
**Workflow Name**: [name]
**Status**: BLOCKED

**Block Reason**: [specific condition preventing implementation]

**Blocked On**: [@ai-navigator / @dev-lead / @database / @backend / user]

**What is needed**:
1. [specific requirement 1]
2. [specific requirement 2]

**What I can do now**:
- [partial deliverable or design document that doesn't require the blocked item]

**Next Step**: [who needs to act and what they need to provide]
```
