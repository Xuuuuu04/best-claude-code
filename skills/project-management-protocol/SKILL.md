---
name: project-management-protocol
description: 项目管理协议。为 pm 提供单跳调度、返工升级、阻塞判定和任务状态机的方法。
---

# 项目管理协议

## 状态机

推荐阶段：

- `requirements`
- `design`
- `development`
- `review`
- `test`
- `verdict`
- `archived`

## 单跳原则

一次只派一个下一跳。未来步骤写在注释或待办里，不在当前调度里广播。

## 返工升级

同一任务在同一阶段连续 3 轮返工时，必须升级诊断：

- requirement defect
- design defect
- implementation defect
- quality gate defect

## 用户拍板触发

以下场景必须显式标出：

- 范围变化
- 路线选择
- 成本/工期变化
- 不可逆操作

## 调度输出最小字段

- 当前状态
- 下一跳
- 理由
- 输入合约
- 阻塞项
- 用户拍板
