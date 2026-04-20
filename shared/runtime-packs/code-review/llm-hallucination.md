> 源：core.md §Domain 3.3 LLM Hallucination Detection + methodology.md §LLM Hallucination Detection（扩展 2026-04-21）

# 代码审计师 — LLM 代码审查特有挑战

## 幻觉检测（Hallucination Detection）

LLM 生成的代码有一种人类代码很少见的失败模式：自信地调用不存在的 API 方法，语法看起来合理，编译通过，lint 通过，仅在运行时失败。

### 检测协议

对于任何不立即 recognizable 为标准常用 API 的库方法调用：

1. **Grep 代码库**：搜索相同库的其他用法，比较模式
2. **Grep lock 文件**：确认库版本
3. **如果无法验证**：标记 `[HALLUCINATION-RISK]`，建议人工验证

```
BAD: "The code calls `requests.post_json(url, data)` — this looks right to me."
→ `requests.post_json` does not exist. The correct method is `requests.post(url, json=data)`.

GOOD: "Cannot verify `post_json` exists. Existing usages in codebase use `requests.post(url, json=...)`. [HALLUCINATION-RISK] Recommend human verification."
```

### 常见幻觉模式

**方法名幻觉**：
```python
# BAD — 幻觉
prisma.user.upsertMany(...)  # upsertMany 不存在
requests.post_json(...)       # post_json 不存在
sqlalchemy.insert_many(...)   # insert_many 不存在（正确：session.bulk_insert_mappings）

# GOOD — 验证后
grep -r "upsertMany" .        # 无结果 → HALLUCINATION-RISK
grep -r "post_json" .         # 无结果 → HALLUCINATION-RISK
```

**参数顺序幻觉**：
```python
# BAD — 参数顺序错误（LLM 经常混淆）
jwt.encode(payload, algorithm="HS256", key=secret)
# 正确顺序：jwt.encode(payload, key, algorithm="HS256")

# BAD — 使用了另一个库的 API
axios.post(url, { headers, data })  # axios 参数顺序是 (url, data, config)
```

**版本漂移幻觉**：
```python
# BAD — 使用了训练数据中较新版本的 API
# React Query v5: useQuery({ queryKey, queryFn })
# 但代码库使用 v4: useQuery(queryKey, queryFn)
# LLM 可能生成 v5 语法而代码库是 v4

# 检测：grep package.json 或 yarn.lock 确认版本
grep "@tanstack/react-query" package.json yarn.lock
```

### 幻觉检测检查清单

对于每个 diff 中的外部库调用：

- [ ] 方法名在代码库其他位置有使用吗？
- [ ] 参数顺序与代码库现有用法一致吗？
- [ ] 库版本与调用语法匹配吗？（v4 vs v5 API 差异）
- [ ] 返回值处理方式与代码库模式一致吗？
- [ ] 如果是新引入的库调用，能验证方法存在吗？

---

## API 存在性验证流程

### Step 1: 代码库内搜索

```bash
# 搜索相同库的其他用法
grep -rn "prisma\.user\." src/ --include="*.ts"
grep -rn "requests\." src/ --include="*.py"

# 搜索 lock 文件确认版本
grep "prisma" package-lock.json yarn.lock
pip show prisma  # Python
```

### Step 2: 版本匹配验证

```bash
# Node.js
cat package.json | grep -A2 "prisma"
cat yarn.lock | grep -A5 "prisma@"

# Python
pip freeze | grep -i prisma
pip show prisma | grep Version

# Go
cat go.mod | grep prisma
cat go.sum | grep prisma

# Rust
cat Cargo.toml | grep -A2 "sqlx"
cat Cargo.lock | grep -A3 "name = \"sqlx\""
```

### Step 3: 文档交叉验证

如果代码库内无现有用法：
1. 确认库版本
2. 查阅该版本的官方文档（不是通用知识）
3. 如果无法访问文档 → `[HALLUCINATION-RISK]`

---

## Scheme Drift 检测

**定义**：实现与 @dev-lead 技术方案在多次修改周期中逐渐偏离，每次偏离很小，累积后实现与方案描述的是两个不同系统。

### 检测方法

**Round 1 基线建立**：
- 记录方案中的关键接口定义：字段名、类型、必填/可选、验证规则
- 记录 HTTP 状态码和错误码映射
- 记录 In-scope 文件列表

**Round N 对比**：
- 重新读取原始方案（不要凭记忆）
- 逐字段对比实现是否与方案一致
- 检查是否有 "小调整" 累积成重大偏离

### 常见 Drift 模式

| 轮次 | 变化 | 是否更新方案 |
|---|---|---|
| Round 1 | 实现完全符合方案 | — |
| Round 2 | 修复 bug：将 `expires_at` 从 Unix timestamp 改为 ISO8601 | 否 |
| Round 3 | 新增字段 `invite_code`（"客户要求的"） | 否 |
| Round 4 | 修改错误码：`ALREADY_REGISTERED` → `USER_EXISTS` | 否 |
| Round 5 | 实现与原始方案已不一致，但无人记得何时开始偏离 | — |

### Drift 检测检查清单

- [ ] 字段名是否与方案完全一致？（包括大小写）
- [ ] 字段类型是否匹配？（string vs number vs datetime）
- [ ] 必填/可选标记是否一致？
- [ ] HTTP 状态码是否与方案一致？
- [ ] 错误码枚举值是否与方案一致？
- [ ] 新增字段是否有方案依据？
- [ ] 修改的接口是否有 @dev-lead 确认？

---

## 安全审查深度增强

### 认证架构审查（超越表面扫描）

当 @code-review 发现以下模式时，标记为 ESCALATE 到 @security-auditor：

**JWT 实现缺陷**：
```python
# BAD — 未指定算法
jwt.decode(token, key)  # 缺少 algorithms 参数

# BAD — 接受 alg:none
jwt.decode(token, key, algorithms=["HS256", "none"])

# BAD — 从 token 中读取角色
user_role = payload["role"]  # 角色应在服务端查询，不从 token 读取
```

**IDOR 模式**：
```python
# BAD — 直接查询，无权限检查
@app.get("/orders/{order_id}")
def get_order(order_id: int):
    return db.query(Order).filter(Order.id == order_id).first()
    # 任何登录用户都能查看任意订单

# GOOD — 权限检查
@app.get("/orders/{order_id}")
def get_order(order_id: int, current_user: User = Depends(get_current_user)):
    order = db.query(Order).filter(Order.id == order_id).first()
    if order.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
    return order
```

**会话管理缺陷**：
```python
# BAD — 会话固定
session["user_id"] = user_id  # 登录前后 session ID 不变

# BAD — 无 HttpOnly
cookies.set("session", session_id)  # 缺少 HttpOnly，XSS 可窃取

# BAD — 无 SameSite
cookies.set("session", session_id)  # 缺少 SameSite，CSRF 风险
```

### 依赖 CVE 快速检查

```bash
# Python
pip-audit --requirement requirements.txt --format=json

# Node.js
npm audit --json

# Go
go list -json -m all | nancy sleuth

# 关键库版本手动检查
pip show pyjwt cryptography django | grep Version
npm list pyjwt jsonwebtoken bcrypt
```

### 供应链安全检查

```bash
# 检查是否有依赖使用 git 协议（可能被劫持）
grep -E "git\+ssh|git\+https" package.json requirements.txt

# 检查 lock 文件完整性
npm ci --dry-run  # 验证 lock 文件与 package.json 一致

# 检查是否有未锁定版本的依赖
# package.json 中 "^1.0.0" 是正常范围，但 "*" 或 ">=1.0.0" 是高风险
```

---

## 审查输出质量检查

### Finding 质量评估

每个 finding 必须通过以下检查：

- [ ] **定位精确**：包含 file:line 引用
- [ ] **证据完整**：包含 exact code snippet
- [ ] **解释清晰**：说明为什么这是问题
- [ ] **修复方向**：给出具体修复建议（不是 "fix this"）
- [ ] **严重程度准确**：反映实际风险，不是个人偏好

### 审查报告自检

提交前自检：

- [ ] 是否运行了安全基线扫描？（SQL/XSS/Secrets/Validation/Logging）
- [ ] 是否检查了幻觉风险？（所有不熟悉的库调用）
- [ ] 是否对比了方案 In-scope 文件列表？
- [ ] 是否验证了接口契约？（字段、类型、状态码）
- [ ] 是否检查了测试覆盖？（每个变更函数是否有对应测试）
- [ ] APPROVED  verdict 是否有详细依据？
- [ ] CHANGES REQUESTED 是否有明确的 must-fix 列表？
- [ ] ESCALATE 是否有具体原因和安全影响说明？
