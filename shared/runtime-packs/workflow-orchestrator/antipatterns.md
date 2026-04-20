> Source: core.md §Anti-Patterns + §Rules (Primacy Anchor)

# AI编排大师 — Anti-Patterns

## Named Anti-Patterns

---

### Platform-Agnostic Wishful

**Definition**: Designing workflows as if all platforms share the same node behavior, expression syntax, and error handling model. A platform-agnostic spec forces the implementer to make all platform-specific decisions that should have been in the spec.

**Manifestations**:
```
# BAD — platform-agnostic wishful
"Create an HTTP Request node that calls the Stripe API.
The workflow should work the same way whether we're using n8n or Dify."
```

```
# GOOD — n8n-specific
"HTTP Request node configured with:
- method: POST
- URL: https://api.stripe.com/v1/charges
- Authentication: Header Auth (credential name: 'Stripe-API-Key')
- Body Parameters: { amount: {{ $json.amount * 100 }}, currency: '{{ $json.currency }}' }
- Error handling: Enable 'Retry on Fail' (max 3 retries, wait 5000ms)
- On error: Error Trigger → Slack notification"
```

```
# GOOD — Dify-specific
"HTTP Request node configured with:
- method: POST
- url: https://api.stripe.com/v1/charges
- headers: { Authorization: 'Bearer {{#env.STRIPE_API_KEY#}}' }
- body: { amount: {{ amount * 100 }}, currency: '{{ currency }}' }
- Error handling: IF node checks {{#node_id.response.status_code#}} >= 500
  → retry loop (iteration node, max 3)
  → else: dead-letter Code node"
```

**Why it's dangerous**: "HTTP Request node" means entirely different things in n8n vs Dify vs Coze. "Retry mechanism" is an n8n workflow-level setting while Dify doesn't have native retry — you'd need an iteration node wrapping a Code node. A platform-agnostic spec forces the implementer to make all platform-specific decisions that should have been in the spec.

**Correction**: Name the target platform and use that platform's node names, expression syntax, and configuration vocabulary. Every node reference must be platform-specific.

---

### No Error Branch

**Definition**: A workflow with external call nodes and no error handling. The workflow "works" in testing (happy path only) and breaks silently in production.

**Manifestations**:
```
# BAD — no error branches
[Webhook] → [Transform] → [HTTP Request to Stripe] → [Update DB] → [Send Email]
# If Stripe call fails: failure is invisible
# If DB update fails: data inconsistency
# If email fails: user never knows
```

```
# GOOD — error branches designed simultaneously with happy path
[Webhook] → [Idempotency Check] → [Transform] → [HTTP Request to Stripe]
  Stripe success → [Update DB] → [Send Email]
  Stripe error → [IF 5xx: retry with backoff, else: dead-letter]
  DB error → [Rollback + Dead-letter + Alert]
  Email error → [Log warning, continue — email is non-critical]
```

**Why it's dangerous**: A workflow that only handles the happy path will break silently in production. When an external API returns 503, the workflow stops without notification. When a database write fails, data becomes inconsistent. The first sign of trouble is usually a user complaint or a data integrity issue discovered days later.

**Correction**: Every external call node gets an error branch before the workflow is considered complete. Error branches are first-class, designed simultaneously with the happy path, not added later.

---

### Hardcoded Credentials in Nodes

**Definition**: Embedding API keys, secrets, tokens, or passwords directly in HTTP Request node headers, body fields, or Code node scripts.

**Manifestations**:
```json
// BAD — n8n HTTP Request node with hardcoded API key
{
  "name": "Call Stripe API",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "headers": {
      "Authorization": "Bearer REPLACE_ME"  // FORBIDDEN
    }
  }
}
```

```yaml
# BAD — Dify DSL with inline API key
environment_variables:
  STRIPE_API_KEY: "REPLACE_ME"  # FORBIDDEN
```

```json
// GOOD — n8n referencing credential store
{
  "name": "Call Stripe API",
  "type": "n8n-nodes-base.httpRequest",
  "credentials": {
    "httpHeaderAuth": {
      "id": "stripe-api-key",
      "name": "Stripe-API-Key"
    }
  }
}
```

```yaml
# GOOD — Dify referencing environment variable
environment_variables:
  STRIPE_API_KEY: ""  # Set in Dify UI, not in YAML
```

**Why it's dangerous**: Workflow configs are shared, exported, and version-controlled. A hardcoded API key in a workflow JSON is a credential leak. When the workflow is exported for backup, sharing, or migration, the credential travels with it. Rotating the credential requires editing the workflow, not just the credential store.

**Correction**: Use the platform's credential store. Reference credentials by name, not by value. n8n: Credentials tab. Dify: Environment Variables in UI. Coze: Plugin settings. LangFlow: Global Variables.

---

### Single-Node God-Flow

**Definition**: Entire automation logic in a single Code node using the platform as an expensive script runner. When it fails, the error is "Code node failed at line 147" with no context.

**Manifestations**:
```javascript
// BAD — 200-line Code node in n8n doing everything
const axios = require('axios');
const crypto = require('crypto');
// ... 180 more lines of business logic ...
// Error: "Code node failed at line 147" — which API? which step?
```

```
# GOOD — decomposed into native nodes
[Webhook] → [Set: extract fields] → [HTTP Request: call API A]
  → [IF: check response] → [HTTP Request: call API B]
  → [Set: format output] → [Respond to Webhook]
```

**Why it's dangerous**: Code nodes have no platform-level observability. When a 200-line Code node fails, you get a line number and a stack trace — not a node-level execution log showing which API call failed, what the input was, or how many retries were attempted. The platform's value (visual debugging, node-level metrics, retry visibility) is completely lost.

**Correction**: Decompose into one HTTP Request node per API call, one Set node per data transformation, one IF node per conditional logic. Keep Code nodes under 50 lines. If the logic requires more than 50 lines, it's a backend service — route to @backend.

---

### No Idempotency Key

**Definition**: Webhook-triggered workflow without deduplication protection. Webhook delivery systems retry on network failure.

**Manifestations**:
```
# BAD — Webhook trigger with no idempotency check
[Webhook: Stripe payment.succeeded] → [Update order status to PAID]
  → [Send confirmation email] → [200 response]
# Stripe retries after 5s timeout → order updated twice → email sent twice
```

```
# GOOD — idempotency key check as first processing node
[Webhook: Stripe payment.succeeded]
  → [Set: extract event_id from body.id]
  → [Postgres: SELECT FROM stripe_events WHERE event_id = {{ event_id }}]
  → [IF: exists?]
    YES → [Respond: 200 "already processed"]
    NO → [Update order status] → [Insert event_id into stripe_events]
      → [Send email] → [200 response]
```

**Why it's dangerous**: Webhook delivery systems retry on network failure. A production Webhook integration will eventually receive a duplicate delivery. Without idempotency protection, duplicate deliveries produce duplicate side effects: duplicate records, duplicate emails, duplicate payments, duplicate inventory deductions.

**Correction**: Extract unique event ID from Webhook payload, check deduplication table/Redis key, skip if found, process and record if not. The idempotency check must be the FIRST processing node — before any state-changing operation.

---

### Credential Scope Creep

**Definition**: Using a single credential for multiple unrelated services, or using an admin/root credential where a scoped credential would suffice.

**Manifestations**:
```
# BAD — single "API-Key" credential used for Stripe, SendGrid, and internal API
# If one service is compromised, all three are exposed
```

```
# GOOD — scoped credentials with descriptive names
- Stripe-API-Key (restricted to payment endpoints)
- SendGrid-Bearer-Token (restricted to email send scope)
- Internal-API-Service-Account (restricted to order read/write)
```

**Why it's dangerous**: Credential scope creep means a compromise of one service exposes all services sharing the credential. It also makes credential rotation a high-risk operation — rotating the shared credential requires coordinating across all services.

**Correction**: Use separate credentials for each service. Use service accounts with minimum required permissions. Name credentials descriptively so their purpose is clear.
