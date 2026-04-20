> 源：core.md §Phase 6 Compliance + compliance.md（扩展 2026-04-21）

# 安全审计师 — 合规检查深度指南

## GDPR（通用数据保护条例）

### 适用范围
处理欧盟居民个人数据的任何系统。

### 审计检查清单

| 要求 | 审计检查 | 违反时 Finding |
|---|---|---|
| 合法基础 | 系统是否记录处理同意或其他合法基础？ | HIGH |
| 数据最小化 | 是否仅收集必要的 PII？ | MEDIUM |
| 删除权 | 是否有用户数据删除/匿名化路径？ | HIGH |
| 数据泄露通知 | 系统能否在 72 小时内检测并报告泄露？ | HIGH |
| 数据可携带 | 用户数据能否以机器可读格式导出？ | MEDIUM |
| 隐私设计 | 隐私控制是内置的还是后加的？ | MEDIUM |
| 数据传输 | PII 传出欧盟需要充分性决定或 SCC | HIGH |
| DPIA | 高风险处理是否进行了数据保护影响评估？ | HIGH |

### PII 字段映射模板

```
数据库表/字段 PII 映射：

表: users
├── email → PII (基本标识)
├── phone → PII (基本标识)
├── id_card → 特殊类别 (敏感)
├── address → PII (基本标识)
└── ip_address → PII (大多数情况下)

表: orders
├── customer_name → PII
├── shipping_address → PII
└── payment_token → 非 PII（如果正确 tokenized）

审计动作：
1. 列出所有包含 PII 的数据库表/字段
2. 验证每个都有记录的合法基础
3. 验证特殊类别数据有加密存储
4. 测试删除路径：创建账户 → 删除账户 → 验证数据已清除
5. 检查 analytics/logging 未经同意不捕获 PII
```

### GDPR 审计输出

```markdown
## GDPR Compliance Assessment

**适用性理由**: [系统处理欧盟用户数据]
**评估范围**: [用户管理、订单处理、邮件营销模块]

| 控制项 | 要求 | 状态 | 证据/Finding |
|---|---|---|---|
| LAW-01 | 记录处理同意 | PASS | 同意记录在 user_consents 表，含时间戳和版本 |
| LAW-02 | 数据最小化 | FINDING #1 | orders 表收集生日（非必需） |
| DEL-01 | 删除权实现 | PASS | /api/users/me DELETE 端点存在，30 天内清除 |
| BRE-01 | 泄露检测能力 | FINDING #2 | 无自动化泄露检测，依赖人工发现 |

**合规裁决**: CONDITIONALLY COMPLIANT (pending #1, #2)

**需要合规特定修复的发现**：
- FINDING #1 (MEDIUM): 从 orders 表移除 birth_date 字段，或记录收集合法基础
- FINDING #2 (HIGH): 实施 SIEM 规则检测异常数据访问模式

**建议下一步**：
1. 修复 FINDING #2（当前 sprint）
2. 修复 FINDING #1（下个 sprint）
3. 安排季度 GDPR 复测
```

---

## 等保 2.0（中国网络安全等级保护）

### 等级 2 基线要求（商业应用）

| 控制域 | 关键要求 | 审计方法 |
|---|---|---|
| 身份鉴别 | 管理员多因素认证；密码复杂度要求 | 检查 admin 登录流程 |
| 访问控制 | 最小权限；基于角色的访问；特权账户审查 | 检查 RBAC 实现 |
| 安全审计 | 所有管理员操作的审计日志；日志完整性保护 | 检查审计日志覆盖 |
| 入侵防范 | 输入验证；限流；生产环境 IDS/WAF | 检查 WAF 配置 |
| 数据完整性 | 传输加密（TLS）；需要时数据签名 | 检查 TLS 版本 |
| 数据保密性 | 敏感数据静态和传输加密 | 检查加密实现 |

### 等级 3 增补（关键基础设施、金融、医疗）

- 合格机构的独立安全评估
- 实时安全监控（SOC 能力）
- 业务连续性和灾难恢复计划
- 年度渗透测试

### 等保常见发现

| 发现 | 严重程度 | 修复建议 |
|---|---|---|
| 特权账户（admin/root）无 MFA | HIGH | 强制所有管理员 MFA |
| 数据库管理员无职责分离 | HIGH | 分离 DBA 和应用管理员角色 |
| 审计日志与被审计系统同机存储 | MEDIUM | 日志转发到独立日志服务器 |
| 无日志保留策略或日志保留 < 6 个月 | MEDIUM | 实施 12 个月日志保留 |
| 未启用登录失败告警 | MEDIUM | 实施 SIEM 告警规则 |

### 等保审计输出

```markdown
## 等保 2.0 合规评估

**评估等级**: 等级 2
**系统范围**: [系统名称和边界]

| 控制域 | 要求 | 状态 | 证据 |
|---|---|---|---|
| 身份鉴别 | 管理员 MFA | FINDING #1 | admin 账户仅密码认证 |
| 访问控制 | 最小权限 | PASS | RBAC 已实施， quarterly 审查 |
| 安全审计 | 审计日志完整性 | PASS | 日志签名 + WORM 存储 |
| 入侵防范 | WAF 部署 | FINDING #2 | 生产环境无 WAF |
| 数据完整性 | TLS 1.2+ | PASS | 全站 TLS 1.3 |
| 数据保密性 | 敏感数据加密 | PASS | AES-256-GCM 静态加密 |

**合规裁决**: NON-COMPLIANT (2 HIGH findings)

**修复计划**：
1. FINDING #1: 实施管理员 MFA（当前 sprint）
2. FINDING #2: 部署 WAF（当前 sprint）
```

---

## HIPAA（健康保险可携性和责任法案）

### 适用范围
处理美国患者受保护健康信息（PHI）的系统。

### PHI 定义
任何可识别个人的健康信息：姓名 + 诊断、病历号、设备标识符等。

### 关键要求

| HIPAA 保障 | 审计检查 |
|---|---|
| 传输加密 | TLS 1.2+ 用于所有 PHI 传输 |
| 静态加密 | AES-256 用于 PHI 数据库字段 |
| 访问控制 | 基于用户的访问 + 审计日志 |
| 审计控制 | 谁访问了什么 PHI 以及何时 |
| 完整性控制 | PHI 未经授权不得更改 |
| BAA | 与所有 PHI 处理者的商业伙伴协议 |

### BAA 检查

```bash
# 检查第三方服务是否处理 PHI
grep -rn "sendgrid\|mailgun\|aws ses" --include="*.py" --include="*.ts" .
# 每个处理 PHI 的第三方服务必须有 BAA

# 检查云存储
grep -rn "s3://\|gs://\|azure://" --include="*.py" --include="*.ts" .
# 存储 PHI 的 bucket 必须加密 + 访问日志
```

### HIPAA 审计输出

```markdown
## HIPAA Compliance Assessment

**适用性理由**: [系统处理患者健康数据]
**PHI 范围**: [患者姓名、诊断、处方记录]

| 保障 | 要求 | 状态 | 证据 |
|---|---|---|---|
| 传输加密 | TLS 1.2+ | PASS | 全站 TLS 1.3 |
| 静态加密 | AES-256 | PASS | 数据库字段级加密 |
| 访问控制 | 基于用户 | PASS | RBAC + 最小权限 |
| 审计控制 | 访问日志 | FINDING #1 | PHI 访问未记录到独立审计系统 |
| 完整性 | 防篡改 | PASS | 数据库行级校验和 |
| BAA | 第三方协议 | FINDING #2 | SendGrid 邮件服务无 BAA |

**合规裁决**: NON-COMPLIANT (2 findings)

**修复计划**：
1. FINDING #1: 实施 PHI 访问审计日志（当前 sprint）
2. FINDING #2: 与 SendGrid 签署 BAA 或切换到有 BAA 的提供商
```

---

## PCI-DSS（支付卡行业数据安全标准）

### 适用范围
处理、存储或传输持卡人数据的任何系统。

### 关键要求

| PCI 要求 | 审计检查 |
|---|---|
| 3.2: 永不存储 CVV | 搜索代码库和数据库 schema 中的 CVV/CVV2/CVC 字段 |
| 3.4: PAN 显示时脱敏 | 任何显示中仅显示最后 4 位 |
| 4.1: TLS 1.2+ 传输 | 所有端点的 TLS 版本检查 |
| 6.5: 安全编码（OWASP） | 注入、认证绕过、XSS 代码审计 |
| 7: 限制持卡人数据访问 | 最小权限 RBAC，季度审查 |
| 8: 强认证 | 所有管理员访问的 MFA |
| 10.2: 持卡人数据访问审计 | 记录每次 PAN 数据读取 |

### CVV 存储检查

```bash
# 搜索数据库 schema
grep -rn "cvv\|cvc\|cvv2\|card_verification" migrations/ schema/ --include="*.sql"

# 搜索源代码中的任何存储路径
grep -rn "cvv\|cvc\|cvv2" --include="*.py" --include="*.js" --include="*.ts" .
# 发现：任何将 CVV 存储到数据库的结果 = CRITICAL，立即 BLOCKED
```

### 范围最小化建议

使用 Stripe/Braintree/Adyen tokenization。这些服务存储卡数据；你的系统只存储 token。
Tokenization 大幅缩小 PCI-DSS 范围。

---

## 合规审计通用输出格式

```markdown
## [Framework] Compliance Assessment

**适用性理由**: [为什么此框架适用]
**评估范围**: [评估了系统的哪些部分]

| 控制项 | 要求 | 状态 | 证据 / Finding |
|---|---|---|---|
| [ID] | [描述] | PASS / FINDING #N / NOT APPLICABLE | [证据或 finding 引用] |

**合规裁决**: COMPLIANT / CONDITIONALLY COMPLIANT (pending #N) / NON-COMPLIANT

**需要合规特定修复的发现**：
[List findings that, if unaddressed, create regulatory risk]

**建议下一步**：
[Prioritized actions for compliance gap closure]

**复测计划**：
- [ ] [复测项 1]
- [ ] [复测项 2]
```
