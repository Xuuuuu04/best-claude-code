---
paths:
  - "**/nuxt.config.ts"
  - "**/nuxt.config.js"
  - "**/app.vue"
  - "**/pages/**/*.vue"
  - "**/layouts/**/*.vue"
  - "**/server/api/**/*.ts"
  - "**/server/routes/**/*.ts"
---

# Nuxt 规范

## 版本
- Nuxt 3+（Vue 3 + Nitro）

## 目录约定

- `pages/`：文件系统路由
- `layouts/`：布局
- `components/`：自动导入组件
- `composables/`：自动导入 composable（`useXxx`）
- `server/api/`：API 端点
- `server/middleware/`：服务端中间件
- `middleware/`：路由中间件
- `plugins/`：插件
- `public/`：静态资源

## 渲染模式

- **Universal（SSR）** 默认：首屏 SSR + 客户端 hydration
- **SSG**：`nuxt generate` 预渲染
- **SPA**：`ssr: false`
- **混合**：每路由级别的 `routeRules`

```ts
// nuxt.config.ts
routeRules: {
  '/api/**': { cors: true },
  '/blog/**': { isr: 60 },
  '/admin/**': { ssr: false },
}
```

## 数据获取

- `useFetch` / `useAsyncData`：SSR + CSR 一体
- `$fetch`：直接调用（不参与 hydration）
- `server/api/` 目录内定义 API：自动 API 路由

```ts
// server/api/users.get.ts
export default defineEventHandler(async (event) => {
  const users = await fetchUsers()
  return users
})
```

## Composables

`composables/` 下自动导入：

```ts
// composables/useUser.ts
export const useUser = () => {
  const user = useState<User | null>('user', () => null)
  return { user }
}
```

- `useState`：SSR-safe 共享状态
- `useCookie`：Cookie 读写（SSR + CSR）
- `useRoute` / `useRouter`：路由
- `useNuxtApp`：Nuxt 应用实例

## SEO

- `useSeoMeta` / `useHead`：声明 meta
- OpenGraph、Twitter Card
- `definePageMeta` 页面级配置

## 错误处理

- `error.vue` 根级错误页
- `createError({ statusCode, statusMessage })` 抛 HTTP 错误
- `useError` 取当前错误

## 运行时配置

```ts
// nuxt.config.ts
runtimeConfig: {
  apiSecret: '',         // 仅服务端
  public: {
    apiBase: '/api',     // 客户端也可见
  }
}
```

`useRuntimeConfig()` 读取，服务端私有变量不会泄漏到客户端。

## 中间件

- 路由中间件（`middleware/`）：前置守卫
- 服务端中间件（`server/middleware/`）：请求预处理
- `auth` 中间件典型：未登录重定向

## 模块

- 官方模块：`@nuxt/content`（MD 渲染）、`@nuxt/image`、`@nuxtjs/tailwindcss`、`@pinia/nuxt`
- 配置在 `modules: [...]`

## 状态管理

- 简单：`useState`
- 复杂：Pinia（`@pinia/nuxt`）
- SSR hydration：Pinia 自动处理

## 性能

- `<ClientOnly>`：仅客户端渲染组件
- `<LazyXxx>`：自动代码分割
- `useLazyFetch`：非阻塞加载
- Payload extraction：`ssr: true` + `experimental.payloadExtraction`

## 环境变量

- `.env` + runtimeConfig 注入
- `NUXT_PUBLIC_*` 前缀自动绑定到 `public`

## 反模式

- 在 `setup` 外用 composable（必须在 setup 内或顶层 script setup）
- `window` / `document` 不做 SSR-safe 检查
- 大量逻辑塞页面组件（抽到 composable）
- 客户端直接调 DB（必经 server/api）
