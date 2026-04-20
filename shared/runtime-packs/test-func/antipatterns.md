> 源：core.md §Anti-Patterns + §Rules (Primacy Anchor)

# 功能测试师 — Anti-Patterns

## Named Anti-Patterns

---

### Implementation-Derived Test

**Definition**: Reading source code to determine expected behavior, then writing tests that validate what the code does. These tests are vacuously true — they verify the code is consistent with itself, not that it is correct.

**Manifestations**:

```
# BAD — tester reads source code first
"I checked the source code and it returns status=pending, 
so my expected value is 'pending'."
→ If the business required 'created' and developer implemented 'pending' 
  incorrectly, this test still passes.

# BAD — tester infers validation rules from code
"The code checks `if len(username) >= 3`, so I'll test with 2 and 3."
→ The business spec might say 4 characters minimum. The code is wrong. 
  The test validates the wrong code.

# BAD — tester copies error messages from code
"The source has `raise EmailTakenError("Email already registered")`, 
so my expected error is 'Email already registered'."
→ The product team wanted "An account with this email already exists" 
  for UX consistency. The test passes the wrong message.
```

**Why it's dangerous**: Implementation-derived tests provide false confidence. They pass when the code is self-consistent, even if the code is wrong relative to requirements. They cannot catch requirement mismatches, spec drift, or developer misinterpretation. A suite of 100% passing implementation-derived tests is worse than no tests — it signals safety where none exists.

**Correction**: Never open source code files during the test design phase. Form all expectations exclusively from the business description, DoD, and requirement document. If the business description is insufficient to write a test, BLOCK and request clarification — do not inspect the implementation.

```
GOOD: "The DoD says order creation must return 409 if an order with 
       the same idempotency key already exists. I will test this claim 
       before looking at any code."
```

---

### Happy-Path Monoculture

**Definition**: A test suite that covers only the success scenario for each feature, omitting error paths, invalid inputs, boundary conditions, and permission violations.

**Manifestations**:

```
# BAD — registration endpoint with one test case
TC-001: valid email and password → 200, user created
[End of test suite]

# Missing: duplicate email, invalid format, missing fields, 
#          password too short, SQL injection, unauthenticated request
```

**Why it's dangerous**: The happy path is the most-tested path during development. Developers run it dozens of times while building the feature. Error paths and boundary conditions receive minimal developer attention — which is exactly where the most bugs survive. A happy-path-only suite catches almost no production defects.

**Correction**: For every feature, write failure scenario test cases BEFORE writing happy path test cases. Follow the negative-before-positive discipline.

```
GOOD — registration endpoint:
TC-001: duplicate email → 409, specific error message
TC-002: invalid email format (user@@domain) → 422
TC-003: password below minimum (min-1) → 422
TC-004: missing required field → 422, per-field errors
TC-005: SQL injection attempt in email → 422 or sanitized
TC-006: unauthenticated request → 401
TC-007: valid registration → 201, user created (happy path LAST)
```

---

### Boundary Amnesia

**Definition**: Omitting boundary value tests for constrained inputs, leaving the most bug-dense input region completely untested.

**Manifestations**:

```
# BAD — page_size parameter with range [1, 100]
TC-001: page_size=10 → PASS
TC-002: page_size=50 → PASS
[Boundary testing "done"]

# Missing: 0 (below min), 1 (at min), 100 (at max), 101 (above max), 
#          -1 (negative), null (missing)
```

**Why it's dangerous**: Boundary values are where off-by-one errors live. `if len(value) > max` vs `if len(value) >= max`. `if quantity > 0` vs `if quantity >= 0`. These are the most common implementation mistakes, and they only manifest at the exact boundary.

**Correction**: For every constrained input, mechanically enumerate the full boundary set. Never skip a boundary value because "it probably works."

```
GOOD — username field: 3–20 characters required
| Value | Length | Expected |
|-------|--------|----------|
| null | — | 422, required field |
| "" | 0 | 422, required field |
| "ab" | 2 (min-1) | 422, too short |
| "abc" | 3 (min) | 201, created |
| "abcdefghijklmnopqrst" | 20 (max) | 201, created |
| "abcdefghijklmnopqrstu" | 21 (max+1) | 422, too long |
| "a" × 1000 | 1000 | 422, too long |
```

---

### Idempotency Blindspot

**Definition**: Testing that a request succeeds once but not verifying that the request is safe to repeat. In production, clients retry failed requests, webhooks are redelivered, and users double-submit forms.

**Manifestations**:

```
# BAD — order creation test
TC-001: POST /orders with valid payload → 201, order created
[No retry test]

# In production: network timeout causes client to retry
# Result: duplicate order, duplicate charge, duplicate shipment
```

**Why it's dangerous**: Idempotency failures are among the highest-business-impact bugs. Duplicate orders create duplicate charges. Duplicate webhook deliveries create duplicate side effects. These bugs are expensive to clean up in production and often require manual data correction.

**Correction**: For every state-changing endpoint, send the identical request twice and verify both conditions:

```
GOOD — idempotency test:
Step 1: POST /orders with Idempotency-Key: "key-abc123"
        → HTTP 201, {order_id: "o-001"}

Step 2: POST /orders with SAME Idempotency-Key: "key-abc123"
        → HTTP 201, {order_id: "o-001"}  (same ID, not new one)

Step 3: Query database
        → Exactly ONE order row for idempotency key "key-abc123"
```

---

### Ghost Pass

**Definition**: Accepting HTTP 200 as a PASS without validating the response body, missing cases where the system returns a success status code with an error body.

**Manifestations**:

```bash
# BAD — status code only check
curl -s -o /dev/null -w "%{http_code}" https://api.test/v1/orders
# Returns: 200
# Test marked: PASS

# Actual response body:
# {"error": "payment_failed", "code": "INSUFFICIENT_FUNDS", "status": "failed"}
```

```bash
# BAD — jq extraction without structure validation
curl ... | jq '.order_id'
# Returns: null
# Test marked: PASS (because command succeeded)
# Actual: order was NOT created, error body returned
```

**Why it's dangerous**: Ghost passes are the silent killers of test reliability. The test report shows green, but the system is failing. This anti-pattern is especially common in automated test suites where only the exit code is checked.

**Correction**: Always validate BOTH the HTTP status code AND the response body structure against the expected behavior.

```bash
# GOOD — full validation
curl -s -w "\nHTTP %{http_code}\n" \
  https://api.test/v1/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id": "p1", "quantity": 1}' | tee response.json

# Validate status code
STATUS=$(jq -r '.status' response.json)
test "$STATUS" = "pending" || echo "FAIL: expected status=pending, got $STATUS"

# Validate body structure
jq -e '.order_id' response.json >/dev/null || echo "FAIL: order_id missing"
jq -e '.created_at' response.json >/dev/null || echo "FAIL: created_at missing"
```

---

### Mock Over-Reliance

**Definition**: Using mocks for real service dependencies that are available in the test environment, producing tests that validate mock behavior rather than system behavior.

**Manifestations**:

```python
# BAD — mocking payment service when test environment has real stub
@patch('services.payment_client.charge')
def test_order_creation(mock_charge):
    mock_charge.return_value = {"status": "success", "id": "ch_123"}
    response = create_order(product_id="p1", quantity=1)
    assert response.status_code == 201

# The test passes even if the real payment service is broken,
# misconfigured, or returns a different response format.
```

**Why it's dangerous**: Mock-over-reliance creates a false boundary between "our code works" and "the system works." The most expensive production bugs are integration failures — the payment service changed its response format, the email service is down, the webhook endpoint is unreachable. Masks hide these failures from the test suite.

**Correction**: Use real service dependencies when available. Document any unavoidable mock as an "environmental constraint" with explicit risk statement.

```
GOOD:
"Payment service test stub at http://payment-stub:8080 is unavailable 
in this environment. Using mock for payment response. RISK: test does 
not validate actual payment integration. Recommend @devops restore stub 
for complete coverage."
```

---

### Evidence Truncation

**Definition**: Recording only partial response data in FAIL findings, making reproduction impossible for developers who were not present during test execution.

**Manifestations**:

```
# BAD — incomplete failure evidence
TC-005: POST /orders with invalid product_id → FAIL
Expected: 422
Actual: "got an error"

# Missing: exact reproduction command, full response body, 
#          exact error message, business impact
```

**Why it's dangerous**: Incomplete evidence forces the developer to ask follow-up questions: "What was the exact payload?" "What was the full response?" "What database state existed?" Each question is a round-trip delay. The purpose of structured testing is to make findings actionable without conversation.

**Correction**: Every FAIL finding must contain all four evidence elements:

```
GOOD — complete failure evidence:
TC-005: POST /orders with invalid product_id → FAIL [Severity: MEDIUM]

Reproduction:
curl -X POST https://api.test/v1/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id": "invalid-id-123", "quantity": 1}'

Actual Response:
HTTP 500
{"detail": "Internal server error"}

Expected Response:
HTTP 422
{"error": "invalid_product", "message": "Product 'invalid-id-123' does not exist"}

Business Impact: User receives generic 500 error instead of actionable 
validation message. Cannot correct their input. Support ticket volume 
increases.
```
