---
paths:
  - "**/*.css"
  - "**/*.scss"
  - "**/*.sass"
  - "**/*.less"
  - "**/*.module.css"
---

# CSS 编码规范

## 方案一致性

**优先使用项目已有方案**：Tailwind / CSS Modules / styled-components / emotion / vanilla-extract。不要在同一项目内混搭。

## 命名

### BEM（如项目采用）
```
.block__element--modifier
```

### CSS Modules（推荐）
文件内用 camelCase 或 kebab-case，由构建工具生成唯一 class。

### Tailwind
原子类组合，抽取公共 pattern 用 `@apply` 或组件层封装。

## 避免 !important

`!important` 几乎总是代码异味。例外：
- 覆盖第三方库的内联样式
- Utility class 强制覆盖
必要时显式注释原因。

## 选择器

- 避免过度嵌套（>3 层）
- 避免全局标签选择器（`div { ... }`）
- 优先 class，避免 ID（特异性太高）
- 子元素选择用 `>` 明确层级

## 单位

- 字号、间距：`rem` / `em`（响应用户字号设置）
- 绝对尺寸（边框、分隔线）：`px`
- 移动端适配：项目统一方案（rem / vw / rpx）
- 避免硬编码像素值，用变量或 tokens

## 响应式

- **移动端优先**：默认面向小屏，用 `min-width` 向上扩展
- 断点定义在变量中，保持一致
- 避免过多断点（3-4 个足够）

## 性能

- 避免过深的选择器（性能和可维护性都差）
- 慎用 `*` 通配符和后代选择器
- 避免昂贵属性：`box-shadow` 大量使用、`filter` 在动画中
- `will-change` 只在真正需要时（过度使用反而坏）

## 颜色与主题

- **禁止硬编码颜色值**（除非是绝对独立的组件）
- 使用 CSS 变量 / 主题 tokens
- 深色模式支持：`prefers-color-scheme` 或主题切换

## 可访问性

- 颜色对比度 ≥ 4.5:1（大文本 ≥ 3:1）
- `:focus-visible` 而非只 `:focus`（更好的键盘 UX）
- 不用 `outline: none` 除非替换为等效的焦点指示
- `prefers-reduced-motion` 尊重用户偏好

## 动画

- 动画用 `transform` 和 `opacity`（触发 GPU）
- 避免动画 `width`、`height`、`top`、`left`（触发 layout）
- 长动画必须可取消/跳过
- `animation-fill-mode` 明确

## SCSS / Sass

- `@use` 优先于 `@import`（未来规范）
- 变量、mixin、function 分文件组织
- 避免过深嵌套（2-3 层）

## 注释

- 解释**为什么**（特别是看起来 hack 的规则）
- 代码本身解释**是什么**
