---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "**/*.cts"
---

<rule>
  <!-- ====== 类型系统 ====== -->
  <constraint severity="blocker">禁止 `any`：使用 `unknown` + 类型守卫</constraint>
  <constraint severity="blocker">导出函数必须有显式返回类型</constraint>
  <convention>接口**不加** `I` 前缀（`User` 而非 `IUser`）</convention>
  <convention>优先 `type`，除非需要 `extends` / `implements`</convention>
  <constraint severity="blocker">严格模式：`strict: true` 必须开启（若项目为 false，记入遗留问题）</constraint>
  <convention>使用 `readonly`、`as const` 增强不可变性</convention>

  <!-- ====== 导入导出 ====== -->
  <constraint severity="blocker">ES modules（`import`/`export`），不用 CommonJS（`require`）</constraint>
  <convention>解构导入：`import { foo } from 'bar'`</convention>
  <convention>类型导入：`import type { User } from './types'`</convention>
  <convention>避免默认导出（除了框架要求的，如 React 组件）</convention>
  <convention>按分组排序：标准库 → 第三方 → 本项目（绝对路径）→ 本项目（相对路径）</convention>

  <!-- ====== 空值处理 ====== -->
  <constraint severity="blocker">严格区分 `undefined` 和 `null`（项目应选其一为主）</constraint>
  <convention>可选链 `?.` 和空值合并 `??` 优先于 `||`</convention>
  <constraint severity="blocker">避免非空断言 `!`（除非注释解释为什么安全）</constraint>

  <!-- ====== 命名 ====== -->
  <convention>变量、函数：`camelCase`</convention>
  <convention>类、类型、接口、枚举：`PascalCase`</convention>
  <convention>常量：`UPPER_SNAKE_CASE`（仅对真正的编译时常量）</convention>
  <convention>文件名：`kebab-case` 或项目约定</convention>
  <convention>React 组件文件：`PascalCase.tsx`</convention>
  <convention>布尔：`is` / `has` / `can` 前缀</convention>

  <!-- ====== 异步 ====== -->
  <convention>`async/await` 优先于 `.then()` 链</convention>
  <constraint severity="blocker">Promise 错误必须处理（不 `.catch()` 也要 `await` 后的 try）</constraint>
  <convention>顶层 await 仅在 ESM 入口模块</convention>
  <constraint severity="blocker">禁止 `async` 函数返回 `void`（应返回 `Promise<void>`）</constraint>

  <!-- ====== 错误处理 ====== -->
  <convention>自定义错误类继承 `Error`</convention>
  <constraint severity="blocker">抛 Error 对象而非字符串</constraint>
  <constraint severity="warning">`try/catch (e)` 不要用 `e: any`，用 `e: unknown` + 类型守卫</constraint>
  <constraint severity="blocker">不吞异常，参考 `_global/error-handling.md`</constraint>

  <!-- ====== 其他 ====== -->
  <constraint severity="blocker">禁止 `// @ts-ignore` 和 `// @ts-nocheck`（用 `// @ts-expect-error` 并说明原因）</constraint>
  <convention>`enum` vs union：简单场景用 string union，需要运行时值用 enum 或 `as const` 对象</convention>
  <constraint severity="warning">避免 namespace（用 ES module）</constraint>
  <convention>循环中避免 `await`（除非顺序必需）——用 `Promise.all` 并行</convention>

  <!-- ====== ESLint ====== -->
  <constraint severity="blocker">项目如有 ESLint 配置，必须通过。不接受 `eslint-disable-next-line` 除非有明确注释说明原因。</constraint>

  <!-- ====== 高频陷阱 ====== -->

  <!-- 陷阱 1：as any 静默吞类型错误（接口字段最常见） -->
  <constraint severity="blocker">任何 `as any` / `as unknown as T` 在 code review 中视为 Critical，必须替换为运行时校验或在注释里写 owner 和 ticket。</constraint>
  <example type="bad">

```ts
// 后端返回 { orderId: string }，前端期望 number，强转跳过校验
const order = response.data as any
const id: number = order.orderId  // 运行时是 string，比较和数学运算全错
```

  </example>
  <example type="good">

```ts
import { z } from 'zod'

const OrderSchema = z.object({
  orderId: z.string(),  // 显式声明真实类型
  amount: z.number(),
})

const order = OrderSchema.parse(response.data)  // 失败抛错而非静默
```

  </example>

  <!-- 陷阱 2：枚举判断 magic number（4.7 字面化下高频） -->
  <constraint severity="blocker">高级代码审查师 看到无引用的 `=== <number>` 视为 Critical。详见 `_global/dispatch-table.md` 接口字段对账。</constraint>
  <example type="bad">

```ts
if (order.payType === 1) {  // 1 是什么？支付宝？微信？
  showWechatIcon()
}
```

  </example>
  <example type="good">

```ts
import { PAY_TYPE } from '@/shared/constants/payType'

if (order.payType === PAY_TYPE.WECHAT) {
  showWechatIcon()
}
```

  </example>

  <!-- 陷阱 3：Promise 未 await 静默失败 -->
  <constraint severity="blocker">`@typescript-eslint/no-floating-promises` 必须开启。</constraint>
  <example type="bad">

```ts
async function saveOrder(order: Order) {
  db.save(order)  // 没 await！函数立即返回，错误丢失
  return { ok: true }
}
```

  </example>
  <example type="good">

```ts
async function saveOrder(order: Order) {
  await db.save(order)  // 错误正确传播
  return { ok: true }
}

// ESLint: 启用 @typescript-eslint/no-floating-promises 自动检测
```

  </example>

  <!-- 陷阱 4：Object.keys 不收缩为 keyof T -->
  <example type="bad">

```ts
const obj: Record<string, number> = { a: 1, b: 2 }
Object.keys(obj).forEach(k => {
  obj[k]  // k: string，但 obj 的索引签名要求 k 是 keyof obj —— TS 失明
})
```

  </example>
  <example type="good">

```ts
(Object.keys(obj) as Array<keyof typeof obj>).forEach(k => {
  obj[k]  // 类型正确
})

// 或用 for-in 循环（同样需要类型断言）
// 或重构为已知键的 union 类型
```

  </example>

  <!-- 陷阱 5：?. 链后做赋值 -->
  <example type="bad">

```ts
config?.user.name = 'Alice'  // ❌ SyntaxError：可选链不能用于左值
```

  </example>
  <example type="good">

```ts
if (config) {
  config.user.name = 'Alice'
}
```

  </example>

  <!-- 陷阱 6：discriminated union 没收缩 -->
  <example type="bad">

```ts
type Result = { ok: true; data: User } | { ok: false; error: string }

function handle(r: Result) {
  console.log(r.data)  // ❌ 当 r.ok=false 时 data 不存在，但 TS 不报错（已收缩失败）
}
```

  </example>
  <example type="good">

```ts
function handle(r: Result) {
  if (r.ok) {
    console.log(r.data)  // 这里 TS 知道 data 一定存在
  } else {
    console.error(r.error)
  }
}
```

  </example>

  <!-- ====== ESLint 推荐配置（最低基线） ====== -->
  <requirement>ESLint 最低基线配置：</requirement>
  <pattern>

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

  </pattern>
  <check>未达此基线 → 高级代码审查师 报 Warning，建议升级。</check>

</rule>
