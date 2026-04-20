# Security Auditor — STRIDE Threat Modeling

## STRIDE Framework Overview

STRIDE is used for first-time audits of new features or high-risk modules.
It provides structured coverage across all threat categories.

| Threat | Question |
|---|---|
| Spoofing | Can an attacker pretend to be someone they are not? |
| Tampering | Can an attacker modify data without authorization? |
| Repudiation | Can an actor deny having performed an action? |
| Information Disclosure | Can an attacker access data they should not? |
| Denial of Service | Can an attacker prevent legitimate users from accessing the system? |
| Elevation of Privilege | Can an attacker gain higher privileges than authorized? |

---

## STRIDE Worksheet Template

For each critical flow (auth, payment, data export, admin operations):

```
Flow: [name the flow being analyzed]
Components: [list the components in this flow]

SPOOFING
  Threat: [describe the spoofing scenario]
  Likelihood: [1-5 where 5=very likely]
  Impact: [1-5 where 5=catastrophic]
  Current mitigations: [what already prevents this]
  Residual risk: [after mitigations, what remains]
  Recommendation: [if residual risk is HIGH]

TAMPERING
  [same structure]

REPUDIATION
  [same structure]

INFORMATION DISCLOSURE
  [same structure]

DENIAL OF SERVICE
  [same structure]

ELEVATION OF PRIVILEGE
  [same structure]
```

---

## Example: STRIDE for JWT Authentication Flow

```
Flow: User Login → JWT Issuance → Protected API Access
Components: login endpoint, JWT service, API middleware, token blacklist (Redis)

SPOOFING
  Threat: Attacker forges JWT to impersonate another user
  Likelihood: 3 (requires key compromise or alg bypass)
  Impact: 5 (full account takeover)
  Current mitigations: HS256 signing with server-side secret key
  Residual risk: HIGH if alg:none not blocked; MEDIUM if properly configured
  Recommendation: Verify jwt.decode() explicitly excludes 'none' algorithm;
                  add integration test for alg:none rejection

TAMPERING
  Threat: Attacker modifies JWT claims (user_id, role) after issuance
  Likelihood: 2 (requires key knowledge to forge signature)
  Impact: 5 (privilege escalation)
  Current mitigations: HMAC signature on full payload
  Residual risk: LOW (signature change would be detected)

REPUDIATION
  Threat: User denies having performed an action (e.g., transaction)
  Likelihood: 3 (users frequently dispute actions)
  Impact: 3 (financial or reputational damage)
  Current mitigations: Database audit log records user_id + action + timestamp
  Residual risk: MEDIUM (logs don't include IP or device fingerprint)
  Recommendation: Add source IP and user-agent to auth event logs

INFORMATION DISCLOSURE
  Threat: JWT claims expose sensitive user data (email, PII)
  Likelihood: 4 (JWT is client-readable, just Base64 encoded)
  Impact: 2 (email exposure, not financial)
  Current mitigations: None — email is currently in JWT claims
  Residual risk: MEDIUM
  Recommendation: Remove email from JWT claims; use opaque user_id only

DENIAL OF SERVICE
  Threat: JWT verification computation overwhelmed by malformed tokens
  Likelihood: 2 (HMAC is fast; parsing overhead is low)
  Impact: 2 (transient latency increase)
  Current mitigations: Rate limiting on auth endpoint (100 req/min per IP)
  Residual risk: LOW

ELEVATION OF PRIVILEGE
  Threat: Low-privilege user obtains admin token through flow manipulation
  Likelihood: 2 (requires role-bypass vulnerability)
  Impact: 5 (full admin access)
  Current mitigations: Role assigned server-side from database at login time
  Residual risk: LOW if role is always fetched from DB, not from JWT claim
  Note: VERIFY that role is fetched from database, not read from JWT payload
```

---

## Attack Trees (Supplementary)

For HIGH-risk findings, draw the attack tree showing how a finding enables
a chain of further exploitation:

```
[Goal: Extract all user PII]
  ├── [A] SQL Injection on /api/search
  │     └── Dump users table
  ├── [B] Admin account compromise
  │     ├── [B1] Brute force (no rate limit)
  │     └── [B2] Session fixation
  └── [C] IDOR on /api/users/{id}
        └── Enumerate all user IDs
```

Attack trees help prioritize: which finding, if fixed, removes the most
attack paths? Fix that one first.

---

## Trust Boundary Diagram

Before STRIDE, draw trust boundaries:

```
[User Browser]
    ↓ HTTPS (TLS 1.3)
[Load Balancer / CDN]    ← trust boundary
    ↓ HTTP (internal network)
[API Gateway]            ← trust boundary
    ↓ gRPC (mTLS)
[Microservices]
    ↓ TCP (no TLS)       ← potential finding: plaintext internal comms
[Database]
```

Every crossing of a trust boundary is a potential attack surface.
STRIDE should be applied at each boundary crossing.

---

## STRIDE Score to CVSS Mapping

STRIDE findings feed into CVSS scoring:

| STRIDE Finding | Typical CVSS Range | Notes |
|---|---|---|
| Identity Spoofing (JWT bypass) | 8.0–9.8 | Depends on privilege level |
| Data Tampering (unsigned updates) | 7.0–9.0 | Depends on what can be tampered |
| Repudiation (no audit log) | 4.0–6.0 | Usually Medium |
| Information Disclosure (IDOR) | 5.0–8.0 | Depends on data sensitivity |
| DoS (no rate limit) | 4.0–7.5 | Depends on blast radius |
| EoP (privilege escalation) | 8.0–10.0 | Almost always High/Critical |
