# Domain: Definition of Done Engineering

## 1. Observable Criterion Design

### 1.1 HTTP Endpoint DoD Template

```markdown
### Definition of Done

#### Success Path
- [ ] `[METHOD] [PATH]` with valid input returns [STATUS]:
  ```bash
  curl -X [METHOD] [URL]/[PATH] \
    -H "Authorization: Bearer [token]" \
    -H "Content-Type: application/json" \
    -d '[valid payload]' \
    # Expected: [STATUS] [response body]
  ```

#### Auth Failure
- [ ] `[METHOD] [PATH]` without token returns 401:
  ```bash
  curl -X [METHOD] [URL]/[PATH]
  # Expected: 401 {"error_code": "UNAUTHORIZED", "message": "Authentication required"}
  ```

#### Validation Failure
- [ ] `[METHOD] [PATH]` with invalid field returns 422:
  ```bash
  curl -X [METHOD] [URL]/[PATH] \
    -H "Authorization: Bearer [token]" \
    -H "Content-Type: application/json" \
    -d '[invalid payload]' \
    # Expected: 422 {"error_code": "[CODE]", "message": "[message]"}
  ```

#### Business Rule Violation
- [ ] `[METHOD] [PATH]` with valid but business-invalid input returns [STATUS]:
  ```bash
  curl -X [METHOD] [URL]/[PATH] \
    -H "Authorization: Bearer [token]" \
    -H "Content-Type: application/json" \
    -d '[business-invalid payload]' \
    # Expected: [STATUS] {"error_code": "[CODE]", "message": "[message]"}
  ```
```

### 1.2 Non-Functional DoD Criteria

| Category | Criterion | Verification Method |
|----------|-----------|---------------------|
| Performance | P99 response time < 200ms | `ab -n 1000 -c 10 [URL]` |
| Performance | No N+1 queries | SQL query log analysis |
| Security | No SQL injection | Parameterized queries verified |
| Security | No credentials in logs | Log grep for secrets |
| Security | Input validation on all fields | Schema review |
| Reliability | Idempotency verified | Duplicate request test |
| Reliability | Concurrency handled | Simultaneous request test |
| Accessibility | Keyboard navigable | Manual tab-through test |
| Accessibility | Focus rings visible | Visual inspection |

### 1.3 DoD Independence Guarantee

Each DoD item must be independently testable:

**BAD** (dependent items):
```markdown
- [ ] User can create invitation
- [ ] User can view created invitation (depends on first item)
- [ ] User can accept invitation (depends on first two items)
```

**GOOD** (independent items):
```markdown
- [ ] POST /workspaces/{id}/invitations returns 201 with valid input
- [ ] GET /workspaces/{id}/invitations returns list including existing invitation
- [ ] POST /invitations/{token}/accept returns 200 with valid token
```

---

## 2. Regression Identification

### 2.1 Existing Test Impact

```markdown
## Regression Checklist
- [ ] Existing auth tests pass: `pytest tests/auth/ -v`
- [ ] Existing workspace tests pass: `pytest tests/workspaces/ -v`
- [ ] New invitation tests added to CI pipeline
```

### 2.2 Adjacent Behavior Preservation

When modifying shared utilities:
```markdown
## Adjacent Feature Verification
- [ ] User registration still works (shares email validation logic)
- [ ] Password reset still works (shares token generation logic)
- [ ] Workspace creation still works (shares permission check logic)
```

### 2.3 Migration Rollback Scenario

```markdown
## Migration Safety
- [ ] Behavior verified WITH migration applied
- [ ] Rollback plan documented: `alembic downgrade -1`
- [ ] Rollback tested on staging environment
- [ ] Data loss risk assessment: NONE (new table only)
```

---

## 3. Scheme Review Protocol

### 3.1 Self-Review Checklist

Before delivering a spec, verify:

- [ ] All files named with specific paths
- [ ] All interfaces defined (method, path, request, response, errors)
- [ ] All error conditions specified (status, code, message)
- [ ] All input fields validated (type, length, format, enum)
- [ ] DoD has ≥3 items with ≥1 error path
- [ ] Out-scope has ≥2 items
- [ ] Minimum change rationale documented
- [ ] No business ambiguity left unaddressed
- [ ] Intervention triggers evaluated
- [ ] Dependencies identified and routed

### 3.2 Peer Review Criteria

When reviewing another dev-lead's spec:

1. **Ambiguity scan**: Read as @backend — any moment of "I'd need to figure this out"?
2. **Edge case coverage**: Missing error conditions? Missing validation rules?
3. **Pattern consistency**: Does it match existing codebase conventions?
4. **Feasibility**: Can this be implemented in the estimated time?
5. **Scope boundaries**: Is Out-scope clearly cutting? Any scope leak?

### 3.3 Revision Tracking

```markdown
## Changelog
- v1.0 (2024-01-15): Initial spec
- v1.1 (2024-01-16): Added rate limiting to POST /workspaces/{id}/invitations
- v1.2 (2024-01-17): Changed token format from JWT to UUID per @security-auditor review
```

---

## 4. DoD Examples by Task Type

### 4.1 API Endpoint DoD

```markdown
### Definition of Done
- [ ] POST /api/v1/users with valid data returns 201:
  `curl -X POST ... -d '{"email":"test@example.com","password":"Secure123!"}'` → 201 {"id":"uuid","email":"test@example.com"}
- [ ] POST with duplicate email returns 409:
  `curl ... -d '{"email":"existing@example.com",...}'` → 409 {"error_code":"EMAIL_EXISTS"}
- [ ] POST with weak password returns 422:
  `curl ... -d '{"email":"test@example.com","password":"123"}'` → 422 {"error_code":"PASSWORD_TOO_WEAK"}
- [ ] POST without auth header returns 401:
  `curl ...` (no Authorization) → 401 {"error_code":"UNAUTHORIZED"}
- [ ] P99 latency < 200ms under load:
  `ab -n 1000 -c 10 ...` → P99 < 200ms
```

### 4.2 Frontend Component DoD

```markdown
### Definition of Done
- [ ] Component renders in all 5 states (initial, empty, loading, success, error)
- [ ] Form validation triggers on blur for all fields
- [ ] Submit button disabled until all fields valid
- [ ] Error messages display under correct fields
- [ ] Mobile viewport (375px) renders without horizontal scroll
- [ ] Keyboard navigation works (Tab order, Enter to submit, Escape to close)
- [ ] Screen reader announces dynamic content changes
- [ ] No console errors in any state
```

### 4.3 Database Migration DoD

```markdown
### Definition of Done
- [ ] Migration applies successfully: `alembic upgrade head`
- [ ] Migration rolls back successfully: `alembic downgrade -1`
- [ ] Data integrity preserved: existing data unchanged
- [ ] New constraints enforced: attempt to violate → error
- [ ] Query performance acceptable: EXPLAIN ANALYZE shows index usage
- [ ] Downstream services unaffected: integration tests pass
```

---

## 5. Collaboration Boundaries

### 5.1 Dev-Lead ↔ Architect

| Scenario | Who Decides | Who Implements |
|----------|-------------|----------------|
| New module boundary | @architect | @dev-lead (spec) |
| Module internal refactoring | @dev-lead | @dev-lead (spec) |
| New infrastructure component | @architect | @dev-lead (spec) |
| Service extraction decision | @architect | @dev-lead (spec) |

### 5.2 Dev-Lead ↔ Database Engineer

| Scenario | Who Decides | Who Implements |
|----------|-------------|----------------|
| New table/column | @database | @database (migration) |
| Index strategy | @database | @database (migration) |
| Query optimization | @database | @backend (code) |
| Schema design review | @dev-lead | @database (migration) |

### 5.3 Dev-Lead ↔ Visual Designer

| Scenario | Who Decides | Who Implements |
|----------|-------------|----------------|
| New design token | @visual-designer | @visual-designer |
| Component layout | @visual-designer | @frontend (code) |
| Interaction behavior | @dev-lead (spec) | @frontend (code) |
| Token usage in code | @dev-lead (review) | @frontend (code) |

### 5.4 Dev-Lead ↔ ML Engineer

| Scenario | Who Decides | Who Implements |
|----------|-------------|----------------|
| Model architecture | @ml-engineer | @ml-engineer |
| Feature engineering | @ml-engineer | @ml-engineer |
| API contract for inference | @dev-lead | @dev-lead (spec) |
| Integration pattern | @dev-lead | @backend (code) |

---

## 6. Complexity Control

### 6.1 Cyclomatic Complexity Budget

| Component | Max Complexity | Action When Exceeded |
|-----------|---------------|---------------------|
| Route handler | 5 | Extract validation to schema |
| Service method | 10 | Extract helper methods |
| Repository method | 5 | Use query builder |
| Utility function | 8 | Split into smaller functions |

### 6.2 File Size Guidelines

| File Type | Max Lines | Action When Exceeded |
|-----------|-----------|---------------------|
| Route handler | 200 | Split by resource |
| Service class | 300 | Extract sub-services |
| Repository class | 200 | Split by entity |
| Test file | 400 | Split by scenario |

### 6.3 Interface Count Limits

| Class Type | Max Public Methods | Action When Exceeded |
|------------|-------------------|---------------------|
| Service | 10 | Split by responsibility |
| Repository | 8 | Split by query type |
| Controller | 6 | Split by resource |
