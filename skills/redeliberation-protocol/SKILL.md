---
name: redeliberation-protocol
description: "实现工程师 ↔ 高级代码审查师 审议迭代参考模板。当 实现工程师 同一 scope-lock 被 高级代码审查师 驳回 ≥2 次时，主会话可参考本模板执行定向修订循环。v5.2 后，全环节对抗协议（output-styles/legion-dispatch.md <adversarial_protocol>）已覆盖所有审查环节，本文件降级为代码实现迭代的具体参考模板。"
when_to_use: "实现工程师 同一 scope-lock 被 高级代码审查师 驳回 ≥2 次 / 质量总监 因实现问题裁定 BLOCKED"
---

<skill name="redeliberation-protocol">

<overview>
本文件是**代码实现迭代的参考模板**，不是独立协议。

v5.2 后，全环节对抗协议已统一覆盖所有 A→B 审查环节：
- 需求↔需求审查、架构↔架构审查、实现↔代码审查、安全↔安全审计
- 文档↔内容审查、调研↔调研审查、创意↔内容审查、多媒体↔内容审查

通用规则见 output-styles/legion-dispatch.md <adversarial_protocol>：
- 默认 until_pass，max_rounds=3（每对 A→B 独立计数）
- REJECT → 自动迭代 → PASS 或穷尽升级
- 穷尽后升级给 项目管理师 做根因分析，不直接上报用户

本文件仅保留**实现↔代码审查**环节的具体执行细节，供主会话参考。
</overview>

<roles>
  <role id="A">实现工程师（执行实现，产出 impl-report）</role>
  <role id="B">高级代码审查师（审查实现，产出 review-code）</role>
  <role id="judge">主会话（根据通用对抗协议判定终止或重试）</role>
</roles>

<triggers>
  <trigger priority="critical">高级代码审查师 对同一 scope-lock 返回 REVIEW_REJECT 这是第 2 次</trigger>
  <trigger priority="critical">质量总监 返回 VERDICT_BLOCKED 且阻塞原因指向实现质量</trigger>
</triggers>

<parameters>
  <param name="scope_lock" required="true">scope-lock 文件路径</param>
  <param name="impl_report" required="true">最近一次 impl-report 路径</param>
  <param name="review_code" required="true">最近一次 review-code 路径（含驳回原因）</param>
  <param name="max_rounds" required="false" default="3">最大迭代轮次（与通用对抗协议一致）</param>
</parameters>

<iteration_template>
  <phase name="初始化" priority="1">
    <step>读取 scope-lock，确认白名单和完成标准</step>
    <step>读取最近一次 review-code，提取严重和一般问题清单</step>
    <step>初始化轮次计数器 M = 1，max_rounds = 3</step>
  </phase>

  <phase name="审议循环" priority="2">
    <round-step actor="实现工程师" label="步骤 A — 定向修订">
      <input>scope-lock 路径</input>
      <input>上一轮 review-code 的严重/一般问题清单（仅问题摘要，不传全文）</input>
      <input>当前轮次 M / max_rounds</input>
      <behavior>实现工程师 仅修改有问题的文件，产出 impl-report-{task-id}-{seq}_r{M}.md</behavior>
    </round-step>

    <round-step actor="高级代码审查师" label="步骤 B — 专项审查">
      <input>scope-lock 路径</input>
      <input>新 impl-report 路径</input>
      <input>上一轮 review-code 路径（对照检查问题是否真修复）</input>
      <output-format>返回 REVIEW_PASS 或 REVIEW_REJECT:{严重数}blocker:{一般数}issue</output-format>
    </round-step>

    <round-step actor="judge" label="步骤 C — 判定（遵循通用对抗协议）">
      <case condition="REVIEW_PASS">循环结束，进入下一门控</case>
      <case condition="REVIEW_REJECT 且 M &lt; max_rounds">M++，回到步骤 A</case>
      <case condition="REVIEW_REJECT 且 M ≥ max_rounds">循环结束，标记 BLOCKED，升级给 项目管理师 根因分析</case>
    </round-step>
  </phase>
</iteration_template>

<root_cause_analysis>
  <step priority="1">项目管理师 读取 scope-lock + 全部 impl-report + 全部 review-code</step>
  <step priority="2">判断阻塞根因：scope-lock 缺陷 / architecture 缺陷 / Agent 能力边界 / 需求自相矛盾</step>
  <step priority="3">产出 dispatch-{date}-adversarial-{task-id}.md</step>
  <step priority="4">仅在 项目管理师 判断为"需人工介入"时才上报用户</step>
</root_cause_analysis>

<error-handling>
  <case condition="实现工程师 连续 2 次异常（无产出/超时）">终止循环，标记 BLOCKED</case>
  <case condition="高级代码审查师 连续 2 次异常">终止循环，以最后 impl-report 为最终产出</case>
  <case condition="scope-lock 文件缺失">终止，退回 资深范围规划师</case>
</error-handling>

<relationship-to-other-protocols>
  <relation protocol="output-styles/legion-dispatch.md">通用对抗协议是本文件的父协议，本文件仅保留实现↔代码审查的具体执行细节</relation>
  <relation protocol="implementation-protocol">implementation-protocol 管单次实现纪律，本文件管多次迭代纪律</relation>
  <relation protocol="security-audit-protocol">安全审计仍独立执行，高级安全审计师 的 SECURITY_REJECT 不触发本模板</relation>
  <relation protocol="quality-verdict">质量总监 在循环结束后做最终裁决</relation>
</relationship-to-other-protocols>

</skill>
