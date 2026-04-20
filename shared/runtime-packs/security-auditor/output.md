---
source: agents/security-auditor.md
copied: 2026-04-21
note: Output contract for security audit reports. Defines mandatory sections, formats, and templates.
---

# Security Auditor — Output Contract

## Report Header (Every Report)

```markdown
## Security Audit Report: [Milestone Name] — [YYYY-MM-DD]
**Audit Scope**: [full-stack / module / feature-name]
**Code Snapshot**: [git commit hash]
**Auditor**: [agent name + version]
**Technology Stack**: [languages, frameworks, databases, auth system, cloud provider]
**Priority Framework**: [OWASP Top 10 / CWE Top 25 / PCI-DSS / HIPAA / 等保 2.0]
**Previous Audit**: [date + findings count + remediated count]

**Verdict**: [PASSED | CONDITIONAL PASS (pending #N) | BLOCKED (#N findings block release)]
```

---

## Section 1: Findings (Critical → High → Medium → Low)

### Finding Template

```markdown
### Finding #[N]: [Short Title]
**Severity**: [CRITICAL | HIGH | MEDIUM | LOW]
**CWE**: [CWE-XXX: Name]
**CVSS v3.1**: [X.X] ([Vector String])
**Location**: `file/path:line_number`
**Category**: [Injection / AuthN / AuthZ / Crypto / Config / Dependency / Logic]

**Evidence**:
```[exact code snippet]
```

**Exploit Path** (step-by-step):
1. Attacker [action] → [result]
2. Attacker [action] → [result]
3. Attacker [action] → [impact on system/data]

**Business Impact**: [what data is at risk, how many users affected, regulatory implications]

**Remediation**:
- Immediate: [what to do right now]
- Short-term: [fix within 1 sprint]
- Long-term: [architectural improvement]

**Verification** (post-fix):
```[test command or code review checklist]
```
```

### Filled Example

```markdown
### Finding #1: SQL Injection in Order Search Endpoint
**Severity**: CRITICAL
**CWE**: CWE-89: SQL Injection
**CVSS v3.1**: 9.1 (CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N)
**Location**: `api/orders.py:45`
**Category**: Injection

**Evidence**:
```python
# BAD — user input concatenated into SQL
@app.get("/orders/search")
def search_orders(q: str):
    query = f"SELECT * FROM orders WHERE description LIKE '%{q}%'"
    return db.execute(query)  # CRITICAL: direct concatenation
```

**Exploit Path**:
1. Attacker sends `q = "' UNION SELECT password FROM users--"`
2. Query becomes `SELECT * FROM orders WHERE description LIKE '%' UNION SELECT password FROM users--%'`
3. Database returns all user passwords alongside order data
4. Attacker exfiltrates entire user credential database

**Business Impact**: Complete user credential database exposed. All accounts compromised. GDPR breach notification required within 72 hours.

**Remediation**:
- Immediate: Disable `/orders/search` endpoint until fixed
- Short-term: Replace with parameterized query:
  ```python
  query = "SELECT * FROM orders WHERE description LIKE :pattern"
  db.execute(query, {"pattern": f"%{q}%"})
  ```
- Long-term: Implement ORM-level query builder (SQLAlchemy/SQLModel) to prevent raw SQL patterns

**Verification**:
```python
# Confirm no string interpolation in database layer
grep -r "f\".*execute\|%.execute\|+.*execute" api/
# Expected: 0 matches
```
```

---

## Section 2: OWASP Top 10 Verdict Table

```markdown
### OWASP Top 10 Verdict Table

| ID | Category | Verdict | Evidence | Notes |
|----|----------|---------|----------|-------|
| A01 | Broken Access Control | [PASS/FINDING/N/A] | [file:line or "no issues found"] | |
| A02 | Cryptographic Failures | [PASS/FINDING/N/A] | | |
| A03 | Injection | [PASS/FINDING/N/A] | | |
| A04 | Insecure Design | [PASS/FINDING/N/A] | | |
| A05 | Security Misconfiguration | [PASS/FINDING/N/A] | | |
| A06 | Vulnerable Components | [PASS/FINDING/N/A] | | |
| A07 | Auth Failures | [PASS/FINDING/N/A] | | |
| A08 | Software Integrity | [PASS/FINDING/N/A] | | |
| A09 | Logging Failures | [PASS/FINDING/N/A] | | |
| A10 | SSRF | [PASS/FINDING/N/A] | | |
```

### Filled Example

```markdown
| ID | Category | Verdict | Evidence | Notes |
|----|----------|---------|----------|-------|
| A01 | Broken Access Control | FINDING #3 | `api/orders.py:67` — IDOR on order detail | Missing ownership check |
| A02 | Cryptographic Failures | PASS | JWT uses RS256 with 2048-bit key | Verified key rotation policy exists |
| A03 | Injection | FINDING #1 | `api/orders.py:45` — SQL injection | Parameterized queries needed |
| A04 | Insecure Design | PASS | Rate limiting implemented | 100 req/min per IP |
| A05 | Security Misconfiguration | FINDING #2 | CORS allows `*` with credentials | Restrict to known origins |
| A06 | Vulnerable Components | PASS | `pip-audit` — 0 CRITICAL, 1 HIGH | HIGH is Django 4.1.0 (CVE-2023-31047) |
| A07 | Auth Failures | PASS | State parameter validated | OAuth 2.0 flow verified |
| A08 | Software Integrity | N/A | No CI/CD pipeline yet | Flag for future audit |
| A09 | Logging Failures | PASS | Structured JSON logs with trace_id | Audit log covers auth events |
| A10 | SSRF | PASS | No server-side HTTP requests to user URLs | Verified with code review |
```
```

---

## Section 3: Dependency CVE Scan

```markdown
### Dependency CVE Scan

**Command Run**: `[actual command]`
**Timestamp**: [YYYY-MM-DD HH:MM]

| Package | Version | CVE | Severity | CVSS | Fixed In | Status |
|---------|---------|-----|----------|------|----------|--------|
| [pkg] | [ver] | [CVE-YYYY-XXXXX] | [CRIT/HIGH/MED/LOW] | [X.X] | [ver] | [BLOCKED/ACCEPTED/DEBT] |

**Scan Output** (attach full output):
```
[actual tool output]
```
```

### Filled Example

```markdown
**Command Run**: `pip-audit --requirement requirements.txt --format=json`
**Timestamp**: 2026-04-21 14:30

| Package | Version | CVE | Severity | CVSS | Fixed In | Status |
|---------|---------|-----|----------|------|----------|--------|
| Django | 4.1.0 | CVE-2023-31047 | HIGH | 7.5 | 4.1.7 | DEBT — scheduled upgrade Sprint 12 |
| requests | 2.28.0 | CVE-2023-32681 | MEDIUM | 5.3 | 2.31.0 | ACCEPTED — no exploit path in current usage |
| cryptography | 39.0.0 | CVE-2023-23931 | MEDIUM | 5.9 | 41.0.0 | DEBT — upgrade with Django bump |

**Scan Output**:
```json
{"dependencies": [...], "vulnerabilities": [...]}
```
```

---

## Section 4: Secret Scan

```markdown
### Secret Scan

**Current HEAD**:
- Command: `git grep -E "(password|secret|api_key|token|private_key)\s*=" -- "*.py" "*.js" "*.ts" "*.yaml" "*.yml" "*.json"`
- Result: [0 findings / N findings]
- If findings: list file:line + secret type

**Git History**:
- Command: `git log --all --full-history -p -- . | grep -E "(password|secret|api_key|token|private_key)\s*="`
- Result: [0 findings / N findings]
- If findings: list commit hash + file + secret type + remediation

**Prevention Status**:
- [ ] gitleaks pre-commit hook installed
- [ ] GitHub secret scanning enabled
- [ ] `.gitignore` excludes `.env` files
```

---

## Section 5: STRIDE Threat Model (When Applicable)

```markdown
### STRIDE Threat Model: [Feature/Flow Name]

**Trust Boundaries**: [list boundaries, e.g., "User → API Gateway", "API Gateway → Service", "Service → Database"]

| Threat Category | Likelihood | Impact | Risk Level | Finding # | Mitigation Status |
|-----------------|------------|--------|------------|-----------|-------------------|
| Spoofing | [1-5] | [1-5] | [Critical/High/Med/Low] | [#N or N/A] | [Implemented/Planned/Missing] |
| Tampering | | | | | |
| Repudiation | | | | | |
| Info Disclosure | | | | | |
| Denial of Service | | | | | |
| Elevation of Privilege | | | | | |

**Attack Tree** (for Critical/High risk items):
```
[Goal: Attacker gains admin access]
├── [AND] Compromise user account
│   ├── [OR] Credential stuffing
│   ├── [OR] Phishing
│   └── [OR] Password reset abuse
└── [AND] Escalate to admin
    ├── [OR] IDOR on role change endpoint
    └── [OR] Mass assignment on user update
```
```

---

## Section 6: Compliance Mapping (When Applicable)

```markdown
### Compliance Mapping

| Framework | Control ID | Requirement | Status | Evidence | Finding # |
|-----------|------------|-------------|--------|----------|-----------|
| GDPR | Art. 32 | Encryption of personal data | [COMPLIANT/NON-COMPLIANT] | [file:line or note] | [#N] |
| 等保 2.0 | 8.1.4.3 | Access control | | | |
| HIPAA | 164.312 | Access management | | | |
| PCI-DSS | 3.4 | PAN storage | | | |
```

---

## Section 7: Security Debt Register

```markdown
### Security Debt Register

| # | Severity | Finding | Suggested Sprint | Owner | Risk If Deferred |
|---|----------|---------|------------------|-------|------------------|
| [N] | [SEV] | [brief description] | [Sprint X] | [@backend/@devops] | [what happens if not fixed] |
```

---

## Verdict Decision Matrix

```
CRITICAL findings (>0)     → BLOCKED unconditionally
HIGH findings (>0)         → BLOCKED unconditionally
MEDIUM findings (>3)       → CONDITIONAL PASS (must fix before next milestone)
LOW findings only          → PASSED (debt register required)
No findings                → PASSED
```

---

## BLOCKED Report Format

When audit cannot proceed or must block release:

```markdown
## Security Audit Report: [Milestone] — [YYYY-MM-DD]
**Verdict**: BLOCKED

**Block Condition**: [specific reason]
- [ ] Missing prerequisite: [what is needed]
- [ ] Unfamiliar technology stack: [specific gap]
- [ ] Critical findings block release: [list]
- [ ] Environmental issue: [what is blocking the scan]

**What Was Completed**:
- [list completed sections]

**What Is Blocked**:
- [list blocked sections + why]

**Unblock Conditions**:
1. [specific condition]
2. [specific condition]

**Route To**: [@backend for fixes / @devops for environment / @architect for topology]
```

---

## Quality Checklist (Pre-Submission)

- [ ] Every finding has file:line + code snippet + exploit path
- [ ] Every finding has a CWE number
- [ ] CVSS v3.1 score calculated for every finding
- [ ] pip-audit/npm audit/go list/trivy ran as live Bash, output attached
- [ ] Git history secret scan completed
- [ ] OWASP Top 10 table has verdict for all A01-A10
- [ ] Verdict follows decision matrix (Critical/High = BLOCKED)
- [ ] Debt register includes owner and risk-if-deferred for every accepted item
- [ ] BLOCKED reports list unblock conditions explicitly
- [ ] No speculative findings — every finding is reproducible from provided code
