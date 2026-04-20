# 项目管理师 — Domain 1: Task Lifecycle Engineering

## 1.1 Requirement Decomposition

### INVEST Test Deep Specification

Every task must pass all six INVEST criteria before dispatch. A single failure means the task must be refined or decomposed further.

| Criterion | Test Question | Failure Signal | Correction Action |
|-----------|--------------|----------------|-------------------|
| **I**ndependent | Can this task be dispatched without waiting for a parallel task to complete? | "Implement auth + email + profile" (bundles 3 tasks) | Decompose into separate tasks with clear boundaries |
| **N**egotiable | Can the scope be adjusted (reduced or expanded) without breaking the task's core value? | "Rebuild the entire user system" (all-or-nothing) | Identify the minimum viable subset and make that the task |
| **V**aluable | Does this task produce a user-facing or system-facing outcome that can be demonstrated? | "Refactor internal utils" (no visible outcome) | Attach the refactoring to a feature task, or define a measurable improvement |
| **E**stimable | Can this task be completed in one agent session (≤1 day of focused work)? | "Implement microservices architecture" (too large) | Decompose into smaller tasks: service discovery, API gateway, first service migration |
| **S**mall | Does this task have exactly one core objective? | "Add OAuth2 + SAML + LDAP + API keys" (4 objectives) | Split into one task per authentication mechanism |
| **T**estable | Are there ≥3 observable acceptance criteria that can be independently verified? | "Make it faster" (no observable criteria) | Define specific metrics: "P95 < 200ms", "N+1 eliminated", "Load test passes at 1000 RPS" |

### INVEST Failure Patterns and Resolution

**Pattern 1: The Bundle Task**
```
User request: "I need a complete user authentication system"

BAD decomposition:
- T-020: "Implement auth system" (fails I, E, S, T)

GOOD decomposition:
- T-021: User registration (email/password) — I✓ N✓ V✓ E✓ S✓ T✓
- T-022: User login (JWT token generation) — I✓ N✓ V✓ E✓ S✓ T✓
- T-023: Password reset (email verification) — I✓ N✓ V✓ E✓ S✓ T✓
- T-024: Session management (token refresh) — I✓ N✓ V✓ E✓ S✓ T✓
- T-025: Role definition and assignment — I✓ N✓ V✓ E✓ S✓ T✓
- T-026: Permission checking middleware — I✓ N✓ V✓ E✓ S✓ T✓
```

**Pattern 2: The Infinite Task**
```
BAD:
- T-027: "Improve application performance"
  (fails N — scope is unbounded; fails T — no observable criteria)

GOOD:
- T-027a: "Reduce GET /orders P95 from 800ms to <200ms"
  DoD: (1) Load test at 1000 RPS shows P95 < 200ms; (2) No N+1 queries in order listing;
       (3) Database query plan shows index usage
- T-027b: "Reduce build time from 5min to <2min"
  DoD: (1) CI build completes in <2min; (2) All tests still pass; (3) No build warnings introduced
```

**Pattern 3: The Invisible Task**
```
BAD:
- T-028: "Refactor UserService for better code organization"
  (fails V — no user/system-facing outcome)

GOOD:
- T-028: "Extract payment logic from UserService into PaymentService"
  DoD: (1) PaymentService has 100% unit test coverage; (2) UserService no longer imports payment modules;
       (3) All existing integration tests pass without modification
```

### Decomposition Workflow

```
User request: "I need a complete user authentication system"

Step 1: Identify distinct objectives
- User registration (email/password)
- User login (JWT token generation)
- Password reset (email verification)
- Session management (token refresh)
- Role-based access control

Step 2: Apply INVEST to each
- Registration: I✓ N✓ V✓ E✓ S✓ T✓ → T-021
- Login: I✓ N✓ V✓ E✓ S✓ T✓ → T-022
- Password reset: I✓ N✓ V✓ E✓ S✓ T✓ → T-023
- Session management: I✓ N✓ V✓ E✓ S✓ T✓ → T-024
- RBAC: I✓ N✓ V✓ E✗ (too large) → decompose further
  - Role definition and assignment → T-025
  - Permission checking middleware → T-026

Step 3: Identify dependencies
T-021 (registration table) → T-022 (login reads user table)
T-021 → T-023 (password reset reads user table)
T-022 → T-024 (refresh depends on login)
T-021 → T-025 → T-026 (RBAC chain)

Step 4: Critical path
T-021 → T-022 → T-024 (longest dependency chain)
```

### Scope Boundary Hardening

Every task must have explicit In-scope and Out-scope:

```
T-022: User Login Endpoint

In-scope:
- POST /auth/login endpoint
- Email/password validation
- JWT token generation (access token)
- Error responses: 400 (validation), 401 (invalid credentials), 500 (server error)

Out-scope:
- Token refresh (T-024)
- OAuth2 integration (future task)
- Rate limiting (T-027)
- Frontend login form (@frontend scope)
```

### Dependency Graph Construction Methodology

**Step 1: List all tasks as nodes**
```
Nodes: T-021, T-022, T-023, T-024, T-025, T-026
```

**Step 2: Identify directed dependencies**
```
T-021 → T-022 (T-022 reads users table created by T-021)
T-021 → T-023 (T-023 reads users table)
T-022 → T-024 (refresh token depends on login)
T-021 → T-025 (roles table depends on users table)
T-025 → T-026 (permission middleware depends on roles)
```

**Step 3: Build adjacency list**
```
T-021: [T-022, T-023, T-025]
T-022: [T-024]
T-023: []
T-024: []
T-025: [T-026]
T-026: []
```

**Step 4: Calculate in-degrees (number of prerequisites)**
```
T-021: 0 (no prerequisites — can start immediately)
T-022: 1 (depends on T-021)
T-023: 1 (depends on T-021)
T-024: 1 (depends on T-022)
T-025: 1 (depends on T-021)
T-026: 1 (depends on T-025)
```

**Step 5: Identify critical path**
```
Path 1: T-021 → T-022 → T-024 (length 3)
Path 2: T-021 → T-023 (length 2)
Path 3: T-021 → T-025 → T-026 (length 3)
Critical path: max(Path 1, Path 2, Path 3) = 3 steps
→ Any delay on T-021, T-022, or T-024 delays the entire project
```

**Step 6: Identify parallelization opportunities**
```
After T-021 completes:
- T-022, T-023, T-025 can run in parallel (all have in-degree 1, satisfied by T-021)
- T-024 must wait for T-022
- T-026 must wait for T-025
```

## 1.2 State Machine Management

### State Entry Conditions

| State | Required Before Entry | Documents Required |
|-------|----------------------|-------------------|
| requirements | User request received | User input, project CLAUDE.md |
| scheme | INVEST test passed, dependencies identified | Decomposed task list, dependency graph |
| development | Scheme document approved | T-NNN-scheme.md, migration status verified |
| review | Implementation self-test passed | Changed files list, self-test output |
| test | Code-review PASS | Review report, security baseline |
| verdict | Functional test PASS | Test report, test evidence |
| archived | DoD signed off | All quality gate reports |

### State Exit Conditions (Guard Conditions)

Every state transition must pass ALL guard conditions before proceeding:

**requirements → scheme:**
- [ ] Task decomposed into INVEST-passing subtasks
- [ ] Dependency graph documented in TASK.md
- [ ] User decision points identified and either resolved or logged as BLOCKED
- [ ] Critical path identified
- [ ] No phantom blockers (information needed exists in project context)

**scheme → development:**
- [ ] Scheme document exists and is approved
- [ ] If schema changes required: migration plan documented and @database dispatched
- [ ] API contracts defined (if applicable)
- [ ] Error codes and response formats specified
- [ ] Acceptance criteria ≥3 and independently verifiable

**development → review:**
- [ ] Implementation complete (no skeleton commits, no stub returns)
- [ ] Self-test passed: at least one happy path and one error path
- [ ] Security baseline self-check passed (5 items)
- [ ] Changed files list documented
- [ ] No opportunistic refactoring included

**review → test:**
- [ ] @code-review returned PASS or CHANGES REQUESTED with all changes addressed
- [ ] No HIGH severity findings remaining
- [ ] If security-sensitive: @security-auditor pre-check passed

**test → verdict:**
- [ ] @test-func returned PASS or all failures addressed
- [ ] If frontend task: @test-ui returned PASS
- [ ] Regression test passed (no existing functionality broken)

**verdict → archived:**
- [ ] @test-lead returned PASS
- [ ] DoD checklist all items checked
- [ ] Version snapshot recorded (git tag or commit SHA)
- [ ] User notified of completion
- [ ] Out-of-scope discoveries logged as future tasks

### State Transition Audit Trail

Every state transition must be logged with:
```
[YYYY-MM-DD HH:MM] [STATE] Task-NNN → @agent-name | transition reason | rework:N
```

Example audit trail for a complete task:
```
[2026-04-20 09:00] [REQUIREMENTS] Task-021 → N/A | user request: password reset feature | rework:0
[2026-04-20 09:15] [SCHEME] Task-021 → @dev-lead | INVEST passed, 3-task decomposition | rework:0
[2026-04-20 11:30] [DEVELOPMENT] Task-021 → @database | scheme approved, migration design complete | rework:0
[2026-04-20 14:00] [REVIEW] Task-021 → @code-review | migration applied, self-test passed | rework:0
[2026-04-20 15:00] [TEST] Task-021 → @test-func | code-review passed, no HIGH findings | rework:0
[2026-04-20 16:00] [VERDICT] Task-021 → @test-lead | functional tests passed | rework:0
[2026-04-20 16:30] [ARCHIVED] Task-021 → N/A | DoD signed off, all gates passed | rework:0
```

### Parallel Task Identification Matrix

Tasks can run concurrently ONLY when ALL of the following are true:

| Condition | Test | Failure Example |
|-----------|------|-----------------|
| No shared dependencies | Task A does not produce output that Task B consumes | T-021 (migration) and T-022 (backend) — T-022 needs T-021's schema |
| No shared file writes | Tasks do not modify the same files | Two tasks both editing `config.py` |
| No schema conflicts | Tasks do not require conflicting database changes | T-021 adds `users.email` column, T-022 renames `users.email` to `users.email_address` |
| No API contract coupling | Tasks do not depend on each other's interfaces | T-022 (backend API) and T-023 (frontend page) — frontend depends on backend's API contract |

```
# CAN run in parallel:
T-021 (database: add users table) and T-025 (database: add roles table)
→ Different tables, no foreign key dependency

# CANNOT run in parallel:
T-021 (database: add users table) and T-022 (backend: login endpoint)
→ T-022 reads users table that T-021 creates

# CAN run in parallel with caution:
T-022 (backend: login endpoint) and T-023 (backend: password reset endpoint)
→ Both read users table (already exists), write to different files
→ OK if file list does not overlap
```

### Archive Protocol

```
1. Verify DoD checklist: all criteria met
2. Record version snapshot: git tag or commit SHA
3. Identify out-of-scope items: split into new tasks if valuable
4. Update TASK.md: state = archived, completion date
5. Append progress-log: [archive] Task-NNN | completed
6. Notify user: task complete, next tasks if any
```

## 1.3 Definition of Done Design

### DoD Three-Element Rule

Every DoD must have:
1. **≥3 independently verifiable observable criteria**
2. **Each criterion is a concrete state** (not "the feature works")
3. **No subjective judgment** (not "looks good")

```
# BAD DoD
T-022 DoD:
- Login works
- Error handling is correct
- Code is clean

# GOOD DoD
T-022 DoD:
- POST /auth/login returns 200 with {token, user} for valid credentials
- POST /auth/login returns 401 for invalid credentials (tested with 3 invalid combinations)
- POST /auth/login returns 400 for malformed request (missing email or password)
- Security baseline: SQL parameterization ✓, bcrypt ✓, JWT in env var ✓, input validation ✓, no creds in logs ✓
- @code-review passed with no HIGH findings
```

### DoD Criteria Types

| Type | Example Criteria | Measurement Method |
|------|-----------------|-------------------|
| Functional | Endpoint returns correct response | curl / unit test output |
| Performance | P95 response time < 200ms | Load test report |
| Security | OWASP Top 10 clean | @security-auditor report |
| Accessibility | WCAG 2.1 AA compliant | @test-ui audit |
| Reliability | 99.9% uptime over 7 days | Monitoring dashboard |
| Code Quality | No HIGH findings in review | @code-review report |
| Test Coverage | ≥80% line coverage | Coverage report |

### DoD Template

```
Task-NNN DoD:

Functional:
- [ ] Criterion 1: [specific, observable, measurable]
- [ ] Criterion 2: [specific, observable, measurable]
- [ ] Criterion 3: [specific, observable, measurable]

Non-Functional (if applicable):
- [ ] Performance: [metric and threshold]
- [ ] Security: [baseline or audit requirement]
- [ ] Accessibility: [standard requirement]

Quality Gates:
- [ ] @code-review passed
- [ ] @security-auditor passed (if applicable)
- [ ] @test-func passed
- [ ] @test-ui passed (if frontend)
- [ ] @test-lead verdict passed

Regression:
- [ ] Existing tests pass
- [ ] No breaking changes to existing APIs
```

### Quality Gate Ladder

```
implementer self-test
      ↓
@code-review (mandatory for all code)
      ↓
@security-auditor (mandatory for auth, payment, PII handling)
      ↓
@test-func (mandatory for all features)
      ↓
@test-ui (mandatory for frontend tasks)
      ↓
@test-lead verdict (mandatory for all deliveries)
```

**Skip protocol**: Any gate skip must be logged in progress-log.md with explicit justification. Never skip silently.

```
# GOOD skip justification
[2026-04-20 10:00] [TEST] Task-021 → @test-func | @security-auditor skipped: this is a CSS-only change with no auth/payment/PII scope. Justification logged. | rework:0
```
