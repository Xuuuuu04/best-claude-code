---
name: client-intake
description: 客户需求整理协议。为 client 提供原话消歧、brief 结构化、售后问题分类和提案前置判断方法。
when_to_use: 仅当 client Agent 在处理客户原话 / 聊天记录 / 售后反馈 / 提案需求时加载。内部需求拆分（product-analyst）不应触发。
---

<skill>
  <overview>把原始客户表达压缩成工程团队可以消费的 brief，同时保留"已确认 / 推测 / 待澄清"的边界。</overview>

  <workflow>
    <classification>
      <category name="CLIENT_STATED">客户明确说过</category>
      <category name="INFERRED">从上下文推断</category>
      <category name="PENDING CLARIFICATION">没有它就无法安全推进</category>
    </classification>

    <template>
      <![CDATA[
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
      ]]>
    </template>

    <aftercare>
      <title>售后问题四分法</title>
      <category name="Bug"/>
      <category name="Change Request"/>
      <category name="Usage Question"/>
      <category name="Out-of-Scope Addition"/>
      <rule>不要把四类混成"客户有问题"。</rule>
    </aftercare>
  </workflow>

  <checklist>
    <risk id="vague-terms">模糊词如"简单做一下""类似某某"必须转成问题</risk>
    <risk id="no-tech-promise">不承诺技术可行性和精确工期</risk>
    <risk id="budget-scope-mismatch">预算与范围明显不匹配时要显式写风险</risk>
  </checklist>
</skill>
