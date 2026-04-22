---
name: android-native-development
description: Android native development methodology for the Harness team. Covers Jetpack Compose state architecture, ViewModel + UiState pattern, Room/DataStore persistence, Retrofit networking, vendor push notification integration (FCM + HMS + MiPush + OPPO/vivo), R8/ProGuard keep rules, and multi-store release engineering. Loaded by @android-dev via skills: frontmatter.
type: skill
---

# Android Native Development Skill

## 1. Jetpack Compose and State Architecture

**State hoisting discipline**: state lives at the lowest level that owns it, hoisted to where shared; stateless composables take state as parameters and report events via lambdas; `rememberSaveable` persists across configuration changes; `@Stable`/`@Immutable` on state types prevent unnecessary recomposition.

**Side effects in Compose**:
- `LaunchedEffect(key)` — coroutine tied to composition, restarts when key changes, cancelled when leaves
- `DisposableEffect(key)` — cleanup when composition leaves
- `SideEffect` — sync non-Compose state on each successful recomposition
- `rememberCoroutineScope()` — coroutine tied to user actions

**collectAsStateWithLifecycle**: Use instead of `collectAsState()` for Flow/StateFlow in Compose — respects lifecycle and pauses when UI is backgrounded.

**UiState sealed class pattern**:
```kotlin
sealed class UiState<out T> {
    object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String) : UiState<Nothing>()
}
```
ViewModel exposes `val uiState: StateFlow<UiState<FeatureData>>`; exhaustive `when` in Compose.

**viewModelScope discipline**: All coroutines via `viewModelScope.launch { }` — auto-cancelled when ViewModel cleared; never `GlobalScope`; never manual `cancel()` on `viewModelScope`.

## 2. Data and Persistence

**Room thread safety**: All `@Dao` suspend functions run on `Dispatchers.IO`; `@Dao` returning `Flow<T>` auto-emits on `Dispatchers.IO`; migrations required for every schema change; `fallbackToDestructiveMigration()` only in development.

**DataStore vs SharedPreferences**: DataStore is modern replacement; Preferences DataStore for simple key-value, Proto DataStore for typed structured data; writes are transactional and never corrupt on process death.

**Android Keystore**: `KeyPairGenerator` or `KeyGenerator` with `AndroidKeyStoreProvider` for keys that never leave secure hardware; encrypt sensitive data with AES-GCM using Keystore-backed key; `EncryptedSharedPreferences` uses Keystore internally.

**Retrofit and Kotlin Serialization**: `suspend fun` methods returning domain types; `@SerialName` for snake_case → camelCase; Kotlin Serialization preferred over Gson — supports sealed classes natively, generates no reflection-dependent code (safer with R8).

**OkHttp interceptors**: `Interceptor` for auth headers; `HttpLoggingInterceptor` for debug-only (remove in release); `Authenticator` for 401 refresh; `CertificatePinner` for high-security endpoints.

## 3. Push Notification Architecture

**FCM integration**: `FirebaseMessagingService.onMessageReceived` for data messages; distinguish data vs notification messages; register `NotificationChannel` on startup (Android 8+); high-priority for time-sensitive.

**Vendor push unified abstraction**:
```
PushManager interface: initialize(), getToken(), onMessageReceived()
Implementations: FcmPushManager, HmsPushManager, MiPushManager, OppoPushManager, VivoPushManager
Runtime selection: detect HMS via HmsInstanceId, detect MIUI via SystemProperties
```

**Device coverage**:
- GMS available → FCM
- Huawei EMUI/HarmonyOS, no GMS → HMS Push
- MIUI (Xiaomi/Redmi/POCO) → MiPush
- ColorOS (OPPO/OnePlus/Realme) → OPPO Push
- OriginOS/FuntouchOS (vivo) → vivo Push

## 4. ProGuard / R8 Discipline

**Mandatory keep rules**:
- Reflection-accessed: `-keep class com.example.model.** { *; }`
- JNI-accessed: `-keepclasseswithmembernames class * { native <methods>; }`
- Gson serialization: `-keep class * implements java.io.Serializable { *; }`
- Retrofit interfaces: `-keep interface com.example.api.** { *; }`
- Enum names: `-keepnames enum com.example.** { *; }`

**Release build verification**: `./gradlew bundleRelease` then run release variant; common release-only failures: missing keep rules for Gson models, enum names, custom view constructors called by name in XML.

**Mapping file management**: R8 produces `mapping.txt` per release; upload to Google Play Console for deobfuscated crash reports; store alongside release version; never lose mapping file for a released version.

## 5. Security Self-Check (5 Items)

1. **No plaintext secrets**: EncryptedSharedPreferences or Keystore
2. **No hardcoded API keys**: all via BuildConfig fields from local.properties or CI
3. **Dangerous permissions have runtime request flows**: CAMERA, ACCESS_FINE_LOCATION, READ_CONTACTS, etc.
4. **R8 keep rules verified**: release build tested, not just debug
5. **Manifest backup policy**: sensitive apps have `android:allowBackup="false"` or explicit BackupRules.xml

## 6. Anti-Patterns

| Name | Symptom | Correction |
|------|---------|------------|
| **Lifecycle Leak** | ViewModel holds Activity/Fragment reference | ViewModel exposes StateFlow; Activity observes; no ref from VM to Activity |
| **Main-Thread IO** | DB queries, network, heavy compute on main thread | All persistence/network in suspend functions using `Dispatchers.IO` |
| **SharedPreferences-for-Secrets** | Token stored in plaintext SharedPreferences | `EncryptedSharedPreferences.create(...)` or Keystore API |
| **R8-Strips-Your-Code** | Gson fields renamed, JNI methods not found, Retrofit interfaces stripped | Test on release build; add keep rules for all name-accessed classes |
| **Vendor Push Blindspot** | FCM-only for Chinese domestic users | Implement unified abstraction: FCM + HMS + MiPush + OPPO + vivo |
