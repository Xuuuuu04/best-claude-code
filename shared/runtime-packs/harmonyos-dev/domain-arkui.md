# HarmonyOS Domain — ArkUI Framework, Stage Model, and HMS Core

## 1. ArkUI Component Lifecycle and Performance

### 1.1 Component Lifecycle

```typescript
@Component
struct ProductListView {
  @State products: Product[] = []
  private dataSource: ProductDataSource = new ProductDataSource()

  aboutToAppear() {
    // Component about to appear — initialize data
    this.loadProducts()
  }

  aboutToDisappear() {
    // Component about to disappear — clean up
    this.dataSource.cleanup()
  }

  onPageShow() {
    // Page shown (when in a page)
  }

  onPageHide() {
    // Page hidden
  }

  onBackPress() {
    // Back button pressed — return true to intercept
    return false
  }

  build() {
    List() {
      LazyForEach(this.dataSource, (product: Product) => {
        ListItem() {
          ProductCard({ product: product })
        }
      }, (product: Product) => product.id)
    }
    .cachedCount(5)
    .divider({ strokeWidth: 1, color: '#f0f0f0' })
  }

  private async loadProducts() {
    // Load products
  }
}
```

### 1.2 @Reusable Component Pool

```typescript
@Reusable
@Component
struct ProductCard {
  @ObjectLink product: Product

  aboutToAppear() {
    // Reset state when reused from pool
    console.info('ProductCard reused for:', this.product.id)
  }

  build() {
    Row() {
      Image(this.product.imageUrl)
        .width(80)
        .height(80)
        .objectFit(ImageFit.Cover)

      Column() {
        Text(this.product.name)
          .fontSize(16)
          .maxLines(2)
        Text(`¥${this.product.price}`)
          .fontSize(18)
          .fontColor('#ff4444')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(12)
  }
}
```

### 1.3 LazyForEach with DataSource

```typescript
class ProductDataSource implements IDataSource {
  private listeners: DataChangeListener[] = []
  private products: Product[] = []

  totalCount(): number {
    return this.products.length
  }

  getData(index: number): Product {
    return this.products[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.push(listener)
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const index = this.listeners.indexOf(listener)
    if (index >= 0) {
      this.listeners.splice(index, 1)
    }
  }

  addProducts(newProducts: Product[]) {
    const startIndex = this.products.length
    this.products.push(...newProducts)
    this.listeners.forEach(l => l.onDataAdd(startIndex, newProducts.length))
  }

  cleanup() {
    this.products = []
    this.listeners = []
  }
}
```

---

## 2. Animation System

### 2.1 Explicit Animation with animateTo

```typescript
@Entry
@Component
struct AnimatedButton {
  @State scale: number = 1.0
  @State opacity: number = 1.0

  build() {
    Column() {
      Button('Tap Me')
        .scale({ x: this.scale, y: this.scale })
        .opacity(this.opacity)
        .onClick(() => {
          animateTo({
            duration: 300,
            curve: Curve.EaseInOut,
            onFinish: () => {
              // Animation complete
            }
          }, () => {
            this.scale = 0.9
            this.opacity = 0.7
          })

          // Return to normal
          animateTo({
            duration: 300,
            delay: 300,
            curve: Curve.Spring({ stiffness: 200, damping: 15 })
          }, () => {
            this.scale = 1.0
            this.opacity = 1.0
          })
        })
    }
  }
}
```

### 2.2 Transition Effects

```typescript
@Entry
@Component
struct TransitionDemo {
  @State showDetail: boolean = false

  build() {
    Stack() {
      if (!this.showDetail) {
        Button('Show Detail')
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 100 })))
          .onClick(() => this.showDetail = true)
      } else {
        Column() {
          Text('Detail View')
            .fontSize(24)
          Button('Back')
            .onClick(() => this.showDetail = false)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#fff')
        .transition(TransitionEffect.asymmetric(
          TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: -100 })),
          TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: 100 }))
        ))
      }
    }
  }
}
```

---

## 3. Stage Model Architecture

### 3.1 UIAbility Launch Modes

| Launch Mode | Behavior | Use Case |
|-------------|----------|----------|
| `singleton` (default) | Only one instance regardless of start count | Most apps |
| `multiton` | New instance for each start | Document-based apps |
| `specified` | Custom instance key | Specific multi-instance needs |

```json
// module.json5
{
  "module": {
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "launchType": "singleton",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:layered_image",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:start_window_background"
      }
    ]
  }
}
```

### 3.2 AbilityStage — App-Level Initialization

```typescript
// ets/entryability/AppAbilityStage.ets
import AbilityStage from '@ohos.app.ability.AbilityStage'
import { AGConnectInstance } from '@hw-agconnect/core-ohos'
import { pushService } from '@hw-agconnect/push-ohos'

export default class AppAbilityStage extends AbilityStage {
  onCreate(): void {
    // HMS Core initialization — MUST be here, not in UIAbility
    AGConnectInstance.getInstance(this.context)

    // Push Kit token registration
    pushService.getToken(this.context)
      .then((token: string) => {
        console.info('Push token obtained:', token.substring(0, 8) + '...')
        this.registerTokenToBackend(token)
      })
      .catch((err: BusinessError) => {
        console.error('Push token failed:', err.code, err.message)
      })
  }

  private registerTokenToBackend(token: string) {
    // POST token to your backend
  }
}
```

### 3.3 EntryAbility Lifecycle

```typescript
// ets/entryability/EntryAbility.ets
import UIAbility from '@ohos.app.ability.UIAbility'
import window from '@ohos.window'

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Load main page
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        console.error('Failed to load content:', err.message)
        return
      }
      console.info('Content loaded successfully')
    })

    // Set immersive status bar
    const mainWindow = windowStage.getMainWindowSync()
    mainWindow.setWindowSystemBarEnable(['status', 'navigation'])
  }

  onForeground(): void {
    // App enters foreground
  }

  onBackground(): void {
    // App enters background
  }

  onDestroy(): void {
    // Ability destroyed — clean up
  }
}
```

---

## 4. HMS Core Integration

### 4.1 Push Kit Token Lifecycle

```typescript
import { pushService } from '@hw-agconnect/push-ohos'
import { BusinessError } from '@ohos.base'

class PushManager {
  async getToken(context: Context): Promise<string> {
    try {
      const token = await pushService.getToken(context)
      console.info('Push token:', token)
      return token
    } catch (err) {
      const error = err as BusinessError
      console.error('Get token failed:', error.code, error.message)
      throw error
    }
  }

  onTokenRefresh(callback: (token: string) => void) {
    pushService.on('tokenRefresh', (token: string) => {
      console.info('Token refreshed:', token)
      callback(token)
    })
  }

  onMessageReceived(callback: (message: pushService.PushMessage) => void) {
    pushService.on('messageReceived', (message: pushService.PushMessage) => {
      console.info('Message received:', message)
      callback(message)
    })
  }
}
```

### 4.2 Account Kit Silent Sign-In

```typescript
import { account } from '@hw-agconnect/auth-ohos'

class AuthManager {
  async silentSignIn(): Promise<account.AuthResult | null> {
    try {
      const authParam = new account.AuthParam()
      const authService = account.HuaweiIdAuthManager.getService(authParam)
      const result = await authService.getAuthResult()

      if (result.isTokenValid()) {
        console.info('Silent sign-in success')
        return result
      } else {
        console.info('Token expired, needs explicit sign-in')
        return null
      }
    } catch (err) {
      console.error('Silent sign-in failed:', err)
      return null
    }
  }

  async explicitSignIn(): Promise<account.AuthResult | null> {
    try {
      const authParam = new account.AuthParam()
      authParam.setScope('openid profile')
      const authService = account.HuaweiIdAuthManager.getService(authParam)
      return await authService.getAuthResult()
    } catch (err) {
      console.error('Explicit sign-in failed:', err)
      return null
    }
  }
}
```

### 4.3 Pay Kit (IAP) Purchase Flow

```typescript
import { iap } from '@hw-agconnect/iap-ohos'

class PurchaseManager {
  async queryProducts(productIds: string[]): Promise<iap.ProductInfo[]> {
    const result = await iap.queryProducts({
      productIds: productIds,
      productType: iap.ProductType.CONSUMABLE
    })
    return result.productInfoList
  }

  async purchase(productId: string): Promise<boolean> {
    try {
      const purchaseResult = await iap.purchase({
        productId: productId,
        productType: iap.ProductType.CONSUMABLE
      })

      // Verify purchase on your backend
      const verified = await this.verifyPurchaseOnBackend(purchaseResult)

      if (verified) {
        // Consume the purchase for consumables
        await iap.consumePurchase({
          purchaseToken: purchaseResult.purchaseToken
        })
        return true
      }
      return false
    } catch (err) {
      console.error('Purchase failed:', err)
      return false
    }
  }

  private async verifyPurchaseOnBackend(result: iap.PurchaseResult): Promise<boolean> {
    // POST to your backend for server-side validation
    return true
  }
}
```

---

## 5. System UI Integration

### 5.1 Immersive Status Bar

```typescript
import window from '@ohos.window'

function setupImmersive(windowStage: window.WindowStage) {
  const mainWindow = windowStage.getMainWindowSync()

  // Hide status bar
  mainWindow.setWindowSystemBarEnable([])

  // Or customize status bar appearance
  mainWindow.setWindowSystemBarProperties({
    statusBarColor: '#00000000',
    statusBarContentColor: '#FFFFFF'
  })
}
```

### 5.2 Safe Area Insets

```typescript
@Entry
@Component
struct SafeAreaDemo {
  build() {
    Column() {
      // Content automatically respects safe area
      Text('Safe Content')
        .fontSize(20)
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM, SafeAreaType.CUTOUT, SafeAreaType.KEYBOARD])
    .backgroundColor('#f5f5f5')
  }
}
```
