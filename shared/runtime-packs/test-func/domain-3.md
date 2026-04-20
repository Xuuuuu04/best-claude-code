# 功能测试师 — Domain 3: Test Reporting

## 3.1 Coverage Matrix Integrity

### 3.1.1 Eight-Dimension Accounting

Every test report must account for all eight coverage dimensions:

| Dimension | Description | Minimum Cases |
|---|---|---|
| Main flow | User successfully completes goal via standard path | 1 |
| Input validation | Valid/invalid inputs per field | 2+ per field |
| Boundary conditions | 0/1/min/max/max+1/negative/null/empty | 4+ per constraint |
| Permission matrix | Unauthenticated + each role × resource type | All combinations |
| Error handling | Dependency failures, malformed payloads, DB violations | 1+ per dependency |
| Idempotency | Repeat identical state-changing request | 1 per state-changing endpoint |
| Concurrency | Simultaneous requests for same resource | If applicable |
| E2E user journey | Full CRUD closure across multiple calls | 1 |

For each dimension, report one of:
- **Covered**: N test cases, PASS: M, FAIL: K
- **N/A**: [written justification]
- **Blocked**: [environmental reason]

An omitted dimension is an unreported gap.

### 3.1.2 Severity Classification

| Severity | Definition | Resolution Requirement |
|---|---|---|
| CRITICAL | Core user journey blocked; data loss; security concern | Must be fixed before any release |
| HIGH | Significant feature degraded; incorrect data returned | Must be fixed before release; workaround unacceptable |
| MEDIUM | Edge case failure with limited impact; workaround exists | Can be fixed post-release if independently fixable |
| LOW | Minor inconsistency; no functional impact | Post-release follow-up acceptable |

Severity must reflect business impact, not technical complexity.

**Examples**:
- CRITICAL: "User cannot complete purchase" — blocks revenue
- CRITICAL: "Duplicate charges on retry" — financial impact
- HIGH: "Wrong inventory count returned" — operational error
- HIGH: "Unauthorized access to other users' data" — privacy
- MEDIUM: "Validation error message unclear" — UX friction
- LOW: "Timestamp format inconsistent" — cosmetic

### 3.1.3 Regression Notation

When a test report is for a regression cycle, annotate previously failing cases:

```markdown
| Case ID | Description | Status | Notes |
|---|---|---|---|
| TC-003 | Idempotency — duplicate on retry | PASS | [Previously FAIL Round 1, now PASS] |
| TC-007 | Payment error handling | Still FAIL | [Previously FAIL Round 1, still FAIL — fix incomplete] |
```

## 3.2 Structural Report Quality

### 3.2.1 Traceability to Spec

Every test case should reference the specific requirement or DoD criterion:

```markdown
| Case ID | DoD Ref | Description |
|---|---|---|
| TC-001 | DoD-1 | POST /orders returns 201 with order_id |
| TC-004 | DoD-2 | Out-of-stock product returns 422 |
| TC-008 | DoD-3 | Same idempotency key returns original order |
```

### 3.2.2 Actionability of FAIL Findings

A FAIL finding is actionable if a developer who has not spoken to the tester can:

1. Reproduce the failure using only the information in the finding
2. Understand the expected behavior and why current behavior is wrong
3. Understand the business consequence of leaving the failure unfixed

**Actionability checklist**:
- [ ] Reproduction command is copy-paste executable
- [ ] All prerequisites are self-contained in the reproduction
- [ ] Expected behavior cites specific spec/DoD requirement
- [ ] Actual behavior shows exact response (status + body)
- [ ] Business impact explains user-facing consequence
- [ ] Severity classification guides prioritization

### 3.2.3 Recommendation Quality

The "next steps" recommendation must be specific:

```markdown
# BAD — vague recommendation
- FAIL cases → @backend

# GOOD — specific recommendation
- TC-003 (idempotency failure) → @backend: 
  Missing idempotency key check in POST /orders handler.
  Likely need to add unique constraint on idempotency_key column 
  and return existing order on duplicate key.
  
- TC-005 (permission check missing) → @backend:
  GET /orders/{id} does not verify resource ownership.
  Add owner_id check before returning order data.
  
- TC-007 (payment stub down) → @devops:
  Restore payment stub service at http://payment-stub:8080.
  Blocker for error handling test coverage.
```

## 3.3 Report Templates

### Full Test Suite Template

```markdown
## Functional Test Report: T-019 — Round 1

**Test Date**: 2026-04-21
**Test Environment**: https://api.staging.example.com
**Expectation Source**: docs/tasks/T-019.md, DoD v1.2
**Code Review Basis**: reviews/code-review-T-019-v1.md (APPROVED)

### Coverage Matrix

| Dimension | Status | Cases | PASS | FAIL | BLOCKED | Notes |
|---|---|---|---|---|---|---|
| Main flow | Covered | 3 | 3 | 0 | 0 | — |
| Input validation | Covered | 12 | 10 | 2 | 0 | — |
| Boundary conditions | Covered | 8 | 7 | 1 | 0 | — |
| Permission matrix | Covered | 6 | 4 | 2 | 0 | — |
| Error handling | Covered | 4 | 3 | 0 | 1 | Payment stub down |
| Idempotency | Covered | 2 | 1 | 1 | 0 | — |
| Concurrency | N/A | — | — | — | — | Single-writer, no contention |
| E2E user journey | Covered | 1 | 1 | 0 | 0 | CRUD closure complete |

**Summary**: 36 total cases — PASS: 29 / FAIL: 6 / BLOCKED: 1
**Pass Rate**: 80.6%

### Passing Cases (brief)

[Table of PASS cases]

### Failing Cases (detailed)

[Detailed FAIL findings with reproduction, expected, actual, business impact]

### Blocked Cases

[Environmental blockers with unblock conditions]

### Next Steps

[Specific routing with case IDs and target agents]
```

### Regression Template

```markdown
## Functional Test Report: T-019 — Round 2 (Regression)

**Regression Basis**: func-report-T-019-v1.md
**Previously Failing**: TC-003, TC-005, TC-007

### Regression Results

| Case ID | Previous | Current | Notes |
|---|---|---|---|
| TC-003 | FAIL R1 | PASS | Idempotency fixed |
| TC-005 | FAIL R1 | PASS | Permission check added |
| TC-007 | FAIL R1 | Still FAIL | Payment stub still down |

### Smoke Test

| Test | Status | Notes |
|---|---|---|
| Main flow POST /orders | PASS | No regression |

### Next Steps
- TC-007 → @devops: restore payment stub
- After unblock: re-run TC-007 only
- Then route to @test-lead
```

## 3.4 Pre-Submission Quality Checklist

Before routing the report to @test-lead, verify:

- [ ] Coverage matrix includes all 8 dimensions (or N/A with justification)
- [ ] Every FAIL has: reproduction command + actual response + expected response + business impact
- [ ] Every BLOCKED has: environmental reason + unblock condition + responsible agent
- [ ] Database state verified for all state-changing operations
- [ ] Test data cleaned up (or documented if persistent)
- [ ] Pass rate calculated and stated
- [ ] Next steps specify exact case IDs and target agents
- [ ] Report saved to: `tests/reports/func-report-{task-id}-v{N}.md`
- [ ] Severity classifications reflect business impact, not technical complexity
- [ ] Regression cases annotated with previous round status
