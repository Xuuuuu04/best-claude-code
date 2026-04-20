# 功能测试师 — Output Contract (Detailed)

## Report Structure

Every functional test engagement produces a structured report saved to `tests/reports/func-report-{task-id}-v{N}.md`.

### Header Block

```markdown
## Functional Test Report: [Task ID] — Round [N]

**Test Date**: [YYYY-MM-DD]
**Test Environment**: [API base URL / environment name]
**Expectation Source**: [Task document path + DoD reference]
**Code Review Basis**: [review report path confirming APPROVED]
**Tester**: [agent name / session ID]
```

### Coverage Matrix (Mandatory)

Every test report must account for all eight coverage dimensions:

```markdown
### Coverage Matrix

| Dimension | Status | Cases | PASS | FAIL | BLOCKED | Notes |
|---|---|---|---|---|---|---|
| Main flow | Covered | N | N | N | N | — |
| Input validation | Covered | N | N | N | N | — |
| Boundary conditions | Covered | N | N | N | N | — |
| Permission matrix | Covered | N | N | N | N | — |
| Error handling | Covered | N | N | N | N | — |
| Idempotency | Covered/N/A | N | N | N | N | [reason if N/A] |
| Concurrency | N/A | — | — | — | — | [reason] |
| E2E user journey | Covered | 1 | 1 | 0 | 0 | CRUD closure |

**Summary**: [N] total cases — PASS: [N] / FAIL: [N] / BLOCKED: [N]
**Pass Rate**: [N%]
```

Dimension status rules:
- **Covered**: at least one test case designed and executed for this dimension
- **N/A**: dimension does not apply to this feature; must include written justification
- **Blocked**: environmental issue prevented testing this dimension; must include blocker description

An omitted dimension is an unreported gap. @test-lead will flag missing dimensions.

### Passing Cases (Brief)

```markdown
### Passing Cases (brief)

| Case ID | Description | Status |
|---|---|---|
| TC-001 | POST /orders with valid payload → 201, order in DB | PASS |
| TC-002 | GET /orders/{id} with valid ID → 200, correct fields | PASS |
```

Keep passing cases brief. The detail belongs in FAIL findings.

### Failing Cases (Detailed)

Every FAIL case is a mini-report with four mandatory sections:

```markdown
### Failing Cases (detailed)

**[TC-003] Idempotency — Duplicate order on retry — FAIL** [Severity: HIGH]

**Specification basis**: DoD item 3: "Repeated POST /orders with same idempotency-key within 24h must return the original order, not create a new one."

**Reproduction**:
```bash
# Step 1: Create order
TOKEN="YOUR_TEST_TOKEN_HERE"  # test token for user test@example.com
curl -X POST https://api.test/v1/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: IDEMPOTENCY_KEY_PLACEHOLDER" \
  -d '{"product_id": "p-001", "quantity": 1}'
# Returns: HTTP 201, {"order_id": "o-001", "status": "pending"}

# Step 2: Repeat identical request
curl -X POST https://api.test/v1/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: IDEMPOTENCY_KEY_PLACEHOLDER" \
  -d '{"product_id": "p-001", "quantity": 1}'
# Returns: HTTP 201, {"order_id": "o-002", "status": "pending"}  ← different order_id

# Step 3: Verify database
psql $TEST_DB -c "SELECT id, status FROM orders WHERE user_id = 'u-test' ORDER BY created_at"
# Shows: TWO rows (o-001 and o-002) — idempotency not enforced
```

**Expected**: HTTP 201 with the SAME order_id (o-001). Database shows exactly ONE order row for this idempotency key.

**Actual**: HTTP 201 with a NEW order_id (o-002). Database shows TWO order rows.

**Business impact**: Retried payment requests (due to network timeout) will create duplicate charges. High severity — direct financial impact.
```

### Blocked Cases

```markdown
### Blocked Cases

**[TC-007] Error handling — payment service unavailable** — BLOCKED (Environmental)

The mock payment service at `http://payment-stub:8080` is not responding in the test environment. Unable to test graceful error handling. Notify @devops to restore the stub service.
```

### Next Steps

```markdown
### Next Steps

- FAIL cases → @backend: TC-003 (idempotency), TC-005 (missing permission check on GET /orders/{id})
- Environmental blocker → @devops: restore payment stub service
- After fixes: re-run TC-003, TC-005, TC-007 as regression
- Route final report → @test-lead for release verdict
```

## Severity Classification

| Severity | Criteria | Example |
|---|---|---|
| CRITICAL | Core user journey blocked; data loss or corruption; security concern (auth bypass, privilege escalation) | User cannot complete purchase; duplicate charges on retry; unauthorized access to other users' data |
| HIGH | Significant feature degraded; incorrect data returned to users; major business rule violation | Order status shows "paid" but payment failed; inventory count wrong; email sent to wrong recipient |
| MEDIUM | Edge case failure with limited user impact; workaround exists | Validation error message unclear; pagination offset off by one on page > 10 |
| LOW | Minor inconsistency that does not affect functionality; cosmetic issue | Error message capitalization inconsistent; timestamp format slightly off |

Severity must reflect business impact, not technical complexity. A one-line fix that prevents revenue loss is CRITICAL. A complex edge case that affects 0.01% of users is LOW.

## Regression Report Format

```markdown
## Functional Test Report: [Task ID] — Round [N] (Regression)

**Regression Basis**: func-report-[Task ID]-v[N-1].md
**Previously Failing Cases**: TC-003, TC-007

### Regression Results

| Case ID | Previous Status | Current Status | Notes |
|---|---|---|---|
| TC-003 | FAIL (Round 1) | PASS | Idempotency now enforced correctly |
| TC-007 | FAIL (Round 1) | Still FAIL — fix incomplete | Payment service error handling not yet addressed |

### Smoke Test

| Test | Status | Notes |
|---|---|---|
| Main flow: POST /orders happy path | PASS | No regression introduced by idempotency fix |

### Summary

1 of 2 previously failing cases resolved. 1 outstanding.

### Next Steps

- TC-007 → @backend: payment service error handling
- After TC-007 fix: re-run TC-007 only
- Then route to @test-lead
```

## curl Command Templates

### Basic GET with auth
```bash
curl -s -X GET "https://api.test/v1/orders" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | jq '.'
```

### POST with body and status capture
```bash
curl -s -w "\nHTTP %{http_code}\n" \
  -X POST "https://api.test/v1/orders" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id": "p-001", "quantity": 1}' | tee response.json
```

### Full response with headers
```bash
curl -v -X POST "https://api.test/v1/orders" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id": "p-001", "quantity": 1}' 2>&1 | tee response-full.txt
```

### Database verification (PostgreSQL)
```bash
psql "$TEST_DB_URL" -c "SELECT id, status, amount FROM orders WHERE user_id = 'u-test' ORDER BY created_at DESC LIMIT 5"
```

### Database verification (MongoDB)
```bash
mongosh "$TEST_MONGO_URL" --eval "db.orders.find({user_id: 'u-test'}).sort({created_at: -1}).limit(5)"
```

## Test Case ID Convention

Format: `TC-{category}{sequence}`

| Category | Code | Example |
|---|---|---|
| Main flow | MF | TC-MF001 |
| Input validation | IV | TC-IV003 |
| Boundary value | BV | TC-BV005 |
| Permission matrix | PM | TC-PM002 |
| Error handling | EH | TC-EH004 |
| Idempotency | ID | TC-ID001 |
| Concurrency | CO | TC-CO001 |
| E2E journey | E2E | TC-E2E001 |

## Quality Checklist (Pre-Submission)

Before routing the report to @test-lead, verify:

- [ ] Coverage matrix includes all 8 dimensions (or N/A with justification)
- [ ] Every FAIL has: reproduction command + actual response + expected response + business impact
- [ ] Every BLOCKED has: environmental reason + unblock condition + responsible agent
- [ ] Database state verified for all state-changing operations
- [ ] Test data cleaned up (or documented if persistent test fixtures)
- [ ] Pass rate calculated and stated
- [ ] Next steps specify exact case IDs and target agents
- [ ] Report saved to correct path: `tests/reports/func-report-{task-id}-v{N}.md`
