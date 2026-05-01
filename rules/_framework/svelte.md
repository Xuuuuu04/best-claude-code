---
paths:
  - "**/*.svelte"
  - "**/svelte.config.js"
  - "**/svelte.config.ts"
---

<rule name="svelte-version">
  <convention>Svelte 5+（Runes 语法）</convention>
  <convention>SvelteKit 2+</convention>
</rule>

<rule name="svelte-runes-svelte5">
  <description>新项目用 Runes</description>
  <pattern>
    <code language="svelte">
<script>
  let count = $state(0);
  let doubled = $derived(count * 2);

  $effect(() => {
    console.log('count changed:', count);
  });
</script>

<button onclick={() => count++}>{count}</button>
    </code>
  </pattern>
  <convention>$state()：响应式状态</convention>
  <convention>$derived()：派生值（替代 $:）</convention>
  <convention>$effect()：副作用（替代 onMount 多数场景）</convention>
  <convention>$props()：组件 props</convention>
  <convention>$bindable()：双向绑定</convention>
</rule>

<rule name="svelte4-compat">
  <description>Svelte 4 兼容（老项目）</description>
  <convention>let x = 0 自动响应</convention>
  <convention>$: doubled = x * 2 派生</convention>
  <convention>export let prop 声明 props</convention>
</rule>

<rule name="svelte-components">
  <convention>单文件：script + markup + style</convention>
  <convention>CamelCase 组件名导入：import Header from './Header.svelte'</convention>
  <convention>Props 显式类型（TS）：let { title }: { title: string } = $props();</convention>
</rule>

<rule name="svelte-events">
  <convention>Svelte 5：原生 HTML 事件（onclick 而非 on:click）</convention>
  <convention>自定义事件：通过 callback props（不再 createEventDispatcher）</convention>
</rule>

<rule name="svelte-stores">
  <description>Svelte 4 和部分场景</description>
  <convention>writable / readable / derived</convention>
  <convention>$store 前缀自动订阅</convention>
  <convention>Svelte 5 倾向 Runes 代替 stores（局部状态）</convention>
</rule>

<rule name="sveltekit-routing">
  <convention>src/routes/ 文件系统路由</convention>
  <convention>+page.svelte：页面组件</convention>
  <convention>+page.ts / +page.server.ts：加载数据</convention>
  <convention>+layout.svelte / +layout.ts：布局</convention>
  <convention>+server.ts：API endpoint</convention>
  <convention>+error.svelte：错误页</convention>
</rule>

<rule name="sveltekit-loading">
  <pattern>
    <code language="ts">
// +page.server.ts
export async function load({ params }) {
  return {
    user: await db.user.findUnique({ where: { id: params.id } })
  };
}
    </code>
  </pattern>
  <convention>.server.ts 仅服务端运行（访问 DB、密钥）</convention>
  <convention>没 .server. 的 +page.ts 两端运行</convention>
</rule>

<rule name="sveltekit-actions-forms">
  <pattern>
    <code language="ts">
// +page.server.ts
export const actions = {
  create: async ({ request }) => {
    const data = await request.formData();
    // ...
    return { success: true };
  }
};
    </code>
  </pattern>
  <convention>Progressive Enhancement：表单 method="POST" 无 JS 也能工作。</convention>
</rule>

<rule name="sveltekit-hooks">
  <convention>hooks.server.ts：服务端全局钩子（认证、日志）</convention>
  <convention>hooks.client.ts：客户端全局钩子</convention>
  <convention>handle / handleError</convention>
</rule>

<rule name="svelte-styles">
  <convention>style 默认 scoped</convention>
  <convention>:global() 显式全局</convention>
  <convention>Preprocessor：SCSS / PostCSS / Tailwind 配置</convention>
</rule>

<rule name="svelte-performance">
  <convention>编译时生成，运行时极小</convention>
  <convention>svelte:window / svelte:head 特殊元素</convention>
  <convention>bind:this 引用 DOM / 组件</convention>
</rule>

<rule name="sveltekit-ssr">
  <convention>浏览器专用 API（window / document）用 onMount 或 browser guard</convention>
  <convention>$app/environment 的 browser 变量</convention>
</rule>

<rule name="sveltekit-env">
  <convention>$env/static/public：构建时静态、前缀 PUBLIC_</convention>
  <convention>$env/static/private：构建时静态、服务端</convention>
  <convention>$env/dynamic/public / $env/dynamic/private：运行时</convention>
</rule>

<rule name="svelte-testing">
  <convention>Vitest + @testing-library/svelte</convention>
  <convention>Playwright E2E（SvelteKit 推荐）</convention>
</rule>

<rule name="svelte-anti-patterns">
  <constraint severity="blocker">on:click 在 Svelte 5（用 onclick）</constraint>
  <constraint severity="blocker">客户端引用 .server.ts 文件中的内容</constraint>
  <constraint severity="warning">在组件中重度使用 store（用 Runes 更好）</constraint>
  <constraint severity="warning">未使用 browser guard 访问浏览器 API</constraint>
</rule>
