---
name: agent-guardrails-protocol
description: Agent Guardrails 协议。用于设计或审查 Agent、Skill、Hook、Output Style，强调权限边界、handoff、失败分类和用户拍板触发条件。
when_to_use: 当设计或审查 Agent、Skill、Hook、Output Style、调度规则、handoff、权限边界或失败分类时使用。
---

# Agent Guardrails 协议

## 检查维度

1. 职责边界：这个 Agent 做什么、不做什么、何时停止。
2. 工具边界：允许工具、禁止工具、危险操作确认、写入范围。
3. 上下文边界：默认加载什么、按需读取什么、避免什么污染。
4. Handoff：输入 artifact、输出 artifact、下一跳、失败返回格式。
5. 失败分类：BLOCKED、FAILED、NEEDS_USER、OUT_OF_SCOPE。
6. 验证：如何证明它按边界工作，而不是自证正确。

## 输出要求

给出 `PASS / WARNING / BLOCKED`，并列出必须修改项、建议项和不采纳理由。

## 支持文件

- `references/review-template.md`：review template。
- `references/failure-taxonomy.md`：failure taxonomy。

需要细化检查、模板或失败分类时，按需读取这些 supporting files；不要把长参考默认塞入主上下文。
