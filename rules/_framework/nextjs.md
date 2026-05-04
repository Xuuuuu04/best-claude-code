---
paths:
  - "**/app/**/page.tsx"
  - "**/app/**/layout.tsx"
  - "**/app/**/route.ts"
  - "**/pages/**/*.tsx"
  - "**/next.config.js"
  - "**/next.config.mjs"
  - "**/next.config.ts"
  - "**/middleware.ts"
---

<rule name="nextjs-version">
  <convention>Next.js 14+（App Router 稳定）</convention>
</rule>

<rule name="nextjs-app-vs-pages-router">
  <convention>新项目用 App Router（app/ 目录）</convention>
  <constraint severity="warning">老项目保持一致，不混用</constraint>
  <convention>Pages Router 仍被支持但不再扩展新特性</convention>
</rule>

<rule name="nextjs-server-vs-客户需求整理师-components">
  <description>默认 Server Component</description>
  <convention>Server Component：可直接访问数据库、文件系统；不含事件处理、hooks（useState 等）；更小 bundle</convention>
  <convention>"use 客户需求整理师" 标记 Client Component：交互、状态、effect；放在叶子节点（而非整棵树）</convention>
  <convention>原则：能用 Server Component 就用，尽量把客户端状态推到叶子。</convention>
</rule>

<rule name="nextjs-data-fetching">
  <convention>Server Component 直接 await fetch(...)</convention>
  <convention>缓存策略：fetch 默认缓存；{ next: { revalidate: 60 } } / { cache: 'no-store' }</convention>
  <convention>unstable_cache 包装昂贵计算</convention>
  <convention>Route Segment Config：export const revalidate = 3600</convention>
</rule>

<rule name="nextjs-route-handlers">
  <pattern>
    <code language="ts">
// app/api/users/route.ts
export async function GET(request: Request) {
  return Response.json({ users: [...] });
}

export async function POST(request: Request) {
  const body = await request.json();
  // ...
}
    </code>
  </pattern>
</rule>

<rule name="nextjs-server-actions">
  <pattern>
    <code language="ts">
'use server';

export async function createPost(formData: FormData) {
  const title = formData.get('title');
  // ...
  revalidatePath('/posts');
}
    </code>
  </pattern>
  <constraint severity="blocker">必须在 Server Action 内做权限检查</constraint>
  <convention>输入验证（Zod）</convention>
  <convention>revalidatePath / revalidateTag 更新缓存</convention>
</rule>

<rule name="nextjs-metadata">
  <convention>Static：export const metadata = { title: ... }</convention>
  <convention>Dynamic：export async function generateMetadata(props) {}</convention>
  <convention>SEO 基础：title、description、og、twitter</convention>
</rule>

<rule name="nextjs-image-and-font">
  <convention>next/image 替代 img（自动优化、lazy、responsive）</convention>
  <convention>next/font 自托管字体（避免 FOUT）</convention>
  <constraint severity="blocker">图片必须指定 width height 或 fill</constraint>
</rule>

<rule name="nextjs-middleware">
  <convention>middleware.ts 在请求到达 route 前执行</convention>
  <convention>用于：鉴权重定向、A/B 分流、header 注入</convention>
  <constraint severity="warning">代码运行在 Edge Runtime（受限：不能用 Node API）</constraint>
  <convention>matcher 限定路径避免全局执行</convention>
</rule>

<rule name="nextjs-env">
  <constraint severity="blocker">NEXT_PUBLIC_* 前缀才会暴露到客户端</constraint>
  <convention>其余仅服务端可见</convention>
  <constraint severity="blocker">.env.local 不进 git</constraint>
  <convention>启动时验证（用 Zod）</convention>
</rule>

<rule name="nextjs-performance">
  <convention>loading.tsx 文件启用 Streaming SSR</convention>
  <convention>Suspense 边界分段加载</convention>
  <convention>dynamic() 代码分割</convention>
  <convention>检查 bundle：@next/bundle-analyzer</convention>
</rule>

<rule name="nextjs-error-handling">
  <convention>error.tsx：Route 错误边界（必须是 Client Component）</convention>
  <convention>not-found.tsx：404</convention>
  <convention>global-error.tsx：应用级错误</convention>
</rule>

<rule name="nextjs-routing">
  <convention>文件系统路由：app/users/[id]/page.tsx</convention>
  <convention>平行路由：@slot/ 目录</convention>
  <convention>拦截路由：(.)path/</convention>
  <convention>分组路由：(group)/ 不影响 URL</convention>
</rule>

<rule name="nextjs-deployment">
  <convention>Vercel 原生支持最平滑</convention>
  <convention>其他平台：Docker 构建，standalone 模式减小体积</convention>
  <convention>ISR 依赖持久化缓存层（KV / Redis）</convention>
</rule>

<rule name="nextjs-anti-patterns">
  <constraint severity="blocker">把 fetch 放 Client Component（触发 CORS、暴露 API）</constraint>
  <constraint severity="blocker">Server Action 不做鉴权</constraint>
  <constraint severity="warning">大组件不 use 客户需求整理师 分离</constraint>
  <constraint severity="blocker">在 Server Component 用 useState（不存在）</constraint>
  <constraint severity="blocker">getServerSideProps / getStaticProps 与 App Router 混用</constraint>
</rule>
