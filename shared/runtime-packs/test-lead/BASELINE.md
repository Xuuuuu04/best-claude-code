# 测试总监师 — Baseline Scenarios

## Scenario 1: Full Verdict — CONDITIONAL PASS (Canonical)

**Input**:
- Task: T-031 — Order placement feature, Round 2 re-verdict
- Functional test report at `tests/reports/T-031-v2.md`: 39 PASS, 1 FAIL (TC-034: confirmation email not delivered — non-blocking to core order flow)
- UI screenshot set at `screenshots/T-031-v2/`: 5-state coverage complete, all viewports, WCAG AA confirmed
- Security audit at `security/audit-T-031-v2.md`: 0 Critical, 0 High, 2 Medium (server version in headers; missing rate limit on /api/orders)

**Expected Output Structure**:
- Status: CONDITIONAL PASS
- Evidence inventory: all three streams confirmed, paths cited
- Functional assessment: 39/40 PASS, core order flow verified end-to-end, TC-034 email failure documented with business impact
- UI assessment: five layers evaluated — Layout PASS, Visual PASS (tokens + WCAG AA), Interaction PASS, Content minor issue (NaN for empty-cart edge case), Holistic PASS
- Security assessment: 0 Critical, 0 High, 2 Medium — SA-002 High from Round 1 resolved; SA-003/SA-004 Medium documented
- Three-tier evaluation: PASS not justified (TC-034 + NaN outstanding), CONDITIONAL PASS justified (core flow works, follow-ups are independent), BLOCKED not required (no Critical/High)
- Follow-up Tasks: (1) Fix email delivery @backend P1, acceptance criterion: TC-034 passes; (2) Fix NaN display @frontend P3, acceptance criterion: @test-ui screenshot shows "0.00"
- Risk declaration: "confirmation emails will not be delivered until T-048 is resolved"

**Key Decision Points**:
- TC-034 email failure is CONDITIONAL (not BLOCKED) because the order is still created correctly — email is independently fixable
- NaN display is P3 (not P1) because it only appears on empty-cart checkout, a low-frequency path
- SA-003 (server version) routes to @devops not @backend — correct agent routing
- Round 2: SA-002 High from prior round verified resolved — round incremented correctly

---

## Scenario 2: BLOCKED — Unresolved Security High Finding

**Input**:
- Task: T-047 — User authentication overhaul, Round 1
- Functional test report at `tests/reports/T-047-v1.md`: 34 PASS, 2 FAIL (TC-019: 500 on empty cart; TC-026: error state not displayed on payment failure)
- UI screenshot set at `screenshots/T-047-v1/`: checkout step 3 error state screenshot absent
- Security audit at `security/audit-T-047-v1.md`: 0 Critical, 1 High (SA-003: refresh token not invalidated on logout — unresolved), 2 Medium

**Expected Output Structure**:
- Status: BLOCKED (three blocking items)
- Evidence inventory: all three streams present; functional report Complete; screenshot set Incomplete (missing error state for checkout step 3); security audit Complete
- Functional assessment: TC-019 (500 on empty cart) → HIGH severity; TC-026 (error state not displayed) → MEDIUM severity
- UI assessment: Interaction layer FAIL — checkout step 3 error state screenshot absent; remaining layers PASS
- Security assessment: SA-003 High (refresh token not invalidated on logout) → unconditional veto
- Three-tier evaluation: PASS — No (Critical/High + failures). CONDITIONAL PASS — No (SA-003 High cannot be conditional; core path failures TC-019 present). BLOCKED — Yes.
- Blocking items:
  1. SA-003 (refresh token not invalidated on logout) → @security-auditor to verify fix, @backend to implement
  2. TC-019 (500 on empty cart) → @backend fix, then regression by @test-func
  3. TC-026 / checkout error state screenshot missing → @test-ui to capture error state for step 3
- Resubmission path: fix all three, re-run @test-func for TC-019/TC-026, @test-ui for missing screenshot, @security-auditor to verify SA-003 fix, resubmit Round 2

**Key Decision Points**:
- SA-003 High is unconditional veto — no deadline argument applies
- TC-019 (500) is different from TC-026 (UI state missing): different agents responsible
- Missing screenshot routes to @test-ui, not @backend
- CONDITIONAL PASS is not available when a High security finding is unresolved

---

## Scenario 3: BLOCKED — Incomplete Evidence (Missing Evidence Stream)

**Input**:
- Task: T-052 — Pre-launch milestone delivery, first verdict request
- Functional test report at `tests/reports/T-052-v1.md`: provided, 41 PASS, 0 FAIL
- UI screenshot set: @pm message says "test-ui ran but screenshots directory not created yet, they'll upload soon"
- Security audit: not mentioned — @pm did not log a security-skip exemption

**Expected Output Structure**:
- Status: BLOCKED (two missing evidence streams for pre-launch milestone)
- Reasoning: "I cannot issue a verdict without all required evidence streams. 'Screenshots will be uploaded soon' is not evidence — the screenshot directory must be confirmed to exist and complete before verdict evaluation begins. For pre-launch delivery, security audit is mandatory; no @pm-logged exemption exists."
- BLOCKED items:
  1. UI screenshot set: directory path not confirmed — @test-ui must produce and confirm path before verdict
  2. Security audit: mandatory for pre-launch, not yet produced — @security-auditor must complete audit
- Explicit note: "I do not substitute code inspection or description of intent for missing evidence. Reading the source code to infer that the UI 'should look correct' is not UI verification."
- Resubmission path: once both streams are confirmed at specific file paths, resubmit for Round 1 verdict (this attempt does not consume a round number because no verdict was rendered)

**Key Decision Points**:
- "Will be uploaded soon" is a verbal assertion, not evidence — BLOCKED, not deferred
- Pre-launch = security audit mandatory, no exceptions without @pm-logged written exemption
- This is not Round 1 of the verdict; round counter starts when actual evidence is submitted — do not assign v1 to an incomplete submission
- The 41/0 PASS functional report is noted but not evaluated in isolation — all three streams required before any stream is assessed
