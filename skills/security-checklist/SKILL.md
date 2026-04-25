---
name: security-checklist
description: 安全审查清单。为 security-auditor 和 code-reviewer 提供系统化的安全检查方法，覆盖 OWASP Top 10 和常见漏洞模式。
when_to_use: 当 security-auditor / code-reviewer 审查认证、授权、输入验证、注入、敏感数据处理、依赖风险时；用户提"安全审查"、"OWASP"、"漏洞"、"鉴权"、"权限"、"SQL 注入"、"XSS"、"CSRF" 时自动加载。
---

# 安全审查清单

审查代码时的对抗性思维框架：**假设攻击者会做 X，代码能抵御吗？**

---

## 1. 注入攻击

### SQL 注入
检查方式：grep 查找字符串拼接到 SQL 的模式
```regex
`SELECT.*\$\{|"SELECT.*" \+ |execute\(.*f"SELECT|raw\(.*\$\{
```

✗ 错误：`db.query("SELECT * FROM users WHERE id = " + userId)`
✓ 正确：`db.query("SELECT * FROM users WHERE id = ?", [userId])`

### 命令注入
```regex
`exec\(.*\$\{|shell\(.*\+|os\.system\(.*f"|subprocess.*shell=True
```

✗ 错误：`exec("ping " + userInput)`
✓ 正确：`execFile("ping", [userInput])` 或白名单验证

### NoSQL 注入
MongoDB 等：操作符注入（`{ $ne: null }`）

✗ 错误：直接使用 `req.body` 作为 find 条件
✓ 正确：对字段和操作符做白名单

### LDAP / XPath 注入
类似 SQL 注入，使用参数化查询或转义

---

## 2. 身份和访问控制

### 认证绕过
- 所有需要认证的端点都有认证中间件
- JWT / session 验证正确（签名、过期、撤销）
- 记住我功能安全（长期 token 的存储和撤销）

### 授权失守（IDOR / 权限提升）
- 操作资源前检查所有权：用户 A 不能修改用户 B 的资源
- 角色检查在业务逻辑**之前**，不是**之后**
- 批量操作的权限检查逐项进行

### 密码
✗ MD5 / SHA-1 / 明文
✓ bcrypt / argon2 / scrypt，适当 cost
- 密码最小复杂度要求
- 密码比较用恒定时间函数

---

## 3. 敏感数据暴露

### 硬编码凭证
检查方式：grep 常见密钥模式
```regex
`(api[_-]?key|secret|token|password|pwd)\s*[=:]\s*["'][\w\-]{16,}`
```

✗ 错误：`const API_KEY = "sk-abc123..."`
✓ 正确：`const API_KEY = process.env.API_KEY`

### 日志泄露
- 密码、token、身份证、银行卡不得进入日志
- PII 必须脱敏（姓名、手机、邮箱、地址）

### 错误信息泄露
- 生产环境不返回堆栈
- 不暴露内部路径、数据库结构、版本信息
- 统一错误响应格式，避免通过错误差异探测

### 传输安全
- HTTPS 强制（HSTS）
- 敏感 cookie：`Secure`, `HttpOnly`, `SameSite`
- API token 不放 URL（Query String 会进日志）

---

## 4. XSS（跨站脚本）

### 存储型 / 反射型
- 所有用户输入在输出时转义
- React / Vue 默认已转义，但 `dangerouslySetInnerHTML` / `v-html` 绕过
- Cookie `HttpOnly` 防止 JS 读取

### DOM XSS
- 不把用户输入直接赋给 `innerHTML`、`outerHTML`
- `eval`、`Function` 构造器禁用
- `window.location`、`window.open` 参数不得为用户输入

### CSP
- 设置 Content-Security-Policy
- 限制 `script-src`、`style-src`

---

## 5. CSRF

- 状态改变操作（POST/PUT/DELETE）要求 CSRF token
- 或使用 `SameSite=Strict/Lax` cookie
- GET 不应有副作用

---

## 6. SSRF

- 禁止用户输入决定后端 HTTP 请求的目标
- 如必须，使用域名白名单
- 禁止访问内部 IP（127.x、10.x、172.16-31.x、192.168.x、169.254.x）
- 云环境：禁用 169.254.169.254（元数据端点）

---

## 7. XXE

- XML 解析器禁用外部实体
  ```python
  # Python
  from defusedxml import ElementTree
  # 或
  parser = etree.XMLParser(resolve_entities=False, no_network=True)
  ```

---

## 8. 反序列化漏洞

- 禁止反序列化不可信数据（pickle、Java 序列化、PHP unserialize）
- JSON 解析是安全的（相对而言）
- YAML 使用 `safe_load`

---

## 9. 依赖安全

- 检查 `package-lock.json` / `poetry.lock` / `Gemfile.lock` / `go.sum`
- 运行 `npm audit` / `pip-audit` / `cargo audit`
- 第三方依赖版本不应过旧
- 许可证合规（GPL 等 copyleft 对商业项目可能有影响）

---

## 10. 日志与监控

- 安全事件有日志：失败登录、权限拒绝、异常操作
- 日志保留期满足合规（GDPR、等保）
- 异常行为有告警

---

## 特定场景

### 文件上传
- [ ] 文件类型白名单（不信任 Content-Type，检查文件头 magic number）
- [ ] 文件大小限制
- [ ] 重命名（不用用户提供的文件名）
- [ ] 存储位置隔离（不要放在可 web 访问的目录）
- [ ] 病毒扫描（敏感场景）

### 密码重置
- [ ] Token 单次使用、有过期
- [ ] Token 与用户绑定
- [ ] 不通过 Referrer 泄露
- [ ] 密码重置通知到邮箱

### 支付
- [ ] 金额不从前端传递，从订单 ID 查询
- [ ] 支付状态由服务端回调确认，不信任前端
- [ ] 幂等性（重复支付处理）
- [ ] 退款权限严格控制

### API 限流
- [ ] 敏感端点（登录、注册、密码重置）有限流
- [ ] 基于 IP + 用户的组合限流

---

## 审查产出

对每条发现按严重性归类：

- **Critical**：可被立即利用的漏洞（注入、认证绕过、敏感数据泄露）
- **High**：可能被利用的漏洞（权限失守、CSRF）
- **Medium**：增加攻击面的问题（缺少 CSP、过期依赖）
- **Low**：最佳实践建议（日志格式、错误处理细节）

Critical 和 High 必须在"Critical"或"Warning"区块列出，不能放"Suggestion"。
