# iOS Domain — SwiftUI, UIKit Interop, and State Architecture

## 1. SwiftUI State Ownership Hierarchy

### 1.1 Property Wrapper Selection Guide

| Wrapper | Ownership | Lifetime | Use Case |
|---------|-----------|----------|----------|
| `@State` | View owns | Tied to view instance | Local value-type UI state (toggle, text field input) |
| `@Binding` | Parent owns | Inherited from parent | Child view needs read+write access to parent's state |
| `@StateObject` | View creates | Tied to creating view | Reference-type ViewModel, created once per view |
| `@ObservedObject` | External owns | External management | ViewModel injected from parent or environment |
| `@EnvironmentObject` | App-level | App lifetime | Shared services (auth, settings) |
| `@Environment` | System | System lifetime | System values (colorScheme, dismiss action) |
| `@Observable` (iOS 17+) | Class macro | Instance lifetime | Modern observation, replaces ObservableObject |

```swift
// BAD — @ObservedObject for locally-created ViewModel
struct ProfileView: View {
    @ObservedObject var viewModel = ProfileViewModel() // Recreated on every re-render!
    var body: some View { ... }
}

// GOOD — @StateObject for locally-created ViewModel
struct ProfileView: View {
    @StateObject var viewModel = ProfileViewModel() // Created once, survives re-renders
    var body: some View { ... }
}

// GOOD — @ObservedObject for injected ViewModel
struct ProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel // Passed from parent
    var body: some View { ... }
}
```

### 1.2 Observation Framework (iOS 17+)

```swift
// @Observable macro — no @Published needed
@Observable
class ProductViewModel {
    var products: [Product] = []
    var isLoading = false
    var error: Error?
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await repository.fetchProducts()
        } catch {
            self.error = error
        }
    }
}

// SwiftUI view — automatic reactivity without @StateObject
struct ProductListView: View {
    @Bindable var viewModel: ProductViewModel // @Bindable for two-way binding
    
    var body: some View {
        List(viewModel.products) { product in
            Text(product.name)
        }
        .task {
            await viewModel.loadProducts()
        }
    }
}
```

### 1.3 NavigationStack and Programmatic Navigation

```swift
@Observable
class NavigationStore {
    var path = NavigationPath()
    
    func navigateToProduct(_ productId: String) {
        path.append(Route.productDetail(id: productId))
    }
    
    func navigateToCheckout(_ orderId: String) {
        path.append(Route.checkout(orderId: orderId))
    }
    
    func goBack() {
        path.removeLast()
    }
    
    func goHome() {
        path.removeLast(path.count)
    }
}

enum Route: Hashable {
    case productDetail(id: String)
    case checkout(orderId: String)
    case settings
}

struct ContentView: View {
    @State private var navigationStore = NavigationStore()
    
    var body: some View {
        NavigationStack(path: $navigationStore.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .productDetail(let id):
                        ProductDetailView(productId: id)
                    case .checkout(let orderId):
                        CheckoutView(orderId: orderId)
                    case .settings:
                        SettingsView()
                    }
                }
        }
        .environment(navigationStore)
    }
}
```

---

## 2. Swift Concurrency Discipline

### 2.1 Task Lifecycle Management

```swift
struct AsyncImageView: View {
    let imageURL: URL
    @State private var image: UIImage?
    @State private var task: Task<Void, Never>?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            task = Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: imageURL)
                    if let loadedImage = UIImage(data: data) {
                        await MainActor.run {
                            self.image = loadedImage
                        }
                    }
                } catch {
                    // Handle error
                }
            }
        }
        .onDisappear {
            task?.cancel() // Cancel ongoing download when view disappears
        }
    }
}
```

### 2.2 withCheckedThrowingContinuation for Callback Bridging

```swift
func requestAuthorization() async throws -> Bool {
    try await withCheckedThrowingContinuation { continuation in
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: granted)
            }
        }
    }
}

// Usage
func setupNotifications() async {
    do {
        let granted = try await requestAuthorization()
        if granted {
            await UIApplication.shared.registerForRemoteNotifications()
        }
    } catch {
        print("Authorization failed: \(error)")
    }
}
```

### 2.3 AsyncStream for Delegate-Based APIs

```swift
func locationUpdates() -> AsyncStream<CLLocation> {
    AsyncStream { continuation in
        let manager = CLLocationManager()
        let delegate = LocationDelegate { location in
            continuation.yield(location)
        }
        manager.delegate = delegate
        manager.startUpdatingLocation()
        
        continuation.onTermination = { _ in
            manager.stopUpdatingLocation()
        }
    }
}

private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    let onUpdate: (CLLocation) -> Void
    
    init(onUpdate: @escaping (CLLocation) -> Void) {
        self.onUpdate = onUpdate
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach(onUpdate)
    }
}
```

---

## 3. UIKit Interoperability

### 3.1 UIViewControllerRepresentable

```swift
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                parent.dismiss()
                return
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                    DispatchQueue.main.async {
                        self?.parent.selectedImage = image as? UIImage
                        self?.parent.dismiss()
                    }
                }
            }
        }
    }
}
```

### 3.2 UICollectionView with DiffableDataSource

```swift
final class ProductGridViewController: UIViewController {
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Product>!
    
    enum Section {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        configureDataSource()
        applySnapshot()
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewCompositionalLayout { _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.5),
                heightDimension: .absolute(200)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
            
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(200)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
    }
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Product>(
            collectionView: collectionView
        ) { collectionView, indexPath, product in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ProductCell",
                for: indexPath
            ) as! ProductCell
            cell.configure(with: product)
            return cell
        }
    }
    
    private func applySnapshot(products: [Product] = []) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Product>()
        snapshot.appendSections([.main])
        snapshot.appendItems(products)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
```

---

## 4. App Store Submission and TestFlight

### 4.1 App Store Submission Checklist

```
Pre-Submission Verification:
□ Bundle ID matches App Store Connect record
□ Version number incremented (CFBundleShortVersionString)
□ Build number incremented (CFBundleVersion)
□ Provisioning profile: App Store Distribution
□ Certificate: Distribution (not Development)
□ Archive builds cleanly: Product → Archive
□ App thinning enabled (App Store automatically thins)
□ Bitcode disabled (Apple deprecated bitcode)
□ Required capabilities declared in entitlements
□ All Info.plist usage descriptions populated
□ Privacy manifest (PrivacyInfo.xcprivacy) complete
□ Screenshots for all supported device sizes
□ App Store metadata: name, subtitle, description, keywords
□ Content rating questionnaire completed
□ Export compliance answered
```

### 4.2 TestFlight Distribution

```bash
# Build and archive
xcodebuild -scheme MyApp -destination "generic/platform=iOS" archive -archivePath build/MyApp.xcarchive

# Export IPA for TestFlight
xcodebuild -exportArchive -archivePath build/MyApp.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath build/

# ExportOptions.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

### 4.3 Privacy Manifest (PrivacyInfo.xcprivacy)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyCollectedDataTypes</key>
    <array>
        <dict>
            <key>NSPrivacyCollectedDataType</key>
            <string>NSPrivacyCollectedDataTypeUserID</string>
            <key>NSPrivacyCollectedDataTypeLinked</key>
            <true/>
            <key>NSPrivacyCollectedDataTypeTracking</key>
            <false/>
            <key>NSPrivacyCollectedDataTypePurposes</key>
            <array>
                <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
            </array>
        </dict>
    </array>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```
