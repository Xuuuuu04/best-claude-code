---
name: client-intake
description: 客户需求整理协议。为 client 提供原话消歧、brief 结构化、售后问题分类和提案前置判断方法。
when_to_use: 仅当 client Agent 在处理客户原话 / 聊天记录 / 售后反馈 / 提案需求时加载。内部需求拆分（product-analyst）不应触发。
---

# 客户需求整理协议

## 目标

把原始客户表达压缩成工程团队可以消费的 brief，同时保留“已确认 / 推测 / 待澄清”的边界。

## 基本分类

每条输入都要归到以下三类之一：

- `CLIENT STATED`：客户明确说过
- `INFERRED`：从上下文推断
- `PENDING CLARIFICATION`：没有它就无法安全推进

## 提炼模板

```markdown
## Client Stated
- 目标用户：
- 主要功能：
- 工期/预算信号：

## Inferred
- ...

## Pending Clarification
1. ...

## Out of Scope Anchor
- ...
```

## 售后问题四分法

- `Bug`
- `Change Request`
- `Usage Question`
- `Out-of-Scope Addition`

不要把四类混成“客户有问题”。

## 风险提示

- 模糊词如“简单做一下”“类似某某”必须转成问题
- 不承诺技术可行性和精确工期
- 预算与范围明显不匹配时要显式写风险
