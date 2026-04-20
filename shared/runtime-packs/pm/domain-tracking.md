# 项目管理师 — Domain: Progress Tracking Depth

## 1. Task Dependency Graph

### Dependency Graph Notation

Use a simple text-based dependency graph for visualization:

```
T-021 (schema: users table) ──┬──→ T-022 (backend: login endpoint) ──→ T-024 (integration test)
                              │                                         ↑
                              ├──→ T-023 (backend: password reset) ─────┤
                              │                                         │
                              └──→ T-025 (schema: roles table) ──→ T-026 (backend: RBAC middleware)

Critical path: T-021 → T-022 → T-024 (3 steps, longest chain)
Parallel opportunities: T-022, T-023, T-025 can run after T-021 completes
```

### Dependency Matrix

For complex projects, use a dependency matrix:

```
      T-021  T-022  T-023  T-024  T-025  T-026
T-021   —     →      →      —      →      —
T-022   —     —      —      →      —      —
T-023   —     —      —      →      —      —
T-024   —     —      —      —      —      —
T-025   —     —      —      —      —      →
T-026   —     —      —      —      —      —

→ = "must complete before" (row task must complete before column task)
```

### Dependency Graph Construction Workflow

**Step 1: List all tasks**
```
Tasks: T-021, T-022, T-023, T-024, T-025, T-026
```

**Step 2: Identify prerequisites for each task**
```
T-021: None (can start immediately)
T-022: T-021 (needs users table)
T-023: T-021 (needs users table)
T-024: T-022, T-023 (needs both endpoints)
T-025: T-021 (needs users table for foreign key)
T-026: T-025 (needs roles table)
```

**Step 3: Calculate in-degrees**
```
T-021: 0
T-022: 1
T-023: 1
T-024: 2
T-025: 1
T-026: 1
```

**Step 4: Topological sort (dispatch order)**
```
1. T-021 (in-degree 0)
2. T-022, T-023, T-025 (in-degree 1, all prerequisites met)
3. T-024 (in-degree 2, needs T-022 + T-023)
   T-026 (in-degree 1, needs T-025)
4. Done
```

**Step 5: Identify critical path**
```
Path 1: T-021 → T-022 → T-024 (length 3)
Path 2: T-021 → T-023 → T-024 (length 3)
Path 3: T-021 → T-025 → T-026 (length 3)
Critical path length: 3
→ Any delay on T-021, T-022, T-023, or T-024 delays the entire project
```

## 2. Blocker Chain Analysis

### Blocker Chain Tracing

When a task is blocked, trace the blocker to its root cause:

```
T-024 (integration test) BLOCKED
│
├─ Why? T-024 needs T-022 and T-023
│  ├─ T-022: COMPLETE ✓
│  └─ T-023: BLOCKED
│     │
│     ├─ Why? T-023 needs scheme T-023-scheme.md
│     └─ T-023-scheme.md: MISSING
│        │
│        ├─ Why? @dev-lead was dispatched but returned BLOCKED
│        └─ @dev-lead: BLOCKED on user decision (email provider selection)
│           │
│           └─ Root cause: User decision D-003 pending since 2026-04-20

Blocker chain: T-024 → T-023 → scheme missing → @dev-lead blocked → user decision D-003
Root cause: User has not decided on email provider
Unblock condition: User selects provider (D-003 resolved)
Impact: 3 tasks blocked (T-023, T-024, and any tasks depending on T-024)
```

### Blocker Chain Template

```
## Blocker Chain Analysis: T-NNN

**Blocked Task**: T-NNN — [description]
**Blocker ID**: B-NNN

**Chain**:
```
T-NNN BLOCKED
└─ Needs: [prerequisite]
   └─ [prerequisite] BLOCKED / INCOMPLETE
      └─ Needs: [next level]
         └─ Root cause: [ultimate blocker]
```

**Root Cause**: [specific cause]
**Root Cause Type**: [Technical / Resource / Decision / External]
**Root Cause Owner**: [who can resolve]

**Impact Chain**:
| Level | Task | State | Impact |
|-------|------|-------|--------|
| 1 (root) | [task] | [state] | Root cause |
| 2 | [task] | [state] | Blocked by level 1 |
| 3 | [task] | [state] | Blocked by level 2 |

**Unblock Condition**: [exactly what must happen]
**Estimated Unblock Date**: [date]
**Critical Path Affected**: [Yes/No]
```

### Blocker Chain Depth Limits

If a blocker chain exceeds 3 levels, the pm has a structural problem:

```
Level 1: Task blocked on immediate prerequisite
Level 2: Prerequisite blocked on another task
Level 3: That task blocked on a decision/resource
Level 4+: Structural issue — the project plan has a deep dependency that should be flattened

Action at Level 4+: Surface to user as systemic risk. Recommend:
- Flattening dependencies (can tasks be restructured?)
- Adding resources (can blocked tasks be parallelized?)
- Descoping (can the deep chain be broken by removing features?)
```

## 3. Milestone Health度检查

### Milestone Definition

A milestone is a verification checkpoint that groups related tasks and verifies their collective completion before proceeding.

**Milestone characteristics:**
- Groups 2-5 related tasks
- Has a clear go/no-go criteria
- Occurs at natural integration points
- Protects against cascading failures

### Milestone Template

```
## Milestone: M-NNN — [Name]

**Objective**: [what this milestone verifies]
**Target Date**: [YYYY-MM-DD]
**Sprint**: Sprint-N

**Tasks in Milestone**:
| Task | Description | State | Owner | On Critical Path? |
|------|-------------|-------|-------|-------------------|
| T-NNN | [desc] | [state] | @[agent] | Yes/No |
| T-NNN | [desc] | [state] | @[agent] | Yes/No |

**Go Criteria (ALL must pass)**:
- [ ] All tasks in milestone completed
- [ ] All quality gates passed for completed tasks
- [ ] Integration tests pass (if applicable)
- [ ] No open blockers on milestone tasks
- [ ] No unresolved dependencies

**No-Go Criteria (ANY triggers no-go)**:
- [ ] Any task failed quality gate
- [ ] Any task has open blocker > 24h
- [ ] Integration test failure
- [ ] Regression detected

**Go/No-Go Decision**: [GO / NO-GO]
**Decision Date**: [date]
**Next Milestone**: M-NNN
```

### Milestone Health Checklist

Before declaring a milestone complete:

```
□ All tasks in milestone: state = archived or ready-for-verdict
□ Quality gates: @code-review passed for all code tasks
□ Security: @security-auditor passed for security-sensitive tasks
□ Tests: @test-func passed for all functional tasks
□ UI: @test-ui passed for all frontend tasks
□ Integration: cross-task integration verified
□ Regression: existing functionality not broken
□ Documentation: scheme docs updated if architecture changed
□ Blockers: no open blockers on milestone tasks
□ Dependencies: all prerequisite milestones complete
```

### Milestone Go/No-Go Decision Record

```
## Milestone Decision: M-NNN

**Date**: [YYYY-MM-DD]
**Milestone**: [name]

**Task Status**:
| Task | Required | Actual | Gap |
|------|----------|--------|-----|
| T-NNN | Complete | Complete | None |
| T-NNN | Complete | In Progress | 1 day behind |

**Quality Gate Status**:
| Gate | Required | Actual | Gap |
|------|----------|--------|-----|
| @code-review | Pass | Pass | None |
| @test-func | Pass | Fail | 2 test failures |

**Decision**: NO-GO
**Reason**: @test-func failures in T-NNN must be resolved before proceeding
**Remediation**: [specific actions]
**Re-evaluation Date**: [date]
```

## 4. Cross-Sprint Risk Accumulation

### Risk Accumulation Pattern

Risks that are not resolved in one Sprint accumulate and compound:

```
Sprint 3:
- R-001: Redis staging availability (Medium probability, High impact)
  → Mitigation: verify with @devops
  → Status: Not verified by Sprint end

Sprint 4:
- R-001: Redis staging availability (now High probability — still not verified)
  → Impact increased: T-024 (cache layer) now in Sprint 4, blocked if Redis unavailable
  → New risk: R-004 — Sprint 4 goal at risk if T-024 blocked

Sprint 5:
- R-001: Redis staging availability (Critical — blocking T-024 and T-031)
- R-004: Sprint goal at risk (cascaded from R-001)
- Total risk exposure: 2× original
```

### Cross-Sprint Risk Tracking

```
## Cross-Sprint Risk Register

| Risk ID | Origin Sprint | Current Sprint | Age | Probability | Impact | Status | Escalation |
|---------|--------------|----------------|-----|-------------|--------|--------|------------|
| R-001 | Sprint 3 | Sprint 5 | 2 sprints | High | Critical | Escalated | User notified |
| R-002 | Sprint 4 | Sprint 4 | 1 sprint | Medium | Medium | Active | Monitoring |

**Accumulated Risk Exposure**: [summary of compounded risks]
**Recommended Action**: [specific action to resolve accumulated risks]
```

### Risk Burn-Down

Track risk resolution like task completion:

```
## Sprint Risk Burn-Down

Sprint 4 Start:
- Active risks: 5
- Critical: 1
- High: 2
- Medium: 2

Sprint 4 End:
- Active risks: 3
- Critical: 0 (R-001 escalated and resolved)
- High: 1
- Medium: 2
- New risks introduced: 1
- Risks resolved: 3

Trend: Risk resolution rate improving. 1 critical risk escalated to user and resolved.
```

## 5. Progress Visualization Formats

### Task Board Summary

```
## Task Board: Sprint-N

### Active (in progress)
| Task | State | Agent | Age | Rework | Blockers |
|------|-------|-------|-----|--------|----------|
| T-022 | development | @backend | 2 days | 0 | None |
| T-025 | scheme | @dev-lead | 1 day | 0 | None |

### Blocked
| Task | State | Blocker | Age | SLA Status |
|------|-------|---------|-----|------------|
| T-019 | BLOCKED | B-002 (user decision) | 22h | ✓ Within SLA |
| T-023 | BLOCKED | B-003 (scheme missing) | 26h | ⚠️ BREACH |

### Ready for Dispatch
| Task | State | Next Agent | Priority | Critical Path? |
|------|-------|------------|----------|----------------|
| T-021 | scheme-complete | @backend | P1 | Yes |

### Completed (this Sprint)
| Task | Completed | Agent | Rework |
|------|-----------|-------|--------|
| T-020 | 2026-04-19 | @backend | 0 |
```

### Sprint Progress Bar

```
Sprint-N Progress: [████████░░░░░░░░░░░░] 40% (8/20 story points)

By State:
- requirements: 2 tasks
- scheme: 1 task
- development: 2 tasks
- review: 1 task
- test: 1 task
- archived: 3 tasks

By Agent:
- @dev-lead: 1 active
- @backend: 2 active
- @code-review: 1 active
- @test-func: 1 active
```

### Cumulative Flow

```
## Cumulative Flow: Last 7 Days

          requirements  scheme  development  review  test  archived
Day -7:   5            2       3            1       1     2
Day -6:   4            3       3            1       1     3
Day -5:   3            3       4            1       1     4
Day -4:   3            2       4            2       1     5
Day -3:   2            2       4            2       2     5
Day -2:   2            1       4            3       2     5
Day -1:   1            1       3            3       3     6
Day 0:    1            1       2            3       3     7

Trend: Archived tasks increasing. Development WIP stable. Review/test bottleneck emerging.
Action: Consider if @code-review capacity is sufficient.
```

## 6. Progress Tracking Anti-Patterns

### Progress Theater

**Definition**: Creating the appearance of progress without actual advancement. Tasks move through states but quality gates are skipped or faked.

**Manifestation**:
```
# BAD
PM: "T-022 is in review state."
# Reality: @code-review returned CHANGES REQUESTED but PM moved task to review anyway.
# → State does not reflect reality. Quality gate was not actually passed.

# GOOD
PM: "T-022: @code-review returned CHANGES REQUESTED. State remains development.
Re-dispatching @backend with specific findings."
```

### Vanity Metrics

**Definition**: Tracking metrics that look good but don't indicate actual project health.

**Manifestation**:
```
# BAD
PM: "We completed 10 tasks this Sprint!"
# Reality: 8 of those tasks were fast-path typo fixes. The 2 complex tasks are both blocked.
# → Task count is meaningless without considering complexity and business value.

# GOOD
PM: "Sprint progress: 40% by story points. 3 tasks archived (including 1 critical path task).
2 tasks blocked (1 SLA breach). Critical path delay: 1 day."
```

### Stale Progress Log

**Definition**: progress-log.md not updated after state changes, creating a disconnect between the log and reality.

**Manifestation**:
```
# BAD
progress-log.md last entry: 2026-04-20
Current date: 2026-04-23
# → 3 days of activity not logged. Cannot reconstruct project state from log.

# GOOD
Every state change immediately logged. progress-log.md reflects reality within minutes.
```

## 7. Progress Tracking Checklist

### Daily
- [ ] Review all active tasks for state accuracy
- [ ] Update progress-log.md with any new dispatches or state changes
- [ ] Check blocker ages against SLA
- [ ] Verify TASK.md matches actual project state

### Per-Dispatch
- [ ] Log dispatch to progress-log.md
- [ ] Update TASK.md task state
- [ ] Check if dispatch creates new dependencies or blockers
- [ ] Verify the dispatched task is the highest-priority ready task

### Per-Agent-Return
- [ ] Parse return status (READY-FOR-NEXT / BLOCKED / FAILED / UNSURE)
- [ ] Update TASK.md with return summary
- [ ] Check rework counter
- [ ] If BLOCKED: register blocker, set SLA, notify owner
- [ ] If FAILED: increment rework counter, assess escalation need
- [ ] Log return to progress-log.md

### Per-Sprint
- [ ] Calculate velocity (story points completed)
- [ ] Calculate rework rate (reworked tasks / total tasks)
- [ ] Calculate blocker resolution time (average age of resolved blockers)
- [ ] Update risk register
- [ ] Archive completed Sprint data
- [ ] Plan next Sprint based on velocity and capacity
