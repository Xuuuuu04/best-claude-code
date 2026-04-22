---
name: code-quality-review
description: Per-diff code quality and security baseline review methodology for the Harness team. Covers three-layer comparison (requirement/scheme/implementation), adversarial reading, security baseline scan (SQLi/XSS/secrets/validation/logging), data consistency, error handling, performance baseline, and LLM hallucination detection. Loaded by @code-review via skills: frontmatter.
type: skill
---

# Code Quality Review Skill

## 1. Three-Layer Comparison

**Layer 1 — Requirement alignment**: Does the code implement the business intent exactly? Common failures: wrong user role, wrong behavior, partial feature.

**Layer 2 — Scheme alignment**: Compare scheme's In-scope file list against actual changed files; compare every field name, type, required/optional, validation rule, HTTP status code, error code. One deviation is a finding. Files changed but not in scheme → unauthorized scope expansion.

**Layer 3 — Implementation quality**: Data flow correctness, error path coverage, concurrency safety, performance (N+1 queries, long transactions), maintainability (function length, nesting depth, naming, DRY).

Complete each layer before moving to the next. Do not interleave.

## 2. Security Baseline Scan (Mandatory Every Review)

Five checks run on every review, every round, no exceptions:

| Check | Pattern | Severity if found |
|---|---|---|
| SQL injection | String concatenation into SQL, f-string interpolation, `%` formatting in DB calls, ORM escape bypass | CRITICAL |
| XSS | `innerHTML = value`, `dangerouslySetInnerHTML`, `v-html` without DOMPurify, `document.write()` with user input | HIGH |
| Hardcoded secrets | `(password\|secret\|api_key\|token\|private_key)\s*=\s*['"]`, `sk_live_`, `ghp_` | CRITICAL |
| Input validation | User-controlled input reaches business logic without type/length/format validation | HIGH |
| Sensitive logging | Log lines include password, token, secret, auth header values | HIGH |

## 3. Adversarial Reading

Read code as an attacker:
- **Null/empty/boundary**: null input, empty string, integer 0, negative, 10MB string, Unicode with emoji, SQL special characters
- **Concurrency simulation**: two simultaneous requests for any write; SELECT-then-UPDATE without lock = race condition
- **Dependency failure**: what happens when DB/cache/API/file system fails, times out, or returns unexpected format?

## 4. LLM Hallucination Detection

LLM-generated code may call API methods that don't exist. Protocol:
1. For every external library method: does it exist in the installed version?
2. Grep the dependency lock file for version. Grep existing codebase for usage patterns.
3. If unverifiable → tag `[HALLUCINATION-RISK]` and recommend human verification.

## 5. Data Consistency Review

- **Transaction boundaries**: multi-table writes in single request — inside a transaction? Isolation level appropriate?
- **Race conditions**: SELECT-then-UPDATE without lock; application-level counter increments; test-and-set without atomic operation
- **Idempotency**: webhook processing, async jobs, user submit buttons — deduplication mechanism present?
- **Cache-database consistency**: cache invalidation on writes, stale read scenarios

## 6. Error Handling Quality

- **Ghost failures**: `except Exception: pass`, `catch (e) {}` — every caught exception must be re-raised, logged, or explicitly documented as intentionally swallowed
- **External call resilience**: HTTP calls without timeout; retry on non-idempotent operations; missing circuit breaker
- **Error hygiene**: stack traces, internal paths, SQL errors, connection strings must not leak in production responses

## 7. Performance Baseline

- **N+1 query detection**: loop triggering N queries where one would suffice
- **Long transactions**: holding locks during external API calls
- **Synchronous blocking**: operations that should be async

## 8. Severity Classification

| Severity | Definition | Examples |
|---|---|---|
| **CRITICAL** | Unconditional block | SQL injection, XSS vector, hardcoded secret, auth bypass, data loss risk |
| **HIGH** | Strong block | Missing input validation on external data, sensitive data in logs, IDOR, broken error handling on critical paths, scheme contract violation on core fields |
| **MEDIUM** | Fix required before APPROVED | N+1 queries, transaction boundary issues, non-critical scheme deviations, maintainability issues |
| **LOW** | Advisory | Minor style issues, optional improvements, documentation gaps |
| **HALLUCINATION-RISK** | Flag for human verification | Unverifiable API method call |

## 9. Verdict Protocol

- **APPROVED**: all dimensions verified, no CRITICAL or HIGH. Must state which dimensions were checked.
- **CHANGES REQUESTED**: CRITICAL or HIGH findings present. Must list each finding with file:line + snippet + explanation + fix direction.
- **ESCALATE to @security-auditor**: authN/authZ design flaw, suspected taint flow, multiple related security findings suggesting systemic issue.
- **Route to @dev-lead**: root cause is in the scheme, not the implementation.

## 10. Anti-Patterns

| Name | Symptom | Correction |
|---|---|---|
| **Nit-Picking Blockade** | Blocking on style preferences while missing real issues | Style auto-fixable by linter = LOW at most |
| **Hallucination Blind Spot** | Accepting LLM API calls without verification | Grep lock file + codebase; tag `[HALLUCINATION-RISK]` if uncertain |
| **Green-Stamp Review** | APPROVED without checking security baseline or scheme alignment | APPROVED requires rationale with verified dimensions |
| **Iteration Sympathy** | Lowering threshold in later rounds | Round N gets Round 1 standards |
| **Root Cause Misattribution** | Requiring implementer to fix scheme-layer problems | Route to @dev-lead for scheme revision |
