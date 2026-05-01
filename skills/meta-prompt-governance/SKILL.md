---
name: meta-prompt-governance
description: 元提示词治理协议。为 prompt-engineer 提供 drift 诊断、边界冲突分析和新增 agent 审批标准。
when_to_use: 仅当 prompt-engineer Agent 在改 agent / skill / rule / output-style / hook 或诊断职责重叠 / dispatch 跑偏时加载。日常需求审查 / 代码审查 / 实现工作不应触发。
---

<skill name="meta-prompt-governance">

<overview>
为 prompt-engineer 提供系统级的 drift 诊断、根因分类、新增 agent 审批门槛、变更优先级排序和回归检查方法。
</overview>

<drift-diagnosis>
  <rule priority="critical">没有这三项，不要改：</rule>
  <triple>
    <item label="输入">输入是什么</item>
    <item label="期望">期望是什么</item>
    <item label="实际">实际发生了什么</item>
  </triple>
</drift-diagnosis>

<root-cause-taxonomy>
  <cause name="prompt defect">prompt 自身缺陷</cause>
  <cause name="rule conflict">规则冲突</cause>
  <cause name="routing ambiguity">路由歧义</cause>
  <cause name="capability boundary">能力边界</cause>
</root-cause-taxonomy>

<new-agent-approval-gate>
必须证明：
  <criterion priority="critical">现有 agent 无法无违约覆盖</criterion>
  <criterion priority="critical">新边界可以用例子判定</criterion>
  <criterion priority="high">维护成本小于收益</criterion>
</new-agent-approval-gate>

<change-priority>
优先考虑：
  <rank priority="1">改规则</rank>
  <rank priority="2">改 skill</rank>
  <rank priority="3">改 agent prompt</rank>
  <rank priority="4">新增 agent</rank>
</change-priority>

<regression-checklist>
每次元变更后都要列出：
  <item priority="critical">哪些输入路由会变化</item>
  <item priority="high">哪些相邻角色边界要复核</item>
  <item priority="high">哪些文档要同步</item>
</regression-checklist>

</skill>
