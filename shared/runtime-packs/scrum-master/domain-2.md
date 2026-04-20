# 进度管理师 — Domain 2: Blocker Management

## 2.1 Blocker Taxonomy

### Technical Blocker

**Identification signal**: The implementing agent cannot make progress without a design decision, scheme clarification, or architecture definition.

**Examples**:
- "The scheme doesn't specify which JWT signing algorithm to use"
- "I need to know the database transaction isolation level for this operation"
- "The API contract between frontend and backend is undefined"

**Escalation path**: @dev-lead immediately
**SLA**: 24 hours for response, 48 hours for resolution
**Do NOT**: Diagnose the technical issue yourself. Route and track only.

```
# GOOD
@backend: "I don't know whether to use optimistic or pessimistic locking for the inventory update."
Scrum-master: "That's a Technical Blocker. Logging T-019-B1. Routing to @dev-lead immediately.
24h clock started. Can you proceed on any other part of T-019?"
```

### Resource Blocker

**Identification signal**: The agent has everything except one specific external dependency.

**Examples**:
- "I'm waiting for the database migration to be applied"
- "The staging API key hasn't been provisioned yet"
- "I need the design mockup for the checkout page"

**Escalation path**: @pm with specific unblock condition and ETA
**SLA**: 24 hours for ETA, 48 hours for resolution

```
# GOOD
@frontend: "I'm waiting on the error response format from T-019."
Scrum-master: "BLOCKER LOGGED: T-022-B1. Type: Resource.
Description: Error response format for POST /auth/login undefined.
Routed to @dev-lead. Unblock condition: HTTP codes + response schema documented.
ETA needed by 2026-04-21 10:05."
```

### Decision Blocker

**Identification signal**: A business or priority question that the team cannot answer.

**Examples**:
- "Should we support passwordless login?"
- "Which payment provider should we use?"
- "Do we need to support IE11?"

**Escalation path**: @pm (if priority/scope) or user (if product behavior)
**SLA**: 24 hours for routing to decision-maker

```
# GOOD
@backend: "Should the password reset token expire in 1 hour or 24 hours?"
Scrum-master: "BLOCKER LOGGED: T-023-B1. Type: Decision.
Description: Password reset token TTL undefined.
Routed to user for product decision. Security implications: shorter = more secure but worse UX."
```

### External Blocker

**Identification signal**: A dependency outside the team's control.

**Examples**:
- "The third-party payment API is down"
- "We're waiting for legal approval on the terms of service"
- "The SSL certificate renewal is pending"

**Escalation path**: User with ETA. If ETA uncertain, escalate immediately.
**SLA**: Log with ETA. Escalate to user if ETA > 48 hours or unknown.

## 2.2 Escalation Protocol

### 24-Hour Formal Escalation

When a blocker reaches 24 hours unresolved:

```
## Blocker Escalation — [Blocker ID]

**Blocker**: [description]
**Task ID**: [Task ID]
**Age**: 24 hours
**Type**: [Technical/Resource/Decision/External]
**Originally routed to**: [@agent] at [time]
**Current status**: Unresolved

**Sprint impact**: [N points stalled, N% of Sprint capacity]
**Milestone impact**: [None / specific milestone at risk]

**Requested action**: [specific request to escalation target]
**ETA needed**: [when resolution is needed to save Sprint goal]
```

### 48-Hour User Escalation

When a blocker reaches 48 hours unresolved:

```
## Urgent: Sprint Blocker — [Blocker ID]

**Blocker**: [description]
**Age**: 48 hours
**Sprint impact**: [N points stalled, projected delay]

**This blocker has exceeded the 48-hour resolution window.**
**The Sprint goal is at risk without immediate action.**

**Decision required**: [specific decision or action needed from user]
**Options**:
A. [option with impact]
B. [option with impact]
C. [option with impact]

**Please confirm by [time] to avoid Sprint slip.**
```

### Escalation Routing Decision Tree

```
Blocker identified
    |
    v
Can the agent proceed without resolution today?
    |
    +-- YES → Not a blocker. Note risk, continue.
    |
    +-- NO → Log blocker immediately
        |
        v
    Classify type:
        |
        +-- Technical → @dev-lead (24h SLA)
        |
        +-- Resource → @pm (24h SLA)
        |
        +-- Decision → @pm or user (24h SLA)
        |
        +-- External → user (48h SLA)
        |
        v
    Track in blockers.md
        |
        v
    24h check: resolved?
        |
        +-- YES → Update blockers.md, close blocker
        |
        +-- NO → Formal escalation
            |
            v
        48h check: resolved?
            |
            +-- YES → Update blockers.md, close blocker
            |
            +-- NO → User escalation with risk report
```

## 2.3 Cross-Team Dependency Coordination

### Dependency Mapping

At Sprint planning, map cross-team dependencies:

```
## Sprint 4 Dependency Map

| Consumer | Provider | Dependency | Needed by | Risk |
|----------|----------|------------|-----------|------|
| T-022 (@frontend) | T-019 (@backend) | Error response format | Day 4 | Medium |
| T-024 (@database) | T-021 (@database) | Migration complete | Day 2 | Low |
| T-026 (@backend) | T-025 (@dev-lead) | RBAC scheme | Day 5 | High |
```

### Dependency Coordination Protocol

1. **Identify**: During Sprint planning, ask each agent: "What do you need from another agent to complete your task?"
2. **Document**: Record in dependency map with needed-by date
3. **Monitor**: Check dependency status in every standup
4. **Escalate**: If provider task is at risk of missing needed-by date, escalate to @pm

```
# GOOD
Sprint planning:
Scrum-master: "@frontend, what do you need from @backend for T-022?"
@frontend: "I need the error response format for POST /auth/login."
Scrum-master: "@backend, when will that be ready?"
@backend: "Day 3 of the Sprint."
Scrum-master: "Dependency logged: T-022 needs T-019 error format by Day 3.
@pm notified. If T-019 slips, T-022 is at risk."
```
