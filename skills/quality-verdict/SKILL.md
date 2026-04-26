---
name: quality-verdict
description: 最终质量裁决协议。为 test-lead 提供功能 / 视觉 / 安全三证据流的综合判断方法。
when_to_use: 仅当 test-lead Agent 在里程碑 / 上线前裁决（PASS / CONDITIONAL PASS / BLOCKED）时加载。单一阶段测试报告产出（functional-tester / visual-tester / security-auditor）不应触发。
---

# 最终质量裁决协议

## 三类证据

- 功能测试：主路径、边界、回归
- 视觉测试：状态、布局、交互、截图
- 安全审计：高危与未关闭风险

## 三档裁决

- `PASS`
- `CONDITIONAL PASS`
- `BLOCKED`

## 一票否决

以下任一存在时不能 PASS：

- 未关闭高危安全问题
- 核心功能失败
- 关键界面状态失真
- 关键证据缺失

## CONDITIONAL PASS 条件

仅允许：

- 核心链路已通过
- 剩余问题为中低风险
- 后续修复可独立成任务

## 输出要求

- 列清证据来源
- 写明为什么不是另外两档
- BLOCKED 必须附修复路由

## 参考样品

- `examples/sample-verdict-three-tiers.md` — PASS / CONDITIONAL PASS / BLOCKED 三档真实样品（含三档关键差异速记表）
