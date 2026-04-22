---
name: system-architecture
description: System-level architecture methodology for the Harness team. Covers architectural patterns (monolith/DDD/event-driven), infrastructure decision framework (storage/protocol/reliability), C4 model, ADR writing with reversal conditions, and architecture evolution paths. Loaded by @architect via skills: frontmatter.
type: skill
---

# System Architecture Skill

## 1. Core Disciplines

### YAGNI-First Architecture
Every complexity must earn its place against a concrete current requirement. "We might need this later" is a YAGNI violation.

BAD: "We should use Kafka even though we have 3 engineers and 500 users, because we might need to scale."
GOOD: "We use a job queue backed by PostgreSQL. When write volume causes measurable P99 degradation — instrumented explicitly — we evaluate a dedicated queue at that point."

### Conway's Law Forcing Function
Before recommending any service split, ask: "Which team will own this service?" If the answer is "the same team that owns everything else," the split provides no ownership benefit — it only adds operational complexity.

### Failure Domain Mandate
Every component in an architecture diagram must answer: "What happens to the user when this box fails?" If you cannot answer for every box, the diagram is incomplete.

## 2. Team-Size Architecture Selector

| Team Size | Default | Exception Conditions |
|-----------|---------|---------------------|
| ≤5 | Monolith only | No discussion. Document as ADR-001. |
| 5–15 | Modular Monolith | Independent deploy requirement with different release cadences; radically different SLA per module |
| 15+ | Microservices viable | Must justify each service boundary with Conway's Law team ownership argument |

NEVER recommend microservices for < 8 people.

## 3. Architectural Patterns

### Monolith to Service Spectrum
- **Monolith**: ≤5 engineers, single deployment unit, shared codebase cost < split cost
- **Modular Monolith**: hard module boundaries enforced by package visibility, public API interfaces, prohibited cross-package imports
- **Microservices**: requires independent deploy cadence, demonstrably different SLA, team size ≥ 8 with clear domain ownership

### Domain-Driven Design
- **Bounded Context**: boundary is where ubiquitous language changes
- **Context map patterns**: Partnership, Shared Kernel, Customer-Supplier, Anti-Corruption Layer
- **Aggregate**: transaction boundary; one operation = one aggregate; aggregate root is single entry point for all writes
- **Domain events**: named in past tense (OrderPlaced), carry minimum data, publisher does not know consumers

### Event-Driven Architecture
- **Event-driven vs request-driven**: event-driven when consumer tolerates latency and publisher does not need consumer's result
- **CQRS**: write model optimizes for consistency; read model optimizes for query performance; synchronization cost must be justified
- **Saga pattern**: Choreography (event-chain, no central coordinator, hard to trace) vs Orchestration (central orchestrator, explicit compensation, easier to trace)

## 4. Infrastructure Decision Framework

### Storage Selection
- **RDBMS**: strong consistency, relational queries, ACID transactions; PostgreSQL as default for new projects
- **NoSQL**: MongoDB (document/flexible schema), Redis (cache/session/lock), Cassandra (write-heavy time-series)
- **Read-write separation**: introduce read replica when read:write > 4:1 or P99 degradation demonstrated

### Communication Protocol
- **REST**: external-facing API, standard HTTP semantics
- **GraphQL**: frontend-driven with diverse query shapes from multiple clients
- **gRPC**: internal service-to-service high-throughput
- **Synchronous**: user needs immediate confirmation, result feeds next computation
- **Asynchronous**: background processing acceptable, consumer failure should not fail publisher

### Message Queue Selection
- **Kafka**: high-throughput event log, durable, replay-capable
- **RabbitMQ**: complex routing, lower throughput, per-message acknowledgment
- **Redis Streams**: lightweight, simpler ops, sufficient for < 10k messages/second

### Reliability Architecture
- **Failure domain isolation**: each component's failure mode must be stated
- **Rate limiting**: token bucket for API rate limiting
- **Circuit breaker**: CLOSED → OPEN → HALF-OPEN → CLOSED; fallback for OPEN state defined at design time
- **Distributed transactions**: 2PC (same-infrastructure only), Saga orchestration (cross-service with compensation), eventual consistency (business accepts non-immediate)

## 5. Architecture Governance

### C4 Model
- **L1 Context**: system as single box, users, external dependencies; stakeholder communication
- **L2 Container**: deployable/runnable units, technology choices; @devops uses for deployment topology
- **L3 Component**: modules within container; @dev-lead uses to enforce boundaries
- **L4 Code**: NOT produced by architect

### ADR Format
```
## ADR-NNN: [Title]
**Date**: YYYY-MM-DD | **Status**: Accepted
### Context
[Why needed now. Current state. Driving forces.]
### Decision
[What we chose. One clear declarative sentence.]
### Consequences
**Gained**: [...] | **Accepted cost**: [...] | **Known risks**: [...]
### Reversal Conditions
[Specific quantitative triggers: "When X exceeds Y" or "When team grows beyond N"]
```

NEVER produce an ADR without Reversal Conditions. An ADR without exit conditions is a one-way door.

### Architecture Evolution
- **Evolution stage triggers**: quantitative thresholds that trigger upgrade; thresholds without measurement instrumentation are meaningless
- **Migration paths**: dual-write transition, shadow mode, phased traffic cut-over (5% → 20% → 50% → 100%)
- **Technical debt register**: known shortcuts, interest rate (slowdown per month), projected payoff cost

## 6. Three-Candidate Expansion

For every architectural decision, expand three candidates:
- **Conservative**: fits current team, minimum new infrastructure, fastest to production
- **Mainstream**: standard industry pattern, moderate operational cost, reasonable growth path
- **Progressive**: higher scalability ceiling, higher operational complexity, justified only if conservative cannot handle projected load

For each: state failure domain, Conway's Law fit, evolution trigger, and the one thing that makes this option wrong if assumptions change.

CHOOSE and justify. Do not present all three and ask user to pick.

## 7. Anti-Patterns

**Premature Decomposition**: splitting into services before domain is understood. Result: distributed monolith — all operational complexity, none of the independence.

**Complexity Import**: technology whose operational complexity exceeds the problem it solves at current scale. A product with 200 DAU does not need Kubernetes + Kafka + service mesh.

**Contextless ADR**: states what was decided but not why, no reversal conditions. The value is preserving reasoning, not documenting outcome.

**Bus Factor Blindspot**: designing only for happy path, omitting failure domain analysis. A system designed only for success is a system where failure is a surprise every time.

**YAGNI Violation**: adding complexity justified by imagined future requirements. "Sets us up for the future" is a YAGNI violation.
