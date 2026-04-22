---
paths:
  - "**/*.svelte"
  - "**/svelte.config.js"
  - "**/svelte.config.ts"
---

# Svelte / SvelteKit 规范

## 版本
- Svelte 5+（Runes 语法）
- SvelteKit 2+

## Runes（Svelte 5）

新项目用 Runes：

```svelte
<script>
  let count = $state(0);
  let doubled = $derived(count * 2);
  
  $effect(() => {
    console.log('count changed:', count);
  });
</script>

<button onclick={() => count++}>{count}</button>
```

- `$state()`：响应式状态
- `$derived()`：派生值（替代 `$:`）
- `$effect()`：副作用（替代 `onMount` 多数场景）
- `$props()`：组件 props
- `$bindable()`：双向绑定

## Svelte 4 兼容（老项目）

- `let x = 0` 自动响应
- `$: doubled = x * 2` 派生
- `export let prop` 声明 props

## 组件

- 单文件：script + markup + style
- CamelCase 组件名导入：`import Header from './Header.svelte'`
- Props 显式类型（TS）：`let { title }: { title: string } = $props();`

## 事件

- Svelte 5：原生 HTML 事件（`onclick` 而非 `on:click`）
- 自定义事件：通过 callback props（不再 `createEventDispatcher`）

## Stores（Svelte 4 和部分场景）

- `writable` / `readable` / `derived`
- `$store` 前缀自动订阅
- Svelte 5 倾向 Runes 代替 stores（局部状态）

## SvelteKit

### 路由
- `src/routes/` 文件系统路由
- `+page.svelte`：页面组件
- `+page.ts` / `+page.server.ts`：加载数据
- `+layout.svelte` / `+layout.ts`：布局
- `+server.ts`：API endpoint
- `+error.svelte`：错误页

### 加载

```ts
// +page.server.ts
export async function load({ params }) {
  return {
    user: await db.user.findUnique({ where: { id: params.id } })
  };
}
```

- `.server.ts` 仅服务端运行（访问 DB、密钥）
- 没 `.server.` 的 `+page.ts` 两端运行

### Actions / Forms

```ts
// +page.server.ts
export const actions = {
  create: async ({ request }) => {
    const data = await request.formData();
    // ...
    return { success: true };
  }
};
```

Progressive Enhancement：表单 `method="POST"` 无 JS 也能工作。

### Hooks

- `hooks.server.ts`：服务端全局钩子（认证、日志）
- `hooks.client.ts`：客户端全局钩子
- `handle` / `handleError`

## 样式

- `<style>` 默认 scoped
- `:global()` 显式全局
- Preprocessor：SCSS / PostCSS / Tailwind 配置

## 性能

- 编译时生成，运行时极小
- `<svelte:window>` / `<svelte:head>` 特殊元素
- `bind:this` 引用 DOM / 组件

## SSR 注意

- 浏览器专用 API（`window` / `document`）用 `onMount` 或 `browser` guard
- `$app/environment` 的 `browser` 变量

## 环境变量

- `$env/static/public`：构建时静态、前缀 `PUBLIC_`
- `$env/static/private`：构建时静态、服务端
- `$env/dynamic/public` / `$env/dynamic/private`：运行时

## 测试

- Vitest + `@testing-library/svelte`
- Playwright E2E（SvelteKit 推荐）

## 反模式

- `on:click` 在 Svelte 5（用 `onclick`）
- 客户端引用 `.server.ts` 文件中的内容
- 在组件中重度使用 store（用 Runes 更好）
- 未使用 `browser` guard 访问浏览器 API
