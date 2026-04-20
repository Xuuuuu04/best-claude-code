# 项目管理师 — Domain: Escalation Protocol Depth

## 1. Escalation Trigger Conditions

An escalation is triggered when any of the following conditions are met:

| Trigger | Condition | Automatic? | Log Tag |
|---------|-----------|------------|---------|
| Third-rework | Rework count = 3 at same state | Yes | [ESCALATE] |
| Blocker SLA breach | Blocker age > SLA (24h Technical/Decision, 48h External) | Yes | [ESCALATE] |
| Boundary dispute | Two agents dispute ownership with no resolution after 1 round | No | [ESCALATE] |
| User decision required | Business decision (scope/cost/schedule) with no user response > 48h | No | [ESCALATE] |
| Quality gate failure cascade | Same gate fails 2+ consecutive tasks | No | [ESCALATE] |
| Agent capacity exhaustion | Agent reports inability to complete task type | No | [ESCALATE] |
| Scheme unworkable | Implementer identifies fundamental scheme flaw on first attempt | No | [ESCALATE] |

## 2. Escalation Target Mapping

### Decision Tree: Where to Escalate

```
Escalation triggered
│
├─ Is this a third-rework escalation?
│  ├─ Root cause = Implementation defect → @dev-lead
│  ├─ Root cause = Scheme defect (structural) → @architect
│  ├─ Root cause = Scheme defect (interface) → @dev-lead
│  ├─ Root cause = Requirement ambiguity → @client or user
│  ├─ Root cause = Quality gate misalignment → user
│  └─ Root cause = Resource constraint → @pm
│
├─ Is this a blocker SLA breach?
│  ├─ Blocker type = Technical → escalate to blocker's manager (@dev-lead for scheme, @architect for architecture)
│  ├─ Blocker type = Resource → @pm for resource reallocation
│  ├─ Blocker type = Decision → user (with urgency flag)
│  └─ Blocker type = External → user (with impact quantification)
│
├─ Is this a boundary dispute?
│  └─ Route to @dev-lead for technical boundaries, @pm for process boundaries
│
├─ Is this a user decision timeout?
│  └─ Re-surface to user with urgency flag and default option
│
├─ Is this a quality gate cascade?
│  └─ Route to @test-lead for test standards, @dev-lead for implementation standards
│
└─ Is this agent capacity exhaustion?
   └─ Route to @pm for reassignment or training
```

### Escalation Target Reference

| Target | Escalation Type | When to Use | When NOT to Use |
|--------|----------------|-------------|-----------------|
| @dev-lead | Scheme/interface defect, implementation defect, technical blocker | Technical plan is wrong or incomplete | Business decisions, resource allocation |
| @architect | Structural scheme defect, system-level architecture gap | Cross-module design, technology selection | Interface-level gaps (use @dev-lead) |
| @client | Requirement ambiguity, user-facing scope questions | Spec is unclear, user needs clarification | Technical implementation issues |
| user | Business decisions, priority calls, scope approvals | Cost, schedule, scope trade-offs | Technical details (route through @dev-lead first) |
| @pm | Resource constraints, process gaps, blocker tracking | Agent unavailable, no owner for task type | Technical decisions |
| @test-lead | Quality gate standards, test strategy | Cascade test failures, test coverage gaps | Implementation defects |
| @prompt-engineer | Agent behavior anomalies, harness spec issues | Agent consistently violates rules | Normal task execution issues |

## 3. Escalation Information Template

### Standard Escalation Report

```
## Escalation Report: [Task/Blocker ID]

**Escalation ID**: E-NNN
**Date**: [YYYY-MM-DD HH:MM]
**Trigger**: [third-rework / blocker-breach / boundary-dispute / user-timeout / quality-cascade / capacity / scheme-flaw]

**Summary**: [one-sentence description of what is being escalated]

**Background**:
[2-3 sentences of context — what led to this escalation]

**Evidence**:
- [ ] Evidence item 1: [specific observation]
- [ ] Evidence item 2: [specific observation]
- [ ] Evidence item 3: [specific observation]

**Root Cause Analysis**:
[Classification with supporting reasoning]

**Impact Assessment**:
| Dimension | Impact |
|-----------|--------|
| Tasks affected | [list] |
| Schedule | [delay estimate] |
| Sprint goal | [at risk / not at risk] |
| Downstream agents | [list of agents affected] |

**Requested Action**:
[Specific, actionable request for the escalation target]

**Timeline**:
- Escalation dispatched: [date]
- Expected resolution: [date]
- Next check: [date]

**Files Updated**: progress-log.md [appended: ESCALATE] / TASK.md [escalation logged]
```

### Third-Rework Escalation Report (Detailed)

```
## Escalation Report: Task-NNN — Third Rework

**Escalation ID**: E-NNN
**Date**: [YYYY-MM-DD HH:MM]
**Task**: T-NNN — [description]
**State**: [state where rework occurred]

**Rework History**:
| Round | Date | Agent | Outcome | Failure Summary |
|-------|------|-------|---------|-----------------|
| 1 | [date] | @[name] | FAILED | [specific failure] |
| 2 | [date] | @[name] | CHANGES REQUESTED | [specific failure] |
| 3 | [date] | @[name] | FAILED | [specific failure] |

**Pattern Analysis**:
[What do the three failures have in common? Same bug type? Same component? Same missing specification?]

**Root Cause Classification**: [implementation / scheme / requirement / quality / resource]
**Classification Rationale**: [why this classification, not another]

**Escalation Target**: @[agent-name]
**Requested Action**: [specific request]

**Post-Escalation Plan**:
- [ ] Do NOT dispatch back to original agent automatically
- [ ] Re-evaluate plan after escalation resolution
- [ ] Reset rework counter
- [ ] Document lesson learned

**Rework Count**: 3 → reset to 0 after escalation resolution
```

### Blocker SLA Breach Escalation Report

```
## Escalation Report: Blocker B-NNN — SLA Breach

**Escalation ID**: E-NNN
**Date**: [YYYY-MM-DD HH:MM]
**Blocker**: B-NNN
**Task**: T-NNN — [description]

**Blocker Details**:
- Type: [Technical / Resource / Decision / External]
- Owner: @[agent-name] / user
- Discovery: [date]
- SLA: [X hours]
- Actual age: [Y hours] — BREACH by [Z hours]

**Previous Follow-ups**:
| Date | Action | Response |
|------|--------|----------|
| [date] | Pinged owner | [response or no response] |
| [date] | Escalated to [target] | [response or no response] |

**Impact**:
- Downstream tasks blocked: [list]
- Critical path affected: [Yes/No]
- Sprint goal at risk: [Yes/No]

**Escalation Target**: @[agent-name]
**Requested Action**: [specific request with deadline]
```

## 4. Escalation Communication Protocol

### To @dev-lead

```
ESCALATION to @dev-lead

**Task**: T-NNN — [description]
**Trigger**: [reason]

**Problem**: [specific technical problem]
**Evidence**: [failure summaries, logs, outputs]
**Impact**: [what is blocked, how many tasks affected]

**Requested Action**: [specific request — scheme revision, clarification, re-evaluation]
**Deadline**: [when resolution is needed]

**Do NOT dispatch back to original agent until**: [specific condition]
```

### To @architect

```
ESCALATION to @architect

**Task**: T-NNN — [description]
**Trigger**: [reason]

**Problem**: [structural/system-level problem]
**Evidence**: [scheme gaps, cross-module issues, technology conflicts]
**Impact**: [system-wide implications]

**Requested Action**: [architectural decision or scheme revision]
**Deadline**: [when resolution is needed]

**Scope**: [whether this affects one module or multiple modules]
```

### To User

```
ESCALATION to User

**Task**: T-NNN — [description]
**Trigger**: [reason — usually decision timeout or business decision required]

**Decision Required**: [specific decision]
**Options**:
| Option | Pros | Cons | Impact |
|--------|------|------|--------|
| A | ... | ... | ... |
| B | ... | ... | ... |

**Default if no response by [date]**: [what will happen]
**Impact of delay**: [what happens if decision is delayed further]
**Recommended option**: [pm's recommendation with rationale]
```

## 5. Escalation Tracking

### Escalation Register

```
## Escalation Register

| Escalation ID | Task/Blocker | Trigger | Target | Dispatched | Resolved | Age | Status |
|---------------|--------------|---------|--------|------------|----------|-----|--------|
| E-001 | T-034 | 3-rework | @dev-lead | 2026-04-20 | 2026-04-21 | 24h | Resolved |
| E-002 | B-001 | SLA breach | @dev-lead | 2026-04-21 | — | 12h | Active |
| E-003 | T-019 | User timeout | user | 2026-04-21 | — | 6h | Active |
```

### Escalation Aging

| Age | Status | Action |
|-----|--------|--------|
| 0-12h | ✓ Fresh | Monitor |
| 12-24h | ⚠️ Aging | Ping escalation target |
| 24-48h | 🔴 Stalled | Escalate to next level (target's manager or user) |
| 48h+ | 🚨 Critical | User notification + consider descoping |

## 6. Post-Escalation Protocol

### Resolution Verification

When an escalation target returns a resolution:

```
- [ ] Read resolution carefully
- [ ] Verify resolution addresses the root cause (not just symptoms)
- [ ] Check for new dependencies introduced by resolution
- [ ] Check for downstream tasks affected by resolution
- [ ] Determine if original agent is still appropriate
- [ ] Reset rework counter
- [ ] Document lesson learned
- [ ] Start fresh dispatch chain
```

### Lesson Learned Template

```
## Lesson Learned: [Escalation ID]

**What happened**: [summary]
**Root cause**: [classification]
**How it was resolved**: [summary]
**How to prevent recurrence**:
- [ ] Action 1: [specific preventive action]
- [ ] Action 2: [specific preventive action]

**Process improvement**: [if applicable, update process documentation]
**Files Updated**: TASK.md [lesson learned appended] / shared/guides [if process change needed]
```

## 7. Escalation Anti-Patterns

### Escalation Avoidance

**Definition**: Delaying escalation beyond the trigger condition, hoping the problem resolves itself.

**Manifestation**:
```
# BAD
Rework count = 3. PM: "Let me try one more time with @backend before escalating."
# → Fourth dispatch violates the protocol. Wastes agent rounds.

# GOOD
Rework count = 3. PM immediately executes escalation protocol.
```

### Wrong Target Escalation

**Definition**: Escalating to the wrong agent (e.g., sending a scheme defect to @architect when it's interface-level).

**Manifestation**:
```
# BAD
Missing API error code definition → escalated to @architect
# → @architect deals with system topology, not API contracts

# GOOD
Missing API error code definition → escalated to @dev-lead
```

### Escalation Without Evidence

**Definition**: Escalating with vague complaints instead of specific evidence.

**Manifestation**:
```
# BAD
"@backend keeps failing this task. Please fix it."
# → No evidence, no root cause, no specific request

# GOOD
"Task-034 reached 3 reworks. Round 1: file size limit error. Round 2: race condition.
Round 3: S3 timeout. Pattern: scheme T-033 lacks external call specification.
Request: revise T-033 with timeout config, concurrency model, cleanup guarantees."
```
