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
