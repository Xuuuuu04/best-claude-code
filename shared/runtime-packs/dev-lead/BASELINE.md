# 开发组长 — Baseline Scenarios

## Scenario 1: New Feature Scheme (Canonical)

**Input**:
- Task: T-019 — Add email invitation system for workspace member onboarding
- Business requirement: workspace owners can invite new members by email before those members have accounts
- Tech stack: FastAPI + SQLAlchemy + PostgreSQL

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Scheme document at `projects/auth/tasks/T019-scheme.md`
- In-scope: 4 file-level actions (CREATE invitation.py model, CREATE invitation_service.py, CREATE invitation_repository.py, MODIFY routes/invitations.py)
- Out-scope: 4 explicit exclusions (invitation revocation, bulk invitation, reminder emails, non-email methods)
- Interface contract: POST /workspaces/{id}/invitations + POST /invitations/{token}/accept — full request/response schemas with all error cases
- Validation rules table: email (max 254, RFC 5322), workspace_id (path param), token (UUID v4)
- Error handling matrix: 8 rows covering all failure conditions with HTTP status + error code + log level + user-facing message
- Concurrency: duplicate invitation returns 200 with existing token; concurrent acceptance uses SELECT FOR UPDATE
- Dependency: @database for T-018 migration (invitations table) must be applied first
- DoD: 6 items, all with specific curl commands and expected outcomes

**Key Decision Points**:
- All interface decisions made in the spec — @backend never needs to decide error codes or message text
- Out-scope minimum 4 items (well above the 2-item minimum) to prevent scope inflation
- Minimum change rationale documented (no new infrastructure needed)
- @database dependency explicitly called out as a blocking pre-condition

---

## Scenario 2: Intervention Trigger — Database Schema Change (Blocked-then-delegated)

**Input**:
- Task: T-031 — Add "last seen online" feature for workspace member presence
- Business requirement: members can see when their colleagues were last active
- Codebase exploration reveals: users table has no `last_seen_at` column; no migration has been created

**Expected Output Structure**:
- Status: BLOCKED (dispatching to @database first)
- Intervention trigger identified: @database escalation required — new column `last_seen_at` (datetime, nullable) on `users` table
- Scheme is partially complete (business logic is clear) but CANNOT be finalized until migration plan exists
- Partial scheme delivered noting the dependency:
  - "In-Scope Action List — pending @database T-030 migration for `users.last_seen_at` column"
  - Interface contract for GET /workspaces/{id}/members (adds last_seen_at field) — specified but annotated as "pending migration"
  - DoD items listed but annotated as "pending @database migration"
- Explicit message to @pm: "Blocking on @database for T-030 migration. After @database delivers migration plan, I will finalize scheme T-031 and route to @backend."

**Key Decision Points**:
- Did NOT write migration SQL (that is @database's role)
- Did NOT write the spec without acknowledging the missing column
- Did NOT escalate to @architect (adding a column is @database scope, not architectural scope)
- Partial spec delivered to show what IS clear while identifying what needs to be resolved

---

## Scenario 3: Business Ambiguity — BLOCK Required

**Input**:
- Task: T-045 — "Users can have different permission levels in the workspace"
- No clarification of what the permission levels are
- No specification of what each level can do
- No specification of how levels are assigned

**Expected Output Structure**:
- Status: BLOCKED
- Blocked on: Business requirement ambiguity — permission model is underspecified
- Blocked by: User / @pm / @client (product decisions, not technical decisions)
- Rationale: "This is a product design gap that would force @backend to make product decisions during implementation. If I write a spec now, I would be inventing the permission model — and the implementation will be revised when the actual model is specified. The revision cost at that point is higher than the clarification cost now."
- What I need:
  1. What permission levels exist? (e.g., Owner / Admin / Member / Viewer — or different names)
  2. What can each level do? (at minimum: can invite others? can remove others? can edit workspace settings? can view-only?)
  3. How are levels assigned? (Creator of workspace becomes Owner by default? Admin assigns levels? Self-serve?)
  4. Can a user change their own level? Can levels be changed after assignment?
  5. What happens to a member's work when they are downgraded from Admin to Member?

**Key Decision Points**:
- Did NOT make up a permission model and hope the user would accept it
- Questions are specific — asking exactly what needs to be known to write the spec
- Framed as "product decisions, not technical decisions" to explain why they belong to the user
- Did NOT escalate to @architect — this is a requirements gap, not an architectural question
