# 鸿蒙开发师 — Baseline Scenarios

## Scenario 1: Push Notification Opt-In with Account Kit Silent Sign-In (Canonical)

**Input**:
- @dev-lead scheme: "On app first launch, silently sign in the user with Account Kit. If silent sign-in fails, show explicit sign-in. After sign-in, request push notification permission and register the push token with our backend. Target: API 11, phone, Stage Model. HMS Push Kit and Account Kit are enabled in AppGallery Connect."

**Expected Output Structure**:
- Context lock-in: API 11, HarmonyOS 4.2, phone, Stage Model confirmed
- HMS Kit inventory: Push Kit + Account Kit → both enabled in AppGallery Connect → agconnect-services.json downloaded and placed in entry/
- Permission declaration before code: `ohos.permission.INTERNET` (install-time) + `ohos.permission.GET_BUNDLE_INFO` (install-time, required by HMS Auth) in module.json5
- oh-package.json5: add `@hw-agconnect/push: ^1.4.0` + `@hw-agconnect/auth: ^1.4.0`

- Layered implementation (strict order):
  1. AppAbilityStage.ets: `AGConnectInstance.getInstance(this.context)` + `pushService.getToken()` in `AbilityStage.onCreate()`
  2. EntryAbility.ets: first-launch detection in `onWindowStageCreate()` → trigger sign-in flow
  3. OnboardingPage.ets: silent sign-in attempt → on success, proceed to token registration; on failure, show explicit sign-in button

- Account Kit silent sign-in pattern:
  ```typescript
  // In EntryAbility.onWindowStageCreate
  const authParam = new account.AuthParam()
  account.HuaweiIdAuthManager.getService(authParam).getAuthResult()
    .then((result) => {
      if (result.isTokenValid()) {
        // Silent sign-in succeeded
        registerPushToken(result.accessToken)
      } else {
        // Token expired — show explicit sign-in
        showExplicitSignIn()
      }
    })
    .catch(() => showExplicitSignIn())
  ```

- Push token registration: `HmsInstanceId.getToken(context, appId, 'HCM')` → POST to own backend with token

- Deliverable:
  - `ets/entryability/AppAbilityStage.ets` — AGConnect init + push token registration
  - `ets/entryability/EntryAbility.ets` — first-launch detection
  - `ets/pages/OnboardingPage.ets` — notification permission rationale UI
  - `entry/module.json5` — permission declarations
  - `entry/oh-package.json5` — new dependencies
  - Test file: `ets/test/OnboardingTest.ets` (hypium, 3 cases)

- Next steps: backend (Push Kit server-side token registration endpoint) + security-auditor (Account Kit token storage review)

**Key Decision Points**:
- HMS initialization is in `AbilityStage.onCreate()`, NOT in `UIAbility.onCreate()` — this is the Stage Model Initialization Funnel
- Silent sign-in always attempted first, explicit sign-in is the fallback — not the default
- Push token registration triggered after authentication succeeds — token is meaningless without user identity
- No GMS/Firebase dependencies present — HMS Core is the mandatory replacement
- Emulator limitation noted: HMS Pay sandbox and distributed APIs not testable on emulator

---

## Scenario 2: BLOCKED — Android Code Port and GMS Dependency

**Input**:
- @dev-lead: "Port the Android push notification module to HarmonyOS. The Android code uses Firebase Cloud Messaging (FCM). Also, we're using `com.google.android.gms:play-services-maps` for the map feature. Just port it over."

**Expected Output Structure**:

**BLOCKED — three separate issues require resolution before any implementation:**

**Block 1 — "Port" assumption is incorrect:**
"HarmonyOS NEXT is not Android. ArkTS is not Kotlin/Java. There is no Android runtime on HarmonyOS NEXT — no AOSP, no APK, no JVM. Android code cannot be 'ported' — it must be rewritten from scratch in ArkTS using HarmonyOS Stage Model APIs. Before proceeding, I need confirmation from @dev-lead that a full rewrite (not a port) is authorized for this scope."

**Block 2 — FCM does not exist on HarmonyOS NEXT:**
"Firebase Cloud Messaging (FCM) is a Google service that runs on Google Mobile Services (GMS). HarmonyOS NEXT has no GMS layer — Firebase is completely unavailable. The replacement is HMS Push Kit, which is entirely different in API, initialization sequence, and server-side integration:
- Android FCM: `FirebaseMessaging.getInstance().getToken()` + Firebase server API
- HarmonyOS HMS Push: `HmsInstanceId.getToken(context, appId, 'HCM')` + HMS Push API v3 (different server endpoint, different payload format, requires AGConnect project setup)
The backend push sending integration will need to be updated by @backend to call HMS Push API v3 instead of FCM."

**Block 3 — `play-services-maps` does not exist on HarmonyOS NEXT:**
"Google Maps SDK (`play-services-maps`) is not available on HarmonyOS NEXT. The replacement is HMS Map Kit. This requires:
1. HMS Map Kit enabled in AppGallery Connect console
2. `oh-package.json5`: `@hw-agconnect/map: ^6.11.0`
3. API surface differs: `MapComponent` in ArkUI instead of `MapView`, POI search API differs, geocoding differs
This is not a dependency swap — it requires UI component changes and API call changes."

**Status**: BLOCKED on three items
**Unblock conditions**:
1. @dev-lead confirms full rewrite (not port) is authorized and provides scope
2. @backend confirms they will update the push sending server to use HMS Push API v3
3. @dev-lead confirms HMS Map Kit as the replacement (or defers map feature to a separate task)

**Key Decision Points**:
- Three distinct block conditions identified separately
- Block 1 is a scope/expectation issue — routes to @dev-lead for rewrite authorization
- Block 2 has a downstream impact on @backend (server-side push integration) — explicitly called out
- Block 3 is a UI component rewrite — not a library swap
- No speculative "here's what the ArkTS version might look like" code provided while blocked

---

## Scenario 3: Atomic Service Size Over Budget + Distributed Note Sync

**Input**:
- @dev-lead: "Implement the notes atomic service feature. Notes sync across the user's Huawei devices. We added a rich text editor library (800 KB) and a charting library (1.2 MB) for note analytics. AppGallery upload failed: 'package exceeds 10 MB limit.' Current size is 12.4 MB."

**Expected Output Structure**:

**Part A — Size Over Budget (Blocking Issue)**

1. Run `hvigorw assembleHap --analyze-size` → identify largest contributors

2. Diagnosis: likely root causes at 12.4 MB:
   - Rich text editor: 800 KB (potentially replaceable or deferrable)
   - Charting library: 1.2 MB (analytics is non-core to the atomic service value)
   - Compiled ABC bytecode for all features: possibly includes non-core features

3. Remediation options:
   - Option A (Preferred): Move charting library to on-demand HAR package — atomic service initial package excludes it until user navigates to analytics view. Save: ~1.2 MB
   - Option B: Replace rich text editor with a miniprogram-compatible lightweight implementation. Save: ~600 KB
   - Both options combined: 12.4 MB → ~10.6 MB → still over. Need to also audit all images and other resources.

4. Mandatory outcome: total initial package < 10 MB before AppGallery resubmission. Soft target: < 8 MB (2 MB buffer).

**Part B — Distributed Notes Sync**

1. Permissions required: `ohos.permission.DISTRIBUTED_DATASYNC` in module.json5

2. Single-device path FIRST (mandatory):
   - Use `preferences.getPreferences()` to save notes locally
   - This path must work even when no paired device is present

3. Distributed enhancement layer (on top of local):
   - Check `deviceManager.getTrustedDeviceListSync()` before any distributed call
   - Use `distributedData.KVStore` with `SINGLE_VERSION` strategy for note content
   - Implement `onContinue()` for task migration: serialize `{noteId, scrollPosition, editCursor}` in `wantParams`
   - Implement `onNewWant()` on the target device to restore state from `wantParams`

4. Test requirement: emulator CANNOT test distributed sync. Two physical Huawei devices on the same network required.

5. Distributed failure handling:
   - KVStore sync failure → log warning, continue with local data
   - No paired device → skip distributed sync entirely, no error shown to user

**Deliverable for this task** (after size issue is resolved):
- module.json5: add `DISTRIBUTED_DATASYNC` permission
- NoteStorageService.ets: save-local-first + distributed-sync-if-available pattern
- NoteEntryAbility.ets: `onContinue()` implementation
- NoteRestoreAbility.ets: `onNewWant()` implementation
- Test plan: local save test (emulator) + sync test (two physical devices, separate test session)

**Key Decision Points**:
- Size fix is a blocking issue — submission will fail again without it
- HAR splitting is the right pattern for non-core libraries in atomic services (analytics is browseable, not launch-critical)
- Single-device path implemented and tested before distributed layer — distributed is an enhancement, not a requirement
- Two-device test session is flagged separately — cannot be done in emulator, requires physical device lab
