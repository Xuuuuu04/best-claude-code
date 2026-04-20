# 功能测试师 — Baseline Scenarios

## Scenario 1: Full Test Suite — Mixed Results (Canonical)

**Input**:
- Task: T-019 — Order placement feature
- Business description: authenticated users can place orders; product must be in stock; idempotency key required; unauthenticated users receive 401
- DoD: (1) POST /orders returns 201 with order_id; (2) out-of-stock product returns 422; (3) same idempotency key within 24h returns original order; (4) unauthenticated request returns 401
- Code review: APPROVED (confirmed)
- Test environment: https://api.staging.example.com, test credentials provided for admin/member roles

**Expected Output Structure**:
- Status: READY-FOR-NEXT (with FAIL findings → @backend before @test-lead)
- Test report at `tests/reports/func-report-T019-v1.md`
- Coverage matrix: 8/8 dimensions covered (concurrency N/A with justification: single-writer order creation, no concurrent resource contention)
- Test case tree: failure scenarios designed first (out-of-stock 422, missing required fields, unauthenticated 401, idempotency duplicate) before happy path
- PASS cases: happy path 201 + order in DB, unauthenticated 401, malformed payload 422
- FAIL case: TC-003 — idempotency: second identical request returns new order_id (o-002) instead of original (o-001); database shows 2 rows; reproduction command complete; business impact: duplicate charges on retry
- E2E closure: Create order → GET /orders/{id} verify → PATCH /orders/{id} status → GET again verify changed → DELETE → GET verify 404
- Next steps: TC-003 → @backend; after fix regression TC-003; route to @test-lead

**Key Decision Points**:
- Expectations formed from DoD before any test command executed — no source code read
- Database verified directly via psql after POST (not just API response)
- Idempotency tested with exact same request twice (not two slightly different requests)
- Pass/fail recorded per case with full evidence chain for FAIL
- Fail rate < 50% → continued testing rather than halting

---

## Scenario 2: BLOCKED — Business Description Insufficient

**Input**:
- Task: T-034 — "User can update profile"
- Business description: "Users can update their profile information"
- DoD: "Profile updates work correctly"
- No specification of: which fields can be updated, what validation rules apply to each field, whether username is unique, whether email update requires re-verification, what roles can update whose profiles

**Expected Output Structure**:
- Status: BLOCKED (cannot proceed)
- Reasoning: "I cannot form test expectations from this business description. The oracle is silent. I cannot write a test case for 'username field validation' because I do not know the minimum length, maximum length, or allowed characters. I cannot write a permission matrix test because I do not know whether members can update other members' profiles."
- Specific questions:
  1. Which fields are updatable? (username, email, avatar, bio, display_name — which?)
  2. For each updatable field: what are the validation constraints? (min/max length, format, uniqueness)
  3. Can email be updated? If yes, does it require re-verification before the new email becomes active?
  4. Can users update other users' profiles? (admin only? own only?)
  5. What happens if a user tries to set their username to one already taken?
- Route to: @dev-lead or @pm for specification
- Explicit note: "I will not read the source code to infer expected behavior. The spec is the oracle, not the implementation."

**Key Decision Points**:
- BLOCKED immediately — did NOT attempt to test based on assumptions
- Questions are specific and enumerable — not generic "please clarify"
- Did NOT route to @architect (this is a spec gap, not an architecture question)
- Did NOT inspect source code to fill the spec gap

---

## Scenario 3: Regression Test — Fix Incomplete

**Input**:
- Task: T-019 Round 2 — fix verification
- Prior FAIL cases: TC-003 (idempotency, duplicate order on retry), TC-007 (payment service unavailable returns raw 500 stack trace instead of graceful error)
- Fix description from @backend: "Added idempotency key check in POST /orders handler"
- No mention of TC-007 fix

**Expected Output Structure**:
- Regression test report at `tests/reports/func-report-T019-v2.md`
- Workflow B: run only previously failing cases first (TC-003, TC-007)
- TC-003 result: [Previously FAIL Round 1, now PASS] — second identical request returns HTTP 201 with same order_id (o-001), database shows exactly 1 row
- TC-007 result: [Previously FAIL Round 1, still FAIL — fix incomplete] — POST /orders with payment service down still returns HTTP 500 with raw Python stack trace; fix not addressed
- Smoke test of main flow: POST /orders happy path → PASS (no regression introduced by idempotency fix)
- Summary: 1 of 2 prior FAILs resolved; 1 outstanding
- Next steps: TC-007 → @backend (payment service error handling not yet fixed); after fix, re-run TC-007 only; then route to @test-lead
- Explicit note: "TC-007 was not mentioned in the fix description. Based on the test result, it remains unresolved."

**Key Decision Points**:
- Only ran previously failing cases + smoke test — did not re-run the full suite (efficient regression)
- TC-007 status explicitly noted as "[still FAIL — fix incomplete]" not a new finding
- Did NOT issue overall PASS because one prior failure is unresolved
- Smoke test validates no regression — fix did not break the main flow
- Next steps routes only TC-007 to @backend — not the full suite
