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
