---
name: project-management-protocol
description: 项目管理协议。为 pm 提供单跳调度、返工升级、阻塞判定和任务状态机的方法。
when_to_use: 仅当 pm Agent 在做"下一跳判断 / 返工升级 / 阻塞处理 / 多阶段任务推进"时加载。单一 Agent 自身工作流不应触发。
---

<skill name="project-management-protocol">

<overview>
为 pm 提供任务状态机、单跳调度原则、返工升级阈值、用户拍板触发条件和最小调度输出字段。
</overview>

<state-machine>
推荐阶段：
  <state>requirements</state>
  <state>design</state>
  <state>development</state>
  <state>review</state>
  <state>test</state>
  <state>verdict</state>
  <state>archived</state>
</state-machine>

<single-hop-principle>
  <rule priority="critical">一次只派一个下一跳。未来步骤写在注释或待办里，不在当前调度里广播。</rule>
</single-hop-principle>

<rework-escalation>
  <rule priority="critical">同一任务在同一阶段连续 3 轮返工时，必须升级诊断：</rule>
  <root-cause-taxonomy>
    <cause>requirement defect</cause>
    <cause>design defect</cause>
    <cause>implementation defect</cause>
    <cause>quality gate defect</cause>
  </root-cause-taxonomy>
</rework-escalation>

<user-escalation-triggers>
以下场景必须显式标出：
  <trigger priority="critical">范围变化</trigger>
  <trigger priority="critical">路线选择</trigger>
  <trigger priority="high">成本/工期变化</trigger>
  <trigger priority="critical">不可逆操作</trigger>
</user-escalation-triggers>

<dispatch-output-fields>
最小字段：
  <field name="当前状态" required="true"/>
  <field name="下一跳" required="true"/>
  <field name="理由" required="true"/>
  <field name="输入合约" required="true"/>
  <field name="阻塞项" required="true"/>
  <field name="用户拍板" required="true"/>
</dispatch-output-fields>

</skill>
