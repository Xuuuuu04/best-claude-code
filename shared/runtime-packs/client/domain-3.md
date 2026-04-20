# Domain 3: 售后反馈分类与升级

## 3.1 反馈分类矩阵

### 分类决策树

```
收到客户反馈
├── 是否关于现有功能？
│   ├── 是 → 功能是否按规格工作？
│   │   ├── 是 → 客户是否满意？
│   │   │   ├── 是 → ✅ 正面反馈，记录
│   │   │   └── 否 → 是理解问题还是期望不同？
│   │   │       ├── 理解问题 → USAGE QUESTION
│   │   │       └── 期望不同 → CHANGE REQUEST
│   │   └── 否 → 是否有复现步骤？
│   │       ├── 是 → BUG
│   │       └── 否 → 需要更多信息
│   └── 否 → 是否在原始合同范围内？
│       ├── 是 → CHANGE REQUEST
│       └── 否 → OUT-OF-SCOPE ADDITION
```

### 分类标准详解

**Bug（缺陷）**
- 定义: 实际行为与已确认规格不符
- 必要条件:
  - [ ] 可复现的步骤
  - [ ] 预期行为（来自合同/规格）
  - [ ] 实际行为
  - [ ] 影响范围
- 商业后果: 通常在保修期内免费修复
- 路由: @pm → 创建修复任务

**Change Request（变更请求）**
- 定义: 修改现有功能的行为，或添加合同范围内但未实现的功能
- 判断标准: "这个功能在合同中吗？"
  - 在合同中 + 未按规格实现 = Bug
  - 在合同中 + 客户想要不同行为 = Change Request
  - 不在合同中 = Out-of-Scope Addition
- 商业后果: 需要变更订单，可能产生额外费用
- 路由: @dev-lead 评估范围 → 商业谈判

**Usage Question（使用问题）**
- 定义: 客户不知道如何使用现有功能
- 特征:
  - 功能按规格工作
  - 客户操作方式不正确或不了解
  - 不需要代码变更
- 商业后果: 通常免费支持，计入客户服务成本
- 路由: 提供使用指导 / 更新文档

**Out-of-Scope Addition（范围外新增）**
- 定义: 合同中从未包含的功能
- 判断标准: "原始合同/规格中是否提到这个功能？"
- 商业后果: 新的商业机会，需要新的合同或变更订单
- 路由: 评估 → 报价 → 客户决策

---

## 3.2 分类处理流程

### Bug 处理流程

```
1. 接收报告
   └── 记录: 时间、客户、问题描述

2. 分类确认
   └── 验证: 是否为 Bug（有复现步骤 + 与规格不符）

3. 信息完善
   └── 收集: 复现步骤、环境信息、截图/录屏、影响范围

4. 影响评估
   └── 评估: 严重程度（Critical/High/Medium/Low）、影响用户数

5. 路由
   └── 发送给: @pm 创建修复任务

6. 客户沟通 (DRAFT)
   └── "我们已确认 [问题描述] 是一个缺陷。我们的技术团队正在修复，预计在 [时间范围] 内完成。我们会及时更新进度。"

7. 修复验证
   └── 修复后验证，通知客户

8. 关闭
   └── 客户确认，记录关闭
```

### Change Request 处理流程

```
1. 接收请求
   └── 记录: 原始需求、变更内容、原因

2. 分类确认
   └── 验证: 是否为 Change Request（合同中存在，但行为不同）

3. 影响分析
   └── 评估: 对现有功能的影响、技术复杂度、时间范围

4. 商业评估
   └── 评估: 是否需要额外费用、对时间线的影响

5. 路由
   └── 发送给: @dev-lead 进行技术评估

6. 客户沟通 (DRAFT)
   └── "您提出的 [变更内容] 是对现有功能的修改。根据我们的评估，这需要 [时间范围] 和 [费用范围]。请确认是否继续？"

7. 审批
   └── 客户审批后，创建变更订单

8. 实施
   └── 按计划实施变更
```

---

## 3.3 客户沟通模板

### Bug 通知模板

```
Subject: [Project Name] — Issue Confirmation and Fix Timeline

Hi [Client Name],

Thank you for reporting [issue summary].

We have confirmed this is a defect in [feature/module]. Here are the details:

**Issue**: [description]
**Impact**: [who is affected, how severely]
**Status**: Our development team is working on a fix
**Expected Fix**: [time range]
**Workaround**: [if any, temporary workaround]

We will update you by [date] with the progress. Once the fix is ready, we will deploy it to [environment] for your verification.

Best regards,
[Name]
```

### Change Request 模板

```
Subject: [Project Name] — Change Request Assessment

Hi [Client Name],

Thank you for your request regarding [change description].

We have assessed this as a change request to the original scope. Here is our evaluation:

**Requested Change**: [description]
**Impact on Existing Features**: [description]
**Estimated Effort**: [time range]
**Additional Investment**: [cost range]
**Impact on Timeline**: [description]

If you would like to proceed, we will prepare a change order for your approval.

Please let us know how you would like to proceed.

Best regards,
[Name]
```

### Usage Question 模板

```
Subject: [Project Name] — How to [Task]

Hi [Client Name],

Thank you for your question about [feature/functionality].

Here is how to [accomplish the task]:

1. [Step 1]
2. [Step 2]
3. [Step 3]

[Include screenshot if helpful]

If you have any other questions, please don't hesitate to ask.

Best regards,
[Name]
```

### Out-of-Scope 模板

```
Subject: [Project Name] — Feature Request Assessment

Hi [Client Name],

Thank you for your suggestion about [feature].

After reviewing our original agreement, this feature was not included in the current scope. However, we would be happy to implement it.

Here are two options:

**Option A: Add to Current Project**
- Estimated Effort: [time range]
- Additional Investment: [cost]
- Impact on Current Timeline: [description]

**Option B: Phase 2 Project**
- We can plan this as a separate enhancement project after the current delivery
- This allows us to complete the current scope on time

Please let us know which option you prefer, or if you would like to discuss further.

Best regards,
[Name]
```

---

## 3.4 升级路径

### 升级触发条件

| 场景 | 升级路径 | 升级原因 |
|------|----------|----------|
| Bug 影响 > 50% 用户 | 立即升级 → @pm + @dev-lead | 高影响，需要紧急响应 |
| 客户威胁终止合同 | 立即升级 → Main process | 商业风险 |
| Change Request > 原合同 20% | 升级 → @pm + Main process | 范围重大变更 |
| 技术方案需要架构变更 | 升级 → @architect | 技术决策 |
| 涉及安全漏洞 | 立即升级 → @security-auditor | 安全风险 |
| 客户连续 3 次投诉同类问题 | 升级 → @pm + 质量回顾 | 系统性问题 |

### 升级信息模板

```
## Escalation Report

**From**: [@client]
**To**: [升级对象]
**Date**: [YYYY-MM-DD]
**Priority**: Critical / High / Medium / Low

**Issue Summary**: [1-2 句]
**Client**: [名称，合作历史]
**Classification**: [Bug / Change Request / Usage Question / Out-of-Scope]
**Impact**: [商业影响，技术影响]
**Client Sentiment**: [满意 / 中性 / 不满 / 愤怒]
**Immediate Action Taken**: [已采取的措施]
**Recommended Action**: [建议的下一步]
**Support Needed**: [需要升级对象提供什么支持]
```
