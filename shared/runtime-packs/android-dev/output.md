# Android 开发师 — Output Contract Template

## Android Implementation Output

**Task**: [Task ID] — [one-sentence description]
**Status**: READY-FOR-NEXT | BLOCKED | FAILED

**Changed Files**:
- `[file path]`: [what changed — new file / modified / deleted]

**Gradle Impact**:
- New dependencies: [dependency notation + version + reason]
- Build variants affected: [debug / release / flavor]
- minSdk / targetSdk change: [from X to Y — reason]

**Manifest Impact**:
- New permissions: [permission name + protection level (normal/dangerous) + runtime request required?]
- New components: [Activity / Service / Receiver / Provider]
- New intent filters: [action + category]

**ProGuard / R8 Rules Added**:
```proguard
# [Rule text]
# Reason: [why this rule is needed — reflection / JNI / serialization]
```

---

**Lifecycle Safety Self-Check**:
- ViewModel holds Activity/Fragment ref: [NONE detected / FIXED — see below]
- All coroutines in viewModelScope/lifecycleScope: [PASS]
- Fragment observers use viewLifecycleOwner: [PASS / N/A]
- Main-thread I/O: [NONE — all DB/network on Dispatchers.IO]

**Security Self-Check**:
- Secrets storage: [PASS — EncryptedSharedPreferences / Keystore / N/A]
- No hardcoded credentials: [PASS — all via BuildConfig fields from local.properties]
- Dangerous permissions have runtime request: [PASS / N/A — list: CAMERA, LOCATION, etc.]
- R8 keep rules verified with release build: [PASS — `./gradlew bundleRelease` tested]
- allowBackup policy: [PASS — `android:allowBackup="false"` / BackupRules.xml / N/A]

**Push Coverage** (if in scope):
- FCM: [INTEGRATED / N/A]
- HMS Push (华为): [INTEGRATED / N/A]
- MiPush (小米): [INTEGRATED / N/A]
- OPPO Push: [INTEGRATED / N/A]
- vivo Push: [INTEGRATED / N/A]

**Known Limitations / Discovered Issues**:
- [spec assumption flagged — e.g., "scheme does not specify error state for network timeout"]
- [out-of-scope issue discovered — logged as future task, not touched]

**Recommended Next Step**: @code-review — [one-sentence review focus]

---

## Filled Example — T-055 Order Checkout Screen

```
## Android Implementation Output

**Task**: T-055 — Order checkout screen with payment integration
**Status**: READY-FOR-NEXT

**Changed Files**:
- `feature/checkout/src/main/java/com/example/checkout/CheckoutScreen.kt`: New Composable — checkout UI with form validation
- `feature/checkout/src/main/java/com/example/checkout/CheckoutViewModel.kt`: New HiltViewModel — state management + payment flow
- `feature/checkout/src/main/java/com/example/checkout/CheckoutRepository.kt`: New repository — order creation + status polling
- `feature/checkout/src/main/java/com/example/checkout/di/CheckoutModule.kt`: New Hilt module
- `feature/checkout/src/main/res/values/strings.xml`: Added checkout-related strings

**Gradle Impact**:
- New dependencies:
  - `androidx.lifecycle:lifecycle-runtime-compose:2.8.0` (collectAsStateWithLifecycle)
  - `io.coil-kt:coil-compose:2.6.0` (product image loading)
- minSdk: unchanged (24)
- targetSdk: unchanged (34)

**Manifest Impact**:
- No new permissions (payment uses backend-signed params, no sensitive permissions)
- No new components

**ProGuard / R8 Rules Added**: NONE
- Using Kotlin Serialization (no reflection), no new JNI, no custom views

**Lifecycle Safety Self-Check**:
- ViewModel holds Activity/Fragment ref: NONE detected
- All coroutines in viewModelScope: PASS
- Fragment observers use viewLifecycleOwner: N/A (Compose-only screen)
- Main-thread I/O: NONE — all network/DB on Dispatchers.IO

**Security Self-Check**:
- Secrets storage: PASS — auth token in EncryptedSharedPreferences (existing)
- No hardcoded credentials: PASS
- Dangerous permissions: N/A
- R8 keep rules verified: PASS — bundleRelease tested, no crashes
- allowBackup: PASS — false (existing app policy)

**Push Coverage**: N/A — not a push-triggered feature

**Known Limitations**:
- Scheme does not specify timeout for payment status polling — implemented 30s max with 2s interval
- Order retry logic not specified — implemented single retry with exponential backoff

**Recommended Next Step**: @code-review — review CheckoutViewModel coroutine lifecycle, StateFlow state transitions, and polling cancellation in onCleared()
```

---

## BLOCKED Example — Missing Domestic Push Scheme

```
## Android Implementation Output

**Task**: T-062 — Push notification integration
**Status**: BLOCKED

**Blocked on**: Technical scheme incomplete + missing backend endpoint

**Block reasons**:
1. **Missing vendor SDK specification**: Scheme states "domestic push required" but does not specify which OEM markets are in scope. Required clarification:
   - Huawei HMS Push (com.huawei.hms:push) — required for all Huawei devices
   - Xiaomi MiPush (com.xiaomi.mipush:push-client) — required for MIUI devices
   - OPPO Push + vivo Push — confirm if these markets are in scope

2. **Missing backend token registration endpoint**: Push token must be sent to backend for server-side targeting. No endpoint specified in scheme. @backend must define: POST /devices/{id}/push-token

3. **Missing notification channel specification**: Scheme does not define which notification channels are needed (order updates / messages / promotions) and their importance levels

**What I need to proceed**:
1. @dev-lead to confirm target OEM markets and vendor SDK list
2. @backend to define push token registration endpoint
3. @dev-lead to specify notification channels and importance levels

**Do NOT begin implementing**: FCM-only is not acceptable for domestic market. Do not add vendor SDKs speculatively without confirmed scope.
```
