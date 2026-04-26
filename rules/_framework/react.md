---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
---

# React 编码规范

## 组件

- **函数组件 + Hooks** 优先，类组件仅在有充分理由
- 组件单一职责
- props 类型显式（TypeScript / PropTypes）
- 组件文件：`PascalCase.tsx`
- 一个文件一个主组件（辅助组件除外）

## Hooks

- 顶层调用，不在循环/条件中
- 自定义 Hook 以 `use` 开头
- `useEffect` 依赖完整（ESLint exhaustive-deps）
- `useMemo` / `useCallback` 不滥用（有明确的性能或引用稳定需求才加）

## 状态管理

- 局部 state：`useState`
- 派生 state：直接计算，不存 state
- 复杂 state 逻辑：`useReducer`
- 跨层共享：`Context` 或外部状态库（Zustand / Redux / Jotai）
- 服务端状态：TanStack Query / SWR（**不手动管理**异步数据）

## 副作用

- `useEffect` 用于**同步到外部系统**（订阅、DOM、timer）
- 不用 `useEffect` 做：
  - 响应事件（用事件处理器）
  - 派生 state（直接计算）
  - 数据获取（用 Query 库）

## 列表

- `key` 必须稳定且唯一（**不用 index** 除非列表静态）
- 大列表（>100）用虚拟化（`react-window`、`tanstack-virtual`）

## 性能

- 避免不必要的重渲染：
  - 稳定引用（`useMemo` / `useCallback` 传给子组件）
  - `React.memo` 的合理使用
- Profiler 定位性能问题，不凭感觉加优化
- 代码分割：`React.lazy` + `Suspense`

## 错误边界

- 关键 UI 树包裹 `ErrorBoundary`
- Error boundary 不捕获事件处理器错误、异步错误——这些要手动 try/catch

## 事件处理

- 命名：`handle{Event}` 内部、`on{Event}` props
- 防抖 / 节流：大量事件时
- 清理：订阅、定时器必须在 cleanup 中注销

## 表单

- 简单：受控组件
- 复杂：专用库（React Hook Form / Formik）
- 验证：Zod / Yup / Joi

## 测试

- Testing Library（用户视角，不测实现）
- Selector 优先级：`role` > `label` > `text` > `data-testid` > `className`
- 避免测试内部 state，测试渲染结果和行为

## 可访问性

- 语义化 HTML：`<button>`, `<nav>`, `<main>`
- `role` / `aria-*` 只在原生语义不足时
- 键盘可达：`tabindex`、focus 可见、focus trap（对话框）

## 反模式

✗ 直接修改 state（`state.push(...)` 不触发渲染）
✗ 在 render 中做副作用
✗ 在 `useEffect` 中做可以在事件处理器中做的事
✗ `useState` 存可从 props 或其他 state 派生的值
✗ 过度使用 `useMemo` / `useCallback`（增加成本不增加收益）
✗ 在 render 中创建新对象/函数传给 memo 子组件（破坏 memo）

---

## 高频陷阱（含反例代码）

### 陷阱 1：useEffect 闭包捕获旧值（stale closure）

✗ 错误：定时器读到旧的 count
```tsx
function Counter() {
  const [count, setCount] = useState(0)
  useEffect(() => {
    const id = setInterval(() => {
      setCount(count + 1)  // ❌ 始终读到 count=0，count 永远 = 1
    }, 1000)
    return () => clearInterval(id)
  }, [])  // 空依赖 = 闭包冻结
}
```

✓ 正确：用函数式更新
```tsx
useEffect(() => {
  const id = setInterval(() => {
    setCount(c => c + 1)  // 用最新 c
  }, 1000)
  return () => clearInterval(id)
}, [])
```

### 陷阱 2：list key 用 index 导致输入丢失

✗ 错误：
```tsx
{items.map((item, i) => (
  <input key={i} defaultValue={item.name} />  // 删除中间项，所有 input 错位
))}
```

✓ 正确：用稳定 ID
```tsx
{items.map(item => (
  <input key={item.id} defaultValue={item.name} />
))}
```

**判据**：`key={index}` 在动态列表（增删排序）中视为 Critical bug。仅静态列表（永不变化）允许。

### 陷阱 3：useEffect 依赖错误导致死循环

✗ 错误：
```tsx
useEffect(() => {
  setData({ count: data.count + 1 })  // ❌ 改 data 触发 effect，effect 又改 data
}, [data])
```

✓ 正确：识别真实依赖
```tsx
// 如果是事件触发，移到事件处理器
function handleClick() {
  setData({ count: data.count + 1 })
}

// 如果是初始化，effect 用空依赖 + ref 守卫
const initialized = useRef(false)
useEffect(() => {
  if (initialized.current) return
  initialized.current = true
  setData({ count: 1 })
}, [])
```

### 陷阱 4：在 render 中创建对象传给 memo 子组件

✗ 错误：memo 失效
```tsx
function Parent() {
  return <Child config={{ theme: 'dark' }} />
  //              ^ 每次 render 新对象，Child memo 失效
}
const Child = React.memo(({ config }) => ...)
```

✓ 正确：稳定引用
```tsx
function Parent() {
  const config = useMemo(() => ({ theme: 'dark' }), [])
  return <Child config={config} />
}
```

或更好：把 config 提出组件
```tsx
const CONFIG = { theme: 'dark' } as const
function Parent() {
  return <Child config={CONFIG} />
}
```

### 陷阱 5：用 useEffect 做派生 state

✗ 错误：
```tsx
function User({ firstName, lastName }) {
  const [fullName, setFullName] = useState('')
  useEffect(() => {
    setFullName(`${firstName} ${lastName}`)  // ❌ 双次渲染 + 同步问题
  }, [firstName, lastName])
}
```

✓ 正确：直接计算
```tsx
function User({ firstName, lastName }) {
  const fullName = `${firstName} ${lastName}`  // 派生值不需要 state
}
```

### 陷阱 6：Context value 不稳定导致全树重渲

✗ 错误：
```tsx
function App() {
  const [user, setUser] = useState(null)
  return (
    <UserContext.Provider value={{ user, setUser }}>
      {/* 每次 render 新对象，所有 consumer 重渲 */}
    </UserContext.Provider>
  )
}
```

✓ 正确：
```tsx
function App() {
  const [user, setUser] = useState(null)
  const value = useMemo(() => ({ user, setUser }), [user])
  return <UserContext.Provider value={value}>{...}</UserContext.Provider>
}
```

### 陷阱 7：Strict Mode 下 effect 执行两次时假设单次

✗ 错误：
```tsx
useEffect(() => {
  socket.connect()  // ❌ Strict Mode 下连接 2 次，可能撞限流
}, [])
```

✓ 正确：cleanup 必须配对
```tsx
useEffect(() => {
  socket.connect()
  return () => socket.disconnect()  // 第二次连接前先断开
}, [])
```

### 陷阱 8：在 setState 之后立即读 state（异步陷阱）

✗ 错误：
```tsx
const [count, setCount] = useState(0)
function handleClick() {
  setCount(1)
  console.log(count)  // ❌ 仍然是 0，state 更新是异步的
}
```

✓ 正确：用本地变量或 useEffect 响应
```tsx
function handleClick() {
  const newCount = 1
  setCount(newCount)
  console.log(newCount)  // 用本地值
  // 或用 useEffect([count]) 响应 state 变化
}
```

---

## 决策树：什么时候不用 useEffect

```
我想要副作用？
├─ 它是响应用户交互的吗？
│   └─ ✅ 用事件处理器，不用 useEffect
├─ 它是计算派生值吗？
│   └─ ✅ 直接在 render 中计算，不用 state + useEffect
├─ 它是数据获取吗？
│   └─ ✅ 用 TanStack Query / SWR，不手动 useEffect + fetch
├─ 它是同步到外部系统（DOM API、订阅、定时器）吗？
│   └─ ✅ 这是 useEffect 的正确用法
└─ 它是初始化全局状态吗？
    └─ ⚠️ 考虑外部状态库（Zustand / Jotai）而非 useEffect
```

参考：[You Might Not Need an Effect](https://react.dev/learn/you-might-not-need-an-effect)
