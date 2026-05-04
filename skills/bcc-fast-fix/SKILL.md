---
name: bcc-fast-fix
description: 极速修复模式。Agent 完全不参与——主会话直接读取、修改、验证、交付。仅适用于单文件、≤20 行、无 schema/依赖/接口变更的 trivial/small 级修复。
argument-hint: "<文件路径 + 改动描述>"
disable-model-invocation: true
---

<skill name="bcc-fast-fix" type="fast-path-fix">

<overview>
极速修复模式。Agent 完全不参与——主会话直接读取、修改、验证、交付。仅适用于单文件、≤20 行、无 schema/依赖/接口变更的 trivial/small 级修复。
</overview>

<thresholds>

<admission-gate>
准入检查（8 条，<em>全部满足</em>才走此模式）：

<checklist>
  <check id="1" label="仅 1 个文件">
    <fail>→ 退回到自然语言调度（需要 scope-lock）</fail>
  </check>
  <check id="2" label="≤20 行净增删">
    <fail>→ 同上</fail>
  </check>
  <check id="3" label="不涉及 .prisma/migration//package.json/tsconfig/Dockerfile/CI 配置/docker-compose">
    <fail>→ 退回到完整流水线</fail>
  </check>
  <check id="4" label="不改变任何函数签名/API endpoint/类型导出/接口契约">
    <fail>→ 同上——接口变更必须走 高级代码审查师</fail>
  </check>
  <check id="5" label="不引入新 import/require/依赖">
    <fail>→ 同上</fail>
  </check>
  <check id="6" label="不修改认证/授权/支付/密码逻辑">
    <fail>→ 同上 + 安全审计</fail>
  </check>
  <check id="7" label="不涉及数据库查询或 schema">
    <fail>→ 同上 + 资深数据库工程师</fail>
  </check>
  <check id="8" label="目标文件不在 .claude/ 或 .gitignore 中">
    <fail>→ 人工确认</fail>
  </check>
</checklist>

<gate-rule>任一不满足 → 拒绝走 fast-fix → 按 dispatch-table 走完整流水线。</gate-rule>

</admission-gate>

</thresholds>

<phases>

<phase id="1" name="预检">

<instructions>

<step id="1.1" title="文件审查">
<procedure>
  <item>读目标文件，确认行数 ≤500（过大文件 fast-fix 风险高）</item>
  <item>检查该文件是否在某个进行中的 scope-lock 白名单中（避免并发修改冲突）</item>
  <item>检查该文件所在目录是否有 CLAUDE.md（有 → 修完需更新变更日志）</item>
</procedure>
</step>

</instructions>

</phase>

<phase id="2" name="修改">

<instructions>

<step id="2.1" title="修改原则">
<rules>
  <rule>精确修改，不顺手修其他</rule>
  <rule>不确定 → 不猜，退回到完整流水线（用不确定项标记机制）</rule>
</rules>
</step>

</instructions>

</phase>

<phase id="3" name="验证（全部通过才交付）">

<instructions>

<step id="3.1" title="验证矩阵">
<verification-table>
  <verify name="相关测试" cmd="npx jest path/to/file.test.ts --no-coverage" fallback="修复后重试，最多 2 次 → 仍失败则退回" />
  <verify name="Lint" cmd="npx eslint path/to/file.ts 或 ruff check path/to/file.py" fallback="必须清零" />
  <verify name="Typecheck" cmd="npx tsc --noEmit 或 mypy path/to/file.py" fallback="必须通过" />
</verification-table>
</step>

</instructions>

</phase>

<phase id="4" name="CLAUDE.md 更新">

<instructions>

<step id="4.1" title="变更日志追加">
<condition>如果该文件所在目录有 CLAUDE.md</condition>：
更新变更日志：| {日期} | {改动摘要} | bcc-fast-fix |
</step>

</instructions>

</phase>

<phase id="5" name="交付">

<instructions>

<step id="5.1" title="交付报告">
<template-output>
✓ fast-fix 完成
  └ 文件: {路径}
  └ 改动: {一行描述}
  └ 验证: {测试 N passed / lint 0 / typecheck ok / CLAUDE.md 已更新}
</template-output>
</step>

</instructions>

</phase>

</phases>

<failure-handling>

<table>
  <case condition="测试失败（首轮）" action="分析原因 → 修复 → 重跑" />
  <case condition="测试失败（第 2 次）" action="最后一次重试" />
  <case condition="测试失败（第 3 次）" action="退回到完整流水线——不是 fast-fix 能解决的" />
  <case condition="Lint 告警" action="必须清零，不清零不交付" />
  <case condition="Typecheck 失败" action="必须通过，类型错误不能'快速修'" />
  <case condition="发现修改波及了其他文件" action="立即停止，退回到完整流水线" />
  <case condition="scope-lock 冲突" action="停止，报告用户——该文件有其他 Agent 正在修改" />
</table>

</failure-handling>

<prohibitions>
<item>不派任何 Agent</item>
<item>不写 impl-report（太轻量）</item>
<item>不修改白名单外文件</item>
<item>不扩大修改范围</item>
<item>不跳过验证（"这么简单应该没问题"）</item>
<item>不修改 scope-lock-guard 保护的路径</item>
<item>不同时修多个文件（即使"这两个修起来一样简单"）</item>
</prohibitions>

<output>
文件修改 + CLAUDE.md 变更日志更新。无 artifact 产出。
</output>

</skill>
