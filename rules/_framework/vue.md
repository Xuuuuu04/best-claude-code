---
paths:
  - "**/*.vue"
---

# Vue 编码规范

## 版本与 API

- Vue 3+ 优先
- **Composition API + `<script setup>`** 语法优先于 Options API
- TypeScript 强烈推荐

## 组件

- 单文件组件（SFC）：template + script + style
- 文件名 `PascalCase.vue`
- 组件名 `PascalCase`（模板中和 template 引用时）
- 一个文件一个组件

## 响应式

- 单值：`ref()`
- 对象/数组：`reactive()`
- 派生：`computed()`
- 副作用：`watch()`（显式依赖）或 `watchEffect()`（自动依赖）

### 陷阱
- 解构 `reactive` 对象会**丢失响应性**：用 `toRefs` 或直接访问
- `ref` 在 template 中自动解包，在 script 中需要 `.value`

## Props & Emits

```vue
<script setup lang="ts">
const props = defineProps<{
  userId: string;
  showEmail?: boolean;
}>();

const emit = defineEmits<{
  (e: 'update', value: string): void;
  (e: 'submit'): void;
}>();
</script>
```

Props 默认值：`withDefaults(defineProps<...>(), { showEmail: false })`

## 指令

- `v-for` 必须有 `key`（稳定唯一）
- **不要** `v-for` 和 `v-if` 在同一元素（性能 + 语义）
- `v-show` vs `v-if`：频繁切换用 show，条件稀疏用 if
- `v-model` 双向绑定，自定义组件需要 `modelValue` + `update:modelValue`

## 生命周期

- `onMounted`、`onUnmounted`、`onUpdated` 等
- 订阅、定时器**必须**在 `onUnmounted` 中清理

## 状态管理

- 简单：`provide` / `inject` 跨层
- 复杂：Pinia（官方推荐，Vue 3 原生感）
- 避免 Vuex（Vue 2 时代，已被 Pinia 替代）

## 路由

- Vue Router 4+（组合式 API 风格）
- `useRouter` / `useRoute`
- 路由守卫：业务权限检查

## 样式

- 优先 `scoped` 或 CSS Modules 避免泄漏
- 不推荐在组件内写全局样式
- 支持 CSS 预处理器（`<style lang="scss">`）

## 性能

- `v-memo` 缓存渲染
- `shallowRef` / `shallowReactive` 避免深度响应
- 大列表虚拟化（`vue-virtual-scroller`）
- 异步组件 + `Suspense`

## 测试

- Vitest + Vue Test Utils
- 组件测试：`mount()` / `shallowMount()`
- 交互优先于快照

## 反模式

✗ 在 `created` / `setup` 中做异步操作且不处理竞态
✗ watch 未清理
✗ 直接修改 props（破坏单向数据流）
✗ 过度使用 `provide/inject` 替代 props
✗ 在 template 中调用昂贵方法（用 computed）
