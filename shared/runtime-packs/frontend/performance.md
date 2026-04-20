> 源：core.md §Domain 3.2 Performance Discipline（扩展 2026-04-21）

# 前端开发师 — Performance Optimization

## Core Web Vitals 目标

| 指标 | 目标值 | 测量工具 |
|---|---|---|
| LCP (Largest Contentful Paint) | ≤ 2.5s | Chrome DevTools / Lighthouse |
| INP (Interaction to Next Paint) | ≤ 200ms | Chrome DevTools / web-vitals.js |
| CLS (Cumulative Layout Shift) | ≤ 0.1 | Lighthouse / CrUX |
| TTFB (Time to First Byte) | ≤ 600ms | Network panel |
| FCP (First Contentful Paint) | ≤ 1.8s | Lighthouse |

---

## React 19 Performance Patterns

**React Compiler (自动 memoization)**

React 19 引入 React Compiler，自动处理 memoization，减少手动 `useMemo`/`useCallback`/`React.memo` 需求。

```tsx
// React 19 之前 — 手动 memoization
const UserList = React.memo(({ users }: { users: User[] }) => {
  const sortedUsers = useMemo(() => 
    users.sort((a, b) => a.name.localeCompare(b.name)),
    [users]
  );
  return <ul>{sortedUsers.map(u => <UserCard key={u.id} user={u} />)}</ul>;
});

// React 19 + Compiler — 自动 memoization，无需手动包裹
// 编译器自动分析依赖，插入等效 memoization
function UserList({ users }: { users: User[] }) {
  const sortedUsers = users.sort((a, b) => a.name.localeCompare(b.name));
  return <ul>{sortedUsers.map(u => <UserCard key={u.id} user={u} />)}</ul>;
}
```

**注意**：React Compiler 是编译时优化，不改变运行时语义。在 Compiler 启用前，仍遵循 "profiler 先行" 原则。

**useTransition — 非紧急更新**

```tsx
import { useTransition } from 'react';

function SearchResults() {
  const [isPending, startTransition] = useTransition();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);

  const handleSearch = (value: string) => {
    setQuery(value); // 紧急更新：输入框立即响应
    startTransition(() => {
      // 非紧急更新：搜索结果可以延迟
      setResults(filterResults(value));
    });
  };

  return (
    <>
      <input value={query} onChange={e => handleSearch(e.target.value)} />
      {isPending && <Spinner />}
      <ResultsList items={results} />
    </>
  );
}
```

**useDeferredValue — 延迟非关键渲染**

```tsx
import { useDeferredValue } from 'react';

function Dashboard({ data }: { data: DashboardData }) {
  const deferredData = useDeferredValue(data);
  const isStale = data !== deferredData;

  return (
    <div style={{ opacity: isStale ? 0.8 : 1 }}>
      <HeavyChart data={deferredData} />
    </div>
  );
}
```

---

## Next.js 15 App Router 性能

**Server Components 默认**

```tsx
// app/page.tsx — 默认 Server Component，零 JS bundle
import { Suspense } from 'react';

// 此组件在服务端渲染，不发送 JS 到客户端
export default async function Page() {
  const data = await fetch('https://api.example.com/data', {
    next: { revalidate: 60 }, // ISR: 60秒增量再生成
  });

  return (
    <main>
      <h1>Dashboard</h1>
      <Suspense fallback={<Skeleton />}>
        <DataTable data={data} />
      </Suspense>
    </main>
  );
}
```

**Streaming SSR**

```tsx
// Suspense boundaries enable streaming
import { Suspense } from 'react';

export default function Page() {
  return (
    <>
      <Header /> {/* 立即渲染 */}
      <Suspense fallback={<ProductSkeleton />}>
        <ProductList /> {/* 数据就绪后流式传输 */}
      </Suspense>
      <Suspense fallback={<ReviewSkeleton />}>
        <Reviews /> {/* 独立流式传输 */}
      </Suspense>
    </>
  );
}
```

**Image 优化**

```tsx
import Image from 'next/image';

// 自动：WebP/AVIF 格式、响应式尺寸、懒加载、blur placeholder
<Image
  src="/hero.jpg"
  alt="Hero"
  width={1200}
  height={600}
  priority // LCP 图片标记 priority，禁用懒加载
  placeholder="blur"
  blurDataURL="data:image/jpeg;base64,..."
/>
```

---

## Tailwind CSS v4 性能

**CSS-first 配置**

Tailwind v4 使用 CSS-native 配置，无需 `tailwind.config.js`：

```css
/* app.css — Tailwind v4 */
@import "tailwindcss";

@theme {
  --color-primary-500: #3b82f6;
  --spacing-card: 1.5rem;
  --radius-lg: 0.75rem;
}
```

**@layer 工具类优化**

```css
@layer components {
  .btn-primary {
    @apply px-4 py-2 bg-primary-500 text-white rounded-lg;
    /* 编译时生成单一类，避免运行时组合 */
  }
}
```

**容器查询**

```css
/* Tailwind v4 原生支持容器查询 */
@container (min-width: 400px) {
  .card-grid {
    @apply grid-cols-2;
  }
}
```

---

## Vite 6 构建优化

**依赖预构建优化**

```typescript
// vite.config.ts
export default defineConfig({
  optimizeDeps: {
    include: ['react', 'react-dom', 'lodash-es'],
    exclude: ['@internal/package'], // 不预构建的包
  },
  build: {
    target: 'es2022',
    rollupOptions: {
      output: {
        manualChunks: {
          // 代码分割策略
          vendor: ['react', 'react-dom'],
          ui: ['@radix-ui/react-dialog', '@radix-ui/react-select'],
        },
      },
    },
  },
});
```

**Module Federation (Vite 6 + @originjs/plugin-federation)**

```typescript
// vite.config.ts — 微前端架构
import federation from '@originjs/vite-plugin-federation';

export default defineConfig({
  plugins: [
    federation({
      name: 'host-app',
      remotes: {
        remoteApp: 'http://localhost:5001/assets/remoteEntry.js',
      },
      shared: ['react', 'react-dom'],
    }),
  ],
});
```

---

## 性能测量与监控

**web-vitals.js 实时采集**

```typescript
import { onLCP, onINP, onCLS, onTTFB } from 'web-vitals';

onLCP(console.log);
onINP(console.log);
onCLS(console.log);
onTTFB(console.log);

// 上报到监控系统
onLCP((metric) => {
  fetch('/api/metrics', {
    method: 'POST',
    body: JSON.stringify({
      name: 'LCP',
      value: metric.value,
      id: metric.id,
    }),
  });
});
```

**Lighthouse CI**

```bash
# .github/workflows/lighthouse.yml
npm install -g @lhci/cli
lhci autorun --config=lighthouserc.js
```

```javascript
// lighthouserc.js
module.exports = {
  ci: {
    assert: {
      assertions: {
        'categories:performance': ['warn', { minScore: 0.9 }],
        'categories:accessibility': ['error', { minScore: 0.95 }],
        'first-contentful-paint': ['warn', { maxNumericValue: 1800 }],
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
      },
    },
  },
};
```

---

## 虚拟滚动与大数据渲染

```tsx
import { useVirtualizer } from '@tanstack/react-virtual';

function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);
  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50, // 每行预估高度
    overscan: 5, // 视口外预渲染行数
  });

  return (
    <div ref={parentRef} style={{ height: '400px', overflow: 'auto' }}>
      <div style={{ height: `${virtualizer.getTotalSize()}px`, position: 'relative' }}>
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualItem.size}px`,
              transform: `translateY(${virtualItem.start}px)`,
            }}
          >
            {items[virtualItem.index].name}
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

## 资源加载优化

**Prefetch / Preload**

```html
<!-- 预加载关键资源 -->
<link rel="preload" href="/fonts/inter.woff2" as="font" type="font/woff2" crossorigin />

<!-- 预获取下一页 -->
<link rel="prefetch" href="/dashboard" />

<!-- 预连接第三方域名 -->
<link rel="preconnect" href="https://api.example.com" />
<link rel="dns-prefetch" href="https://cdn.example.com" />
```

**Script 加载策略**

```html
<!-- async: 并行下载，下载完立即执行 -->
<script async src="/analytics.js"></script>

<!-- defer: 并行下载，HTML 解析完后执行 -->
<script defer src="/app.js"></script>

<!-- module: 自动 defer -->
<script type="module" src="/app.js"></script>

<!-- 关键脚本内联 -->
<script>
  // 首屏必需的 JS 内联，避免额外请求
  document.documentElement.classList.add('js-enabled');
</script>
```
