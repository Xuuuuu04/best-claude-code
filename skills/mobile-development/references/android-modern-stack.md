# Android 现代技术栈速查

> **来源 attribution**：本文档内容综合自以下开源 skill 与 Google 官方文档：
> - [android/skills](https://github.com/android/skills) — Apache 2.0（Google LLC）
> - [MiniMax-AI/skills · android-native-dev](https://github.com/MiniMax-AI/skills/tree/main/skills/android-native-dev) — MIT
> - [developer.android.com](https://developer.android.com)（Google 公开文档）
> - Material Design 3 Guidelines（material.io）
>
> 本文档保留方法论与流程，已根据 Agent Legion implementer-mobile 工作流改写。Android / Jetpack / Material Design 是 Google LLC 的商标。

适用：implementer-mobile 接到 Android 任务时。

---

## 1. 项目情境识别（动手前必做）

| 情境 | 特征 | 处理 |
|:--|:--|:--|
| **空目录** | 无文件 | 完整初始化（含 Gradle Wrapper） |
| **有 Gradle Wrapper** | `gradlew` + `gradle/wrapper/` 存在 | 直接用 `./gradlew` |
| **Android Studio 项目** | 完整结构但可能缺 wrapper | 检查 wrapper，缺则 `gradle wrapper` |
| **不完整项目** | 部分文件 | 补齐后再开发 |

**核心原则**：写业务逻辑前确认 `./gradlew assembleDebug` 成功。

---

## 2. 现代项目最小骨架

```
MyApp/
├── gradle.properties          # AndroidX 等
├── settings.gradle.kts
├── build.gradle.kts           # 根级
├── gradle/wrapper/
│   └── gradle-wrapper.properties
├── app/
│   ├── build.gradle.kts       # Module 级
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── java/com/example/myapp/
│       │   └── MainActivity.kt
│       └── res/
│           ├── values/{strings,colors,themes}.xml
│           └── mipmap-*/
```

`gradle.properties` 必含：
```properties
android.useAndroidX=true
android.enableJetifier=true
org.gradle.parallel=true
kotlin.code.style=official
# 大项目调高内存：org.gradle.jvmargs=-Xmx4096m
```

---

## 3. Compose 依赖（用 BOM 管版本）

```kotlin
dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
}
```

---

## 4. Build Variants（dev / staging / prod）

```kotlin
android {
    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            buildConfigField("String", "API_BASE_URL", "\"https://dev-api.example.com\"")
            buildConfigField("Boolean", "ENABLE_LOGGING", "true")
        }
        create("prod") {
            dimension = "environment"
            buildConfigField("String", "API_BASE_URL", "\"https://api.example.com\"")
            buildConfigField("Boolean", "ENABLE_LOGGING", "false")
        }
    }
    buildFeatures { buildConfig = true }   // AGP 8+ 必须显式开启
}
```

构建命令：
- `./gradlew assembleDevDebug` / `./gradlew assembleProdRelease`
- `./gradlew installDevDebug`

---

## 5. XML 迁移到 Jetpack Compose（10 步法）

来源 attribution：基于 [android/skills/jetpack-compose](https://github.com/android/skills/tree/main/jetpack-compose)（Apache 2.0）的 10 步方法论。

1. **识别最佳 XML 候选**——单一 layout、无复杂自定义 View
2. **分析项目和 layout 结构**——找出依赖、theme、style
3. **定计划**——给用户审批
4. **截图当前 UI**——baseline screenshot
5. **设置 Compose 依赖+编译器**——若缺则补
6. **设置 Compose Theme**——最小集，复用 XML theme 保持互通
7. **迁移 XML layout 到 Compose**——必含 `@Preview`
8. **替换使用点**——双向互通：Compose-in-Views / Views-in-Compose
9. **视觉验证**——baseline 对比 Preview，迭代到 pixel parity
10. **删除 XML**——确认无引用后

---

## 6. Edge-to-Edge（Android 15+ 默认）

来源 attribution：基于 [android/skills/system/edge-to-edge](https://github.com/android/skills/tree/main/system)（Apache 2.0）。

**前置**：必须 Compose + targetSdk ≥ 35。

```kotlin
// MainActivity.onCreate
enableEdgeToEdge()       // 在 setContent 前
setContent { ... }
```

`AndroidManifest.xml` 用键盘的 Activity 加：
```xml
android:windowSoftInputMode="adjustResize"
```

应用 insets（**只用一种**避免双 padding）：
1. **优先**：Scaffold 的 `innerPadding`
2. Material 3 组件自带 inset 处理（`TopAppBar` / `BottomAppBar` / `NavigationBar` 等）
3. Material 2：用 `windowInsets` 参数传给 component（不要给父容器加 padding）
4. 非 Scaffold：`Modifier.safeDrawingPadding()` 或 `Modifier.windowInsetsPadding(WindowInsets.safeDrawing)`

**TextField 必须**：验证 IME 不遮挡输入框（用 `Modifier.imePadding()` 或 fitInside `WindowInsetsRulers.SafeDrawing`）。

---

## 7. Navigation 3（替代 Navigation 2）

来源 attribution：基于 [android/skills/navigation/navigation-3](https://github.com/android/skills/tree/main/navigation/navigation-3)（Apache 2.0）。

核心 API：
- `NavKey` — 类型安全的目的地标识
- `NavHost` — 容器
- `NavDisplay` — 渲染
- `EntryProvider` DSL — 声明式注册

涵盖 patterns：
- 多个 backstack（每个 Tab 自己的栈）
- 深链接（同步/异步 backstack 重建）
- Scenes（Dialog / BottomSheet / List-Detail / Two-Pane / Supporting Pane）
- 条件导航（登录态切换）
- 返回结果（事件 vs 状态）
- DI 集成（Hilt / Koin）

**何时迁移**：现有项目用 Navigation 2 → 走专项迁移指南。新项目直接用 3。

---

## 8. AGP 9 升级路径

来源 attribution：基于 [android/skills/build/agp/agp-9-upgrade](https://github.com/android/skills/tree/main/build)（Apache 2.0）。

**前置**：当前 AGP < 9 时，先用 Android Studio 的 AGP Upgrade Assistant 升到最新稳定版。

升级步骤：
1. 更新依赖：KSP ≥ 2.3.6、Hilt ≥ 2.59.2
2. 迁移到 built-in Kotlin（不再需要单独 kotlin-android plugin）
3. 迁移到新 AGP DSL
4. kapt 迁移到 KSP 或 legacy-kapt
5. BuildConfig：custom 字段必须显式启用 `buildFeatures.buildConfig`
6. 清理 `gradle.properties`：删除过时 flag（`android.builtInKotlin` / `android.newDsl` / `android.uniquePackageNames` / `android.enableAppCompileTimeRClass`）

KMP 项目**不适用**——用专项 KMP 迁移指南。

---

## 9. 性能：R8 优化分析

来源 attribution：基于 [android/skills/performance/r8-analyzer](https://github.com/android/skills/tree/main/performance)（Apache 2.0）。

启用 R8（Release 构建默认）：
```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
```

分析工具：APK Analyzer（Android Studio 内置）+ R8 missing rules report。

常见问题：
- 反射调用的类被 strip → 加 `-keep` 规则
- Gson/Moshi/Kotlinx serialization 的模型类需 `@Keep` 或 keep rule
- 第三方库 keep rules 通常在其文档

---

## 10. Play Billing 升级

来源 attribution：基于 [android/skills/play/play-billing-library-version-upgrade](https://github.com/android/skills/tree/main/play)（Apache 2.0）。

迁移建议：从 Billing Library 5/6 → 7+，关键变化：
- `BillingClient.Builder` 链式 API
- `queryPurchasesAsync()` 替代旧 `queryPurchases`
- ProductDetails（替代 SkuDetails）
- 一次性产品 + 订阅都用 `launchBillingFlow`

测试：用 Play Console 的 license testers + 静态响应测试 SKU。

---

## 11. 完成前 Checklist

- [ ] `./gradlew assembleDebug` 成功
- [ ] `gradle.properties` 含 `useAndroidX=true` `enableJetifier=true`
- [ ] Compose 用 BOM 管版本
- [ ] 多环境用 productFlavors 配置（不要硬编码 API URL）
- [ ] Material 3 Theme 配齐（color scheme + typography + shape）
- [ ] Touch target ≥ 48dp
- [ ] Accessibility：contentDescription / talkback 验过
- [ ] Edge-to-edge 应用 insets，TextField 不被 IME 遮挡
- [ ] Release 构建启用 R8 + 测试 keep rules
- [ ] AGP / Gradle / JDK 版本兼容（看 release notes 兼容表）
