---
name: visual-design-protocol
description: 视觉设计协议。用于高质量 Web/UI 设计、组件视觉优化、landing page、dashboard 和设计系统落地，强调非模板化审美、可访问性和实现可行性。
when_to_use: 当用户要求设计系统、UI 美化、landing page、dashboard、组件视觉、响应式布局、暗色模式或前端审美提升时使用。
---

# Visual Design 协议

> **与本目录 `design-system-protocol` 的关系**：本协议负责**审美方向**（气质、情绪、差异化、非模板化）。token 工程（数学关系、A11y 对比度、组件状态矩阵）由 `design-system-protocol` 负责。两者互补：本协议定调子，design-system-protocol 定数值。

## 工作流

1. 定义产品气质：用户、场景、情绪、差异化、禁区。
2. 建立视觉系统：颜色、字阶、间距、圆角、阴影、动效、图标风格。
3. 设计组件状态：default、hover、focus、active、disabled、loading、empty、error。
4. 布局先移动端和响应式断点，再考虑大屏信息密度。
5. 实现时复用项目技术栈和组件库，不混搭风格体系。
6. 验证：截图、对比度、键盘导航、空/错/加载状态、视觉一致性。

## 约束

- 避免 generic AI aesthetic：不要默认紫色渐变、玻璃拟态、空洞 slogan。
- 不为视觉效果牺牲可访问性和可维护性。
- 不引入未批准的大型 UI 依赖。

## 支持文件

- `references/design-brief.md`：design brief。
- `references/anti-slop-checklist.md`：anti slop checklist。
- `references/anti-slop-deeper.md`：AI Slop 反模式清单 + 替代方案 + 占位符策略 + Design system 优先 + 字号/对比度 floor + 多变体探索 + CSS 现代特性 + Tweaks 设计。综合自 Claude Design 公开行为协议（已 attribution）。

需要细化检查、模板或失败分类时，按需读取这些 supporting files；不要把长参考默认塞入主上下文。
