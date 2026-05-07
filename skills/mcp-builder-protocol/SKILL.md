---
name: mcp-builder-protocol
description: MCP Server 构建协议。用于设计、实现、审查 MCP 工具，强调工具 schema、鉴权边界、错误处理、最小权限和可观测性。
when_to_use: 当用户要设计、实现、调试或审查 MCP server、MCP tools、外部 API 工具接入或 agent 工具协议时使用。
---

<skill>
  <overview>MCP Server 构建协议。用于设计、实现、审查 MCP 工具，强调工具 schema、鉴权边界、错误处理、最小权限和可观测性。</overview>

  <workflow>
    <step n="1">明确集成目标：外部系统、用户任务、只读/写入能力、权限边界。</step>
    <step n="2">设计工具：名称、描述、输入 schema、输出结构、错误类型、幂等性。</step>
    <step n="3">鉴权：凭据来源、最小权限、过期/撤销、日志脱敏。</step>
    <step n="4">实现：参数验证、超时、重试、速率限制、结构化错误。</step>
    <step n="5">测试：schema 校验、happy path、权限不足、外部超时、无效输入。</step>
    <step n="6">文档：安装、配置、示例调用、安全注意事项。</step>
  </workflow>

  <checklist>
    <constraint id="no-escalation-bait">工具描述不能诱导模型越权。</constraint>
    <constraint id="no-secret-in-output">不把 secret 放入工具输出或日志。</constraint>
    <constraint id="write-auditable">写操作必须可审计，危险操作需要确认或 dry-run。</constraint>
  </checklist>

  <reference>
    <file path="references/tool-design-template.md" purpose="tool design template"/>
    <file path="references/security-checklist.md" purpose="security checklist"/>
    <note>需要细化检查、模板或失败分类时，按需读取这些 supporting files；不要把长参考默认塞入主上下文。</note>
  </reference>
</skill>
