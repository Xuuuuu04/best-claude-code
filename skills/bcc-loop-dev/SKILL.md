---
name: bcc-loop-dev
description: 顶级团队自主开发模式。全部 Agent 团队自动循环迭代，人工仅在安全漏洞和生产部署等不可逆操作时介入。自动 git commit+push，智能自适应并发，以最大轮次和最高代价持续迭代直到世界级严正交付。
argument-hint: "<任务描述> (完整功能需求)"
disable-model-invocation: true
---

<skill name="bcc-loop-dev" type="autonomous-development-loop">

<overview>
顶级团队自主开发模式。全部 Agent 团队自动循环迭代，人工仅在安全漏洞和生产部署等不可逆操作时介入。自动 git commit+push，智能自适应并发，以最大轮次和最高代价持续迭代直到世界级严正交付。
</overview>

<core-principles>
<principle id="human-gate">人工仅在安全 + 不可逆时介入（生产部署、DB schema 变更、API 密钥变更、安全漏洞）</principle>
<principle id="auto-git">每 scope-lock 通过完整流水线后 auto commit + push；失败时 auto revert 到上一个 commit</principle>
<principle id="adaptive-concurrency">优先标准并发（S0-S3），遭遇 agent 失败/限流时动态降级，恢复后自动尝试升回高并发</principle>
<principle id="token-routing">收 IMPL_DONE → 派 code-reviewer；收 REVIEW_REJECT → redeliberation；收 VERDICT_PASS → 提交+下一 scope</principle>
<principle id="self-healing">redeliberation 自动循环 + pm 穷尽升级 + reviewer 漏审反馈写入 agent-memory</principle>
</core-principles>

<preflight>
启动前检查：
<item>项目已有 .claude/CLAUDE.md（如无，先跑 /bcc-init-project）</item>
<item><cmd>bash ~/.claude/bin/doctor.sh</cmd> 通过</item>
<item>确认当前分支干净（git status --porcelain 为空或仅含 .claude/ 下文件）</item>
<item>向用户确认任务描述和成功标准</item>
</preflight>

<phases>

<phase id="1" name="规划">

<instructions>

<step id="1.1" title="需求分析">
派 product-analyst → 产出 requirements
<next>→ requirements-reviewer（含对抗性压力测试）</next>
</step>

<step id="1.2" title="架构设计">
派 architect → 产出 architecture
<next>→ architecture-reviewer（含断点分析）</next>
</step>

<step id="1.3" title="范围锁定">
派 scope-planner → 产出 scope-lock[] + scope-plan（含集成风险标记 + 并行批次规划）
</step>

</instructions>

</phase>

<phase id="2" name="实现（按 Batch 推进，自适应并发）">

<instructions>

<step id="2.1" title="并发实现">
for each Batch:
<procedure>
  <item>并发派 implementer-*（attempt S2 并发）</item>
  <item>收集 IMPL_DONE token</item>
</procedure>
</step>

<step id="2.2" title="自适应降级">
如某 implementer 失败/超时：
<degradation>
  <stage level="降级">该 Batch 改为串行</stage>
  <stage level="观察">之后 3 个 Batch 保持低并发</stage>
  <stage level="恢复">3 Batch 无失败 → 尝试恢复到标准并发</stage>
</degradation>
</step>

<step id="2.3" title="代码审查">
串行派 code-reviewer（6 维审查含对抗性）
<branch>
  <case condition="REVIEW_REJECT">→ redeliberation（max 3 轮）</case>
  <case condition="REVIEW_PASS">→ 继续</case>
</branch>
</step>

</instructions>

</phase>

<phase id="3" name="验证">

<instructions>

<step id="3.1" title="安全审计">
<condition>如涉后端/认证/支付</condition>：派 security-auditor（OWASP + 7 维业务逻辑攻击）
</step>

<step id="3.2" title="功能测试">
派 functional-tester（验收+边界+回归）
</step>

<step id="3.3" title="视觉测试">
<condition>如涉 UI</condition>：派 visual-tester（5 状态截图证据）
</step>

</instructions>

</phase>

<phase id="4" name="裁决与交付">

<instructions>

<step id="4.1" title="跨 scope 一致性">
<condition>scope-lock ≥ 3</condition> → test-lead 含跨 scope 一致性检查
</step>

<step id="4.2" title="最终裁决">
test-lead 汇总 functional+visual+security + 一致性 + reviewer 质量反馈
<verdict-branch>
  <case condition="VERDICT_PASS">→ git commit+push → 下一 scope</case>
  <case condition="VERDICT_CONDITIONAL">→ 人工确认</case>
  <case condition="VERDICT_BLOCKED">→ 回到阶段 1 修复</case>
</verdict-branch>
</step>

</instructions>

</phase>

</phases>

<git-automation>
每个 scope-lock 的完整流水线通过后（VERDICT_PASS）：
<cmd-block>git add -A
git commit -m "feat({scope-name}): {scope 描述} — 通过 code-reviewer+security+test+verdict"
git push</cmd-block>

如后续 scope 失败需要回滚：
<cmd-block>git revert {commit} --no-edit
git push</cmd-block>
</git-automation>

<adaptive-concurrency>
并发等级状态机：

<state-machine>
  <state name="标准" level="S2" trigger="默认">同 Batch scope-lock 全部并行</state>
  <state name="降级" level="S0" trigger="任意 Agent 返回异常/超时/连续 2 次 REVIEW_REJECT">同 Batch 全部串行</state>
  <state name="恢复试探" level="S1" trigger="降级后连续 3 Batch 无异常">同 Batch 2 个并行</state>
  <state name="恢复标准" level="S2" trigger="S1 稳定后再 3 Batch 无异常">回到标准并发</state>
</state-machine>

<note>并发变更只影响后续 Batch，不中断正在运行的 Agent。</note>
</adaptive-concurrency>

<decision-boundary>

<auto-decisions>以下不问人：
<item>所有非生产的技术决策</item>
<item>staging 部署</item>
<item>scope-lock 拆分和 Agent 选择</item>
<item>代码审查-修复循环</item>
<item>git commit + push</item>
<item>自适应并发调整</item>
</auto-decisions>

<pause-ask-user>以下暂停 AskUserQuestion：
<item>生产部署</item>
<item>DB schema 变更</item>
<item>API 密钥/endpoint 变更</item>
<item>SECURITY_REJECT — 立即暂停</item>
<item>git push --force / 删除分支/tag/云资源</item>
<item>引入新语言/框架</item>
</pause-ask-user>

<protocol>到达决策点时：描述当前状态 + 为什么需要决策 + 推荐选项及后果 → 等待回复。</protocol>

</decision-boundary>

<delivery-standard>

<standards>
  <standard name="代码审查" criteria="所有 scope-lock REVIEW_PASS" fallback="继续 redeliberation" />
  <standard name="对抗性" criteria="code-reviewer 维度 6 全部 [通过]" fallback="退回 implementer" />
  <standard name="安全" criteria="涉后端/认证/支付 → SECURITY_PASS + 业务逻辑攻击 7 维全 [通过]" fallback="退回 implementer" />
  <standard name="功能" criteria="TEST_PASS，含边界/回归/并发" fallback="退回 implementer" />
  <standard name="视觉" criteria="UI 变更 → VISUAL_PASS + 5 状态截图" fallback="退回 implementer" />
  <standard name="跨 scope" criteria="scope-lock ≥3 → 一致性检查 PASS" fallback="退回 architect/scope-planner" />
  <standard name="测试覆盖" criteria="新增代码 ≥85%" fallback="退回 implementer 补测试" />
  <standard name="文档" criteria="受影响 CLAUDE.md 变更日志已更新" fallback="补文档" />
  <standard name="裁决" criteria="test-lead VERDICT_PASS" fallback="继续迭代" />
</standards>

<rule>任一不满足 → 继续。</rule>

</delivery-standard>

<thresholds>

<safety-valves>
  <valve condition="同一 scope-lock 迭代 ≥5 轮仍未 PASS" action="暂停，报告用户——scope 可能有根本缺陷" />
  <valve condition="连续 3 个 scope-lock 均 BLOCKED" action="退回 architect 重新设计" />
  <valve condition="总派遣次数 ≥100" action="暂停，汇报进度+消耗，请用户确认继续" />
  <valve condition="test-lead 连续 2 次 CONDITIONAL PASS" action="视为 PASS（条件已足够轻微）" />
  <valve condition="连续 5 次 Agent 派遣全部异常" action="暂停，系统性故障" />
  <valve condition="安全漏洞发现" action="立即暂停，等用户决策" />
</safety-valves>

</thresholds>

<progress-report>
每 scope-lock 完成：
<template>
[loop-dev] {n}/{total} scope 完成
  git: {commit hash} — {commit message}
  消耗: {本次派遣数} 派遣 / {累计} 累计
</template>
每 20 次派遣汇报 token 消耗。
</progress-report>

<health-self-check>
每轮循环后检查：
<item>近 10 次派遣失败率 &gt;30% → 暂停诊断</item>
<item>连续 3 次 redeliberation 穷尽 → 暂停</item>
<item>同类型驳回 pattern 重复 ≥3 次 → 标记 + 写 agent-memory</item>
<item>scope-lock 平均 turns &gt;30 → 提醒 scope-planner 粒度偏大</item>
<item>自适应并发当前状态 → 汇报</item>
</health-self-check>

<resume>
中断后可通过描述续跑。loop-dev 自动扫描 artifact 状态，跳过已 accepted 的 scope，从断点继续。续跑时恢复自适应并发状态为"标准"，让系统重新试探。
</resume>

<output>
Git commits + artifact 文件（由各阶段 Agent 产出）。
</output>

</skill>
