---
name: 需求审查样品（feat-20260425-05 客户群发推送）
description: 标准 review-requirements artifact 格式参考，含完整 / 不完整两种状态对比
type: review-requirements
task_id: feat-20260425-05
generated_at: 2026-04-25T10:15:00+0800
产出者: requirements-reviewer
status: accepted
关联:
  - requirements-feat-20260425-05.md
---

# review-requirements: feat-20260425-05 客户群发推送

## 审查结果：**需修改** ⚠

需求 artifact 在"完整性"和"可测性"两个维度有缺口，需 product-analyst 补齐后才能进入 architect 阶段。

## 审查矩阵

| 维度 | 状态 | 问题数 |
|:--|:--:|:-:|
| 1. 完整性（必要字段齐） | ⚠ | 2 |
| 2. 可测性（验收可机器/人工判定） | ⚠ | 2 |
| 3. 边界（输入/异常/规模） | ✓ | 0 |
| 4. 风险（合规/可逆/数据） | ⚠ | 1 |

**总计**：5 处需补齐，全部为可补类（无 BLOCKED）。

## 1. 完整性

### Issue-1: 缺"非目标"段落

requirements 中只列了"要做什么"，未明确"不做什么"。容易导致 architect / implementer 自行扩张。

**建议补充**：
```markdown
## 非目标
- 不做：定时调度（仅手动触发）
- 不做：富媒体（仅文本+链接）
- 不做：撤回（已发送不可撤）
```

### Issue-2: 用户角色未定义

谁能发起群发？管理员？运营？所有商户？requirements 没说清，会影响权限审查。

**建议补充**：明确 RBAC 矩阵——`role: merchant_admin` 才能发起。

## 2. 可测性

### Issue-3: 验收标准 #2 不可测

> 验收标准 #2："推送应该有较好的送达率"

"较好"无法测试。

**建议改为**：
> 推送送达率 ≥ 95%（24 小时内观察）；接收回执 callback 失败率 ≤ 0.5%

### Issue-4: 验收标准 #4 含主观判断

> 验收标准 #4："文案符合品牌调性"

人工审查可以，但需要明确 reviewer 是谁。

**建议**：
- 文案模板由 `creative` agent 提前产出 → 加入 architecture artifact
- 验收标准改为："推送文案 100% 来自批准模板库"

## 3. 边界

✓ 包含目标用户筛选规则（标签 / 地域 / 活跃度）
✓ 单次群发上限 10000 用户，超出分批
✓ 失败用户加入重试队列
✓ 已通用户不重复推送（dedup window 7 天）

## 4. 风险

### Issue-5: 缺合规审查

群发推送涉及 GDPR / 个保法的"用户同意"。需求未提及"对未授权推送的用户跳过"。

**建议补充**：
```markdown
## 合规约束
- 仅向 push_consent=true 的用户推送
- 跳过 push_consent 缺失或为 false 的用户
- 每条推送中含一键退订入口
```

## 总结建议

1. product-analyst 补齐 Issue-1 ~ Issue-5（预计 30 分钟）
2. 重新提交 requirements-feat-20260425-05.md（status: draft → accepted）
3. 我（requirements-reviewer）复审一次
4. 通过后 → architect 接手

不需要重写整个需求，只需补段。
