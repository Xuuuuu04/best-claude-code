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

---

## 高频陷阱（含反例代码）

### 陷阱 1：`as any` 静默吞类型错误（接口字段最常见）

✗ 错误：
```ts
// 后端返回 { orderId: string }，前端期望 number，强转跳过校验
const order = response.data as any
const id: number = order.orderId  // 运行时是 string，比较和数学运算全错
```

✓ 正确：用 Zod / type guard 在边界做运行时校验
```ts
import { z } from 'zod'

const OrderSchema = z.object({
  orderId: z.string(),  // 显式声明真实类型
  amount: z.number(),
})

const order = OrderSchema.parse(response.data)  // 失败抛错而非静默
```

**判据**：任何 `as any` / `as unknown as T` 在 code review 中视为 Critical，必须替换为运行时校验或在注释里写 owner 和 ticket。

### 陷阱 2：枚举判断 magic number（4.7 字面化下高频）

✗ 错误：
```ts
if (order.payType === 1) {  // 1 是什么？支付宝？微信？
  showWechatIcon()
}
```

✓ 正确：始终引用字典常量
```ts
import { PAY_TYPE } from '@/shared/constants/payType'

if (order.payType === PAY_TYPE.WECHAT) {
  showWechatIcon()
}
```

**判据**：详见 `_global/dispatch-table.md` § 接口字段对账。code-reviewer 看到无引用的 `=== <number>` 视为 Critical。

### 陷阱 3：Promise 未 await 静默失败

✗ 错误：
```ts
async function saveOrder(order: Order) {
  db.save(order)  // 没 await！函数立即返回，错误丢失
  return { ok: true }
}
```

✓ 正确：
```ts
async function saveOrder(order: Order) {
  await db.save(order)  // 错误正确传播
  return { ok: true }
}

// ESLint: 启用 @typescript-eslint/no-floating-promises 自动检测
```

**判据**：`@typescript-eslint/no-floating-promises` 必须开启。

### 陷阱 4：`Object.keys` 不收缩为 keyof T

✗ 错误：
```ts
const obj: Record<string, number> = { a: 1, b: 2 }
Object.keys(obj).forEach(k => {
  obj[k]  // k: string，但 obj 的索引签名要求 k 是 keyof obj —— TS 失明
})
```

✓ 正确：
```ts
(Object.keys(obj) as Array<keyof typeof obj>).forEach(k => {
  obj[k]  // 类型正确
})

// 或用 for-in 循环（同样需要类型断言）
// 或重构为已知键的 union 类型
```

### 陷阱 5：`?.` 链后做赋值

✗ 错误：
```ts
config?.user.name = 'Alice'  // ❌ SyntaxError：可选链不能用于左值
```

✓ 正确：
```ts
if (config) {
  config.user.name = 'Alice'
}
```

### 陷阱 6：discriminated union 没收缩

✗ 错误：
```ts
type Result = { ok: true; data: User } | { ok: false; error: string }

function handle(r: Result) {
  console.log(r.data)  // ❌ 当 r.ok=false 时 data 不存在，但 TS 不报错（已收缩失败）
}
```

✓ 正确：先收缩再访问
```ts
function handle(r: Result) {
  if (r.ok) {
    console.log(r.data)  // 这里 TS 知道 data 一定存在
  } else {
    console.error(r.error)
  }
}
```

---

## ESLint 推荐配置（最低基线）

```json
{
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-floating-promises": "error",
    "@typescript-eslint/strict-boolean-expressions": "warn",
    "@typescript-eslint/switch-exhaustiveness-check": "error",
    "@typescript-eslint/no-unnecessary-type-assertion": "error",
    "@typescript-eslint/consistent-type-imports": "error"
  }
}
```

未达此基线 → code-reviewer 报 Warning，建议升级。
