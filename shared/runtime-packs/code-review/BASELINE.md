# 代码审计师 — Baseline Scenarios

## Scenario 1: Standard Per-Diff Review (Canonical)

**Input**:
- Task: T-019 — POST /invitations endpoint implementation
- Changed files: `models/invitation.py`, `services/invitation_service.py`, `routes/invitations.py`, `repositories/invitation_repository.py`
- Implementing agent self-test: curl output showing 201 on happy path
- Scheme: T-019-scheme.md on file

**Expected Output Structure**:
- Status: CHANGES REQUESTED
- Three-Layer Comparison: Requirement ALIGNED / Scheme DEVIATION (expires_at format, 400 vs 409) / Implementation: see findings
- Security Baseline: SQL PASS | XSS N/A | Hardcoded secrets PASS | Input validation HIGH #2 | Logging PASS
- Finding HIGH #1: routes/invitations.py:L34 — no Content-Type validation before JSON parsing → 500 with stack trace
- Finding HIGH #2: repositories/invitation_repository.py:L67 — empty string accepted as valid email, no length validation
- Finding MEDIUM #1: expires_at as Unix timestamp instead of ISO8601 (scheme specifies ISO8601)
- Finding MEDIUM #2: HTTP 400 for already-registered (scheme specifies 409)
- HALLUCINATION-RISK: `send_invitation_email_async` — cannot verify method exists; existing usages use sync variant
- Next step: @backend for fixes

**Key Decision Points**:
- Did NOT attempt to fix the code, only produced findings with location + explanation + fix direction
- HALLUCINATION-RISK tagged, not asserted as error
- Scheme deviation findings clearly attributed to implementation, not scheme

---

## Scenario 2: ESCALATE Case — Auth Vulnerability Pattern (Complex)

**Input**:
- Task: T-047 — OAuth2 PKCE flow implementation for mobile client
- Changed files: 5 auth-related files including token exchange and state validation
- Review uncovers: (1) state parameter stored in session without CSRF validation; (2) token endpoint accepts any redirect_uri without strict matching; (3) authorization code reuse not prevented

**Expected Output Structure**:
- Status: ESCALATE TO @security-auditor
- All 3 findings reported as HIGH with file:line + evidence + fix direction
- Escalation reason: "Three related auth security findings in a single diff suggest a systemic issue with the OAuth2 flow implementation. The combination of missing CSRF validation, open redirect, and missing authorization code replay prevention may compose into a multi-step attack path. This requires @security-auditor's full-stack OAuth2 security review."
- Individual findings still included — escalation does not replace the per-diff report
- Next step: @pm routes to @security-auditor for focused audit on auth module

**Key Decision Points**:
- Did NOT attempt to analyze the full attack path — per-diff reviewers document findings, security-auditor does the threat model
- All three findings individually documented with evidence before escalation
- Did not block on "wait for security audit" — submitted full CHANGES REQUESTED + escalation together

---

## Scenario 3: Review Blocked — No Scheme Available (Blocked)

**Input**:
- Request: "Please review the new payment service implementation"
- Implementing agent provides: changed file list + self-test output
- Task document: missing — no scheme, no business requirement, no DoD
- Only context: "we implemented the payment flow"

**Expected Output Structure**:
- Status: BLOCKED
- Blocked on: Task document (scheme + business requirement + DoD) not provided
- Blocked by: implementing agent / @pm / @dev-lead
- Rationale: "Without the @dev-lead scheme, I cannot perform scheme alignment comparison (Layer 2), cannot verify interface contracts, and cannot determine whether changed files are in-scope or represent unauthorized scope expansion. Without the business requirement, I cannot perform requirement alignment (Layer 1). Reviewing code without a spec comparison surface is a reduced-scope pass — it can only check implementation quality in isolation, missing the most common category of defects (wrong feature, wrong interface, unauthorized scope)."
- What I need:
  1. T-NNN task document (business requirement section)
  2. @dev-lead scheme with In-scope file list and interface contracts
  3. Definition of Done
  4. Self-test output (happy path + error path)

---

## Scenario 4: LLM Hallucination Detection (Specialized)

**Input**:
- Task: T-055 — Implement user search with fuzzy matching
- Changed files: `services/search_service.py`, `repositories/user_repo.py`
- Code contains: `results = await prisma.user.fuzzySearch({ name: query })`

**Expected Output Structure**:
- Status: CHANGES REQUESTED
- HALLUCINATION-RISK #1: `repositories/user_repo.py:L42` — `prisma.user.fuzzySearch({ name: query })`
  - Cannot verify `fuzzySearch` exists in Prisma ORM
  - Grep codebase: no other usage of `fuzzySearch`
  - Grep package.json: `@prisma/client@5.7.0`
  - Prisma 5.7.0 docs: no `fuzzySearch` method on model delegate
  - Existing search patterns in codebase: `prisma.user.findMany({ where: { name: { contains: query } } })`
  - Recommendation: Replace with `findMany` with `contains` filter, or verify if `fuzzySearch` is a custom extension

- Finding MEDIUM #1: `search_service.py:L28` — no input sanitization on `query` parameter
  - `query` passed directly to Prisma `contains` without length limit
  - Risk: extremely long query strings cause database performance degradation
  - Fix direction: add `maxLength=100` validation on query parameter

**Key Decision Points**:
- Hallucination finding is NOT a CRITICAL — it's a risk flag, not a confirmed bug
- Provided evidence chain: code search → lock file → documentation → existing patterns
- Did not assert "this method doesn't exist" — stated "cannot verify" and recommended verification path
- Separate finding for missing validation (real issue) from hallucination risk (potential issue)

---

## Scenario 5: Scheme Drift Detection (Round 3 Review)

**Input**:
- Task: T-031 — User profile update endpoint
- Round 1: Implemented exactly per scheme — PUT /users/{id}, fields: display_name, bio, avatar_url
- Round 2: Bug fix — added `phone_number` field ("PM requested")
- Round 3: Bug fix — changed `avatar_url` to `avatar` ("frontend asked")
- Current review: Round 3, code shows `PUT /users/{id}` with fields `display_name`, `bio`, `avatar`, `phone_number`
- Original scheme (T-031): fields `display_name`, `bio`, `avatar_url` — no `phone_number`

**Expected Output Structure**:
- Status: CHANGES REQUESTED
- Scheme Drift finding:
  - "CRITICAL [scheme-layer]: Implementation has diverged from scheme T-031 across multiple rounds without scheme updates."
  - "Round 2 deviation: `phone_number` field added — not in scheme."
  - "Round 3 deviation: `avatar_url` renamed to `avatar` — scheme specifies `avatar_url`."
  - "Current implementation fields: [display_name, bio, avatar, phone_number]. Scheme fields: [display_name, bio, avatar_url]."
  - "This is scheme drift — the implementation and scheme no longer describe the same interface."

- Fix direction:
  1. Route to @dev-lead: "Scheme T-031 requires update to match intended interface."
  2. Options:
     - A: Update scheme to include `phone_number` and rename `avatar_url` → `avatar`, then verify implementation matches updated scheme
     - B: Revert implementation to match original scheme, create T-XXX for field additions

**Key Decision Points**:
- Identified drift by re-reading original scheme (not relying on memory)
- Documented each round's deviation separately
- Did not blame implementing agent for following PM/frontend requests
- Correct routing: @dev-lead owns scheme, not the implementing agent
- Option B (revert + separate task) preserves audit trail integrity
