---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "**/*.cts"
---

# TypeScript 编码规范

## 类型系统

- **禁止 `any`**：使用 `unknown` + 类型守卫
- **导出函数**必须有显式返回类型
- 接口**不加** `I` 前缀（`User` 而非 `IUser`）
- 优先 `type`，除非需要 `extends` / `implements`
- **严格模式**：`strict: true` 必须开启（若项目为 false，记入遗留问题）
- 使用 `readonly`、`as const` 增强不可变性

## 导入导出

- ES modules（`import`/`export`），不用 CommonJS（`require`）
- 解构导入：`import { foo } from 'bar'`
- 类型导入：`import type { User } from './types'`
- 避免默认导出（除了框架要求的，如 React 组件）
- 按分组排序：标准库 → 第三方 → 本项目（绝对路径）→ 本项目（相对路径）

## 空值处理

- **严格区分** `undefined` 和 `null`（项目应选其一为主）
- 可选链 `?.` 和空值合并 `??` 优先于 `||`
- 避免非空断言 `!`（除非注释解释为什么安全）

## 命名

- 变量、函数：`camelCase`
- 类、类型、接口、枚举：`PascalCase`
- 常量：`UPPER_SNAKE_CASE`（仅对真正的编译时常量）
- 文件名：`kebab-case` 或项目约定
- React 组件文件：`PascalCase.tsx`
- 布尔：`is` / `has` / `can` 前缀

## 异步

- `async/await` 优先于 `.then()` 链
- Promise 错误必须处理（不 `.catch()` 也要 `await` 后的 try）
- 顶层 await 仅在 ESM 入口模块
- 禁止 `async` 函数返回 `void`（应返回 `Promise<void>`）

## 错误处理

- 自定义错误类继承 `Error`
- 抛 Error 对象而非字符串
- `try/catch (e)` 不要用 `e: any`，用 `e: unknown` + 类型守卫
- 不吞异常，参考 `_global/error-handling.md`

## 其他

- 禁止 `// @ts-ignore` 和 `// @ts-nocheck`（用 `// @ts-expect-error` 并说明原因）
- `enum` vs union：简单场景用 string union，需要运行时值用 enum 或 `as const` 对象
- 避免 namespace（用 ES module）
- 循环中避免 `await`（除非顺序必需）——用 `Promise.all` 并行

## ESLint

项目如有 ESLint 配置，必须通过。不接受 `eslint-disable-next-line` 除非有明确注释说明原因。
