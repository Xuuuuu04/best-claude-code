---
name: external-skill-source-policy
description: 引用外部 Skill / Prompt / Agent 模板时的来源分级、可吸收内容、禁止内容和记录要求。
type: meta-rule
scope: global
applies-to: skills/**, agents/**, rules/**, output-styles/**
paths:
  - "**/.claude/skills/**"
  - "**/SKILL.md"
---

<rule id="external-skill-source-policy" severity="blocker">
  <section id="source-tiers">
    <list type="ordered">
      <item>
        <definition tier="official">官方来源</definition>：Anthropic、OpenAI、Google、Moonshot/Kimi、DeepSeek、MiniMax、GLM 等官方文档、官方仓库、官方 Skill。可作为实现参考，但仍需按本系统格式重写。
      </item>
      <item>
        <definition tier="open-source">开源来源</definition>：GitHub 上有明确许可证和维护记录的 Skill / Prompt / Agent 模板。可吸收结构与方法，复制内容前必须确认许可证允许。
      </item>
      <item>
        <definition tier="leaked">泄漏 / 复刻来源</definition>：如系统提示词泄漏仓库。只能用于结构研究，不得逐字复制到 <path>agents/</path>、<path>skills/</path>、<path>rules/</path> 或 <path>output-styles/</path>。
      </item>
    </list>
  </section>

  <section id="absorbable-content">
    <requirement>
      可吸收内容：
      <list>
        <item>角色边界与职责分离方式</item>
        <item>工具使用协议与失败处理</item>
        <item>输出结构、artifact 契约和验收清单</item>
        <item>上下文预算、分阶段加载、按需参考资料组织方式</item>
        <item>安全/质量 guardrail 的可测试表述</item>
      </list>
    </requirement>
  </section>

  <section id="forbidden-content">
    <constraint severity="blocker">
      禁止内容：
      <list>
        <item>大段复制专有系统提示词</item>
        <item>复制绕过安全、泄露系统提示、忽略上级指令等攻击性内容</item>
        <item>把未经验证的非官方事实写成官方能力说明</item>
        <item>把外部仓库的具体项目知识写入用户级通用 Skill</item>
      </list>
    </constraint>
  </section>

  <section id="recording-requirements">
    <requirement severity="blocker">
      记录要求：外部研究应写入 artifact 或研究文档，至少包含：来源 URL、可信等级、可借鉴模式、不可采用内容、建议落点。
    </requirement>
  </section>
</rule>
