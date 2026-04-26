---
name: security-audit-protocol
description: 安全审计协议（流程总纲）。为 security-auditor 提供专项审查步骤、证据收集和 verdict 模板。聚焦"如何做安全审查"，与 security-checklist（OWASP 检查细则）配合使用。
when_to_use: 仅当 security-auditor Agent 在执行专项安全审查（认证 / 授权 / 输入验证 / 敏感数据 / 依赖风险 / 日志泄露）时加载。code-reviewer 一般审查 / functional-tester 不应触发。
---

# 安全审计协议（流程总纲）

## 与 security-checklist 的分工

| 文件 | 职责 | 何时用 |
|:--|:--|:--|
| **security-audit-protocol（本文件）** | **流程总纲**：审查步骤、证据收集、verdict 模板、Critical 阻断规则 | security-auditor 主流程 |
| **security-checklist** | **检查细则**：OWASP Top 10 具体漏洞模式、注入/XSS/CSRF 反例代码 | 本协议每步深入时引用 |

调用顺序：先按本协议的步骤推进，遇到具体漏洞类型时跳到 security-checklist 对应章节查细则。

## 目标

对高风险变更做专项安全审查，避免安全问题被一般代码审查稀释。

## 通用原则

1. **安全问题不因“只是 demo”而降级**
2. **Critical 风险立即阻断继续实现/部署**
3. **优先审查可被直接利用的路径**

## 重点场景

- 认证、授权、会话、JWT、RBAC
- 外部输入、SQL/命令/模板注入
- 密钥、token、日志脱敏、敏感配置
- 依赖升级、部署配置、环境变量

## 检查清单

- [ ] 所有外部输入都有验证与约束
- [ ] 无 SQL / 命令 / 模板注入路径
- [ ] 认证与授权链路正确
- [ ] 无密钥、token、PII 泄露
- [ ] 日志与错误信息无敏感暴露
- [ ] 依赖升级无已知高危风险

## Critical 示例

- ✗ SQL 拼接用户输入
- ✗ 关键接口缺少权限校验
- ✗ 密钥或 token 硬编码
- ✗ 生产日志输出敏感数据

## 输出

写入 `.claude/artifacts/review-security-{task-id}.md`，明确区分 `Critical` 与可延后项。
