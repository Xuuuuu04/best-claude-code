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
    return {} as Invitation;  # FORBIDDEN
}
```

```go
// Go
func (s *UserService) Create(ctx context.Context, req CreateUserRequest) (*User, error) {
    return nil, nil  // stub — FORBIDDEN
}
```

```rust
// Rust
async fn create_user(Json(req): Json<CreateUserRequest>) -> Result<Json<User>, AppError> {
    todo!()  // FORBIDDEN in production paths
}
```

**Why it's dangerous**: Skeleton commits pass static analysis, pass linting, may even pass tests that mock the function. The defect is invisible until the function is called in production with real data. The function body looks legitimate in a diff.

**Correction**: Every function submitted to @code-review must either have complete implementation, or be explicitly marked as `raise NotImplementedError("Not yet implemented: create_user")` / `todo!("reason")`. Never `pass`. Never a stub return without the NotImplementedError.

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

```rust
// Rust — ignoring Result with let _ =
let _ = email_service.send(user_id).await;  // GHOST FAILURE
// Correction: use ? or match
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

---

### Connection Pool Exhaustion

**Definition**: Opening database connections without proper lifecycle management, leading to pool exhaustion under load.

**Manifestations**:
```python
# BAD — connection not closed
conn = db_pool.getconn()
cursor = conn.cursor()
cursor.execute("SELECT * FROM users")
# Missing: conn.close() or pool.putconn(conn)

# BAD — opening connection per row in a loop
for user_id in user_ids:
    conn = db_pool.getconn()  # 1000 users = 1000 connections
    ...
```

```go
// BAD — not returning connections to pool
func (r *Repo) Query(ctx context.Context) {
    db.WithContext(ctx).Raw("SELECT ...").Scan(&results)
    // GORM handles this, but raw sql.DB requires Close()
}
```

**Why it's dangerous**: Under production load, connection pool exhaustion causes cascading failures — all requests block waiting for connections, response times spike, health checks fail, service restarts. The root cause is invisible in application logs.

**Correction**: Always use connection context managers. In Python: `with pool.getconn() as conn:`. In Go: GORM handles pooling automatically; raw `sql.DB` uses `defer rows.Close()`. Monitor pool metrics: active connections, idle connections, wait queue depth.

```python
# GOOD — context manager ensures return to pool
with db_pool.connection() as conn:
    with conn.cursor() as cursor:
        cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
        return cursor.fetchone()
```

---

### N+1 Cascade

**Definition**: A single API request triggers an unbounded number of database queries due to lazy loading in loops, often compounding across multiple nested relationships.

**Manifestations**:
```python
# BAD — N+1 in a loop, each item triggers another query
orders = session.query(Order).filter(Order.user_id == user_id).all()
return [
    {
        "id": order.id,
        "items": [item.to_dict() for item in order.items],  # 1 query per order
        "customer": order.customer.to_dict(),  # 1 query per order
    }
    for order in orders
]
# For 50 orders: 1 + 50 + 50 = 101 queries
```

**Why it's dangerous**: N+1 cascades turn O(1) API calls into O(n) database load. With nested relationships, complexity becomes O(n²). A single request that should take 50ms takes 5 seconds. Under concurrent load, the database CPU saturates.

**Correction**: Eager load all required relationships before the loop. Use `joinedload` for one-to-one, `selectinload` for one-to-many. Measure query count with SQL logging enabled.

```python
# GOOD — eager load with selectinload (2 queries total)
orders = (
    session.query(Order)
    .options(
        selectinload(Order.items),
        joinedload(Order.customer),
    )
    .filter(Order.user_id == user_id)
    .all()
)
```

---

### Transaction Boundary Leak

**Definition**: Holding a database transaction open during external service calls, network I/O, or other slow operations.

**Manifestations**:
```python
# BAD — transaction holds lock during email send
async with db.begin() as txn:
    invitation = await invitation_repo.create(txn, req)
    await email_service.send(invitation.email, ...)  # 2-5 seconds, lock held
    await audit_repo.create(txn, {...})
```

```go
// BAD — same pattern in Go
db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
    tx.Create(&order)
    paymentClient.Charge(ctx, order.Amount)  // external call inside transaction
    tx.Create(&auditLog)
    return nil
})
```

**Why it's dangerous**: Database locks are held for the duration of the external call. Under load, this causes lock contention, connection pool exhaustion, and cascading timeouts. The email service's slowness becomes the database's slowness.

**Correction**: External calls happen AFTER transaction commit. Use outbox pattern or background tasks for operations that need transactional guarantees alongside external calls.

```python
# GOOD — commit first, then send email
async with db.begin() as txn:
    invitation = await invitation_repo.create(txn, req)
    await audit_repo.create(txn, {...})
# Transaction committed here

# Email sent outside transaction
await email_service.send(invitation.email, ...)
# Or use background task:
background_tasks.add_task(email_service.send_invitation_email, invitation.id)
```

---

### Magic String Configuration

**Definition**: Hardcoding environment-specific values (URLs, timeouts, feature flags) in source code instead of external configuration.

**Manifestations**:
```python
# BAD — hardcoded in source
API_TIMEOUT = 30  # seconds
STRIPE_WEBHOOK_SECRET = "whsec_test_xxx"  # committed to git
REDIS_URL = "redis://localhost:6379/0"
```

```go
// BAD — hardcoded in source
const (
    MaxRetries = 3
    RetryDelay = 2 * time.Second
    PaymentGatewayURL = "https://api.stripe.com/v1"
)
```

**Why it's dangerous**: Environment-specific values in source code require code changes to adjust behavior. Secrets in source code are exposed in git history forever. Different environments (dev/staging/prod) need different values — hardcoding forces conditional logic or branch divergence.

**Correction**: All environment-specific values load from environment variables or secrets manager at startup. Fail fast if required config is missing.

```python
# GOOD — pydantic-settings with validation
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    api_timeout: int = 30
    stripe_webhook_secret: str  # required — missing = startup failure
    redis_url: str = "redis://localhost:6379/0"
    max_retries: int = 3

    class Config:
        env_file = ".env"

settings = Settings()  # Fails at startup if stripe_webhook_secret missing
```

```rust
// GOOD — envy + serde
use serde::Deserialize;

#[derive(Deserialize, Debug)]
struct Config {
    #[serde(default = "default_timeout")]
    api_timeout: u64,
    stripe_webhook_secret: String,  // required
    #[serde(default = "default_redis_url")]
    redis_url: String,
}

fn default_timeout() -> u64 { 30 }
fn default_redis_url() -> String { "redis://localhost:6379/0".to_string() }

let config: Config = envy::from_env().expect("Missing required environment variables");
```
