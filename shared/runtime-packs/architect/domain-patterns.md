# Domain: Architectural Patterns and Infrastructure Decisions

## 1. Monolith to Service Spectrum

### 1.1 Monolith (≤5 Engineers)

**Characteristics**:
- Single codebase, single deployable
- No module boundaries enforced
- Shared database with all tables
- Fastest time-to-market

**When to choose**:
- Team size ≤ 5
- Single deployment unit acceptable
- No independent scaling requirements
- Domain boundaries not yet understood

**Failure domain**:
```
Any component fails → entire system down
Recovery: restart entire application
Blast radius: 100%
```

### 1.2 Modular Monolith (5-15 Engineers)

**Characteristics**:
- Single codebase, single deployable
- Enforced module boundaries (package/namespace)
- Shared database with schema separation
- Module interfaces tested in isolation

**Enforcement mechanisms**:
```python
# Python: Module boundary enforcement
# auth/ module __init__.py
from .services import AuthService
from .models import User

__all__ = ['AuthService', 'User']
# No direct export of internal repositories

# CI lint rule: no cross-module imports
# "from tasks.models import Task" in auth/ module = ERROR
```

```java
// Java: Package visibility enforcement
// auth module
package com.taskflow.auth;

public class AuthService { /* public interface */ }
class UserRepository { /* package-private, not accessible from tasks */ }
```

**When to choose**:
- Team size 5-15
- Need clear boundaries for future extraction
- No independent deploy requirement yet
- Domain boundaries becoming stable

### 1.3 Microservices (15+ Engineers)

**Characteristics**:
- Multiple codebases, multiple deployables
- Independent deployment and scaling
- Database per service
- Network communication between services

**Justification threshold** (ALL must be true):
- Team size ≥ 15 with distinct domain ownership
- Independent deploy cadence required
- Different SLA requirements per service
- Operational expertise confirmed

**Failure domain**:
```
Service A fails → Service B may degrade gracefully
Recovery: restart only Service A
Blast radius: Service A consumers only
```

---

## 2. Domain-Driven Design Patterns

### 2.1 Bounded Context Identification

**Identification criteria**:
- Ubiquitous language changes
- Different domain experts
- Independent evolution potential
- Different consistency requirements

**Context map patterns**:

| Pattern | Relationship | When to use |
|---------|-------------|-------------|
| Partnership | Mutual dependency | Two teams, closely aligned goals |
| Shared Kernel | Shared model subset | Common vocabulary, rare changes |
| Customer-Supplier | Upstream/downstream | Clear dependency direction |
| Anti-Corruption Layer | Translation layer | Legacy system integration |
| Open Host Service | Published language | Multiple consumers |

### 2.2 Aggregate Design

**Rules**:
- One transaction = one aggregate
- Aggregate root is the single entry point
- References to other aggregates by ID only

```python
# BAD — Cross-aggregate reference
class Order:
    def __init__(self):
        self.items = []  # Value objects OK
        self.customer = Customer()  # WRONG: direct reference

# GOOD — Reference by ID
class Order:
    def __init__(self):
        self.items = []  # Value objects
        self.customer_id = None  # Reference by ID
```

### 2.3 Domain Event Design

**Naming convention**: Past tense, not imperative
```
BAD:  PlaceOrder, SendEmail, UpdateInventory
GOOD: OrderPlaced, EmailSent, InventoryUpdated
```

**Event structure**:
```json
{
  "event_id": "uuid",
  "event_type": "OrderPlaced",
  "aggregate_id": "order-123",
  "aggregate_type": "Order",
  "timestamp": "2024-01-15T10:30:00Z",
  "payload": {
    "order_id": "order-123",
    "customer_id": "cust-456",
    "total": 99.99,
    "currency": "USD"
  }
}
```

**Event sourcing considerations**:
- Event store is the source of truth
- Current state = fold(all events)
- Snapshot for performance
- NOT for: simple CRUD, small domains, teams without event sourcing experience

---

## 3. Event-Driven Architecture

### 3.1 Event-Driven vs Request-Driven

| Aspect | Request-Driven | Event-Driven |
|--------|---------------|--------------|
| Coupling | Tight (caller knows callee) | Loose (publisher doesn't know consumers) |
| Latency | Immediate | Potentially delayed |
| Failure handling | Caller handles | Consumer handles independently |
| Use case | User needs immediate result | Background processing acceptable |

### 3.2 CQRS (Command Query Responsibility Segregation)

**When justified**:
- Read and write patterns are fundamentally different
- Read model requires denormalization
- Write model requires complex validation
- Team has operational expertise for dual models

**When NOT justified**:
- Simple CRUD operations
- Read:write ratio < 4:1
- No performance issues with unified model
- Team lacks operational expertise

```
[Command] → [Write Model] → [Event Bus] → [Read Model] → [Query]
     ↑            ↓                              ↓
  [Client]    [Event Store]                  [Cache]
```

### 3.3 Saga Pattern

**Choreography Saga**:
```
[Order Service] ──OrderPlaced──▶ [Payment Service]
                                     │
                                     ▼
[Inventory Service] ◀──PaymentProcessed──
     │
     ▼
[Shipping Service] ◀──InventoryReserved──
```

**Orchestration Saga**:
```
                    ┌─────────────────┐
                    │   [Orchestrator] │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
[Order Service]      [Payment Service]    [Inventory Service]
        │                    │                    │
        └────────────────────┴────────────────────┘
                             │
                             ▼
                    [Shipping Service]
```

**Compensation design**:
```python
# Every forward step needs a compensating step
class OrderSaga:
    def create_order(self, order_data):
        # Forward step
        order = self.order_service.create(order_data)
        
        try:
            # Forward step
            payment = self.payment_service.charge(order)
        except PaymentError:
            # Compensation
            self.order_service.cancel(order.id)
            raise
        
        try:
            # Forward step
            self.inventory_service.reserve(order.items)
        except InventoryError:
            # Compensation
            self.payment_service.refund(payment.id)
            self.order_service.cancel(order.id)
            raise
```

---

## 4. Infrastructure Decision Framework

### 4.1 Storage Selection Matrix

| Requirement | Primary Choice | When to Consider Alternative |
|-------------|---------------|------------------------------|
| Strong consistency, relational | PostgreSQL | MySQL (existing expertise) |
| Document model, flexible schema | MongoDB | PostgreSQL JSONB (if team knows SQL) |
| Hot data cache | Redis | Memcached (simpler, no persistence) |
| Time-series data | TimescaleDB | InfluxDB (if already using TICK stack) |
| Full-text search | PostgreSQL tsvector | Elasticsearch (if complex search) |
| Graph relationships | PostgreSQL | Neo4j (if deep graph queries) |

### 4.2 Communication Protocol Selection

| Scenario | Protocol | Rationale |
|----------|----------|-----------|
| External API | REST | Standard HTTP semantics, caching, tooling |
| Frontend-driven queries | GraphQL | Multiple clients, diverse query shapes |
| Internal service-to-service | gRPC | Performance, type safety, streaming |
| Real-time updates | WebSocket | Bidirectional, low latency |
| Event streaming | Kafka | Durability, replay, high throughput |
| Task queue | RabbitMQ | Complex routing, per-message ack |
| Lightweight events | Redis Streams | Simple ops, < 10k msg/sec |

### 4.3 Reliability Patterns

**Circuit Breaker States**:
```
CLOSED: Normal operation, requests pass through
  ↓ (failure rate > threshold)
OPEN: Requests fail immediately, no external calls
  ↓ (timeout expires)
HALF-OPEN: Single probe request allowed
  ↓ (probe succeeds)
CLOSED: Return to normal
  ↓ (probe fails)
OPEN: Remain open
```

**Rate Limiting**:
```python
# Token bucket algorithm
class TokenBucket:
    def __init__(self, capacity, refill_rate):
        self.capacity = capacity
        self.tokens = capacity
        self.refill_rate = refill_rate
        self.last_refill = time.time()
    
    def allow_request(self):
        self._refill()
        if self.tokens >= 1:
            self.tokens -= 1
            return True
        return False
    
    def _refill(self):
        now = time.time()
        elapsed = now - self.last_refill
        self.tokens = min(
            self.capacity,
            self.tokens + elapsed * self.refill_rate
        )
        self.last_refill = now
```

---

## 5. Migration Path Design

### 5.1 Dual-Write Transition

```
Phase 1: Write to old system, read from old system
Phase 2: Write to BOTH systems, read from old system
Phase 3: Write to BOTH systems, read from new system (with fallback)
Phase 4: Write to new system, read from new system
Phase 5: Remove old system
```

### 5.2 Shadow Mode

```
[Production Traffic] ──▶ [Old System] ──▶ [Response to User]
              │
              └────────▶ [New System] ──▶ [Compare with Old]
                           ↓
                        [Metrics]
```

### 5.3 Phased Traffic Cut-over

```
Week 1: 5% traffic to new system
Week 2: 20% traffic to new system
Week 3: 50% traffic to new system
Week 4: 100% traffic to new system
Week 5: Monitor, then remove old system
```

**Rollback criteria**:
- Error rate > 0.1%
- P99 latency > 2× baseline
- Any data inconsistency detected
