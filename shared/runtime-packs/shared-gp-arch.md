# Shared GP-ARCH — Architecture Invariants (GP-A01–A07)

**Source**: Extracted from `shared/guides/harness-orchestrator-longform.md §11.3`
**Applies to**: 架构师 (primary), 开发组长 (scheme layer), @code-review (detection)
**Enforcement**: @code-review detects GP-A* violations and escalates to @architect when
                 the root cause is architectural, not implementer-layer.

---

## GP-A01–A07: Architecture Invariants

```
GP-A01: [MANUAL] Data flow must be traceable: input → validation → processing →
                  output, with clear responsibility at each stage.

GP-A02: [MANUAL] Dependency injection > hardcoding. Composition > inheritance.

GP-A03: [MANUAL] Modules communicate through interfaces, not direct internal access.

GP-A04: [MANUAL] Every external call MUST handle: timeout + retry (exponential
                  backoff) + circuit breaker (where justified by consequence of
                  failure).

GP-A05: [MANUAL] Pure functions > functions with side effects. Side effects are
                  concentrated at the system boundary, not distributed through logic.

GP-A06: [MANUAL] Over-engineering test: "if I remove this abstraction layer, does
                  the code remain correct and maintainable?" If yes — remove it.
                  Complexity must earn its place against a current requirement.

GP-A07: [MANUAL] Prefer proven, composable technology with stable APIs and strong
                  representation in LLM training data. Novel technology choices
                  require explicit justification of what known technology cannot
                  provide.
```

---

## All GP-A* Rules Are MANUAL

Architecture violations cannot be auto-detected. They require agent or human judgment
about system-level design properties. This is why @architect is an opus-tier agent:
architecture decisions have compounding consequences if wrong.

---

## GP-A Enforcement Protocol

### @architect (架构师) — Primary Owner
Responsible for establishing and enforcing GP-A* across ADRs and technical design.
Any architectural decision that violates GP-A01–A07 requires an explicit justification
in the ADR before it can proceed.

### @dev-lead (开发组长) — Scheme Layer
Responsible for translating architecture decisions into file-level schemes that
comply with GP-A* rules. When a scheme proposal would violate GP-A*, route to
@architect before proceeding.

### @code-review (代码审计师) — Detection Layer
Code review may detect symptoms of GP-A* violations in implementation diffs:
- Direct module-to-module internal access (GP-A03 symptom)
- External calls without timeout configuration (GP-A04 symptom)
- Business logic with distributed side effects (GP-A05 symptom)
- Unnecessary abstraction layers (GP-A06 symptom)

When @code-review detects a GP-A* symptom, the finding should note: "This may
indicate a GP-A* architecture violation. Route to @architect for evaluation."

---

## Decision Guides

### GP-A02: DI vs. Hardcoding
```
BAD:  class UserService:
          db = MySQLConnection("localhost:3306")  # hardcoded
          
GOOD: class UserService:
          def __init__(self, db: DatabaseConnection):
              self.db = db  # injected
```

Composition over inheritance means:
```
BAD:  class UserEmailService(EmailService):  # inherits for reuse
GOOD: class UserEmailService:
          def __init__(self, email_service: EmailService):  # composes
```

### GP-A04: Resilient External Call Pattern
Every external call should have:
1. **Timeout**: configured, not default or infinite
2. **Retry**: exponential backoff with jitter, max 3 retries
3. **Circuit breaker**: for dependencies where failure rate matters
   (not every call needs a circuit breaker — justify by consequence)

```python
# Minimum pattern (Python)
try:
    response = requests.get(url, timeout=(3, 10))  # (connect, read)
    response.raise_for_status()
except requests.Timeout:
    raise ServiceTimeoutError(f"Dependency {service_name} timed out")
except requests.RequestException as e:
    raise ServiceUnavailableError(f"Dependency {service_name} failed: {e}")
```

### GP-A06: Over-Engineering Test
Ask: "If I remove this abstraction layer, does the code remain correct?"

If yes, and there is no current requirement that creates the need for the
abstraction, remove it. Speculative abstractions create maintenance cost without
current benefit.

YAGNI: You Aren't Gonna Need It. The abstraction layer earns its presence by
solving a current problem that cannot be solved without it.

### GP-A07: Technology Selection Justification
When proposing a new technology:
1. State what known technology cannot provide
2. State the maturity and community support level
3. State the LLM training data representation (affects generated code quality)
4. State the rollback path if the technology proves inadequate

Novelty alone is not a justification. A well-known technology with documented
limitations beats an unknown technology with unknown limitations.

---

## Relationship to Other GP Groups

| GP Group | Layer | Who Enforces |
|---|---|---|
| GP-C* | Code quality | @code-review (per diff) |
| GP-S* | Security baseline | @code-review (per diff) + @security-auditor (milestone) |
| GP-A* | Architecture | @architect (design) + @dev-lead (scheme) + @code-review (detection) |
| GP-O* | Orchestration | Main process (self-enforcement) + Hook-E (GP-O01) |
