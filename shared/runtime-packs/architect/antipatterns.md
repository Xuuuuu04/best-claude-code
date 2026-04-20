> Source: core.md §Anti-Patterns + §Rules (Primacy Anchor)

# 架构师 — Anti-Patterns

## Named Anti-Patterns

---

### Premature Decomposition

**Definition**: Splitting a system into services before the domain is understood well enough to define stable service boundaries.

**Manifestations**:
```
# BAD — 3 months into product, team of 4, 500 users
"Let's split into User Service, Order Service, Payment Service, Notification Service."

# Result 6 months later:
- Feature "apply discount code" touches 3 services
- "Show user their orders" fans out into 4 network calls
- Local development requires running 5 services
- A simple bug fix requires coordinated deploys across 3 repos
```

```
# GOOD — same team, modular monolith approach
"Start with 4 modules in a single deployable:
- auth/ module (owns users table)
- orders/ module (owns orders table)
- payments/ module (owns transactions table)
- notifications/ module (owns notification_log table)

Module boundaries enforced by:
- Package visibility rules
- No cross-module ORM queries
- Public interface: NotificationService.send(event)

Extract as service only when:
- Team grows to 8+ engineers
- A module has independent deploy requirements
- A module needs different SLA from others"
```

**Why it's dangerous**: Microservices require stable domain boundaries. You cannot define stable domain boundaries before you understand the domain. The result is a **distributed monolith** — all the operational complexity of microservices, none of the independence.

**Correction**: Start with a Modular Monolith. Extract one service at a time along a boundary that has already proven stable in the monolith. Each extraction must be justified by Conway's Law team ownership.

---

### Complexity Import

**Definition**: Introducing a technology whose operational complexity exceeds the problem it solves at the current scale.

**Manifestations**:
```
# BAD — 200 DAU, 3 engineers
"We need Kubernetes for orchestration, Kafka for events,
Redis Cluster for cache, and a service mesh for observability."

# Operational reality:
- 60% of engineering time spent on infrastructure maintenance
- On-call rotation is 1 in 3 — every engineer is on-call weekly
- First Kafka partition rebalance incident takes 4 hours to resolve
- Nobody fully understands the service mesh configuration
```

```
# GOOD — same constraints
"Current stack: PostgreSQL monolith + background worker.

Measured symptoms:
- API P99: 180ms (target: < 200ms) ✓
- Background job queue: < 100 items average ✓
- Database CPU: 15% average ✓

Decision: No new infrastructure.
Monitoring: Track API P99, queue depth, DB CPU.
Trigger for re-evaluation: API P99 > 500ms for 7 days
  OR queue depth > 10,000 sustained for 3 days."
```

**Why it's dangerous**: Every infrastructure component requires operational expertise, has failure modes, needs monitoring, and consumes on-call attention. Complexity imported before it is needed is complexity that must be maintained without providing value.

**Correction**: "What is the measured symptom that this solves, and what is the simplest intervention that addresses that symptom?" If the answer is "we might need it later," that is a YAGNI violation.

---

### Contextless ADR

**Definition**: An architecture decision record that states what was decided but not why, and provides no reversal conditions.

**Manifestations**:
```markdown
<!-- BAD — Contextless ADR -->
## ADR-003: Database Selection

**Status**: Accepted

### Decision
We use MongoDB.

### Consequences
- Flexible schema
- Horizontal scaling
```

```markdown
<!-- GOOD — Complete ADR -->
## ADR-003: Database Selection

**Date**: 2024-01-15
**Status**: Accepted

### Context
The product is a content management system where:
- Content types are user-defined and change frequently
- Relationships are primarily tree-shaped (parent-child)
- Query patterns are document-centric (fetch page with all blocks)
- Current scale: 1,000 documents, 50 concurrent users
- Team: 3 backend engineers, no DBA

Options considered:
1. PostgreSQL with JSONB columns
2. MongoDB
3. DynamoDB (AWS-specific, rejected due to vendor lock-in concern)

### Decision
We use MongoDB.

### Consequences
**Gained**:
- Schema flexibility for user-defined content types
- Native tree query support ($graphLookup)
- Team familiarity (2 of 3 engineers have production MongoDB experience)

**Accepted cost**:
- No ACID transactions across collections
- Eventual consistency for cross-collection references
- Operational complexity: replica set management, backup strategy

**Known risks**:
- Data corruption risk if writes are not carefully ordered
- Query performance degradation if indexes are not maintained

### Reversal Conditions
- When cross-collection transaction requirements emerge
- When document count exceeds 1,000,000 and query P99 > 500ms
- When team hires a DBA and PostgreSQL JSONB becomes viable
```

**Why it's dangerous**: The value of an ADR is not documenting the outcome — it is preserving the reasoning. Without context and reversal conditions, the ADR cannot be challenged or evolved intelligently. Future engineers read it and think "MongoDB was chosen because... someone chose it?"

**Correction**: Every ADR must answer: what were the options considered, what drove the choice, what are we accepting as a cost, and under what specific conditions should this decision be revisited.

---

### Bus Factor Blindspot

**Definition**: Designing only for the operational steady state and omitting failure domain analysis.

**Manifestations**:
```
# BAD — Architecture diagram with no failure analysis
[User] → [Load Balancer] → [API Server] → [Database]
                                     ↓
                                  [Cache]

# First production incident:
# "Why is the site down? The database is fine."
# "Oh, the cache failed and the API servers are all crashing
#    because they can't handle the database load directly."
```

```
# GOOD — Same diagram with failure annotations
[User] → [Load Balancer] → [API Server] → [Database Primary]
                                     ↓        ↓ [Read Replica]
                                  [Cache]   [Read Replica]

Failure annotations:
- API Server instance fails:
  → LB removes from pool (10s health check)
  → In-flight requests fail, clients retry
  → Blast radius: 1/N of capacity

- Database Primary fails:
  → Automatic failover to replica (30s RTO)
  → Writes queue for 30s then 503
  → Reads continue from replica (replication lag < 1s)
  → Blast radius: write operations only

- Cache fails:
  → Fallthrough to database (10× read load)
  → API servers throttle to prevent DB overload
  → Degraded mode: slower responses, no cache
  → Blast radius: read performance only
```

**Why it's dangerous**: Failure modes do not appear in diagrams unless you put them there intentionally. A system designed only for success is a system where failure is a surprise every time.

**Correction**: For every component, write: "(a) what user operations are affected, (b) what is the degraded mode, (c) what is the recovery path, and (d) what is the blast radius."

---

### YAGNI Violation

**Definition**: Adding architectural complexity justified by imagined future requirements rather than demonstrated current needs.

**Manifestations**:
```
# BAD — Current: 150 users, 3 engineers
"We should use CQRS because when we scale we'll need
 separate read and write models."

# Reality 12 months later:
- Product pivoted from B2C to B2B
- The "read model" was never needed
- CQRS complexity slowed every feature delivery
- Team spent 3 months removing CQRS to simplify
```

```
# GOOD — same starting point
"Current architecture: standard MVC with PostgreSQL.

Measured need for CQRS:
- Read:write ratio: 3:1 (not high enough)
- Read query P99: 45ms (well within SLA)
- No complex reporting requirements

Decision: No CQRS.
Monitoring: Track read:write ratio, read P99.
Trigger for re-evaluation: read:write ratio > 10:1
  AND read P99 > 200ms for 7 days."
```

**Why it's dangerous**: YAGNI violations are debt issued against requirements that may never materialize. If the product pivots, the entire complexity investment is stranded. The team pays the operational cost of the complexity without receiving the benefit.

**Correction**: "What specific, measured problem does this solve today?" If the answer is "it sets us up for the future," that is a YAGNI violation. Future-proofing is a myth — the future is never what you expect.
