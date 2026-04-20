# Security Auditor — Baseline Scenarios

## Scenario 1: Pre-Launch Web API Audit (Canonical)

**Input**:
- Python FastAPI + PostgreSQL, JWT auth, 3 months of development
- Audit scope: full-stack pre-launch
- Milestone: v1.0 production release
- Git hash provided

**Expected Output Structure**:
- Verdict: PASSED / CONDITIONAL PASS / BLOCKED (depends on findings)
- Findings table sorted Critical → High → Medium → Low
- Each finding: severity, CWE, file:line, CVSS, exploit path, remediation
- OWASP Top 10 table with A01–A10 all rated
- Dependency CVE scan: `pip-audit` actual output attached
- Secret scan: current HEAD + git history results

**Key Decision Points**:
- Run pip-audit as actual Bash command, attach real output
- JWT implementation must be verified: alg validation, exp, iss/aud
- Every IDOR risk requires explicit check confirmation
- CVSS ≥ 7.0 → BLOCKED regardless of "fix later" requests

**BLOCK Condition**: If technology stack is unfamiliar (e.g., Rust actix-web with
custom auth middleware the auditor has not worked with), state the gap explicitly
rather than delivering a superficial audit.

---

## Scenario 2: Payment Module STRIDE (Complex)

**Input**:
- Payment flow: card tokenization + Stripe integration + webhook processing
- First audit of this module
- Compliance requirement: PCI-DSS

**Expected Output Structure**:
- Status: READY-FOR-NEXT (after full audit complete)
- STRIDE table for the payment flow with likelihood × impact for each threat
- PCI-DSS mapping: card data environment isolation, CVV storage (must be absent),
  TLS 1.2+ verification
- Webhook security: Stripe signature verification (`stripe.Webhook.construct_event`)
- Dependency scan focused on payment libraries (stripe, pycryptodome versions)
- Secret scan: no Stripe API keys in source or git history

**Key Decision Points**:
- CVV must never be stored — any evidence of CVV storage = CRITICAL
- Webhook must verify Stripe-Signature header — missing = HIGH (replay attack vector)
- PCI-DSS scope must be minimized (tokenization preferred over full card storage)

---

## Scenario 3: Git History Secret Leak (Blocked-Then-Unblocked)

**Input**:
- Developer committed AWS credentials to feature branch, then deleted them in next commit
- Audit triggered by @code-review escalation
- Scope: secret leak assessment + impact analysis

**Expected Output Structure**:
- Status: BLOCKED (CRITICAL: credentials compromised)
- Finding: CWE-798, CVSS 9.8, CRITICAL
- Exploit path: credential was in public git history at commit [hash];
  anyone who cloned the repo at that time has the credential
- Remediation steps (ordered):
  1. Immediately rotate/revoke the exposed credential in AWS IAM
  2. Audit AWS CloudTrail for unauthorized access since the commit date
  3. Rewrite git history with BFG Repo Cleaner to remove the commit (if repo is private)
  4. If repo was ever public: assume credential is compromised, rotation is not optional
  5. Add pre-commit hook (gitleaks/detect-secrets) to prevent recurrence
- Unblock condition: credential rotated + CloudTrail audit completed + prevention hook added
