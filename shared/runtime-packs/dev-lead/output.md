# 开发组长 — Output Contract

## Standard Output Format

```
## Technical Scheme: [Task ID] — [Task Name]

**Background**: [One sentence: business driver for this change]
**Approach selected**: [Which approach and why]

### In-Scope Action List
- [ ] [CREATE/MODIFY] `path/to/file.py`: [specific change — class/function, parameter types, return type, behavior]

### Out-Scope (Explicitly Excluded)
- [Item]: [reason — minimum 2 items]

### Interface Contract
**[METHOD] /path/resource**
Auth: [required (JWT) / none]
Request: `{"field": "type, required/optional, validation constraints"}`
Response [status]: `{...}`
Error [status]: `{"error_code": "CODE", "message": "user-facing message"}`

### Validation Rules
| Field | Type | Required | Min | Max | Format | Notes |

### Error Handling Matrix
| Trigger | HTTP Status | Error Code | Log Level | User Message |

### Concurrency & Idempotency
[How duplicate/concurrent requests are handled]

### Dependencies (Other Agents Required First)
- @database: [specific migration needed]

### Definition of Done
- [ ] [specific observable behavior + verification method — minimum 3, at least 1 error-path]

### Future Task Suggestions (Out-of-Scope Improvements Noticed)
- [Issue observed]: [brief description for future consideration]
```

---

## Filled Example: T-019 Invitation System

```
## Technical Scheme: T-019 — Email Invitation System

**Background**: Workspace owners need to invite new members by email before those members have accounts.
**Approach selected**: Token-based invitation flow with email delivery. [MINIMUM CHANGE RATIONALE: OAuth-style invitation is overkill for MVP; token-based is sufficient and can evolve to OAuth later.]

### In-Scope Action List
- [ ] CREATE `models/invitation.py`: Invitation model with fields: id (UUID PK), workspace_id (FK, UUID), email (VARCHAR 254), token (UUID, UNIQUE), role (ENUM: admin/member), expires_at (TIMESTAMP), created_at (TIMESTAMP), accepted_at (TIMESTAMP, nullable)
- [ ] CREATE `repositories/invitation_repository.py`: InvitationRepository class with methods: create(workspace_id, email, role) → Invitation, get_by_token(token) → Invitation | None, mark_accepted(invitation_id) → None, list_by_workspace(workspace_id) → List[Invitation]
- [ ] CREATE `services/invitation_service.py`: InvitationService class with methods: send_invitation(workspace_id, email, role) → Invitation, accept_invitation(token, user_id) → None, list_pending(workspace_id) → List[Invitation]
- [ ] CREATE `routes/invitations.py`: three routes — POST /workspaces/{id}/invitations (create+send), POST /invitations/{token}/accept, GET /workspaces/{id}/invitations
- [ ] MODIFY `services/email_service.py`: add send_invitation_email(to_email, token, workspace_name) → None

### Out-Scope (Explicitly Excluded)
- Invitation revocation: product decision needed on whether revoked invitations should be hard-deleted or marked revoked; out-of-scope for MVP
- Bulk invitation (CSV upload): requires frontend file upload component not in current design system; future task
- Reminder emails: requires scheduling mechanism (cron or queue); future task after core flow validated
- Non-email invitation methods (magic link, OAuth): future enhancement

### Interface Contract
**POST /workspaces/{id}/invitations**
Auth: required (JWT), permission: workspace:admin
Request: `{"email": "string, required, max 254, RFC 5322", "role": "enum[admin, member], default: member"}`
Response 201: `{"id": "uuid", "email": "string", "token": "uuid", "expires_at": "ISO8601"}`
Error 400: `{"error_code": "INVALID_EMAIL", "message": "Please enter a valid email address"}`
Error 403: `{"error_code": "INSUFFICIENT_PERMISSION", "message": "Only workspace admins can send invitations"}`
Error 409: `{"error_code": "ALREADY_MEMBER", "message": "This user is already a member of the workspace"}`
Error 409: `{"error_code": "PENDING_INVITATION_EXISTS", "message": "An invitation is already pending for this email"}`

**POST /invitations/{token}/accept**
Auth: required (JWT)
Request: `{}`
Response 200: `{"workspace_id": "uuid", "role": "string"}`
Error 400: `{"error_code": "INVALID_TOKEN", "message": "This invitation link is invalid or has expired"}`
Error 409: `{"error_code": "ALREADY_ACCEPTED", "message": "This invitation has already been accepted"}`

**GET /workspaces/{id}/invitations**
Auth: required (JWT), permission: workspace:admin
Response 200: `{"items": [{"id": "uuid", "email": "string", "role": "string", "status": "pending|accepted|expired", "created_at": "ISO8601"}]}`

### Validation Rules
| Field | Type | Required | Min | Max | Format | Notes |
|-------|------|----------|-----|-----|--------|-------|
| email | string | Yes | 3 | 254 | RFC 5322 | Reject disposable email domains |
| role | enum | No | — | — | admin, member | Default: member |
| token (path) | UUID | Yes | 36 | 36 | UUID v4 | URL path parameter |

### Error Handling Matrix
| Trigger | HTTP Status | Error Code | Log Level | User Message |
|---------|-------------|------------|-----------|--------------|
| Invalid email format | 400 | INVALID_EMAIL | WARN | Please enter a valid email address |
| Missing email | 400 | MISSING_FIELD | WARN | Email is required |
| Invalid role value | 422 | INVALID_ENUM | WARN | Role must be 'admin' or 'member' |
| Non-admin sender | 403 | INSUFFICIENT_PERMISSION | WARN | Only workspace admins can send invitations |
| Email already member | 409 | ALREADY_MEMBER | INFO | This user is already a member |
| Pending invitation exists | 409 | PENDING_INVITATION_EXISTS | INFO | An invitation is already pending |
| Invalid/expired token | 400 | INVALID_TOKEN | WARN | This invitation link is invalid or has expired |
| Already accepted | 409 | ALREADY_ACCEPTED | INFO | This invitation has already been accepted |
| Email send failure | 500 | EMAIL_DELIVERY_FAILED | ERROR | We couldn't send the invitation email. Please try again. |

### Concurrency & Idempotency
- Duplicate invitation for same email: returns 200 with existing token (idempotent)
- Concurrent acceptance: first writer wins; second gets 409 ALREADY_ACCEPTED
- Token uniqueness: database UNIQUE constraint on token
- Expiration: 7 days from creation; checked at acceptance time

### Dependencies (Other Agents Required First)
- @database: T-018 migration for invitations table (id UUID PK, workspace_id FK, email VARCHAR(254), token UUID UNIQUE, role VARCHAR(20), expires_at TIMESTAMP, created_at TIMESTAMP, accepted_at TIMESTAMP)
- @visual-designer: Invitation email template (token-based acceptance link)

### Definition of Done
- [ ] POST /workspaces/{id}/invitations with valid email returns 201 with token: `curl -X POST ... -d '{"email":"new@example.com"}'` → 201 {"token":"uuid..."}
- [ ] POST with invalid email returns 400 with INVALID_EMAIL: `curl ... -d '{"email":"not-an-email"}'` → 400
- [ ] POST by non-admin returns 403: `curl ... (as member)` → 403
- [ ] Duplicate invitation returns 200 with same token: `curl ...` (twice) → 201 then 200
- [ ] POST /invitations/{token}/accept with valid token returns 200 and adds user to workspace
- [ ] Accept with expired token returns 400 INVALID_TOKEN: create invitation, wait 7 days, accept → 400
- [ ] Accept same token twice: first 200, second 409 ALREADY_ACCEPTED
- [ ] GET /workspaces/{id}/invitations returns list with correct statuses

### Future Task Suggestions
- `invitation_service.py`: add revoke_invitation() method for admin cancellation
- `routes/invitations.py`: add DELETE endpoint for invitation revocation
- Email delivery: add retry mechanism with exponential backoff for transient failures
```

---

## Output Component Requirements

### In-Scope Action List

Each item must be:
- **Action**: CREATE, MODIFY, or DELETE
- **File path**: Exact path relative to project root
- **Specific change**: Class name, method signatures, parameter types, return types, behavior

**BAD**: "Add validation to the password reset endpoint"
**GOOD**: "MODIFY `auth/handlers/reset_password.py`: add validation to POST /auth/reset-password: token field (required, UUID v4), new_password field (required, min 8, max 128, ≥1 uppercase, ≥1 digit)"

### Out-Scope List

Each item must answer:
- What specifically is not included?
- Why? (out-of-scope for this task / future task / different role)

Minimum 2 items required.

### Interface Contract

For every new or changed endpoint:
- **METHOD + PATH**: HTTP method and resource path
- **Auth**: Required or none, and permission if required
- **Request**: Every field with type, required/optional, validation constraints
- **Response**: Status code and body schema for success
- **Error**: Status code, error_code, and user-facing message for every error condition

### Validation Rules Table

Required columns:
- **Field**: Parameter or body field name
- **Type**: Data type (string, integer, boolean, enum, UUID, etc.)
- **Required**: Yes/No
- **Min**: Minimum length/value
- **Max**: Maximum length/value
- **Format**: Regex, enum values, or format specification
- **Notes**: Additional constraints (cross-field, business rules)

### Error Handling Matrix

Required columns:
- **Trigger**: What causes the error
- **HTTP Status**: Response status code
- **Error Code**: Machine-readable error code (string constant)
- **Log Level**: INFO/WARN/ERROR
- **User Message**: Human-readable message displayed to user

Every public interface must have at least: auth failure, validation failure, business rule violation.

### Definition of Done

Minimum 3 items, at least 1 error-path:
- Each item must be independently observable
- Each item must have a verification method (curl command, test assertion, metric)
- Each item must be testable from a clean state

---

## BLOCKED Output Format

When spec cannot be completed:

```
## Technical Scheme: [Task ID] — [Task Name]

**Status**: BLOCKED

**Blocked on**: [specific condition]

**Blocked by**: [@pm / @client / @architect / @database / @visual-designer / user]

**What is needed**:
1. [specific requirement 1]
2. [specific requirement 2]

**What is clear so far**:
- [partial specification that doesn't require the blocked item]

**Next Step**: [who needs to act and what they need to provide]
```
