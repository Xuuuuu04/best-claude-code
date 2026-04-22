---
paths:
  - "**/tailwind.config.js"
  - "**/tailwind.config.ts"
  - "**/tailwind.config.mjs"
  - "**/postcss.config.js"
---

# Tailwind CSS 规范

## 版本
- Tailwind CSS 3+ 或 4+（v4 新引擎）

## 使用哲学

- 原子类组合而非自定义类
- 优先配置 / Design Token 而非魔法数字
- 在必要时抽取组件（不强制每次抽）

## 配置

```ts
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
```

- `content` 精确（影响 purge 和构建性能）
- `extend` 扩展而非覆盖默认 theme
- 颜色 token 命名有语义（`brand`、`accent`）

## 类的顺序

建议按：布局 → 间距 → 尺寸 → 排版 → 背景 → 边框 → 效果 → 交互

```html
<div class="flex items-center gap-4 p-6 w-full text-sm font-medium text-gray-900 bg-white border border-gray-200 rounded-lg shadow-sm hover:bg-gray-50">
```

`prettier-plugin-tailwindcss` 自动排序。

## 响应式

- 移动端优先：默认样式针对最小屏
- 向上扩展：`sm:` / `md:` / `lg:` / `xl:` / `2xl:`
- 断点与 `theme.screens` 对齐项目设计

## 状态与变体

- 交互：`hover:` / `focus:` / `active:` / `disabled:`
- 表单：`checked:` / `required:` / `invalid:`
- 暗色模式：`dark:` 前缀
- 组合：`sm:hover:bg-blue-500`

## 暗色模式

- 配置 `darkMode: 'class'` 或 `'media'`
- `class`：`<html class="dark">` 手动切换
- `media`：跟随系统 `prefers-color-scheme`

## 自定义类抽取

**重复 ≥3 次** 才考虑抽取：

```css
@layer components {
  .btn-primary {
    @apply px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700;
  }
}
```

或在框架中用组件封装（React Component / Vue Component）。

## @apply 慎用

- `@apply` 在某些场景有用，但**滥用**会失去 Tailwind 的优势
- 优先组件封装而非 `@apply`

## 性能

- `content` 扫描准确（遗漏导致 class 被 purge，多余导致构建慢）
- 避免动态类名字符串拼接（Tailwind 无法检测）：
  ```tsx
  // 错误：Tailwind 看不到
  const c = `text-${color}-500`
  
  // 正确：完整 class 字符串在源码中可见
  const c = color === 'red' ? 'text-red-500' : 'text-blue-500'
  ```

## Arbitrary Values（任意值）

`w-[237px]` / `bg-[#1a2b3c]` / `grid-cols-[200px_1fr]` 临时值。

**不滥用**：如果某值反复使用，抽到 theme 配置。

## 可访问性

- 不要只依赖颜色区分状态（盲色用户）
- `focus-visible:` 提供焦点指示
- `sr-only` 给屏幕阅读器提示
- `aria-*` 属性配合 Tailwind 样式状态

## 常见组合

- Flex 居中：`flex items-center justify-center`
- Grid 自适应：`grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4`
- Card 基础：`p-6 bg-white dark:bg-gray-800 rounded-lg shadow`
- 按钮基础：`px-4 py-2 rounded-md font-medium transition-colors`

## 反模式

- 内联大量 arbitrary values（应抽 token）
- 动态拼 class 字符串（被 purge）
- `!important` 覆盖（用 variant 前缀或调整顺序）
- 和传统 CSS 混用全局样式（除非明确边界）
