# Shared GP-CODE — Code Invariants (GP-C01–C10)

**Source**: Extracted from `shared/guides/harness-orchestrator-longform.md §11.1`
**Applies to**: 代码审计师, all implementation agents, main process quality gate enforcement
**Enforcement**: 代码审计师 catches GP-C* violations; violation is a CHANGES REQUESTED finding

---

## GP-C01–C10: Code Invariants

```
GP-C01: [AUTO]   Functions ≤ 50 lines. Exceeding this threshold requires
                  splitting. Flag as ISSUE, do not silently accept.

GP-C02: [AUTO]   Nesting ≤ 4 levels. Use early return / guard clause to reduce
                  nesting. Deep nesting is a readability failure.

GP-C03: [MANUAL] Magic numbers and strings MUST be extracted to named constants
                  or configuration files. Inline literals are a maintenance trap.

GP-C04: [AUTO]   All public functions and classes MUST have docstrings.
                  Undocumented public API is a contract that exists only in the
                  author's head.

GP-C05: [AUTO]   In languages with type systems, type annotation coverage = 100%.
                  Unannotated code is a hidden type bug waiting to surface at runtime.

GP-C06: [AUTO]   Every catch/except block MUST do one of: re-raise, log with
                  structured context, or return a structured error response.
                  Empty catch = CRITICAL — code-review one-vote block.
                  (Ghost Failure anti-pattern)

GP-C07: [MANUAL] Naming must be self-explanatory. A variable name that requires
                  a comment to understand is a naming failure, not a comment
                  opportunity.

GP-C08: [AUTO]   Imports grouped: standard library → third-party → local.
                  Groups separated by blank lines.

GP-C09: [AUTO]   No unexplained TODO/FIXME. Every TODO must contain: reason +
                  owner + estimated resolution date.

GP-C10: [MANUAL] Dependency direction is one-way. Inner layers MUST NOT import
                  outer layers. Circular imports are a structural defect.
```

---

## Marker Legend

- `[AUTO]` — detectable by automated tooling (linter, semgrep, grep). Should be
  integrated into pre-commit hooks for automatic blocking at the tool layer,
  not at the review layer.
- `[MANUAL]` — requires agent or human judgment.

---

## Enforcement Protocol for @code-review

For each GP-C* rule, the severity of a violation is:

| Violation | Severity |
|---|---|
| GP-C06 empty catch (Ghost Failure) | CRITICAL — one-vote block |
| GP-C01 function > 50 lines (≤ 100 lines) | MEDIUM |
| GP-C01 function > 100 lines | HIGH |
| GP-C02 nesting > 4 levels | HIGH |
| GP-C05 missing type annotations | HIGH (in typed languages) |
| GP-C03 magic literals | MEDIUM |
| GP-C04 missing docstrings (public API) | MEDIUM |
| GP-C09 unexplained TODO/FIXME | LOW |
| GP-C10 circular import | HIGH |
| GP-C07 unclear naming | LOW–MEDIUM depending on context |
| GP-C08 import grouping | LOW |

---

## Quick Reference — Language-Specific Checks

**Python**:
- `except Exception: pass` → GP-C06 CRITICAL
- `def function(x, y):` with no type hints → GP-C05 HIGH
- `result = x * 86400` (magic 86400) → GP-C03 MEDIUM
- Function ending at line 80+ from def → GP-C01 check

**TypeScript/JavaScript**:
- `catch (e) {}` → GP-C06 CRITICAL
- Function with `any` return type → GP-C05 HIGH
- `const timeout = 30000` without named constant → GP-C03 MEDIUM

**Go**:
- `if err != nil { _ = err }` → GP-C06 CRITICAL
- Unexported function with no comment → GP-C04 MEDIUM (exported = HIGH)

**Java**:
- `catch (Exception ignored) {}` → GP-C06 CRITICAL
- Raw type usage (e.g., `List` instead of `List<String>`) → GP-C05 HIGH
