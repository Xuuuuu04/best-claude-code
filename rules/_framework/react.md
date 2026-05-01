---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
---

<rule name="react-component-design">
  <convention>函数组件 + Hooks 优先，类组件仅在有充分理由时使用</convention>
  <convention>组件单一职责</convention>
  <convention>props 类型显式（TypeScript / PropTypes）</convention>
  <convention>组件文件：PascalCase.tsx</convention>
  <convention>一个文件一个主组件（辅助组件除外）</convention>
</rule>

<rule name="react-hooks">
  <convention>顶层调用，不在循环/条件中</convention>
  <convention>自定义 Hook 以 use 开头</convention>
  <convention>useEffect 依赖完整（ESLint exhaustive-deps）</convention>
  <convention>useMemo / useCallback 不滥用（有明确的性能或引用稳定需求才加）</convention>
</rule>

<rule name="react-state-management">
  <convention>局部 state：useState</convention>
  <convention>派生 state：直接计算，不存 state</convention>
  <convention>复杂 state 逻辑：useReducer</convention>
  <convention>跨层共享：Context 或外部状态库（Zustand / Redux / Jotai）</convention>
  <convention>服务端状态：TanStack Query / SWR（不手动管理异步数据）</convention>
</rule>

<rule name="react-effects">
  <convention>useEffect 用于同步到外部系统（订阅、DOM、timer）</convention>
  <constraint severity="warning">不用 useEffect 做：响应事件（用事件处理器）、派生 state（直接计算）、数据获取（用 Query 库）</constraint>
</rule>

<rule name="react-lists">
  <constraint severity="blocker">key 必须稳定且唯一，不用 index 除非列表静态</constraint>
  <convention>大列表（大于100）用虚拟化（react-window、tanstack-virtual）</convention>
</rule>

<rule name="react-performance">
  <convention>避免不必要的重渲染：稳定引用（useMemo / useCallback 传给子组件）、React.memo 的合理使用</convention>
  <convention>Profiler 定位性能问题，不凭感觉加优化</convention>
  <convention>代码分割：React.lazy + Suspense</convention>
</rule>

<rule name="react-error-boundaries">
  <convention>关键 UI 树包裹 ErrorBoundary</convention>
  <constraint severity="warning">Error boundary 不捕获事件处理器错误、异步错误——这些要手动 try/catch</constraint>
</rule>

<rule name="react-event-handling">
  <convention>命名：handle{Event} 内部、on{Event} props</convention>
  <convention>防抖 / 节流：大量事件时</convention>
  <convention>清理：订阅、定时器必须在 cleanup 中注销</convention>
</rule>

<rule name="react-forms">
  <convention>简单：受控组件</convention>
  <convention>复杂：专用库（React Hook Form / Formik）</convention>
  <convention>验证：Zod / Yup / Joi</convention>
</rule>

<rule name="react-testing">
  <convention>Testing Library（用户视角，不测实现）</convention>
  <convention>Selector 优先级：role 大于 label 大于 text 大于 data-testid 大于 className</convention>
  <convention>避免测试内部 state，测试渲染结果和行为</convention>
</rule>

<rule name="react-accessibility">
  <convention>语义化 HTML：button、nav、main</convention>
  <convention>role / aria-* 只在原生语义不足时使用</convention>
  <convention>键盘可达：tabindex、focus 可见、focus trap（对话框）</convention>
</rule>

<rule name="react-anti-patterns">
  <constraint severity="blocker">直接修改 state（state.push(...) 不触发渲染）</constraint>
  <constraint severity="blocker">在 render 中做副作用</constraint>
  <constraint severity="blocker">在 useEffect 中做可以在事件处理器中做的事</constraint>
  <constraint severity="blocker">useState 存可从 props 或其他 state 派生的值</constraint>
  <constraint severity="warning">过度使用 useMemo / useCallback（增加成本不增加收益）</constraint>
  <constraint severity="warning">在 render 中创建新对象/函数传给 memo 子组件（破坏 memo）</constraint>
</rule>

<rule name="react-pitfall-stale-closure">
  <description>useEffect 闭包捕获旧值（stale closure）</description>

  <example type="bad">
    <title>定时器读到旧的 count</title>
    <code language="tsx">
function Counter() {
  const [count, setCount] = useState(0)
  useEffect(() => {
    const id = setInterval(() => {
      setCount(count + 1)  // 始终读到 count=0，count 永远 = 1
    }, 1000)
    return () => clearInterval(id)
  }, [])  // 空依赖 = 闭包冻结
}
    </code>
  </example>

  <example type="good">
    <title>用函数式更新</title>
    <code language="tsx">
useEffect(() => {
  const id = setInterval(() => {
    setCount(c => c + 1)  // 用最新 c
  }, 1000)
  return () => clearInterval(id)
}, [])
    </code>
  </example>
</rule>

<rule name="react-pitfall-list-key-index">
  <description>list key 用 index 导致输入丢失</description>

  <example type="bad">
    <code language="tsx">
{items.map((item, i) => (
  <input key={i} defaultValue={item.name} />  // 删除中间项，所有 input 错位
))}
    </code>
  </example>

  <example type="good">
    <title>用稳定 ID</title>
    <code language="tsx">
{items.map(item => (
  <input key={item.id} defaultValue={item.name} />
))}
    </code>
  </example>

  <constraint severity="blocker">key={index} 在动态列表（增删排序）中视为 Critical bug。仅静态列表（永不变化）允许。</constraint>
</rule>

<rule name="react-pitfall-effect-infinite-loop">
  <description>useEffect 依赖错误导致死循环</description>

  <example type="bad">
    <code language="tsx">
useEffect(() => {
  setData({ count: data.count + 1 })  // 改 data 触发 effect，effect 又改 data
}, [data])
    </code>
  </example>

  <example type="good">
    <title>识别真实依赖：事件触发移到事件处理器；初始化用空依赖 + ref 守卫</title>
    <code language="tsx">
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
    </code>
  </example>
</rule>

<rule name="react-pitfall-render-objects-break-memo">
  <description>在 render 中创建对象传给 memo 子组件</description>

  <example type="bad">
    <title>memo 失效</title>
    <code language="tsx">
function Parent() {
  return <Child config={{ theme: 'dark' }} />
  //              ^ 每次 render 新对象，Child memo 失效
}
const Child = React.memo(({ config }) => ...)
    </code>
  </example>

  <example type="good">
    <title>稳定引用</title>
    <code language="tsx">
function Parent() {
  const config = useMemo(() => ({ theme: 'dark' }), [])
  return <Child config={config} />
}
    </code>
  </example>

  <example type="good">
    <title>更好：把 config 提出组件</title>
    <code language="tsx">
const CONFIG = { theme: 'dark' } as const
function Parent() {
  return <Child config={CONFIG} />
}
    </code>
  </example>
</rule>

<rule name="react-pitfall-useeffect-derived-state">
  <description>用 useEffect 做派生 state</description>

  <example type="bad">
    <code language="tsx">
function User({ firstName, lastName }) {
  const [fullName, setFullName] = useState('')
  useEffect(() => {
    setFullName(`${firstName} ${lastName}`)  // 双次渲染 + 同步问题
  }, [firstName, lastName])
}
    </code>
  </example>

  <example type="good">
    <title>直接计算</title>
    <code language="tsx">
function User({ firstName, lastName }) {
  const fullName = `${firstName} ${lastName}`  // 派生值不需要 state
}
    </code>
  </example>
</rule>

<rule name="react-pitfall-unstable-context">
  <description>Context value 不稳定导致全树重渲</description>

  <example type="bad">
    <code language="tsx">
function App() {
  const [user, setUser] = useState(null)
  return (
    <UserContext.Provider value={{ user, setUser }}>
      {/* 每次 render 新对象，所有 consumer 重渲 */}
    </UserContext.Provider>
  )
}
    </code>
  </example>

  <example type="good">
    <code language="tsx">
function App() {
  const [user, setUser] = useState(null)
  const value = useMemo(() => ({ user, setUser }), [user])
  return <UserContext.Provider value={value}>{/* ... */}</UserContext.Provider>
}
    </code>
  </example>
</rule>

<rule name="react-pitfall-strict-mode-double-effect">
  <description>Strict Mode 下 effect 执行两次时假设单次</description>

  <example type="bad">
    <code language="tsx">
useEffect(() => {
  socket.connect()  // Strict Mode 下连接 2 次，可能撞限流
}, [])
    </code>
  </example>

  <example type="good">
    <title>cleanup 必须配对</title>
    <code language="tsx">
useEffect(() => {
  socket.connect()
  return () => socket.disconnect()  // 第二次连接前先断开
}, [])
    </code>
  </example>
</rule>

<rule name="react-pitfall-setstate-async-read">
  <description>在 setState 之后立即读 state（异步陷阱）</description>

  <example type="bad">
    <code language="tsx">
const [count, setCount] = useState(0)
function handleClick() {
  setCount(1)
  console.log(count)  // 仍然是 0，state 更新是异步的
}
    </code>
  </example>

  <example type="good">
    <title>用本地变量或 useEffect 响应</title>
    <code language="tsx">
function handleClick() {
  const newCount = 1
  setCount(newCount)
  console.log(newCount)  // 用本地值
  // 或用 useEffect([count]) 响应 state 变化
}
    </code>
  </example>
</rule>

<rule name="react-effect-decision-tree">
  <description>什么时候不用 useEffect</description>
  <pattern>
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
  </pattern>
  <convention>参考：You Might Not Need an Effect (https://react.dev/learn/you-might-not-need-an-effect)</convention>
</rule>
