---
paths:
  - "**/*.css"
  - "**/*.scss"
  - "**/*.sass"
  - "**/*.less"
  - "**/*.module.css"
---

<rule>
  <!-- ====== 方案一致性 ====== -->
  <constraint severity="blocker">优先使用项目已有方案：Tailwind / CSS Modules / styled-components / emotion / vanilla-extract。不要在同一项目内混搭。</constraint>

  <!-- ====== 命名 ====== -->
  <convention>BEM（如项目采用）：</convention>
  <pattern>

```css
.block__element--modifier
```

  </pattern>
  <convention>CSS Modules（推荐）：文件内用 camelCase 或 kebab-case，由构建工具生成唯一 class。</convention>
  <convention>Tailwind：原子类组合，抽取公共 pattern 用 `@apply` 或组件层封装。</convention>

  <!-- ====== 避免 !important ====== -->
  <constraint severity="warning">`!important` 几乎总是代码异味。例外：
  - 覆盖第三方库的内联样式
  - Utility class 强制覆盖
  必要时显式注释原因。</constraint>

  <!-- ====== 选择器 ====== -->
  <constraint severity="warning">避免过度嵌套（大于 3 层）</constraint>
  <constraint severity="warning">避免全局标签选择器（`div { ... }`）</constraint>
  <convention>优先 class，避免 ID（特异性太高）</convention>
  <convention>子元素选择用 `>` 明确层级</convention>

  <!-- ====== 单位 ====== -->
  <convention>字号、间距：`rem` / `em`（响应用户字号设置）</convention>
  <convention>绝对尺寸（边框、分隔线）：`px`</convention>
  <convention>移动端适配：项目统一方案（rem / vw / rpx）</convention>
  <convention>避免硬编码像素值，用变量或 tokens</convention>

  <!-- ====== 响应式 ====== -->
  <convention>移动端优先：默认面向小屏，用 `min-width` 向上扩展</convention>
  <convention>断点定义在变量中，保持一致</convention>
  <convention>避免过多断点（3-4 个足够）</convention>

  <!-- ====== 性能 ====== -->
  <constraint severity="warning">避免过深的选择器（性能和可维护性都差）</constraint>
  <constraint severity="warning">慎用 `*` 通配符和后代选择器</constraint>
  <constraint severity="warning">避免昂贵属性：`box-shadow` 大量使用、`filter` 在动画中</constraint>
  <convention>`will-change` 只在真正需要时（过度使用反而坏）</convention>

  <!-- ====== 颜色与主题 ====== -->
  <constraint severity="blocker">禁止硬编码颜色值（除非是绝对独立的组件）</constraint>
  <convention>使用 CSS 变量 / 主题 tokens</convention>
  <convention>深色模式支持：`prefers-color-scheme` 或主题切换</convention>

  <!-- ====== 可访问性 ====== -->
  <constraint severity="blocker">颜色对比度 >= 4.5:1（大文本 >= 3:1）</constraint>
  <convention>`:focus-visible` 而非只 `:focus`（更好的键盘 UX）</convention>
  <constraint severity="warning">不用 `outline: none` 除非替换为等效的焦点指示</constraint>
  <convention>`prefers-reduced-motion` 尊重用户偏好</convention>

  <!-- ====== 动画 ====== -->
  <convention>动画用 `transform` 和 `opacity`（触发 GPU）</convention>
  <constraint severity="warning">避免动画 `width`、`height`、`top`、`left`（触发 layout）</constraint>
  <convention>长动画必须可取消/跳过</convention>
  <convention>`animation-fill-mode` 明确</convention>

  <!-- ====== SCSS / Sass ====== -->
  <convention>`@use` 优先于 `@import`（未来规范）</convention>
  <convention>变量、mixin、function 分文件组织</convention>
  <convention>避免过深嵌套（2-3 层）</convention>

  <!-- ====== 注释 ====== -->
  <convention>解释为什么（特别是看起来 hack 的规则）</convention>
  <convention>代码本身解释是什么</convention>

</rule>
