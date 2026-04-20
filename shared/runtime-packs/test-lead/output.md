# 测试总监师 — Output Contract (Detailed)

## Verdict Report Structure

Verdict saved to `verdicts/verdict-{task-id}-v{n}.md`:

```markdown
## Quality Verdict: [Task ID] — Round [N]

**Verdict Date**: [YYYY-MM-DD]
**Verdict Type**: [PASS / CONDITIONAL PASS / BLOCKED]
**Evaluator**: [agent name / session ID]
**Task Description**: [one-sentence summary]
```

### Evidence Inventory

```markdown
### Evidence Inventory

| Stream | Source Agent | Artifact Path | Status | Notes |
|---|---|---|---|---|
| Functional test | @test-func | tests/reports/func-report-T031-v2.md | Complete | 39 PASS, 1 FAIL |
| UI screenshots | @test-ui | screenshots/T031-v2/ | Complete | 5 states, both viewports |
| Security audit | @security-auditor | security/audit-T031-v2.md | Complete | 0 Critical, 0 High, 2 Medium |
```

Status values:
- **Complete**: all required artifacts present and readable
- **Incomplete**: artifacts present but missing required sections
- **Missing**: artifacts not found at specified path
- **N/A**: stream not required for this delivery type

### Functional Test Assessment

```markdown
### Functional Test Assessment

**Coverage matrix**: 8/8 dimensions covered
**Test case results**: 40 total — PASS: 39 / FAIL: 1 / BLOCKED: 0
**Pass rate**: 97.5%

**Failed cases**:
- TC-034 [Severity: MEDIUM] — Confirmation email not delivered
  | Spec basis: DoD item 5 — "User receives confirmation email within 60 seconds"
  | Reproduction: Complete purchase → no email received within 60s
  | Business impact: User uncertainty about order status; support ticket increase
  | Core path impact: No — order is created correctly, user sees success screen

**Functional judgment**: PASS with one non-core-path MEDIUM finding
```

### UI Assessment (Five Layers)

```markdown
### UI Assessment (Five Layers)

| Layer | Result | Notes |
|---|---|---|
| Layout | PASS | Visual hierarchy clear, consistent grid alignment |
| Visual | PASS | Color accuracy matches design tokens, WCAG AA contrast verified |
| Interaction | PASS | All states visible, hover/focus/active distinct |
| Content | Minor issue | Empty cart shows "NaN" instead of "0.00" (screenshot: checkout-desktop-empty.png) |
| Holistic | PASS | Mobile viewport coherent, no half-finished components |

**UI state coverage**: 5/5 states confirmed for all screens
**UI judgment**: PASS with one LOW content issue
```

Five-layer definitions:
- **Layout**: visual hierarchy, alignment, spacing, whitespace balance
- **Visual**: color accuracy, contrast ratios, typography hierarchy
- **Interaction**: button states, feedback visibility, error message clarity
- **Content**: text truncation, placeholder copy, data format consistency
- **Holistic**: mobile viewport, overall professionalism, no half-finished components

### Security Assessment

```markdown
### Security Assessment

**Critical findings**: 0
**High findings**: 0 (SA-002 from Round 1 resolved)
**Medium findings**: 2
  - SA-003: Server version disclosed in HTTP headers
  - SA-004: Missing rate limit on /api/orders
**Low findings**: 0

**OWASP coverage**: Complete (Top 10 all addressed)
**Dependency scan**: Executed, 0 critical vulnerabilities

**Security judgment**: PASS (no Critical/High unresolved)
```

### Three-Tier Evaluation

```markdown
### Three-Tier Evaluation

- **PASS justified?** No — TC-034 (email failure) and NaN display outstanding
- **CONDITIONAL PASS justified?** Yes — core order flow works end-to-end,
  all Critical/High resolved, TC-034 is independently fixable (email service
  is separate from order creation), NaN is cosmetic
- **BLOCKED required?** No — no Critical/High findings, core path functional,
  no incomplete evidence streams
```

### Final Verdict

```markdown
### Final Verdict

**CONDITIONAL PASS**

Rationale: Core order placement flow verified end-to-end (39/40 functional
 tests PASS). UI assessment passes all five layers with one LOW content issue.
 Security audit clean (0 Critical, 0 High). Two follow-up items are
 independently fixable and do not block core functionality.

**Follow-up Tasks**:

1. Fix confirmation email delivery
   | Agent: @backend
   | Priority: P1
   | Acceptance criterion: TC-034 passes — email received within 60s of order creation
   | Task ID: T-048

2. Fix empty cart NaN display
   | Agent: @frontend
   | Priority: P3
   | Acceptance criterion: @test-ui screenshot shows "0.00" instead of "NaN"
   | Task ID: T-049

**Risk Declaration**: By issuing CONDITIONAL PASS, the team accepts that:
- Confirmation emails will not be delivered until T-048 is resolved
- Empty cart displays "NaN" instead of "0.00" until T-049 is resolved

Follow-up Tasks are not optional. They must be completed before next milestone.
```

## BLOCKED Verdict Format

```markdown
### Final Verdict

**BLOCKED** (three blocking items)

**Blocking items**:

1. SA-003 | Refresh token not invalidated on logout [Severity: HIGH]
   | Failure: Logout does not revoke refresh token; token remains valid until expiry
   | Fix: Implement token blacklist; check blacklist in refresh middleware
   | Route to: @backend (fix) + @security-auditor (verify)

2. TC-019 | POST /api/orders returns 500 on empty cart [Severity: HIGH]
   | Failure: Server crashes when cart has no items
   | Fix: Add null/empty check before processing
   | Route to: @backend

3. Missing screenshot | Checkout step 3 error state [Severity: MEDIUM]
   | Failure: @test-ui did not capture error state for checkout step 3
   | Fix: Trigger payment failure, capture error state screenshot
   | Route to: @test-ui

**Resubmission path**:
1. @backend fixes SA-003 and TC-019
2. @security-auditor verifies SA-003 fix and updates audit report
3. @test-ui captures missing screenshot
4. @test-func re-runs TC-019 regression test
5. Resubmit all three evidence streams for Round 2
```

## Verdict Decision Flowchart

```
Start
  |
  v
All three evidence streams present? ──No──> BLOCKED (missing stream)
  | Yes
  v
Read functional report ──Any Critical/High?──Yes──> BLOCKED
  | No
  v
Read UI screenshots ──Any user-blocking defect?──Yes──> BLOCKED
  | No
  v
Read security audit ──Any Critical/High unresolved?──Yes──> BLOCKED
  | No
  v
Core path functional? ──No──> BLOCKED
  | Yes
  v
Any MEDIUM/LOW findings? ──No──> PASS
  | Yes
  v
Independently fixable? ──No──> BLOCKED
  | Yes
  v
CONDITIONAL PASS
```

## Severity Classification Reference

| Severity | Definition | Verdict Impact |
|---|---|---|
| CRITICAL | Security Critical/High; complete core flow failure; data integrity risk; auth bypass | Unconditional BLOCKED |
| HIGH | Non-core feature completely broken; UI unusable for significant portion; High security finding; P99 > 10× SLA | Strong BLOCKED |
| MEDIUM | Non-core defect with workaround; UI cosmetic; Medium security with no realistic exploit | CONDITIONAL PASS candidate |
| LOW | Text copy errors; minor visual misalignment; edge-case in low-frequency flow | CONDITIONAL PASS or PASS |

## Conditional Pass Independence Test

A follow-up item is independently fixable if ALL of the following are true:

1. **Code isolation**: Fixing it does not require modifying core flow code
2. **Deployment isolation**: Can be deployed in a separate deployment from the main feature
3. **User impact isolation**: Does not create a user-blocking problem in production
4. **Testability**: Has a clear, testable acceptance criterion

If any condition fails → reclassify as BLOCKED.

## Cross-Task Pattern Detection

Flag to @pm when:

| Pattern | Threshold | Action |
|---|---|---|
| Same defect category | 3+ consecutive Tasks | Escalate to @pm for root cause investigation |
| Coverage gap | @test-func consistently missing same dimension | Flag for test protocol update |
| Rework rate | 3+ BLOCKED verdicts for same Task without resolution | Flag for scheme/architecture review |
| Security finding recurrence | Same vulnerability type in 2+ Tasks | Escalate to @security-auditor for systemic audit |

## Quality Checklist (Pre-Verdict)

Before issuing any verdict:

- [ ] All required evidence streams confirmed at specific file paths
- [ ] Functional report read (not summarized)
- [ ] UI screenshots reviewed (not described)
- [ ] Security audit read (not summarized)
- [ ] Coverage matrix complete (8 dimensions or justified N/A)
- [ ] Every FAIL has complete evidence chain
- [ ] Three-tier evaluation explicitly documented
- [ ] Verdict rationale references specific evidence artifacts
- [ ] BLOCKED items: finding ID + description + corrective action + target agent
- [ ] CONDITIONAL PASS items: independence test passed + follow-up Task specs + risk declaration
- [ ] Report saved to: `verdicts/verdict-{task-id}-v{n}.md`
