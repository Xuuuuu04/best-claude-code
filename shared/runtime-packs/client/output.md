# 客户沟通师 — Output Contract

## 标准输出模板

### Pre-Sales Intake 输出

```
## Client Intake Output: [Project Name]

**Intake Type**: Pre-sales
**Project Summary**: [1–2 sentence description]

**Core Features** (semantically enhanced):
1. [Feature]: [CLIENT STATED / INFERRED — PENDING CLARIFICATION] — [specific behavior + acceptance criterion]
2. [Feature]: [CLIENT STATED / INFERRED — PENDING CLARIFICATION] — [specific behavior + acceptance criterion]

**Primary User Roles**: [Role name: scenario description]

**Non-Functional Requirements**: [performance / security / compliance / availability]

**Timeline Expectation**:
- Client stated: [their words]
- Feasibility assessment: [realistic range / "unrealistic — recommend scope reduction"]

**Budget Range**:
- Client stated: [their words]
- Scope consistency: [matches estimate / strained / requires scope negotiation]

**Out-of-Scope Anchor**: [≥2 explicit items not included]

**Pending Clarification Items**: [numbered list — each a specific question blocking a specific decision]

**Technical Feasibility Assessment**: [Conventional / Needs @tech-research on: items]

**Risk Register**: [≥2 risks — type + description + mitigation]

**Go/No-Go Assessment**: [GO / CONDITIONAL GO (pending X) / NO-GO] + rationale

**Recommended Next Step**: @pm / @tech-research
```

### Post-Delivery Triage 输出

```
## Issue Classification Report: [Project Name]

**Issue ID**: [ID]
**Received**: [Date]
**Client Message**: [ verbatim or summary ]

**Classification**: [Bug / Change Request / Usage Question / Out-of-Scope Addition]
**Confidence**: [High / Medium / Low]

**Analysis**:
- Original spec reference: [where was this behavior defined?]
- Expected behavior: [from spec]
- Actual behavior: [from client report]
- Impact scope: [who is affected, how severely]

**Commercial Consequence**: [warranty / change order / training / new engagement]

**Recommended Action**: [specific next step]

**Draft Client Response** (DRAFT — review before sending):
[polite, clear, non-technical explanation + next steps]
```

---

## 输出组件详解

### 1. Core Features 语义增强格式

每条功能必须包含：
- **来源标签**: CLIENT STATED / INFERRED / PENDING CLARIFICATION
- **具体行为**: 用用户故事格式或 Given/When/Then
- **验收标准**: 可测试的通过条件

```
BAD:
"用户管理功能"

GOOD:
"用户注册 [CLIENT STATED]
- 行为: 新用户可通过邮箱+密码注册，接收验证邮件后激活账户
- 验收标准: Given 未注册邮箱，When 提交注册表单，Then 收到验证邮件，And 点击链接后账户激活，And 可正常登录
- PENDING CLARIFICATION: 是否支持手机号注册？是否支持第三方登录（微信/Google）？"
```

---

### 2. Pending Clarification 格式规范

每个待澄清项必须包含：
- **编号**: 便于引用
- **问题**: 具体问题，不是笼统的"需要确认"
- **阻塞决策**: 如果不回答，会阻塞哪个具体决策
- **建议答案**: 提供选项或建议，降低客户回答成本

```
PENDING CLARIFICATION:
1. 用户注册方式 — 阻塞: 认证模块设计
   - 选项 A: 仅邮箱+密码
   - 选项 B: 邮箱 + 手机号双因子
   - 选项 C: 邮箱 + 第三方登录（微信/Google）
   - 建议: 选项 A 为 MVP，选项 C 为 Phase 2

2. "AI 功能"具体能力 — 阻塞: 技术可行性评估
   - 选项 A: 智能客服聊天机器人
   - 选项 B: 内容推荐引擎
   - 选项 C: 文档自动分类
   - 选项 D: 以上组合
   - 注意: 各选项成本差异 5-10×
```

---

### 3. Out-of-Scope Anchor 格式

必须明确列出：
- **不在本次范围内的功能**（≥2 项）
- **明确排除的原因**
- **未来可能的扩展方向**（如适用）

```
Out-of-Scope Anchor:
1. 移动端原生应用 (iOS/Android) — 原因: 预算限制，Web PWA 优先；Phase 2 可考虑
2. 多语言支持 — 原因: 目标用户为中文市场；英文版需额外 2-3 周
3. 第三方支付集成 — 原因: MVP 阶段不涉及交易；如后续需要，建议接入微信支付/支付宝
4. 实时协作编辑 — 原因: 技术复杂度高，需引入 WebSocket + OT 算法；建议 V2 评估

注意: 任何未明确列出的功能均需通过变更请求流程添加
```

---

### 4. Risk Register 格式

每个风险必须包含：
- **类型**: 商业 / 技术 / 时间 / 客户流程
- **描述**: 具体风险内容
- **概率**: 高 / 中 / 低
- **影响**: 高 / 中 / 低
- **缓解措施**: 具体行动

```
Risk Register:
1. [商业] 预算-范围不匹配 — 概率: 高，影响: 高
   - 描述: 客户预算 20 万，但期望功能相当于 50 万+ 的项目
   - 缓解: 明确 MVP 范围，建议分阶段交付；提供范围-预算对照表

2. [技术] "AI 功能"未定义 — 概率: 高，影响: 高
   - 描述: "AI 功能"可能从简单规则引擎到复杂 ML 模型，成本差异 10×
   - 缓解: 必须澄清后再做技术可行性评估；建议先从规则引擎起步

3. [时间] 客户决策流程长 — 概率: 中，影响: 中
   - 描述: 客户提及"需要内部讨论"，可能延长签约时间
   - 缓解: 提供清晰的决策材料，减少来回次数；设定提案有效期
```

---

### 5. Go/No-Go 评估矩阵

```
Go/No-Go Assessment:

| 维度 | 评分 (1-5) | 权重 | 加权分 | 说明 |
|------|-----------|------|--------|------|
| 技术可行性 | 4 | 25% | 1.0 | 常规 Web 开发，无新技术风险 |
| 商业可行性 | 3 | 25% | 0.75 | 预算偏紧，需严格范围控制 |
| 执行匹配度 | 4 | 25% | 1.0 | 团队有类似项目经验 |
| 客户关系 | 3 | 25% | 0.75 | 新客户，决策流程待观察 |
| **总分** | | | **3.5** | |

评估标准:
- 4.0-5.0: GO — 风险可控，建议承接
- 3.0-3.9: CONDITIONAL GO — 需满足特定条件后承接
- 1.0-2.9: NO-GO — 风险过高，建议婉拒

结论: CONDITIONAL GO
条件: (1) 澄清 Pending items 1-3; (2) 确认 MVP 范围后重新评估预算匹配度
```

---

## 存档路径规范

- 客户简报: `docs/client-brief-[project]-v[N].md`
- 问题分类报告: `docs/issue-reports/[project]-issue-[ID]-[date].md`
- 提案文档: `docs/proposals/[project]-proposal-v[N].md`

---

## 质量检查清单

交付前逐项确认：

- [ ] 所有模糊表达已解决或标记为 PENDING CLARIFICATION
- [ ] CLIENT STATED 和 INFERRED 明确区分
- [ ] 技术能力声明带有"subject to technical role confirmation"
- [ ] 时间估计为范围，不是单点
- [ ] 已知风险已披露
- [ ] Out-of-Scope Anchor 明确（≥2 项）
- [ ] @pm 可以直接开始任务分解，无需追问
- [ ] 售后问题已正确分类（Bug/Change/Question/Out-of-Scope）
- [ ] 客户回复草稿标记为 DRAFT
- [ ] Go/No-Go 评估诚实，不乐观
