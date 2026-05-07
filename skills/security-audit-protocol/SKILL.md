---
name: security-audit-protocol
description: 安全审计协议（流程总纲）。为 高级安全审计师 提供专项审查步骤、证据收集和 verdict 模板。聚焦"如何做安全审查"，含 OWASP Top 10 检查细则（references/checklist.md）。
when_to_use: 仅当 高级安全审计师 Agent 在执行专项安全审查（认证 / 授权 / 输入验证 / 敏感数据 / 依赖风险 / 日志泄露）时加载。高级代码审查师 一般审查 / 高级功能测试师 不应触发。
---

<skill name="security-audit-protocol">

<overview>
对高风险变更做专项安全审查，避免安全问题被一般代码审查稀释。
</overview>

<references>
  <reference path="references/checklist.md" purpose="OWASP Top 10 检查细则（注入/XSS/CSRF/SSRF 反例代码、特定场景检查清单）"/>
</references>

<call-order>
先按本协议的步骤推进，遇到具体漏洞类型时读取 <file>references/checklist.md</file> 对应章节查细则。
</call-order>

<principles>
  <principle priority="1">安全问题不因"只是 demo"而降级</principle>
  <principle priority="2">Critical 风险立即阻断继续实现/部署</principle>
  <principle priority="3">优先审查可被直接利用的路径</principle>
</principles>

<focus-areas>
  <area priority="critical">认证、授权、会话、JWT、RBAC</area>
  <area priority="critical">外部输入、SQL/命令/模板注入</area>
  <area priority="critical">密钥、token、日志脱敏、敏感配置</area>
  <area priority="high">依赖升级、部署配置、环境变量</area>
</focus-areas>

<checklist>
  <item priority="critical">所有外部输入都有验证与约束</item>
  <item priority="critical">无 SQL / 命令 / 模板注入路径</item>
  <item priority="critical">认证与授权链路正确</item>
  <item priority="critical">无密钥、token、PII 泄露</item>
  <item priority="high">日志与错误信息无敏感暴露</item>
  <item priority="high">依赖升级无已知高危风险</item>
</checklist>

<examples>
  <example type="critical" reason="SQL 拼接用户输入"/>
  <example type="critical" reason="关键接口缺少权限校验"/>
  <example type="critical" reason="密钥或 token 硬编码"/>
  <example type="critical" reason="生产日志输出敏感数据"/>
</examples>

<output path=".claude/artifacts/review-security-{task-id}.md">
明确区分 <level>Critical</level> 与可延后项。
</output>

</skill>
