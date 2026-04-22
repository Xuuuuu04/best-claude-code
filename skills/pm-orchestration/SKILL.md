---
name: pm-orchestration
description: Task state machine, INVEST decomposition, single-step dispatch, three-rework escalation, progress logging. Loaded by @pm via skills: frontmatter.
---

# PM Orchestration Skill

## 1. Task State Machine

```
requirements → scheme → development → review → test → verdict → archived
     ↑            ↑          ↑          ↑        ↑       ↑
     └────────────┴──────────┴──────────┴────────┴───────┘
              (rework loops back to appropriate state)
```

### State Entry/Exit Conditions

| State | Entry Condition | Exit Trigger | Documents Required |
|---|---|---|---|
| requirements | User request received | Decomposition complete, decisions resolved | User input, project CLAUDE.md, TASK.md |
| scheme | INVEST passed, dependencies mapped | Scheme document approved | Task list, dependency graph |
| development | Scheme approved, migrations applied | Self-test passed (happy + error path) | Scheme doc, migration status |
| review | Implementation complete, self-test passed | PASS → test; CHANGES → development | Changed files, self-test output |
| test | Code-review passed, no HIGH findings | Test pass → verdict; FAIL → development | Review report, test plan |
| verdict | Functional + UI tests passed | PASS → archive; FAIL → development | Test reports, security audit |
| archived | DoD signed off | Terminal state | All gate reports, version snapshot |

### State Transition Guards
- requirements → scheme: INVEST test passed, dependency graph documented, no phantom blockers
- scheme → development: scheme approved, migration plan confirmed if schema changes, API contracts defined
- development → review: implementation complete, self-test passed, security baseline passed, changed files documented
- review → test: code-review PASS or all changes addressed, no HIGH findings remaining
- test → verdict: test-func PASS, test-ui PASS (if frontend), regression passed
- verdict → archived: test-lead PASS, DoD checklist complete, version snapshot recorded

## 2. INVEST Test

Every task must pass all six criteria:
- **Independent**: can be dispatched without parallel task completion
- **Negotiable**: scope adjustable without breaking the system
- **Valuable**: user/system-facing outcome
- **Estimable**: completable in one focused session
- **Small**: single core objective
- **Testable**: ≥3 observable acceptance criteria

## 3. Rework Counter Rules

- **Scope**: per-task-per-state
- **Increment**: "CHANGES REQUESTED", "FAILED", "send back for revision"
- **Do NOT increment**: state transitions, re-dispatch after PASS, agent handoffs within same state
- **Reset**: counter resets when task successfully exits the state
- **Trigger**: count = 3 at SAME state with SAME agent type

### Third-Rework Escalation Decision Tree

```
Task reaches rework = 3 at state X
│
├─ Same bug pattern across all 3 rounds?
│  → Implementation defect → @dev-lead (scheme re-evaluation)
├─ Plan fundamentally unworkable from round 1?
│  → Scheme defect → @architect (structural) / @dev-lead (interface)
├─ Spec genuinely unclear or contradictory?
│  → Requirement ambiguity → @client or user clarification
├─ Reviewer and implementer disagree on standards?
│  → Quality gate misalignment → surface to user
└─ Agent lacks capacity or skill?
   → Resource constraint → reassign or escalate
```

Post-escalation: do NOT auto-dispatch back to original path. Re-evaluate plan and start fresh dispatch chain. Reset rework counter.

## 4. Dispatch Discipline

### Single-Step Rule
Dispatch exactly ONE next-hop per response. Record future steps in TASK.md as "pending dispatch" with dependency note.

### Fast-Path Test
Before accepting any routing task, check:
1. Single file only? ✓
2. No schema/migration changes? ✓
3. No new API endpoints or contracts? ✓
4. No requirement ambiguity? ✓

All four yes → fast-path. Main process dispatches directly. Do not route through pm.

### Rationale-Driven Dispatch
Every dispatch must answer "why this agent, not a different one?"

### Multi-Step Orchestration
For 5+ tasks with complex dependencies:
1. BUILD dependency graph
2. IDENTIFY critical path
3. BATCH non-critical-path tasks (truly independent only)
4. ESTABLISH milestone checkpoints (every 2-3 critical path steps)
5. MAINTAIN live task board in TASK.md
6. SURFACE cumulative risk (single points of failure)

## 5. Progress Log Format

### Entry Format
```
[YYYY-MM-DD HH:MM] [TAG] Task-NNN → @agent-name | reason | rework:N
```

### Tags
| Tag | Meaning | When to use |
|---|---|---|
| [SCHEME] | Task entering scheme state | Dispatching to @dev-lead / @architect |
| [DEVELOPMENT] | Task entering development | Dispatching to implementer |
| [REVIEW] | Task entering review | Dispatching to @code-review |
| [TEST] | Task entering test | Dispatching to @test-func / @test-ui |
| [VERDICT] | Task entering verdict | Dispatching to @test-lead |
| [ARCHIVED] | Task completed | Terminal state |
| [BLOCKED] | Task cannot proceed | Decision/resource/external blocker |
| [ESCALATE] | Third-rework trigger | Escalation in progress |
| [SCOPE] | Scope change detected | User decision required |
| [DECISION] | Decision recorded | User or agent made decision |
| [RISK] | Risk signal | Overrun or dependency delay |
| [MILESTONE] | Milestone checkpoint | Verification point |

### Blocker Register
| Blocker ID | Task ID | Description | Type | Owner | Discovery | Age | Unblock Condition |

### Risk Register
| Risk ID | Type | Description | Probability | Impact | Mitigation | Owner |

## 6. Anti-Patterns

### Phantom Blocker
Marking BLOCKED when needed information exists in project context. Correction: run Glob and Grep before declaring BLOCKED.

### Decision Ping-Pong
Bouncing decision between agents without surfacing to user. Correction: if ≥2 agents passed decision back without resolution, it belongs to the user.

### Multi-Hop Plan
Outputting multiple next steps in single response. Correction: dispatch exactly one step; record future as "pending dispatch".

### Scope Drift
Allowing task scope to expand silently. Correction: surface scope change request with original vs proposed + impact quantification.

### Stale Task
Completed task not archived. Correction: every READY-FOR-NEXT triggers immediate TASK.md update and archive.

### Dispatch Carpet Bomb
Dispatching dependent tasks in parallel. Correction: analyze dependencies; only parallelize truly independent tasks.

### Ghost Task
Task with no owner, no clear next step, no unblock condition. Correction: every task needs description, DoD, state, and next step.

### Scope Vacuum
Task with undefined or infinitely expandable boundary. Correction: DoD three-element rule — ≥3 observable criteria, concrete states, no subjective judgment.

### Priority Inflation
Labeling every task as HIGH. Correction: strict P0-P3 framework with explicit criteria.

| Priority | Criteria | Dispatch Order |
|---|---|---|
| P0 — Critical | Production outage, security incident, data loss | Immediate, interrupts current work |
| P1 — High | Blocks critical path, Sprint goal at risk | Next dispatch after current |
| P2 — Medium | Important but not blocking | Queue for next slot |
| P3 — Low | Nice-to-have, maintenance | Backlog |

Max 1 P0 and 2-3 P1 tasks at any time.

## 7. Collaboration Boundaries

### Case 1: @dev-lead vs @architect
- Interface contracts, API design, module interaction → @dev-lead
- System topology, technology selection, cross-module patterns → @architect
- Unclear → @dev-lead first; escalate if needed

### Case 2: @backend vs @database
- @database first (migration), then @backend (implementation)
- Never dispatch @backend before migration applied

### Case 3: @frontend vs @backend
- @backend first (API contract must exist)
- Exception: @frontend mock/prototype with stubbed API

### Case 4: Security-Auditor Gate Placement
- Security-sensitive tasks: AFTER @code-review, BEFORE @test-func
- Non-security-sensitive: parallel with @test-func
- Never skip for auth, payment, or PII-handling features
