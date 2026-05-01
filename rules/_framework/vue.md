---
paths:
  - "**/*.vue"
---

<rule name="vue-version-and-api">
  <convention>Vue 3+ 优先</convention>
  <convention>Composition API + script setup 语法优先于 Options API</convention>
  <convention>TypeScript 强烈推荐</convention>
</rule>

<rule name="vue-components">
  <convention>单文件组件（SFC）：template + script + style</convention>
  <convention>文件名 PascalCase.vue</convention>
  <convention>组件名 PascalCase（模板中和 template 引用时）</convention>
  <convention>一个文件一个组件</convention>
</rule>

<rule name="vue-reactivity">
  <convention>单值：ref()</convention>
  <convention>对象/数组：reactive()</convention>
  <convention>派生：computed()</convention>
  <convention>副作用：watch()（显式依赖）或 watchEffect()（自动依赖）</convention>

  <constraint severity="warning">解构 reactive 对象会丢失响应性：用 toRefs 或直接访问</constraint>
  <constraint severity="warning">ref 在 template 中自动解包，在 script 中需要 .value</constraint>
</rule>

<rule name="vue-props-and-emits">
  <pattern>
    <code language="vue">
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
    </code>
  </pattern>
  <convention>Props 默认值：withDefaults(defineProps<...>(), { showEmail: false })</convention>
</rule>

<rule name="vue-directives">
  <constraint severity="blocker">v-for 必须有 key（稳定唯一）</constraint>
  <constraint severity="warning">不要 v-for 和 v-if 在同一元素（性能 + 语义）</constraint>
  <convention>v-show vs v-if：频繁切换用 show，条件稀疏用 if</convention>
  <convention>v-model 双向绑定，自定义组件需要 modelValue + update:modelValue</convention>
</rule>

<rule name="vue-lifecycle">
  <convention>onMounted、onUnmounted、onUpdated 等</convention>
  <constraint severity="blocker">订阅、定时器必须在 onUnmounted 中清理</constraint>
</rule>

<rule name="vue-state-management">
  <convention>简单：provide / inject 跨层</convention>
  <convention>复杂：Pinia（官方推荐，Vue 3 原生感）</convention>
  <constraint severity="warning">避免 Vuex（Vue 2 时代，已被 Pinia 替代）</constraint>
</rule>

<rule name="vue-routing">
  <convention>Vue Router 4+（组合式 API 风格）</convention>
  <convention>useRouter / useRoute</convention>
  <convention>路由守卫：业务权限检查</convention>
</rule>

<rule name="vue-styles">
  <convention>优先 scoped 或 CSS Modules 避免泄漏</convention>
  <convention>不推荐在组件内写全局样式</convention>
  <convention>支持 CSS 预处理器（style lang="scss"）</convention>
</rule>

<rule name="vue-scoped-css-duplicate-declaration-pitfall">
  <description>Scoped CSS 重复声明陷阱（高频 bug）</description>
  <convention>scoped 编译后所有选择器都加 .cls.data-v-xxx 后缀。同一选择器在 style 内声明多次时后者完全覆盖前者（不是 cascade 增强，是等价覆盖）。</convention>

  <example type="bad">
    <code language="vue">
<style scoped>
.menu-item { padding: 28rpx 32rpx; }
/* ... 100 行后 ... */
.panel-menu { ... }
.menu-item { padding: 28rpx 0; }  /* 后声明覆盖前面，主菜单 padding 实际 = 0 */
</style>
    </code>
  </example>

  <example type="good">
    <title>用后代选择器或独立类名限定作用域</title>
    <code language="vue">
<style scoped>
.menu-item { padding: 28rpx 32rpx; }
.panel-menu .menu-item { padding: 28rpx 0; }
</style>
    </code>
  </example>

  <check>改 .vue 文件 CSS 前必做：grep -nE '^\s*\.{className}\s*\{' file.vue 确认目标类只声明一次。客户报告"我改了但没变化"时，第一反应排查 CSS 覆盖，而不是缓存或编译问题。</check>
</rule>

<rule name="vue-performance">
  <convention>v-memo 缓存渲染</convention>
  <convention>shallowRef / shallowReactive 避免深度响应</convention>
  <convention>大列表虚拟化（vue-virtual-scroller）</convention>
  <convention>异步组件 + Suspense</convention>
</rule>

<rule name="vue-testing">
  <convention>Vitest + Vue Test Utils</convention>
  <convention>组件测试：mount() / shallowMount()</convention>
  <convention>交互优先于快照</convention>
</rule>

<rule name="vue-anti-patterns">
  <constraint severity="blocker">在 created / setup 中做异步操作且不处理竞态</constraint>
  <constraint severity="blocker">watch 未清理</constraint>
  <constraint severity="blocker">直接修改 props（破坏单向数据流）</constraint>
  <constraint severity="warning">过度使用 provide/inject 替代 props</constraint>
  <constraint severity="warning">在 template 中调用昂贵方法（用 computed）</constraint>
  <constraint severity="blocker">动态切换 input :type 不加 :key：input 已有值时浏览器可能不重新渲染，密码可见性切换无效。修复：input :type="show ? 'text' : 'password'" :key="show" 强制重建 DOM。</constraint>
</rule>
