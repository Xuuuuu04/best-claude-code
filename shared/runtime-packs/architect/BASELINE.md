# 架构师 — Baseline Scenarios

## Scenario 1: New Product Architecture (Canonical)

**Input**:
- Trigger: Project initialization — greenfield SaaS product
- Team: 4 engineers (2 backend, 1 frontend, 1 fullstack)
- Timeline: MVP in 3 months
- Expected scale: 500 users at launch, 5,000 at 12 months

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Recommended Tier: Modular Monolith (Conway's Law: unified team, no independent deploy requirement)
- ADR-001: Modular Monolith over microservices — reversal condition: team > 8 with distinct domain ownership
- ADR-002: PostgreSQL as sole datastore — reversal condition: write QPS > 2,000/sec sustained for 7 days
- ADR-003: Django signals for cross-module events — reversal condition: fan-out to > 5 consumers or consumer latency > 1s
- Module boundaries: 3 enforced modules with CI lint enforcement on cross-module imports
- Failure domain map: 3 components × 5 columns (failure mode, degraded behavior, recovery path, blast radius)
- Evolution path: Stage 2 at write QPS > 1,000/sec (read replica), Stage 3 at team > 10 (service extraction evaluation)

**Key Decision Points**:
- Rejected microservices without asking user — team of 4 cannot sustain independent service operations
- Rejected Redis/Kafka — no demonstrated bottleneck at 500 users
- Module boundaries enforced in CI, not just documented

---

## Scenario 2: Dev-Lead Escalation — Data Ownership Conflict (Complex)

**Input**:
- @dev-lead escalation: "auth module and billing module are both writing to the users table and we keep getting inconsistent data"
- Current state: modular monolith, 6 engineers, 18 months old codebase
- Evidence provided: 3 production incidents with conflicting user state in the last month

**Expected Output Structure**:
- Status: READY-FOR-NEXT (returned to @dev-lead with ADR)
- Validated escalation: confirmed as data ownership architecture problem (not implementation issue)
- Root cause: data ownership ambiguity — no single writer declared for users table
- ADR-012: User entity ownership → auth/ module is the single writer; billing/ accesses via `UserService.get_billing_context(user_id)`; direct cross-module ORM queries forbidden
- Migration path: dual-write transition (add interface method, migrate billing reads, remove direct ORM access, CI lint enforcement)
- Reversal conditions: if auth/ becomes a bottleneck at > 2,000 auth operations/sec, evaluate read replica on users table

**Key Decision Points**:
- Did NOT recommend splitting auth and billing into services — team is 6 people, data ownership rule solves the problem without service complexity
- Migration path specified with phases, not just "refactor it"
- CI lint rule specified as enforcement mechanism (not just documentation)

---

## Scenario 3: Premature Complexity Request (Blocked/Redirected)

**Input**:
- User request: "We want to add Kafka for our event streaming, because we'll need to scale our notifications"
- Current state: 3 engineers, 200 daily active users, PostgreSQL monolith working fine
- No measured performance issue, no demonstrated bottleneck

**Expected Output Structure**:
- Status: REDIRECTED (not blocked — returned with explanation and alternative)
- Rejected Kafka introduction: no demonstrated bottleneck; team of 3 cannot sustain Kafka cluster operations
- Alternative designed: PostgreSQL-backed job queue (`notifications_queue` table + background worker)
  - Zero new infrastructure
  - Uses existing team knowledge
  - Handles < 10,000 notifications/day at current scale
- Evolution trigger defined: "When notification backlog exceeds 10,000 queued items sustained for 3 days, or when delivery latency P99 > 30 seconds, evaluate Kafka at that point"
- Instrumentation specified: what to measure before trigger can fire
- ADR-007: PostgreSQL job queue over Kafka — reversal condition: quantitative trigger above

**Key Decision Points**:
- Rejected the premise without dismissing the user concern
- Provided a concrete alternative with a specific evolution path
- Named the instrumentation needed before the evolution trigger can fire
