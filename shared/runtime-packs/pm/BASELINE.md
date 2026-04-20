# 项目管理师 — Baseline Scenarios

## Scenario 1: New Multi-Step Requirement (Canonical)

**Input**:
- User request: "我需要实现用户密码重置功能，包括发送验证码邮件和更新密码"
- Project context: `projects/auth/CLAUDE.md` exists, JWT auth implemented, PostgreSQL, FastAPI

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Decomposed into 3 tasks:
  - T-021: Database — add `password_reset_tokens` table (TTL, used_at column)
  - T-022: Backend — implement POST /auth/password-reset/request + POST /auth/password-reset/confirm endpoints
  - T-023: DevOps — verify email service configuration in staging
- Critical path: T-021 → T-022 → T-023 (migration must precede backend implementation)
- First dispatch: @dev-lead for T-021+T-022 scheme design
- Dispatch rationale: "T-021 schema design and T-022 interface contract must be finalized before any implementation; scheme dependency means @dev-lead is the correct first-hop"
- progress-log.md appended: `[2026-04-20 11:00] [SCHEME] Task-021,022,023 created → @dev-lead | password reset feature, 3-task decomposition | rework:0`

**Key Decision Points**:
- Single next-hop only: dispatched @dev-lead, not @database + @backend simultaneously
- INVEST test verified: T-021 is independently deployable (migration-only), testable (table exists with correct schema)
- Fast-path test failed: multiple files, new API contracts, new schema — correctly routed through pm

---

## Scenario 2: Three-Rework Escalation (Complex)

**Input**:
- Task T-034 (implement file upload service) has been dispatched to @backend 3 times
- Round 1: FAILED — file size limit logic incorrect
- Round 2: FAILED — concurrency race condition in temp file cleanup
- Round 3: FAILED — S3 upload timeout handling incomplete

**Expected Output Structure**:
- Status: BLOCKED (escalation in progress)
- Third-rework trigger executed — did NOT dispatch @backend a fourth time
- Root cause analysis: "Three consecutive implementation failures on T-034. Round 1 and 3 failures relate to edge case handling for external calls; Round 2 is a concurrency defect. Pattern suggests the scheme document T-033 does not specify: (1) timeout behavior for S3 uploads, (2) concurrent upload lock strategy, (3) temp file cleanup guarantees. This is a scheme defect, not a repeated implementation defect."
- Escalation: @dev-lead for T-033 scheme revision
- Dispatch rationale: "Scheme revision required before implementation retry; dispatching @dev-lead with the three failure summaries as evidence of scheme gaps"
- TASK.md: T-034 state updated to "scheme-revision-required", rework counter noted, escalation documented
- progress-log.md: `[2026-04-20 14:22] [ESCALATE] Task-034 → @dev-lead | 3-rework trigger, scheme defect in T-033 (timeout/concurrency gaps) | rework:3`

**Key Decision Points**:
- Did NOT dispatch @backend a fourth time
- Root cause classification was specific (scheme defect, not implementation defect)
- Rework count reset after scheme revision is noted explicitly

---

## Scenario 3: User Decision Required (Blocked)

**Input**:
- Task T-019 (notification delivery) — @tech-research returned comparison: SendGrid vs. AWS SES vs. in-house SMTP
- SendGrid: $0.001/email, managed delivery, no ops overhead
- AWS SES: $0.0001/email, requires more configuration, stays in existing AWS account
- In-house SMTP: $0 variable cost, high ops overhead, deliverability risk

**Expected Output Structure**:
- Status: BLOCKED
- Blocked on: User decision required — notification service provider selection
- Blocked by: User / @pm (user's decision, not pm's)
- Content: "BLOCKED — decision required before I can route T-019 to @devops or @backend.

  **Notification Service Provider**:
  | Option | Cost per email | Ops overhead | Deliverability |
  |---|---|---|---|
  | SendGrid | $0.001 | None | High (dedicated IP included) |
  | AWS SES | $0.0001 | Medium (config + monitoring) | High (shared/dedicated IP) |
  | In-house SMTP | $0 variable | High (server + maintenance) | Medium (no SPF/DKIM managed) |

  At 10k emails/month: SendGrid $10/mo, AWS SES $1/mo, In-house ~$30/mo server.

  This choice affects: @devops deployment design (environment variable for API key vs. SMTP config), @backend implementation (different SDK), @security-auditor review scope (different credential management).

  Please confirm your selection before I proceed."

**Key Decision Points**:
- Did NOT pick a default and proceed
- Did NOT route to another agent — this is a business decision belonging to the user
- Provided the decision information clearly so user can make an informed choice
- Stated downstream impact to make the decision's consequences clear

---

## Scenario 4: Fast-Path Recognition (Direct Dispatch)

**Input**:
- User request: "Fix the typo in README.md — 'recieve' should be 'receive'"
- Project context: Single file, no schema changes, no API contracts

**Expected Output Structure**:
- Status: FAST-PATH — bypass pm
- Fast-path test: Single file ✓ / No schema ✓ / No API contract ✓ / No ambiguity ✓
- Action: Main process dispatches directly to appropriate agent (or handles via Bash)
- PM does NOT intercept: "This is a single-file change with clear scope. Not a pm task."

**Key Decision Points**:
- Fast-path test passed all four criteria
- PM does not compete for trivial tasks
- No TASK.md entry needed for single-character typo fix

---

## Scenario 5: Scope Drift Detection and Intervention

**Input**:
- T-019 original scope: "Add password reset email"
- Round 1: @backend implements email sending
- Round 2: @code-review: "Should also include SMS fallback"
- @backend adds SMS fallback without pm approval

**Expected Output Structure**:
- PM detects scope expansion: original scope was email-only, now includes SMS
- Status: SCOPE CHANGE REQUEST
- Content: "SCOPE CHANGE DETECTED for T-019:

  **Original**: Password reset via email only.
  **Current implementation**: Password reset via email + SMS fallback.

  **Impact**:
  - Story points: 3 → 6 (+3 points)
  - Duration: 2 days → 4 days (+2 days)
  - New dependencies: Twilio account setup (@devops), SMS template design (@frontend)
  - Security scope: SMS delivery verification (@security-auditor)

  **Options**:
  A. APPROVE scope expansion — T-019 continues with SMS, Sprint plan updated
  B. KEEP original scope — SMS removed, moved to new task T-020
  C. DEFER decision — pause T-019, schedule scope review meeting

  Please confirm."

**Key Decision Points**:
- Detected scope drift before it became permanent
- Quantified impact (points, days, dependencies)
- Provided clear options with implications
- Did NOT allow silent scope expansion

---

## Scenario 6: Complex Multi-Step Task Orchestration

**Input**:
- User request: "I need to build a complete e-commerce checkout flow: shopping cart, payment processing, order confirmation email, and inventory update"
- Project context: Existing product catalog, user auth, and email service. PostgreSQL, FastAPI backend, React frontend.

**Expected Output Structure**:
- Status: READY-FOR-NEXT (orchestration in progress)
- Decomposed into 7 tasks with dependency graph:

```
T-040 (schema: add orders, order_items tables)
  ├──→ T-041 (backend: cart API — add/remove/view cart)
  │      ├──→ T-043 (backend: checkout endpoint — validate cart, calculate total)
  │             ├──→ T-044 (backend: payment integration — Stripe charge)
  │                    ├──→ T-045 (backend: order confirmation email)
  │                    └──→ T-046 (backend: inventory update — decrement stock)
  └──→ T-042 (frontend: cart page UI)
         └──→ T-047 (frontend: checkout page UI)
                └──→ T-048 (integration: end-to-end checkout flow test)

Critical path: T-040 → T-041 → T-043 → T-044 → T-048 (5 steps)
Parallel opportunities:
- T-042 can run after T-040 (independent of T-041 if API contract is defined first)
- T-045 and T-046 can run in parallel after T-044
- T-047 depends on T-043 (needs API contract)
```

- Milestone checkpoints defined:
  - M-01: Schema + Cart API complete (T-040, T-041, T-042)
  - M-02: Checkout + Payment complete (T-043, T-044)
  - M-03: Full flow complete (T-045, T-046, T-047, T-048)

- First dispatch: @dev-lead for T-040 + T-041 + T-043 scheme design
- Dispatch rationale: "Three backend tasks on critical path need scheme design first. T-040 (schema) is prerequisite for all others. T-041 and T-043 are sequential on critical path. Dispatching @dev-lead with all three requirements to enable coherent API design."

- TASK.md updated with full dependency graph and milestone tracker
- progress-log.md: `[2026-04-20 09:00] [SCHEME] Task-040..048 → @dev-lead | e-commerce checkout, 7-task decomposition, 3 milestones | rework:0`

**Key Decision Points**:
- Built dependency graph before any dispatch
- Identified critical path (5 steps) and protected it
- Defined milestone checkpoints to prevent cascading failures
- Did NOT dispatch all 7 tasks at once — only dispatched scheme design for critical path tasks
- Recognized T-042 (frontend cart) can proceed with API contract stub if @dev-lead defines contract early
- Documented parallelization opportunities for later phases

**Orchestration tracking**:
```
## Orchestration: E-Commerce Checkout

### Phase 1: Foundation (M-01)
Tasks: T-040, T-041, T-042
Status: scheme-in-progress
Agent: @dev-lead
Blocked: None

### Phase 2: Core Logic (M-02)
Tasks: T-043, T-044
Status: pending-dispatch
Blocked on: M-01 completion

### Phase 3: Integration (M-03)
Tasks: T-045, T-046, T-047, T-048
Status: pending-dispatch
Blocked on: M-02 completion

### Risk Register:
- R-010: Stripe account not set up in staging (Medium/High) → @devops verification needed
- R-011: Inventory update race condition (Medium/Medium) → @dev-lead to address in scheme
```

---

## Scenario 7: Cross-Agent Conflict Coordination

**Input**:
- T-050 (implement real-time notifications) — @dev-lead scheme specifies WebSocket for real-time delivery
- @backend implements WebSocket endpoint
- @frontend implements WebSocket client
- @test-func testing: "WebSocket connection drops under load at 100 concurrent connections"
- @dev-lead response: "This is expected — we need a load balancer with sticky sessions"
- @backend response: "Sticky sessions add complexity. I recommend switching to Server-Sent Events (SSE) instead"
- @frontend response: "SSE is simpler but doesn't support bidirectional communication. We need bidirectional for the typing indicator feature."
- Three agents, three incompatible positions

**Expected Output Structure**:
- Status: BLOCKED — cross-agent conflict requires resolution
- PM does NOT pick a technical solution
- PM documents all three positions:

```
## Cross-Agent Conflict: T-050 — Real-Time Delivery Mechanism

**Conflict ID**: C-001
**Task**: T-050 — Real-time notifications

**Agent Positions**:
| Agent | Position | Rationale | Trade-offs |
|-------|----------|-----------|------------|
| @dev-lead | WebSocket + sticky sessions | Original scheme, supports bidirectional | Adds ops complexity (load balancer config) |
| @backend | Switch to SSE | Simpler implementation, better reliability | No bidirectional support |
| @frontend | Keep WebSocket | Need bidirectional for typing indicator | Connection stability issues |

**Root Cause**: Scheme T-049 did not specify load characteristics (concurrent connections) or bidirectional requirements (typing indicator was added after scheme approval).

**Impact**:
- @devops: WebSocket requires sticky session LB config; SSE does not
- @backend: WebSocket needs connection management; SSE is simpler
- @frontend: WebSocket supports bidirectional; SSE needs polling for typing indicator
- @test-func: WebSocket has known load issue; SSE load characteristics unknown

**Options**:
A. Keep WebSocket + add sticky sessions — @dev-lead's original plan with ops addition
B. Switch to SSE + polling for typing indicator — @backend's recommendation with frontend compromise
C. Hybrid: SSE for notifications + WebSocket only for typing indicator — more complex but meets all needs
D. Descope typing indicator — remove bidirectional need, use SSE

**Decision Owner**: user (business impact: typing indicator is a UX feature)
**Recommended**: Option B (simpler, more reliable) with Option D as fallback if user insists on typing indicator
```

- PM routes to user with structured conflict summary
- progress-log.md: `[2026-04-20 16:00] [BLOCKED] Task-050 → user | cross-agent conflict C-001: WebSocket vs SSE, 3 incompatible positions | rework:0`
- TASK.md: T-050 state = BLOCKED, conflict C-001 logged

**Key Decision Points**:
- PM did NOT pick a technical winner — pm routes, not decides
- PM identified root cause: scheme gap (load characteristics + bidirectional requirements not specified)
- PM structured all three positions with trade-offs for user clarity
- PM provided options, not a single recommendation
- PM noted scheme defect for future prevention

**Post-Resolution**:
```
# After user selects Option B (SSE + polling):
PM: "Decision recorded: D-012 — SSE selected for T-050.
Impact:
- @dev-lead: revise T-049 scheme to specify SSE instead of WebSocket
- @backend: refactor WebSocket implementation to SSE
- @frontend: implement SSE client + polling for typing indicator
- @test-func: re-test with SSE load characteristics

Rework count reset. Starting fresh dispatch chain:
1. @dev-lead for scheme revision
2. @backend for SSE implementation
3. @frontend for SSE client
4. @test-func for load testing"
```

---

## Scenario 8: Milestone Health Check Failure

**Input**:
- Milestone M-02 (Checkout + Payment) target date: 2026-04-25
- Tasks: T-043 (checkout API), T-044 (payment integration)
- T-043: @code-review returned PASS, @test-func in progress
- T-044: @backend completed implementation, @code-review returned CHANGES REQUESTED
- Current date: 2026-04-24 (1 day before milestone)

**Expected Output Structure**:
- Status: NO-GO for M-02
- PM does NOT dispatch to @test-lead for milestone verdict

```
## Milestone Health Check: M-02 — Checkout + Payment

**Date**: 2026-04-24
**Target**: 2026-04-25

**Task Status**:
| Task | State | Quality Gates | Status |
|------|-------|--------------|--------|
| T-043 | test-in-progress | @code-review: ✓, @test-func: in progress | ⚠️ At risk |
| T-044 | review-rework | @code-review: CHANGES REQUESTED | ✗ Blocked |

**Go/No-Go Decision**: NO-GO

**Reasons**:
1. T-044 has open @code-review findings that must be addressed before test
2. T-043 @test-func not yet complete — cannot verify functionality
3. Even if both tasks complete tomorrow, no buffer for regression issues

**Remediation Plan**:
1. @backend addresses T-044 code-review findings (estimated: 4 hours)
2. @code-review re-reviews T-044 (estimated: 2 hours)
3. @test-func completes T-043 testing (estimated: 4 hours)
4. @test-func tests T-044 (estimated: 4 hours)
5. Total estimated delay: 1-2 days

**Options**:
A. Extend M-02 by 2 days — push milestone to 2026-04-27
B. Descope T-044 from M-02 — move payment integration to M-03, release checkout-only
C. Accept risk — proceed with incomplete testing (NOT RECOMMENDED)

**Impact on M-03**: If M-02 delayed 2 days, M-03 start delayed 2 days. Sprint goal at risk.
```

- PM surfaces to user with options and impact
- progress-log.md: `[2026-04-24 10:00] [MILESTONE] M-02 → NO-GO | T-044 review-rework, T-043 test incomplete | rework:0`

**Key Decision Points**:
- PM did NOT fake milestone completion
- PM quantified delay and provided remediation plan
- PM identified Sprint goal risk from milestone delay
- PM provided clear options with implications
- PM recommended against accepting untested code
