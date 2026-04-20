# Android Domain — Kotlin Best Practices and Gradle Engineering

## 1. Kotlin Language Discipline

### 1.1 Null Safety and Elvis Operator

```kotlin
// BAD — platform types from Java interop without null check
val name: String = javaObject.getName()  // may crash at runtime

// GOOD — explicit null handling
val name: String = javaObject.getName() ?: "Unknown"
val nameOrNull: String? = javaObject.getName()

// BAD — !! in production paths
val length = user.name!!.length  // EXC_BAD_ACCESS equivalent on Android

// GOOD — safe call with fallback
val length = user.name?.length ?: 0
```

### 1.2 Sealed Classes for State Modeling

```kotlin
sealed interface Result<out T> {
    data class Success<T>(val data: T) : Result<T>
    data class Error(val code: Int, val message: String) : Result<Nothing>
    data object Loading : Result<Nothing>
}

// Exhaustive when — compiler enforces all branches
fun handle(result: Result<User>) = when (result) {
    is Result.Success -> displayUser(result.data)
    is Result.Error -> showError(result.message)
    Result.Loading -> showLoading()
}
```

### 1.3 Extension Functions for Domain Expressiveness

```kotlin
// BAD — utility class with static methods
object StringUtils {
    fun isValidEmail(email: String): Boolean = ...
}

// GOOD — extension function
fun String.isValidEmail(): Boolean =
    Patterns.EMAIL_ADDRESS.matcher(this).matches()

// Usage
if (input.isValidEmail()) { ... }
```

### 1.4 Data Class Immutability

```kotlin
// BAD — mutable data class (unstable in Compose)
data class User(var name: String, var age: Int)

// GOOD — immutable with copy()
data class User(val name: String, val age: Int)

// Update: creates new instance
val updated = user.copy(age = user.age + 1)
```

---

## 2. Gradle Kotlin DSL and Version Catalog

### 2.1 libs.versions.toml Structure

```toml
[versions]
kotlin = "1.9.23"
compose-bom = "2024.04.00"
hilt = "2.51"
room = "2.6.1"

[libraries]
androidx-core-ktx = { group = "androidx.core", name = "core-ktx", version = "1.13.0" }
compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "compose-bom" }
compose-ui = { group = "androidx.compose.ui", name = "ui" }
compose-material3 = { group = "androidx.compose.material3", name = "material3" }
hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
hilt-compiler = { group = "com.google.dagger", name = "hilt-compiler", version.ref = "hilt" }
room-runtime = { group = "androidx.room", name = "room-runtime", version.ref = "room" }
room-compiler = { group = "androidx.room", name = "room-compiler", version.ref = "room" }

[bundles]
compose = ["compose-ui", "compose-material3", "compose-ui-tooling-preview"]

[plugins]
android-application = { id = "com.android.application", version = "8.3.2" }
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
```

### 2.2 Module-Level build.gradle.kts

```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.hilt)
    alias(libs.plugins.kotlin.serialization)
    id("kotlin-kapt")
}

android {
    namespace = "com.example.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.12"
    }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(platform(libs.compose.bom))
    implementation(libs.bundles.compose)
    implementation(libs.hilt.android)
    kapt(libs.hilt.compiler)
    implementation(libs.room.runtime)
    kapt(libs.room.compiler)
}
```

### 2.3 Signing Configuration (local.properties + BuildConfig)

```kotlin
// local.properties (gitignored)
STORE_FILE=/path/to/release.keystore
STORE_PASSWORD=********
KEY_ALIAS=release
KEY_PASSWORD=********

// build.gradle.kts
val localProperties = Properties().apply {
    load(rootProject.file("local.properties").inputStream())
}

android {
    signingConfigs {
        create("release") {
            storeFile = file(localProperties.getProperty("STORE_FILE"))
            storePassword = localProperties.getProperty("STORE_PASSWORD")
            keyAlias = localProperties.getProperty("KEY_ALIAS")
            keyPassword = localProperties.getProperty("KEY_PASSWORD")
        }
    }
}
```

---

## 3. AndroidManifest.xml Essentials

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Normal permissions — no runtime request needed -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Dangerous permissions — runtime request required -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- Feature declarations -->
    <uses-feature android:name="android.hardware.camera" android:required="false" />

    <application
        android:name=".MyApplication"
        android:allowBackup="false"
        android:dataExtractionRules="@xml/data_extraction_rules"
        android:fullBackupContent="false"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.MyApp"
        tools:targetApi="34">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.MyApp">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- FCM service -->
        <service
            android:name=".push.FcmMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

        <!-- FileProvider for sharing -->
        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>
    </application>
</manifest>
```

---

## 4. NDK Basics

### 4.1 CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.22.1)
project("myapp")

add_library(
    native-lib
    SHARED
    src/main/cpp/native-lib.cpp
)

find_library(
    log-lib
    log
)

target_link_libraries(
    native-lib
    ${log-lib}
)
```

### 4.2 JNI Bridge Kotlin + C++

```kotlin
// Kotlin side
class NativeBridge {
    companion object {
        init {
            System.loadLibrary("native-lib")
        }
    }

    external fun processImage(bitmap: Bitmap): ByteArray
    external fun verifySignature(data: ByteArray, signature: ByteArray): Boolean
}
```

```cpp
// C++ side — extern "C" prevents name mangling
#include <jni.h>
#include <android/log.h>

#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, "Native", __VA_ARGS__)

extern "C" JNIEXPORT jbyteArray JNICALL
Java_com_example_app_NativeBridge_processImage(
    JNIEnv* env,
    jobject thiz,
    jobject bitmap
) {
    // Process bitmap...
    LOGI("Processing image in native code");
    return result;
}
```

### 4.3 NDK R8 Keep Rules

```proguard
# JNI native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Native bridge class
-keep class com.example.app.NativeBridge {
    *;
}
```

---

## 5. Project Structure Convention

```
app/
├── build.gradle.kts
├── proguard-rules.pro
└── src/
    ├── main/
    │   ├── AndroidManifest.xml
    │   ├── java/com/example/app/
    │   │   ├── MainActivity.kt
    │   │   ├── MyApplication.kt
    │   │   ├── di/
    │   │   │   └── AppModule.kt
    │   │   ├── ui/
    │   │   │   ├── theme/
    │   │   │   │   ├── Color.kt
    │   │   │   │   ├── Theme.kt
    │   │   │   │   └── Type.kt
    │   │   │   └── components/
    │   │   ├── domain/
    │   │   │   ├── model/
    │   │   │   ├── repository/
    │   │   │   └── usecase/
    │   │   ├── data/
    │   │   │   ├── local/
    │   │   │   │   ├── dao/
    │   │   │   │   ├── entity/
    │   │   │   │   └── database/
    │   │   │   ├── remote/
    │   │   │   │   ├── api/
    │   │   │   │   └── dto/
    │   │   │   └── repository/
    │   │   └── presentation/
    │   │       ├── viewmodel/
    │   │       └── screen/
    │   ├── cpp/
    │   │   └── native-lib.cpp
    │   └── res/
    │       ├── values/
    │       ├── drawable/
    │       └── xml/
    └── test/
        └── java/
```
