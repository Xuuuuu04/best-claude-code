# Shared GP-SECURITY — Security Invariants (GP-S01–S13)

**Source**: Extracted from `shared/guides/harness-orchestrator-longform.md §11.2`
**Applies to**: 安全审计师 (deep audit), 代码审计师 (baseline), all implementation agents (self-check)
**Mode**: GP-S* rules are mode-invariant — they apply in poc mode, debug mode, and prototypes.
          "It's just a demo" does not grant a GP-S* exemption.

---

## GP-S01–S13: Security Invariants (CWE-Aligned)

```
GP-S01: [AUTO]   SQL MUST be parameterized. String-concatenated SQL = CRITICAL.
                  (CWE-89 — SQL Injection)

GP-S02: [AUTO]   Command execution MUST use parameterized API (e.g., subprocess
                  list form). shell=True or equivalent = CRITICAL. (CWE-78)

GP-S03: [MANUAL] Template rendering MUST use auto-escaping. Disabling escaping
                  requires explicit DispatchPlan registration. (CWE-79)

GP-S04: [MANUAL] Password storage: bcrypt / scrypt / argon2.
                  MD5 or SHA1 for passwords = CRITICAL. (CWE-916)

GP-S05: [AUTO]   Credentials = environment variables / secrets manager.
                  Hardcoded (password|secret|token|key) in source = CRITICAL.
                  (CWE-798)

GP-S06: [MANUAL] All external input MUST be validated: type + length + range +
                  format. Whitelist > blacklist for enum values. (CWE-20)

GP-S07: [MANUAL] File uploads: validate MIME type + size + extension.
                  File path MUST NOT be user-controlled. (CWE-434)

GP-S08: [AUTO]   Logs MUST NOT contain: password | token | secret | credit_card.
                  (CWE-532)

GP-S09: [MANUAL] Encryption: AES-256-GCM / RSA-2048+ / ECDSA P-256+.
                  Homegrown encryption = CRITICAL. (CWE-327)

GP-S10: [MANUAL] JWT: MUST verify signature + exp + iss/aud claims. (CWE-287)

GP-S11: [AUTO]   Resources (file handles / connections / locks) MUST use
                  try-with-resources / context manager / defer. (CWE-401)

GP-S12: [AUTO]   Deserialization of untrusted data requires a safe library +
                  type allowlist. (CWE-502)

GP-S13: [MANUAL] User input MUST NOT be directly concatenated into system prompts
                  or tool descriptions. Structured separation or explicit escaping
                  is mandatory. Direct concatenation = CRITICAL.
                  (CWE-79 variant — Prompt Injection)
```

---

## Severity Classification

| GP-S* | CWE | Per-Diff Severity | Deep Audit Scope |
|---|---|---|---|
| GP-S01 SQL Injection | CWE-89 | CRITICAL | @code-review catches per diff; @security-auditor traces full taint flow |
| GP-S02 Command Injection | CWE-78 | CRITICAL | both |
| GP-S03 XSS via template | CWE-79 | HIGH | @code-review catches per diff |
| GP-S04 Weak password hash | CWE-916 | CRITICAL | @security-auditor (auth deep-dive) |
| GP-S05 Hardcoded creds | CWE-798 | CRITICAL | both; git history scan required |
| GP-S06 Input validation | CWE-20 | HIGH | @code-review per endpoint |
| GP-S07 File upload | CWE-434 | HIGH | both |
| GP-S08 Sensitive logging | CWE-532 | HIGH | both |
| GP-S09 Homegrown crypto | CWE-327 | CRITICAL | @security-auditor |
| GP-S10 JWT bypass | CWE-287 | HIGH→CRITICAL | @security-auditor (auth deep-dive) |
| GP-S11 Resource leak | CWE-401 | MEDIUM | @code-review |
| GP-S12 Unsafe deserialization | CWE-502 | HIGH | @security-auditor |
| GP-S13 Prompt injection | CWE-79v | CRITICAL (AI systems) | @security-auditor + @code-review |

---

## Per-Agent Responsibility Split

### @code-review (代码审计师) — Per-Diff Baseline
Responsible for catching GP-S01, GP-S02, GP-S03, GP-S05, GP-S06, GP-S08 on
every code diff. These are the "surface scan" items that should be caught before
a milestone security audit.

Mandatory per-diff security baseline:
1. SQL parameterization (GP-S01)
2. XSS injection vectors (GP-S03)
3. Hardcoded secrets grep (GP-S05)
4. Input validation coverage (GP-S06)
5. Sensitive logging check (GP-S08)

### @security-auditor (安全审计师) — Milestone Deep Audit
Responsible for full coverage of GP-S01–S13 at milestone boundaries.
Deep audit includes: STRIDE threat modeling, full taint flow analysis,
dependency CVE scanning, git history secret scan, auth design review.

### Implementation Agents (self-check before handoff)
Must verify GP-S01, GP-S04, GP-S05, GP-S06, GP-S08 during self-test.
Any GP-S* violation discovered during self-test blocks handoff to @code-review.

---

## Language-Specific GP-S Patterns

**Python**:
- `cursor.execute(f"SELECT ... {user_input}")` → GP-S01 CRITICAL
- `os.system(f"cmd {user_input}")` → GP-S02 CRITICAL
- `hashlib.md5(password.encode())` → GP-S04 CRITICAL
- `SECRET_KEY = "abc123"` in source → GP-S05 CRITICAL
- `pickle.loads(user_data)` → GP-S12 HIGH

**Node.js / TypeScript**:
- Template literal in SQL: `` `SELECT ... ${req.body.id}` `` → GP-S01 CRITICAL
- `exec(userInput)` or `eval(userInput)` → GP-S02 CRITICAL
- `res.end(userInput)` with no sanitization in HTML context → GP-S03 HIGH
- `jwt.verify(token)` without algorithm check → GP-S10 HIGH

**Go**:
- `db.Query("SELECT ... " + userID)` → GP-S01 CRITICAL
- `exec.Command("/bin/sh", "-c", userInput)` → GP-S02 CRITICAL
- `defer file.Close()` missing after `os.Open()` → GP-S11 MEDIUM

---

## GP-S13 — Prompt Injection (AI-Specific)

This rule was added for AI/LLM systems where user input can escape into the
system prompt context. It applies to:
- Any API call to an LLM where user input is included in the system prompt
- Tool descriptions that include user-provided values
- Memory/context systems that retrieve user-written content and inject it

Detection pattern:
```
BAD:  system_prompt = f"You are a helpful assistant. User said: {user_message}"
GOOD: Use structured message format with role separation
      messages = [{"role": "system", "content": system_prompt},
                  {"role": "user", "content": user_message}]
```
