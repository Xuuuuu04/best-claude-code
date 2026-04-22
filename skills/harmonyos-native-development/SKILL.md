---
name: harmonyos-native-development
description: HarmonyOS NEXT native development methodology for the Harness team. Covers ArkTS strict-mode language, decorator-driven state ownership graph (@State/@Prop/@Link/@Provide/@Consume/@Observed), Stage Model architecture (UIAbility/ExtensionAbility/AbilityStage), HMS Core kit integration, distributed capabilities with trust-gate pattern, atomic service size discipline, and AppGallery Connect submission compliance. Loaded by @harmonyos-dev via skills: frontmatter.
type: skill
---

# HarmonyOS Native Development Skill

## 1. ArkTS Language and State System

**Decorator ownership hierarchy** (draw before writing any component tree):
- `@State` — owner of value-type state, local to the component
- `@Prop` — one-way child read-only copy
- `@Link` — two-way child reference
- `@Provide`/`@Consume` — cross-hierarchy state sharing
- `@Observed`/`@ObjectLink` — nested object reactivity
- `@ObservedV2`/`@Trace` — fine-grained property tracking (API 12+)

**State mutation rule**: Direct mutation of `@State` object/array does NOT trigger re-render. Must replace the reference: `this.orders = [...this.orders, item]`. For nested objects, use `@Observed` + `@ObjectLink`.

**ArkTS strict mode**: No `any` type, no dynamic property access, no `eval()`, no reflection. These are compliance issues, not style preferences.

**Storage**: `AppStorage` (app-level reactive), `LocalStorage` (page-level), `PersistentStorage` (disk-backed), `Preferences` (key-value local).

**Concurrency**: `taskpool` (message-based concurrent tasks, NOT coroutines), `Worker` (persistent background thread), `async`/`await`, NAPI for C++ async ops.

## 2. Stage Model Architecture

**Lifecycle funnel**: `AbilityStage.onCreate()` → `UIAbility.onCreate()` → `onWindowStageCreate()` → UI rendering.

**UIAbility**: `onCreate`, `onWindowStageCreate`, `onForeground`, `onBackground`, `onDestroy`. Launch modes: `singleton` (default), `multiton`, `specified`.

**AbilityStage**: App-level init hook. HMS Kit initialization MUST happen here, NOT in `UIAbility.onCreate()`. Initializing in `UIAbility` risks race conditions.

**ExtensionAbility types**: `FormExtensionAbility` (cards), `ServiceExtensionAbility` (background), `ShareExtensionAbility` (share sheet), `InputMethodExtensionAbility` (IME).

**Module types**: HAP (deployable unit), HSP (runtime-shared library), HAR (compile-time static library).

## 3. HMS Core Integration

**Integration flow**: Enable in AppGallery Connect → download `agconnect-services.json` to `entry/` → add `@hw-agconnect/[kit]` to `oh-package.json5` → initialize `AGConnectInstance` in `AbilityStage.onCreate()` → implement Kit API with error handling.

**Kit replacements** (no GMS on HarmonyOS NEXT):
| GMS | HMS Core |
|-----|----------|
| FCM | Push Kit |
| Google Sign-In | Account Kit |
| Google Maps | Map Kit |
| Google Pay | Pay Kit (IAP) |

**Pay Kit**: In-app purchases MUST use HMS IAP per AppGallery policy. Flow: `createPurchaseIntent()` → Activity result → server-side `verifyPurchase()` → `consumePurchase()` for consumables.

## 4. Distributed Capabilities

**Trust gate**: Distributed APIs operate only between paired, trusted devices on the same network. Requires:
1. `ohos.permission.DISTRIBUTED_DATASYNC` declared in `module.json5`
2. Device paired via `deviceManager`
3. Network adjacency

**Implementation order**: single-device path FIRST, distributed enhancement layered on top. Every distributed call is potentially unavailable.

**Task continuation**: `continuationManager.register()` → device picker → `onContinue()` serialization → `onCreate()` deserialization on target device.

**KVStore sync**: PULL / PUSH / PUSH_PULL modes; conflict resolution policy; network-conditional sync.

## 5. Atomic Service Discipline

- 10 MB initial package hard limit (submission blocker)
- Team soft limit: 8 MB
- Monitor with `hvigorw assembleHap --analyze-size`
- Use `LazyForEach` + `@Reusable` for list rendering
- `FormExtensionAbility` for service cards
- `AppLinking` for deep links without install

## 6. AppGallery Compliance

- In-app purchases: HMS IAP mandatory
- Privacy manifest (隐私声明) required
- ICP 备案 required for mainland China services
- Signing certificate from AppGallery Connect (not self-signed)
- Phased rollout (灰度发布) and A/B testing available

## 7. Anti-Patterns

| Name | Symptom | Correction |
|------|---------|------------|
| **Android Mental Model Drift** | Treating UIAbility like Activity, KVStore like SharedPreferences | Name assumption explicitly; map to HarmonyOS equivalent |
| **Direct Object Mutation** | `this.list.push(item)` on `@State` expecting re-render | Replace reference: `this.list = [...this.list, item]` |
| **Distributed Without Trust Gate** | Calling distributed APIs without device availability check | Check `deviceManager.getTrustedDeviceListSync()` first |
| **GMS Dependency** | Adding Firebase/Google SDK to project | Replace with HMS Core equivalent |
| **Atomic Service Size Creep** | Adding libraries without tracking bundle size | Run size analysis after every significant dependency addition |
| **AbilityStage Init Missing** | HMS Kit initialization in `UIAbility.onCreate()` | Move to `AbilityStage.onCreate()` |

## 8. Self-Check Checklist

- [ ] Every system API `@since` confirmed within target `minAPIVersion`
- [ ] No deprecated FA Model APIs in Stage Model project
- [ ] ArkTS strict mode: no `any`, no dynamic property access, no `eval()`
- [ ] All `ohos.permission.*` declared in `module.json5`
- [ ] Runtime permissions have user-facing rationale
- [ ] `agconnect-services.json` present in `entry/`
- [ ] AGConnect initialized in `AbilityStage.onCreate()`
- [ ] No GMS/Google SDK dependencies
- [ ] `@State` mutations use reference replacement
- [ ] Distributed calls have single-device fallback
- [ ] Atomic service size < 10 MB (if applicable)
- [ ] Privacy manifest and 备案 status confirmed
