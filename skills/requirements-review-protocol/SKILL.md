---
name: requirements-review-protocol
description: 需求审查协议。为 高级需求审查师 提供完整性、可测试性、边界与风险审查清单。
when_to_use: 仅当 高级需求审查师 或 资深需求分析师 Agent 在审查 requirements-* artifact 时加载。需求收集阶段（客户需求整理师 / 资深需求分析师 还在写）不应触发。
---

<skill name="requirements-review-protocol">

<overview>
确保 requirements artifact 可以作为可靠的下游输入。
</overview>

<principles>
  <principle priority="1">Critical 一票否决：需求模糊到影响架构阶段时，必须退回</principle>
  <principle priority="2">可测试优先：不接受"优化体验""支持导入"这类空泛描述</principle>
  <principle priority="3">边界先行：空输入、失败路径、权限不足、并发条件都要显式出现</principle>
  <principle priority="4">依赖清晰：Task 间依赖、外部系统、潜在冲突必须写出来</principle>
</principles>

<checklist>
  <section name="完整性">
    <item priority="critical">每个 Task 都有明确目标和交付内容</item>
    <item priority="high">业务目标清楚，不只是罗列改动</item>
    <item priority="high">风险和待确认事项被显式列出</item>
  </section>

  <section name="可测性">
    <item priority="critical">每个 Task 都有至少一条可测试验收标准</item>
    <item priority="high">标准描述行为/结果，不描述实现方案</item>
    <item priority="medium">性能、安全、合规等隐性要求在需要时被显式化</item>
  </section>

  <section name="边界">
    <item priority="critical">成功路径清晰</item>
    <item priority="critical">失败路径清晰</item>
    <item priority="high">特殊输入被考虑（空、超长、异常值）</item>
    <item priority="high">权限/角色边界被考虑（如适用）</item>
  </section>

  <section name="依赖与冲突">
    <item priority="high">Task 间依赖被正确标注</item>
    <item priority="high">与现有功能冲突已识别</item>
    <item priority="medium">外部依赖或前置条件已识别</item>
  </section>
</checklist>

<examples>
  <example type="critical" reason='"提升搜索体验" —— 不可测'/>
  <example type="critical" reason='"支持导入" —— 未说明格式、上限、失败处理'/>
  <example type="critical" reason='"接入订单模块" —— 未说明交互和成功标准'/>
</examples>

<output path=".claude/artifacts/review-requirements-{task-id}.md">
按 <level>Critical</level> / <level>Warning</level> / <level>Suggestion</level> / 未覆盖项 结构组织。
</output>

<references>
  <reference path="examples/sample-review-requirements.md" purpose="客户群发推送需求审查样品（4 维度矩阵：完整性 / 可测性 / 边界 / 风险，带 5 处具体 Issue + 修复建议）"/>
</references>

</skill>
