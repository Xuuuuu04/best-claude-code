# iOS 开发师 — Anti-Patterns

## Named Anti-Patterns

---

### Main-Thread Hostage

**Definition**: Blocking I/O, network requests, JSON decoding, Core Data fetches, or heavy computation on the main actor. The main actor is for UI reads and writes only.

**Manifestations**:
```swift
// BAD — synchronous network call on main actor
@MainActor
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    
    func loadProducts() {
        // WRONG: blocking the main thread
        let data = try! Data(contentsOf: URL(string: "https://api.example.com/products")!)
        products = try! JSONDecoder().decode([Product].self, from: data)
    }
}
```

```swift
// BAD — Core Data fetch on main context for large dataset
@MainActor
func fetchAllOrders() {
    let request: NSFetchRequest<Order> = Order.fetchRequest()
    let orders = try? viewContext.fetch(request) // 10,000+ items on main thread
    // UI freezes for seconds
}
```

**Why it's dangerous**: UI freezes measured by Instruments Main Thread Checker. Users see unresponsive interface. App Store may flag excessive hangs. Background tasks on main thread drain battery.

**Correction**: Use `async`/`await` with explicit actor boundary crossings.

```swift
// GOOD — async/await with background work
@MainActor
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    
    func loadProducts() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let fetched = try await repository.fetchProducts() // off main actor
                products = fetched // back on @MainActor
            } catch {
                // handle error
            }
        }
    }
}
```

---

### Force-Unwrap Plague

**Definition**: Pervasive use of `!` to suppress optional handling. When the optional is nil at runtime, the result is EXC_BAD_ACCESS — a crash that is invisible in development and surfaces only on specific devices or data conditions.

**Manifestations**:
```swift
// BAD — force unwrap on network response
let user = try! JSONDecoder().decode(User.self, from: data)
let image = UIImage(named: "avatar")! // crashes if asset missing
let url = URL(string: user.profileUrl)! // crashes if URL invalid
```

```swift
// BAD — force cast
let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! MyCell
let dict = response as! [String: Any]
```

**Why it's dangerous**: EXC_BAD_ACCESS is the most preventable iOS crash class. It produces no stack trace at the point of failure. Users experience sudden app termination. Crashlytics groups them under generic signals.

**Correction**: `guard let`, `if let`, `??`, `try?`, `as?`, or structured throwing.

```swift
// GOOD — safe unwrapping
guard let user = try? JSONDecoder().decode(User.self, from: data) else {
    throw APIError.decodingFailed
}

let image = UIImage(named: "avatar") ?? UIImage(systemName: "person.circle")

if let url = URL(string: user.profileUrl) {
    // use url
}

// Safe cast
guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? MyCell else {
    return UITableViewCell()
}
```

---

### Retain Cycle Web

**Definition**: Escaping closures capturing `self` strongly, creating circular strong references that prevent deallocation. Memory grows with each allocation. Completion handlers call UI methods on logically-deallocated view controllers.

**Manifestations**:
```swift
// BAD — strong self capture in escaping closure
URLSession.shared.dataTask(with: request) { data, response, error in
    self.updateUI(with: data) // RETAIN CYCLE
}.resume()
```

```swift
// BAD — NotificationCenter observer with strong self
NotificationCenter.default.addObserver(
    forName: .userDidLogin,
    object: nil,
    queue: .main
) { notification in
    self.handleLogin(notification) // RETAIN CYCLE
}
```

```swift
// BAD — Timer retaining target
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    self.updateCountdown() // RETAIN CYCLE
}
```

**Why it's dangerous**: Memory grows unbounded. Instruments Memory Graph shows multiple instances of the same ViewController alive. Callbacks fire on deallocated objects causing crashes or stale UI updates.

**Correction**: `[weak self]` in every escaping closure. Verify with Instruments Memory Graph.

```swift
// GOOD — weak self capture
URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
    guard let self else { return }
    self.updateUI(with: data)
}.resume()

// GOOD — NotificationCenter with weak self + removal in deinit
private var cancellables = Set<AnyCancellable>()

NotificationCenter.default
    .publisher(for: .userDidLogin)
    .sink { [weak self] notification in
        self?.handleLogin(notification)
    }
    .store(in: &cancellables)

// GOOD — Timer with weak self, invalidated on deinit
private weak var timer: Timer?

timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    self?.updateCountdown()
}

deinit {
    timer?.invalidate()
}
```

---

### UserDefaults-for-Secrets

**Definition**: Storing JWT tokens, API keys, passwords, or any sensitive credential in `UserDefaults`. UserDefaults persists as a plaintext plist file.

**Manifestations**:
```swift
// BAD — plaintext token storage
UserDefaults.standard.set(token, forKey: "auth_token")
UserDefaults.standard.set(apiKey, forKey: "api_key")
```

**Why it's dangerous**: UserDefaults plist is readable via Xcode Devices panel without jailbreak. iMazing and other backup tools can extract it. On a compromised device, any app with file system access can read other apps' UserDefaults.

**Correction**: Keychain with appropriate accessibility level.

```swift
// GOOD — KeychainService wrapper
class KeychainService {
    static let shared = KeychainService()
    
    func save(_ data: Data, service: String, account: String) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        SecItemDelete(query as CFDictionary) // Remove existing
        return SecItemAdd(query as CFDictionary, nil)
    }
    
    func read(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
}
```

---

### Invisible IDFA Collection

**Definition**: Accessing advertising identifier data without ATT (App Tracking Transparency) consent. Since iOS 14.5, unauthorized IDFA access returns all zeros — the data appears valid but is meaningless.

**Manifestations**:
```swift
// BAD — IDFA access without consent check
let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
// Returns 00000000-0000-0000-0000-000000000000 if unauthorized
analytics.track("install", ["idfa": idfa]) // tracks meaningless zeros
```

```swift
// BAD — missing NSUserTrackingUsageDescription in Info.plist
// App crashes on launch when ATT dialog triggered
```

**Why it's dangerous**: The analytics pipeline accepts zeros as valid identifiers. Marketing decisions are made on garbage data. Missing `NSUserTrackingUsageDescription` causes App Store rejection.

**Correction**: Check authorization status before accessing IDFA. Provide usage description.

```swift
// GOOD — ATT consent before IDFA access
import AppTrackingTransparency

func requestTrackingPermission() {
    ATTrackingManager.requestTrackingAuthorization { status in
        switch status {
        case .authorized:
            let idfa = ASIdentifierManager.shared().advertisingIdentifier
            // Safe to use idfa
        case .denied, .notDetermined, .restricted:
            // Do not collect IDFA
            break
        @unknown default:
            break
        }
    }
}
```

```xml
<!-- Info.plist -->
<key>NSUserTrackingUsageDescription</key>
<string>Your data will be used to deliver personalized ads and measure their effectiveness.</string>
```

---

### Core Data Context Thread Violation

**Definition**: Passing `NSManagedObject` instances between contexts or performing Core Data operations on the wrong thread. Core Data contexts have thread affinity.

**Manifestations**:
```swift
// BAD — passing managed object between contexts
let user = viewContext.object(with: objectID) as! User
backgroundContext.perform {
    user.name = "New Name" // CRASH: object from different context
    try? backgroundContext.save()
}
```

```swift
// BAD — fetching on background but updating UI without main context
DispatchQueue.global().async {
    let users = try? backgroundContext.fetch(request)
    label.text = users?.first?.name // CRASH: UI update off main thread + wrong context
}
```

**Why it's dangerous**: `EXC_BAD_ACCESS` or `NSInternalInconsistencyException` at runtime. Data corruption when multiple contexts modify the same object. UI updates on background thread cause crashes.

**Correction**: Pass `NSManagedObjectID` between contexts, not objects. Always update UI on main context.

```swift
// GOOD — pass object ID, re-fetch on target context
backgroundContext.perform {
    guard let user = backgroundContext.object(with: objectID) as? User else { return }
    user.name = "New Name"
    try? backgroundContext.save()
    
    // Merge changes to view context
    DispatchQueue.main.async {
        self.viewContext.mergeChanges(fromContextDidSave: notification)
    }
}
```

---

### SwiftData Migration Blindspot

**Definition**: Adding `@Model` properties or changing property types without a migration plan. SwiftData requires explicit schema versioning for any model change.

**Manifestations**:
```swift
// Version 1
@Model
class Note {
    var title: String
    var content: String
}

// Version 2 — added property without migration
@Model
class Note {
    var title: String
    var content: String
    var tags: [String] // CRASH: existing stores have no tags column
}
```

**Why it's dangerous**: App crashes on launch for users with existing data. No automatic migration in SwiftData — must define `VersionedSchema` and `SchemaMigrationPlan`.

**Correction**: Versioned schema with explicit migration plan.

```swift
enum NoteSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    @Model
    class Note {
        var title: String
        var content: String
    }
}

enum NoteSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    @Model
    class Note {
        var title: String
        var content: String
        var tags: [String]
    }
}

enum NoteMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [NoteSchemaV1.self, NoteSchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: NoteSchemaV1.self,
        toVersion: NoteSchemaV2.self,
        willMigrate: { context in
            // Set default values for new properties
        },
        didMigrate: nil
    )
}
```
