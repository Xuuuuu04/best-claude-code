# 跨平台移动开发师 — Baseline Scenarios

## Scenario 1: Flutter Feature with Platform Divergence (Canonical)

**Input**:
- Task: T-055 — Add push notification support (in-app banners + background deep links)
- Framework: Flutter 3.22, Dart 3.3, using Riverpod for state management
- Target: iOS 16+ and Android API 33+, domestic Android market (华为/小米/OPPO/vivo) required

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Framework confirmed before any code written
- Platform divergence analysis:
  - iOS: APNs for push, permission requested at app launch, no notification channels
  - Android: FCM for GMS devices + HMS Push + MiPush/OPPO/vivo for domestic; notification channels required for Android 8+; permission requested at OS level for Android 13+
  - `Platform.isIOS` branch for permission request flow; `Platform.isAndroid` for notification channel creation
- Package vet: `firebase_messaging` (last published <3 months, null safety, iOS+Android example) + `huawei_push` HMS package
- No native bridge needed (firebase_messaging covers the FCM layer; HMS uses dedicated package)
- Implementation layers in order: notification service class (pure Dart) → Riverpod notification provider → UI banner widget (const constructor) → platform branches for permission + channel setup
- Rebuild storm self-check: banner widget uses `const` constructor, scoped `ConsumerWidget` for notification state
- Dual-store checklist: Info.plist `NSUserNotificationsUsageDescription` + APNs capability declared; AndroidManifest RECEIVE_BOOT_COMPLETED + POST_NOTIFICATIONS + notification channel created in Application.onCreate()
- Fastlane: iOS lane with APNs push capability in provisioning profile; Android lane with Google Play + per-channel APK for domestic stores
- Next step: @code-review with focus on domestic push SDK integration correctness

**Key Decision Points**:
- FCM alone is not acceptable for domestic market — HMS + MiPush/OPPO/vivo added
- Notification channel creation in Android Application.onCreate() (not Activity.onCreate()) — platform divergence documented
- const constructors on all notification banner widgets confirmed

---

## Scenario 2: BLOCKED — Native Bridge Required, Framework Not Confirmed

**Input**:
- Request: "我需要接入蓝牙 HID 设备，读取健康数据，实时展示到屏幕"
- No framework specified
- No technical scheme document provided

**Expected Output Structure**:
- Status: BLOCKED (two blocking conditions)
- Blocking condition 1: Framework not specified — Flutter or React Native? Must be confirmed before any code is written. MethodChannel vs NativeModule are incompatible. This is the highest-priority disambiguation.
- Blocking condition 2: BLE HID is a native capability — no satisfactory cross-platform package exists for GATT notification streams on both iOS and Android simultaneously. A native bridge is required. Proposed bridge contract designed and presented:
  ```
  EventChannel: com.example/ble_hr
  Events: { "type": "hrReading", "deviceId": String, "bpm": Int, "timestamp": Int }
             { "type": "deviceDiscovered", "deviceId": String, "name": String, "rssi": Int }
             { "type": "connectionLost", "deviceId": String, "reason": String }
  MethodChannel: com.example/ble_hr
  Methods: startScan(): void | stopScan(): void
           connectToDevice({ "deviceId": String }): { "success": Bool }
           Errors: DEVICE_NOT_FOUND | PERMISSION_DENIED | ALREADY_CONNECTED
           disconnect({ "deviceId": String }): void
  ```
- Next steps: (1) user confirms framework; (2) route bridge contract to @ios-dev (CoreBluetooth BLE GATT implementation) and @android-dev (Android BLE GATT implementation); (3) shared Flutter/RN layer implementation begins only after both native sides confirm the contract is implementable

**Key Decision Points**:
- Did NOT write any code without framework confirmation
- Did NOT attempt BLE in pure Dart/JS — designed bridge contract immediately
- Bridge contract is complete (EventChannel + MethodChannel with all method names, arg types, return types, error codes)
- Did NOT route to @ios-dev and @android-dev yet — framework must be confirmed first by user

---

## Scenario 3: React Native Performance Investigation

**Input**:
- Bug report: "产品列表页在中低端 Android 设备上滑动明显卡顿"
- Framework: React Native 0.73, bare workflow, Redux Toolkit state management
- Device: Xiaomi Redmi 9A (Helio G25, 2GB RAM)

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Baseline measurement: launch Flipper → Performance → record scroll on ProductListScreen on device → baseline frame budget: 16ms; measured: 38ms per frame (jank)
- Root cause diagnosis: Flipper profiler shows `ProductCard` re-rendering on every scroll event despite product data not changing; root cause: (1) `renderItem` prop creates new arrow function reference on every FlatList render; (2) `ProductCard` receives `onAddToCart` callback created inline (new reference every render); (3) `ProductCard` not wrapped in `React.memo`
- Minimum fix:
  - Wrap `ProductCard` in `React.memo` with shallow comparison
  - Extract `renderItem` to `useCallback` with `[]` dependency (stable reference)
  - Extract `onAddToCart` to `useCallback` with correct dependencies
  - Verify no object/array literals passed as props to ProductCard
- After fix measurement: 14ms per frame — within 16ms budget, jank resolved
- Before/after numbers documented in delivery
- Next step: @code-review with focus on useCallback/useMemo correctness and memo comparison

**Key Decision Points**:
- Measured BEFORE fixing — did not guess the root cause
- Applied minimum fix (React.memo + useCallback) — did not restructure the component tree
- Measured AFTER fixing to verify the fix actually resolved the jank
- Documented before/after frame budget numbers
