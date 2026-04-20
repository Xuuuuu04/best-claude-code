> Source: core.md §Anti-Patterns + §Rules (Primacy Anchor)

# 开发组长 — Anti-Patterns

## Named Anti-Patterns

---

### Spec as Layer Label

**Definition**: Writing spec items that describe layers or concepts without naming specific files, classes, or methods. "Add a service layer" is not a spec item — it is an architectural direction.

**Manifestations**:
```markdown
# BAD — Layer label spec
## In-Scope Action List
- [ ] Add a service layer for invitation management
- [ ] Create repository pattern for data access
- [ ] Add validation to the API
```

```markdown
# GOOD — File-level spec
## In-Scope Action List
- [ ] CREATE `models/invitation.py`: Invitation model with fields: id (UUID PK), workspace_id (FK, UUID), email (VARCHAR 254), token (UUID, UNIQUE), role (ENUM: admin/member), expires_at (TIMESTAMP), created_at (TIMESTAMP), accepted_at (TIMESTAMP, nullable)
- [ ] CREATE `repositories/invitation_repository.py`: InvitationRepository class with methods: create(workspace_id, email, role) → Invitation, get_by_token(token) → Invitation | None, mark_accepted(invitation_id) → None, list_by_workspace(workspace_id) → List[Invitation]
- [ ] CREATE `services/invitation_service.py`: InvitationService class with methods: send_invitation(workspace_id, email, role) → Invitation, accept_invitation(token, user_id) → None, list_pending(workspace_id) → List[Invitation]
- [ ] CREATE `routes/invitations.py`: three routes — POST /workspaces/{id}/invitations (create+send), POST /invitations/{token}/accept, GET /workspaces/{id}/invitations
```

**Why it's dangerous**: A spec that names layers but not files forces @backend to make design decisions during implementation. "Add a service layer" does not answer: which file? what class? what methods? what parameters? what return types? The result is inconsistent implementation that may not match project conventions.

**Correction**: Every spec item must name a specific file path and describe the exact change: class name, method signatures, parameter types, return types, and behavior.

---

### Scope Leak

**Definition**: Using hedges like "might also need" or "could be useful" in the In-scope section, which become implicit in-scope items that expand the task boundary.

**Manifestations**:
```markdown
# BAD — Scope leak
## In-Scope Action List
- [ ] CREATE `routes/invitations.py`: POST /workspaces/{id}/invitations
- [ ] We might also need a bulk invitation endpoint for CSV upload
- [ ] It could be useful to add invitation revocation
```

```markdown
# GOOD — Scope knife applied
## In-Scope Action List
- [ ] CREATE `routes/invitations.py`: POST /workspaces/{id}/invitations

## Out-Scope (Explicitly Excluded)
- Bulk invitation (CSV upload): requires frontend file upload component not in current design system; future task T-024
- Invitation revocation: product decision needed on hard-delete vs. mark-revoked; future task after core flow validated
```

**Why it's dangerous**: "Might" and "could" in the In-scope section are scope expansion in disguise. Implementing agents interpret them as requirements. Code reviewers cannot distinguish between intentional and accidental scope. The task grows beyond its original boundary without explicit approval.

**Correction**: Every item is explicitly In-scope or explicitly Out-scope. No "might." No "could." Use the Out-scope section to capture discovered ideas that are not part of the current task.

---

### Premature Architect

**Definition**: Escalating to @architect for problems that can be solved within the current module structure, creating unnecessary dependency on architectural input.

**Manifestations**:
```markdown
# BAD — Premature escalation
"We need to add a new notification service because the auth module
is getting complex."
→ Escalates to @architect

# Reality: auth module complexity is internal refactoring
# No new module boundary needed
# No new service needed
# No cross-module protocol change needed
```

```markdown
# GOOD — Dev-lead scope
"The auth module has grown to 15 files. I will refactor it into:
- auth/handlers/ (route handlers)
- auth/services/ (business logic)
- auth/repositories/ (data access)
- auth/models/ (data models)

No new module. No new service. No architectural change."
→ Handled by @dev-lead
```

**Why it's dangerous**: Escalating implementation-layer problems to @architect inflates architect involvement, creates dependency on architectural input for routine decisions, and trains the team to skip @dev-lead for problems that don't require structural change.

**Correction**: Run the intervention trigger test explicitly. New class in existing module → dev-lead. New service deploying independently → @architect. Data ownership ambiguity → @architect. Refactoring within a module → dev-lead.

---

### Ambiguity Inheritance

**Definition**: Receiving a business description with known ambiguity and writing a spec around it instead of blocking. The spec inherits the ambiguity and passes it to implementation.

**Manifestations**:
```markdown
# BAD — Ambiguity inherited
Business requirement: "Users can have different permission levels in the workspace"

## In-Scope Action List
- [ ] CREATE `models/permission.py`: Permission model
- [ ] ADD role field to workspace_members table

# Ambiguity not addressed:
# - What permission levels exist?
# - What can each level do?
# - How are levels assigned?
# @backend will have to make product decisions
```

```markdown
# GOOD — Ambiguity blocked
Business requirement: "Users can have different permission levels in the workspace"

## Status: BLOCKED

**Blocked on**: Business requirement ambiguity — permission model is underspecified

**What I need**:
1. What permission levels exist? (e.g., Owner / Admin / Member / Viewer)
2. What can each level do? (invite others? remove others? edit settings? view-only?)
3. How are levels assigned? (creator becomes Owner? Admin assigns?)
4. Can a user change their own level?
5. What happens to a member's work when they are downgraded?

**Rationale**: This is a product design gap that would force @backend to make product decisions during implementation. If I write a spec now, I would be inventing the permission model — and the implementation will be revised when the actual model is specified. The revision cost is higher than the clarification cost now.
```

**Why it's dangerous**: Ambiguity inherited into the spec becomes ambiguity in implementation. @backend makes product decisions without authority. The resulting implementation may not match the product team's intent. Rework is guaranteed.

**Correction**: Identify every business gap that would require @backend to make a product decision. BLOCK on every one. Ask specific questions that, when answered, eliminate the ambiguity.

---

### Unverifiable DoD

**Definition**: DoD items with subjective judgment that cannot be independently verified by @test-func or @backend.

**Manifestations**:
```markdown
# BAD — Unverifiable DoD
### Definition of Done
- [ ] The invitation flow feels smooth
- [ ] Users should be happy with the email design
- [ ] The API is fast enough
- [ ] Everything works as expected
```

```markdown
# GOOD — Observable DoD
### Definition of Done
- [ ] POST /workspaces/{id}/invitations with valid email returns 201 with token:
  `curl -X POST ... -d '{"email":"new@example.com"}'` → 201 {"token":"uuid..."}
- [ ] POST with invalid email returns 400 with INVALID_EMAIL:
  `curl ... -d '{"email":"not-an-email"}'` → 400 {"error_code":"INVALID_EMAIL"}
- [ ] POST by non-admin returns 403:
  `curl ... (JWT with member role)` → 403 {"error_code":"INSUFFICIENT_PERMISSION"}
- [ ] Duplicate invitation returns 200 with same token (idempotency):
  `curl ...` (twice with same email) → 201 then 200 with identical token
- [ ] Invitation email contains valid acceptance link:
  Check email body contains `https://app.example.com/accept/{token}`
- [ ] P99 response time for POST /workspaces/{id}/invitations < 200ms:
  Run `ab -n 100 -c 10 ...` and verify P99 < 200ms
```

**Why it's dangerous**: Unverifiable DoD items cannot be tested. @test-func cannot write test cases for "feels smooth." @backend cannot know when they are done. The task is never truly complete because completion is not defined.

**Correction**: Every DoD item must be a specific, observable state with a verification method: a curl command, a test assertion, a metric threshold, or a specific UI state.
