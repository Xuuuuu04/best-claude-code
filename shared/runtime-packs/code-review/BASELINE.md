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
