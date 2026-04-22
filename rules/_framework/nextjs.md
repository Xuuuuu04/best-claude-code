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

# Next.js 规范

## 版本
- Next.js 14+（App Router 稳定）

## App Router vs Pages Router

- **新项目用 App Router**（`app/` 目录）
- 老项目保持一致，不混用
- Pages Router 仍被支持但不再扩展新特性

## Server Components vs Client Components

默认 Server Component：
- 可直接访问数据库、文件系统
- 不含事件处理、hooks（`useState` 等）
- 更小 bundle

`"use client"` 标记 Client Component：
- 交互、状态、effect
- 放在叶子节点（而非整棵树）

**原则**：能用 Server Component 就用，尽量把客户端状态推到叶子。

## Data Fetching

- Server Component 直接 `await fetch(...)`
- 缓存策略：`fetch` 默认缓存；`{ next: { revalidate: 60 } }` / `{ cache: 'no-store' }`
- `unstable_cache` 包装昂贵计算
- Route Segment Config：`export const revalidate = 3600`

## Route Handlers

`app/api/users/route.ts`:

```ts
export async function GET(request: Request) {
  return Response.json({ users: [...] });
}

export async function POST(request: Request) {
  const body = await request.json();
  // ...
}
```

## Server Actions

```ts
'use server';

export async function createPost(formData: FormData) {
  const title = formData.get('title');
  // ...
  revalidatePath('/posts');
}
```

- **必须** 在 Server Action 内做权限检查
- 输入验证（Zod）
- `revalidatePath` / `revalidateTag` 更新缓存

## Metadata

- Static：`export const metadata = { title: ... }`
- Dynamic：`export async function generateMetadata(props) {}`
- SEO 基础：title、description、og、twitter

## Image & Font

- `next/image` 替代 `<img>`（自动优化、lazy、responsive）
- `next/font` 自托管字体（避免 FOUT）
- 图片必须指定 `width` `height` 或 `fill`

## Middleware

- `middleware.ts` 在请求到达 route 前执行
- 用于：鉴权重定向、A/B 分流、header 注入
- 代码运行在 Edge Runtime（受限：不能用 Node API）
- `matcher` 限定路径避免全局执行

## 环境变量

- `NEXT_PUBLIC_*` 前缀才会暴露到客户端
- 其余仅服务端可见
- `.env.local` 不进 git
- 启动时验证（用 Zod）

## 性能

- `loading.tsx` 文件启用 Streaming SSR
- `Suspense` 边界分段加载
- `dynamic()` 代码分割
- 检查 bundle：`@next/bundle-analyzer`

## 错误处理

- `error.tsx`：Route 错误边界（必须是 Client Component）
- `not-found.tsx`：404
- `global-error.tsx`：应用级错误

## 路由

- 文件系统路由：`app/users/[id]/page.tsx`
- 平行路由：`@slot/` 目录
- 拦截路由：`(.)path/`
- 分组路由：`(group)/` 不影响 URL

## 部署

- Vercel 原生支持最平滑
- 其他平台：Docker 构建，`standalone` 模式减小体积
- ISR 依赖持久化缓存层（KV / Redis）

## 反模式

- 把 fetch 放 Client Component（触发 CORS、暴露 API）
- Server Action 不做鉴权
- 大组件不 `use client` 分离
- 在 Server Component 用 `useState`（不存在）
- `getServerSideProps` / `getStaticProps` 与 App Router 混用
