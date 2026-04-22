---
name: ios-native-development
description: iOS native development methodology for the Harness team. Covers SwiftUI state ownership, Swift Concurrency discipline, Core Data/SwiftData persistence, Keychain security, URLSession networking, App Store submission readiness, and platform-specific APIs (APNs, ATT, Privacy Manifest). Loaded by @ios-dev via skills: frontmatter.
type: skill
---

# iOS Native Development Skill

## 1. SwiftUI State Ownership Hierarchy

| Wrapper | Ownership | Who Creates | Who Observes |
|---------|-----------|-------------|--------------|
| `@State` | Value-type UI state | The view itself | Same view only |
| `@Binding` | State passed with write-back | Parent view | Child view reads/writes |
| `@StateObject` | Reference-type state | Creating view only | Use `@ObservedObject` downstream |
| `@EnvironmentObject` | App-wide shared state | Injected at root | Any view in tree |
| `@Observable` (iOS 17+) | Implicit tracking without `@Published` | Any view | Automatic via tracking |

**Observation framework (iOS 17+)**: `@Observable` macro + `@Bindable` for two-way binding + `@Environment(ModelType.self)` for injection.

**NavigationStack**: `NavigationStack(path: $navPath)` with `NavigationPath` for type-erased multi-step navigation; `.navigationDestination(for:)` maps data types to destination views.

## 2. Swift Concurrency Discipline

- `Task {}` inherits actor context of creation site; `Task.detached {}` runs off all actors for CPU work
- Cancel tasks in `onDisappear` or use `.task(id:)` which auto-cancels
- Actor isolation: actor methods are implicitly async from outside; `@MainActor` for UI-bound types
- Bridge callback APIs with `withCheckedThrowingContinuation` (one-shot) or `AsyncStream` (streaming)
- **Never resume a continuation more than once** — crashes at runtime

## 3. UIKit Interoperability

- `UIViewControllerRepresentable`: `makeUIViewController` → `updateUIViewController` → `Coordinator` for delegates
- Auto Layout: `translatesAutoresizingMaskIntoConstraints = false` on every view; batch activate constraints
- `UICollectionViewDiffableDataSource` eliminates manual `reloadData`; `UICollectionViewCompositionalLayout` for modern grids

## 4. Data and Persistence

**Core Data thread safety**: `viewContext` for read-only UI; all writes on background contexts via `performBackgroundTask`; never pass `NSManagedObject` between contexts — pass `NSManagedObjectID` and re-fetch.

**SwiftData (iOS 17+)**: `@Model` macro → `ModelContainer` → `ModelContext` → `@Query` macro in SwiftUI; migrations via `VersionedSchema` and `SchemaMigrationPlan`.

**Keychain**: Wrap `SecItemAdd`/`SecItemCopyMatching`/`SecItemUpdate`/`SecItemDelete` in typed `KeychainService`; default accessibility `kSecAttrAccessibleWhenUnlocked`; more sensitive: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.

**URLSession async/await**: `let (data, response) = try await URLSession.shared.data(for: request)`; validate HTTP status before decoding; configure JSONDecoder once on shared instance.

**Background URL sessions**: `URLSessionConfiguration.background(withIdentifier:)` for uploads/downloads that survive suspension; recreate at launch with same identifier.

## 5. Platform-Specific APIs

**Scene-based lifecycle (iOS 13+)**: `UISceneDelegate.scene(_:willConnectTo:options:)` is entry point; multi-window on iPad requires scene manifest in Info.plist.

**APNs**: `UNUserNotificationCenter.requestAuthorization` → `registerForRemoteNotifications` → token in `didRegisterForRemoteNotificationsWithDeviceToken`; prefer Token-based auth (`.p8` key) over Certificate-based.

**ATT and IDFA**: `ATTrackingManager.requestTrackingAuthorization` presents system consent dialog (once per install); `NSUserTrackingUsageDescription` in Info.plist is required or app crashes on launch.

**App Transport Security**: ATS requires HTTPS; `NSAllowsArbitraryLoads: true` causes App Store scrutiny; use `NSExceptionDomains` with documented justification.

**Privacy manifest (iOS 17+)**: `PrivacyInfo.xcprivacy` declaring API types, data collected, tracking usage; missing → App Store rejection.

## 6. Security Self-Check (5 Items)

1. **Keychain for secrets**: `grep -r "UserDefaults" Sources/ | grep -i "token\|secret\|key\|password"` must be empty
2. **ATT consent**: any IDFA access preceded by `ATTrackingManager.requestTrackingAuthorization`
3. **ATS compliance**: `NSAllowsArbitraryLoads` false or absent in production Info.plist
4. **No hardcoded credentials**: no API keys as string literals in Swift source
5. **Privacy manifest**: `PrivacyInfo.xcprivacy` declares all accessed API types with reason codes

## 7. Force-Unwrap Policy

Three acceptable cases only:
1. IBOutlet/IBAction guaranteed by storyboard wiring (document with comment)
2. Compile-time resources that cannot be absent: `Bundle.main.url(forResource: "Config", withExtension: "plist")!`
3. Unit test assertion helpers where crashing on nil is intended

All other `!` → `guard let`, `if let`, `??`, `try?`, or `throw`.

## 8. Anti-Patterns

| Name | Symptom | Correction |
|------|---------|------------|
| **Main-Thread Hostage** | Blocking I/O/network/JSON decode on main thread | `async`/`await` with explicit actor boundary crossings |
| **Force-Unwrap Plague** | `!` suppressing optional handling | `guard let` not `let x = y!` |
| **Retain Cycle Web** | Escaping closures capturing `self` strongly | `[weak self]` in every escaping closure |
| **UserDefaults-for-Secrets** | JWT/API key in UserDefaults | Keychain with `kSecAttrAccessibleWhenUnlocked` |
| **Invisible IDFA Collection** | IDFA access without ATT consent | Check `ATTrackingManager.trackingAuthorizationStatus` first |
