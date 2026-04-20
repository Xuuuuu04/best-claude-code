# 鸿蒙开发师 — Anti-Patterns

## Named Anti-Patterns

---

### Android Mental Model Drift

**Definition**: Developer maps HarmonyOS concepts to Android equivalents. Symptoms: UIAbility treated like Activity (wrong lifecycle hooks), imports Android libraries, uses Java reflection patterns.

**Manifestations**:
```typescript
// BAD — treating UIAbility like Activity
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // WRONG: thinking this is like Activity.onCreate()
    // UIAbility context is NOT the same as Activity context
    this.setContentView('pages/Index') // setContentView doesn't exist!
  }
}
```

```typescript
// BAD — importing Android libraries
import android.os.Bundle // Does not exist on HarmonyOS NEXT
import com.google.firebase // GMS not available
```

**Why it's dangerous**: HarmonyOS NEXT has no Android runtime. UIAbility lifecycle hooks differ fundamentally from Activity. Android code requires complete rewrite, not a port. The compiler may not catch all assumptions — some fail at runtime.

**Correction**: Before writing any code, explicitly map the Android concept to its HarmonyOS Stage Model equivalent.

```typescript
// GOOD — correct Stage Model lifecycle
export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Correct: windowStage.loadContent() replaces setContentView()
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        console.error('Failed to load content:', err.message)
        return
      }
      console.info('Content loaded successfully')
    })
  }
}
```

---

### Direct Object Mutation Breaking Reactivity

**Definition**: `this.myList.push(item)` or `this.myObj.field = value` on `@State` decorated properties expecting UI refresh.

**Manifestations**:
```typescript
@Component
struct OrderList {
  @State orders: Order[] = []

  build() {
    Button('Add').onClick(() => {
      // Direct push does NOT notify ArkUI of change
      this.orders.push(new Order('item-123'))
    })
    List() {
      ForEach(this.orders, (order: Order) => {
        ListItem() { Text(order.id) }
      })
    }
  }
}
```

**Why it's dangerous**: ArkUI's reactivity system tracks changes via assignment on `@State` references. Mutating contents without replacing the reference is invisible to the framework. The UI does not update despite data changing.

**Correction**: Replace the reference. For nested object mutation, use `@Observed` + `@ObjectLink`.

```typescript
@Component
struct OrderList {
  @State orders: Order[] = []

  build() {
    Button('Add').onClick(() => {
      // Replace reference → ArkUI detects @State change → re-render
      this.orders = [...this.orders, new Order('item-123')]
    })
    List() {
      ForEach(this.orders, (order: Order) => {
        ListItem() { Text(order.id) }
      }, (order: Order) => order.id) // keyGenerator for stable diffing
    }
  }
}
```

---

### Distributed Without Trust Gate Check

**Definition**: Calling `kvStore.put()` or `continuationManager.register()` without checking `deviceManager.getTrustedDeviceListSync()` first.

**Manifestations**:
```typescript
// BAD — assumes distributed capability is always available
async function saveNote(note: Note): Promise<void> {
  const kvStore = await distributedData.createKVManager(config)
    .getKVStore<distributedData.SingleKVStore>('notes-store', options)
  await kvStore.put(note.id, JSON.stringify(note))
  // If distributed sync fails, user silently loses data
}
```

**Why it's dangerous**: Distributed APIs require trusted device pairing and network adjacency. Calling them on an isolated device throws `BusinessError` and silently fails without proper handling.

**Correction**: Always check trusted device availability. Implement single-device path first.

```typescript
// GOOD — single-device path first, distributed as enhancement
async function saveNote(note: Note): Promise<void> {
  // 1. Always save locally first (guaranteed to work)
  const preference = await preferences.getPreferences(context, 'local-notes')
  await preference.put(note.id, JSON.stringify(note))
  await preference.flush()

  // 2. Attempt distributed sync only if trusted device is available
  const devices = deviceManager.getTrustedDeviceListSync()
  if (devices.length > 0) {
    try {
      const kvManager = distributedData.createKVManager(config)
      const kvStore = await kvManager.getKVStore<distributedData.SingleKVStore>(
        'notes-store', { kvStoreType: distributedData.KVStoreType.SINGLE_VERSION }
      )
      await kvStore.put(note.id, JSON.stringify(note))
    } catch (e) {
      // Distributed sync failure is non-fatal — local save already done
      console.warn('Distributed sync skipped: ' + (e as BusinessError).code)
    }
  }
}
```

---

### GMS Dependency in HarmonyOS NEXT Code

**Definition**: Adding `com.google.firebase:firebase-messaging` or `com.google.android.gms` to the project, or writing code that calls FCM APIs.

**Manifestations**:
```typescript
// BAD — Firebase dependency
import { FirebaseMessaging } from '@google/firebase' // Does not exist

// BAD — Google Sign-In
import { GoogleSignin } from '@react-native-google-signin/google-signin' // Does not exist
```

**Why it's dangerous**: HarmonyOS NEXT has no Google Mobile Services. These dependencies will not resolve. Firebase does not exist on this platform. Build fails at `ohpm install` or `hvigorw` stage.

**Correction**: Replace every GMS dependency with its HMS Core equivalent.

| GMS Service | HMS Core Replacement |
|------------|---------------------|
| FCM (Firebase Cloud Messaging) | HMS Push Kit |
| Google Sign-In | HMS Account Kit |
| Google Maps | HMS Map Kit |
| Google Pay | HMS Pay Kit (IAP) |
| Firebase Analytics | HMS Analytics Kit |
| Google Location Services | HMS Location Kit |

---

### Atomic Service Size Creep

**Definition**: Adding full-featured libraries (charting libraries, large image processing SDKs) to an atomic service module without tracking bundle size.

**Manifestations**:
```typescript
// Adding a 1.2MB charting library to a 9MB atomic service
// Total: 10.2MB → AppGallery upload fails
```

**Why it's dangerous**: Atomic services have a hard 10 MB initial package limit. Exceeding it blocks AppGallery submission at upload time — wasting submission quota and delaying release.

**Correction**: Run `hvigorw assembleHap --analyze-size` after every significant dependency addition. Set an 8 MB soft limit. Use HAR splitting to defer non-critical code to on-demand packages.

```bash
# Size monitoring
hvigorw assembleHap --analyze-size

# Output analysis:
# - Identify largest contributors
# - Move non-core libraries to on-demand HAR
# - Compress images, remove unused resources
```

---

### FA Model Feature Addition

**Definition**: Adding new features using FA (Feature Ability) Model APIs in a project that should use Stage Model. FA Model is deprecated for new development.

**Manifestations**:
```typescript
// BAD — using FA Model APIs
import featureAbility from '@ohos.ability.featureAbility'

featureAbility.startAbility({
  want: {
    bundleName: 'com.example.app',
    abilityName: 'com.example.app.MainAbility'
  }
})
```

**Why it's dangerous**: FA Model is deprecated. New apps using FA Model may be rejected from AppGallery. Stage Model provides better lifecycle management, multi-window support, and distributed capabilities.

**Correction**: Use Stage Model exclusively. UIAbility, ExtensionAbility, AbilityStage.

```typescript
// GOOD — Stage Model
import UIAbility from '@ohos.app.ability.UIAbility'

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index')
  }
}
```

---

### AbilityStage Init Missing

**Definition**: Initializing HMS Core kits or global services in `UIAbility.onCreate()` instead of `AbilityStage.onCreate()`.

**Manifestations**:
```typescript
// BAD — HMS init in UIAbility (too late, potential race condition)
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AGConnectInstance.getInstance() // UIAbility context may not be ready
    pushService.getToken() // May fail silently
  }
}
```

**Why it's dangerous**: `UIAbility.onCreate()` runs per-ability instance. If multiple abilities exist, initialization runs multiple times. Race conditions occur when UI code calls Kit APIs before initialization completes.

**Correction**: HMS initialization belongs in `AbilityStage.onCreate()` — the true app-level entry point.

```typescript
// GOOD — app-global init in AbilityStage
export default class AppAbilityStage extends AbilityStage {
  onCreate(): void {
    AGConnectInstance.getInstance(this.context)
    pushService.getToken(this.context).then((token: string) => {
      console.info('Push token obtained')
    }).catch((err: BusinessError) => {
      console.error('Push token failed: ' + err.code)
    })
  }
}
```
