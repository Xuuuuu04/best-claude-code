> 源：core.md §Anti-Patterns + §Rules (Primacy Anchor)

# Android 开发师 — Anti-Patterns

## Named Anti-Patterns

---

### Lifecycle Leak

**Definition**: Holding an Activity or Fragment reference in a ViewModel. ViewModel survives configuration changes (screen rotation); Activity does not. The old Activity is retained in memory after destruction, and callbacks fire on a dead context.

**Manifestations**:
```kotlin
// BAD — Activity reference in ViewModel
class OrderViewModel(private val activity: OrderActivity) : ViewModel() {
    fun submitOrder() {
        viewModelScope.launch {
            val result = repository.submit()
            activity.updateUI(result)  // LIFECYCLE LEAK
        }
    }
}
```

```kotlin
// BAD — Fragment reference in ViewModel
class ProfileViewModel(private val fragment: ProfileFragment) : ViewModel() {
    fun loadProfile() {
        viewModelScope.launch {
            val profile = repository.getProfile()
            fragment.displayProfile(profile)  // LIFECYCLE LEAK
        }
    }
}
```

**Why it's dangerous**: After screen rotation, the old Activity is destroyed but still held by ViewModel. A new Activity is created. Now there are two Activity instances in memory. ViewModel calls methods on the dead Activity — causing crashes, memory leaks, and inconsistent UI state. Google Play Console tracks memory leaks via `android:largeHeap` usage trends.

**Correction**: ViewModel exposes `StateFlow`. Activity/Fragment observes. No reference from ViewModel to Activity/Fragment ever.

```kotlin
// GOOD — ViewModel exposes state; UI observes
@HiltViewModel
class OrderViewModel @Inject constructor(
    private val repository: OrderRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow<OrderUiState>(OrderUiState.Loading)
    val uiState: StateFlow<OrderUiState> = _uiState.asStateFlow()

    fun submitOrder() {
        viewModelScope.launch {
            _uiState.value = OrderUiState.Loading
            val result = repository.submit()
            _uiState.value = when (result) {
                is Result.Success -> OrderUiState.Success(result.data)
                is Result.Error -> OrderUiState.Error(result.message)
            }
        }
    }
}

// In Activity/Fragment
@Composable
fun OrderScreen(viewModel: OrderViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    // uiState drives UI — no reference back to ViewModel
}
```

---

### Main-Thread IO

**Definition**: Performing database queries, network calls, file I/O, or heavy computation on `Dispatchers.Main`. The main thread is for UI updates only.

**Manifestations**:
```kotlin
// BAD — Room query on main thread
@Composable
fun UserList() {
    val users by remember { dao.getAllUsers() }.collectAsState(emptyList())
    // If dao.getAllUsers() is not a suspend function with Flow,
    // Room may execute on main thread → ANR
}
```

```kotlin
// BAD — synchronous network call
@MainActor
class ProductViewModel : ViewModel() {
    fun loadProducts() {
        viewModelScope.launch {
            // WRONG: blocking call on main thread
            val response = URL("https://api.example.com/products").readText()
            // ANR after 5 seconds
        }
    }
}
```

```kotlin
// BAD — JSON decoding on main thread without dispatcher switch
viewModelScope.launch {
    val json = api.fetchRawJson()  // network on IO (ok)
    val products = Gson().fromJson(json, Array<Product>::class.java)
    // JSON decode on Main — jank for large payloads
}
```

**Why it's dangerous**: ANR (Application Not Responding) dialogs appear after ~5 seconds of main thread blockage. Google Play tracks ANR rates; elevated ANR rates cause store listing demotion. Even sub-5s blocks cause janky UI — dropped frames visible to users.

**Correction**: All persistence and network in suspend functions using `Dispatchers.IO`. CPU-intensive work on `Dispatchers.Default`. Main thread for UI updates only.

```kotlin
// GOOD — explicit dispatcher discipline
viewModelScope.launch {
    val products = withContext(Dispatchers.IO) {
        repository.fetchProducts()  // network + DB on IO
    }
    _uiState.value = OrderUiState.Success(products)
}

// GOOD — Room returns Flow automatically on IO
@Dao
interface UserDao {
    @Query("SELECT * FROM users")
    fun getAllUsers(): Flow<List<User>>  // Flow emits on IO dispatcher
}
```

---

### SharedPreferences-for-Secrets

**Definition**: Storing JWT tokens, API keys, passwords, or any sensitive credential in `SharedPreferences`. SharedPreferences is a plaintext XML file stored in `/data/data/<package>/shared_prefs/`.

**Manifestations**:
```kotlin
// BAD — plaintext token storage
val prefs = PreferenceManager.getDefaultSharedPreferences(context)
prefs.edit().putString("auth_token", token).apply()

// BAD — plaintext API key
prefs.edit().putString("api_key", "REPLACE_ME").apply()
```

```kotlin
// BAD — even encrypted SharedPreferences without Keystore
val masterKey = MasterKey.Builder(context).build()
// MasterKey without user authentication — still decryptable on rooted device
```

**Why it's dangerous**: SharedPreferences XML is readable via ADB on any device with USB debugging enabled. Backup extraction tools can read it without root. On rooted devices, any app with `READ_EXTERNAL_STORAGE` can access other apps' shared_prefs. This is a disqualifying security defect in any security audit.

**Correction**: Use `EncryptedSharedPreferences` backed by Android Keystore, or the Keystore API directly for high-sensitivity keys.

```kotlin
// GOOD — EncryptedSharedPreferences with Keystore
val masterKey = MasterKey.Builder(context)
    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
    .build()

val encryptedPrefs = EncryptedSharedPreferences.create(
    context,
    "secret_prefs",
    masterKey,
    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)

encryptedPrefs.edit().putString("auth_token", token).apply()
```

```kotlin
// GOOD — Keystore direct for encryption keys (never leaves secure hardware)
val keyGenerator = KeyGenerator.getInstance("AES", "AndroidKeyStore")
keyGenerator.init(
    KeyGenParameterSpec.Builder("my_key_alias", KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
        .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
        .setUserAuthenticationRequired(true)  // biometric required
        .setInvalidatedByBiometricEnrollment(true)
        .build()
)
val secretKey = keyGenerator.generateKey()
```

---

### R8-Strips-Your-Code

**Definition**: Shipping a release build where R8 has renamed or removed classes accessed by reflection, JNI, or serialization frameworks. Debug builds bypass R8 — the crash only appears in release.

**Manifestations**:
```kotlin
// BAD — Gson reflection with no keep rule
enum class OrderStatus { PENDING, PAID, SHIPPED, DELIVERED }
// Gson uses reflection to map "PAID" → OrderStatus.PAID
// R8 renames enum constants in release → JsonSyntaxException
```

```kotlin
// BAD — JNI native method without keep rule
class NativeBridge {
    external fun processImage(bitmap: Bitmap): ByteArray
    // R8 strips the class or renames the method → UnsatisfiedLinkError
}
```

```kotlin
// BAD — Retrofit interface without keep rule
interface UserApi {
    @GET("users/{id}")
    suspend fun getUser(@Path("id") id: String): User
    // R8 strips unused methods → AbstractMethodError at runtime
}
```

**Why it's dangerous**: The crash only happens in release builds. Debug builds work perfectly. Developers often test only debug builds during development. The first time the crash is seen is in production, reported via Google Play Console crash reports. These are the most expensive bugs to fix because they require a new release cycle.

**Correction**: Add specific keep rules for every reflection-accessed, JNI-accessed, and serialized class. Test on release build before marking complete.

```proguard
# GOOD — specific keep rules (not blanket)
# Gson enum
-keepnames enum com.example.order.OrderStatus { *; }

# JNI native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Kotlin Serialization (preferred — no reflection, inherently R8-safe)
# Switch from Gson to @Serializable for new code
@Serializable
enum class OrderStatus { PENDING, PAID, SHIPPED, DELIVERED }
```

```kotlin
// GOOD — @Keep annotation for individual classes
@Keep
class LegacyApiResponse(
    @SerializedName("status") val status: String
)
```

---

### Vendor Push Blindspot

**Definition**: Implementing FCM-only push notifications for a product targeting Chinese domestic users. FCM requires Google Mobile Services (GMS), which is unavailable on most Huawei devices and optional on others in mainland China.

**Manifestations**:
```kotlin
// BAD — FCM only, no vendor abstraction
class MyFirebaseService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        // Only reaches GMS-enabled devices
    }
}
```

**Why it's dangerous**: FCM-only reaches approximately 50% of Chinese Android users. Huawei devices (post-2019) have no GMS. Xiaomi/OPPO/vivo devices may have GMS disabled or use aggressive battery optimization that kills FCM services. Users on non-GMS devices simply never receive push notifications — a silent failure that looks like "push is working" in testing on a Pixel device.

**Correction**: Implement a unified push abstraction with runtime vendor detection.

```kotlin
// GOOD — unified push manager with vendor detection
interface PushManager {
    fun initialize(context: Context)
    fun getToken(): String?
    fun onMessageReceived(data: Map<String, String>)
}

class UnifiedPushManager(context: Context) {
    private val manager: PushManager = when {
        isHmsAvailable(context) -> HmsPushManager()
        isMiui() -> MiPushManager()
        isOppo() -> OppoPushManager()
        isVivo() -> VivoPushManager()
        else -> FcmPushManager()
    }
    // All vendor SDKs initialized; token registered to same backend endpoint
}
```

---

### Compose Recomposition Storm

**Definition**: Causing excessive recompositions in Jetpack Compose by passing unstable objects, creating inline lambdas, or missing `remember`/`key` annotations.

**Manifestations**:
```kotlin
// BAD — inline lambda creates new reference every recomposition
@Composable
fun ProductList(products: List<Product>) {
    Column {
        products.forEach { product ->
            ProductCard(
                product = product,
                onClick = { viewModel.selectProduct(product) }  // NEW lambda every time
            )
        }
    }
}
```

```kotlin
// BAD — unstable data class (var properties)
data class Product(var name: String, var price: Double)  // var = unstable

// BAD — missing @Immutable on stable data class
@Composable
fun ProductCard(product: Product) {  // Compose treats as unstable → always recomposes
```

**Why it's dangerous**: Excessive recompositions cause frame drops (jank), high CPU usage, and battery drain. On low-end devices, this makes the app unusable. The issue is invisible in debug builds (Compose skips recomposition optimization in debug).

**Correction**: Use `remember`, stable types, and `const` where applicable.

```kotlin
// GOOD — remembered lambda + stable types
@Composable
fun ProductList(products: List<Product>, viewModel: ProductViewModel) {
    Column {
        products.forEach { product ->
            val onClick = remember(product.id) {
                { viewModel.selectProduct(product) }
            }
            ProductCard(product = product, onClick = onClick)
        }
    }
}

// GOOD — immutable data class + @Immutable annotation
@Immutable
data class Product(val name: String, val price: Double)  // val = stable
```

---

### Coroutine Scope Escape

**Definition**: Launching coroutines in `GlobalScope` or a custom scope that outlives the component that started them. The coroutine continues running after the user navigates away, potentially causing memory leaks, stale callbacks, or duplicate operations.

**Manifestations**:
```kotlin
// BAD — GlobalScope never cancelled
class PaymentViewModel : ViewModel() {
    fun processPayment() {
        GlobalScope.launch {  // NEVER cancelled
            repository.processPayment()
        }
    }
}
```

```kotlin
// BAD — manual scope not tied to lifecycle
val scope = CoroutineScope(Dispatchers.Main)
// scope is never cancelled when Fragment is destroyed
```

**Why it's dangerous**: GlobalScope coroutines run for the lifetime of the application. If the user navigates away from the payment screen, the payment processing continues, and the callback tries to update a destroyed UI. This causes crashes (`IllegalStateException: Fragment not attached`) and wastes resources.

**Correction**: Always use lifecycle-bound scopes.

```kotlin
// GOOD — viewModelScope auto-cancels on ViewModel clear
@HiltViewModel
class PaymentViewModel @Inject constructor(
    private val repository: PaymentRepository
) : ViewModel() {
    fun processPayment() {
        viewModelScope.launch {
            _uiState.value = PaymentUiState.Processing
            val result = repository.processPayment()
            _uiState.value = result.toUiState()
        }  // Automatically cancelled when ViewModel is cleared
    }
}

// GOOD — lifecycleScope for Fragment/Activity
fragment.lifecycleScope.launch {
    // Cancelled when Fragment lifecycle is destroyed
}

// GOOD — viewLifecycleOwner.lifecycleScope for Fragment views
fragment.viewLifecycleOwner.lifecycleScope.launch {
    // Cancelled when Fragment view is destroyed (survives config change)
}
```
