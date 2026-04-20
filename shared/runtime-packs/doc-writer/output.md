# 文档工程师 — Output Contract

## 标准输出模板

### 文档交付模板

```
## Documentation Delivery: [Document Type]

**Document**: [Title] | **Reader Persona**: [role + goal] | **Version**: v[X.Y] — [YYYY-MM-DD]
**Document Type (Diátaxis)**: [Tutorial / How-to / Reference / Explanation / Mixed]
**Archive Path**: docs/[category]/[filename]-v[version].md
**Source Materials Used**: [file → sections it informs]
**Known Gaps / BLOCKED Sections**: [Section — missing item — responsible @agent] / (none)
**Next Steps**: [@pm / @client / User]
```

---

## 输出组件详解

### 1. 文档头部规范

每个文档必须以以下格式开头：

```markdown
# [Document Title] v[MAJOR.MINOR] — [YYYY-MM-DD]

**Reader Persona**: [Specific role and goal]
**Document Type**: [Diátaxis quadrant]
**Last Updated**: [YYYY-MM-DD]
**Source Materials**: [List of source files/agents]
```

**版本号规则**：
- **MAJOR (x.0.0)**: 文档重构、目标读者变更、记录系统有 breaking changes
- **MINOR (0.x.0)**: 新增章节、重大改写、新增端点/功能
- **PATCH (0.0.x)**: 错别字修正、澄清说明、不影响含义的修改

---

### 2. 文档类型结构模板

#### API 文档结构（OpenAPI 3.1 标准）

```
# [API Name] API Documentation v[X.Y] — [Date]

## 1. Overview
- API 用途（1-2 句）
- 基础 URL
- 版本策略

## 2. Authentication
- 如何获取凭证
- 请求头格式: `Authorization: Bearer {token}`
- Token TTL 和刷新流程
- 凭证无效时的行为

## 3. Quick Start
- 第一个 API 调用（完整可运行示例）
- 预期输出

## 4. Endpoint Reference
### 4.1 [Resource Name]
#### [HTTP Method] [Path]
- Summary: [一句话描述]
- Description: [详细描述]
- Parameters: [表格: name, in, required, type, description, example]
- Request Body: [表格: field, type, required, constraints, description]
- Responses: [表格: status, description, body schema, example]
- Security: [required scopes/permissions]

## 5. Error Code Table
| Error Code | HTTP Status | Title | Description | Resolution | Example |
|---|---|---|---|---|---|
| [CODE] | [status] | [title] | [when this occurs] | [how to fix] | [example response] |

## 6. SDK Examples
- [Language 1]: [完整示例]
- [Language 2]: [完整示例]

## 7. Rate Limits
| Endpoint | Limit | Window | Exceed Behavior |
|---|---|---|---|

## 8. Changelog
- v[X.Y] [Date]: [What changed]
```

#### 用户手册结构

```
# [Product Name] User Manual v[X.Y] — [Date]

**Reader Persona**: [End user who wants to accomplish tasks]

## 1. Getting Started
- 产品简介
- 系统要求
- 首次登录

## 2. Key Concepts
- [概念 1]: [解释]
- [概念 2]: [解释]

## 3. Task Guides
### 3.1 [Task Name]
1. [Step 1]
2. [Step 2]
3. [Step 3]
**Expected Result**: [What should happen]
**Troubleshooting**: [What to do if it doesn't work]

## 4. FAQ
| Question | Answer |
|---|---|

## 5. Troubleshooting
| Symptom | Cause | Solution |
|---|---|---|

## 6. Glossary
| Term | Definition |
|---|---|
```

#### 部署指南结构

```
# [System Name] Deployment Guide v[X.Y] — [Date]

**Reader Persona**: [Operations engineer deploying to production]

## 1. Prerequisites
- OS: [Specific version, e.g., "Ubuntu 22.04 LTS"]
- Docker: [Specific version, e.g., ">= 24.0"]
- Ports: [List required ports]
- DNS: [Required records]
- TLS: [Certificate requirements]
- Credentials: [How to obtain each required credential]
- Resources: [Minimum CPU/RAM/Disk]

## 2. Installation
### 2.1 [Component 1]
```bash
# Exact commands
```
### 2.2 [Component 2]
...

## 3. Configuration
| Setting | Default | Description | Required? |
|---|---|---|---|

## 4. Verification
```bash
# Commands to verify successful deployment
```

## 5. Troubleshooting
| Error Message | Cause | Fix |
|---|---|---|
| `[exact error text]` | [why] | `[exact command]` |

## 6. Rollback
```bash
# Exact rollback procedure
```

## 7. Maintenance
- Backup procedure
- Update procedure
- Monitoring checklist
```

#### 论文 IMRaD 结构

```
# [Paper Title] v[X.Y] — [Date]

## 1. Introduction
- Problem statement
- Gap in existing work
- Contribution claims (numbered list)
- Paper organization

## 2. Methods
- [Precise enough for replication]
- [Data sources]
- [Analysis approach]

## 3. Results
- [Descriptive only, no interpretation]
- [Tables and figures with numbers]

## 4. Discussion
- [Interpret results]
- [Compare to baselines with specific numbers]
- [Acknowledge limitations explicitly]
- [Future work]

## References
- [Every factual claim about prior work cited]
- [Venue-specific format]
```

#### 里程碑报告结构

```
# [Project Name] Milestone Report v[X.Y] — [Date]

**Reader Persona**: [Executive who needs to decide what to do next]

## 1. Executive Summary
- [Decision-required items first]
- [Key metrics in absolute numbers]

## 2. Deliverables Completed
| Deliverable | Status | Evidence | Notes |
|---|---|---|---|

## 3. Metrics / KPIs
| Metric | Target | Actual | Variance |
|---|---|---|---|

## 4. Risks and Blockers
| Risk | Probability | Impact | Mitigation | Owner |
|---|---|---|---|---|

## 5. Budget Status
| Category | Planned | Actual | Variance |
|---|---|---|---|

## 6. Next Steps
- [Commitment list with owners and dates]

## 7. Decisions Required
- [What decision is needed, from whom, by when]
```

#### 交接文档结构

```
# [System Name] Handover Document v[X.Y] — [Date]

**Reader Persona**: [Engineer taking over maintenance/development]

## 1. System Overview
- Purpose
- Architecture diagram
- Key components

## 2. Technology Stack
| Layer | Technology | Version | Purpose |
|---|---|---|---|

## 3. Repository Structure
```
[Tree view with description of each directory]
```

## 4. Development Setup
```bash
# Exact commands to set up dev environment
```

## 5. Deployment
- [Reference to deployment guide]
- [Environment differences]

## 6. Operational Runbook
| Scenario | Command/Procedure | Expected Output | Escalation |
|---|---|---|---|

## 7. Known Issues
| Issue | Workaround | Planned Fix | Ticket |
|---|---|---|---|

## 8. Architecture Decisions
| Decision | Context | Consequence | Date |
|---|---|---|---|

## 9. Contacts
| Role | Name | Contact | Responsibility |
|---|---|---|---|
```

---

### 3. 代码示例规范

每个代码示例必须包含：

```
**要求清单**:
- [ ] 代码围栏中明确指定语言
- [ ] 包含所有必要的 import/依赖
- [ ] 使用真实值或清晰的占位符（`YOUR_API_KEY`）
- [ ] 包含预期输出
- [ ] 可复制粘贴运行（只需替换占位符）

**示例**:
```python
import requests
import os

# Set your API key as an environment variable
# export API_KEY="your-api-key-here"

API_KEY = os.environ.get("API_KEY")
BASE_URL = "https://api.example.com/v1"

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

response = requests.get(f"{BASE_URL}/users", headers=headers)
print(response.status_code)  # Expected: 200
print(response.json())       # Expected: {"users": [...]}
```
```

---

### 4. 变更日志规范

```
## Changelog

### v2.1 — 2026-04-20
- Added: GET /api/v1/orders/{id} endpoint documentation
- Updated: Authentication section with refresh token flow
- Fixed: Error code table formatting

### v2.0 — 2026-03-15
- Major: Restructured document per Diátaxis framework
- Added: Quick Start tutorial section
- Removed: Legacy v1 endpoint documentation (moved to deprecated doc)

### v1.1 — 2026-02-28
- Fixed: Typo in request body example
- Updated: Rate limits to match current production values

### v1.0 — 2026-02-01
- Initial release
```

---

## 存档路径规范

| 文档类型 | 路径模板 |
|---------|----------|
| API 文档 | `docs/api/[api-name]-api-v[version].md` |
| 用户手册 | `docs/user/[product]-user-manual-v[version].md` |
| 部署指南 | `docs/ops/[system]-deploy-guide-v[version].md` |
| 论文/学术 | `docs/research/[paper]-draft-v[version].md` |
| 里程碑报告 | `docs/reports/milestone-[YYYYMM]-v[version].md` |
| 交接文档 | `docs/handover/[system]-handover-v[version].md` |
| 故障排查 | `docs/ops/[system]-troubleshooting-v[version].md` |

---

## 质量检查清单

交付前逐项确认：

- [ ] 读者角色已在文档开头明确声明
- [ ] 所有源材料已读取并验证存在
- [ ] 每个事实声明可追溯至源文档
- [ ] 文档已加盖版本号和日期
- [ ] 所有代码示例完整、可运行，包含预期输出
- [ ] 文档中无 TODO、placeholder 或 "待补充"
- [ ] 文档 > 5 章节时有目录和锚点链接
- [ ] 结构符合 Diátaxis 四象限（未混合教程和参考）
- [ ] 错误码表包含机器可读码、HTTP 状态、描述、解决方案
- [ ] 部署指南的先决条件具体到版本号
- [ ] 变更日志记录了本次所有变更
- [ ] 存档路径符合命名规范
