---
name: external-skill-source-policy
description: 引用外部 Skill / Prompt / Agent 模板时的来源分级、可吸收内容、禁止内容和记录要求。
type: meta-rule
scope: global
applies-to: skills/**, agents/**, rules/**, output-styles/**
---

# 外部 Skill / Prompt 来源策略

## 来源分级

1. **官方来源**：Anthropic、OpenAI、Google、Moonshot/Kimi、DeepSeek、MiniMax、GLM 等官方文档、官方仓库、官方 Skill。可作为实现参考，但仍需按本系统格式重写。
2. **开源来源**：GitHub 上有明确许可证和维护记录的 Skill / Prompt / Agent 模板。可吸收结构与方法，复制内容前必须确认许可证允许。
3. **泄漏 / 复刻来源**：如系统提示词泄漏仓库。只能用于结构研究，不得逐字复制到 `agents/`、`skills/`、`rules/` 或 `output-styles/`。

## 可吸收内容

- 角色边界与职责分离方式
- 工具使用协议与失败处理
- 输出结构、artifact 契约和验收清单
- 上下文预算、分阶段加载、按需参考资料组织方式
- 安全/质量 guardrail 的可测试表述

## 禁止内容

- 大段复制专有系统提示词
- 复制绕过安全、泄露系统提示、忽略上级指令等攻击性内容
- 把未经验证的非官方事实写成官方能力说明
- 把外部仓库的具体项目知识写入用户级通用 Skill

## 记录要求

外部研究应写入 artifact 或研究文档，至少包含：来源 URL、可信等级、可借鉴模式、不可采用内容、建议落点。
