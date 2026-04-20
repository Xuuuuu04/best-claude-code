# HarmonyOS Domain — ArkTS Language, Decorators, and State Architecture

## 1. Decorator Ownership Hierarchy

### 1.1 State Ownership Graph

Every piece of state has exactly one owner decorated with `@State`. Children receive via `@Prop` (read-only copy) or `@Link` (two-way reference). Cross-hierarchy via `@Provide`/`@Consume`.

```typescript
// BAD — direct mutation of @State object does not trigger re-render
@Component
struct OrderList {
  @State orders: Order[] = []

  build() {
    Button('Add').onClick(() => {
      this.orders.push(new Order('item-123')) // INVISIBLE to ArkUI
    })
    List() {
      ForEach(this.orders, (order: Order) => {
        ListItem() { Text(order.id) }
      })
    }
  }
}

// GOOD — replace reference to trigger reactivity
@Component
struct OrderList {
  @State orders: Order[] = []

  build() {
    Button('Add').onClick(() => {
      this.orders = [...this.orders, new Order('item-123')]
    })
    List() {
      ForEach(this.orders, (order: Order) => {
        ListItem() { Text(order.id) }
      }, (order: Order) => order.id) // keyGenerator
    }
  }
}
```

### 1.2 Decorator Reference Table

| Decorator | Direction | Owner | Use Case |
|-----------|-----------|-------|----------|
| `@State` | Self-owned | Current component | Local mutable state |
| `@Prop` | One-way (down) | Parent | Parent passes data to child, child cannot modify |
| `@Link` | Two-way | Parent | Parent and child share mutable reference |
| `@Provide` / `@Consume` | Cross-hierarchy | Ancestor / Descendant | Deep prop drilling avoidance |
| `@Observed` / `@ObjectLink` | Nested observation | Class + Component | Object property changes trigger re-render |
| `@ObservedV2` / `@Trace` | Fine-grained (API 12+) | Class + Component | Property-level tracking |

```typescript
// @Provide / @Consume for cross-hierarchy state
@Entry
@Component
struct ParentPage {
  @Provide('theme') theme: Theme = new Theme('light')

  build() {
    Column() {
      ChildComponent()
    }
  }
}

@Component
struct ChildComponent {
  build() {
    GrandChildComponent()
  }
}

@Component
struct GrandChildComponent {
  @Consume('theme') theme: Theme

  build() {
    Text('Themed Text')
      .fontColor(this.theme.primaryColor)
  }
}
```

### 1.3 @Observed + @ObjectLink for Nested Objects

```typescript
@Observed
class ShoppingCart {
  items: CartItem[] = []
  totalPrice: number = 0

  addItem(item: CartItem) {
    this.items.push(item)
    this.recalculateTotal()
  }

  private recalculateTotal() {
    this.totalPrice = this.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  }
}

@Component
struct CartView {
  @ObjectLink cart: ShoppingCart

  build() {
    Column() {
      Text(`Total: ¥${this.cart.totalPrice}`)
      List() {
        ForEach(this.cart.items, (item: CartItem) => {
          ListItem() {
            Text(`${item.name} x${item.quantity}`)
          }
        }, (item: CartItem) => item.id)
      }
    }
  }
}
```

---

## 2. ArkTS Strict Mode Compliance

### 2.1 No `any` Type

```typescript
// BAD — any type bypasses type checking
function processData(data: any): any {
  return data.value // No compile-time checking
}

// GOOD — explicit types
interface ApiResponse<T> {
  code: number
  data: T
  message: string
}

function processData<T>(response: ApiResponse<T>): T {
  if (response.code !== 0) {
    throw new Error(response.message)
  }
  return response.data
}
```

### 2.2 No Dynamic Property Access

```typescript
// BAD — dynamic property access
const value = obj[fieldName] // Compile error in strict mode

// GOOD — typed access with index signature
interface ConfigMap {
  [key: string]: string
}

function getConfig(config: ConfigMap, key: string): string {
  return config[key] ?? ''
}
```

### 2.3 No `eval()` or `new Function()`

```typescript
// BAD — both forbidden in ArkTS strict mode
eval('console.log("hello")')
const fn = new Function('a', 'b', 'return a + b')
```

---

## 3. Concurrency: taskpool vs Worker vs NAPI

### 3.1 taskpool for Concurrent Tasks

```typescript
import taskpool from '@ohos.taskpool'

// Define concurrent task
@Concurrent
function calculatePrimes(start: number, end: number): number[] {
  const primes: number[] = []
  for (let i = start; i <= end; i++) {
    if (isPrime(i)) primes.push(i)
  }
  return primes
}

function isPrime(n: number): boolean {
  if (n < 2) return false
  for (let i = 2; i <= Math.sqrt(n); i++) {
    if (n % i === 0) return false
  }
  return true
}

// Execute in taskpool
async function findPrimesInRange() {
  const task1 = new taskpool.Task(calculatePrimes, 2, 50000)
  const task2 = new taskpool.Task(calculatePrimes, 50001, 100000)

  const [primes1, primes2] = await taskpool.execute(task1, task2)
  return [...primes1, ...primes2]
}
```

### 3.2 Worker for Long-Running Background Work

```typescript
// worker.ts
import worker from '@ohos.worker'

const workerPort = worker.workerPort

workerPort.onmessage = (e: MessageEvents) => {
  const { type, data } = e.data
  switch (type) {
    case 'processImage':
      const result = processImage(data)
      workerPort.postMessage({ type: 'imageProcessed', data: result })
      break
  }
}

function processImage(imageData: ArrayBuffer): ArrayBuffer {
  // Heavy image processing
  return imageData
}
```

```typescript
// Main thread
import worker from '@ohos.worker'

const imageWorker = new worker.ThreadWorker('entry/ets/workers/ImageWorker.ts')

imageWorker.postMessage({
  type: 'processImage',
  data: imageArrayBuffer
})

imageWorker.onmessage = (e: MessageEvents) => {
  if (e.data.type === 'imageProcessed') {
    displayProcessedImage(e.data.data)
  }
}

// Clean up when done
imageWorker.terminate()
```

---

## 4. Module System: HAP vs HSP vs HAR

| Module Type | Description | Use Case |
|-------------|-------------|----------|
| HAP | HarmonyOS Ability Package — deployable unit | Entry module, feature modules |
| HSP | Harmony Shared Package — runtime shared | Shared libraries loaded once at runtime |
| HAR | Harmony Archive — compile-time static | Code reuse, compiled into dependent HAP |

```json
// entry/oh-package.json5
{
  "name": "entry",
  "version": "1.0.0",
  "description": "Entry module",
  "main": "",
  "author": "",
  "license": "",
  "dependencies": {
    "@hw-agconnect/core": "^1.4.0",
    "@hw-agconnect/push": "^1.4.0",
    "@hw-agconnect/auth": "^1.4.0"
  }
}
```

```json
// build-profile.json5
{
  "app": {
    "signingConfigs": [],
    "compileSdkVersion": 11,
    "compatibleSdkVersion": 11,
    "products": [
      {
        "name": "default",
        "signingConfig": "default",
        "compatibleSdkVersion": "11",
        "runtimeOS": "HarmonyOS"
      }
    ]
  },
  "modules": [
    {
      "name": "entry",
      "srcPath": "./entry",
      "targets": [
        {
          "name": "default",
          "applyToProducts": ["default"]
        }
      ]
    }
  ]
}
```
