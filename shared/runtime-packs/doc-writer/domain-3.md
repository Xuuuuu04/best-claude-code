# Domain 3: 信息工程

## 3.1 源事实管理

### 事实追踪架构

每个文档中的事实声明必须能追溯到源材料：

```markdown
## Fact Trail

| Section | Claim | Source File | Source Line | Last Verified |
|---------|-------|-------------|-------------|---------------|
| 4.1 Create Order | POST /orders returns 201 | src/routes/orders.py | L47 | 2026-04-20 |
| 4.1 Create Order | Idempotency key TTL is 24h | src/services/order_service.py | L89 | 2026-04-20 |
| 5.2 Error Codes | VALIDATION_ERROR maps to 422 | src/exceptions.py | L23 | 2026-04-20 |
```

**事实追踪规则**：
- API 端点描述 → 追溯到实现文件和行号
- 错误码描述 → 追溯到错误定义文件
- 配置值 → 追溯到配置文件或环境变量文档
- 性能数据 → 追溯到测试报告或监控数据

### 单一事实来源原则

**原则**：文档链接，不复制

```
BAD:
在 API 文档中复制了数据库 schema 的字段定义。
→ 当 schema 变更时，文档和代码不同步。

GOOD:
在 API 文档中引用 schema 文件：
"Request body fields match the Order model defined in `src/models/order.py`. See that file for the authoritative field definitions."
→ 文档始终与代码同步。
```

**例外情况**：
- 代码片段（必须可复制粘贴）
- 错误码表（需要人类可读的描述）
- 快速参考（需要独立完整的表格）

### 差距识别与阻塞

在开始写每个章节之前，验证源材料是否存在：

```markdown
## Source Material Check

| Section | Required Source | Status | Responsible Agent |
|---------|----------------|--------|-------------------|
| 4.1 Create Order | src/routes/orders.py | ✅ Available | @backend |
| 4.2 Get Order | src/routes/orders.py | ✅ Available | @backend |
| 5.1 Error Codes | src/exceptions.py | ❌ Missing | @backend |
| 6.1 Rate Limits | ops/config/rate-limits.yml | ⚠️ Outdated | @devops |
```

**阻塞规则**：
- 如果关键源材料缺失 → BLOCK 整个文档
- 如果部分源材料缺失 → BLOCK 相关章节，交付其余部分
- 如果源材料过期 → 标记为 STALE，请求更新

---

## 3.2 文档生命周期

### 版本递增策略

| 版本类型 | 格式 | 触发条件 | 示例 |
|----------|------|----------|------|
| **Patch** | 0.0.x | 错别字修正、澄清说明、格式修复 | 1.0.0 → 1.0.1 |
| **Minor** | 0.x.0 | 新增章节、重大改写、新增端点/功能 | 1.0.0 → 1.1.0 |
| **Major** | x.0.0 | 文档重构、目标读者变更、系统 breaking changes | 1.0.0 → 2.0.0 |

**版本决策树**：
```
变更是否改变文档结构？
├── 是 → Major (x.0.0)
└── 否 → 变更是否新增内容？
    ├── 是 → Minor (0.x.0)
    └── 否 → Patch (0.0.x)
```

### 存档路径规范

| 文档类型 | 路径模板 | 示例 |
|---------|----------|------|
| API 文档 | `docs/api/[api-name]-api-v[version].md` | `docs/api/payment-api-v2.1.md` |
| 用户手册 | `docs/user/[product]-user-manual-v[version].md` | `docs/user/acme-app-user-manual-v1.3.md` |
| 部署指南 | `docs/ops/[system]-deploy-guide-v[version].md` | `docsOps/payment-service-deploy-guide-v3.0.md` |
| 论文/学术 | `docs/research/[paper]-draft-v[version].md` | `docs/research/federated-learning-draft-v1.2.md` |
| 里程碑报告 | `docs/reports/milestone-[YYYYMM]-v[version].md` | `docs/reports/milestone-202604-v1.0.md` |
| 交接文档 | `docs/handover/[system]-handover-v[version].md` | `docs/handover/legacy-api-handover-v2.0.md` |
| 故障排查 | `docs/ops/[system]-troubleshooting-v[version].md` | `docs/ops/payment-service-troubleshooting-v1.1.md` |

### 弃用与替代

当新版本替代旧版本时：

```markdown
# [Old Document Title] v[X.Y] — [Date]

⚠️ **DEPRECATED**: This document has been superseded by [new document link].
Please refer to the new version for up-to-date information.

**Superseded Date**: [YYYY-MM-DD]
**Reason**: [Why this document was replaced]

---

[Original content remains for historical reference]
```

**规则**：
- 不要删除旧版本文档
- 在旧文档头部添加 DEPRECATED 标记
- 提供指向新版本的链接
- 记录替代原因和日期

---

## 3.3 文档维护流程

### 定期审查清单

每季度审查一次活跃文档：

```markdown
## Document Review Checklist

**Document**: [Name]
**Version**: [Current version]
**Last Reviewed**: [Date]
**Reviewer**: [Name]

### Accuracy
- [ ] 所有代码示例仍然可运行
- [ ] 所有端点/功能描述与代码一致
- [ ] 所有链接有效
- [ ] 版本号与系统版本匹配

### Completeness
- [ ] 新功能已文档化
- [ ] 已弃用功能已标记
- [ ] 错误码表完整
- [ ] 故障排查覆盖最新问题

### Usability
- [ ] 读者角色仍然准确
- [ ] 结构仍然合理
- [ ] 导航仍然有效
- [ ] 示例仍然相关

### Action Items
| Issue | Priority | Owner | Due Date |
|-------|----------|-------|----------|
| [Issue 1] | [High/Med/Low] | [Owner] | [Date] |
```

### 变更触发文档更新

| 变更类型 | 需要更新的文档 | 版本递增 |
|----------|---------------|----------|
| 新增 API 端点 | API 文档 | Minor |
| 修改 API 行为 | API 文档 | Minor |
| 新增错误码 | API 文档 | Minor |
| 修改认证方式 | API 文档 + 部署指南 | Minor |
| 新增功能 | 用户手册 + API 文档 | Minor |
| 修改配置 | 部署指南 | Minor |
| 修复文档错误 | 相关文档 | Patch |
| 重构系统架构 | 所有文档 | Major |

---

## 3.4 文档质量度量

### 质量指标

| 指标 | 测量方法 | 目标 |
|------|----------|------|
| **准确性** | 代码示例是否能运行？ | 100% |
| **完整性** | 是否有 TODO/placeholder？ | 0 |
| **时效性** | 最后更新日期？ | < 3 个月 |
| **可追溯性** | 事实声明是否有来源？ | 100% |
| **可用性** | 新读者能否在 20 分钟内完成第一个任务？ | Yes |
| **导航性** | 找到特定信息需要多长时间？ | < 2 分钟 |

### 读者反馈收集

```markdown
## Document Feedback

**Document**: [Name]
**Reader**: [Role]
**Date**: [YYYY-MM-DD]

### What worked well?
[Reader's positive feedback]

### What was confusing?
[Reader's confusion points]

### What was missing?
[Reader's gaps]

### Suggested improvements
[Reader's suggestions]

### Action Items
| Suggestion | Priority | Owner | Status |
|-----------|----------|-------|--------|
| [Suggestion 1] | [High/Med/Low] | [Owner] | [Open/In Progress/Done] |
```
