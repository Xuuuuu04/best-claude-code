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

<rule name="nuxt-version">
  <convention>Nuxt 3+（Vue 3 + Nitro）</convention>
</rule>

<rule name="nuxt-directory-conventions">
  <convention>pages/：文件系统路由</convention>
  <convention>layouts/：布局</convention>
  <convention>components/：自动导入组件</convention>
  <convention>composables/：自动导入 composable（useXxx）</convention>
  <convention>server/api/：API 端点</convention>
  <convention>server/middleware/：服务端中间件</convention>
  <convention>middleware/：路由中间件</convention>
  <convention>plugins/：插件</convention>
  <convention>public/：静态资源</convention>
</rule>

<rule name="nuxt-rendering-modes">
  <convention>Universal（SSR）默认：首屏 SSR + 客户端 hydration</convention>
  <convention>SSG：nuxt generate 预渲染</convention>
  <convention>SPA：ssr: false</convention>
  <convention>混合：每路由级别的 routeRules</convention>
  <pattern>
    <code language="ts">
// nuxt.config.ts
routeRules: {
  '/api/**': { cors: true },
  '/blog/**': { isr: 60 },
  '/admin/**': { ssr: false },
}
    </code>
  </pattern>
</rule>

<rule name="nuxt-data-fetching">
  <convention>useFetch / useAsyncData：SSR + CSR 一体</convention>
  <convention>$fetch：直接调用（不参与 hydration）</convention>
  <convention>server/api/ 目录内定义 API：自动 API 路由</convention>
  <pattern>
    <code language="ts">
// server/api/users.get.ts
export default defineEventHandler(async (event) => {
  const users = await fetchUsers()
  return users
})
    </code>
  </pattern>
</rule>

<rule name="nuxt-composables">
  <convention>composables/ 下自动导入</convention>
  <pattern>
    <code language="ts">
// composables/useUser.ts
export const useUser = () => {
  const user = useState<User | null>('user', () => null)
  return { user }
}
    </code>
  </pattern>
  <convention>useState：SSR-safe 共享状态</convention>
  <convention>useCookie：Cookie 读写（SSR + CSR）</convention>
  <convention>useRoute / useRouter：路由</convention>
  <convention>useNuxtApp：Nuxt 应用实例</convention>
</rule>

<rule name="nuxt-seo">
  <convention>useSeoMeta / useHead：声明 meta</convention>
  <convention>OpenGraph、Twitter Card</convention>
  <convention>definePageMeta 页面级配置</convention>
</rule>

<rule name="nuxt-error-handling">
  <convention>error.vue 根级错误页</convention>
  <convention>createError({ statusCode, statusMessage }) 抛 HTTP 错误</convention>
  <convention>useError 取当前错误</convention>
</rule>

<rule name="nuxt-runtime-config">
  <pattern>
    <code language="ts">
// nuxt.config.ts
runtimeConfig: {
  apiSecret: '',         // 仅服务端
  public: {
    apiBase: '/api',     // 客户端也可见
  }
}
    </code>
  </pattern>
  <convention>useRuntimeConfig() 读取，服务端私有变量不会泄漏到客户端。</convention>
</rule>

<rule name="nuxt-middleware">
  <convention>路由中间件（middleware/）：前置守卫</convention>
  <convention>服务端中间件（server/middleware/）：请求预处理</convention>
  <convention>auth 中间件典型：未登录重定向</convention>
</rule>

<rule name="nuxt-modules">
  <convention>官方模块：@nuxt/content（MD 渲染）、@nuxt/image、@nuxtjs/tailwindcss、@pinia/nuxt</convention>
  <convention>配置在 modules: [...]</convention>
</rule>

<rule name="nuxt-state-management">
  <convention>简单：useState</convention>
  <convention>复杂：Pinia（@pinia/nuxt）</convention>
  <convention>SSR hydration：Pinia 自动处理</convention>
</rule>

<rule name="nuxt-performance">
  <convention>ClientOnly：仅客户端渲染组件</convention>
  <convention>LazyXxx：自动代码分割</convention>
  <convention>useLazyFetch：非阻塞加载</convention>
  <convention>Payload extraction：ssr: true + experimental.payloadExtraction</convention>
</rule>

<rule name="nuxt-env">
  <convention>.env + runtimeConfig 注入</convention>
  <convention>NUXT_PUBLIC_* 前缀自动绑定到 public</convention>
</rule>

<rule name="nuxt-anti-patterns">
  <constraint severity="blocker">在 setup 外用 composable（必须在 setup 内或顶层 script setup）</constraint>
  <constraint severity="warning">window / document 不做 SSR-safe 检查</constraint>
  <constraint severity="warning">大量逻辑塞页面组件（抽到 composable）</constraint>
  <constraint severity="blocker">客户端直接调 DB（必经 server/api）</constraint>
</rule>
