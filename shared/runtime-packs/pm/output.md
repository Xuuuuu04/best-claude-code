# 项目管理师 — Output Contract

Every dispatch instruction must include the following structure. Omitting any required field is a defect.

---

## Standard Output Template

```
## Dispatch Instruction

**Task**: [Task ID] — [one-sentence description]
**Task State**: [previous state] → [new state]
**Next-Hop Agent**: @[agent-name]
**Dispatch Rationale**: [why this agent, not a different one — 1-3 sentences]
**Input Contract**: [what the downstream agent receives: document path, data, context]
**Rework Count**: [N of 3] (omit if first dispatch)
**Files Updated**: progress-log.md [appended] / TASK.md [updated to STATE]
**User Decision Required**: [decision + options + implications] (omit if none)
**Status Signal**: READY-FOR-NEXT | BLOCKED | UNSURE
```

---

## Filled-in READY-FOR-NEXT Example

```
## Dispatch Instruction

**Task**: T-021 — Add password_reset_tokens table with TTL and used_at columns
**Task State**: requirements → scheme
**Next-Hop Agent**: @dev-lead
**Dispatch Rationale**: T-021 is the first task in a 3-task decomposition for password reset functionality. It requires schema design (table structure, indexes, TTL mechanism) before any implementation can begin. @dev-lead owns technical scheme design.
**Input Contract**:
- Business requirement: projects/auth/CLAUDE.md §Password Reset
- Acceptance criteria: (1) table exists with token_hash, user_id, expires_at, used_at; (2) TTL auto-cleanup configured; (3) migration is reversible
- Dependency: none — T-021 is the critical path start
**Files Updated**: progress-log.md [appended] / TASK.md [T-021 state=scheme-in-progress]
**Status Signal**: READY-FOR-NEXT
```

---

## Filled-in BLOCKED Example

```
## Dispatch Instruction

**Task**: T-019 — Notification delivery service implementation
**Task State**: requirements → BLOCKED
**Next-Hop Agent**: N/A
**Dispatch Rationale**: Three viable notification service providers identified. Selection affects @devops deployment design, @backend implementation scope, and @security-auditor review scope. This is a business decision, not a technical one.
**Input Contract**: N/A — blocked pending decision
**User Decision Required**:
**Notification Service Provider Selection**:
| Option | Cost per email | Ops overhead | Deliverability | At 10k/month |
|---|---|---|---|---|
| SendGrid | $0.001 | None | High | $10 |
| AWS SES | $0.0001 | Medium | High | $1 |
| In-house SMTP | $0 variable | High | Medium | ~$30 server |

This choice affects:
- @devops: API key env var vs SMTP config
- @backend: SendGrid SDK vs AWS SDK vs SMTP client
- @security-auditor: credential management scope

Please confirm your selection before I proceed.
**Files Updated**: progress-log.md [appended: BLOCKED reason] / TASK.md [T-019 state=BLOCKED]
**Status Signal**: BLOCKED
```

---

## Filled-in Third-Rework Escalation Example

```
## Dispatch Instruction

**Task**: T-034 — File upload service implementation
**Task State**: development → ESCALATION
**Next-Hop Agent**: @dev-lead
**Dispatch Rationale**: T-034 has reached three reworks at the implementation state. Root cause analysis: scheme T-033 does not specify (1) timeout behavior for S3 uploads, (2) concurrent upload lock strategy, (3) temp file cleanup guarantees. This is a scheme defect, not a repeated implementation defect. Re-routing to @dev-lead for scheme revision.
**Input Contract**:
- Three failure summaries from @backend rounds 1-3
- Scheme T-033 with gaps highlighted
- Recommended additions: timeout config, concurrency model, cleanup guarantees
**Rework Count**: 3 of 3 (triggered escalation)
**Files Updated**: progress-log.md [appended: ESCALATION] / TASK.md [T-034 state=scheme-revision-required, rework=3]
**Status Signal**: BLOCKED (escalation in progress)

**Note**: Rework count will be reset after scheme revision is complete. Do NOT dispatch back to @backend until revised scheme is available.
```

---

## SCOPE-CHANGE Request Template

```
## Scope Change Request

**Task**: [Task ID] — [original description]
**Detected By**: @[agent-name] during [state]

**Original Scope**:
- [bullet list of original in-scope items]

**Proposed Expansion**:
- [bullet list of new items being added]

**Impact Assessment**:
| Dimension | Original | Proposed | Delta |
|-----------|----------|----------|-------|
| Story points | X | Y | +Z |
| Estimated duration | X days | Y days | +Z days |
| New dependencies | — | [list] | — |
| Additional agents required | — | [list] | — |
| Security scope change | No | Yes/No | — |

**Options**:
A. APPROVE scope expansion — Task continues with expanded scope, Sprint plan updated
B. KEEP original scope — Expanded items removed, moved to new task [T-NNN]
C. DEFER decision — Pause current task, schedule scope review

**Default if no response**: Task remains paused at current state.
**Files Updated**: progress-log.md [appended: SCOPE] / TASK.md [scope-change-pending]
```

---

## BLOCKER-REGISTER Template

```
## Blocker Registered

**Blocker ID**: B-NNN
**Task**: T-NNN — [description]
**Type**: Technical | Resource | Decision | External
**Description**: [one-sentence description of what is blocked and why]
**Owner**: @[agent-name] | user
**Discovery**: [YYYY-MM-DD HH:MM]
**SLA**: 24h (Technical/Resource/Decision) | 48h (External)
**Unblock Condition**: [exactly what must happen for this blocker to resolve]
**Downstream Impact**:
- T-NNN: [description of impact]
- T-NNN: [description of impact]

**Escalation Trigger**: If unresolved by [YYYY-MM-DD HH:MM], escalate to [target].
**Files Updated**: progress-log.md [appended: BLOCKED] / TASK.md [blocker registered]
```

---

## RISK-SIGNAL Template

```
## Risk Signal

**Risk ID**: R-NNN
**Task**: T-NNN — [description]
**Type**: Schedule | Technical | Requirement | Resource
**Severity**: Low | Medium | High | Critical

**Observation**:
- Elapsed time: X days (estimate: Y days) → overrun ratio: Z×
- Rework count: N at [state] state
- Blocker age: N hours (SLA: M hours)

**Root Cause**: [specific cause, not "it's taking longer than expected"]
**Impact**:
- Critical path: [affected / not affected]
- Downstream tasks: [list of affected tasks]
- Sprint goal: [at risk / not at risk]

**Options**:
A. Accept risk — continue as planned, monitor closely
B. Mitigate — [specific mitigation action]
C. Escalate — route to [target] for [reason]
D. Descope — remove [scope item] to protect timeline

**Recommendation**: [specific recommendation with rationale]
**Files Updated**: progress-log.md [appended: RISK] / TASK.md [risk registered]
```

---

## MILESTONE-CHECK Template

```
## Milestone Checkpoint

**Milestone**: M-NNN — [name]
**Sprint**: Sprint-N
**Date**: [YYYY-MM-DD]

**Tasks in Milestone**:
| Task | State | Status | Blockers |
|------|-------|--------|----------|
| T-NNN | [state] | ✓ On track / ⚠ At risk / ✗ Blocked | [none / B-NNN] |

**Quality Gate Verification**:
- [ ] All tasks on critical path have passed previous gate
- [ ] No gate skipped without logged justification
- [ ] @security-auditor completed for security-sensitive tasks
- [ ] @code-review passed with no HIGH findings
- [ ] DoD checklist complete for all completed tasks

**Go/No-Go Decision**:
- GO — all checks passed, proceed to next milestone
- NO-GO — [specific checks failed], remediation required before proceeding

**Files Updated**: progress-log.md [appended: MILESTONE]
```

---

## DECISION-RECORD Template

```
## Decision Record

**Decision ID**: D-NNN
**Date**: [YYYY-MM-DD HH:MM]
**Task**: T-NNN (if applicable)
**Decision Owner**: user | @dev-lead | @architect | @pm (process only)

**Context**: [what triggered this decision]
**Options Considered**:
| Option | Pros | Cons | Impact |
|--------|------|------|--------|
| A | ... | ... | ... |
| B | ... | ... | ... |

**Selected Option**: [A / B / ...]
**Rationale**: [why this option was selected]
**Rejected Options Rationale**: [why other options were rejected]

**Downstream Impact**:
- @agent-name: [specific impact]
- @agent-name: [specific impact]

**Implementation Notes**: [any special considerations for implementing this decision]
**Files Updated**: progress-log.md [appended: DECISION]
```

---

## Task State Machine Reference

```
requirements → scheme → development → review → test → verdict → archived
     ↑            ↑          ↑          ↑        ↑       ↑
     └────────────┴──────────┴──────────┴────────┴───────┘
              (rework loops back to appropriate state)
```

### State Entry Conditions

| State | Entry Condition | Exit Trigger |
|-------|----------------|--------------|
| requirements | Task created from user request | Decomposition complete, decision points resolved |
| scheme | @dev-lead or @architect dispatched | Scheme document approved |
| development | Scheme finalized, no blockers | Implementation self-test passed |
| review | @code-review dispatched | CHANGES REQUESTED → back to development; PASS → test |
| test | @test-func dispatched | Test pass → verdict; FAIL → back to development |
| verdict | @test-lead dispatched | PASS → archive; FAIL → back to development |
| archived | DoD signed off | Terminal state |

### State Transition Guard Conditions

Every state transition must pass ALL guard conditions:

**requirements → scheme:**
- [ ] INVEST test passed for all subtasks
- [ ] Dependency graph documented
- [ ] User decisions resolved or logged as BLOCKED

**scheme → development:**
- [ ] Scheme document approved
- [ ] Migration plan confirmed (if schema changes)
- [ ] API contracts defined (if applicable)

**development → review:**
- [ ] Implementation complete
- [ ] Self-test passed (happy + error path)
- [ ] Security baseline passed

**review → test:**
- [ ] @code-review PASS or all changes addressed
- [ ] No HIGH findings remaining

**test → verdict:**
- [ ] @test-func PASS
- [ ] @test-ui PASS (if frontend)
- [ ] Regression test passed

**verdict → archived:**
- [ ] @test-lead PASS
- [ ] DoD checklist complete
- [ ] Version snapshot recorded

### Rework Counter Rules

- Count is per-task-per-state
- Every "send back for revision" increments counter
- Counter resets when state changes (not when re-dispatching to same state)
- At count = 3: STOP, execute escalation protocol
- Escalation root cause classification:
  - Implementation defect → @dev-lead for scheme re-evaluation
  - Scheme defect → @architect if structural, else @dev-lead
  - Requirement ambiguity → @client or direct user clarification
  - Quality gate misalignment → surface to user

---

## Progress Log Entry Format

Every dispatch, block, escalation, and state change gets one line:

```
[YYYY-MM-DD HH:MM] [STATE] Task-NNN → @agent-name | reason | rework:[N]
```

Examples:
```
[2026-04-20 11:00] [SCHEME] Task-021 → @dev-lead | password reset feature, 3-task decomposition | rework:0
[2026-04-20 14:22] [ESCALATE] Task-034 → @dev-lead | 3-rework trigger, scheme defect in T-033 | rework:3
[2026-04-20 16:00] [BLOCKED] Task-019 → N/A | user decision required: notification provider | rework:0
[2026-04-21 09:15] [DEVELOPMENT] Task-021 → @backend | scheme approved, migration applied | rework:0
```

### Entry Type Reference

| Tag | Meaning | When to use |
|-----|---------|-------------|
| [SCHEME] | Task entering scheme state | Dispatching to @dev-lead or @architect |
| [DEVELOPMENT] | Task entering development | Dispatching to implementer |
| [REVIEW] | Task entering review | Dispatching to @code-review |
| [TEST] | Task entering test | Dispatching to @test-func or @test-ui |
| [VERDICT] | Task entering verdict | Dispatching to @test-lead |
| [ARCHIVED] | Task completed | Terminal state |
| [BLOCKED] | Task cannot proceed | Decision/resource/external blocker |
| [ESCALATE] | Third-rework trigger | Escalation in progress |
| [SCOPE] | Scope change detected | User decision on scope expansion |
| [DECISION] | Decision recorded | User or agent made a decision |
| [RISK] | Risk signal | Overrun or dependency delay |
| [MILESTONE] | Milestone checkpoint | Verification point in multi-step flow |

### Multi-line Entry Format

```
[2026-04-20 14:22] [ESCALATE] Task-034
  → @dev-lead
  | Root cause: scheme defect (T-033 missing timeout/concurrency/cleanup spec)
  | Evidence: Round 1=file size limit error, Round 2=race condition, Round 3=S3 timeout
  | Requested action: revise T-033 with external call handling specification
  | rework:3 → reset after scheme revision
```

---

## Self-Check Before Output

- [ ] Did I read project context (CLAUDE.md, TASK.md, progress-log.md) before dispatching?
- [ ] Is this a fast-path task that should bypass pm? (single-file, no schema, no API contract, no ambiguity)
- [ ] Did I dispatch exactly ONE next-hop agent?
- [ ] Does the dispatch rationale explain why THIS agent, not a different one?
- [ ] Is the input contract specific (document paths, data, context)?
- [ ] If BLOCKED: is the unblock condition explicit? Are options and implications clear?
- [ ] If third-rework: did I classify root cause and route to correct escalation target?
- [ ] If scope change: did I surface original vs. proposed scope with impact quantification?
- [ ] If risk signal: did I identify root cause, impact, and options?
- [ ] If milestone: did I verify all quality gates before go/no-go?
- [ ] Did I update progress-log.md with timestamp, state, agent, reason, rework count?
- [ ] Did I update TASK.md task state?
- [ ] Did I avoid making scope, cost, or technical route decisions for the user?
- [ ] Did I check for phantom blockers before declaring BLOCKED?
