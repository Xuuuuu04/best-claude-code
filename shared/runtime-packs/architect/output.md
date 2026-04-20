# 架构师 — Output Contract

## Standard Output Format

```
## Architecture Design Output: [Project / Feature Name]

**Trigger**: [initialization / cross-module restructuring / architectural mismatch / dev-lead escalation]
**Team Size**: [N engineers, discipline distribution]
**Recommended Tier**: [Monolith / Modular Monolith / Microservices — with one-sentence justification]

### Architecture Decision Summary
[System layering + module boundaries + key infrastructure selections — written as executable constraints for @dev-lead]

### ADR Index
- `docs/architecture/adr/ADR-001-[topic].md`: [decision title]

### C4 Diagram References
- Context (L1): [file path or inline ASCII] — actors + external system dependencies
- Container (L2): [file path or inline ASCII] — deployable units + technology choices
- Component (L3): [file path or inline ASCII if needed] — module breakdown within containers

### Failure Domain Map
| Component | Failure mode | Degraded behavior | Recovery path | Blast radius |
|---|---|---|---|---|

### Evolution Path
| Stage | Trigger condition (quantitative) | Architecture change |
|---|---|---|

### Downstream Constraints
- @dev-lead: [boundary rules — which modules MUST NOT directly call which]
- @database: [data ownership rules — which module is the single writer for each entity]
- @devops: [deployment topology — how many deployable units, their dependencies]

### User Decisions Required
[Explicit decisions that require user input]
```

---

## ADR Format Template

```
## ADR-NNN: [Decision Title]

**Date**: [YYYY-MM-DD]
**Status**: Accepted

### Context
[Why is this decision needed now. What is the current state. What are the driving forces. What options were considered.]

### Decision
[What we chose. One clear declarative sentence.]

### Consequences
**Gained**: [What this gives us]
**Accepted cost**: [What we are giving up or taking on]
**Known risks**: [What could go wrong with this choice]

### Reversal Conditions
[Specific quantitative triggers: "When X exceeds Y" or "When team grows beyond N engineers"]
```

---

## Filled Example: New SaaS Product (Modular Monolith)

```
## Architecture Design Output: TaskFlow — Team Task Management SaaS

**Trigger**: Project initialization
**Team Size**: 4 engineers (2 backend, 1 frontend, 1 fullstack)
**Recommended Tier**: Modular Monolith — Conway's Law: unified team, no independent deploy requirement

### Architecture Decision Summary
- 3 enforced modules: auth/, tasks/, notifications/
- Module boundary rule: no cross-module ORM queries; cross-module access via published interface only
- Communication: synchronous REST within monolith, async events for notifications
- Data ownership: auth owns users, tasks owns tasks/projects, notifications owns notification_log
- Infrastructure: PostgreSQL single instance, Redis for sessions only

### ADR Index
- `docs/architecture/adr/ADR-001-modular-monolith.md`: Modular Monolith over microservices
- `docs/architecture/adr/ADR-002-postgresql.md`: PostgreSQL as sole datastore
- `docs/architecture/adr/ADR-003-django-signals.md`: Django signals for cross-module events

### C4 Diagram References

Context (L1):
```
[User] → [TaskFlow System] → [Stripe]
                ↓
           [SendGrid]
```

Container (L2):
```
[User] → [Nginx] → [Django App] → [PostgreSQL]
                         ↓
                      [Redis]
```

Component (L3):
```
[Django App]
├── auth/ (users, auth, permissions)
├── tasks/ (tasks, projects, assignments)
└── notifications/ (email, in-app, webhooks)
```

### Failure Domain Map
| Component | Failure mode | Degraded behavior | Recovery path | Blast radius |
|---|---|---|---|---|
| PostgreSQL Primary | Disk failure | Reads from replica, writes 503 | Automatic failover (30s) | Write operations only |
| Redis | Memory exhaustion | Session fallthrough to DB | Restart + warm cache | Session performance |
| Django App | Memory leak | LB removes instance | Auto-restart | 1/N capacity |

### Evolution Path
| Stage | Trigger condition | Architecture change |
|---|---|---|
| 1 (current) | — | Modular monolith, single deploy |
| 2 | Write QPS > 1,000 sustained 7 days | Read replica for reporting |
| 3 | Team > 10 engineers | Evaluate service extraction for notifications |

### Downstream Constraints
- @dev-lead: auth/ module MUST NOT query tasks table directly; use TaskService.get_for_user()
- @database: auth is single writer for users; tasks is single writer for tasks; notifications is single writer for notification_log
- @devops: Single container deploy; PostgreSQL primary + replica; Redis optional (session fallback to DB)

### User Decisions Required
- Confirm team size will stay < 10 for next 12 months
- Accept read replica consistency lag for reporting queries
```

---

## Filled Example: Dev-Lead Escalation (Data Ownership)

```
## Architecture Design Output: Auth/Billing Data Ownership Fix

**Trigger**: @dev-lead escalation
**Team Size**: 6 engineers
**Recommended Tier**: Modular Monolith (no service split needed)

### Architecture Decision Summary
- Root cause: data ownership ambiguity — no single writer for users table
- Fix: auth/ module is the single writer for users table
- billing/ module accesses user data via UserService.get_billing_context(user_id)
- Direct cross-module ORM queries forbidden by CI lint rule
- Migration: dual-write transition over 2 sprints

### ADR Index
- `docs/architecture/adr/ADR-012-user-ownership.md`: User entity ownership → auth/ module

### C4 Diagram References
Component (L3) — updated:
```
[Monolith]
├── auth/ (owns users table)
│   └── UserService (public interface)
├── billing/ (reads users via UserService)
│   └── BillingService
└── orders/ (reads users via UserService)
```

### Failure Domain Map
| Component | Failure mode | Degraded behavior | Recovery path | Blast radius |
|---|---|---|---|---|
| UserService | High latency | Billing queries slow | Scale read replicas | Billing module only |

### Evolution Path
| Stage | Trigger condition | Architecture change |
|---|---|---|
| 1 (current) | — | Dual-write transition |
| 2 | auth/ > 2,000 ops/sec | Read replica for users table |

### Downstream Constraints
- @dev-lead: Update billing module to use UserService; remove direct User ORM queries
- @database: No schema change; add index on users.id for UserService lookups
- @devops: No deployment topology change

### User Decisions Required
- Approve 2-sprint migration timeline
- Accept temporary dual-write complexity during transition
```

---

## Output Component Requirements

### Architecture Decision Summary

Must be expressible as executable constraints:
- "Module X MUST NOT directly access Module Y's tables"
- "All cross-module communication MUST go through [protocol]"
- "Module Z is the single writer for [entity]"

### ADR Index

Each ADR must have:
1. **Context**: Why now, current state, driving forces
2. **Decision**: One clear declarative sentence
3. **Consequences**: Gained, accepted cost, known risks
4. **Reversal Conditions**: Quantitative triggers

### C4 Diagrams

**Level 1 — Context**:
- Shows system as single box
- External actors (users, other systems)
- No internal structure

**Level 2 — Container**:
- Shows deployable units (apps, databases, caches)
- Technology choices labeled
- Communication protocols shown

**Level 3 — Component**:
- Shows modules within a container
- Public interfaces marked
- Data ownership indicated

**Level 4 — Code**: NEVER produced by architect. This is implementation detail.

### Failure Domain Map

Required columns:
- **Component**: What can fail
- **Failure mode**: How it fails (disk, network, memory, code)
- **Degraded behavior**: What the user experiences
- **Recovery path**: How the system recovers
- **Blast radius**: What else is affected

### Evolution Path

Required columns:
- **Stage**: Numbered stage
- **Trigger condition**: Quantitative threshold (not "when we grow")
- **Architecture change**: What changes at this stage

### Downstream Constraints

Must specify for each downstream role:
- @dev-lead: Boundary rules and interface contracts
- @database: Data ownership and consistency requirements
- @devops: Deployment topology and infrastructure needs
