---
name: security-deep-audit
description: Deep security audit methodology for the Harness team. Covers OWASP Top 10, CWE catalog, STRIDE threat modeling, dependency CVE scanning, git history secret scanning, authentication deep-dive (JWT/OAuth/IDOR/RBAC), cryptography baseline, infrastructure security, and compliance mapping (GDPR/等保2.0/PCI-DSS/HIPAA). Loaded by @security-auditor via skills: frontmatter.
type: skill
---

# Security Deep Audit Skill

## 1. Audit Scope and Context

Confirm before beginning:
1. Audit depth: full-stack / module / feature
2. Priority framework: OWASP Top 10 / CWE Top 25 / PCI-DSS / HIPAA / 等保 2.0
3. Code freeze status: stable or changing?
4. Technology stack: languages, frameworks, databases, auth system, cloud provider
5. Previous audit findings and remediation status

BLOCK if technology stack is unfamiliar. Delivering incomplete audit with unknown gaps is worse than blocking.

## 2. Automated Scans

Run all automated tools and attach actual output:

```bash
# Python dependencies
pip-audit --requirement requirements.txt --format json

# Node.js dependencies
npm audit --json

# Go modules
go list -json -m all | nancy sleuth

# Container / image
trivy image myapp:latest --format json

# Git history secret scan
git log --all --full-history -- . | git diff HEAD~1 | \
  grep -E "(password|secret|api_key|token|private_key)\s*="

# Semgrep SAST
semgrep --config=p/owasp-top-ten --json .
```

## 3. Injection Vulnerabilities (CWE-89, CWE-78, CWE-94, CWE-22)

| Vector | Check | Pattern |
|---|---|---|
| SQL Injection | Parameterized queries, ORM escape analysis, second-order injection | `.execute("..." + var)`, f-string in query |
| Command Injection | `subprocess(shell=True)`, `os.system(user_input)`, `exec/eval` with user content | shell=True with user-controlled args |
| Template Injection (SSTI) | Jinja2 auto-escape audit, `{{ user_input }}` in templates | unsanitized template variables |
| Path Traversal | User-controlled file paths, directory escape, symlink attacks | `open(user_path)` without validation |
| Prompt Injection | LLM system prompt contamination, tool description injection | user content in system prompt |

## 4. Authentication and Authorization Deep-Dive

**JWT audit checklist**:
- Signature verified? `alg: none` prevented? Algorithm confusion (RS256→HS256) blocked?
- `exp`, `iss`, `aud` claims validated?
- Library version checked against known CVEs (python-jose < 3.3.0 CVE-2022-29217, PyJWT < 2.4.0)

**IDOR check** — for every resource endpoint:
```
GET /api/users/{id}  → verify req.user.id == id OR req.user.has_permission(id)
GET /api/orders/{id} → same check
GET /api/files/{path} → path traversal + permission check
```

**OAuth 2.0 / OIDC**: CSRF on callback, state parameter, open redirect, token leak

**Session Management**: fixation, hijacking, insufficient expiry, cookie flags (SameSite, HttpOnly, Secure)

**RBAC Bypass**: role confusion, privilege escalation paths, admin endpoint enumeration

## 5. Cryptography Baseline

- **Weak algorithms**: MD5/SHA1 for passwords (CWE-916), DES/RC4/ECB mode (CWE-327)
- **Key management**: hardcoded secrets (CWE-798), insufficient entropy (CWE-330)
- **Certificate validation**: pinning bypass, expired cert acceptance, weak cipher suites
- **Homegrown crypto**: any custom implementation = CRITICAL by definition (CWE-327)

## 6. OWASP Top 10 Checklist

Rate each category: PASS / FINDING #N / NOT APPLICABLE. Every PASS must cite specific evidence.

| Category | What to check |
|---|---|
| A01: Broken Access Control | IDOR, privilege escalation, CORS, forced browsing |
| A02: Cryptographic Failures | PII in transit/rest, weak algorithms, key management |
| A03: Injection | SQL, command, template, XPath, LDAP |
| A04: Insecure Design | Threat model gaps, missing rate limiting, no defense-in-depth |
| A05: Security Misconfiguration | Default creds, debug endpoints, error verbosity |
| A06: Vulnerable Components | CVE scan results, outdated dependencies |
| A07: Auth & Session Failures | JWT issues, session fixation, weak passwords |
| A08: Software Integrity Failures | CI/CD security, unsigned artifacts, supply chain |
| A09: Security Logging Failures | Audit trail completeness, log injection, sensitive data in logs |
| A10: SSRF | Internal service requests, URL parameter validation |

## 7. STRIDE Threat Modeling

For new features or first audit, complete STRIDE for each critical flow:

| Threat | Question | Score |
|---|---|---|
| Spoofing | Can attacker impersonate another identity? | likelihood × impact |
| Tampering | Can data be modified without detection? | likelihood × impact |
| Repudiation | Are actions logged with sufficient detail to attribute? | likelihood × impact |
| Information Disclosure | Can sensitive data be exposed? | likelihood × impact |
| Denial of Service | Can attacker exhaust resources? | likelihood × impact |
| Elevation of Privilege | Can low-privilege user gain higher privileges? | likelihood × impact |

## 8. Supply Chain and Dependencies

- **CVE scanning**: pip-audit, npm audit, trivy, snyk
- **Git history scanning**: `git log --all --full-history` — committed-then-deleted secrets are still compromised
- **Transitive dependency risk**: deep dependency tree vulnerabilities
- **SBOM**: Software Bill of Materials generation and review

## 9. Infrastructure and Configuration

- **Secret management**: env vars, secrets manager integration, config file exposure
- **TLS**: protocol version, cipher suite, HSTS, certificate transparency
- **CORS**: wildcard origins, credential exposure
- **Security headers**: CSP, X-Frame-Options, X-Content-Type-Options, HSTS

## 10. Compliance Mapping

| Framework | Applicable checks |
|---|---|
| GDPR | PII data mapping, consent recording, erasure path, breach notification |
| 等保 2.0 | 身份鉴别, 访问控制, 安全审计, 入侵防范, 数据完整性, 数据保密性 |
| PCI-DSS | Card data environment isolation, no storing CVV, TLS 1.2+, audit logging |
| HIPAA | PHI encryption at rest/transit, access controls, audit logs, BAA |

## 11. CVSS Scoring

| Range | Severity | Action |
|---|---|---|
| 9.0–10.0 | Critical | BLOCK unconditionally |
| 7.0–8.9 | High | BLOCK if unmitigated |
| 4.0–6.9 | Medium | Document in debt register |
| 0.1–3.9 | Low | Document in debt register |

## 12. Anti-Patterns

| Name | Symptom | Correction |
|---|---|---|
| **Compliance Theater** | OWASP checklist as checkbox exercise without verification | Every PASS cites specific evidence: code location, test performed, result observed |
| **High-Sev Fatigue** | Downgrading CVSS ≥ 7.0 because "hard to exploit" | CVSS ≥ 7.0 = BLOCKED. No exceptions. |
| **Current-HEAD-Only Scanning** | Secret scan only on HEAD, missing deleted commits | `git log --all --full-history` + diff across all commits |
| **Audit Without Exploit Path** | Finding says "input validation missing" without exploit path | Every finding includes step-by-step exploit path from attacker request to achieved impact |
| **Fix Authority Confusion** | Security auditor writing code fixes instead of findings | Produce findings with exploit paths + remediation recommendations. Fix authority belongs to implementing agent. |
