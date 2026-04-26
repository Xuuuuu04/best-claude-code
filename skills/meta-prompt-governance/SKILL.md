---
name: meta-prompt-governance
description: 元提示词治理协议。为 prompt-engineer 提供 drift 诊断、边界冲突分析和新增 agent 审批标准。
when_to_use: 仅当 prompt-engineer Agent 在改 agent / skill / rule / output-style / hook 或诊断职责重叠 / dispatch 跑偏时加载。日常需求审查 / 代码审查 / 实现工作不应触发。
---

# 元提示词治理协议

## Drift 诊断三元组

没有这三项，不要改：

- 输入是什么
- 期望是什么
- 实际发生了什么

## 根因分类

- prompt defect
- rule conflict
- routing ambiguity
- capability boundary

## 新增 agent 审批门槛

必须证明：

- 现有 agent 无法无违约覆盖
- 新边界可以用例子判定
- 维护成本小于收益

## 变更优先级

优先考虑：

1. 改规则
2. 改 skill
3. 改 agent prompt
4. 新增 agent

## 回归检查

每次元变更后都要列出：

- 哪些输入路由会变化
- 哪些相邻角色边界要复核
- 哪些文档要同步
