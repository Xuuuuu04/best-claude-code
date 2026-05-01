---
name: redeliberation-protocol
description: "再审议协议。当 implementer 同一 scope-lock 被 code-reviewer 驳回 ≥2 次，或 test-lead 因实现问题裁定 BLOCKED 时自动加载。实现 A-B 审议迭代闭环（implementer ↔ reviewer），judge 判定终止，max 3 轮。"
when_to_use: "实现被驳回 ≥2 次 / test-lead BLOCKED / 同一 scope 反复返工 / code-reviewer 多次 REJECT"
---

<skill name="redeliberation-protocol">

<overview>
本协议实现「A-B 审议迭代」闭环：当 implementer 的同一 scope-lock 被反复驳回时，将隐式返工显式化为有计数器、有上限、有历史记录的受控循环。

<roles>
  <role id="A">implementer（执行实现，产出 impl-report）</role>
  <role id="B">code-reviewer（审查实现，产出 review-code）</role>
  <role id="judge">test-lead 或主会话（判定终止或重试）</role>
</roles>

循环最多 3 轮。每轮 A → B → judge，judge 判定 PASS 则结束，RETRY 则进入下一轮。
</overview>

<triggers>
  <trigger priority="critical">code-reviewer 对同一 scope-lock 返回 <token>REVIEW_REJECT</token> 这是第 2 次</trigger>
  <trigger priority="critical">test-lead 返回 <token>VERDICT_BLOCKED</token> 且阻塞原因指向实现质量</trigger>
  <trigger priority="high">implementer 的 impl-report 被同一 reviewer 驳回 ≥2 次</trigger>
  <trigger priority="high">主会话检测到同一 scope-lock 的 <file>review-code-*</file> 文件 ≥2 个且最新为 REJECT</trigger>
</triggers>

<non-triggers>
  <case>安全审计驳回（那是 security-auditor 的独立 gate，不走实现迭代）</case>
</non-triggers>

<parameters>
  <param name="scope_lock" required="true">scope-lock 文件路径</param>
  <param name="impl_report" required="true">最近一次 impl-report 路径</param>
  <param name="review_code" required="true">最近一次 review-code 路径（含驳回原因）</param>
  <param name="max_rounds" required="false" default="3">最大迭代轮次</param>
</parameters>

<file-conventions>
在 scope-lock 同目录下追加迭代文件：

  <file role="主会话维护"><var>{scope-lock 同目录}</var>/redelib_v{M}.md — 记录每轮判定</file>

代码修改直接覆盖原文件（同 scope-lock 白名单路径），不创建额外分支。
</file-conventions>

<instructions>
  <phase name="初始化" priority="1">
    <step>读取 scope-lock，确认白名单和完成标准</step>
    <step>读取最近一次 review-code，提取严重和一般问题清单</step>
    <step>初始化轮次计数器 M = 1，max_rounds = 3</step>
  </phase>

  <phase name="审议循环（最多 max_rounds 轮）" priority="2">
每轮依次执行：

    <round-step actor="implementer" label="步骤 A — 定向修订">
调度器派遣 implementer，prompt 中传入：
      <input>scope-lock 路径</input>
      <input>上一轮 review-code 的严重/一般问题清单（仅问题摘要，不传全文）</input>
      <input>当前轮次 M / max_rounds</input>
      <behavior>implementer 仅修改有问题的文件，产出 <artifact>impl-report-{task-id}-{seq}_r{M}.md</artifact></behavior>
    </round-step>

    <round-step actor="code-reviewer" label="步骤 B — 专项审查">
调度器派遣 code-reviewer，prompt 中传入：
      <input>scope-lock 路径</input>
      <input>新 impl-report 路径</input>
      <input>上一轮 review-code 路径（对照检查问题是否真修复）</input>
      <output-format>返回 <token>REVIEW_PASS</token> 或 <token>REVIEW_REJECT:{严重数}blocker:{一般数}issue</token></output-format>
    </round-step>

    <round-step actor="judge" label="步骤 C — 判定">
      <case condition="REVIEW_PASS">循环结束，进入最终阶段</case>
      <case condition="REVIEW_REJECT 且 M &lt; max_rounds">M++，回到步骤 A</case>
      <case condition="REVIEW_REJECT 且 M ≥ max_rounds">循环结束，进入最终阶段（标记为 BLOCKED）</case>
    </round-step>
  </phase>

  <phase name="向用户返回结果" priority="3">
    <case condition="通过">再审议通过，最终产出：<var>{impl-report 路径}</var>，共 <var>{M}</var> 轮</case>
    <case condition="未通过">再审议未通过（<var>{max_rounds}</var> 轮后仍驳回），最终阻塞问题：<var>{严重数}</var>blocker <var>{一般数}</var>issue，建议人工介入</case>
  </phase>
</instructions>

<error-handling>
  <case condition="implementer 连续 2 次异常（无产出/超时）">终止循环，标记 BLOCKED</case>
  <case condition="code-reviewer 连续 2 次异常">终止循环，以最后 impl-report 为最终产出</case>
  <case condition="scope-lock 文件缺失">终止，退回 scope-planner</case>
</error-handling>

<relationship-to-other-protocols>
  <relation protocol="implementation-protocol">本协议包装 implementer + code-reviewer 的交互，不替代它们</relation>
  <relation protocol="security-audit-protocol">安全审计仍独立执行，security-auditor 的 <token>SECURITY_REJECT</token> 不触发本协议</relation>
  <relation protocol="quality-verdict">test-lead 在本协议中承担 judge 角色，或在循环结束后做最终裁决</relation>
  <relation protocol="implementation-protocol" complement="true">implementation-protocol 管单次实现纪律，本协议管多次迭代纪律</relation>
</relationship-to-other-protocols>

<escalation name="穷尽升级（max_rounds 耗尽时）">
再审议 3 轮后仍被驳回时，<emphasis>不直接上报用户</emphasis>。先派遣 <agent>pm</agent> 做根因分析：

  <step priority="1">pm 读取 scope-lock + 全部 impl-report + 全部 review-code</step>
  <step priority="2">pm 判断阻塞根因：</step>

  <root-cause-analysis>
    <cause name="scope-lock 缺陷" symptom="白名单遗漏、接口契约不清">
      <action>退回 <agent>scope-planner</agent> 修订 scope-lock，重新开始</action>
    </cause>
    <cause name="architecture 缺陷" symptom="设计不可行">
      <action>退回 <agent>architect</agent>，重新设计</action>
    </cause>
    <cause name="implementer 能力边界" symptom="确实做不到">
      <action>上报用户，建议人工介入或拆更小 scope</action>
    </cause>
  </root-cause-analysis>

  <step priority="3">pm 产出 <artifact>dispatch-{date}-redelib-{task-id}.md</artifact></step>

仅在 pm 也判断为"需人工介入"时才上报用户。
</escalation>

</skill>
