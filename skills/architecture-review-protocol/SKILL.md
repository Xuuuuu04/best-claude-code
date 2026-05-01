---
name: architecture-review-protocol
description: 架构审查协议。为 architecture-reviewer 提供 design 与 scope-lock 的可执行性审查清单。
when_to_use: 仅当 architecture-reviewer Agent 在审查 architecture-* 或 scope-lock-* artifact 时加载。架构方案产出阶段（architect 在写）、代码审查阶段不应触发。
---

<skill name="architecture-review-protocol">

<overview>
确保 architecture 与 scope-lock 能稳定指导实现，而不是把歧义继续传给 implementer。
</overview>

<principles>
  <principle priority="1">设计不能把歧义下放：下游 implementer 不应继续补需求</principle>
  <principle priority="2">scope-lock 是实现契约，不是提醒清单</principle>
  <principle priority="3">架构与范围必须一致：不能 architecture 说 A，scope-lock 写成 B</principle>
  <principle priority="4">可执行优于优雅：设计可以普通，但必须稳定可实现</principle>
</principles>

<checklist>
  <section name="技术选型">
    <item priority="high">新旧技术栈选择有理由</item>
    <item priority="medium">没有明显过度工程</item>
    <item priority="medium">没有明显欠工程</item>
  </section>

  <section name="契约">
    <item priority="critical">类型、签名、字段、错误路径完整</item>
    <item priority="critical">与 requirements 一致</item>
    <item priority="high">与现有风格不冲突</item>
  </section>

  <section name="scope-lock-质量">
    <item priority="critical">精确到文件和关键函数</item>
    <item priority="critical">白名单与禁止事项都完整</item>
    <item priority="high">验证命令可运行</item>
    <item priority="high">完成标准可逐条勾选</item>
    <item priority="medium">推荐 implementer 合理</item>
  </section>

  <section name="执行关系">
    <item priority="high">并行依赖图清晰</item>
    <item priority="critical">没把多个无关任务强塞进一个 scope-lock</item>
  </section>
</checklist>

<examples>
  <example type="critical" reason='"修改 auth 模块" —— 不够精确'/>
  <example type="critical" reason="scope-lock 未列禁止事项 —— 越界风险过高"/>
  <example type="critical" reason="architecture 与 requirements 冲突 —— 下游无从判断"/>
</examples>

<output path=".claude/artifacts/review-architecture-{task-id}.md"/>

<references>
  <reference path="examples/sample-review-architecture.md" purpose="实时通知系统架构审查样品（6 维度矩阵 + scope-lock 文件冲突 Critical 处理 + 过度/欠工程平衡建议）"/>
</references>

</skill>
