# Domain: C4 Model and ADR Engineering

## 1. C4 Model Diagrams

### 1.1 Context Diagram (Level 1)

**Purpose**: Show the system as a single box, its users, and external dependencies. For stakeholder communication.

```
┌─────────────────────────────────────────────────────────────┐
│                        TaskFlow SaaS                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              [TaskFlow Web Application]                │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
         ▲                           │
         │                           │
    [Team Member]              [Stripe API]
    [Team Admin]               [SendGrid API]
    [Guest Viewer]             [Slack API]
```

**Rules**:
- System is ONE box
- No internal structure shown
- External systems are boxes outside
- Actors are stick figures or labeled boxes
- Data flow arrows show direction

### 1.2 Container Diagram (Level 2)

**Purpose**: Show deployable/runnable units and technology choices. For @devops deployment topology.

```
┌─────────────────────────────────────────────────────────────┐
│                        TaskFlow SaaS                         │
│                                                              │
│  ┌──────────┐      ┌──────────────┐      ┌──────────────┐  │
│  │  [User]  │─────▶│   [Nginx]    │─────▶│ [Django App] │  │
│  └──────────┘      │   (reverse   │      │   (Python)   │  │
│                    │   proxy)     │      └──────┬───────┘  │
│                    └──────────────┘             │          │
│                                                 │          │
│                              ┌──────────────────┘          │
│                              ▼                              │
│                    ┌──────────────────┐                    │
│                    │   [PostgreSQL]   │                    │
│                    │    (primary)     │                    │
│                    └────────┬─────────┘                    │
│                             │                               │
│                    ┌────────▼─────────┐                    │
│                    │   [PostgreSQL]   │                    │
│                    │    (replica)     │                    │
│                    └──────────────────┘                    │
│                                                              │
│                    ┌──────────────────┐                    │
│                    │     [Redis]      │                    │
│                    │   (sessions)     │                    │
│                    └──────────────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

**Rules**:
- Each box is a deployable unit
- Technology labeled in parentheses
- Communication protocols on arrows
- External systems shown at boundaries

### 1.3 Component Diagram (Level 3)

**Purpose**: Show modules within a container. For @dev-lead boundary enforcement.

```
┌─────────────────────────────────────────────────────────────┐
│                    [Django Application]                      │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   auth/     │  │   tasks/    │  │   notifications/    │ │
│  │   module    │  │   module    │  │      module         │ │
│  │             │  │             │  │                     │ │
│  │ • User      │  │ • Task      │  │ • EmailService      │ │
│  │   model     │  │   model     │  │ • WebhookService    │ │
│  │ • Auth      │  │ • Project   │  │ • InAppService      │ │
│  │   service   │  │   model     │  │                     │ │
│  │ • Perm      │  │ • Task      │  │ Publishes:          │ │
│  │   service   │  │   service   │  │ • TaskAssignedEvent │ │
│  │             │  │             │  │ • TaskCompletedEvent│ │
│  │ Owns:       │  │ Owns:       │  │                     │ │
│  │ • users     │  │ • tasks     │  │ Subscribes:         │ │
│  │   table     │  │ • projects  │  │ • UserCreatedEvent  │ │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘ │
│         │                │                     │            │
│         └────────────────┴─────────────────────┘            │
│                          │                                  │
│                    ┌─────▼─────┐                           │
│                    │ [events]  │  ← Django signals          │
│                    │  channel  │                             │
│                    └───────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

**Rules**:
- Modules show ownership (models, services, tables)
- Public interfaces marked
- Events published/subscribed shown
- NO code-level details (classes, methods)

### 1.4 PlantUML C4 Example

```plantuml
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Context.puml

LAYOUT_WITH_LEGEND()

Person(teamMember, "Team Member", "Creates and manages tasks")
Person(teamAdmin, "Team Admin", "Manages team settings and billing")
System(taskflow, "TaskFlow", "Team task management SaaS")
System_Ext(stripe, "Stripe", "Payment processing")
System_Ext(sendgrid, "SendGrid", "Email delivery")

Rel(teamMember, taskflow, "Manages tasks")
Rel(teamAdmin, taskflow, "Manages team")
Rel(taskflow, stripe, "Processes payments")
Rel(taskflow, sendgrid, "Sends emails")

@enduml
```

---

## 2. ADR Writing

### 2.1 ADR Structure

```markdown
## ADR-NNN: [Decision Title]

**Date**: [YYYY-MM-DD]
**Status**: Proposed | Accepted | Deprecated | Superseded by ADR-XXX

### Context
[Why is this decision needed now]
[What is the current state]
[What are the driving forces]
[What options were considered]

### Decision
[What we chose — one clear declarative sentence]

### Consequences
**Gained**:
- [Benefit 1]
- [Benefit 2]

**Accepted cost**:
- [Cost 1]
- [Cost 2]

**Known risks**:
- [Risk 1]
- [Risk 2]

### Reversal Conditions
[Specific quantitative triggers]

### Related Decisions
- [ADR-XXX: related decision]
```

### 2.2 Complete ADR Example

```markdown
## ADR-001: Modular Monolith over Microservices

**Date**: 2024-01-15
**Status**: Accepted

### Context
TaskFlow is a new SaaS product for team task management. Current state:
- Team: 4 engineers (2 backend, 1 frontend, 1 fullstack)
- Timeline: MVP in 3 months
- Expected scale: 500 users at launch, 5,000 at 12 months
- No existing infrastructure

Driving forces:
- Fast time-to-market is critical
- Small team cannot sustain operational complexity
- Domain boundaries are not yet stable

Options considered:
1. Monolith (single codebase, no module boundaries)
2. Modular Monolith (enforced module boundaries, single deploy)
3. Microservices (independent deployable services)

### Decision
We choose Modular Monolith with 3 enforced modules (auth, tasks, notifications).

### Consequences
**Gained**:
- Clear module boundaries for future extraction
- Single deploy simplifies CI/CD
- Team can focus on product, not infrastructure
- Module interfaces can be tested in isolation

**Accepted cost**:
- Cannot independently scale modules
- Cannot independently deploy modules
- Module boundary enforcement requires CI lint rules

**Known risks**:
- Module boundaries may be wrong and require refactoring
- Team may resist boundary enforcement

### Reversal Conditions
- When team grows beyond 8 engineers with distinct domain ownership
- When one module requires independent scaling (measured: CPU > 70% while others < 30%)
- When different modules need different release cadences

### Related Decisions
- ADR-002: PostgreSQL as sole datastore
- ADR-003: Module boundary enforcement in CI
```

### 2.3 ADR Index Template

```markdown
# Architecture Decision Records

| ADR | Title | Status | Date | Reversal Condition |
|-----|-------|--------|------|-------------------|
| 001 | Modular Monolith | Accepted | 2024-01-15 | Team > 8 engineers |
| 002 | PostgreSQL | Accepted | 2024-01-15 | Write QPS > 2,000/s |
| 003 | Django Signals | Accepted | 2024-01-15 | Fan-out > 5 consumers |
| 004 | Redis Cache | Proposed | 2024-03-01 | Read P99 > 200ms |
```

---

## 3. Service Split Decision Matrix

### 3.1 Decision Criteria

| Criterion | Weight | Monolith | Modular Monolith | Microservices |
|-----------|--------|----------|------------------|---------------|
| Team size | High | ✓ ≤5 | ✓ 5-15 | ✓ ≥15 |
| Independent deploy need | High | ✗ | △ | ✓ |
| Different SLA requirements | Medium | ✗ | △ | ✓ |
| Domain boundary stability | High | ✗ | △ | ✓ |
| Operational expertise | High | ✓ | ✓ | ✗ |
| Time to market | Medium | ✓ | ✓ | ✗ |

### 3.2 Service Split Checklist

Before recommending a service split, ALL must be true:
- [ ] Team size ≥ 8 engineers
- [ ] Clear domain ownership (which team owns which service)
- [ ] Independent deploy requirement documented
- [ ] Different SLA or scaling requirements documented
- [ ] Migration path from current architecture defined
- [ ] Operational expertise for service operations confirmed
- [ ] Failure domain analysis for each service completed

### 3.3 Service Split Anti-Patterns

```
# BAD — Split by technical layer
User Service (reads users table)
Order Service (reads orders table)
Payment Service (reads payments table)

# Result: "Show user their order history" = 3 network calls
```

```
# GOOD — Split by business capability
Auth Service (owns authentication, sessions, permissions)
Order Service (owns order lifecycle, inventory reservation)
Payment Service (owns payment processing, refunds)

# Each service has a clear business owner
# Each service can evolve independently
```

---

## 4. Evolution Roadmap

### 4.1 Stage Definition

```
Stage 0: Current State
├── Architecture: [current]
├── Scale: [current metrics]
└── Team: [current size]

Stage 1: Near-term (3-6 months)
├── Trigger: [quantitative condition]
├── Change: [what changes]
├── Effort: [estimated]
└── Dependencies: [what must happen first]

Stage 2: Mid-term (6-12 months)
├── Trigger: [quantitative condition]
├── Change: [what changes]
├── Effort: [estimated]
└── Dependencies: [what must happen first]

Stage 3: Long-term (12-36 months)
├── Trigger: [quantitative condition]
├── Change: [what changes]
├── Effort: [estimated]
└── Dependencies: [what must happen first]
```

### 4.2 Evolution Example

```
## TaskFlow Evolution Roadmap

### Stage 1: Read Replica (Current → 6 months)
**Trigger**: Read QPS > 1,000 sustained for 7 days
**Change**: Add PostgreSQL read replica for reporting queries
**Effort**: 2 weeks
**Dependencies**: @database migration for replica configuration

### Stage 2: Cache Layer (6-12 months)
**Trigger**: API P99 > 200ms for 7 days AND read:write ratio > 4:1
**Change**: Add Redis cache for hot data (user sessions, task lists)
**Effort**: 3 weeks
**Dependencies**: Cache invalidation strategy defined

### Stage 3: Service Extraction (12-24 months)
**Trigger**: Team > 10 engineers with distinct domain ownership
**Change**: Extract notifications service (highest fan-out, lowest coupling)
**Effort**: 6 weeks
**Dependencies**: Event bus (Kafka or RabbitMQ) operational
```

---

## 5. Infrastructure Introduction Assessment

### 5.1 Justification Template

```
## Infrastructure Introduction: [Component Name]

### Problem Statement
[Measured symptom that justifies introduction]

### Current State
[Current solution and its limitations]

### Proposed Solution
[What infrastructure component and why]

### Alternatives Considered
1. [Alternative 1]: [why rejected]
2. [Alternative 2]: [why rejected]

### Operational Cost
- Setup effort: [X weeks]
- Ongoing maintenance: [X hours/week]
- On-call impact: [description]
- Team expertise required: [description]

### Failure Modes
- [Failure 1]: [impact and mitigation]
- [Failure 2]: [impact and mitigation]

### Reversal Conditions
[When this component should be removed or replaced]
```

### 5.2 Infrastructure Decision Examples

| Component | Justified When | Not Justified When |
|-----------|---------------|-------------------|
| Redis Cache | Read P99 > 200ms, read:write > 4:1 | "Might need caching later" |
| Kafka | > 10k messages/sec, multiple consumers | "We might need events" |
| Read Replica | Read QPS > 1,000, DB CPU > 70% | "For reporting" (no scale) |
| CDN | Static assets > 1MB, global users | Single-region MVP |
| Elasticsearch | Full-text search required | SQL LIKE queries sufficient |
