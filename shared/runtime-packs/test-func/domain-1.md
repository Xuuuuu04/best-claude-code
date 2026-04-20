# 功能测试师 — Domain 1: Test Design Methodology

## 1.1 Equivalence Partitioning and Boundary Analysis

### 1.1.1 Equivalence Class Design

Equivalence partitioning divides the input space into classes where all values in a class are expected to be treated identically by the system.

**Valid classes**: Inputs the system should accept and process correctly.
**Invalid classes**: Inputs the system should reject with a specific error.

Each invalid class gets its own test case because different validation code handles each failure mode.

**Example — Phone number field**:

| Class | Values | Expected |
|---|---|---|
| Valid | +8613800138000 (E.164, China) | Accept, process |
| Valid | +14155552671 (E.164, US) | Accept, process |
| Invalid — alphabetic | "abc123" | 422, invalid format |
| Invalid — special chars | "+86-138-0013-8000" | 422, invalid format |
| Invalid — too short | "+861" | 422, too short |
| Invalid — too long | "+861380013800012345" | 422, too long |
| Invalid — empty | "" | 422, required field |
| Invalid — null | null | 422, required field |

**Key principle**: One test per invalid class. Do not combine multiple invalid conditions in one test (unless testing combination behavior is the explicit goal) — when a test with multiple invalid inputs fails, you cannot tell which validation rule triggered the failure.

### 1.1.2 Boundary Value Enumeration

For every numeric or length-constrained input, test the exact boundary values:

| Boundary | Value | Expected |
|---|---|---|
| Zero | 0 | Depends on business rule |
| One | 1 | Often special case |
| Min - 1 | min - 1 | Should fail |
| Min | min | Should pass |
| Max | max | Should pass |
| Max + 1 | max + 1 | Should fail |
| Negative | -1 (or min negative) | Should fail |

**Example — `page_size` parameter with range [1, 100]**:

| Test | Value | Expected |
|---|---|---|
| TC-BV01 | 0 (below min) | 422, "page_size must be at least 1" |
| TC-BV02 | 1 (at min) | 200, 1 item per page |
| TC-BV03 | 100 (at max) | 200, 100 items per page |
| TC-BV04 | 101 (above max) | 422, "page_size must be at most 100" |
| TC-BV05 | null (missing) | 422, "page_size is required" |
| TC-BV06 | -1 (negative) | 422, "page_size must be positive" |

**Example — Username field: 3–20 characters**:

| Test | Value | Length | Expected |
|---|---|---|---|
| TC-BV07 | null | — | 422, required |
| TC-BV08 | "" | 0 | 422, required |
| TC-BV09 | "ab" | 2 (min-1) | 422, too short |
| TC-BV10 | "abc" | 3 (min) | 201, created |
| TC-BV11 | "abcdefghijklmnopqrst" | 20 (max) | 201, created |
| TC-BV12 | "abcdefghijklmnopqrstu" | 21 (max+1) | 422, too long |
| TC-BV13 | "a" × 1000 | 1000 | 422, too long |

### 1.1.3 Null and Empty Distinction

`null`, `""`, `" "`, and missing fields have different business semantics and often different validation paths. Test each separately for every required field.

| Value | JSON Representation | Semantics |
|---|---|---|
| null | `{"field": null}` | Explicitly null |
| Empty string | `{"field": ""}` | Provided but empty |
| Whitespace | `{"field": " "}` | Provided but whitespace-only |
| Missing | `{}` | Field absent from payload |

**Example — Required email field**:

```bash
# Test null
curl -X POST /register -d '{"email": null, "password": "valid123"}'
# Expected: 422, "email is required"

# Test empty string
curl -X POST /register -d '{"email": "", "password": "valid123"}'
# Expected: 422, "email is required"

# Test whitespace
curl -X POST /register -d '{"email": " ", "password": "valid123"}'
# Expected: 422, "email is required" (if trim applied) OR 422, "invalid email format"

# Test missing field
curl -X POST /register -d '{"password": "valid123"}'
# Expected: 422, "email is required"
```

## 1.2 State Machine and Decision Table

### 1.2.1 State Transition Coverage

For stateful resources (order, subscription, ticket), map all valid transitions AND all invalid transitions.

**Example — Order state machine**:

Valid transitions:
- pending → paid (payment confirmed)
- pending → cancelled (user cancels)
- paid → shipped (fulfillment)
- shipped → delivered (delivery confirmed)
- delivered → refunded (refund processed)

Invalid transitions (must be rejected):
- shipped → pending (cannot un-ship)
- cancelled → paid (cannot pay cancelled order)
- delivered → shipped (cannot un-deliver)
- pending → refunded (must be delivered first)

**Test design**:

```bash
# Valid transition: pending → paid
curl -X PATCH /orders/o-001 -d '{"status": "paid", "payment_id": "pay_123"}'
# Expected: 200, status updated to "paid"

# Invalid transition: shipped → pending
curl -X PATCH /orders/o-001 -d '{"status": "pending"}'
# Expected: 409, "Cannot transition from shipped to pending"
```

### 1.2.2 Decision Table for Multi-Condition Logic

When behavior depends on the combination of multiple conditions, enumerate significant combinations.

**Example — Resource access control**:

| Condition | Admin | Admin | Member | Member |
|---|---|---|---|---|
| Own resource? | Yes | No | Yes | No |
| Resource public? | — | Yes | — | Yes |
| Expected | 200, full data | 200, full data | 200, full data | 403 |

Test all four combinations explicitly.

### 1.2.3 User Journey Modeling

Start from the user's goal, not from the API endpoints.

**Example — "Buyer completes a purchase"**:

1. Authenticate → verify token received
2. Search products → verify results contain valid products
3. Add to cart → verify cart updated
4. Initiate payment → verify payment intent created
5. Confirm payment → verify payment success
6. Verify order status = "paid" → query GET /orders/{id}
7. Verify inventory decremented → query database

Each step has a verification sub-step. The journey is not complete until all sub-steps pass.

## 1.3 Coverage Dimension Matrix

### 1.3.1 Permission Matrix Construction

For every API endpoint, construct the full permission matrix:

| Role | Own Resource | Other's Resource | Admin-Visible | Expected |
|---|---|---|---|---|
| Unauthenticated | — | — | — | 401 |
| Admin | 200 | 200 | 200 | Full access |
| Member (owner) | 200 | — | — | Own data only |
| Member (other) | — | 403 | — | No cross-access |
| Guest | — | — | 200 (if public) | Public only |

**Critical rule**: Test the 403 and 401 cases explicitly. Missing these tests means IDOR (Insecure Direct Object Reference) and auth bypass bugs survive to production.

### 1.3.2 Idempotency Test Design

Identify all state-changing operations that may be retried:

1. POST operations that create resources
2. PATCH operations that update state
3. DELETE operations

For each:

```bash
# Step 1: First request
RESPONSE1=$(curl -s -X POST /orders -H "Idempotency-Key: key-abc" -d '{...}')
ID1=$(echo $RESPONSE1 | jq -r '.order_id')
STATUS1=$(echo $RESPONSE1 | jq -r '.status')

# Step 2: Identical second request
RESPONSE2=$(curl -s -X POST /orders -H "Idempotency-Key: key-abc" -d '{...}')
ID2=$(echo $RESPONSE2 | jq -r '.order_id')
STATUS2=$(echo $RESPONSE2 | jq -r '.status')

# Verification: same ID, same status
test "$ID1" = "$ID2" || echo "FAIL: idempotency violated"
test "$STATUS1" = "$STATUS2" || echo "FAIL: status mismatch"

# Database: exactly one record
COUNT=$(psql $DB -t -c "SELECT COUNT(*) FROM orders WHERE idempotency_key = 'key-abc'")
test "$COUNT" -eq 1 || echo "FAIL: duplicate records created"
```

### 1.3.3 Error Injection Design

For each external dependency, design error injection tests:

| Dependency | Failure Mode | Test Approach | Expected Behavior |
|---|---|---|---|
| Payment service | Timeout | Delay response > timeout threshold | 503 with retry-after header |
| Payment service | 500 error | Return 500 from stub | Graceful error, no duplicate charges |
| Email service | Unreachable | Stop email service container | Order succeeds, email queued for retry |
| Database | Connection lost | Kill DB connection mid-transaction | Transaction rolled back, no partial state |
| Third-party API | Rate limited | Return 429 | Backoff and retry, or graceful degradation |

**Error injection methods**:
- Mock/stub service: configure to return specific error responses
- Network-level: use toxiproxy or similar to introduce latency/packet loss
- Container-level: stop/restart dependency containers during test
