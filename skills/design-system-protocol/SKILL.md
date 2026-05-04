---
name: design-system-protocol
description: 设计系统协议。为 视觉设计专家 提供 token 体系、组件状态矩阵、布局规则和 A11y 校验框架。
when_to_use: 仅当 视觉设计专家 Agent 在做 design tokens / 组件规范 / 布局规则 / 暗色模式 / A11y 设计基线时加载。视觉测试（高级视觉测试师）和前端实现（高级前端工程师）不应触发。
---

<skill name="design-system-protocol">

<identity>
与本目录 `visual-design-protocol` 的关系：本协议负责**token 工程**（数学关系、A11y 对比度、组件状态矩阵）。审美方向（气质、情绪、差异化）由 `visual-design-protocol` 负责。两者互补：visual-design-protocol 定调子，本协议定数值。前端实现时，高级前端工程师 加载 visual-design-protocol，视觉设计专家 加载本协议。
</identity>

<knowledge domain="token-hierarchy">
<convention name="Primitive">基础原始值</convention>
<convention name="Semantic">语义化 token</convention>
<convention name="Component">组件级 token</convention>
<rule>组件规范引用 token，不直接散落原始值。</rule>
</knowledge>

<knowledge domain="minimum-token-set">
<principle>最小 token 集</principle>
<checklist>
  <item>颜色</item>
  <item>字体</item>
  <item>间距</item>
  <item>圆角</item>
  <item>阴影</item>
  <item>动效</item>
</checklist>
</knowledge>

<knowledge domain="component-spec-requirements">
<principle>组件规范至少包含</principle>
<checklist>
  <item>Anatomy（结构分解）</item>
  <item>States（状态矩阵）</item>
  <item>Variants（变体）</item>
  <item>Size / density（尺寸/密度）</item>
  <item>A11y 注释</item>
</checklist>
</knowledge>

<knowledge domain="a11y-baseline">
<principle>A11y 基线</principle>
<checklist>
  <item>对比度</item>
  <item>focus ring</item>
  <item>键盘可达性</item>
  <item>减少动效方案</item>
</checklist>
</knowledge>

<convention name="output-principles">
<principle>输出原则</principle>
<checklist>
  <item>先 token，再组件</item>
  <item>先规范，再实现</item>
  <item>先约束，再视觉形容词</item>
</checklist>
</convention>

</skill>
