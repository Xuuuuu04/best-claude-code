---
name: crossplatform-mobile-development
description: Cross-platform mobile development methodology for the Harness team. Covers Flutter (Dart 3+, BLoC/Riverpod, MethodChannel/FFI, performance) and React Native (Fabric/TurboModules, Reanimated 3, RTK Query/Zustand). Includes dual-store delivery contract, native bridge contract discipline, CI/CD with Fastlane/Codemagic, and platform divergence management. Loaded by @crossplatform-mobile-dev via skills: frontmatter.
type: skill
---

# Cross-Platform Mobile Development Skill

## 1. Flutter / Dart 3+

### 1.1 Widget Architecture and State Management

**Const constructor discipline**: Every `StatelessWidget` with no mutable props must have `const` constructor; Flutter's widget diff skips rebuilding subtrees rooted at `const` widgets; missing `const` causes entire subtree to rebuild on every parent `setState`; run `flutter analyze` with `prefer_const_constructors` lint.

**BLoC pattern**:
- `Cubit` for simple state (no events, only methods)
- `Bloc` for complex event-driven flows
- `BlocBuilder` for rebuilding on state change
- `BlocListener` for side effects without rebuilding
- `BlocConsumer` combining both
- `HydratedBloc` for state persistence

**Riverpod 2.x**:
- `AsyncNotifierProvider` for async data with loading/error/data states
- `FutureProvider` for one-shot async values
- `ref.watch` triggers rebuild; `ref.read` one-shot read without subscription (use in callbacks)
- `ref.invalidate` for manual cache invalidation

### 1.2 Platform Channels and FFI

**MethodChannel contract discipline**:
- Method name as reverse-DNS string: `com.example.feature/method`
- Arguments as `Map<String, dynamic>` (JSON-serializable only)
- Return values as JSON-serializable primitives
- Error handling via `PlatformException` with `code`, `message`, `details`
- Document every method, argument, return type, and error code before native implementation

**EventChannel**: Delivers `Stream<dynamic>` from native to Dart; use for continuous sensor data, BLE streams, real-time location; cancel `StreamSubscription` in `dispose()`.

**Dart isolates**: `compute(function, argument)` for one-shot background work (JSON decode, image processing); `Isolate.spawn` for long-running; `dart:ffi` for calling C shared libraries directly.

### 1.3 Performance

**Flutter DevTools**: Performance tab for expensive frames (>16ms = jank); widget rebuild tracker; memory tab for leak detection; profile on physical device in profile mode (`flutter run --profile`), NOT debug mode.

**ListView.builder vs Column**: Use `ListView.builder` with `itemCount`/`itemBuilder` for lists that could exceed ~20 items; lazily creates widgets. For grids: `GridView.builder`; for variable-height mixed content: `CustomScrollView` with `SliverList`/`SliverGrid`.

## 2. React Native

### 2.1 New Architecture (Fabric + TurboModules)

**TurboModules via Codegen**: Define native module spec in TypeScript using `TurboModuleRegistry.get<Spec>('ModuleName')`; Codegen generates C++ bridge automatically; iOS implements `RCTTurboModule`, Android implements `TurboModule`.

**Reanimated 3 worklets**: `worklet` functions run on UI thread (not JS thread), enabling 60fps animations without crossing bridge per frame; `useSharedValue`, `useAnimatedStyle`, `withTiming`, `withSpring`, `withSequence`; direct `GestureDetector` integration (v3).

**Hermes engine**: Pre-compiles JS to bytecode at build time, reducing startup; not all npm packages are Hermes-compatible (some use `eval()` or `Function()` constructors); verify before adding.

### 2.2 State Management and Data

**Redux Toolkit with RTK Query**: `createSlice` for sync state; `createApi` for server state with automatic cache invalidation, loading states, refetching; `invalidateTags` for manual cache invalidation after mutations.

**Zustand for client state**: Minimal, no boilerplate; `create<State>((set, get) => ({...}))`; `immer` middleware for immutable updates; `persist` middleware with `react-native-mmkv` storage adapter.

**react-native-mmkv vs AsyncStorage**: MMKV is synchronous, 10-30x faster; backed by C++ MMKV library; use for app state persistence, preferences, auth tokens (encrypted with `MMKV.encryptionKey`).

### 2.3 Bridge and Native Integration

**When to bridge**: Only when required API is native-only (CameraX full pipeline, ARKit, vendor push SDK, device attestation, Bluetooth HID). Do NOT bridge for: HTTP requests, local storage, standard push, navigation, standard animations.

**NativeEventEmitter pattern**: `NativeEventEmitter(NativeModules.ModuleName)` for JS event listener; use for ongoing native events (BLE discovery, NFC detection, hardware sensors); always call `subscription.remove()` on unmount.

## 3. CI/CD and Release

### 3.1 Fastlane for Dual-Store

**iOS lane with match**: `match(type: "appstore")` syncs certificates from git storage; `gym(scheme: "Runner", export_method: "app-store")` builds IPA; `pilot` uploads to TestFlight internal; requires App Store Connect API key for CI.

**Android lane**: `gradle(task: "bundle", build_type: "Release")` builds AAB; `supply(track: "internal")` uploads to Google Play; for domestic store APKs: build per-flavor APKs with `assembleRelease`.

**Secrets management**: Never embed API keys, certificates, or keystore passwords in `Fastfile`; use `ENV["VARIABLE_NAME"]` for all secrets.

### 3.2 Codemagic Configuration

**codemagic.yaml**: `workflows` with `name`, `environment` (xcode version, flutter version, env var groups), `scripts` (ordered build steps), `artifacts` (IPA path, AAB path), `publishing` (App Store Connect, Google Play).

**Code signing**: iOS — upload certificate (.p12) and provisioning profile to Codemagic team settings; Android — upload keystore; verify by installing produced artifact on device.

## 4. Dual-Store Delivery Contract

Every feature must answer for both platforms:

**iOS checklist**:
- Permissions declared in `Info.plist`?
- Deep links configured in Associated Domains entitlement?
- Notification handling configured for APNs?
- Archive builds cleanly with `flutter build ios --release`?
- TestFlight upload lane works?

**Android checklist**:
- Permissions declared in `AndroidManifest.xml`?
- Deep links configured in App Links intent filters?
- Notification channels created for Android 8+ (`NotificationChannel`)?
- GMS availability check implemented for domestic market?
- AAB builds cleanly with `flutter build appbundle`?
- Google Play Internal track upload lane works?

## 5. Bridge Contract Discipline

Bridge contract is a formal cross-language document given to @ios-dev and @android-dev before any native implementation:

```
Bridge Contract: com.example.app/bluetooth

Method: connectToDevice
  Arguments: { "deviceId": String, "timeout_ms": Int }
  Returns: { "connected": Bool, "deviceName": String }
  Errors:
    - "DEVICE_NOT_FOUND": Device ID not in discovered devices list
    - "CONNECTION_TIMEOUT": Connection attempt exceeded timeout_ms
    - "PERMISSION_DENIED": Bluetooth permission not granted

EventChannel: com.example.app/bluetooth/events
  Events:
    - { "type": "deviceDiscovered", "deviceId": String, "name": String, "rssi": Int }
    - { "type": "deviceDisconnected", "deviceId": String, "reason": String }
```

## 6. Anti-Patterns

| Name | Symptom | Correction |
|------|---------|------------|
| **Rebuild Storm** | Unnecessary rebuilds of subtrees that didn't change | Lift state to BLoC/Riverpod; `const` constructors; `ListView.builder`; smallest-scope `BlocBuilder` |
| **Bridge Overuse** | Calling native bridge on per-frame basis (~60 calls/sec) | Use `EventChannel` for streams; Reanimated 3 worklets for animation-coupled logic |
| **Dependency Pinning Miss** | Native dep versions unpinned, causing divergent failures | Pin to exact versions in `pubspec.yaml` / `package.json` |
| **Platform-Divergent Undocumented** | Feature behaves differently on iOS vs Android without docs | Output contract must include "Platform Divergence" section |
| **Single-Store Mindset** | Fastlane/Codemagic for one store, other "later" | Every `Fastfile` must have both iOS and Android lanes |
