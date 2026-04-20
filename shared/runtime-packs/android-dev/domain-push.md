# Android Domain — Vendor Push Unified Architecture

## 1. Unified Push Manager Interface

```kotlin
interface PushManager {
    fun initialize(context: Context)
    fun getToken(callback: (Result<String>) -> Unit)
    fun onMessageReceived(data: Map<String, String>)
    fun onTokenRefresh(token: String)
}
```

## 2. Runtime Vendor Detection

```kotlin
object VendorDetector {
    fun isHmsAvailable(context: Context): Boolean {
        return try {
            val instanceId = com.huawei.hms.aaid.HmsInstanceId.getInstance(context)
            instanceId.id != null
        } catch (e: Exception) {
            false
        }
    }

    fun isMiui(): Boolean {
        return !getSystemProperty("ro.miui.ui.version.name").isNullOrEmpty()
    }

    fun isOppo(): Boolean {
        return !getSystemProperty("ro.build.version.opporom").isNullOrEmpty()
    }

    fun isVivo(): Boolean {
        return !getSystemProperty("ro.vivo.os.version").isNullOrEmpty()
    }

    private fun getSystemProperty(key: String): String? {
        return try {
            Class.forName("android.os.SystemProperties")
                .getMethod("get", String::class.java)
                .invoke(null, key) as? String
        } catch (e: Exception) {
            null
        }
    }
}
```

## 3. Unified Push Manager Implementation

```kotlin
@Singleton
class UnifiedPushManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val tokenRepository: PushTokenRepository
) {
    private val manager: PushManager by lazy {
        when {
            VendorDetector.isHmsAvailable(context) -> HmsPushManager()
            VendorDetector.isMiui() -> MiPushManager()
            VendorDetector.isOppo() -> OppoPushManager()
            VendorDetector.isVivo() -> VivoPushManager()
            else -> FcmPushManager()
        }
    }

    fun initialize() {
        manager.initialize(context)
    }

    fun registerTokenToBackend() {
        manager.getToken { result ->
            result.onSuccess { token ->
                CoroutineScope(Dispatchers.IO).launch {
                    tokenRepository.registerToken(token, getVendorName())
                }
            }
        }
    }

    private fun getVendorName(): String = when (manager) {
        is HmsPushManager -> "hms"
        is MiPushManager -> "mi"
        is OppoPushManager -> "oppo"
        is VivoPushManager -> "vivo"
        else -> "fcm"
    }
}
```

## 4. FCM Implementation

```kotlin
class FcmPushManager : PushManager {
    override fun initialize(context: Context) {
        FirebaseApp.initializeApp(context)
    }

    override fun getToken(callback: (Result<String>) -> Unit) {
        FirebaseMessaging.getInstance().token
            .addOnSuccessListener { callback(Result.success(it)) }
            .addOnFailureListener { callback(Result.failure(it)) }
    }

    override fun onMessageReceived(data: Map<String, String>) {
        // Handle FCM data message
    }

    override fun onTokenRefresh(token: String) {
        // Token refresh handled by FcmMessagingService
    }
}

class FcmMessagingService : FirebaseMessagingService() {
    @Inject lateinit var pushManager: UnifiedPushManager

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        pushManager.registerTokenToBackend()
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        pushManager.onMessageReceived(data)
    }
}
```

## 5. HMS Push Implementation

```kotlin
class HmsPushManager : PushManager {
    override fun initialize(context: Context) {
        // HMS auto-initialized via agconnect-services.json
    }

    override fun getToken(callback: (Result<String>) -> Unit) {
        try {
            val token = HmsInstanceId.getInstance(context)
                .getToken("YOUR_APP_ID", "HCM")
            if (!token.isNullOrEmpty()) {
                callback(Result.success(token))
            } else {
                callback(Result.failure(Exception("HMS token empty")))
            }
        } catch (e: Exception) {
            callback(Result.failure(e))
        }
    }

    override fun onMessageReceived(data: Map<String, String>) {
        // Handle HMS data message
    }

    override fun onTokenRefresh(token: String) {
        // Token refresh handled by HmsMessageService
    }
}
```

## 6. Notification Channels (Android 8+)

```kotlin
class NotificationChannelManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    fun createChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channels = listOf(
                createChannel(
                    CHANNEL_ORDER_UPDATES,
                    "Order Updates",
                    NotificationManager.IMPORTANCE_HIGH
                ),
                createChannel(
                    CHANNEL_MESSAGES,
                    "Messages",
                    NotificationManager.IMPORTANCE_DEFAULT
                ),
                createChannel(
                    CHANNEL_PROMOTIONS,
                    "Promotions",
                    NotificationManager.IMPORTANCE_LOW
                )
            )

            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannels(channels)
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createChannel(
        id: String,
        name: String,
        importance: Int
    ): NotificationChannel {
        return NotificationChannel(id, name, importance).apply {
            description = "Notifications for $name"
            if (importance == NotificationManager.IMPORTANCE_HIGH) {
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
            }
        }
    }

    companion object {
        const val CHANNEL_ORDER_UPDATES = "order_updates"
        const val CHANNEL_MESSAGES = "messages"
        const val CHANNEL_PROMOTIONS = "promotions"
    }
}
```

## 7. Gradle Dependencies for Push

```kotlin
dependencies {
    // FCM
    implementation("com.google.firebase:firebase-messaging:23.4.1")

    // HMS Push
    implementation("com.huawei.hms:push:6.11.0.300")

    // MiPush
    implementation("com.xiaomi.mipush:push-client:6.0.2")

    // OPPO Push
    implementation("com.heytap.msp:push:3.4.0")

    // vivo Push
    implementation("com.vivo.push:push-sdk:3.0.0")
}
```

## 8. Domestic Store Release Checklist

| Store | Package Format | Requirements |
|-------|---------------|-------------|
| Google Play | AAB (Android App Bundle) | targetSdk 33+, privacy policy, content rating |
| 华为应用市场 | APK or AAB | HMS Core integration, 备案号 (if applicable) |
| 小米应用商店 | APK | MIUI optimization guidelines, 隐私政策 |
| OPPO/vivo | APK | Push SDK integration, 应用合规声明 |
| 应用宝 | APK | 腾讯开放平台账号, 软件著作权 |

```kotlin
// Build variant for domestic stores (no GMS)
android {
    flavorDimensions += "market"
    productFlavors {
        create("global") {
            dimension = "market"
            buildConfigField("String", "PUSH_PROVIDER", "\"fcm\"")
        }
        create("domestic") {
            dimension = "market"
            buildConfigField("String", "PUSH_PROVIDER", "\"hms,mi,oppo,vivo\"")
        }
    }
}
```
