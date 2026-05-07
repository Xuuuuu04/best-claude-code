---
name: functional-test-protocol
description: 功能测试协议。为 高级功能测试师 提供验收标准验证、边界构造和回归检查步骤。
when_to_use: 仅当 高级功能测试师 Agent 在执行验收标准验证 / 边界场景 / 回归测试 / 端到端用户路径时加载。视觉测试 / 安全审查 / 代码审查不应触发。
---

<skill name="functional-test-protocol">

<overview>
验证实现满足 requirements 中的验收标准，并且没有引入明显回归。
</overview>

<principles>
  <principle priority="1">以验收标准为准，而不是以实现者报告为准</principle>
  <principle priority="2">边界场景必须主动构造</principle>
  <principle priority="3">回归验证不可省略</principle>
</principles>

<instructions>
  <step priority="1">运行项目测试套件与必要的集成命令</step>
  <step priority="2">逐条对照 requirements 的验收标准</step>
  <step priority="3">构造空输入、极限输入、失败路径、权限不足等边界场景</step>
  <step priority="4">对 bug 修复验证回归场景，对重构验证行为等价性</step>
</instructions>

<examples>
  <example type="critical" reason="测试套件失败"/>
  <example type="critical" reason="关键验收标准未被验证"/>
  <example type="critical" reason="回归场景未覆盖"/>
</examples>

<output path=".claude/artifacts/review-functional-{task-id}.md"/>

<references>
  <reference path="examples/sample-review-functional.md" purpose="并发 bug 修复的功能验证样品（验收标准矩阵 / 边界场景表 / 回归历史复现 / 验收建议）"/>
</references>

</skill>
