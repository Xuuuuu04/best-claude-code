# Android 开发师 — Baseline Scenarios

## Scenario 1: Order Checkout Screen (Canonical)

**Input**:
- @dev-lead scheme: "Implement order checkout screen. New Composable `CheckoutScreen`. ViewModel: `CheckoutViewModel` with `createOrder()` and `pollOrderStatus()`. State: `CheckoutUiState` sealed class. API: POST /orders, GET /orders/{id}/status. Dispatch: Dispatchers.IO for all network. HiltViewModel. Target: existing module `feature/checkout`."
- Existing project uses: Hilt, Retrofit + Kotlin Serialization, StateFlow, MVVM.

**Expected Output Structure**:
- Read scheme + existing project structure before writing any code
- Implement in strict layer order: domain (data class `Order`, `CheckoutRepository` interface, `CreateOrderUseCase`) → data (`CheckoutRepositoryImpl`, `OrderApi` Retrofit interface) → ViewModel (`@HiltViewModel CheckoutViewModel` with `viewModelScope.launch`, `StateFlow<CheckoutUiState>`) → UI (`CheckoutScreen @Composable` using `collectAsStateWithLifecycle()`)
- `CheckoutUiState` sealed class: `object Loading`, `data class Success(val order: Order)`, `data class Error(val message: String)`
- All network calls in `withContext(Dispatchers.IO)` or `suspend` functions
- `pollOrderStatus()` uses `viewModelScope.launch { delay(2000); repeat() }` pattern — cancelled on ViewModel clear
- Lifecycle safety self-check: PASS — no Activity ref in ViewModel, all coroutines in viewModelScope, collectAsStateWithLifecycle in Composable
- Security self-check: PASS — no new credentials, existing EncryptedSharedPreferences for auth token
- R8 check: PASS — using Kotlin Serialization (no Gson reflection), no new reflection-dependent classes, keep rules not needed for this feature; `./gradlew bundleRelease` runs successfully
- Push coverage: N/A — not push-triggered
- Next step: @code-review — review CheckoutViewModel coroutine lifecycle, StateFlow state transitions, and polling cancellation in `onCleared()`

**Key Decision Points**:
- Domain layer first — `CheckoutRepository` interface is pure Kotlin, no Android framework
- ViewModel uses `StateFlow` not `LiveData` — matching existing project convention (read via Grep before implementing)
- `collectAsStateWithLifecycle()` not `collectAsState()` — lifecycle-aware collection
- Polling coroutine launched in `viewModelScope` — automatically cancelled when ViewModel is cleared
- bundleRelease tested before marking complete — not just assembleDebug

---

## Scenario 2: BLOCKED — Missing Scheme + Domestic Push Required

**Input**:
- User: "implement push notifications for the Chinese domestic market"
- No technical scheme provided, no target module specified, no vendor SDK configuration available in project

**Expected Output Structure**:
- Status: BLOCKED — multiple prerequisites missing before implementation can begin
- "I cannot implement push notifications without a technical scheme. Please have @dev-lead provide:"
  - "1. Target markets: which vendor SDKs are required? (Huawei HMS / Xiaomi MiPush / OPPO / vivo — confirm which OEM markets are in scope)"
  - "2. Architecture: which module does the PushManager abstraction belong to? (`:core:notifications` or equivalent)"
  - "3. Backend integration: what is the push token registration endpoint? (the device token must be sent to the backend — @backend must define this endpoint first)"
  - "4. Notification types: which notification channels are needed? (order updates / messages / promotions — each needs a separate channel with its own importance level)"
- Do NOT begin implementing FCM alone and assume domestic push can be added later
- Do NOT invent a push architecture without the scheme

**Key Decision Points**:
- BLOCK fires before any SDK dependency is added to build.gradle
- All four missing items are specific — each blocks a specific implementation decision
- Correctly identifies backend dependency (push token registration endpoint) that must be ready before the SDK can be fully integrated
- Does not assume FCM-only is acceptable for domestic Chinese market

---

## Scenario 3: Bug Fix — R8 Production Crash (Release-Only)

**Input**:
- @test-func: "POST-DELIVERY BUG: App crashes with `JsonSyntaxException: Expected STRING but was BEGIN_OBJECT` only on production release build. Does not reproduce in debug build. Crash is in `OrderStatusDeserializer`. Device: Huawei P30, Android 10."
- Source: `data class OrderStatus(@SerializedName("status") val status: StatusEnum)` using Gson

**Expected Output Structure**:
- Reproduce: confirm this ONLY happens in release build (R8 enabled) — debug build works
- Root cause: `StatusEnum` is accessed by Gson reflection, and R8 has renamed or stripped the enum constants; release build has no keep rule for `StatusEnum`
- Evaluate scope: configuration fix only (ProGuard keep rule) — no architecture change
- Implement minimum fix: add to `proguard-rules.pro`:
  ```
  -keepnames enum com.example.order.StatusEnum { *; }
  ```
  OR annotate the enum with `@Keep`
- Alternative recommendation: switch from Gson to Kotlin Serialization (`@Serializable enum class StatusEnum`) — Kotlin Serialization generates no reflection-dependent code and is inherently R8-safe; recommend as a follow-up task to @dev-lead
- Verify: `./gradlew bundleRelease` + install release APK on device + trigger the order status response → `JsonSyntaxException` no longer thrown
- Do NOT add `keep class com.example.** { *; }` as a blanket rule — overly broad, defeats R8's size reduction benefits
- Output: bug fix report with: root cause (R8 stripped StatusEnum constants), fix (specific keep rule), verification (release build tested), recommendation (Kotlin Serialization migration for all Gson-using models)
- Next step: @code-review — review keep rule scope (confirm it is narrowly targeted)

**Key Decision Points**:
- Identifies the release-only reproduction as a diagnostic marker — immediately identifies R8 as the likely culprit
- Implements the minimum fix (one ProGuard rule) — does not refactor surrounding code
- Provides alternative recommendation (Kotlin Serialization migration) as a separate future task — not bundled into the bug fix
- Blanket keep rule explicitly rejected — explains why (defeats R8 size reduction)
- bundleRelease tested on physical device before marking fix complete
