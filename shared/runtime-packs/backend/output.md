> 源：core.md §Output Contract + §Dispatch Signals

# 后端开发师 — Output Contract & Dispatch Signals

## Output Contract

Every implementation handoff MUST use this format. No exceptions.

```
## Backend Implementation Output

**Task**: [Task ID] — [one-sentence description]
**Status**: READY-FOR-NEXT | BLOCKED | FAILED

**Changed Files**:
- `path/to/file.ext`: [what changed — one line]
- `path/to/file2.ext`: [what changed]

**Self-Test Results**:
[curl commands + actual output for happy path]
[curl commands + actual output for at least one error path]

**Security Baseline**:
- SQL parameterization: ✓/✗
- Password handling: ✓/✗/N/A
- Credential externalization: ✓/✗
- Input validation: ✓/✗
- Log hygiene: ✓/✗

**Known Limitations / Discovered Issues**: [optional — out-of-scope items discovered]

**Recommended Next Step**: @code-review — [specific focus area for reviewer]
```

---

## Filled Example — T-019 User Invitation Endpoint

```
## Backend Implementation Output

**Task**: T-019 — POST /api/v1/invitations endpoint with idempotency

**Status**: READY-FOR-NEXT

**Changed Files**:
- `src/handlers/invitation_handler.py`: new POST /api/v1/invitations route handler with Pydantic validation
- `src/services/invitation_service.py`: new InvitationService.create() with idempotency key check
- `src/repositories/invitation_repo.py`: new InvitationRepository.create() and get_by_idempotency_key()
- `src/schemas/invitation.py`: CreateInvitationRequest (email, role, idempotency_key) + InvitationResponse

**Self-Test Results**:
Happy path:
  curl -X POST http://localhost:8000/api/v1/invitations \
    -H "Authorization: Bearer $TEST_TOKEN" \
    -H "Content-Type: application/json" \
    -H "Idempotency-Key: test-key-001" \
    -d '{"email": "test@example.com", "role": "member"}'
  Response (201): {"id": 42, "email": "test@example.com", "role": "member", "status": "pending", "expires_at": "2026-04-27T00:00:00Z"}

Error path — duplicate idempotency key:
  [same curl with same Idempotency-Key header]
  Response (200): {"id": 42, ...} [idempotent repeat returns existing]

Error path — invalid email:
  curl -d '{"email": "not-an-email", "role": "member"}' ...
  Response (400): {"type": "https://api.example.com/errors/validation", "status": 400, "detail": "email: invalid email format"}

Error path — unauthorized:
  [curl without Authorization header]
  Response (401): {"code": "UNAUTHORIZED", "message": "Authentication required"}

**Security Baseline**:
- SQL parameterization: ✓ (Pydantic + SQLAlchemy parameterized queries throughout)
- Password handling: N/A (no passwords in this endpoint)
- Credential externalization: ✓ (DB URL, JWT_SECRET from env vars only)
- Input validation: ✓ (email: isEmail+max254; role: Enum[member,admin]; idempotency_key: max64)
- Log hygiene: ✓ (logs contain user_id, invitation_id — no email addresses or tokens in log lines)

**Known Limitations / Discovered Issues**:
- `user_service.py:L89`: existing password reset endpoint has N+1 issue unrelated to T-019. Recommend T-043.

**Recommended Next Step**: @code-review — verify idempotency logic in invitation_service.py, confirm security baseline on all five items, check transaction boundary in create().
```

---

## BLOCKED Output Example

```
## Backend Implementation Output

**Task**: T-042 — POST /api/v1/payments endpoint

**Status**: BLOCKED

**Block Reason**:
Scheme document T-042 does not specify:
1. Which payment provider to use (Stripe / PayPal / internal) — affects DTO structure, error codes, retry strategy
2. Error code for payment declined vs. insufficient funds — client handling differs
3. Whether idempotency key is required — omission would allow duplicate charges

**Routing**: @dev-lead for scheme clarification on items 1-3.
**No code has been written** — implementation blocked before Step 1.
```

---

## Dispatch Signals

**Strong triggers** (dispatch @backend immediately):
- "写这个接口" / "write this endpoint"
- "后端实现" / "backend implementation"
- "写这个服务" / "write this service"
- "修后端 bug" / "fix this API bug"
- Task state transitions from "scheme-complete" to "development"

**Do NOT dispatch @backend when**:
- No finalized scheme document exists → @dev-lead first
- Required database migration is pending → @database first
- Task is purely frontend → @frontend
- Task is ML model training / inference → @ml-engineer
- Task is Dockerfile / CI/CD → @devops
- Task is deep security audit → @security-auditor
- Task is API documentation → @doc-writer
- Request is to fill spec gaps → BLOCK, route to @dev-lead
