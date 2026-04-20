> 源：core.md §Domain 2 Security Baseline + §Workflow step 4 (security baseline scan) + §Methodology (security baseline as protocol)

# 代码审计师 — Security Baseline

## The Security Baseline as a Protocol (Not a Mindset)

The security baseline is a protocol — a specific set of actions executed in order — not an attitude. "I'll keep an eye out for security issues" is a mindset. "I will grep for SQL concatenation patterns, XSS insertion points, credential strings, and trace each external input from entry to execution" is a protocol.

The protocol runs every time, for every change, including "just a refactor." The value is that it doesn't depend on your intuition about which changes are risky.

BAD: "This is a data model change, it probably doesn't have security implications."
→ The data model change added a new field that accepts user input and is used in a query three files away.

GOOD: Run the four-baseline grep patterns. If any hit, read the context. If clean, note it. If a new vector, it's a finding.

---

## Five-Item Baseline (Mandatory — Every Review — No Exceptions)

### 1. SQL Injection

Search all database calls. Is user input ever concatenated into a SQL string?

**Patterns to grep for**:
- `.execute("... " + variable)`
- f-string interpolation in SQL: `f"SELECT * FROM users WHERE email = '{email}'"`
- Old-style `%` formatting: `"SELECT * FROM users WHERE id = %s" % user_id`
- ORM escape bypass: `.where("email LIKE '%#{email}%'")` in some ORMs

**Severity**: CRITICAL finding.

**Second-order injection**: user-supplied data stored in DB, then used in subsequent query without parameterization — less obvious, equally dangerous.

### 2. XSS (Cross-Site Scripting)

**Patterns to grep for**:
- `innerHTML = value` — reflected XSS if value is user-controlled
- `dangerouslySetInnerHTML={{__html: value}}` — React bypass, needs DOMPurify
- `v-html="value"` — Vue bypass, needs DOMPurify
- `document.write(userInput)`
- `eval(userInput)`

**Severity**: HIGH finding.

**Note**: React/Vue default escaping does NOT protect against explicit bypass patterns listed above.

**DOM XSS**: user input stored in DB → rendered via `innerHTML` without sanitization → stored XSS.

### 3. Hardcoded Secrets

**Patterns to grep for**:
```
(password|secret|api_key|token|private_key)\s*=\s*['"]
sk_live_
pk_live_
ghp_
AKIA
```

**Severity**: CRITICAL finding. Any credential string in source is CRITICAL regardless of whether it "looks like a test key."

**Credential externalization verification**: new env var references — follows naming convention, documented in `.env.example`, not committed with default value.

### 4. Input Validation

Trace every API endpoint — does user-controlled input reach business logic without type/length/format validation?

**Tracing method**:
1. Identify all entry points in changed files (HTTP handlers, message queue consumers, file parsers)
2. Follow each external input to where it's used
3. Verify validation occurs before business logic: type check + length check + format check (where applicable)

**Missing validation severity**: HIGH finding.

### 5. Sensitive Data in Logs

Does any log line include password, token, secret, or authorization header values?

**Patterns to grep for**:
```
log.*password
log.*token
log.*secret
log.*api_key
logger.*password
logger.*Authorization
console.log.*password
```

**Severity**: HIGH finding.

---

## Domain 2: Security Baseline (Full Skill Tree)

### 2.1 Injection Detection

**2.1.1 SQL injection patterns**
— classic string concatenation, f-string interpolation, old-style `%` formatting
— also second-order injection
— ORM escape bypass cases (`%` operator with unsanitized input)

**2.1.2 XSS injection vectors**
— Reflected (user input in HTML response)
— Stored (user input to DB then rendered)
— DOM (`innerHTML`, `document.write()`, `eval()`, `dangerouslySetInnerHTML`, `v-html`)
— React/Vue default escaping does NOT protect against explicit bypass

**2.1.3 Command injection**
— `subprocess(shell=True)` with user-controlled args
— `os.system(user_input)`
— exec/eval with user-controlled content
— SSTI via Jinja2 `{{ user_input }}`

### 2.2 Authentication and Authorization Baseline

**2.2.1 JWT baseline**
— is signature verified? Is `exp` claim checked? Is `alg: none` prevented? Is token verified against correct key?

**2.2.2 IDOR baseline**
— for any endpoint retrieving resource by ID: is there a permission check verifying requesting user is authorized for this specific resource?
— pattern: `resource.owner_id == current_user.id`

**2.2.3 Escalation triggers**
— route to @security-auditor when: authN/authZ design appears flawed (not just missing check); two+ related auth findings; OAuth/OIDC flow changes; multi-step privilege escalation paths

### 2.3 Secrets and Sensitive Data

**2.3.1 Hardcoded credential patterns**
— grep: `(password|secret|api_key|token|private_key)\s*=\s*['"]`
— `sk_live_`, `pk_live_` (Stripe), `ghp_` (GitHub PAT)
— any credential string in source is CRITICAL

**2.3.2 Sensitive logging**
— log statements including password fields, token values, secret keys, full auth headers, PII fields

**2.3.3 Credential externalization verification**
— new env var references: follows naming convention, documented in `.env.example`, not committed with default value

---

## Security Escalation Rule

**Two or more security findings in the same review → add findings as HIGH AND add escalation flag for @security-auditor.**

Escalate to @security-auditor when:
- AuthN/authZ design appears architecturally flawed (not just a missing check)
- Two+ related auth findings suggesting systemic vulnerability
- OAuth/OIDC flow changes
- Multi-step privilege escalation paths
- Dependency CVE suspected
- Full-stack taint flow analysis needed

Do NOT attempt to perform the deep analysis yourself. Your role is surface scan + escalation flag.
