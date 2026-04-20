# 功能测试师 — Domain 2: Test Execution

## 2.1 API Testing Tools

### 2.1.1 curl Patterns

**Basic authenticated GET**:
```bash
curl -s -X GET "https://api.test/v1/orders" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | jq '.'
```

**POST with body and status code capture**:
```bash
curl -s -w "\nHTTP %{http_code}\n" \
  -X POST "https://api.test/v1/orders" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id": "p-001", "quantity": 1}' | tee response.json
```

**Full verbose output (headers + body)**:
```bash
curl -v -X POST "https://api.test/v1/orders" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id": "p-001", "quantity": 1}' 2>&1 | tee response-full.txt
```

**Store token securely (avoid command history exposure)**:
```bash
# Set token in environment variable, not inline
export TOKEN="YOUR_TEST_TOKEN_HERE"

# Use in curl without exposing in history
curl -s -H "Authorization: Bearer $TOKEN" https://api.test/v1/orders
```

**Capture response headers specifically**:
```bash
curl -s -I -X GET "https://api.test/v1/orders" \
  -H "Authorization: Bearer $TOKEN" | tee headers.txt
```

### 2.1.2 Response Validation Patterns

**Field extraction with jq**:
```bash
# Extract single field
STATUS=$(curl -s ... | jq -r '.status')

# Extract nested field
USER_ID=$(curl -s ... | jq -r '.data.user.id')

# Inline assertion
test "$(curl -s ... | jq -r '.status')" = "pending" || echo "FAIL"
```

**Structure validation**:
```bash
# Verify field exists and is non-null
curl -s ... | jq -e '.order_id' > /dev/null || echo "FAIL: order_id missing"

# Verify array length
curl -s ... | jq '.items | length'  # should be >= 0

# Verify timestamp format
curl -s ... | jq -r '.created_at' | grep -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}T'
```

**Complex multi-step tests with Python**:
```python
import requests

session = requests.Session()
session.headers.update({"Authorization": f"Bearer {token}"})

# Step 1: Create
resp = session.post("/orders", json={"product_id": "p1", "quantity": 1})
assert resp.status_code == 201
order_id = resp.json()["order_id"]

# Step 2: Read
resp = session.get(f"/orders/{order_id}")
assert resp.status_code == 200
assert resp.json()["status"] == "pending"

# Step 3: Update
resp = session.patch(f"/orders/{order_id}", json={"status": "cancelled"})
assert resp.status_code == 200

# Step 4: Verify
resp = session.get(f"/orders/{order_id}")
assert resp.json()["status"] == "cancelled"
```

### 2.1.3 Database State Verification

**PostgreSQL**:
```bash
# After POST: verify row created
psql "$TEST_DB_URL" -c "SELECT id, status, amount FROM orders WHERE id = '$ORDER_ID'"

# After DELETE: verify row gone (hard delete)
psql "$TEST_DB_URL" -c "SELECT COUNT(*) FROM orders WHERE id = '$ORDER_ID'"
# Expected: 0

# After DELETE: verify soft delete
psql "$TEST_DB_URL" -c "SELECT deleted_at FROM orders WHERE id = '$ORDER_ID'"
# Expected: non-null timestamp

# Verify no duplicate records
psql "$TEST_DB_URL" -c "SELECT idempotency_key, COUNT(*) FROM orders GROUP BY idempotency_key HAVING COUNT(*) > 1"
# Expected: no rows
```

**MongoDB**:
```bash
# Verify document exists
mongosh "$TEST_MONGO_URL" --eval "db.orders.findOne({_id: ObjectId('$ORDER_ID')})"

# Verify document deleted
mongosh "$TEST_MONGO_URL" --eval "db.orders.findOne({_id: ObjectId('$ORDER_ID')})"
# Expected: null

# Verify array field
mongosh "$TEST_MONGO_URL" --eval "db.orders.findOne({_id: ObjectId('$ORDER_ID')}).items.length"
```

**MySQL**:
```bash
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" \
  -e "SELECT id, status FROM orders WHERE id = '$ORDER_ID'"
```

## 2.2 Evidence Collection

### 2.2.1 Reproduction Command Discipline

Every FAIL test case must have a reproduction command that satisfies three criteria:

1. **Copy-paste executable**: A developer who was not present can copy the command and run it
2. **Zero-state start**: Creates its own prerequisites (gets its own token, creates its own test data)
3. **Isolated**: Produces the failure without depending on other tests having been run

**Example — Good reproduction**:
```bash
# Prerequisites: none (self-contained)
# Get token
TOKEN=$(curl -s -X POST /auth/login \
  -d '{"email": "test@example.com", "password": "testpass123"}' | jq -r '.token')

# Create order (prerequisite for the bug)
ORDER_RESPONSE=$(curl -s -X POST /orders \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"product_id": "p-001", "quantity": 1}')
ORDER_ID=$(echo $ORDER_RESPONSE | jq -r '.order_id')

# Reproduce the bug: attempt to cancel already-shipped order
curl -s -w "\nHTTP %{http_code}\n" \
  -X PATCH "/orders/$ORDER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"status": "cancelled"}'
# Expected: 409
# Actual: 200 (BUG — allows cancelling shipped order)
```

**Example — Bad reproduction**:
```bash
# BAD — depends on external state, not self-contained
curl -X PATCH /orders/o-001 -d '{"status": "cancelled"}'
# Where did o-001 come from? What state is it in? Unknown.
```

### 2.2.2 Response Completeness

Never truncate the actual response in a FAIL finding.

**If response is small (< 50 lines)**: Include full response inline.

**If response is large (> 50 lines)**:
- Include relevant excerpt in the finding
- Attach full response in appendix
- Mark with `[FULL RESPONSE IN APPENDIX A]`

**Required response elements**:
- HTTP status code
- Full response body (JSON/XML/etc.)
- Relevant response headers (Content-Type, Location, Retry-After)
- Timestamp of request (for correlation with server logs)

### 2.2.3 Business Impact Classification

Every FAIL finding must state the business consequence:

| Impact Category | Description | Example |
|---|---|---|
| Revenue blocking | Prevents user from completing a paid action | "User cannot complete purchase — checkout returns 500" |
| Data integrity | Corrupts or duplicates data | "Duplicate orders created on retry — inventory count becomes incorrect" |
| Privacy violation | Exposes data to unauthorized users | "User can view other users' order history by changing ID in URL" |
| Operational error | Causes incorrect business decisions | "Report shows incorrect revenue due to double-counting" |
| User experience | Frustrates users without blocking | "Error message does not indicate which field is invalid" |
| Compliance | Violates regulatory requirement | "GDPR data export missing required fields" |

## 2.3 Anti-Hallucination Discipline

### 2.3.1 Response Trust

Only trust what actually appeared in the command output.

```
BAD: "The response probably contains an error field."
GOOD: "Response body: {\"status\": 500, \"detail\": \"Internal server error\"}"

BAD: "It seems like the order was created."
GOOD: "HTTP 201. Response body contains order_id: 'o-001'. Database query confirms row exists."
```

If tool output was truncated, mark it explicitly:
```
[TRUNCATED] — Full response not available. Only first 50 lines captured.
Do not infer content of truncated portion.
```

### 2.3.2 Status Code Extraction

Extract HTTP status code from actual response headers or curl's `%{http_code}` output. Do not infer from response body content.

```bash
# GOOD — explicit status capture
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" ...)
echo "HTTP Status: $STATUS_CODE"

# BAD — inferring from body
# Response body: {"error": "not_found"}
# Do NOT assume status is 404 — it might be 200 with error body
```

### 2.3.3 Uncertainty Acknowledgment

When tool output is ambiguous or environment behavior is unexpected, report `UNSURE` rather than guessing.

```
UNSURE: curl returned empty response body with HTTP 0. Could be:
- Network timeout (environmental)
- Server crash (functional bug)
- DNS resolution failure (environmental)

Recommendation: Re-run test after confirming network connectivity.
If reproducible, investigate server logs for crash evidence.
```

```
UNSURE: Response body contains "status": "unknown" which is not documented
in the business spec. Cannot classify as PASS (undocumented value) or FAIL
(might be valid internal state). Route to @dev-lead for spec clarification.
```

An `UNSURE` result is more honest and useful than a fabricated PASS or FAIL. Document the specific reason for uncertainty and the information needed to resolve it.
