> 源：shared/code-standards/typescript.md (migrated 2026-04-20)

# 前端开发师 — TypeScript 代码规范

## 严格模式

`tsconfig.json` 必须启用 `strict: true`，包含以下子选项：

- `strictNullChecks: true` — 空值必须显式处理
- `noImplicitAny: true` — 禁止隐式 any
- `strictFunctionTypes: true` — 函数类型严格检查

---

## 命名规范

| 类型 | 风格 | 示例 |
|------|------|------|
| 变量/函数 | camelCase | `getUserById`, `isActive` |
| 类/接口/类型/枚举 | PascalCase | `UserService`, `ApiResponse` |
| 常量 | UPPER_SNAKE_CASE | `MAX_PAGE_SIZE` |
| 组件文件 | PascalCase.vue | `UserProfile.vue` |
| 工具文件 | camelCase.ts | `formatDate.ts` |
| 私有属性 | `_` 前缀或 `#` | `_cache`, `#internal` |

---

## 类型定义规则

- **禁止 `any`**。使用 `unknown` + 类型守卫替代不确定类型
- 优先使用 `interface` 定义对象结构，`type` 用于联合类型和工具类型
- API 响应必须有类型定义，不允许 `as any` 断言
- 组件 props 使用 `defineProps<T>()` 泛型形式

### 运行时验证 — Zod

使用 Zod 做运行时数据验证。类型从 schema 推导，避免重复定义：

```typescript
import { z } from 'zod'

const UserSchema = z.object({
  id: z.number(),
  name: z.string().min(1),
  email: z.string().email(),
  role: z.enum(['admin', 'user']),
})

type User = z.infer<typeof UserSchema>

function parseUser(data: unknown): User {
  return UserSchema.parse(data) // throws ZodError on failure
}
```

**必须使用 Zod 的场景**：

- 外部 API 响应（第三方接口返回的数据结构不可信）
- 用户表单提交
- 环境变量 / 配置文件（启动时验证必需字段）
- 缓存数据读取

**禁止**：`as` 类型断言（`response.data as User`）用于不可信数据。

---

## 异步编程

- 优先使用 `async/await`，避免 `.then()` 链式调用
- 异步函数必须有错误处理（try/catch 或 .catch）
- 避免在循环中 await — 使用 `Promise.all` 或 `Promise.allSettled`

```typescript
// GOOD
async function fetchUsers(): Promise<User[]> {
  try {
    const response = await api.get<User[]>('/users')
    return response.data
  } catch (error) {
    console.error('Failed to fetch users:', error)
    throw error
  }
}

// BAD
function fetchUsers() {
  return api.get('/users').then(res => res.data).then(data => data)
}
```

---

## Vue 3 特有规范

### 组合式 API

- 所有新组件使用 `<script setup lang="ts">` 语法
- 响应式数据：基本类型用 `ref()`，对象用 `reactive()`
- 计算属性用 `computed()`，副作用用 `watch()`/`watchEffect()`
- 组件内逻辑顺序：props → emits → 响应式状态 → 计算属性 → 方法 → 生命周期

### 状态管理（Pinia）

- 每个 store 使用组合式语法（setup store）
- Store 文件放在 `stores/` 目录，命名 `useXxxStore.ts`
- 异步操作放在 store actions 中，不在组件中直接调用 API

### 组件设计

- 单文件组件三段顺序：`<script>` → `<template>` → `<style>`
- Props 必须有类型和默认值定义
- 事件名使用 kebab-case：`@update-value`
- 插槽使用具名插槽而非默认插槽（除非组件只有一个插槽点）

---

## ESLint 要求

使用 `@vue/eslint-config-typescript` + `eslint-plugin-vue` 推荐规则集：

- `no-unused-vars: error`
- `no-console: warn`（生产构建应移除 console）
- `vue/multi-word-component-names: error`
- `vue/no-v-html: warn`（XSS 风险）

---

## 导入顺序

1. Vue 核心（`vue`, `vue-router`, `pinia`）
2. 第三方库（`axios`, `element-plus`, `dayjs`）
3. 项目内公共模块（`@/utils`, `@/composables`, `@/stores`）
4. 当前模块的子组件和类型
