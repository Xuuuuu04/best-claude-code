# iOS Domain — Core Data, SwiftData, Keychain, and Networking

## 1. Core Data Background Context Discipline

### 1.1 Proper Context Usage

```swift
final class CoreDataStack {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MyModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask { context in
            block(context)
        }
    }
}

// BAD — writing on view context for large operations
func importProducts(_ products: [ProductDTO]) {
    products.forEach { dto in
        let product = Product(context: viewContext)
        product.name = dto.name
        product.price = dto.price
    }
    try? viewContext.save() // Blocks main thread!
}

// GOOD — background context for writes
func importProducts(_ products: [ProductDTO]) {
    CoreDataStack.shared.performBackgroundTask { context in
        products.forEach { dto in
            let product = Product(context: context)
            product.name = dto.name
            product.price = dto.price
        }
        do {
            try context.save()
        } catch {
            print("Import failed: \(error)")
        }
    }
}
```

### 1.2 NSFetchedResultsController for List Views

```swift
final class ProductListViewModel: ObservableObject {
    @Published var products: [Product] = []
    
    private var fetchedResultsController: NSFetchedResultsController<Product>?
    
    func setupFetchController() {
        let request: NSFetchRequest<Product> = Product.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: CoreDataStack.shared.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        fetchedResultsController?.delegate = self
        
        do {
            try fetchedResultsController?.performFetch()
            products = fetchedResultsController?.fetchedObjects ?? []
        } catch {
            print("Fetch failed: \(error)")
        }
    }
}

extension ProductListViewModel: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        products = controller.fetchedObjects as? [Product] ?? []
    }
}
```

---

## 2. SwiftData (iOS 17+)

### 2.1 Model Definition and Container Setup

```swift
import SwiftData

@Model
class Note {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var tags: [String]
    
    init(title: String, content: String, tags: [String] = []) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.tags = tags
    }
}

// App entry point
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Note.self)
    }
}
```

### 2.2 SwiftUI Integration with @Query

```swift
struct NoteListView: View {
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            ForEach(notes) { note in
                NavigationLink(value: note) {
                    NoteRow(note: note)
                }
            }
            .onDelete(perform: deleteNotes)
        }
    }
    
    private func deleteNotes(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(notes[index])
        }
        try? modelContext.save()
    }
}
```

### 2.3 Versioned Schema Migration

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
        @Attribute(.unique) var id: UUID
        var title: String
        var content: String
        var tags: [String]
        var createdAt: Date
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
            // Set default values for new properties before migration
        },
        didMigrate: nil
    )
}
```

---

## 3. Keychain Service Implementation

```swift
enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidStatus(OSStatus)
    case conversionFailed
}

final class KeychainService {
    static let shared = KeychainService()
    
    @discardableResult
    func save(
        data: Data,
        service: String,
        account: String,
        accessibility: CFString = kSecAttrAccessibleWhenUnlocked
    ) -> Result<Void, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            return .failure(.invalidStatus(status))
        }
        return .success(())
    }
    
    func read(service: String, account: String) -> Result<Data, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return .failure(.itemNotFound)
            }
            return .failure(.invalidStatus(status))
        }
        
        guard let data = result as? Data else {
            return .failure(.conversionFailed)
        }
        return .success(data)
    }
    
    @discardableResult
    func delete(service: String, account: String) -> Result<Void, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            return .failure(.invalidStatus(status))
        }
        return .success(())
    }
}

// Convenience extensions for String values
extension KeychainService {
    func saveString(_ value: String, service: String, account: String) -> Result<Void, KeychainError> {
        guard let data = value.data(using: .utf8) else {
            return .failure(.conversionFailed)
        }
        return save(data: data, service: service, account: account)
    }
    
    func readString(service: String, account: String) -> Result<String, KeychainError> {
        read(service: service, account: account).flatMap { data in
            guard let string = String(data: data, encoding: .utf8) else {
                return .failure(.conversionFailed)
            }
            return .success(string)
        }
    }
}

// Usage
func saveAuthToken(_ token: String) {
    let result = KeychainService.shared.saveString(
        token,
        service: "com.example.app",
        account: "auth_token"
    )
    if case .failure(let error) = result {
        print("Failed to save token: \(error)")
    }
}
```

---

## 4. URLSession async/await and Background Sessions

### 4.1 Typed API Client

```swift
enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingFailed(Error)
}

final class APIClient {
    static let shared = APIClient()
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = URL(string: endpoint.path, relativeTo: endpoint.baseURL) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = try? KeychainService.shared.readString(
            service: "com.example.app",
            account: "auth_token"
        ).get() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}

struct Endpoint {
    let baseURL: URL
    let path: String
    let method: String
    let body: Data?
    
    static func getProducts(baseURL: URL) -> Endpoint {
        Endpoint(baseURL: baseURL, path: "/api/products", method: "GET", body: nil)
    }
}
```

### 4.2 Background URL Session for Downloads

```swift
final class DownloadManager: NSObject {
    static let shared = DownloadManager()
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(
            withIdentifier: "com.example.app.downloads"
        )
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    func downloadFile(from url: URL) {
        let task = session.downloadTask(with: url)
        task.resume()
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // Move file from temp location to permanent storage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsPath.appendingPathComponent(location.lastPathComponent)
        
        try? FileManager.default.moveItem(at: location, to: destinationURL)
    }
    
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error {
            print("Download failed: \(error)")
        }
    }
}

// AppDelegate handling background events
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        // Store completion handler for later use
        DownloadManager.shared.backgroundCompletionHandler = completionHandler
    }
}
```
