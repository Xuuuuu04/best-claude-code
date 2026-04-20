> 源：core.md §Domain 3.2 Security Baseline + §Methodology (five-item security check)

# 后端开发师 — Security Baseline

## The Five-Item Security Self-Check (Run Before Every Handoff)

All five must pass. Any open item is a BLOCK on handoff to @code-review.

**1. SQL Parameterization**
- No string interpolation for user-controlled values in queries
- No f-string, %-formatting, or string concatenation in SQL
- ORM: always use parameterized methods (`.where(email: ?)` not `.where("email = '#{email}'"`)
- Raw SQL: always use placeholders (`?` / `$1` / `#{param}`)

**2. Password Handling**
- bcrypt only — cost ≥ 10 (recommend 12)
- No plaintext password storage
- No passwords in log statements
- No passwords in error responses
- Token handling: JWT must verify signature + exp + iss + aud

**3. Credential Externalization**
- No hardcoded API keys in source code
- No hardcoded DB credentials in source code
- No hardcoded JWT secrets in source code
- All credentials loaded from environment variables or secrets manager
- `.env` files must never be committed to version control

**4. Input Validation Coverage**
- Every external input (HTTP, file upload, message queue, CLI arg) has:
  - Type check (string, int, bool — no coercion surprises)
  - Length constraint (max length enforced)
  - Format constraint (email format, UUID format, date format — where applicable)
  - Enum constraint (only allowed values — where applicable)
- Validation occurs at the outermost layer (DTO/schema/handler) before any business logic

**5. Log Hygiene**
- No password values in logs
- No token values in logs (JWT, API keys, session tokens)
- No secret values in logs
- No PII in logs beyond what is explicitly required by data policy
- Log fields like `user_id` (opaque identifiers) are acceptable; `password: "hunter2"` is not

---

## Domain 3.2 Security Baseline (Full Skill Tree)

**3.2 Security Baseline (All Five Mandatory)**

├── SQL parameterization (parameterized queries, never string interpolation)
│   - Classic violation: `.execute("SELECT * FROM users WHERE email = '" + email + "'")`
│   - ORM escape bypass: `.where("email LIKE '%#{email}%'")` — still vulnerable if concatenated
│   - Safe pattern: `.where(email: email)` or `.where("email = ?", email)`
│
├── Authentication (JWT verify sig+exp+iss+aud, bcrypt cost≥10, no plaintext passwords)
│   - JWT: verify signature with correct key, check `exp` is in future, check `iss` matches expected issuer
│   - JWT: prevent `alg: none` bypass — explicitly specify expected algorithm
│   - bcrypt: cost factor ≥ 10 (12 recommended); argon2 is acceptable alternative
│   - No MD5/SHA1/SHA256 for password hashing — these are hash functions, not password KDFs
│
└── Authorization (RBAC, IDOR check: resource.owner_id == current_user.id)
    - Every endpoint retrieving a user-owned resource must verify ownership
    - Pattern: `if resource.owner_id != current_user.id: raise ForbiddenError`
    - JWT does not enforce authorization — it only authenticates. Authorization is separate logic.
    - RBAC: role checked at handler/guard layer, not derived from JWT payload claims alone

---

## Domain 3.1 API Contract Discipline (Related Security Context)

├── RESTful resource modeling (plural nouns, ≤2 nesting levels, action endpoints)
├── Error format standardization (RFC 7807 Problem Details structure)
│   - `type`, `title`, `status`, `detail`, `instance` fields
│   - Error codes in `type` URI or custom `code` field
│   - Never expose internal stack traces or SQL errors in production error responses
└── Versioning strategy (URL prefix /v1/, non-breaking additions, Sunset header)

---

## Domain 3.3 Observability (Log Security Integration)

├── Structured logging (JSON, trace_id, INFO/WARN/ERROR levels, no PII in logs)
│   - Use structured logger (structlog, zap, logrus, Winston) — not print()/console.log()
│   - Every log entry includes: timestamp, level, trace_id, service name
│   - Log correlation: pass trace_id from incoming request through all outbound calls
│
├── Health and readiness (/health for liveness, /ready for readiness)
│   - /health: returns 200 if process is alive (no DB check)
│   - /ready: returns 200 only when all dependencies (DB, cache, message queue) are reachable
│
└── Distributed tracing (X-Request-ID propagation through all outbound calls)
    - Extract X-Request-ID from incoming request header
    - Inject X-Request-ID into all outbound HTTP calls
    - Include trace_id in structured log entries for log correlation

---

## Security Checklist (Handoff Signoff Format)

Copy into every implementation report before recommending @code-review:

```
**Security Baseline**:
- SQL parameterization: ✓/✗ [if ✗, describe gap]
- Password handling: ✓/✗/N/A [if ✗, describe gap]
- Credential externalization: ✓/✗ [if ✗, list hardcoded items]
- Input validation: ✓/✗ [if ✗, list unvalidated inputs]
- Log hygiene: ✓/✗ [if ✗, list sensitive fields in logs]
```

All five must be ✓ or N/A. Any ✗ blocks handoff.
