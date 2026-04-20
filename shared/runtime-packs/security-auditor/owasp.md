# Security Auditor — OWASP Top 10 Deep Dive

## A01: Broken Access Control

The #1 OWASP category. Occurs when authenticated users can access resources or
perform actions beyond their intended permissions.

**Checks**:
- IDOR: for every endpoint with a resource ID parameter, verify ownership check
- Forced browsing: unauthenticated access to admin endpoints, debug routes
- CORS misconfiguration: wildcard `Access-Control-Allow-Origin: *` with credentials
- JWT audience bypass: token valid for service A accepted by service B
- Parameter tampering: user_id, role, account_type in request body/params

**Test patterns**:
```python
# IDOR test
# User A: GET /api/orders/123 → 200 (user A owns order 123)
# User B: GET /api/orders/123 → should be 403, not 200
# If user B gets 200: IDOR vulnerability

# CORS test
curl -H "Origin: https://evil.com" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS https://api.target.com/api/data
# Look for: Access-Control-Allow-Origin: https://evil.com
# or: Access-Control-Allow-Origin: *
# with Access-Control-Allow-Credentials: true → HIGH finding
```

---

## A02: Cryptographic Failures

**Checks**:
- PII transmitted over HTTP (not HTTPS)
- Sensitive data in database without encryption at rest
- Weak password hashing (MD5, SHA1, bcrypt with cost < 10)
- Hardcoded encryption keys
- IV reuse in AES-CBC mode

**grep patterns**:
```bash
# Weak hash for passwords
grep -rn "md5\|sha1\|hashlib.sha1\|hashlib.md5" --include="*.py" .
# Look for usages near "password"

# Hardcoded secrets
grep -rn "(password|secret|api_key|token)\s*=\s*['\"]" --include="*.py" .

# HTTP URLs (non-HTTPS)
grep -rn "http://" --include="*.py" . | grep -v "localhost\|127.0.0.1\|comment"
```

---

## A03: Injection

See `shared-gp-security.md` GP-S01 through GP-S03 for core patterns.

**Additional injection types**:

**XPath Injection**:
```python
# BAD
tree.xpath(f"//user[@name='{username}']")

# GOOD
tree.xpath("//user[@name=$name]", name=username)
```

**LDAP Injection** (if LDAP auth is used):
```python
# BAD: f"(uid={username})"
# GOOD: use ldap3 with filter escaping: ldap3.utils.conv.escape_filter_chars(username)
```

**NoSQL Injection (MongoDB)**:
```javascript
// BAD
db.users.findOne({username: req.body.username, password: req.body.password})
// Attacker sends: password: {$ne: null} → matches any password

// GOOD: validate types before query
if (typeof req.body.password !== 'string') { return res.status(400).json(...); }
```

---

## A04: Insecure Design

**Checks**:
- Missing rate limiting on authentication endpoints (brute force)
- No account lockout after repeated failed logins
- Password reset tokens with insufficient entropy or long validity window
- Mass assignment vulnerabilities (user can set `is_admin: true`)
- Business logic flaws (negative quantity in cart, negative payment amount)

**Rate limiting check**:
```bash
# Test: send 100 login requests in rapid succession
# Expected: 429 Too Many Requests after N attempts
# Finding if: still 200/401 after 100 attempts
```

---

## A05: Security Misconfiguration

**Checks**:
- Debug mode enabled in production (`DEBUG=True`, `app.debug = True`)
- Default credentials not changed (admin/admin, root/root)
- Verbose error messages exposing stack traces in production
- Unnecessary features enabled (directory listing, default pages)
- Security headers missing

**Security headers check**:
```bash
curl -I https://api.target.com/
# Expected headers:
# Strict-Transport-Security: max-age=31536000; includeSubDomains
# X-Content-Type-Options: nosniff
# X-Frame-Options: DENY or SAMEORIGIN
# Content-Security-Policy: [policy]
# Missing any of these: LOW finding (except HSTS missing on public API: MEDIUM)
```

---

## A06: Vulnerable and Outdated Components

See automated scan protocol in `core.md §Phase 2`.

**Manual check for critical libraries**:
```bash
# Python: check specific high-risk libraries
pip show cryptography pyjwt django flask requests | grep Version

# Cross-reference with NVD / GitHub Advisory Database
# pip-audit does this automatically but manual spot-check for critical paths
```

---

## A07: Identification and Authentication Failures

**JWT checks** (most common):

```python
# Verify: library configured to reject alg:none
import jwt
# BAD: jwt.decode(token, key, algorithms=["HS256", "none"])
# GOOD: jwt.decode(token, key, algorithms=["HS256"])
# Also verify: options={"require": ["exp", "iss", "aud"]}

# Known vulnerable library versions:
# python-jose < 3.3.0: CVE-2022-29217
# PyJWT < 2.4.0: CVE-2022-29217 (different vector)
```

**Session security**:
```bash
# Check cookie flags
curl -I https://app.target.com/login -c cookies.txt
# Look for: Set-Cookie: session=xxx; HttpOnly; Secure; SameSite=Strict
# Missing HttpOnly: XSS can steal session
# Missing Secure: session transmitted over HTTP
# Missing SameSite: CSRF risk
```

---

## A08: Software and Data Integrity Failures

**CI/CD security**:
- GitHub Actions: are third-party actions pinned to commit hash, not tag?
- Are deployment secrets stored in CI secrets, not in .env files in repo?
- Are container images signed?

**Deserialization**:
```python
# Python pickle: NEVER deserialize untrusted data
pickle.loads(user_data)  # CRITICAL: arbitrary code execution
# Fix: use JSON or msgpack with type validation
```

---

## A09: Security Logging and Monitoring Failures

**Audit log completeness check**:

Events that MUST be logged:
- Authentication (success and failure, with user ID and IP)
- Authorization failures (who tried to access what)
- Password changes
- Admin actions
- Payment transactions
- Data exports

Events that MUST NOT be logged:
- Passwords (even failed attempts)
- Tokens / session IDs
- Credit card numbers
- PII fields beyond user ID

---

## A10: Server-Side Request Forgery (SSRF)

**Detection**:
```bash
# Look for URL parameters
grep -rn "url=\|endpoint=\|host=\|target=" --include="*.py" . | grep "request.args\|request.form"

# Check for internal service fetch patterns
grep -rn "requests.get\|urllib.request.urlopen\|http.get" --include="*.py" .
```

**Test pattern**:
```
# If app fetches URL from user input:
POST /api/fetch-url
Body: {"url": "http://169.254.169.254/latest/meta-data/iam/security-credentials/"}
# AWS IMDSv1 metadata exposed → credential leak → CRITICAL
```

**Mitigation**: allowlist permitted domains/IPs; reject internal/private IP ranges
at the application layer before making any request.
