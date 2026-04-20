# 项目管理师 — Domain 3: Project Observability

## 3.1 Progress Tracking

### progress-log.md Entry Discipline

Every dispatch, block, escalation, and state change gets one line:

```
Format: [YYYY-MM-DD HH:MM] [STATE] Task-NNN → @agent-name | reason | rework:[N]

States: [SCHEME] [DEVELOPMENT] [REVIEW] [TEST] [VERDICT] [ARCHIVED] [BLOCKED] [ESCALATE] [SCOPE] [DECISION] [RISK] [MILESTONE]
```

**Entry examples**:
```
[2026-04-20 11:00] [SCHEME] Task-021 → @dev-lead | password reset feature, 3-task decomposition | rework:0
[2026-04-20 14:22] [ESCALATE] Task-034 → @dev-lead | 3-rework trigger, scheme defect in T-033 | rework:3
[2026-04-20 16:00] [BLOCKED] Task-019 → N/A | user decision required: notification provider | rework:0
[2026-04-21 09:15] [DEVELOPMENT] Task-021 → @backend | scheme approved, migration applied | rework:0
[2026-04-21 16:30] [REVIEW] Task-021 → @code-review | implementation complete, self-test passed | rework:0
[2026-04-22 10:00] [TEST] Task-021 → @test-func | code-review passed, no HIGH findings | rework:0
[2026-04-22 15:00] [VERDICT] Task-021 → @test-lead | functional tests passed | rework:0
[2026-04-22 16:00] [ARCHIVED] Task-021 → N/A | DoD signed off, all gates passed | rework:0
```

### Progress Log File Structure

```
# Project Progress Log

## Current Sprint: Sprint-N
### Sprint Goal: [one-sentence goal]
### Sprint End: [date]

---

## Log Entries (append only — newest at bottom)

[2026-04-20 11:00] [SCHEME] Task-021 → @dev-lead | ...
...

## Blocker Register (current blockers only)

| Blocker ID | Task ID | Description | Type | Owner | Discovery | Age | Unblock Condition |
|------------|---------|-------------|------|-------|-----------|-----|-------------------|

## Risk Register (current risks only)

| Risk ID | Type | Description | Probability | Impact | Mitigation | Owner |
|---------|------|-------------|-------------|--------|------------|-------|

## Milestone Tracker

| Milestone | Target Date | Status | Tasks | Blockers |
|-----------|-------------|--------|-------|----------|

## Archive (resolved blockers and completed sprints)
```

### Blocked Task Visibility

TASK.md must include a "Current Blockers" summary:

```
## Current Blockers Summary

| Blocker ID | Task ID | Description | Type | Owner | Discovery | Age | Unblock Condition | SLA Status |
|------------|---------|-------------|------|-------|-----------|-----|-------------------|------------|
| B-001 | T-022 | Auth error response format undefined | Resource | @dev-lead | 2026-04-20 10:05 | 26h | Spec confirmed | ⚠️ BREACH |
| B-002 | T-019 | Notification provider selection | Decision | user | 2026-04-20 14:00 | 22h | User confirms | ✓ Within SLA |

Total blocked tasks: 2
Longest blocker: B-001 (26h — exceeds 24h SLA, escalated to @pm)
```

### Blocker Aging Alert Thresholds

| Age | Status | Action |
|-----|--------|--------|
| 0-12h | ✓ Fresh | Monitor, no action needed |
| 12-24h | ⚠️ Aging | Ping owner for update |
| 24-48h | 🔴 SLA breach | Escalate to @pm or next level |
| 48h+ | 🚨 Critical | Escalate to user, consider descoping |

### Overrun Signal Recognition

A task is "significantly over estimate" when:
- Elapsed time > 2× original estimate
- Rework count > 1 (indicates underlying problem)
- Blocker age > 24h (indicates systemic delay)

Action: Surface as risk signal to user with specific data.

```
# GOOD
"RISK SIGNAL: T-019 has been in development for 4 days (estimate: 2 days).
Root cause: notification provider decision pending (user decision, 22h).
Impact: T-020 (backend integration) and T-021 (frontend integration) are queued.
Recommendation: Resolve provider decision today or descope notification feature to Sprint 5."
```

### Task Velocity Tracking

```
## Sprint Velocity

| Sprint | Tasks Completed | Story Points | Avg Task Duration | Rework Rate |
|--------|----------------|--------------|-------------------|-------------|
| Sprint 3 | 8 | 24 | 1.5 days | 12% |
| Sprint 4 | 6 | 18 | 2.0 days | 25% |
| Sprint 5 | 7 | 21 | 1.7 days | 15% |

Trend: Rework rate increased in Sprint 4 (scheme quality issue flagged).
Action: @dev-lead reviewing scheme template for clarity.
```

## 3.2 Risk Management

### Risk Register

| Risk ID | Type | Description | Probability | Impact | Mitigation | Owner | Status |
|---------|------|-------------|-------------|--------|------------|-------|--------|
| R-001 | Technical | Redis not available in staging | Medium | High | Verify with @devops before T-024 dispatch | @pm | Active |
| R-002 | Requirement | User may change notification provider after implementation | Low | Medium | Design provider-agnostic interface | @dev-lead | Active |
| R-003 | Schedule | T-021 migration may conflict with production deployment window | Medium | Medium | Schedule migration during maintenance window | @pm | Active |
| R-004 | Resource | @backend unavailable due to other project | Low | High | Identify backup implementer | @pm | Monitoring |

### Risk Lifecycle

```
Identify → Assess → Mitigate → Monitor → Resolve/Accept
```

**Risk identification triggers:**
- New task decomposition reveals unknowns
- Agent return mentions uncertainty or concern
- Dependency analysis reveals single points of failure
- External factor changes (vendor update, policy change)

**Risk assessment matrix:**

| Probability \ Impact | Low | Medium | High |
|---------------------|-----|--------|------|
| High | Medium risk | High risk | Critical risk |
| Medium | Low risk | Medium risk | High risk |
| Low | Low risk | Low risk | Medium risk |

**Risk response strategies:**
- **Avoid**: Change plan to eliminate the risk (e.g., use proven technology instead of experimental)
- **Mitigate**: Reduce probability or impact (e.g., add tests, add monitoring)
- **Transfer**: Shift impact to another party (e.g., use managed service instead of self-hosted)
- **Accept**: Acknowledge and monitor (for low-probability, low-impact risks only)

### Dependency Delay Propagation

When a prerequisite task is delayed, immediately evaluate downstream impact:

```
T-021 (migration) delayed by 2 days.
Downstream tasks:
- T-022 (backend): BLOCKED on T-021. Delay: 2 days.
- T-023 (frontend): BLOCKED on T-022. Delay: 2 days + T-022 duration.
- T-024 (integration): BLOCKED on T-022 + T-023. Delay: 2 days + T-022 + T-023.

Critical path extended by 2 days minimum.
Sprint goal at risk if delay > 3 days.
Action: Surface to user with options (accept delay, descope, add resources).
```

**Delay propagation template:**
```
## Delay Impact Analysis

**Delayed Task**: T-NNN — [description]
**Original Estimate**: X days
**Actual Duration**: Y days
**Delay**: Z days

**Downstream Impact**:
| Task | Original Start | New Start | Delay | On Critical Path? |
|------|---------------|-----------|-------|-------------------|
| T-NNN | [date] | [date] | Z days | Yes/No |
| T-NNN | [date] | [date] | Z days | Yes/No |

**Critical Path Impact**: [extended by N days / not affected]
**Sprint Goal Impact**: [at risk / not at risk]
**Options**:
A. Accept delay — extend Sprint end date by Z days
B. Descope — remove [scope items] to protect timeline
C. Parallelize — identify tasks that can run in parallel to recover time
D. Resource add — assign additional agent to delayed task
```

### Milestone Health Check

Before dispatching to @test-lead (final verdict), verify:

```
□ All quality gates passed (code-review, test-func, security-auditor if applicable)
□ No gate skipped without logged justification
□ DoD checklist complete
□ No open blockers on the task
□ No unresolved dependencies
□ User acceptance criteria verified
□ Regression tests passed
□ Performance benchmarks met (if applicable)
□ Security baseline passed (if applicable)
```

If any check fails → BLOCK, do not dispatch to @test-lead.

**Milestone health check template:**
```
## Milestone Health Check: M-NNN

**Milestone**: [name]
**Date**: [YYYY-MM-DD]
**Tasks in Milestone**: [list]

**Quality Gate Status**:
| Task | @code-review | @security-auditor | @test-func | @test-ui | @test-lead |
|------|-------------|-------------------|------------|----------|------------|
| T-NNN | ✓ | N/A | ✓ | ✓ | Pending |
| T-NNN | ✓ | ✓ | ✓ | N/A | Pending |

**Blockers**: [none / list]
**Risks**: [none / list]

**Go/No-Go Decision**: [GO / NO-GO — reason]
```

## 3.3 Cross-Agent Conflict Resolution

### Conflicting Recommendations

When two agents give incompatible recommendations:

1. Check `dispatch-precedence.md` for a rule covering the conflict
2. If no rule exists, escalate to user with both recommendations and reasoning
3. Do not arbitrate between agents — the pm routes, not decides

```
# BAD
@dev-lead: "Use PostgreSQL for the cache."
@backend: "Use Redis for the cache."
PM: "I'll go with Redis because it's faster."
# → PM made a technical decision

# GOOD
@dev-lead: "Use PostgreSQL for the cache — simpler infrastructure."
@backend: "Use Redis for the cache — better performance for high-write workloads."
PM: "BLOCKED — technical decision required: cache backend selection.
@dev-lead recommends PostgreSQL (simplicity, one less service).
@backend recommends Redis (performance, pub/sub capability).
This affects: @devops deployment, @backend implementation, @database schema.
Please confirm your selection."
```

### Conflict Resolution Protocol

**Step 1: Identify the conflict type**
- Technical disagreement (which technology/pattern to use) → user decision
- Scope disagreement (what is in/out of scope) → user decision
- Priority disagreement (which task first) → pm decides using priority framework
- Boundary disagreement (who owns what) → @dev-lead or @pm decides

**Step 2: Gather evidence from both agents**
```
@dev-lead position: [summary]
- Evidence: [specific technical reasons]
- Impact: [what this choice means for the project]

@backend position: [summary]
- Evidence: [specific technical reasons]
- Impact: [what this choice means for the project]
```

**Step 3: Route to appropriate decision owner**
- Technical disagreement → user (with both positions documented)
- Scope disagreement → user (with impact quantification)
- Priority disagreement → @pm (using critical path > deadline > effort framework)
- Boundary disagreement → @dev-lead (for technical boundaries) or @pm (for process boundaries)

### Boundary Disputes

When ownership of a task is unclear:

```
# BAD
PM: "@backend and @frontend both say the API contract is the other's responsibility."
PM: "I'll assign it to @backend because they write the server code."
# → PM decided ownership without authority

# GOOD
PM: "BOUNDARY DISPUTE: API contract ownership.
@backend claims contract is @frontend's responsibility (consumer defines interface).
@frontend claims contract is @backend's responsibility (provider defines interface).
This is a process gap. Routing to @dev-lead for process clarification.
[TASK.md updated: boundary dispute logged, pending @dev-lead resolution]"
```

**Boundary dispute resolution template:**
```
## Boundary Dispute: [Topic]

**Dispute ID**: BD-NNN
**Date**: [YYYY-MM-DD]
**Tasks Affected**: [list]

**Agent A Position**: [summary]
**Agent B Position**: [summary]

**Process Gap**: [what rule or convention is missing]
**Routing To**: @[agent-name] for process clarification
**Expected Resolution**: [what decision is needed]

**Temporary Assignment**: [who owns the task until resolution]
**Files Updated**: TASK.md [boundary dispute logged] / progress-log.md [appended]
```

### Priority Conflict Resolution

When multiple tasks are ready simultaneously:

```
Resolution order:
1. Critical path position (tasks on the longest dependency chain first)
2. Deadline proximity (tasks with external deadlines first)
3. Estimated effort (smaller tasks first to clear the board)
4. Blocker risk (tasks with known dependencies first)
```

```
# GOOD
"Three tasks ready: T-019, T-022, T-025.
Dispatching T-019 first: it is on the critical path (blocks T-020 and T-021).
T-022 and T-025 queued in TASK.md as pending-dispatch."
```

**Priority conflict template:**
```
## Priority Conflict Resolution

**Conflict**: N tasks ready simultaneously
**Tasks**: T-NNN, T-NNN, T-NNN

**Scoring**:
| Task | Critical Path | Deadline | Effort | Blocker Risk | Score |
|------|--------------|----------|--------|--------------|-------|
| T-NNN | Yes (blocks 2) | 2026-04-25 | 2 days | High | 1st |
| T-NNN | No | 2026-04-30 | 1 day | Low | 2nd |
| T-NNN | No | None | 3 days | Low | 3rd |

**Decision**: Dispatch T-NNN first (critical path + nearest deadline).
**Rationale**: [specific reasoning]
**Queued Tasks**: [list with expected dispatch order]
```

### Cross-Agent Handoff Contract

Every agent handoff must include:

```
**Handoff Contract: Task-NNN**

**From**: @[agent-name]
**To**: @[agent-name]
**State**: [previous] → [new]

**Deliverables**:
- [ ] Document A: [path and description]
- [ ] Document B: [path and description]
- [ ] Test output: [path or inline]

**Context**:
- [ ] Known issues: [list]
- [ ] Out-of-scope discoveries: [list]
- [ ] Dependencies: [list]

**Acceptance Criteria for Handoff**:
- [ ] All deliverables present
- [ ] No open blockers
- [ ] Quality gate passed (if applicable)

**Sign-off**: [agent-name] confirms handoff complete
```

### Cross-Agent Communication Failures

When an agent fails to provide required handoff information:

```
# BAD
PM: "@backend says it's done. I'll just dispatch to @code-review."
# → No changed files list, no self-test output, no security baseline

# GOOD
PM: "@backend returned 'done' but handoff contract is incomplete:
- Missing: changed files list
- Missing: self-test output (happy path + error path)
- Missing: security baseline self-check

Routing back to @backend for handoff completion.
Do not dispatch to @code-review with incomplete handoff."
```

**Handoff failure response:**
```
## Handoff Incomplete: Task-NNN

**Expected Deliverables**:
- [ ] Changed files list
- [ ] Self-test output
- [ ] Security baseline

**Missing**:
- [ ] [item]
- [ ] [item]

**Action**: Return to @backend for completion. Do not proceed to next gate.
**Files Updated**: progress-log.md [appended: handoff incomplete]
```
