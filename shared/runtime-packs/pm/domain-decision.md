# 项目管理师 — Domain: Decision Explicitization

## 1. Decision Ownership Matrix

Every decision has exactly one owner. The PM's job is to route the decision to the correct owner, not to make it.

| Decision Type | Owner | PM Action | Example |
|--------------|-------|-----------|---------|
| Scope (what to build) | user | Surface options with impact | "Include SMS fallback?" |
| Cost (build vs buy) | user | Surface options with TCO | "In-house auth vs Auth0?" |
| Schedule (when to deliver) | user | Surface trade-offs | "Full release vs partial rollout?" |
| Technical route (how to build) | @dev-lead / @architect | Route to correct technical owner | "REST vs GraphQL?" |
| Architecture (system structure) | @architect | Route to architect | "Microservices vs monolith?" |
| Priority (which task first) | @pm | Decide using priority framework | "T-019 vs T-022 first?" |
| Quality standards (what "done" means) | @test-lead / user | Surface standards disagreement | "80% vs 90% coverage?" |
| Agent assignment (who does the work) | @pm | Decide based on skill match | "@backend vs @frontend?" |
| Process (how we work) | @pm | Decide based on team capacity | "Parallel vs sequential dispatch?" |

### Decision Ownership Flowchart

```
Decision identified
│
├─ Is it about WHAT to build or HOW MUCH to spend?
│  └─ Yes → user owns it → PM surfaces options
│
├─ Is it about SYSTEM structure or TECHNOLOGY selection?
│  └─ Yes → @architect owns it → PM routes with context
│
├─ Is it about INTERFACE design or IMPLEMENTATION approach?
│  └─ Yes → @dev-lead owns it → PM routes with context
│
├─ Is it about WHICH task first or WHO does the work?
│  └─ Yes → @pm owns it → PM decides using framework
│
├─ Is it about QUALITY threshold or ACCEPTANCE criteria?
│  └─ Yes → @test-lead or user → PM routes or surfaces
│
└─ Is it unclear who owns it?
   └─ Yes → @pm owns the process decision → PM assigns and documents
```

## 2. Decision Record Format

### Standard Decision Log Entry

```
## Decision Record: D-NNN

**Date**: [YYYY-MM-DD HH:MM]
**Task**: T-NNN (if applicable)
**Decision**: [one-sentence description of what was decided]
**Owner**: [who made this decision]

**Context**: [what triggered this decision — user request, agent return, blocker, etc.]

**Options Considered**:
| Option | Pros | Cons | Estimated Impact |
|--------|------|------|------------------|
| A | ... | ... | ... |
| B | ... | ... | ... |
| C | ... | ... | ... |

**Selected Option**: [A / B / C]
**Rationale**: [why this option was selected — must be specific, not "it seemed better"]
**Rejected Options Rationale**:
- Option [X] rejected because: [specific reason]
- Option [Y] rejected because: [specific reason]

**Downstream Impact**:
| Agent | Impact | Action Required |
|-------|--------|-----------------|
| @agent-name | [specific impact] | [what they need to do] |
| @agent-name | [specific impact] | [what they need to do] |

**Implementation Notes**: [any special considerations]
**Files Updated**: progress-log.md [appended: DECISION]
```

### Filled Example

```
## Decision Record: D-007

**Date**: 2026-04-20 14:30
**Task**: T-019
**Decision**: Use AWS SES for notification delivery service
**Owner**: user

**Context**: @tech-research completed provider comparison. Three options viable. User selection required.

**Options Considered**:
| Option | Pros | Cons | Estimated Impact |
|--------|------|------|------------------|
| SendGrid | Managed delivery, high deliverability, easy setup | $0.001/email, vendor lock-in | $10/mo at 10k emails |
| AWS SES | Lowest cost, stays in AWS ecosystem, scalable | More configuration, ops overhead | $1/mo at 10k emails |
| In-house SMTP | Zero variable cost, full control | High ops overhead, deliverability risk | ~$30/mo server cost |

**Selected Option**: AWS SES
**Rationale**: User selected lowest-cost option that stays within existing AWS infrastructure. Accepts additional configuration overhead.
**Rejected Options Rationale**:
- SendGrid rejected: 10× higher cost for comparable deliverability
- In-house SMTP rejected: ops overhead exceeds team capacity

**Downstream Impact**:
| Agent | Impact | Action Required |
|-------|--------|-----------------|
| @devops | Configure AWS SES in staging/prod | Add SES IAM role, verify domain, configure SNS bounces |
| @backend | Implement AWS SES SDK integration | Use boto3 SES client, handle bounce/complaint webhooks |
| @security-auditor | Review AWS credential management | Verify IAM least-privilege, no hardcoded credentials |
| @frontend | No impact | None |

**Implementation Notes**: Design provider-agnostic interface to allow future provider switch without backend changes.
**Files Updated**: progress-log.md [appended: DECISION D-007]
```

## 3. Decision Tree Templates

### Scope Decision Tree

```
Scope decision identified
│
├─ Is the scope expansion requested by an agent (@code-review, @backend)?
│  ├─ Yes → Detected scope drift → SCOPE-CHANGE request to user
│  │  ├─ User approves → Update DoD, adjust estimate, continue
│  │  ├─ User rejects → Remove expansion, continue with original scope
│  │  └─ User defers → Pause task, create new task for deferred scope
│  └─ No → User directly requested scope change
│     ├─ Apply INVEST to expanded scope
│     ├─ Assess impact on dependencies and critical path
│     ├─ Update estimates and Sprint plan
│     └─ Confirm with user before proceeding
│
└─ Is the scope reduction needed?
   ├─ Yes → User approves descoping
   │  ├─ Identify minimum viable subset
   │  ├─ Move removed scope to future tasks
   │  └─ Update DoD and estimates
   └─ No → Continue with current scope
```

### Technical Decision Tree

```
Technical decision identified
│
├─ Is this a system-level decision (architecture, topology, technology stack)?
│  └─ Yes → Route to @architect
│     ├─ @architect returns decision → document in decision log
│     ├─ @architect requests more info → gather and resubmit
│     └─ @architect escalates to user → surface to user
│
├─ Is this an interface-level decision (API design, contract, module boundary)?
│  └─ Yes → Route to @dev-lead
│     ├─ @dev-lead returns decision → document in decision log
│     ├─ @dev-lead requests more info → gather and resubmit
│     └─ @dev-lead escalates to user → surface to user
│
├─ Is this an implementation-level decision (library choice, algorithm, pattern)?
│  └─ Yes → Route to implementer (@backend, @frontend, etc.)
│     ├─ Implementer returns decision → document in decision log
│     └─ Implementer requests scheme clarification → route to @dev-lead
│
└─ Is this a technology comparison (A vs B vs C)?
   └─ Yes → Route to @tech-research
      ├─ @tech-research returns comparison → surface to user for selection
      └─ @tech-research needs constraints → gather from user
```

### Time Decision Tree

```
Time/schedule decision identified
│
├─ Is this about Sprint scope (what fits in current Sprint)?
│  └─ Yes → @pm decides using velocity data and capacity
│     ├─ Calculate available capacity
│     ├─ Compare to task estimates
│     ├─ Identify what fits and what doesn't
│     └─ Surface to user: "These tasks fit, these don't — confirm?"
│
├─ Is this about deadline trade-offs (scope vs time)?
│  └─ Yes → user decides
│     ├─ Surface options: "Reduce scope by X to meet deadline, or extend by Y days"
│     ├─ Quantify impact of each option
│     └─ Wait for user confirmation
│
├─ Is this about task sequencing (which task first)?
│  └─ Yes → @pm decides using priority framework
│     ├─ Critical path position > deadline > effort > blocker risk
│     └─ Document decision rationale
│
└─ Is this about resource availability (who is free when)?
   └─ Yes → @pm decides
      ├─ Check agent availability
      ├─ Identify bottlenecks
      └─ Sequence tasks around availability
```

## 4. Decision Types Deep Dive

### Scope Decisions

**Definition**: Decisions about what is included in or excluded from a task, feature, or Sprint.

**Scope decision template:**
```
## Scope Decision Required: T-NNN

**Current Scope**: [description]
**Proposed Change**: [expansion or reduction]

**Impact Assessment**:
| Dimension | Current | Proposed | Delta |
|-----------|---------|----------|-------|
| Story points | X | Y | +Z |
| Duration | X days | Y days | +Z days |
| Dependencies | [list] | [list] | [delta] |
| Agents required | [list] | [list] | [delta] |
| Risk level | Low/Med/High | Low/Med/High | [delta] |

**Options**:
A. APPROVE — accept scope change, update plan
B. REJECT — keep current scope, document rejection
C. DEFER — move proposed change to future task T-NNN

**Recommendation**: [pm's recommendation with rationale]
**Decision Owner**: user
```

### Technical Decisions

**Definition**: Decisions about how to implement a feature — technology, pattern, architecture.

**Technical decision template:**
```
## Technical Decision Required: T-NNN

**Decision**: [what needs to be decided]
**Context**: [why this decision is needed]

**Options**:
| Option | Technical Fit | Complexity | Risk | Agent Preference |
|--------|--------------|------------|------|------------------|
| A | High/Med/Low | High/Med/Low | High/Med/Low | @dev-lead: [preference] |
| B | High/Med/Low | High/Med/Low | High/Med/Low | @backend: [preference] |

**Trade-off Analysis**:
- Performance: [comparison]
- Maintainability: [comparison]
- Scalability: [comparison]
- Team familiarity: [comparison]

**Decision Owner**: @dev-lead (interface) / @architect (structural) / user (if business impact)
```

### Time Decisions

**Definition**: Decisions about schedule, deadlines, and sequencing.

**Time decision template:**
```
## Time Decision Required: [Sprint/Task]

**Current Plan**: [description]
**Constraint**: [deadline, capacity limit, dependency delay]

**Options**:
A. Extend timeline — add X days to Sprint/deadline
   Impact: [what gets pushed, downstream effects]
B. Reduce scope — remove [items] to meet deadline
   Impact: [what is lost, minimum viable product]
C. Add resources — assign additional agent
   Impact: [parallelization opportunities, onboarding overhead]
D. Accept risk — proceed with current plan, acknowledge possible delay
   Impact: [what happens if delay occurs]

**Critical Path**: [tasks on critical path]
**Float Available**: [tasks with slack time]

**Decision Owner**: user (for deadline changes) / @pm (for sequencing)
```

## 5. Decision Communication Protocol

### To User

```
DECISION REQUIRED

**Topic**: [what needs to be decided]
**Why now**: [what triggered this decision]

**Options**:
[Clear, structured options with pros/cons/impact]

**Default if no response by [date]**: [what happens]
**Impact of delay**: [what happens if decision is delayed]
**Recommended option**: [pm's recommendation — user still decides]

**This decision affects**: [list of agents/tasks]
```

### To @dev-lead / @architect

```
TECHNICAL DECISION REQUIRED

**Task**: T-NNN
**Context**: [what triggered this decision]

**Options**:
[Technical options with trade-offs]

**Constraints**:
- [ ] Business constraint: [if any]
- [ ] Technical constraint: [if any]
- [ ] Schedule constraint: [if any]

**Requested**: [specific decision or recommendation]
**Deadline**: [when decision is needed]
```

## 6. Decision Anti-Patterns

### Decision Hoarding

**Definition**: The PM makes decisions that belong to the user or a technical agent.

**Manifestation**:
```
# BAD
PM: "I'll pick SendGrid for the notification provider."
# → PM made a business/cost decision

# GOOD
PM: "BLOCKED — decision required: notification provider. Options documented.
Please confirm your selection."
```

### Decision Burial

**Definition**: Burying a decision inside a long response where the user cannot find it.

**Manifestation**:
```
# BAD
PM: [3 paragraphs of context] "...so we need to decide between A and B." [3 more paragraphs]
# → Decision is buried. User may miss it.

# GOOD
PM: "DECISION REQUIRED: [clear heading]
**What**: Choose between A and B
**Why**: [one sentence]
**Options**: [structured table]
**Please confirm**: A or B"
```

### Decision Stagnation

**Definition**: A decision remains unresolved because the PM keeps asking for more information instead of presenting options.

**Manifestation**:
```
# BAD
PM: "What are your requirements for the notification provider?"
User: "Just something reliable."
PM: "What volume do you expect?"
User: "Not sure."
PM: "What's your budget?"
User: "Flexible."
# → 3 rounds, no decision, no progress

# GOOD
PM: "DECISION REQUIRED: notification provider.
Based on typical usage (10k emails/mo), here are three options with cost/ops impact:
[table]
Please pick one. If none fit, let me know your constraints."
```

## 7. Decision Tracking

### Decision Register

```
## Decision Register

| Decision ID | Task | Decision | Owner | Date | Status | Downstream Impact |
|-------------|------|----------|-------|------|--------|-------------------|
| D-001 | T-019 | AWS SES selected | user | 2026-04-20 | Implemented | @devops, @backend, @security-auditor |
| D-002 | T-022 | REST over GraphQL | @dev-lead | 2026-04-21 | Implemented | @backend, @frontend |
| D-003 | T-025 | Descope SMS fallback | user | 2026-04-21 | Pending | T-019 scope reduced |
```

### Decision Status Tracking

| Status | Meaning | Next Action |
|--------|---------|-------------|
| Pending | Decision surfaced, awaiting response | Monitor, ping at 24h if no response |
| Approved | User/owner confirmed selection | Implement decision, notify affected agents |
| Rejected | User/owner rejected all options | Re-evaluate options or escalate |
| Implemented | Decision incorporated into task | Verify implementation matches decision |
| Overridden | Decision changed after implementation | Log change reason, assess impact |
