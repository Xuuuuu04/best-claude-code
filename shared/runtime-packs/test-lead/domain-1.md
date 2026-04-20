# 测试总监师 — Domain 1: Verdict Judgment

## 1.1 Three-Evidence Synthesis

### 1.1.1 Functional Report Audit

**Coverage matrix completeness**:

Verify the test report accounts for all eight dimensions:

| Dimension | Minimum Expectation | Flag If |
|---|---|---|
| Main flow | ≥1 test case | Missing |
| Input validation | ≥2 per field | Missing or insufficient |
| Boundary conditions | ≥4 per constraint | Missing |
| Permission matrix | All role combinations | Missing 401/403 tests |
| Error handling | ≥1 per dependency | Missing |
| Idempotency | ≥1 per state-changing endpoint | Missing without justification |
| Concurrency | If applicable | Missing without N/A justification |
| E2E journey | ≥1 CRUD closure | Missing |

Any dimension marked N/A must have written justification. An omitted dimension is an unreported gap.

**Failed test case evidence chain sufficiency**:

Every FAIL must have:
1. Exact reproduction steps (copy-paste executable)
2. Actual response (status + full body)
3. Expected behavior with source (business spec/DoD — not implementation)
4. Business impact statement

If any element is missing, the FAIL finding is incomplete. Flag to @test-func for evidence completion.

**Pass rate interpretation**:

| Pass Rate | Interpretation | Typical Verdict |
|---|---|---|
| 100% | All tests pass | PASS candidate |
| 95-99% | Minor edge cases fail | CONDITIONAL PASS candidate |
| 80-94% | Significant issues, core path may be affected | CONDITIONAL PASS or BLOCKED |
| <80% | Fundamental issues | BLOCKED |

Pass rate alone does not determine verdict. A 100% pass rate with shallow coverage is worse than a 95% pass rate with thorough coverage.

### 1.1.2 UI Screenshot Audit

**Five-layer assessment**:

| Layer | What to Check | Evidence Reference |
|---|---|---|
| Layout | Visual hierarchy, alignment, spacing, whitespace | Screenshot files |
| Visual | Color accuracy vs design tokens, contrast ratios | Screenshot + token file |
| Interaction | Button states, feedback visibility, error clarity | Screenshot + checklist |
| Content | Text truncation, placeholder copy, data formats | Screenshot |
| Holistic | Mobile viewport, professionalism, completeness | All screenshots |

**Five-state verification**:

Every page must have evidence for: initial, empty, loading, success, error.

| State | What It Shows | Missing Risk |
|---|---|---|
| Initial | First load, no interaction | Layout defects at first impression |
| Empty | No data state | Empty state missing or broken |
| Loading | Async operation | Loading UI defects |
| Success | Operation completed | Success feedback missing |
| Error | Failure state | Error handling broken |

**Mobile viewport non-negotiable**:

- Screenshots at 375×667 mandatory
- Navigation must be usable
- Form fields must be fillable
- CTA must be within thumb reach
- Text must be readable without zoom

### 1.1.3 Security Audit Evaluation

**Critical/High finding triage**:

Any unresolved Critical or High finding = unconditional BLOCKED. No exceptions.

| Finding Level | Action | Justification Allowed? |
|---|---|---|
| Critical | BLOCKED | No |
| High | BLOCKED | No |
| Medium | CONDITIONAL PASS candidate | Yes, with risk acceptance |
| Low | PASS or CONDITIONAL PASS | Yes |

**OWASP Top 10 completeness** (pre-launch mandatory):

Verify the security audit addresses:
1. Injection (SQL, NoSQL, OS command)
2. Broken Authentication
3. Sensitive Data Exposure
4. XML External Entities (XXE)
5. Broken Access Control
6. Security Misconfiguration
7. Cross-Site Scripting (XSS)
8. Insecure Deserialization
9. Using Components with Known Vulnerabilities
10. Insufficient Logging and Monitoring

**Dependency scan verification**:

Confirm the audit includes:
- Dependency scan was executed (not just asserted)
- Scan tool identified (Snyk, OWASP Dependency-Check, etc.)
- Critical/high vulnerability count
- Remediation status for each

## 1.2 Severity Classification

### 1.2.1 Critical

**Criteria**:
- Any security Critical or High finding
- Complete core flow failure (user cannot accomplish primary goal)
- Data integrity risk (corruption, loss, unauthorized modification)
- Authentication bypass or privilege escalation

**Examples**:
- "Any user can access admin dashboard by changing URL"
- "Payment processed but order not created — money taken, no record"
- "SQL injection allows arbitrary data access"
- "Refresh token not invalidated on logout — session hijacking possible"

**Verdict impact**: Unconditional BLOCKED

### 1.2.2 High

**Criteria**:
- Non-core feature completely non-functional
- UI unusable for significant user portion
- High security finding
- Performance degradation making core flows unusable (P99 > 10× SLA)

**Examples**:
- "Search returns no results for all queries"
- "Mobile checkout button not clickable on iOS Safari"
- "CSRF protection missing on state-changing endpoints"
- "Page load time > 30 seconds on 4G"

**Verdict impact**: Strong BLOCKED

### 1.2.3 Medium/Low

**Medium criteria**:
- Non-core defect with documented workaround
- UI cosmetic issue
- Medium security with no realistic exploit
- Edge case failure with limited user impact

**Low criteria**:
- Text copy errors
- Minor visual misalignment
- Edge-case failures in low-frequency flows

**Verdict impact**: CONDITIONAL PASS candidate (if independently fixable)

## 1.3 Conditional Pass Design

### 1.3.1 Independence Test

A follow-up item passes the independence test if ALL of the following are true:

1. **Code isolation**: Fixing it does not require modifying core flow code
   ```
   PASS: Email delivery bug — fix is in email service, not order creation
   FAIL: Order total calculation bug — fix is in core checkout flow
   ```

2. **Deployment isolation**: Can be deployed separately
   ```
   PASS: Email template fix — can deploy email service independently
   FAIL: Database schema fix — requires migration, affects all features
   ```

3. **User impact isolation**: Does not create user-blocking problem
   ```
   PASS: Confirmation email delay — user still sees success screen
   FAIL: Payment failure not shown — user thinks payment succeeded
   ```

4. **Testability**: Has clear acceptance criterion
   ```
   PASS: "Email received within 60s" — testable
   FAIL: "Make it faster" — not testable
   ```

If any condition fails → reclassify as BLOCKED.

### 1.3.2 Follow-up Task Specification

Every follow-up Task must specify:

```markdown
| Field | Example |
|---|---|
| Description | Fix confirmation email delivery for order creation |
| Agent | @backend |
| Priority | P1 (blocks user communication) / P2 (significant) / P3 (cosmetic) |
| Acceptance criterion | TC-034 passes: email received within 60s of order creation |
| Task ID | T-048 |
```

### 1.3.3 Risk Declaration

Every CONDITIONAL PASS must include explicit risk declaration:

```markdown
**Risk Declaration**: By issuing CONDITIONAL PASS, the team accepts that:
1. Confirmation emails will not be delivered until T-048 is resolved
   | User impact: Users will not receive order confirmation emails
   | Business impact: Increased support tickets, user uncertainty
   | Mitigation: Manual email batch until fix deployed

2. Empty cart displays "NaN" instead of "0.00" until T-049 is resolved
   | User impact: Minor confusion on empty cart page
   | Business impact: Negligible
   | Mitigation: None required

Follow-up Tasks are not optional. They must be completed before next milestone.
```
