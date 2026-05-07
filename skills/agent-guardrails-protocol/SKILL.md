---
name: agent-guardrails-protocol
description: Agent Guardrails 协议。用于设计或审查 Agent、Skill、Hook、Output Style，强调权限边界、handoff、失败分类和用户拍板触发条件。
when_to_use: 当设计或审查 Agent、Skill、Hook、Output Style、调度规则、handoff、权限边界或失败分类时使用。
---

<skill name="agent-guardrails-protocol">

<overview>
用于设计或审查 Agent、Skill、Hook、Output Style，确保每个组件有明确的职责边界、工具边界、上下文边界、handoff 契约、失败分类和可验证性。
</overview>

<checklist>
  <section name="职责边界">
    <item priority="critical">这个 Agent 做什么、不做什么、何时停止</item>
  </section>

  <section name="工具边界">
    <item priority="critical">允许工具、禁止工具、危险操作确认、写入范围</item>
  </section>

  <section name="上下文边界">
    <item priority="high">默认加载什么、按需读取什么、避免什么污染</item>
  </section>

  <section name="Handoff">
    <item priority="critical">输入 artifact、输出 artifact、下一跳、失败返回格式</item>
  </section>

  <section name="失败分类">
    <item priority="critical">区分 <level>BLOCKED</level>、<level>FAILED</level>、<level>NEEDS_USER</level>、<level>OUT_OF_SCOPE</level></item>
  </section>

  <section name="验证">
    <item priority="high">如何证明它按边界工作，而不是自证正确</item>
  </section>
</checklist>

<output-requirements>
给出 <verdict>PASS</verdict> / <verdict>WARNING</verdict> / <verdict>BLOCKED</verdict>，并列出必须修改项、建议项和不采纳理由。
</output-requirements>

<references>
  <reference path="references/review-template.md" purpose="review template"/>
  <reference path="references/failure-taxonomy.md" purpose="failure taxonomy"/>
</references>

<usage-note>
需要细化检查、模板或失败分类时，按需读取这些 supporting files；不要把长参考默认塞入主上下文。
</usage-note>

</skill>
