---
name: quality-verdict
description: 最终质量裁决协议。为 test-lead 提供功能 / 视觉 / 安全三证据流的综合判断方法。
when_to_use: 仅当 test-lead Agent 在里程碑 / 上线前裁决（PASS / CONDITIONAL PASS / BLOCKED）时加载。单一阶段测试报告产出（functional-tester / visual-tester / security-auditor）不应触发。
---

<skill name="quality-verdict">

<overview>
综合功能测试、视觉测试、安全审计三类证据流，做出最终质量裁决。
</overview>

<evidence-sources>
  <source name="功能测试">主路径、边界、回归</source>
  <source name="视觉测试">状态、布局、交互、截图</source>
  <source name="安全审计">高危与未关闭风险</source>
  <source name="数字审计">L3 论文数字 vs 原始结果一致性</source>
  <source name="引用审计">L4 引用完整性、元数据、上下文</source>
  <source name="定理审计">L3+ 定理自洽性、证明逻辑链、符号一致性</source>
  <source name="学术审查">5 维学术审计 + Debate Protocol 结果</source>
</evidence-sources>

<verdict-tiers>
  <tier name="PASS" description="全部门控通过，可上线/交付"/>
  <tier name="CONDITIONAL PASS" description="核心链路通过，剩余问题中低风险，后续可独立修复"/>
  <tier name="BLOCKED" description="存在不可接受的未关闭问题，禁止上线/交付"/>
</verdict-tiers>

<veto-rules>
  <rule priority="critical">未关闭高危安全问题 → 不能 PASS</rule>
  <rule priority="critical">核心功能失败 → 不能 PASS</rule>
  <rule priority="critical">关键界面状态失真 → 不能 PASS</rule>
  <rule priority="critical">关键证据缺失 → 不能 PASS</rule>
  <rule priority="critical">学术项目 AUDIT_FAIL（数字/引用/定理审计失败）→ 不能 PASS</rule>
  <rule priority="critical">学术项目 5 维审查含 ≥1 严重 → 不能 PASS</rule>
</veto-rules>

<conditional-pass-conditions>
仅允许以下情况给 CONDITIONAL PASS：
  <condition>核心链路已通过</condition>
  <condition>剩余问题为中低风险</condition>
  <condition>后续修复可独立成任务</condition>
  <condition>学术项目：审计累计 WARN ≥3 但无 FAIL，且审稿人 5 维审查无严重</condition>
</conditional-pass-conditions>

<academic-verdict-rules>
  学术项目裁决逻辑：
  <list>
    <item>PASS：全部审计 PASS + 5 维审查 PASS + 无严重问题</item>
    <item>CONDITIONAL PASS：审计累计 WARN ≥3 但无 FAIL，或审稿人 Borderline 但无严重</item>
    <item>BLOCKED：任一审计 FAIL / 审稿人 REJECT 含严重 / 关键证据缺失</item>
  </list>
  <note>学术项目的裁决不由单一 reviewer 决定，test-lead 需综合审计 verdict + 审稿 verdict + assurance 等级做最终判断。</note>
</academic-verdict-rules>

<output-requirements>
  <requirement>列清证据来源</requirement>
  <requirement>写明为什么不是另外两档</requirement>
  <requirement>BLOCKED 必须附修复路由</requirement>
</output-requirements>

<references>
  <reference path="examples/sample-verdict-three-tiers.md" purpose="PASS / CONDITIONAL PASS / BLOCKED 三档真实样品（含三档关键差异速记表）"/>
</references>

</skill>
