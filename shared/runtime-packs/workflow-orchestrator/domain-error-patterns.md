# Domain: Error Handling, Idempotency, and Integration Patterns

## 1. Error Branch Architecture

### 1.1 Retry-with-Backoff

**Configuration for n8n HTTP Request node**:
```json
{
  "name": "API Call with Retry",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "options": {
      "timeout": 10000
    }
  },
  "retryOnFail": true,
  "maxTries": 3,
  "waitBetweenTries": 5000
}
```

**Manual retry loop (for platforms without native retry)**:
```
[External Call] → [IF: success?]
  YES → [Continue]
  NO → [Set: retry_count += 1]
    → [IF: retry_count < 3?]
      YES → [Wait: 2^retry_count seconds] → [Retry External Call]
      NO → [Dead-letter]
```

**Backoff formula**:
```
delay = base_delay * (2 ^ attempt) + jitter

# Example with base_delay = 2s, jitter = ±20%
Attempt 1: 2s + jitter → 1.6s - 2.4s
Attempt 2: 4s + jitter → 3.2s - 4.8s
Attempt 3: 8s + jitter → 6.4s - 9.6s
```

### 1.2 Dead-Letter Queue Pattern

**n8n implementation**:
```json
{
  "name": "Dead Letter",
  "type": "n8n-nodes-base.postgres",
  "parameters": {
    "operation": "insert",
    "table": "dead_letter_queue",
    "columns": {
      "workflow_id": "={{ $workflow.id }}",
      "execution_id": "={{ $execution.id }}",
      "node_name": "={{ $json.error.node }}",
      "error_message": "={{ $json.error.message }}",
      "payload": "={{ JSON.stringify($json.payload) }}",
      "created_at": "={{ $now.toISO() }}"
    }
  }
}
```

**Dead-letter table schema**:
```sql
CREATE TABLE dead_letter_queue (
    id SERIAL PRIMARY KEY,
    workflow_id VARCHAR(255) NOT NULL,
    execution_id VARCHAR(255) NOT NULL,
    node_name VARCHAR(255) NOT NULL,
    error_message TEXT,
    payload JSONB,
    retry_count INT DEFAULT 0,
    status VARCHAR(50) DEFAULT 'pending', -- pending | retried | resolved | failed
    created_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP
);
```

### 1.3 Circuit Breaker Pattern

**Redis-based implementation in n8n Code node**:
```javascript
// Code node: Circuit breaker check
const redis = require('ioredis');
const client = new redis($env.REDIS_URL);

const SERVICE_KEY = 'circuit:payment_api';
const FAILURE_THRESHOLD = 5;
const WINDOW_SECONDS = 60;
const COOLDOWN_SECONDS = 30;

async function checkCircuit() {
  const state = await client.get(`${SERVICE_KEY}:state`);
  
  if (state === 'OPEN') {
    const openedAt = await client.get(`${SERVICE_KEY}:opened_at`);
    const elapsed = Date.now() - parseInt(openedAt);
    
    if (elapsed < COOLDOWN_SECONDS * 1000) {
      return { status: 'OPEN', canCall: false };
    }
    
    // Transition to HALF-OPEN
    await client.set(`${SERVICE_KEY}:state`, 'HALF-OPEN');
    return { status: 'HALF-OPEN', canCall: true };
  }
  
  return { status: state || 'CLOSED', canCall: true };
}

return [await checkCircuit()];
```

**Circuit breaker states**:
```
CLOSED → normal operation
  ↑         ↓ (5 failures in 60s)
  └──── HALF-OPEN ←─┘
            ↓ (1 success)
          OPEN (30s cooldown)
```

---

## 2. Idempotency Patterns

### 2.1 Idempotency Key Check

**n8n implementation with Postgres**:
```
[Webhook] → [Set: extract event_id]
  → [Postgres: SELECT COUNT(*) FROM processed_events WHERE event_id = {{ event_id }}]
    → [IF: count > 0?]
      YES → [Respond: 200 "already processed"]
      NO → [Process business logic]
        → [Postgres: INSERT INTO processed_events (event_id, processed_at)]
        → [Respond: 200 "success"]
```

**Processed events table**:
```sql
CREATE TABLE processed_events (
    event_id VARCHAR(255) PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    payload_hash VARCHAR(64),
    processed_at TIMESTAMP DEFAULT NOW(),
    response_status INT
);

-- Auto-cleanup old records
CREATE INDEX idx_processed_events_at ON processed_events(processed_at);
```

### 2.2 State Machine Guard

**Order status transition guard**:
```javascript
// Code node: State machine guard
const allowedTransitions = {
  'PENDING': ['PAID', 'CANCELLED'],
  'PAID': ['SHIPPED', 'REFUNDED'],
  'SHIPPED': ['DELIVERED', 'RETURNED'],
  'DELIVERED': ['RETURNED'],
  'CANCELLED': [],
  'REFUNDED': [],
  'RETURNED': []
};

const currentStatus = $json.currentStatus;
const targetStatus = $json.targetStatus;

if (!allowedTransitions[currentStatus]?.includes(targetStatus)) {
  return [{
    error: `Invalid transition: ${currentStatus} → ${targetStatus}`,
    canProceed: false
  }];
}

return [{ canProceed: true }];
```

### 2.3 Natural Idempotency (UPSERT)

**n8n Postgres node**:
```json
{
  "name": "Upsert Order",
  "type": "n8n-nodes-base.postgres",
  "parameters": {
    "operation": "executeQuery",
    "query": "INSERT INTO orders (id, status, updated_at) VALUES ({{ $json.orderId }}, {{ $json.status }}, NOW()) ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status, updated_at = NOW() WHERE orders.status != EXCLUDED.status"
  }
}
```

---

## 3. Data Mapping and Transformation

### 3.1 Platform Expression Syntax Comparison

| Operation | n8n | Dify (Jinja2) | Coze | LangFlow |
|---|---|---|---|---|
| Access field | `{{ $json.field }}` | `{{#node.field#}}` | `{{input.field}}` | `{{node.output}}` |
| Array map | `{{ $json.items.map(i => i.id) }}` | `{{ items | map(attribute='id') | list }}` | `{{input.items}}` | N/A |
| Filter | `{{ $json.items.filter(i => i.active) }}` | `{{ items | selectattr('active') | list }}` | Code node | N/A |
| Date format | `{{ $now.toFormat('yyyy-MM-dd') }}` | `{{ now | date('Y-m-d') }}` | Code node | N/A |
| Conditional | `{{ $json.status === 'active' ? 'yes' : 'no' }}` | `{% if status == 'active' %}yes{% else %}no{% endif %}` | Condition node | N/A |

### 3.2 Batch Processing Pattern

**n8n Split in Batches**:
```json
{
  "name": "Process Batch",
  "type": "n8n-nodes-base.splitInBatches",
  "parameters": {
    "batchSize": 10,
    "options": {
      "reset": false
    }
  }
}
```

**Flow**:
```
[Get All Items] → [Split in Batches: 10]
  → [Process Item] → [Merge: Append]
  → [Continue] → [Next Batch]
```

### 3.3 Aggregation Pattern

**n8n Merge node configurations**:

| Mode | Behavior | Use Case |
|---|---|---|
| `append` | Collect all items from all branches | Gather results from parallel processing |
| `combine` | Merge fields from multiple branches by key | Join data from different sources |
| `chooseBranch` | Select which branch continues | Conditional routing |

---

## 4. Webhook Security Patterns

### 4.1 Signature Verification (Stripe-style)

```javascript
// Code node: HMAC signature verification
const crypto = require('crypto');

const secret = $credentials.webhookSecret.value;
const signature = $headers['stripe-signature'];
const payload = $body;

const expected = crypto
  .createHmac('sha256', secret)
  .update(payload, 'utf8')
  .digest('hex');

if (!crypto.timingSafeEqual(
  Buffer.from(signature),
  Buffer.from(expected)
)) {
  return [{ verified: false, error: 'Invalid signature' }];
}

return [{ verified: true }];
```

### 4.2 Replay Attack Prevention

```javascript
// Code node: Timestamp validation
const timestamp = parseInt($headers['x-webhook-timestamp']);
const now = Math.floor(Date.now() / 1000);
const tolerance = 300; // 5 minutes

if (Math.abs(now - timestamp) > tolerance) {
  return [{ valid: false, error: 'Timestamp too old' }];
}

return [{ valid: true }];
```

---

## 5. Credential Management Patterns

### 5.1 Credential Rotation Strategy

```
Phase 1: Generate new credential
Phase 2: Update workflow to reference new credential name
Phase 3: Test workflow with new credential
Phase 4: Deprecate old credential (30-day grace period)
Phase 5: Remove old credential
```

### 5.2 Environment-Specific Credentials

| Environment | Credential Name Pattern | Example |
|---|---|---|
| Development | `{service}-dev` | `Stripe-API-Key-Dev` |
| Staging | `{service}-staging` | `Stripe-API-Key-Staging` |
| Production | `{service}-prod` | `Stripe-API-Key-Prod` |

### 5.3 Credential Scope Matrix

| Service | Read Scope | Write Scope | Admin Scope |
|---|---|---|---|
| Order API | `orders:read` | `orders:write` | `orders:admin` |
| Email API | `email:read` | `email:send` | `email:admin` |
| User API | `users:read` | `users:write` | `users:admin` |
