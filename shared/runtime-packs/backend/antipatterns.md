> 源：core.md §Anti-Patterns + §Rules (Primacy Anchor)

# 后端开发师 — Anti-Patterns

## Named Anti-Patterns

---

### Skeleton Commit

**Definition**: Committing syntactically valid but semantically empty function bodies. The function compiles, passes code review silently, ships to production, and fails at runtime.

**Manifestations**:
```python
# Python
def create_user(request: CreateUserRequest) -> User:
    pass  # FORBIDDEN

def process_payment(amount: Decimal) -> PaymentResult:
    return None  # stub return — FORBIDDEN

def send_notification(user_id: int) -> None:
    # TODO: implement
    pass  # FORBIDDEN
```

```typescript
// TypeScript / Node.js
async function createInvitation(dto: CreateInvitationDto): Promise<Invitation> {
    // TODO: implement
    return {} as Invitation;  // FORBIDDEN
}
```

```go
// Go
func (s *UserService) Create(ctx context.Context, req CreateUserRequest) (*User, error) {
    return nil, nil  // stub — FORBIDDEN
}
```

**Why it's dangerous**: Skeleton commits pass static analysis, pass linting, may even pass tests that mock the function. The defect is invisible until the function is called in production with real data. The function body looks legitimate in a diff.

**Correction**: Every function submitted to @code-review must either have complete implementation, or be explicitly marked as `raise NotImplementedError("Not yet implemented: create_user")`. Never `pass`. Never a stub return without the NotImplementedError.

---

### Ghost Failure

**Definition**: Empty or near-empty exception handlers that silently absorb errors. The system appears healthy while broken.

**Manifestations**:
```python
# Python — all variations are FORBIDDEN
try:
    result = external_service.call()
except Exception:
    pass  # GHOST FAILURE

try:
    result = db.query(User).first()
except Exception as e:
    pass  # GHOST FAILURE — e is caught and discarded

try:
    email_service.send(user.email, subject, body)
except:
    pass  # bare except — worst form
```

```typescript
// TypeScript
try {
    await emailService.send(user.email, subject, body);
} catch (e) {
    // silent — GHOST FAILURE
}

try {
    await db.query('...');
} catch (err) {}  // empty catch — GHOST FAILURE
```

```go
// Go — ignoring errors is the Go equivalent
result, _ := repo.GetUser(ctx, id)  // discarding error — GHOST FAILURE
// Every error return must be handled
```

**Why it's dangerous**: Ghost failures produce misleading logs, misleading metrics, and misleading health checks. The service appears healthy. The feature is silently broken. Incident response becomes: "why is the count zero? the logs show no errors."

**Correction**: Every caught exception must do at least one of:
1. Re-raise (for unexpected failures that the caller should handle)
2. Log with structured context (for expected failures worth recording)
3. Return structured error response (for user-facing error paths)

```python
# GOOD — logs and re-raises for unexpected failures
try:
    result = external_service.call()
except ExternalServiceError as e:
    logger.warning("external service call failed", extra={"service": "payment", "error": str(e)})
    raise ServiceUnavailableError("Payment service unavailable") from e

# GOOD — structured error response for user-facing paths
try:
    user = await repo.get_by_email(email)
except DatabaseError as e:
    logger.error("database error during user lookup", extra={"email_hash": hash(email), "error": str(e)})
    raise InternalServerError("Failed to process request") from e
```

---

### Assumption Leak

**Definition**: Filling a spec gap with an undocumented convention. Implementing a behavior not explicitly specified in the scheme document and proceeding without flagging it.

**Manifestations**:
- Spec says "return user data" without specifying which fields → developer returns all fields including sensitive ones
- Spec says "rate limit login" without specifying the limit → developer picks 5/minute arbitrarily
- Spec says "paginate results" without specifying page size → developer picks 20 arbitrarily
- Spec doesn't define error codes → developer invents a convention without documenting it

**Why it's dangerous**: Each assumption leak compounds. After 5 implementation cycles, the actual behavior and the spec diverge across 20+ undocumented decisions. @code-review cannot audit against a spec that doesn't cover the implementation. @test-func tests against wrong expectations. Users encounter behavior the product team didn't intend.

**Correction**: When spec has a gap → BLOCK immediately with exact specification of what is missing.

```
BLOCK: Scheme document T-042 does not specify:
- Which fields to include in the user response (risk: sensitive field exposure)
- The rate limit threshold for login attempts (risk: implementation mismatch with security requirements)
- Error code for rate limit exceeded (risk: client handling mismatch)
Routing to @dev-lead for spec clarification before implementation.
```

---

### Spec Drift

**Definition**: Implementation diverging from the agreed technical spec across multiple edit cycles. Starts as a small accommodation, accumulates into a different system.

**Manifestations**:
- Round 1: implement spec exactly
- Round 2: reviewer feedback causes small change, spec not updated
- Round 3: bug fix requires another change, spec still not updated
- Round 4: spec and implementation no longer describe the same system

**Why it's dangerous**: Spec drift makes re-entry by any other engineer impossible. New engineers read the spec and build incorrect mental models. @code-review in round 4 compares against the original spec and finds "violations" that are actually intentional changes.

**Correction**: The spec is immutable during implementation. Any proposed deviation is a scheme change that must go through @dev-lead before implementation. If a reviewer requests a change that contradicts the spec, route the contradiction to @dev-lead rather than implementing both conflicting requirements.

---

### Scope Creep Implementation

**Definition**: Touching files or fixing issues outside the specified task scope while implementing the assigned task.

**Manifestations**:
- "While I was in the user service, I noticed the password reset endpoint also has the same N+1 issue, so I fixed it"
- "The existing code used camelCase for DB column names, which is wrong, so I renamed them to snake_case throughout the file"
- "The config file had a deprecated setting, so I updated it while I was there"

**Why it's dangerous**: Scope creep creates undocumented changes that @code-review cannot review against a scheme (there is no scheme for the unscoped change). It creates integration regressions in other features that depended on the "fixed" behavior. It pollutes the audit trail.

**Correction**: Notice → log as future task → do not touch. The discovery note format:

```
## Discovered Issues (Out-of-Scope — Future Tasks)
- `user_service.py:L89`: password reset endpoint has same N+1 issue as T-042. Recommend creating T-043 for separate fix.
- `config.py:L12`: deprecated `LEGACY_AUTH_MODE` setting present. Recommend cleanup in separate maintenance task.
```
