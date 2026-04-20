# Domain: Specification Engineering

## 1. Codebase Archaeology

### 1.1 Directory Structure Pattern Recognition

**Monorepo vs Single-repo**:
```
# Monorepo pattern
├── packages/
│   ├── frontend/          # React/Vue app
│   ├── backend/           # API server
│   └── shared/            # Common types/utils
├── package.json           # Root workspace config
└── turbo.json             # Build pipeline

# Single-repo pattern
├── src/
│   ├── components/        # UI components
│   ├── services/          # Business logic
│   ├── models/            # Data models
│   └── routes/            # API routes
├── tests/
└── requirements.txt
```

**Feature-based vs Layer-based**:
```
# Feature-based (preferred for large codebases)
├── features/
│   ├── auth/
│   │   ├── handlers.py
│   │   ├── service.py
│   │   ├── repository.py
│   │   └── models.py
│   └── tasks/
│       ├── handlers.py
│       ├── service.py
│       ├── repository.py
│       └── models.py

# Layer-based (preferred for small codebases)
├── handlers/
│   ├── auth.py
│   └── tasks.py
├── services/
│   ├── auth.py
│   └── tasks.py
├── repositories/
│   ├── auth.py
│   └── tasks.py
└── models/
    ├── user.py
    └── task.py
```

### 1.2 Convention Extraction

**Naming patterns**:
```python
# snake_case (Python)
def get_user_by_email(email: str) -> User | None:
    pass

# camelCase (JavaScript)
function getUserByEmail(email) {
    return userRepository.findByEmail(email);
}

# PascalCase (classes)
class InvitationService:
    pass
```

**Validation library identification**:
```python
# Pydantic (FastAPI)
from pydantic import BaseModel, EmailStr

class CreateInvitationRequest(BaseModel):
    email: EmailStr
    role: str = "member"

# Django forms
from django import forms

class InvitationForm(forms.Form):
    email = forms.EmailField()
    role = forms.ChoiceField(choices=[("admin", "Admin"), ("member", "Member")])
```

**Authentication middleware pattern**:
```python
# FastAPI dependency
async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    pass

# Django middleware
class AuthenticationMiddleware:
    def __call__(self, request):
        request.user = self.get_user(request)
        return self.get_response(request)
```

### 1.3 Technical Debt Recognition

**Classification**:
| Type | Definition | Action |
|------|-----------|--------|
| Must-resolve | Spec cannot be written without addressing | BLOCK, resolve before spec |
| Should-note | Acknowledge but don't fix | Note in spec, log for future |
| Out-of-scope | Not related to current task | Log as future task suggestion |

**Examples**:
```python
# Must-resolve: Missing migration
# Spec requires new table but migration doesn't exist
# → BLOCK on @database

# Should-note: Inconsistent naming
# Some files use snake_case, others use camelCase
# → Note in spec: "Follow existing convention in this module"

# Out-of-scope: Unrelated quality issue
# "While exploring, noticed auth module has 2000-line file"
# → Log as future task: "Refactor auth/handlers.py into smaller files"
```

---

## 2. Interface Contract Design

### 2.1 RESTful Resource Modeling

**Rules**:
- Plural nouns: `/users`, `/orders`, `/workspaces`
- Nested depth ≤ 2: `/workspaces/{id}/members` OK, `/workspaces/{id}/members/{id}/tasks` NOT OK
- Action endpoints for non-CRUD: `POST /users/{id}/actions/deactivate`
- No verbs in paths: `/getUser` → `/users/{id}`

**Resource hierarchy**:
```
GET    /workspaces              # List workspaces
POST   /workspaces              # Create workspace
GET    /workspaces/{id}         # Get workspace
PATCH  /workspaces/{id}         # Update workspace
DELETE /workspaces/{id}         # Delete workspace
GET    /workspaces/{id}/members # List members
POST   /workspaces/{id}/members # Add member
DELETE /workspaces/{id}/members/{userId} # Remove member
```

### 2.2 Request/Response Schema Precision

**Pydantic BaseModel example**:
```python
from pydantic import BaseModel, EmailStr, Field
from typing import Literal
from datetime import datetime

class CreateInvitationRequest(BaseModel):
    email: EmailStr = Field(
        ...,
        description="Invitee email address",
        examples=["user@example.com"]
    )
    role: Literal["admin", "member"] = Field(
        default="member",
        description="Role in the workspace"
    )

class InvitationResponse(BaseModel):
    id: str = Field(..., description="Invitation UUID")
    email: str
    token: str = Field(..., description="Unique acceptance token")
    role: str
    status: Literal["pending", "accepted", "expired"]
    expires_at: datetime
    created_at: datetime

class ErrorResponse(BaseModel):
    error_code: str = Field(..., description="Machine-readable error code")
    message: str = Field(..., description="Human-readable error message")
    details: dict = Field(default={}, description="Additional error context")
```

### 2.3 Error Contract Completeness

**Standard error envelope**:
```json
{
  "error_code": "BUSINESS_CODE",
  "message": "Human readable description",
  "details": {
    "field": "email",
    "reason": "invalid_format"
  }
}
```

**Error code taxonomy**:
```
# Format: {DOMAIN}_{ERROR_TYPE}
AUTH_INVALID_CREDENTIALS
AUTH_TOKEN_EXPIRED
AUTH_INSUFFICIENT_PERMISSIONS

VALIDATION_MISSING_FIELD
VALIDATION_INVALID_FORMAT
VALIDATION_OUT_OF_RANGE
VALIDATION_INVALID_ENUM

BUSINESS_RESOURCE_NOT_FOUND
BUSINESS_RESOURCE_ALREADY_EXISTS
BUSINESS_STATE_TRANSITION_INVALID

SYSTEM_INTERNAL_ERROR
SYSTEM_SERVICE_UNAVAILABLE
SYSTEM_TIMEOUT
```

---

## 3. Validation and Constraint Specification

### 3.1 Input Validation Taxonomy

| Validation Type | Example | Layer |
|----------------|---------|-------|
| Type validation | `email` must be string | API boundary |
| Range validation | `age` must be 18-120 | API boundary |
| Format validation | `email` must match RFC 5322 | API boundary |
| Enum validation | `role` must be "admin" or "member" | API boundary |
| Cross-field | `password` must match `password_confirm` | Service layer |
| Business rule | `email` must not already exist | Service layer |
| Integrity | `workspace_id` must reference existing workspace | Database layer |

### 3.2 Validation Layer Placement

```python
# API boundary: All external input
@app.post("/invitations")
async def create_invitation(
    request: CreateInvitationRequest,  # Pydantic validates
    current_user: User = Depends(get_current_user)
):
    pass

# Service layer: Business rule constraints
class InvitationService:
    async def send_invitation(self, workspace_id: str, email: str, role: str):
        # Business rule: check if email already member
        if await self.member_repo.exists(workspace_id, email):
            raise AlreadyMemberError()
        
        # Business rule: check pending invitation
        if await self.invitation_repo.has_pending(workspace_id, email):
            raise PendingInvitationExistsError()
        
        # Create invitation
        return await self.invitation_repo.create(workspace_id, email, role)

# Database layer: Integrity constraints
# UNIQUE constraint on (workspace_id, email) where status = 'pending'
# FOREIGN KEY constraint on workspace_id
```

### 3.3 Error Message Quality

**Internal vs user-facing**:
```python
# BAD — Internal message exposed to user
{"error_code": "VALIDATION_ERROR", "message": "Field email failed regex validation"}

# GOOD — User-friendly message
{"error_code": "INVALID_EMAIL", "message": "Please enter a valid email address (e.g. name@example.com)"}

# GOOD — With helpful context
{"error_code": "PASSWORD_POLICY_VIOLATION", "message": "Password must be at least 8 characters and include at least one uppercase letter and one number"}
```

---

## 4. Scope Precision Techniques

### 4.1 In-Scope Action List Format

```
[ACTION] [FILE PATH]: [SPECIFIC CHANGE DESCRIPTION]

Examples:
- CREATE src/models/invitation.py: Invitation model with fields...
- MODIFY src/services/auth_service.py: add validate_token() method...
- DELETE src/utils/deprecated.py: remove unused helper functions
```

### 4.2 Out-Scope List Writing

Each item must answer:
1. What specifically is not included?
2. Why? (out-of-scope for this task / future task / different role)

```markdown
## Out-Scope (Explicitly Excluded)
- Invitation revocation: product decision needed on hard-delete vs. mark-revoked; out-of-scope for MVP
- Bulk invitation (CSV upload): requires frontend file upload component not in current design system; future task T-024
- Reminder emails: requires scheduling mechanism; future task after core flow validated
- Non-email invitation methods: future enhancement after email flow proven
```

### 4.3 Scope Creep Detection

When @code-review or @backend returns with changes not in the spec:

1. **Evaluate**: Is this a necessary companion or unauthorized expansion?
2. **Necessary companion**: Directly required for the spec to work (e.g., adding index for query performance)
3. **Unauthorized expansion**: Nice-to-have not required by spec (e.g., adding unrelated feature)

**Response**:
- Necessary companion: Update spec to include, document rationale
- Unauthorized expansion: Revert or require explicit scheme amendment

---

## 5. Intervention Trigger Criteria

### 5.1 @architect Escalation

ANY ONE triggers escalation:
- [ ] New module with different lifecycle/ownership
- [ ] New API contract between services
- [ ] New infrastructure component (queue, cache, CDN)
- [ ] Data ownership ambiguity across modules

### 5.2 @database Escalation

ANY ONE triggers escalation:
- [ ] New table
- [ ] New column
- [ ] Changed column type/nullability/constraint
- [ ] New index
- [ ] Migration requires data transform

**Dev-lead does NOT write migration SQL.**

### 5.3 @visual-designer Escalation

ANY ONE triggers escalation:
- [ ] New UI component not in design system
- [ ] New interaction pattern not covered by existing tokens
- [ ] New color/spacing/typography token needed

"Looks similar to existing component" is NOT sufficient to skip.

---

## 6. Failure Path Design

### 6.1 Error Matrix Completeness

Every public interface must have:
- [ ] Auth failure: no token, invalid token, insufficient permissions
- [ ] Validation failure: missing field, invalid format, out of range
- [ ] External dependency failure: database error, API timeout
- [ ] Business rule violation: invalid state transition, duplicate resource

### 6.2 Concurrency Scenario Specification

```markdown
## Concurrency & Idempotency

### Duplicate Invitation
- Scenario: User clicks "Send invitation" twice
- Behavior: Second request returns 200 with existing token (idempotent)
- Mechanism: UNIQUE constraint on (workspace_id, email, status='pending')

### Concurrent Acceptance
- Scenario: Two users click acceptance link simultaneously
- Behavior: First writer wins; second gets 409 ALREADY_ACCEPTED
- Mechanism: SELECT FOR UPDATE on invitation row
- User-facing: Second user sees "This invitation has already been accepted"

### Concurrent Role Change
- Scenario: Admin A changes user role to admin while Admin B changes to member
- Behavior: Last writer wins; no merge strategy
- Mechanism: Optimistic locking with version field
- User-facing: Success message shows final state
```

### 6.3 Idempotency Specification

```markdown
## Idempotency

### Mechanism: Idempotency Key
- Key source: Client-generated UUID in header `X-Idempotency-Key`
- Storage: Redis with TTL 24 hours
- Behavior: 
  - New key: process request, store response, return 201
  - Existing key: return stored response with 200
  - Key expired: process as new request

### Mechanism: Natural UPSERT
- Operation: INSERT ... ON CONFLICT UPDATE
- Behavior: Last write wins
- Use case: Update user profile (always safe to overwrite)

### Mechanism: State Machine Guard
- Operation: Check current state before transition
- Behavior: Invalid transition returns 409 CONFLICT
- Use case: Order status changes (PENDING → PAID, not PAID → PENDING)
```
