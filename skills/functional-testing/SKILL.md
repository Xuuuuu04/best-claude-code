---
name: functional-testing
description: Black-box functional testing methodology for the Harness team. Covers business-description oracle, eight-dimension coverage matrix, equivalence partitioning, boundary value analysis, state machine testing, decision table testing, E2E user journey, permission matrix testing, idempotency verification, error path verification, and structured test reporting. Loaded by @test-func via skills: frontmatter.
type: skill
---

# Functional Testing Skill

## 1. Business-Description Oracle

All test expectations must be formed from the requirement document, DoD, and business logic specification BEFORE writing any test case or running any command. NEVER read source code to determine expected behavior.

If the business description is insufficient to write the test → BLOCK and route to @dev-lead or @pm for clarification. Do not inspect source code.

## 2. Eight-Dimension Coverage Matrix

Every test suite must account for all eight dimensions:

| Dimension | Description | Failure-First Priority |
|---|---|---|
| Main flow | User successfully completes goal via standard path | Design failure scenarios first |
| Input validation | Valid range + invalid cases (type, format, length, null, empty) | Invalid before valid |
| Boundary values | 0/1/min/max/max+1/negative for every constrained field | Boundary is bug-dense |
| Permission matrix | Unauthenticated + each role + cross-tenant access | 403/401 cases are critical |
| Error handling | Dependent service unavailable, malformed payload, DB constraint violation | Error before success |
| Idempotency | Repeat identical state-changing request twice | Retry safety |
| Concurrency | Two simultaneous requests for same resource (if applicable) | Atomicity verification |
| E2E user journey | Minimum one full CRUD closure | System-level invariant check |

## 3. Boundary Value Analysis

For every constrained input, mechanically enumerate:
- Zero (0), One (1)
- Minimum minus one (min-1), Minimum (min), Minimum plus one (min+1)
- Maximum minus one (max-1), Maximum (max), Maximum plus one (max+1)
- Negative, Null, Empty string, Whitespace-only

Example: username 3–20 characters → test: `''`, `' '`, `'ab'` (2), `'abc'` (3), `'abcdefghijklmnopqrst'` (20), `'abcdefghijklmnopqrstu'` (21), null.

## 4. Test Execution Discipline

- **Serial execution only**: parallel tests introduce race conditions
- **Status code + body validation**: HTTP 200 with `{"error": "..."}` body = FAIL, not PASS
- **Database state verification**: after Create/Update/Delete, query DB directly. API responses can lie.
- **Real dependencies**: avoid mocking real services that are available. Mock = untested integration gap.
- **Evidence completeness**: every FAIL needs reproduction command + actual response + expected response + business impact

## 5. API Testing Patterns

```bash
# Primary curl pattern
curl -s -X POST https://api/v1/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id": "p1", "quantity": 1}' | jq '.'

# Capture status code alongside body
curl ... -w "\nHTTP %{http_code}\n"

# Database state verification (PostgreSQL)
psql $DB_URL -c "SELECT status, amount FROM orders WHERE id = '$ORDER_ID'"

# Database state verification (MongoDB)
mongosh --eval "db.orders.findOne({_id: ObjectId('...')})"
```

## 6. E2E User Journey (CRUD Closure)

Minimum E2E test pattern:
1. Create → verify resource exists
2. Read → verify all fields
3. Update → verify change persisted
4. Read again → verify updated state
5. Delete → verify resource gone (or soft-delete marker)
6. Read one more time → verify 404/empty response

Any gap in this closure is a gap in functional completeness.

## 7. Idempotency Testing

For every state-changing operation that may be retried:
1. Send identical request twice
2. Verify second response matches first (same status, same body)
3. Query database to confirm exactly one record (not two)

Production contexts: client retries, webhook redeliveries, user double-submits.

## 8. Permission Matrix Construction

For every API endpoint, enumerate all user roles + unauthenticated:
- Own resource: expected 200 with correct data
- Other's resource: expected 403
- Unauthenticated: expected 401
- Admin access to user's resource: expected 200

Missing 403/401 tests → IDOR and auth bypass bugs survive to production.

## 9. Failure Evidence Requirements

Every FAIL finding must contain:
1. **Exact reproduction command**: copy-paste executable, starts from zero state
2. **Full actual response**: status + body (not truncated)
3. **Expected response**: derived from business description with citation
4. **Business impact**: user-facing consequence (revenue block, privacy violation, data integrity, operational error)

## 10. Severity Classification

| Severity | Definition |
|---|---|
| **CRITICAL** | Core user journey blocked, data loss, security concern |
| **HIGH** | Significant feature degraded, incorrect data returned to users |
| **MEDIUM** | Edge case failure with limited user impact |
| **LOW** | Minor inconsistency that does not affect functionality |

## 11. Anti-Patterns

| Name | Symptom | Correction |
|---|---|---|
| **Implementation-Derived Test** | Reading source code to determine expected behavior | Form expectations from business description only |
| **Happy-Path Monoculture** | Only testing success scenarios | Design failure scenarios before success scenarios |
| **Boundary Amnesia** | Omitting boundary value tests | Mechanical enumeration: 0/1/min/max/max+1/negative/null/empty |
| **Idempotency Blindspot** | Testing once but not verifying retry safety | Send identical request twice, verify single record in DB |
| **Ghost Pass** | HTTP 200 accepted as PASS without body validation | Always validate status code AND response body |
