---
name: backend-implementation
description: Server-side implementation methodology for the Harness team. Covers security baseline, layer-order implementation, input validation, error handling, N+1 elimination, and self-testing discipline. Supports Python/FastAPI/Django, Node.js/NestJS/Express, Go/Gin, Java/Spring Boot, Rust/Axum stacks. Loaded by @backend via skills: frontmatter.
type: skill
---

# Backend Implementation Skill

## 1. Security Baseline (5-Item Self-Check)

Every handoff MUST pass all five before @code-review:

| # | Check | Verification |
|---|-------|------------|
| 1 | SQL parameterization | All queries use parameterized statements or ORM; no string interpolation in SQL |
| 2 | Password hashing | bcrypt (cost ≥ 10) or Argon2; never plaintext, never MD5/SHA1 |
| 3 | Credentials in env vars | No secrets in source code; 12-factor config via environment |
| 4 | Input validation | Type + length + format + enum for every external input field |
| 5 | No secrets in logs | No passwords, tokens, or PII in log output |

Any failure → fix before handoff. Security design flaw (not just missing validation) → BLOCK and escalate to @security-auditor.

## 2. Implementation Layer Order

Implement strictly bottom-up. Do not skip ahead.

1. **DTO / Schema / Input validation layer**: define valid input before any logic consumes it
   - Every field: type, length constraint, format constraint, enum constraint
   - Pydantic BaseModel / Zod schema / Jakarta Bean Validation / DTO class
2. **Repository / DAO layer**: data access only, no business logic
   - Parameterized queries or ORM
   - N+1 eliminated before moving up
3. **Service layer**: business rules, transaction boundaries, idempotency logic
   - No raw HTTP request objects — framework-agnostic
4. **Controller / Handler layer**: route registration, request parsing, calling service, formatting errors
   - No business logic — controller calls service and formats result

## 3. Spec Boundary Discipline

- NEVER implement beyond the technical spec. Spec runs out → BLOCK and route to @dev-lead.
- NEVER fill a spec gap with an undocumented assumption. Missing error code, field type, or auth model = BLOCK.
- NEVER commit skeleton code: `pass`, stub returns, `TODO: implement`. Either complete or mark as NotImplementedError.
- NEVER swallow exceptions silently. `except: pass` and empty `catch {}` are forbidden. Log, re-raise, or return structured error.

## 4. Error Handling

- Standard error response envelope: `{"error_code": "BUSINESS_CODE", "message": "human readable", "details": {}}`
- Error codes are string constants, not free-form messages
- Every caught exception must be: re-raised, logged with structured context, or converted to structured error response

## 5. Self-Testing

MUST run before handoff:
- At least one happy-path test (curl or unit test)
- At least one error-path test
- Record actual output in handoff report
- "Looks right" is not a self-test

## 6. Anti-Patterns

**Skeleton Commit**: empty function bodies or `pass` in production paths. Correction: complete implementation or NotImplementedError.
**Ghost Failure**: `except: pass` or empty catch. Correction: every caught exception must be handled explicitly.
**Assumption Fill**: filling spec gaps with undocumented guesses. Correction: BLOCK and route to @dev-lead.
**Spec Drift**: implementing beyond the spec. Correction: stop at spec boundary.
**Scope Creep**: opportunistic refactoring during implementation. Correction: log as future task, do not touch.
**Connection Pool Leak**: unclosed connections or missing pool config. Correction: always close connections, configure pool limits.
**N+1 Query**: loading related data in loops. Correction: eager loading, JOINs, or batch queries.
**Transaction Leak**: business logic outside transaction boundary. Correction: transaction wraps the service method.
**Magic String**: hardcoded error messages or status codes. Correction: use constants/enums.
