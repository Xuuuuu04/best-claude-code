# 测试总监师 — Domain 3: Evidence Quality Auditing

## 3.1 Test Report Audit

### 3.1.1 Coverage Matrix Completeness

The eight dimensions and their verification criteria:

| Dimension | Verification Criteria | Common Gap |
|---|---|---|
| Happy path | ≥1 test case for primary user goal | Missing entirely |
| Error paths | ≥1 test per error condition | Only happy path tested |
| Boundary conditions | 0/1/min/max/max+1/null/empty for each constraint | Missing max+1 or null |
| Auth/permission | 401 for unauth, 403 for unauthorized, 200 for authorized | Missing 403 cases |
| Concurrent access | Simultaneous requests if applicable | Always marked N/A without justification |
| Data persistence | DB state verified after state changes | Only API response checked |
| Integration points | External dependency behavior verified | Mocked without justification |
| Edge cases | Unusual but valid inputs | Missing empty arrays, unicode, very long strings |

**N/A justification requirements**:

A dimension marked N/A must have written justification:

```markdown
| Dimension | Status | Justification |
|---|---|---|
| Concurrency | N/A | Single-writer order creation; no concurrent resource contention possible by design |
| Idempotency | N/A | Read-only endpoint (GET); no state change to make idempotent |
```

Unjustified N/A = coverage gap = flag to @test-func.

### 3.1.2 Failed Test Case Evidence Chain

Every FAIL must be auditable:

```markdown
**Required elements**:
1. Exact reproduction steps
   - Copy-paste executable commands
   - Self-contained (creates own prerequisites)
   - Isolated (no dependency on other tests)

2. Actual response
   - HTTP status code
   - Full response body (not truncated)
   - Relevant headers
   - Timestamp

3. Expected behavior with source
   - Cites specific business requirement or DoD item
   - NOT derived from implementation
   - Traceable to documented spec

4. Business impact statement
   - User-facing consequence
   - Business consequence
   - Severity justification
```

**Evidence chain audit**:

| Element | Present? | Quality |
|---|---|---|
| Reproduction command | Yes/No | Executable? Self-contained? |
| Actual response | Yes/No | Complete? Not truncated? |
| Expected behavior | Yes/No | From spec? Not from code? |
| Business impact | Yes/No | Specific? Quantified? |

Any "No" or low quality = incomplete evidence = request @test-func to complete.

### 3.1.3 Expected Value Source Integrity

**Critical rule**: Expected behavior must trace back to documented business requirement, not to the implementation.

**Verification method**:
1. Read the expected behavior stated in the FAIL finding
2. Check if it cites a specific DoD item, requirement ID, or spec section
3. If it cites "source code shows..." or "implementation returns..." → flag as implementation-derived
4. Route to @test-func for correction

**Example — Good expected value source**:
```markdown
Expected: HTTP 422 with error code "product_unavailable"
Source: DoD item 2 — "Out-of-stock product returns 422 with product_unavailable error"
```

**Example — Bad expected value source**:
```markdown
Expected: HTTP 422 with error code "invalid_product"
Source: "The code checks for stock > 0 and returns invalid_product"
→ Implementation-derived! Flag and route to @test-func.
```

## 3.2 Verdict Traceability

### 3.2.1 PASS Traceability

A PASS verdict must reference:

```markdown
**Functional evidence**:
- N test cases covering which dimensions
- Pass rate and interpretation
- Specific test case IDs for core path verification

**UI evidence**:
- Screenshot directory path
- Five-state coverage confirmation
- Five-layer assessment results

**Security evidence**:
- Security audit file path
- Critical/High/Medium/Low counts
- OWASP coverage status
- Dependency scan status
```

**Example — traceable PASS**:
```markdown
PASS justified:
- Functional: 40/40 tests PASS (func-report-T031-v2.md)
  | Core path: TC-MF001 through TC-MF003 verified
  | Boundary values: TC-BV001 through TC-BV012 verified
  | Permission matrix: TC-PM001 through TC-PM006 verified
- UI: 5-state coverage confirmed (screenshots/T031-v2/)
  | All five layers PASS
- Security: 0 Critical, 0 High (security/audit-T031-v2.md)
  | OWASP Top 10 complete
  | Dependency scan: 0 critical vulnerabilities
```

### 3.2.2 BLOCKED Traceability

Every BLOCKED item must be independently actionable:

```markdown
**Required per item**:
1. Finding identifier
   - TC-NNN for functional test cases
   - SA-NNN for security audit findings
   - Screenshot filename for UI defects

2. Exact failure description
   - What is broken
   - How it was observed
   - Why it is a problem

3. Corrective action
   - What needs to be changed
   - How to verify the fix

4. Target agent
   - Who is responsible for the fix
   - Who verifies the fix
```

**Example — traceable BLOCKED**:
```markdown
Blocking items:

1. TC-019 | POST /api/orders returns 500 on empty cart
   | Failure: Server exception when cart.items is empty array
   | Corrective action: Add guard clause: if not cart.items or len(cart.items) == 0: return 422
   | Target: @backend
   | Verification: @test-func re-runs TC-019

2. SA-003 | Refresh token not invalidated on logout
   | Failure: Token remains valid after logout until natural expiry
   | Corrective action: Implement token blacklist table
   | Target: @backend (fix) + @security-auditor (verify)
```

### 3.2.3 CONDITIONAL PASS Traceability

Every CONDITIONAL PASS must have:

```markdown
**Required**:
1. Risk declaration
   - What defect is shipping in production
   - User impact
   - Business impact

2. Follow-up Task specifications
   - Description
   - Acceptance criterion
   - Target agent
   - Priority

3. Independence evidence
   - Why the follow-up is independently fixable
   - Why it doesn't block core functionality

4. Main path evidence
   - Evidence that core flow works despite follow-up items
```

**Example — traceable CONDITIONAL PASS**:
```markdown
CONDITIONAL PASS justified:

Risk declaration:
- Confirmation emails will not be delivered (TC-034)
  | User impact: No email confirmation after purchase
  | Business impact: Increased support tickets
  | Mitigation: Manual batch email until fix

Follow-up Tasks:
1. T-048 | Fix email delivery
   | Criterion: TC-034 passes (email within 60s)
   | Agent: @backend
   | Priority: P1

Independence evidence:
- Email service is separate microservice
- Order creation works correctly without email
- Can deploy email fix independently

Main path evidence:
- TC-MF001 through TC-MF003: order creation → payment → confirmation all PASS
- User sees success screen immediately after payment
```

## 3.3 Cross-Task Quality Patterns

### 3.3.1 Systemic Defect Identification

**Pattern**: Same defect category in three or more consecutive Tasks

**Examples**:
- Three consecutive Tasks have idempotency failures
- Three consecutive Tasks have missing permission checks
- Three consecutive Tasks have 500 errors on edge cases

**Action**:
```markdown
Flag to @pm:
"Pattern detected: idempotency failures in T-019, T-022, T-025.
Root cause likely: idempotency key handling not standardized across endpoints.
Recommendation: Architecture review of idempotency implementation.
Escalate to @architect."
```

### 3.3.2 Coverage Gap Patterns

**Pattern**: @test-func consistently missing same dimension

**Examples**:
- Permission matrix consistently missing 403 cases
- Boundary values consistently missing null/empty
- Error handling consistently missing dependency failure scenarios

**Action**:
```markdown
Flag to @pm:
"Coverage gap pattern: @test-func missing permission matrix 403 cases
in 4 of last 5 Tasks. Test protocol may need update.
Recommendation: Add permission matrix checklist to @test-func standard workflow."
```

### 3.3.3 Rework Rate Analysis

**Pattern**: Task through three+ BLOCKED verdicts without resolution

**Indicators**:
- Same root cause across multiple rounds
- Fix attempts introduce new failures
- Evidence quality degrades over rounds

**Action**:
```markdown
Flag to @pm:
"Rework alert: T-047 has received 4 BLOCKED verdicts across 6 weeks.
Root cause: authentication model keeps changing (JWT → session → JWT+refresh).
Recommendation: Scheme freeze and architecture review before further implementation.
Escalate to @architect and @dev-lead."
```

### Pattern Detection Thresholds

| Pattern | Threshold | Escalation Target |
|---|---|---|
| Systemic defect | 3+ consecutive Tasks | @pm → @architect |
| Coverage gap | 3+ of last 5 Tasks | @pm → update protocol |
| Rework rate | 3+ BLOCKED for same Task | @pm → @architect + @dev-lead |
| Security recurrence | Same vuln type in 2+ Tasks | @pm → @security-auditor |
