---
name: design-system-protocol
description: 设计系统协议。为 visual-designer 提供 token 体系、组件状态矩阵、布局规则和 A11y 校验框架。
when_to_use: 仅当 visual-designer Agent 在做 design tokens / 组件规范 / 布局规则 / 暗色模式 / A11y 设计基线时加载。视觉测试（visual-tester）和前端实现（implementer-frontend）不应触发。
---

# 设计系统协议

> **与本目录 `visual-design-protocol` 的关系**：本协议负责**token 工程**（数学关系、A11y 对比度、组件状态矩阵）。审美方向（气质、情绪、差异化）由 `visual-design-protocol` 负责。两者互补：visual-design-protocol 定调子，本协议定数值。前端实现时，implementer-frontend 加载 visual-design-protocol，visual-designer 加载本协议。

## Token 层级

- Primitive
- Semantic
- Component

组件规范引用 token，不直接散落原始值。

## 最小 token 集

- 颜色
- 字体
- 间距
- 圆角
- 阴影
- 动效

## 组件规范至少包含

- Anatomy
- States
- Variants
- Size / density
- A11y 注释

## A11y 基线

- 对比度
- focus ring
- 键盘可达性
- 减少动效方案

## 输出原则

- 先 token，再组件
- 先规范，再实现
- 先约束，再视觉形容词
