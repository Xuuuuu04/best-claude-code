# Domain 2: 文档类型精通

## 2.1 API 文档（OpenAPI 3.1 标准）

### 端点规范模板

每个端点文档必须包含：

```markdown
## [HTTP Method] [Path]

**Summary**: [一句话描述这个端点做什么]

**Description**: [更详细的描述，包括业务规则、限制、注意事项]

### Parameters

| Name | In | Required | Type | Description | Example |
|------|-----|----------|------|-------------|---------|
| [param] | path/query/header | Yes/No | string/integer | [description] | [example] |

### Request Body

**Content-Type**: `application/json`

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| [field] | string | Yes | Min: 1, Max: 100 | [description] |

**Example**:
```json
{
  "field": "value"
}
```

### Responses

#### [Status Code] [Status Name]
**Description**: [什么时候返回这个状态]

**Response Body**:
| Field | Type | Description |
|-------|------|-------------|
| [field] | string | [description] |

**Example**:
```json
{
  "field": "value"
}
```

#### Error Responses
| Status | Error Code | Description | Resolution |
|--------|------------|-------------|------------|
| 400 | VALIDATION_ERROR | Request body failed validation | Check required fields and formats |
| 401 | UNAUTHORIZED | Invalid or missing authentication | Verify Authorization header |
| 404 | NOT_FOUND | Resource does not exist | Check resource ID |
```

### Security
- **Authentication**: [Bearer Token / API Key / OAuth2]
- **Required Scopes**: [scope list]
```

### 错误码表规范

错误码表是 API 文档中引用频率最高的部分之一，必须完整且易查找：

```markdown
## Error Code Reference

| Error Code | HTTP Status | Title | When It Occurs | Resolution | Example Response |
|------------|-------------|-------|----------------|------------|------------------|
| `INVALID_COUNTRY` | 400 | Invalid country code | The provided country code is not supported | Use ISO 3166-1 alpha-2 country codes | `{"error": "INVALID_COUNTRY", "message": "Country 'XX' is not supported"}` |
| `VALIDATION_ERROR` | 422 | Validation failed | Request body failed schema validation | Check the `details` array for specific field errors | `{"error": "VALIDATION_ERROR", "details": [{"field": "email", "message": "Invalid email format"}]}` |
| `PRODUCT_UNAVAILABLE` | 409 | Product out of stock | The requested product is not available | Check product availability before ordering | `{"error": "PRODUCT_UNAVAILABLE", "product_id": "prod-001"}` |
| `RATE_LIMIT_EXCEEDED` | 429 | Rate limit exceeded | Too many requests | Wait and retry; check `Retry-After` header | `{"error": "RATE_LIMIT_EXCEEDED", "retry_after": 60}` |
| `INTERNAL_ERROR` | 500 | Internal server error | Unexpected server error | Retry the request; if persists, contact support | `{"error": "INTERNAL_ERROR", "request_id": "req-abc123"}` |
```

**错误码表要求**：
- 机器可读的错误码（大写下划线格式）
- HTTP 状态码映射
- 人类可读的标题
- 详细描述（何时发生）
- 解决方案指导（如何修复）
- 示例响应体

### 认证文档规范

```markdown
## Authentication

### Obtaining Credentials
1. [Step 1: How to get API key/token]
2. [Step 2: How to generate/refresh]

### Using Credentials
Include the token in the `Authorization` header:
```
Authorization: Bearer {your-token}
```

### Token Lifecycle
- **TTL**: [Duration, e.g., "24 hours"]
- **Refresh**: [How to refresh before expiry]
- **Invalid Token Response**: [What happens when token is invalid]

### Security Notes
- Never commit tokens to version control
- Use environment variables for token storage
- Rotate tokens regularly
```

---

## 2.2 学术论文（IMRaD 结构）

### IMRaD 详解

**Introduction（引言）**
- 问题陈述：研究领域和具体问题
- 现有工作的 gap：文献综述的关键发现
- 贡献声明：编号列表，明确说明本文贡献
- 论文组织结构

**Methods（方法）**
- 精确到可复现
- 数据来源和收集方法
- 分析方法和工具
- 伦理声明（如适用）

**Results（结果）**
- 仅描述性，无解释
- 使用表格和图表展示数据
- 所有图表有编号、标题、文中引用

**Discussion（讨论）**
- 解释结果含义
- 与 baseline/现有工作比较（具体数字）
- 明确承认局限性
- 未来工作方向

### 引用规范

- 每个关于先前工作的事实声明必须有引用
- 每个比较（"我们的方法优于 [X]"）必须在首次提及 [X] 时引用
- 格式遵循目标期刊/会议的样式指南

### 图表标准

**图表**：
- 编号（Figure 1, Figure 2）
- 标题（在图表下方，能独立理解）
- 文中在出现前引用（"如图 1 所示..."）
- 坐标轴标签带单位

**表格**：
- 编号（Table 1, Table 2）
- 标题（在表格上方）
- 列标题带单位
- 对齐方式一致

---

## 2.3 部署指南

### 先决条件完整性检查

部署指南的先决条件必须具体到版本号：

```markdown
## Prerequisites

### System Requirements
- **OS**: Ubuntu 22.04 LTS (tested on 22.04.3)
- **Docker**: >= 24.0.0
- **Docker Compose**: >= 2.20.0
- **CPU**: 2 cores minimum, 4 cores recommended
- **RAM**: 4GB minimum, 8GB recommended
- **Disk**: 20GB free space minimum

### Network Requirements
- **Port 80**: HTTP traffic
- **Port 443**: HTTPS traffic
- **Port 8080**: Admin dashboard (internal)
- **Outbound**: Access to Docker Hub, package repositories

### DNS Records
| Record Type | Name | Value | TTL |
|-------------|------|-------|-----|
| A | @ | [server IP] | 300 |
| A | www | [server IP] | 300 |
| CNAME | api | [server domain] | 300 |

### TLS Certificates
- Obtain certificates from Let's Encrypt or your CA
- Place fullchain.pem and privkey.pem in `/etc/ssl/certs/`

### External Service Credentials
| Service | Purpose | How to Obtain |
|---------|---------|---------------|
| Stripe | Payment processing | https://dashboard.stripe.com/apikeys |
| SendGrid | Email delivery | https://app.sendgrid.com/settings/api_keys |
| AWS S3 | File storage | https://console.aws.amazon.com/iam/ |
```

### 故障排查结构

每个故障排查条目必须包含：

```markdown
## Troubleshooting

### `[Exact error message text]`
**Symptom**: [What the user sees]
**Cause**: [Why this happens]
**Fix**:
```bash
# Exact command to run
```
**Verification**: [How to confirm the fix worked]
```

**示例**：
```markdown
### `Error: connect ECONNREFUSED 127.0.0.1:5432`
**Symptom**: Application fails to start with database connection error
**Cause**: PostgreSQL container is not running or port is not exposed
**Fix**:
```bash
# Check if PostgreSQL container is running
docker ps | grep postgres

# If not running, start it
docker compose up -d postgres

# Verify port is accessible
nc -zv localhost 5432
```
**Verification**: Run `docker compose logs postgres` — should show "database system is ready"
```

### 回滚步骤

每个部署指南必须包含回滚步骤：

```markdown
## Rollback

If deployment fails, follow these steps to restore the previous version:

1. **Stop the new version**:
   ```bash
   docker compose down
   ```

2. **Restore the previous image**:
   ```bash
   docker pull myapp:v[previous-version]
   ```

3. **Update docker-compose.yml to previous version**:
   ```bash
   sed -i 's/myapp:v[new]/myapp:v[previous]/' docker-compose.yml
   ```

4. **Restart with previous version**:
   ```bash
   docker compose up -d
   ```

5. **Verify rollback**:
   ```bash
   curl -sf https://example.com/health | jq .status
   # Expected: "healthy"
   ```

**Rollback Time**: ~5 minutes
**Data Loss Risk**: None (database migrations are backward-compatible)
```

---

## 2.4 用户手册

### 任务导向结构

用户手册的章节名必须是任务导向：

```
BAD:
- "Project Module"
- "User Management Feature"
- "Settings Page"

GOOD:
- "Create a New Project"
- "Add Team Members"
- "Configure Notification Preferences"
```

### 步骤编写规范

每个任务必须包含：

```markdown
## [Task Name]

**Goal**: [What the user will accomplish]
**Time**: [Estimated time]
**Prerequisites**: [What must be done first]

### Steps

1. [Step 1 — 动作]
   **Expected**: [What should happen]
   
2. [Step 2 — 动作]
   **Expected**: [What should happen]

3. [Step 3 — 动作]
   **Expected**: [What should happen]

### Troubleshooting

**Problem**: [What might go wrong]
**Solution**: [How to fix it]

### Next Steps
- [Related task 1]
- [Related task 2]
```

**步骤数量规则**：
- 每个任务 ≤ 7 个步骤
- 如果超过 7 步，拆分为子任务
- 每个步骤一个动作（不要在一个步骤中混合多个动作）

---

## 2.5 里程碑报告

### 执行摘要结构

执行摘要必须在一页内回答：

```markdown
## Executive Summary

### Decisions Required
1. [Decision 1 — what, from whom, by when]
2. [Decision 2 — what, from whom, by when]

### Key Metrics
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| [Metric 1] | [Target] | [Actual] | [On Track / At Risk / Off Track] |

### Key Risks
| Risk | Impact | Mitigation | Status |
|------|--------|------------|--------|
| [Risk 1] | [High/Med/Low] | [Action] | [Active / Mitigated] |

### Next Period Commitments
- [Commitment 1 — owner — date]
- [Commitment 2 — owner — date]
```

### 风险描述格式

风险必须使用 "如果-则-当" 格式：

```
BAD:
"We might have a delay."

GOOD:
"If the third-party API integration takes longer than 3 days (probability: 60%), then the Phase 2 delivery will slip by 1 week, impacting the client demo scheduled for June 15."
```
