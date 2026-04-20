> 源：core.md §Domain 2 Security Baseline + security-baseline.md（扩展 2026-04-21）

# 代码审计师 — 安全审查深度增强

## 认证架构审查

### JWT 深度审计

**必须验证的 5 个维度**：

| 检查项 | 正确做法 | 常见错误 |
|---|---|---|
| 算法白名单 | `algorithms=["HS256"]` 明确指定 | `algorithms=["HS256", "none"]` 或省略 |
| 签名验证 | 使用正确的密钥验证签名 | 仅解码 payload 不验证签名 |
| 过期检查 | `exp` 必须存在且未过期 | 忽略 exp 或允许无 exp 的 token |
| 签发者验证 | `iss` 匹配预期值 | 接受任何 iss |
| 受众验证 | `aud` 匹配当前服务 | 接受为其他服务签发的 token |

**代码审查模板**：
```python
# GOOD — 完整的 JWT 验证
try:
    payload = jwt.decode(
        token,
        key=settings.JWT_PUBLIC_KEY,
        algorithms=["RS256"],  # 明确指定，不包含 "none"
        options={
            "require": ["exp", "iss", "aud"],
            "verify_exp": True,
            "verify_iss": True,
            "verify_aud": True,
        },
        issuer="https://auth.example.com",
        audience="https://api.example.com",
    )
except jwt.ExpiredSignatureError:
    raise HTTPException(status_code=401, detail="Token expired")
except jwt.InvalidTokenError:
    raise HTTPException(status_code=401, detail="Invalid token")
```

### OAuth 2.0 / OIDC 审查点

**PKCE 流程**：
```python
# 必须验证：
# 1. code_challenge 在授权请求中发送
# 2. code_verifier 在 token 请求中发送
# 3. server 验证 S256(code_verifier) == code_challenge
# 4. state 参数匹配（CSRF 防护）
# 5. redirect_uri 严格匹配注册值
```

**常见 OAuth 漏洞**：
- Open Redirect：`redirect_uri` 未严格匹配 → 攻击者窃取 code
- CSRF：缺少 `state` 参数或 state 可预测
- Token 泄露：token 存储在 localStorage 而非 httpOnly cookie

### IDOR 系统化检查

**检查矩阵**：

| 端点模式 | 必须验证 | 审查代码 |
|---|---|---|
| `GET /api/users/{id}` | `current_user.id == id` 或 `has_permission(id)` | 逐行检查 |
| `GET /api/orders/{id}` | `order.user_id == current_user.id` | 逐行检查 |
| `GET /api/files/{path}` | 路径规范化 + 权限检查 | 逐行检查 |
| `POST /api/transfer` | `from_account` 属于 current_user | 逐行检查 |
| `DELETE /api/comments/{id}` | `comment.author_id == current_user.id` | 逐行检查 |

---

## 输入验证深度审查

### 类型安全验证

```python
# BAD — 类型不安全
@app.post("/orders")
def create_order(quantity: int = Form(...)):
    # quantity 可以是字符串 "10"，FastAPI 会转换
    # 但如果传入 "10; DROP TABLE users;" 呢？
    pass

# GOOD — 严格类型 + 范围验证
from pydantic import BaseModel, Field, validator

class CreateOrderRequest(BaseModel):
    quantity: int = Field(..., ge=1, le=1000)
    product_id: str = Field(..., pattern=r"^prod_[a-z0-9]{10}$")

    @validator('product_id')
    def validate_product_id(cls, v):
        if not v.startswith('prod_'):
            raise ValueError('Invalid product ID format')
        return v
```

### 文件上传安全检查

```python
# 必须验证：
# 1. 文件类型（MIME type + magic number，不只是扩展名）
# 2. 文件大小限制
# 3. 文件名规范化（防止路径遍历）
# 4. 存储位置隔离（不在 web 根目录）
# 5. 病毒扫描（如果适用）

import magic
from pathlib import Path

ALLOWED_TYPES = {'image/jpeg', 'image/png', 'application/pdf'}
MAX_SIZE = 10 * 1024 * 1024  # 10MB

def validate_upload(file: UploadFile) -> None:
    # 检查大小
    content = file.read()
    if len(content) > MAX_SIZE:
        raise HTTPException(413, "File too large")

    # 检查真实类型（magic number）
    detected = magic.from_buffer(content, mime=True)
    if detected not in ALLOWED_TYPES:
        raise HTTPException(415, f"File type {detected} not allowed")

    # 文件名安全化
    safe_name = Path(file.filename).name  # 去除路径
    if '..' in safe_name or safe_name.startswith('.'):
        raise HTTPException(400, "Invalid filename")
```

---

## 依赖安全审查

### CVE 扫描集成

```bash
# Python — pip-audit
pip-audit --requirement requirements.txt --format=json --desc

# Node.js — npm audit
npm audit --json --audit-level=moderate

# Go — nancy
go list -json -m all | nancy sleuth

# Rust — cargo-audit
cargo audit

# 多语言项目 — trivy
trivy fs --scanners vuln .
```

### 关键依赖版本检查

```bash
# 检查已知漏洞版本
# Python
pip show pyjwt | grep Version  # < 2.4.0 = CVE-2022-29217
pip show cryptography | grep Version  # < 39.0.1 = CVE-2023-0286

# Node.js
npm list jsonwebtoken  # < 9.0.0 = CVE-2022-23529
npm list express  # < 4.17.3 = CVE-2022-24999

# 检查是否有未维护的依赖
npm outdated  # 或 pip list --outdated
```

### 供应链攻击防护

```bash
# 检查 lock 文件篡改
git diff HEAD -- package-lock.json  # 异常的依赖变更

# 检查 typosquatting 依赖
# 例如：requests vs reqeusts, django vs djanog
npm list | grep -E "(reqeust|djanog|urllib3s)"

# 检查依赖的依赖（transitive）
npm ls --all --json | jq '.. | objects | select(. vulnerabilities?)'
```

---

## 安全审查输出模板

### 安全专项审查报告

```markdown
## Security Deep-Dive Review: [Task ID]

### Authentication Architecture
| Check | Result | Evidence |
|---|---|---|
| JWT algorithm whitelist | PASS / FAIL | [code location] |
| Signature verification | PASS / FAIL | [code location] |
| Expiration enforcement | PASS / FAIL | [code location] |
| Issuer validation | PASS / FAIL | [code location] |
| Audience validation | PASS / FAIL | [code location] |

### Authorization (IDOR)
| Endpoint | Ownership Check | Result |
|---|---|---|
| GET /api/users/{id} | [code location] | PASS / FAIL |
| GET /api/orders/{id} | [code location] | PASS / FAIL |

### Input Validation
| Input Type | Validation Layer | Result |
|---|---|---|
| Text fields | [schema location] | PASS / FAIL |
| File uploads | [validation location] | PASS / FAIL |
| JSON payloads | [schema location] | PASS / FAIL |

### Dependency Security
| Tool | Command | Result |
|---|---|---|
| pip-audit | `pip-audit --format=json` | [summary] |
| npm audit | `npm audit --json` | [summary] |

### Findings
**CRITICAL**: [file:line] [description] → [exploit path] → Fix: [direction]
**HIGH**: [file:line] [description] → [exploit path] → Fix: [direction]

### Verdict
ESCALATE TO @security-auditor / CHANGES REQUESTED / PASS
```
