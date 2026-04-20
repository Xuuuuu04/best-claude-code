# Domain: n8n Deep Expertise

## 1. Node Configuration Patterns

### 1.1 Webhook Trigger Node

```json
{
  "name": "Stripe Webhook",
  "type": "n8n-nodes-base.webhook",
  "webhookId": "stripe-payment",
  "parameters": {
    "httpMethod": "POST",
    "path": "stripe-payment-webhook",
    "responseMode": "responseNode",
    "options": {
      "rawBody": true
    }
  }
}
```

**Response modes**:
- `onReceived`: respond 200 immediately, continue workflow asynchronously
- `lastNode`: respond with last node's output
- `responseNode`: use Respond to Webhook node for explicit response control

**Authentication**:
- None: for internal/network-secured endpoints
- Basic Auth: username/password
- Header Auth: API key in header
- JWT: token verification

### 1.2 HTTP Request Node with Error Branch

```json
{
  "name": "Get Order",
  "type": "n8n-nodes-base.httpRequest",
  "parameters": {
    "method": "GET",
    "url": "={{ $env.ORDER_SERVICE_URL }}/orders/{{ $json.orderId }}",
    "authentication": "genericCredentialType",
    "genericAuthType": "httpHeaderAuth",
    "sendHeaders": true,
    "headerParameters": {
      "parameters": [
        {
          "name": "Authorization",
          "value": "={{ $credentials.httpHeaderAuth.value }}"
        }
      ]
    },
    "options": {
      "timeout": 10000
    }
  },
  "onError": "continueErrorOutput"
}
```

**Error output branch**: Set `onError` to `continueErrorOutput` to enable dual output (success/error).

### 1.3 IF Node for Conditional Branching

```json
{
  "name": "Check Status",
  "type": "n8n-nodes-base.if",
  "parameters": {
    "conditions": {
      "options": {
        "caseSensitive": true,
        "leftValue": "={{ $json.status }}",
        "operator": {
          "type": "string",
          "operation": "equals"
        },
        "rightValue": "active"
      }
    }
  }
}
```

### 1.4 Set Node for Data Transformation

```json
{
  "name": "Format Payload",
  "type": "n8n-nodes-base.set",
  "parameters": {
    "values": {
      "string": [
        {
          "name": "eventId",
          "value": "={{ $json.body.id }}"
        },
        {
          "name": "amount",
          "value": "={{ $json.body.amount / 100 }}"
        }
      ]
    }
  }
}
```

---

## 2. Expression Engine

### 2.1 Variable References

| Syntax | Meaning | Example |
|---|---|---|
| `$json` | Current node output | `{{ $json.status }}` |
| `$json.field.nested` | Deep path access | `{{ $json.customer.email }}` |
| `$node["NodeName"].json` | Specific node output | `{{ $node["Get Order"].json.id }}` |
| `$env.VAR_NAME` | Environment variable | `{{ $env.API_BASE_URL }}` |
| `$now` | Current datetime (Luxon) | `{{ $now.toISO() }}` |
| `$today` | Start of today | `{{ $today.toFormat('yyyy-MM-dd') }}` |

### 2.2 Array Operations

```
# Map: extract IDs
{{ $json.items.map(item => item.id) }}

# Filter: active items only
{{ $json.items.filter(item => item.status === 'active') }}

# Find: first matching item
{{ $json.items.find(item => item.id === '123') }}

# Reduce: sum amounts
{{ $json.items.reduce((sum, item) => sum + item.amount, 0) }}

# Length: count items
{{ $json.items.length }}
```

### 2.3 Date/Time Operations

```
# Format date
{{ $now.toFormat('yyyy-MM-dd HH:mm:ss') }}

# Add days
{{ $now.plus({ days: 7 }).toISO() }}

# Parse ISO string
{{ DateTime.fromISO($json.createdAt).toRelative() }}

# Check if expired
{{ DateTime.fromISO($json.expiresAt) < $now }}
```

---

## 3. Sub-Workflow Composition

### 3.1 Execute Workflow Node

```json
{
  "name": "Call Auth Refresh",
  "type": "n8n-nodes-base.executeWorkflow",
  "parameters": {
    "workflowId": "={{ $env.AUTH_REFRESH_WORKFLOW_ID }}",
    "options": {
      "waitForSubWorkflow": true
    }
  }
}
```

**Use cases**:
- Reusable authentication token refresh
- Shared validation logic across workflows
- Common error handling pattern

### 3.2 Error Trigger (Global Error Handler)

```json
{
  "name": "Error Trigger",
  "type": "n8n-nodes-base.errorTrigger",
  "parameters": {}
}
```

**Received payload**:
```json
{
  "workflow": {
    "id": "123",
    "name": "My Workflow"
  },
  "execution": {
    "id": "456",
    "url": "https://n8n.example.com/execution/456"
  },
  "error": {
    "message": "Node failed",
    "node": {
      "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest"
    }
  }
}
```

---

## 4. Performance and Scaling

### 4.1 Queue Mode Configuration

```bash
# .env
EXECUTIONS_MODE=queue
QUEUE_BULL_REDIS_HOST=redis.example.com
QUEUE_BULL_REDIS_PORT=6379
QUEUE_BULL_REDIS_DB=2

# Scale workers
N8N_CONCURRENCY_PRODUCTION_LIMIT=10
```

### 4.2 Execution Optimization

**Avoid large datasets**:
- Use Limit node: `limit: 100` before processing
- Use pagination in HTTP Request: `?page={{ $json.page }}&limit=50`
- Use database LIMIT: `SELECT * FROM orders LIMIT 100`

**Memory management**:
- Split in Batches: `batchSize: 10` for large arrays
- Delete unnecessary fields with Set node before passing downstream
- Avoid loading entire tables into workflow memory

---

## 5. Credential Management

### 5.1 Credential Types

| Type | Use Case | Auto-refresh |
|---|---|---|
| API Key | Simple key-based auth | No |
| OAuth2 | Google, Microsoft, etc. | Yes (token refresh) |
| Basic Auth | Username/password | No |
| HTTP Header Auth | Custom header tokens | No |
| JWT | Token-based auth | No |

### 5.2 Credential Reference in Workflow JSON

```json
{
  "credentials": {
    "httpHeaderAuth": {
      "id": "abc123",
      "name": "Stripe-API-Key"
    }
  }
}
```

**Important**: The `name` field is the human-readable name from the credential store. The actual secret value is NOT in the workflow JSON.

### 5.3 HMAC Signing in Code Node

```javascript
// Code node — signing logic only, NOT the secret
const crypto = require('crypto');

const secret = $credentials.hmacSecret.value; // from credential store
const payload = JSON.stringify($json);

const signature = crypto
  .createHmac('sha256', secret)
  .update(payload)
  .digest('hex');

return [{ signature, payload }];
```
