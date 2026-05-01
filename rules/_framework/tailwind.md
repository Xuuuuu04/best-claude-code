---
paths:
  - "**/tailwind.config.js"
  - "**/tailwind.config.ts"
  - "**/tailwind.config.mjs"
  - "**/postcss.config.js"
---

<rule name="tailwind-version-and-philosophy">
  <convention>Tailwind CSS 3+ 或 4+（v4 新引擎）</convention>
  <convention>原子类组合而非自定义类</convention>
  <convention>优先配置 / Design Token 而非魔法数字</convention>
  <convention>在必要时抽取组件（不强制每次抽）</convention>
</rule>

<rule name="tailwind-configuration">
  <pattern>
    <code language="ts">
// tailwind.config.ts
import type { Config } from 'tailwindcss';

export default {
  content: ['./src/**/*.{ts,tsx,html}'],
  theme: {
    extend: {
      colors: {
        brand: { 50: '#...', 500: '#...', 900: '#...' },
      },
      spacing: {
        '18': '4.5rem',
      },
    },
  },
  plugins: [require('@tailwindcss/forms'), require('@tailwindcss/typography')],
} satisfies Config;
    </code>
  </pattern>
  <convention>content 精确（影响 purge 和构建性能）</convention>
  <convention>extend 扩展而非覆盖默认 theme</convention>
  <convention>颜色 token 命名有语义（brand、accent）</convention>
</rule>

<rule name="tailwind-class-ordering">
  <pattern>建议按：布局 -> 间距 -> 尺寸 -> 排版 -> 背景 -> 边框 -> 效果 -> 交互</pattern>
  <example type="good">
    <code language="html">
<div class="flex items-center gap-4 p-6 w-full text-sm font-medium text-gray-900 bg-white border border-gray-200 rounded-lg shadow-sm hover:bg-gray-50">
    </code>
  </example>
  <convention>prettier-plugin-tailwindcss 自动排序。</convention>
</rule>

<rule name="tailwind-responsive">
  <convention>移动端优先：默认样式针对最小屏</convention>
  <convention>向上扩展：sm: / md: / lg: / xl: / 2xl:</convention>
  <convention>断点与 theme.screens 对齐项目设计</convention>
</rule>

<rule name="tailwind-states-and-variants">
  <convention>交互：hover: / focus: / active: / disabled:</convention>
  <convention>表单：checked: / required: / invalid:</convention>
  <convention>暗色模式：dark: 前缀</convention>
  <convention>组合：sm:hover:bg-blue-500</convention>
</rule>

<rule name="tailwind-dark-mode">
  <convention>配置 darkMode: 'class' 或 'media'</convention>
  <convention>class：html class="dark" 手动切换</convention>
  <convention>media：跟随系统 prefers-color-scheme</convention>
</rule>

<rule name="tailwind-custom-class-extraction">
  <convention>重复大于等于 3 次才考虑抽取</convention>
  <pattern>
    <code language="css">
@layer components {
  .btn-primary {
    @apply px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700;
  }
}
    </code>
  </pattern>
  <convention>或在框架中用组件封装（React Component / Vue Component）。</convention>
</rule>

<rule name="tailwind-apply-warning">
  <constraint severity="warning">@apply 在某些场景有用，但滥用会失去 Tailwind 的优势。优先组件封装而非 @apply。</constraint>
</rule>

<rule name="tailwind-performance-purge">
  <constraint severity="blocker">content 扫描准确（遗漏导致 class 被 purge，多余导致构建慢）</constraint>
  <constraint severity="blocker">避免动态类名字符串拼接（Tailwind 无法检测）</constraint>
  <example type="bad">
    <title>Tailwind 看不到</title>
    <code language="tsx">
const c = `text-${color}-500`
    </code>
  </example>
  <example type="good">
    <title>完整 class 字符串在源码中可见</title>
    <code language="tsx">
const c = color === 'red' ? 'text-red-500' : 'text-blue-500'
    </code>
  </example>
</rule>

<rule name="tailwind-arbitrary-values">
  <convention>w-[237px] / bg-[#1a2b3c] / grid-cols-[200px_1fr] 临时值。</convention>
  <constraint severity="warning">不滥用：如果某值反复使用，抽到 theme 配置。</constraint>
</rule>

<rule name="tailwind-accessibility">
  <convention>不要只依赖颜色区分状态（盲色用户）</convention>
  <convention>focus-visible: 提供焦点指示</convention>
  <convention>sr-only 给屏幕阅读器提示</convention>
  <convention>aria-* 属性配合 Tailwind 样式状态</convention>
</rule>

<rule name="tailwind-common-compositions">
  <convention>Flex 居中：flex items-center justify-center</convention>
  <convention>Grid 自适应：grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4</convention>
  <convention>Card 基础：p-6 bg-white dark:bg-gray-800 rounded-lg shadow</convention>
  <convention>按钮基础：px-4 py-2 rounded-md font-medium transition-colors</convention>
</rule>

<rule name="tailwind-anti-patterns">
  <constraint severity="warning">内联大量 arbitrary values（应抽 token）</constraint>
  <constraint severity="blocker">动态拼 class 字符串（被 purge）</constraint>
  <constraint severity="warning">!important 覆盖（用 variant 前缀或调整顺序）</constraint>
  <constraint severity="warning">和传统 CSS 混用全局样式（除非明确边界）</constraint>
</rule>
