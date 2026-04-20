# Security Auditor — Compliance Frameworks Reference

## GDPR (General Data Protection Regulation)

**Applicability**: Any system processing personal data of EU residents.

**Key requirements for audit**:

| Requirement | Audit Check | Finding if Violated |
|---|---|---|
| Lawful basis | Does the system record consent or other lawful basis for processing? | HIGH |
| Data minimization | Is only necessary PII collected? | MEDIUM |
| Right to erasure | Is there a delete/anonymize path for user data? | HIGH |
| Data breach notification | Can the system detect and report breaches within 72 hours? | HIGH |
| Data portability | Can user data be exported in a machine-readable format? | MEDIUM |
| Privacy by design | Are privacy controls built in, or bolted on? | MEDIUM |
| Data transfers | PII transferred outside EU requires adequacy decision or SCCs | HIGH |

**PII mapping checklist**:
```
Fields considered PII under GDPR:
- Name, email, phone number, home address
- IP addresses (in most cases)
- Location data
- Biometric data (fingerprints, facial recognition)
- Health data (special category — requires explicit consent)
- Racial/ethnic origin (special category)
- Sexual orientation (special category)
- Financial data (bank account, credit card)
```

**Audit actions**:
1. List all database tables/fields containing PII
2. Verify each has documented lawful basis
3. Verify encryption at rest for special category data
4. Test deletion path: create account → delete account → verify data gone
5. Check analytics/logging doesn't capture PII without consent

---

## 等保 2.0 (China Cybersecurity Classified Protection)

**Level 2 baseline requirements** (most commercial applications):

| Control Domain | Key Requirements |
|---|---|
| 身份鉴别 (Identity) | Multi-factor auth for admin; password complexity requirements |
| 访问控制 (Access Control) | Least privilege; role-based access; privileged account review |
| 安全审计 (Security Audit) | Audit logs for all admin operations; log integrity protection |
| 入侵防范 (Intrusion Prevention) | Input validation; rate limiting; IDS/WAF in production |
| 数据完整性 (Data Integrity) | Transport encryption (TLS); data signing where required |
| 数据保密性 (Data Confidentiality) | Encryption for sensitive data at rest and in transit |

**Level 3 additions** (critical infrastructure, financial, healthcare):
- Independent security assessment by qualified organization
- Real-time security monitoring (SOC capability)
- Business continuity and disaster recovery plan
- Annual penetration testing

**Common findings in 等保 2.0 audits**:
- Privileged accounts (admin/root) with no MFA: HIGH
- No separation of duties for database admin: HIGH
- Audit logs stored on the same system they audit: MEDIUM
- No log retention policy or logs deleted after < 6 months: MEDIUM

---

## PCI-DSS (Payment Card Industry Data Security Standard)

**Applicability**: Any system that processes, stores, or transmits cardholder data.

**Critical requirements**:

| PCI Requirement | Audit Check |
|---|---|
| 3.2: Never store CVV | Search codebase and database schema for CVV/CVV2/CVC fields |
| 3.4: PAN (card number) masked when displayed | Only last 4 digits visible in any display |
| 4.1: TLS 1.2+ for data transmission | TLS version check on all endpoints |
| 6.5: Secure coding (OWASP) | Code audit for injection, auth bypass, XSS |
| 7: Restrict access to cardholder data | RBAC with least privilege, reviewed quarterly |
| 8: Strong auth for all system components | MFA for all admin access |
| 10.2: Audit logs for all cardholder data access | Log every read of PAN data |

**CVV storage check** (most critical PCI check):
```bash
# Search database schema
grep -rn "cvv\|cvc\|cvv2\|card_verification" migrations/ schema/ --include="*.sql"

# Search source code for any storage path
grep -rn "cvv\|cvc\|cvv2" --include="*.py" --include="*.js" .
# Finding: any result that stores CVV to database = CRITICAL, immediate BLOCKED
```

**Scope minimization recommendation**: use Stripe/Braintree/Adyen tokenization.
These services store the card data; your system stores only a token.
Tokenization reduces PCI-DSS scope dramatically.

---

## HIPAA (Health Insurance Portability and Accountability Act)

**Applicability**: Systems handling Protected Health Information (PHI) for
US patients.

**PHI definition**: any health information that can identify an individual:
name + diagnosis, medical record numbers, device identifiers, etc.

**Key requirements**:

| HIPAA Safeguard | Audit Check |
|---|---|
| Encryption in transit | TLS 1.2+ for all PHI transmission |
| Encryption at rest | AES-256 for PHI database fields |
| Access controls | User-based access with audit logging |
| Audit controls | Logs of who accessed what PHI and when |
| Integrity controls | PHI must not be altered without authorization |
| BAA | Business Associate Agreement required with all PHI processors |

**Business Associate Agreements**: if the system sends PHI to third-party
services (email providers, cloud storage, analytics), a BAA is required.
Absence of BAA = HIGH finding (HIPAA violation risk).

---

## ISO 27001 (Framework Reference Only)

ISO 27001 is a broader information security management framework. For audit
purposes, the key clause relevant to code/application audits:

- **A.8.3**: Information systems acquision, development, and maintenance
  (secure coding standards, testing requirements)
- **A.9.4**: Application and system access control (authentication, session management)
- **A.10.1**: Cryptographic controls (encryption policies, key management)
- **A.12.6**: Technical vulnerability management (CVE scanning, patch management)
- **A.14.2**: Security in development and support processes (code review, pen testing)

---

## Compliance Audit Output Format

For each applicable framework:

```
## [Framework] Compliance Assessment

**Applicability rationale**: [why this framework applies]
**Assessment scope**: [which parts of the system were evaluated]

| Control | Requirement | Status | Evidence / Finding |
|---|---|---|---|
| [ID] | [description] | PASS / FINDING #N / NOT APPLICABLE | [evidence or finding reference] |

**Compliance verdict**: COMPLIANT / CONDITIONALLY COMPLIANT (pending #N) / NON-COMPLIANT

**Findings requiring compliance-specific remediation**:
[List findings that, if unaddressed, create regulatory risk]

**Recommended next steps**:
[Prioritized actions for compliance gap closure]
```
