---
name: specification-engineering
description: File-level technical specification methodology for the Harness team. Covers codebase archaeology, interface contract design, validation taxonomy, error handling matrices, scope precision, intervention triggers, failure path design, and Definition of Done engineering. Loaded by @dev-lead via skills: frontmatter.
type: skill
---

# Specification Engineering Skill

## 1. Core Disciplines

### Decision Elimination
Every time an implementing agent would face a choice during implementation, that choice should have been made in the spec. A spec that eliminates 20 implicit decisions is twice as valuable as one that eliminates 10.

BAD: "Add validation to the password reset endpoint."
GOOD: "Modify `auth/handlers/reset_password.py`: add validation to POST /auth/reset-password: `token`: required, UUID v4; if missing → 400 + `{error_code: MISSING_FIELD, message: 'Token is required'}` + WARN log."

### Minimum Change
Prefer the smaller approach. The larger approach requires documented justification.

### Spec Completeness Gradient
From "incomplete" (many implicit decisions) to "complete" (every decision documented). Identify the boundary explicitly.

## 2. Specification Structure

Every scheme MUST contain:
- **In-scope action list**: `[ACTION] [FILE PATH]: [SPECIFIC CHANGE]` — ACTION is Create/Modify/Delete
- **Out-scope list**: ≥2 items with reason (out-of-scope for this task / future task / different role)
- **Interface contracts**: METHOD + PATH + request schema + response schema + error codes
- **Validation rules**: type + length + format + enum for every external input field
- **Error handling matrix**: trigger → HTTP status + business error code + log level + user message
- **Concurrency & idempotency**: duplicate requests, concurrent writes, conflict resolution
- **DoD**: ≥3 independently verifiable observable criteria, at least 1 error-path

## 3. Codebase Archaeology

Before writing any spec:
1. READ `projects/{name}/CLAUDE.md`
2. GLOB directory structure — understand module organization
3. GREP existing patterns — auth middleware, validation decorators, repository patterns, error handling conventions
4. CONFIRM files referenced in scheme actually exist
5. IDENTIFY naming conventions in use

## 4. Intervention Triggers

Evaluate BEFORE writing spec. Any YES → BLOCK and escalate:

**@architect**: (1) new module with different lifecycle/ownership; (2) new cross-service API contract; (3) new infrastructure component; (4) data ownership ambiguity across modules
**@database**: (1) new table; (2) new column; (3) changed column type/nullability/constraint; (4) new index; (5) migration requires data transform
**@visual-designer**: (1) new UI component not in design system; (2) new interaction pattern not covered by existing tokens; (3) new color/spacing/typography token needed
**@ml-engineer**: ML model or inference pipeline required
**@tech-research**: technology selection question unresolved

## 5. Interface Contract Design

- RESTful: plural noun paths (/users, not /getUser), nested depth ≤2, action endpoints for non-CRUD
- Schema precision: every field — name, type, optional/required, validation constraints (min/max, regex, enum, default)
- Error contract: standard envelope `{"error_code": "BUSINESS_CODE", "message": "human readable", "details": {}}`
- Error codes are string constants, not free-form messages

## 6. Validation Taxonomy

- Type validation, range validation, format validation (email regex, UUID, date)
- Enum validation, cross-field validation (field A required when field B has value C)
- Layer placement: API boundary (all external input) → service layer (business rules) → database layer (integrity constraints)

## 7. Error Handling Matrix Completeness

Every public interface must handle: auth failure, validation failure, external dependency failure, business rule violation. Happy-path-only spec is a half-spec.

## 8. Concurrency & Idempotency

- Duplicate requests: idempotency key (client UUID, content hash, or derived key)
- Deduplication storage: database UNIQUE constraint, Redis key with TTL
- Duplicate response behavior: 200 with original response? 409? Silently succeed?
- Concurrent writes: last-writer-wins? first-writer-wins? both fail? Specify locking mechanism (optimistic/pessimistic/distributed) and user-facing behavior on conflict.

## 9. DoD Engineering

- **Observable criteria**: each item a specific, observable state with verification method (curl command, test assertion, metric value)
- **Independence**: each item independently testable from clean state
- **Error-path coverage**: at least 1 DoD item verifies error behavior
- **Non-functional**: N+1 query check, performance baseline (P99 < X ms), security baseline
- **Regression**: identify existing tests that will be touched; verify adjacent features still work

## 10. Anti-Patterns

**Spec as Layer Label**: "Add a service layer" without file/class/method names. Correction: every item names a specific file path.
**Scope Leak**: hedges like "might also need" become implicit in-scope. Correction: explicitly In-scope or Out-scope. No "might."
**Premature Architect**: escalating to @architect for problems solvable within current module. Correction: run intervention trigger test.
**Ambiguity Inheritance**: writing spec around known business gaps instead of blocking. Correction: BLOCK on every gap requiring @backend to make a product decision.
**Unverifiable DoD**: subjective judgment ("feels smooth"). Correction: specific observable state + verification method.
**"By the way" Anti-Pattern**: including discovered quality issues in In-scope. Correction: log as future task suggestions, NOT in current In-scope.
