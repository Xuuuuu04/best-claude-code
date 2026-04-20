# Android Domain — Security and Keystore

## 1. EncryptedSharedPreferences

```kotlin
@Singleton
class SecureStorage @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val encryptedPrefs = EncryptedSharedPreferences.create(
        context,
        "secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    fun saveToken(token: String) {
        encryptedPrefs.edit()
            .putString(KEY_AUTH_TOKEN, token)
            .apply()
    }

    fun getToken(): String? = encryptedPrefs.getString(KEY_AUTH_TOKEN, null)

    fun clearToken() {
        encryptedPrefs.edit()
            .remove(KEY_AUTH_TOKEN)
            .apply()
    }

    companion object {
        private const val KEY_AUTH_TOKEN = "auth_token"
    }
}
```

## 2. Android Keystore Direct API

```kotlin
class KeystoreManager @Inject constructor() {
    private val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    fun generateKeyPair(alias: String): KeyPair {
        val keyPairGenerator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_RSA,
            "AndroidKeyStore"
        )
        keyPairGenerator.initialize(
            KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_ECB)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_PKCS1)
                .setUserAuthenticationRequired(false)
                .setRandomizedEncryptionRequired(true)
                .build()
        )
        return keyPairGenerator.generateKeyPair()
    }

    fun getPublicKey(alias: String): PublicKey? {
        return keyStore.getCertificate(alias)?.publicKey
    }

    fun getPrivateKey(alias: String): PrivateKey? {
        return keyStore.getKey(alias, null) as? PrivateKey
    }

    fun encrypt(alias: String, plaintext: String): String {
        val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
        cipher.init(Cipher.ENCRYPT_MODE, getPublicKey(alias))
        val encrypted = cipher.doFinal(plaintext.toByteArray())
        return Base64.encodeToString(encrypted, Base64.DEFAULT)
    }

    fun decrypt(alias: String, ciphertext: String): String {
        val cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding")
        cipher.init(Cipher.DECRYPT_MODE, getPrivateKey(alias))
        val decrypted = cipher.doFinal(Base64.decode(ciphertext, Base64.DEFAULT))
        return String(decrypted)
    }
}
```

## 3. Biometric Authentication

```kotlin
@Singleton
class BiometricAuthManager @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val executor = ContextCompat.getMainExecutor(context)

    fun canAuthenticate(): Boolean {
        val biometricManager = BiometricManager.from(context)
        return biometricManager.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_STRONG
        ) == BiometricManager.BIOMETRIC_SUCCESS
    }

    fun authenticate(
        activity: FragmentActivity,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Biometric Authentication")
            .setSubtitle("Confirm your identity")
            .setNegativeButtonText("Cancel")
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .build()

        val biometricPrompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    result: AuthenticationResult
                ) {
                    super.onAuthenticationSucceeded(result)
                    onSuccess()
                }

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    onError(errString.toString())
                }
            }
        )

        biometricPrompt.authenticate(promptInfo)
    }
}
```

## 4. Certificate Pinning

```kotlin
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideOkHttpClient(): OkHttpClient {
        val certificatePinner = CertificatePinner.Builder()
            .add("api.example.com", "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
            .add("api.example.com", "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=")
            .build()

        return OkHttpClient.Builder()
            .certificatePinner(certificatePinner)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .addInterceptor(AuthInterceptor())
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = if (BuildConfig.DEBUG) HttpLoggingInterceptor.Level.BODY
                        else HttpLoggingInterceptor.Level.NONE
            })
            .build()
    }
}
```

## 5. R8 / ProGuard Complete Rules

```proguard
# === Kotlin Serialization (RECOMMENDED — no reflection, inherently R8-safe) ===
# No keep rules needed for @Serializable classes

# === Gson (if still used — migrate to Kotlin Serialization) ===
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory { *; }
-keep class * implements com.google.gson.JsonSerializer { *; }
-keep class * implements com.google.gson.JsonDeserializer { *; }
-keepnames enum com.example.data.model.** { *; }
-keep class com.example.data.model.** { <fields>; }

# === Retrofit ===
-keepattributes Signature
-keepattributes Exceptions
-keep interface com.example.data.api.** { *; }

# === Room ===
-keep class * extends androidx.room.RoomDatabase
-dontwarn androidx.room.paging.**

# === Hilt ===
-keep class dagger.hilt.** { *; }
-keep class * extends dagger.hilt.internal.GeneratedComponent
-keepclassmembers class * {
    @dagger.hilt.android.lifecycle.HiltViewModel <init>(...);
}

# === JNI ===
-keepclasseswithmembernames class * {
    native <methods>;
}

# === Custom Views ===
-keep class * extends android.view.View {
    <init>(android.content.Context);
    <init>(android.content.Context, android.util.AttributeSet);
    <init>(android.content.Context, android.util.AttributeSet, int);
}

# === Parcelable ===
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
```

## 6. Security Self-Check (5 Items)

```
Before recommending @code-review, verify ALL five:

1. No plaintext secrets
   grep -r "getSharedPreferences" src/ | grep -i "token\|key\|password\|secret"
   → Must be empty or reference EncryptedSharedPreferences

2. No hardcoded API keys
   grep -r "\"[A-Za-z0-9_-]\{20,\}\"" src/ --include="*.kt"
   → All keys via BuildConfig fields from local.properties

3. Dangerous permissions have runtime request
   grep -r "android.permission.CAMERA\|ACCESS_FINE_LOCATION" AndroidManifest.xml
   → Each has corresponding ActivityResultLauncher in code

4. R8 keep rules verified
   ./gradlew bundleRelease → install → test on device
   → No ClassNotFoundException, NoSuchMethodError, JsonSyntaxException

5. allowBackup policy
   AndroidManifest.xml: android:allowBackup="false" OR explicit BackupRules.xml
```
