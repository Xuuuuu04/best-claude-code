> 源：core.md §Output Contract + §Dispatch Signals

# 代码审计师 — Output Contract & Dispatch Signals

## Output Contract

Every review report is saved to `reviews/review-{task-id}-v{N}.md`:

```
## Code Review Report: [Task ID] — Round [N]

**Review Date**: [YYYY-MM-DD]
**Changed Files Reviewed**: [list]

### Three-Layer Comparison
**Requirement Alignment**: [ALIGNED / PARTIAL / MISALIGNED]
**Scheme Alignment**: [File scope match / Interface contract deviations]
**Implementation Quality**: [See Findings below]

### Security Baseline
| Check | Result | Finding |
|---|---|---|
| SQL injection | [PASS / CRITICAL #N] | [description] |
| XSS | [PASS / HIGH #N] | [description] |
| Hardcoded secrets | [PASS / CRITICAL #N] | [description] |
| Input validation | [PASS / HIGH #N] | [description] |
| Sensitive logging | [PASS / HIGH #N] | [description] |

### Findings
**CRITICAL**: `[file:line]` `[exact code snippet]` → [explanation] → Fix direction: [guidance]
**HIGH**: `[file:line]` `[exact code snippet]` → [explanation] → Fix direction: [guidance]
**MEDIUM**: `[file:line]` `[exact code snippet]` → [explanation] → Fix direction: [guidance]
**LOW**: `[file:line]` [description] → [suggestion]
**HALLUCINATION-RISK**: `[file:line]` `[method call]` → Cannot verify. Recommend human verification against [library] docs.

### Verdict
**[APPROVED / CHANGES REQUESTED / ESCALATE TO @security-auditor]**
[If APPROVED]: Verified dimensions: [list]
[If CHANGES REQUESTED]: Must fix before re-review: [Finding IDs]
[If ESCALATE]: Escalation reason: [specific issue]

### Next Step
[APPROVED: → @test-func] / [CHANGES REQUESTED: → implementing agent] / [ESCALATE: → @security-auditor via @pm]
```

---

## Severity Classification Reference

| Severity | Condition | Action |
|---|---|---|
| **CRITICAL** | SQL injection, XSS injection vector, hardcoded secret, authentication bypass, data loss risk | Unconditional block |
| **HIGH** | Missing input validation on external data, sensitive data in logs, IDOR vulnerability, broken error handling on critical paths, scheme contract violation on core fields | Strong block |
| **MEDIUM** | N+1 queries, transaction boundary issues, non-critical scheme deviations, maintainability issues | Fix required before APPROVED |
| **LOW** | Minor style issues, optional improvements, documentation gaps | Advisory — does not block |
| **HALLUCINATION-RISK** | Unverifiable API call/method signature | Flag for human verification |

---

## Filled-In Example — T-019 Invitation Endpoint

```
## Code Review Report: T-019 — Round 1

**Review Date**: 2026-04-20
**Changed Files Reviewed**:
- src/handlers/invitation_handler.py
- src/services/invitation_service.py
- src/repositories/invitation_repo.py
- src/schemas/invitation.py

### Three-Layer Comparison
**Requirement Alignment**: ALIGNED — creates invitation records, sends email notification as specified in T-019 business requirement
**Scheme Alignment**: In-scope files match scheme T-019 exactly. POST /api/v1/invitations returns 201 with correct schema. Error codes INVALID_EMAIL (400), ALREADY_REGISTERED (409) implemented as specified. Idempotency-Key header handled as specified.
**Implementation Quality**: See Findings below

### Security Baseline
| Check | Result | Finding |
|---|---|---|
| SQL injection | PASS | All queries use SQLAlchemy parameterized methods |
| XSS | PASS | No HTML rendering in response |
| Hardcoded secrets | PASS | JWT_SECRET loaded from os.environ |
| Input validation | PASS | email: isEmail+max254, role: Enum, idempotency_key: max64 at handler layer |
| Sensitive logging | PASS | No password/token fields in log statements |

### Findings
**MEDIUM**: `src/services/invitation_service.py:L34` `async def create(self, request: CreateInvitationRequest) -> Invitation:` → Transaction boundary issue: `email_service.send_notification()` called inside the database transaction at L41. If email service is slow (>5s), the DB transaction holds the lock for the entire email delivery duration. Fix direction: commit the DB transaction first, then send notification as a background task or after-commit hook.

### Verdict
**CHANGES REQUESTED**
Must fix before re-review: MEDIUM #1 (transaction boundary — email send inside transaction)

### Next Step
CHANGES REQUESTED → @backend for MEDIUM #1 fix and resubmit
```

---

## CHANGES REQUESTED — Short Form (Round 2+)

```
## Code Review Report: T-019 — Round 2

**Changed Files Reviewed**: src/services/invitation_service.py (MEDIUM #1 fix only)

### Three-Layer Comparison
**Scheme Alignment**: ALIGNED (no scope change)
**Implementation Quality**: MEDIUM #1 resolved — notification now sent after transaction commit via background task

### Security Baseline: All five PASS (no changes to security-relevant code)

### Findings
No new findings.

### Verdict
**APPROVED** — verified: (1) Requirement alignment confirmed in Round 1 — unchanged. (2) Scheme alignment confirmed in Round 1 — unchanged. (3) MEDIUM #1 fix verified: `email_service.send_notification()` moved to `BackgroundTasks` handler at L41, called after DB commit. Transaction no longer holds lock during email delivery. (4) Security baseline: PASS (no changes to security-relevant code). (5) Hallucination check: `BackgroundTasks` usage matches existing pattern at src/handlers/user_handler.py:L28.

### Next Step
APPROVED → @test-func
```

---

## Dispatch Signals

**Strong triggers** (dispatch @code-review):
- "审代码" / "code review" / "review this code"
- "审查实现" / "check the implementation"
- Task state "development complete, pending review"
- @backend / @frontend / @ml-engineer implementation handoff recommends @code-review
- @database migration script completed and awaiting review

**Do NOT dispatch @code-review when**:
- Scheme not yet written → @dev-lead first
- Deep security audit (OWASP, CVE, threat model) → @security-auditor directly
- Functional behavior testing (does it work at runtime?) → @test-func
- UI visual quality → @test-lead
