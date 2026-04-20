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

---

## Scenario 4: OAuth 2.0 Implementation Audit (Complex)

**Input**:
- New OAuth 2.0 + OIDC login flow for mobile and web clients
- Stack: Node.js + Express + passport-openidconnect
- Scope: full auth flow audit + STRIDE

**Expected Output Structure**:
- Status: BLOCKED (3 HIGH findings + 1 CRITICAL)
- CRITICAL: `auth.js:L45` — `state` parameter not validated in callback handler
  - Exploit path: attacker crafts login link with attacker's state → victim logs in → callback uses attacker's state → session confused
  - CVSS: 8.1, CWE-352
  - Fix: validate state parameter matches session-stored value before token exchange

- HIGH #1: `auth.js:L67` — `redirect_uri` not strictly matched against registered values
  - Exploit path: attacker registers `evil.com` as redirect_uri → steals authorization code
  - Fix: exact string match against whitelist, no prefix/substring matching

- HIGH #2: `auth.js:L89` — authorization code has no expiration
  - Exploit path: intercepted code can be used indefinitely
  - Fix: code expires in 10 minutes maximum

- HIGH #3: `token.js:L23` — refresh token has no rotation
  - Exploit path: stolen refresh token usable indefinitely
  - Fix: implement refresh token rotation (new refresh token issued with each access token refresh)

- STRIDE summary:
  - Spoofing: HIGH (state validation missing)
  - Tampering: MEDIUM (code signing present)
  - Repudiation: LOW (audit logs complete)
  - Info Disclosure: HIGH (redirect_uri open)
  - DoS: LOW (rate limiting present)
  - EoP: CRITICAL (state confusion → account takeover)

- Dependency scan: `passport-openidconnect@0.1.1` — check for CVEs
- Secret scan: no client secrets in source

**Key Decision Points**:
- OAuth2 安全是系统性问题 — 单个 finding 往往与其他 finding 组合成攻击链
- State 验证缺失 + Open Redirect = 完整的账户接管攻击路径
- Refresh token 无旋转是长期风险 — 短期可能接受，但必须记录为债务

---

## Scenario 5: GDPR + 等保 2.0 双合规审计 (Complex)

**Input**:
- 跨境医疗数据平台，服务中欧用户
- 处理患者健康数据（PHI/特殊类别 PII）
- 合规要求：GDPR + 等保 2.0 等级 3 + HIPAA（与美国医院合作）

**Expected Output Structure**:
- Status: BLOCKED (4 findings: 2 CRITICAL, 2 HIGH)

- CRITICAL #1: `database/schema.sql:L23` — `patients.diagnosis` 字段未加密
  - GDPR 特殊类别数据 + HIPAA PHI 要求加密
  - 等保 2.0 等级 3 要求敏感数据静态加密
  - Fix: 实施 AES-256-GCM 字段级加密

- CRITICAL #2: `api/exports.py:L45` — 数据导出接口无审计日志
  - GDPR 要求记录数据访问；等保要求审计日志完整性
  - 攻击者可批量导出患者数据而无痕迹
  - Fix: 所有导出操作记录到独立审计系统

- HIGH #1: `config.py:L12` — 欧盟患者数据存储在中国服务器
  - GDPR 要求数据传输有充分性决定或 SCC
  - Fix: 实施 SCC + 加密传输 + DPA 协议

- HIGH #2: `auth.py:L78` — 管理员无 MFA
  - 等保 2.0 等级 3 要求管理员 MFA
  - Fix: 强制所有管理员账户启用 MFA

- Compliance mapping:
  | 框架 | 控制项 | 状态 |
  |---|---|---|
  | GDPR | 特殊类别数据加密 | NON-COMPLIANT |
  | GDPR | 数据传输 SCC | NON-COMPLIANT |
  | 等保 2.0 | 管理员 MFA | NON-COMPLIANT |
  | 等保 2.0 | 审计日志完整性 | NON-COMPLIANT |
  | HIPAA | PHI 加密 | NON-COMPLIANT |
  | HIPAA | 访问审计 | NON-COMPLIANT |

- Remediation timeline:
  - Week 1: 实施字段级加密 + 启用管理员 MFA
  - Week 2: 实施审计日志系统 + SCC 协议签署
  - Week 3: 复测所有控制项

**Key Decision Points**:
- 多合规框架重叠时，取最严格的要求
- 等保 2.0 等级 3 + GDPR + HIPAA 三重叠加 = 极高安全基线
- 跨境数据传输是合规中最复杂的部分 — 需要法务 + 安全联合审查
- 医疗数据泄露的 reputational damage 远超罚款本身
