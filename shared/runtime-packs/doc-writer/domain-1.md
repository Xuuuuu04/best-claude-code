# Domain 1: 写作与结构

## 1.1 读者角色驱动的结构

### 读者角色分析模板

在写任何一个文档之前，必须明确填写：

```
## Reader Persona

**Role**: [具体角色，如 "Python 后端开发者" / "非技术客户" / "运维工程师"]
**Goal**: [阅读后需要完成什么？如 "20 分钟内完成第一个 API 调用"]
**Knowledge Level**: [初学者 / 中级 / 专家]
**Context**: [在什么场景下阅读？如 "本地开发环境搭建" / "生产故障排查"]
**Format Preference**: [喜欢详细步骤 / 喜欢快速参考 / 喜欢概念解释]
```

### 不同读者的结构差异

**开发者 API 文档读者**：
- 目标: 尽快让第一个 API 调用成功
- 最优结构: Quick Start → Authentication → Core endpoints → Error handling → Rate limits
- 词汇: 专业术语，假设熟悉 HTTP/REST
- 深度: 精确到字段级别，包含所有 edge cases

**终端用户手册读者**：
- 目标: 完成特定任务
- 最优结构: Overview → Key concepts → Step-by-step tasks → FAQ
- 词汇: 避免所有技术术语，用日常语言
- 深度: 每个步骤有预期结果，"如果不工作怎么办"

**高管里程碑报告读者**：
- 目标: 决定下一步行动
- 最优结构: Decision items → Metrics → Risks → Next steps
- 词汇: 商业语言，量化指标
- 深度: 结论优先，细节在附录

**运维部署指南读者**：
- 目标: 在生产环境成功部署
- 最优结构: Prerequisites → Installation → Configuration → Verification → Troubleshooting → Rollback
- 词汇: 精确的技术术语，命令行操作
- 深度: 每个命令可复制粘贴，版本号精确

---

## 1.2 信息架构

### Diátaxis 四象限

| 象限 | 导向 | 语气 | 假设 | 示例 |
|------|------|------|------|------|
| **Tutorial** | 学习导向 | 对话式，手把手 | 读者是初学者 | "让我们构建你的第一个 API 客户端..." |
| **How-to Guide** | 任务导向 | 直接，假设领域知识 | 读者知道要做什么 | "如何配置 OAuth2 认证..." |
| **Reference** | 信息导向 | 精确，结构化 | 读者知道要找什么 | 端点参数表、错误码列表 |
| **Explanation** | 理解导向 | 叙述式 | 读者想理解原理 | "为什么我们选择 JWT 而不是 Session..." |

**关键规则**：
- 一个文档不要混合多个象限
- Tutorial 和 How-to 的区别：Tutorial 教 "如何学习"，How-to 教 "如何做"
- Reference 不要解释 "为什么"，只陈述 "是什么"
- Explanation 不要包含步骤，只解释概念

### 金字塔结构应用

每个章节/段落遵循：
1. **结论/要点**（最重要的信息）
2. **支持证据**
3. **细节/背景**

```
BAD（细节优先）:
"The API supports multiple authentication methods. First, there is JWT token authentication which uses Bearer tokens. Then there is API key authentication which uses a header. There is also OAuth2 for third-party integrations. Overall, authentication is flexible."

GOOD（结论优先）:
"The API offers three authentication methods: JWT (recommended for most use cases), API key (for server-to-server), and OAuth2 (for third-party integrations).

JWT is the recommended default. Use API keys for automated server-to-server communication. Use OAuth2 only when integrating with third-party applications."
```

### 目录与导航

**文档 > 5 个章节时必须包含**：
- 显式目录（带锚点链接）
- 章节编号
- 返回顶部链接（长文档）

**API 文档导航**：
- 顶部: 端点索引（按资源分组）
- 每个端点: 回到索引的链接
- 错误码: 可排序表格

**用户手册导航**：
- 任务导向的章节名（"创建项目" 而非 "项目模块"）
- 每个任务: 编号步骤（每步 ≤ 7 个）
- 交叉引用相关任务

---

## 1.3 技术写作技巧

### 代码示例要求

每个代码示例必须通过以下检查：

```
**代码示例检查清单**:
- [ ] 代码围栏中明确指定语言（```python, ```bash, ```json）
- [ ] 包含所有必要的 import/依赖声明
- [ ] 使用真实值或清晰的占位符（YOUR_API_KEY, your-username）
- [ ] 包含预期输出（注释或代码块）
- [ ] 可复制粘贴运行（只需替换占位符）
- [ ] 如果涉及环境变量，说明如何设置
```

**示例对比**：

```
BAD:
```
POST /api/v1/orders
Body: {"product_id": "string", "quantity": "integer"}
```
→ 无语言标签，无 import，无真实值，无预期输出

GOOD:
```bash
# Create a new order
# Replace $TOKEN with your API token
# Replace prod-001 with an actual product ID

curl -X POST https://api.example.com/v1/orders \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{
    "product_id": "prod-001",
    "quantity": 2
  }'
```

**Expected Response**:
```json
{
  "order_id": "ord-abc123",
  "status": "pending",
  "created_at": "2026-04-20T10:45:00Z",
  "total_amount": 199.98
}
```
→ 完整、可运行、有预期输出
```

### 版本与日期标记

**文档头部格式**：
```markdown
# [Document Title] v[MAJOR.MINOR] — [YYYY-MM-DD]

**Reader Persona**: [role + goal]
**Document Type**: [Diátaxis quadrant]
**Last Updated**: [YYYY-MM-DD]
**Source Materials**: [list]
```

**版本号规则**：
- **MAJOR (x.0.0)**: 文档重构、目标读者变更、记录系统有 breaking changes
- **MINOR (0.x.0)**: 新增章节、重大改写、新增端点/功能
- **PATCH (0.0.x)**: 错别字修正、澄清说明、不影响含义的修改

**变更日志格式**：
```markdown
## Changelog

### v2.1 — 2026-04-20
- Added: GET /api/v1/orders/{id} endpoint documentation
- Updated: Authentication section with refresh token flow
- Fixed: Error code table formatting
```

### 可读性指标

| 指标 | 规则 | 原因 |
|------|------|------|
| 段落长度 | ≤ 200 词 | 超过后需要视觉分隔 |
| 列表项数 | ≤ 7 项 | 超过后考虑分组 |
| 句子长度 | 短句为主 | 程序式步骤用短句 |
| 术语定义 | 首次使用时定义 | 之后一致使用 |
| 视觉分隔 | 每 2-3 段使用分隔 | 提高扫描效率 |

---

## 1.4 文档质量检查清单

### 通用检查清单

- [ ] 读者角色已在文档开头明确声明
- [ ] 文档类型（Diátaxis）已明确
- [ ] 所有源材料已读取并验证存在
- [ ] 每个事实声明可追溯至源文档
- [ ] 文档已加盖版本号和日期
- [ ] 所有代码示例完整、可运行，包含预期输出
- [ ] 文档中无 TODO、placeholder 或 "待补充"
- [ ] 文档 > 5 章节时有目录和锚点链接
- [ ] 结构符合 Diátaxis 四象限
- [ ] 变更日志已更新

### 按文档类型的额外检查

**API 文档**：
- [ ] 每个端点有：方法、路径、参数表、请求体表、响应表
- [ ] 错误码表包含：机器可读码、HTTP 状态、描述、解决方案、示例
- [ ] 认证部分有：获取凭证、请求头格式、TTL、刷新流程
- [ ] Quick Start 能在 20 分钟内让新用户成功调用

**用户手册**：
- [ ] 章节名是任务导向（"创建项目" 而非 "项目模块"）
- [ ] 每个任务有：编号步骤、预期结果、故障排查
- [ ] 无技术术语（或已解释）
- [ ] 有 FAQ 和术语表

**部署指南**：
- [ ] 先决条件具体到版本号
- [ ] 每个命令可复制粘贴
- [ ] 有验证步骤
- [ ] 有故障排查表（错误消息 → 原因 → 修复）
- [ ] 有回滚步骤

**里程碑报告**：
- [ ] 决策项在状态更新之前
- [ ] 指标是绝对数字（不是百分比变化）
- [ ] 风险格式："如果 [条件] 则 [后果] 在 [日期]"
- [ ] 下一步是承诺列表（有负责人和日期）
