# 后端开发师 — Baseline Scenarios

## Scenario 1: JWT Auth Endpoint Implementation (Canonical)

**Input**:
- @dev-lead scheme: "Implement POST /auth/login. Accepts { email, password }. Returns { token, user: { id, email, role } }. Use bcrypt for password comparison. JWT expires in 7 days, signed with RS256, secret in env var JWT_PRIVATE_KEY. Error codes: 400 (validation error), 401 (invalid credentials), 500 (server error). Stack: FastAPI + SQLAlchemy + PostgreSQL. User table already exists with migration applied."

**Expected Output Structure**:
- READ scheme fully — all required fields answered: which files change (auth router, user service, user schema), interfaces defined (POST /auth/login), error codes defined (400/401/500), auth model defined (RS256 JWT), data access confirmed (User table + migration applied)
- EXPLORE existing code: Grep for existing routers, middleware patterns, naming conventions. Match project conventions.
- CHECK database prerequisites: verify alembic current shows migration applied before touching data access code

- IMPLEMENT in strict layer order:
  1. DTO/Schema (input validation): Pydantic BaseModel — email: EmailStr, password: str with min_length=8
  2. Repository: `get_user_by_email(email) → User | None` — parameterized query, no business logic
  3. Service: `login(email, password) → AuthResult` — bcrypt.checkpw, JWT creation with RS256 signing, 7-day expiry
  4. Controller: POST /auth/login route — parse request, call service, format response, map exceptions to HTTP codes

- Security baseline self-check (all five must pass):
  - SQL parameterization: SQLAlchemy ORM parameterizes automatically [✓]
  - bcrypt: `bcrypt.checkpw(password.encode(), stored_hash)` [✓]
  - Credentials in env vars: `JWT_PRIVATE_KEY = os.environ["JWT_PRIVATE_KEY"]` [✓]
  - Input validation: email format + password min_length enforced in Pydantic schema [✓]
  - No credentials in logs: `logger.info("Login attempt", email=email)` — no password logged [✓]

- Self-test output:
  ```bash
  # Happy path
  curl -X POST /auth/login -d '{"email":"user@test.com","password":"correct_pw"}'
  # → 200 {"token":"eyJ...", "user":{"id":1,"email":"user@test.com","role":"user"}}

  # Error path
  curl -X POST /auth/login -d '{"email":"user@test.com","password":"wrong_pw"}'
  # → 401 {"detail":"Invalid credentials"}
  ```

- Deliverable: Implementation report with changed files, self-test output, security baseline all-pass, @code-review recommendation

**Key Decision Points**:
- Bottom-up implementation order (DTO → repo → service → controller) is mandatory — writing controller first produces untestable, coupled code
- BLOCK condition enforced: if scheme said "JWT authentication" without defining signing algorithm → BLOCK immediately before any code
- bcrypt.checkpw is the password comparison — raw string comparison is a critical security defect
- No opportunistic refactoring: existing unrelated code quality issues logged as future tasks, not touched

---

## Scenario 2: BLOCKED — Missing Spec and Pending Migration

**Input**:
- @dev-lead scheme: "Implement the invite member endpoint. POST /workspaces/{id}/invitations. It should send an invitation. The invitations table has all the fields you need."

**Expected Output Structure**:

**BLOCKED — four spec gaps prevent implementation:**

**Block 1 — Missing auth model:**
"The scheme does not define the authentication model for this endpoint. Options include: JWT (if so, which claim carries the workspace permission?), API key, or public endpoint. I cannot implement auth middleware without this definition. BLOCK: @dev-lead needs to define the authentication and authorization model (who can invite — only workspace owners? any member?)."

**Block 2 — Missing field definitions:**
"The scheme says 'send an invitation' but does not define: (a) what fields the request body accepts — invitee email? role? message? (b) what error codes are defined for the invalid states — what happens if the email is already a member? if the email already has a pending invitation? if the workspace is at its member limit? BLOCK: @dev-lead needs to define the request body schema and error code inventory."

**Block 3 — Migration status unknown:**
"The scheme references 'the invitations table' but I cannot verify whether this migration has been applied without running alembic current. I will not write data access code until I have confirmed the migration is applied. If it is pending → BLOCK on @database."

**Block 4 — Email sending mechanism:**
"'Send an invitation' implies an email. The scheme does not define: which email service (SMTP/SendGrid/AWS SES), what happens if email delivery fails (rollback the invitation record? still create and mark as 'email_pending'?), whether this is synchronous or async via a task queue. BLOCK: @dev-lead needs to define the email mechanism and failure behavior."

**Status**: BLOCKED on four items
**Unblock conditions**:
1. Auth model defined (who can call this endpoint, what permission is required)
2. Request body schema and error code inventory provided
3. Migration verified as applied (or @database provides migration and I can check after it runs)
4. Email sending mechanism and failure behavior defined

**Key Decision Points**:
- All four block conditions identified and named separately — not collapsed into "needs more information"
- BLOCK does not mean the task is rejected — it means implementation cannot proceed safely without these definitions
- No speculative implementation provided ("here's what it might look like") — guessed conventions compound into architectural debt
- Block 3 (migration) is a technical dependency on @database, not a spec gap from @dev-lead

---

## Scenario 3: Bug Fix — N+1 Query in Order Service

**Input**:
- @backend: "The GET /orders endpoint is taking 4-8 seconds in production. We think it's a query problem. The endpoint lists all orders for the current user, including each order's items."

**Expected Output Structure**:
- REPRODUCE first: Run the query with SQL logging enabled to confirm the N+1 pattern before changing code

- DIAGNOSIS (typical N+1 pattern):
  ```python
  # Existing code (BAD — N+1):
  orders = session.query(Order).filter(Order.user_id == user_id).all()
  return [
      {
          "id": order.id,
          "items": [item.to_dict() for item in order.items]  # triggers 1 query per order
      }
      for order in orders
  ]
  # For 50 orders: 1 + 50 = 51 database queries
  ```

- FIX (minimum scope — do not refactor anything else):
  ```python
  # Fix: eager load with joinedload
  orders = (
      session.query(Order)
      .options(joinedload(Order.items))  # single JOIN query
      .filter(Order.user_id == user_id)
      .all()
  )
  return [
      {
          "id": order.id,
          "items": [item.to_dict() for item in order.items]  # uses already-loaded data
      }
      for order in orders
  ]
  # For 50 orders: 1 query with JOIN (or 2 queries with selectinload — both are correct)
  ```

- SCOPE assessment: this fix is purely at the implementation layer (data access pattern). No scheme change required. Proceed.

- REGRESSION test: run existing test suite for order service. Verify GET /orders returns same results with same data.

- Self-test measuring improvement:
  ```bash
  # Before: 51 queries, ~4200ms
  # After: 1 query with JOIN, ~180ms
  curl -w "%{time_total}" /orders  # measure response time after fix
  ```

- Security baseline: N/A (no change to auth, validation, or data paths)

- Deliverable: Bug fix report with: root cause confirmed (N+1 pattern in 3 locations in order_service.py), minimum fix applied (joinedload added), regression test results, response time before/after, @code-review recommendation

**Key Decision Points**:
- REPRODUCE before fix — never change code without confirming the bug exists and understanding its shape
- MINIMUM fix: only N+1 fix is in scope — discovered unrelated code quality issues are logged as future tasks
- No scheme change required: N+1 is an implementation defect, not a design defect
- Measure before/after: "it should be faster" is not a self-test; response time delta is

---

## Scenario 4: BLOCKED — Transaction Boundary Leak + External Call

**Input**:
- @dev-lead scheme: "Implement payment processing endpoint. POST /payments. Create payment record, charge via Stripe, create audit log. All three must succeed or fail together. Stack: FastAPI + SQLAlchemy + PostgreSQL."

**Expected Output Structure**:

**BLOCKED — scheme contains an unsafe transaction boundary design:**

"The scheme states 'all three must succeed or fail together' referring to: (1) create payment record, (2) charge via Stripe, (3) create audit log. This design holds a database transaction open during an external HTTP call to Stripe (typically 500ms–3s). Under concurrent load, this causes:
- Database connection pool exhaustion (connections held for Stripe latency)
- Lock contention on payment-related rows
- Cascading timeouts when Stripe is slow

**BLOCK**: The 'all together' requirement cannot be implemented as a single database transaction that includes the Stripe call. Two safe alternatives:

**Option A — Outbox Pattern (recommended):**
1. DB transaction: create payment record (status='pending') + audit log
2. Commit transaction
3. Call Stripe API
4. If Stripe succeeds: update payment status='completed' in new transaction
5. If Stripe fails: update payment status='failed', trigger refund/retry workflow

**Option B — Saga Pattern:**
1. Create payment record (status='pending')
2. Call Stripe API
3. If Stripe succeeds: create audit log, update status='completed'
4. If Stripe fails after step 1: compensation transaction updates status='failed'

Routing to @dev-lead for scheme revision before implementation."

**Key Decision Points**:
- Identified the architectural flaw (transaction boundary leak) before writing any code
- Provided two concrete alternatives with tradeoffs
- Did not implement the unsafe pattern "because the scheme said so" — the scheme is not a suicide pact
- Escalated to @dev-lead because this is a design-level decision, not an implementation detail

---

## Scenario 5: Rust Axum Endpoint — Async + Error Handling

**Input**:
- @dev-lead scheme: "Implement POST /api/v1/users in Rust Axum. Accepts JSON { email, password, display_name }. Returns 201 with user object. Validates: email format, password 8-128 chars. Uses sqlx with PostgreSQL. Hash password with argon2. Stack: Axum + Tokio + sqlx + PostgreSQL."

**Expected Output Structure**:
- READ scheme fully — all required fields answered
- CHECK: `sqlx migrate status` confirms migrations applied
- IMPLEMENT bottom-up:
  1. DTO: `CreateUserRequest` struct with validation
  2. Repository: `create_user()` with sqlx query!
  3. Service: `create_user()` with argon2 hashing
  4. Handler: Axum route with Json extractor, State, custom error response

```rust
// handler.rs
async fn create_user(
    State(state): State<AppState>,
    Json(req): Json<CreateUserRequest>,
) -> Result<(StatusCode, Json<UserResponse>), AppError> {
    let user = user_service::create(&state.db, req).await?;
    Ok((StatusCode::CREATED, Json(UserResponse::from(user))))
}

// service.rs
pub async fn create(pool: &PgPool, req: CreateUserRequest) -> Result<User, AppError> {
    let password_hash = hash_password(&req.password)?;
    let user = user_repo::create(pool, &req.email, &password_hash, &req.display_name).await?;
    Ok(user)
}

// repository.rs
pub async fn create(pool: &PgPool, email: &str, password_hash: &str, display_name: &str) -> Result<User, sqlx::Error> {
    query_as!(User,
        r#"INSERT INTO users (email, password_hash, display_name) VALUES ($1, $2, $3) RETURNING id, email, display_name, created_at"#,
        email, password_hash, display_name
    )
    .fetch_one(pool)
    .await
}
```

- Security baseline:
  - SQL parameterization: ✓ (sqlx query! macro parameterizes automatically)
  - Password handling: ✓ (argon2 hashing, no plaintext storage)
  - Credential externalization: ✓ (DATABASE_URL from env)
  - Input validation: ✓ (email format + password length in handler layer)
  - Log hygiene: ✓ (no password in logs)

- Self-test:
  ```bash
  curl -X POST http://localhost:3000/api/v1/users \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"secure123","display_name":"Test User"}'
  # → 201 {"id":1,"email":"test@example.com","display_name":"Test User"}
  ```

**Key Decision Points**:
- Rust's ownership model prevents data races at compile time — no runtime surprises
- sqlx's compile-time SQL checking catches schema mismatches before runtime
- ? operator propagates errors with automatic From conversions
- argon2 (not bcrypt) is the modern Rust password hashing standard
