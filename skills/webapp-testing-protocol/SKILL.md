---
name: webapp-testing-protocol
description: Web 应用测试协议。用于本地 Web 应用的功能验证、UI 调试、截图证据、console/network 诊断和可访问性冒烟检查。
when_to_use: 当需要验证本地 Web 应用、UI 交互、页面截图、console/network 错误、回归路径或可访问性冒烟测试时使用。
---

<skill>
  <overview>Web 应用测试协议。用于本地 Web 应用的功能验证、UI 调试、截图证据、console/network 诊断和可访问性冒烟检查。</overview>

  <workflow>
    <step n="1">侦察：确认启动命令、URL、测试账号、关键路径和环境变量需求。</step>
    <step n="2">启动或连接本地服务；记录端口、页面路径和初始状态。</step>
    <step n="3">先观察再操作：检查 console、network、可见布局和交互入口。</step>
    <step n="4">按用户路径执行：输入、点击、跳转、错误状态、刷新、响应式尺寸。</step>
    <step n="5">采集证据：截图、console error、network failure、复现步骤、实际/期望差异。</step>
    <step n="6">汇报结论：PASS / FAIL / BLOCKED，并列出阻塞原因和最小复现。</step>
  </workflow>

  <checklist>
    <constraint id="screenshot-required">不只用文字描述 UI，涉及视觉变化必须有截图路径。</constraint>
    <constraint id="classify-root-cause">不把 flaky 环境问题当功能失败；要区分环境、数据、代码、网络。</constraint>
    <constraint id="no-prod-destructive">不在真实生产环境做破坏性操作。</constraint>
  </checklist>

  <reference>
    <file path="references/evidence-template.md" purpose="evidence template"/>
    <file path="references/pitfalls.md" purpose="pitfalls"/>
    <note>需要细化检查、模板或失败分类时，按需读取这些 supporting files；不要把长参考默认塞入主上下文。</note>
  </reference>
</skill>
