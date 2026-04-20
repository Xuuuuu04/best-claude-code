# 跨平台移动开发师 — Anti-Patterns

## Named Anti-Patterns

---

### Rebuild Storm

**Definition**: Composing a widget/component tree in a way that causes unnecessary rebuilds of subtrees that did not have their data change. In Flutter: missing `const` constructors, state not lifted to BLoC/Riverpod. In React Native: missing `React.memo`, inline function references as props.

**Manifestations**:
```dart
// BAD — no const constructor, rebuilds entire list on every keystroke
class ProductList extends StatelessWidget {
  final List<Product> products;
  ProductList({required this.products}); // NOT const

  @override
  Widget build(BuildContext context) {
    return Column(
      children: products.map((p) => ProductCard(product: p)).toList(),
    );
  }
}
```

```tsx
// BAD — inline arrow function creates new reference every render
function ProductList({ products, onSelect }) {
  return (
    <FlatList
      data={products}
      renderItem={({ item }) => (
        <ProductCard
          product={item}
          onPress={() => onSelect(item)} // NEW function every render
        />
      )}
    />
  );
}
```

**Why it's dangerous**: Excessive rebuilds cause frame drops (jank), high CPU usage, and battery drain. On low-end devices, this makes the app unusable. The issue compounds across the widget/component tree.

**Correction**: Flutter: `const` constructors, lift state to BLoC/Riverpod, `ListView.builder`. RN: `React.memo`, `useCallback`, `useMemo`.

```dart
// GOOD — const constructor + ListView.builder
class ProductList extends StatelessWidget {
  final List<Product> products;
  const ProductList({super.key, required this.products}); // const!

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]); // const if ProductCard is const
      },
    );
  }
}
```

```tsx
// GOOD — useCallback for stable function reference
function ProductList({ products, onSelect }) {
  const renderItem = useCallback(({ item }) => (
    <ProductCard product={item} onPress={onSelect} />
  ), [onSelect]);

  return <FlatList data={products} renderItem={renderItem} />;
}
```

---

### Bridge Overuse

**Definition**: Calling across the native bridge on a per-frame basis (~60 calls/second), creating a serialization tax that overwhelms the bridge thread.

**Manifestations**:
```dart
// BAD — calling MethodChannel every animation frame
AnimationController(
  vsync: this,
  duration: Duration(seconds: 1),
)..addListener(() {
  channel.invokeMethod('updateNativePosition', position); // 60 calls/sec!
});
```

```tsx
// BAD — NativeModules call inside requestAnimationFrame loop
useEffect(() => {
  const animate = () => {
    NativeModules.SensorModule.getLatestReading((reading) => {
      setPosition(reading); // Bridge crossing every frame
    });
    requestAnimationFrame(animate);
  };
  animate();
}, []);
```

**Why it's dangerous**: The bridge has finite throughput. At 60 calls/second with serialization overhead, the UI thread stalls waiting for responses. Frame times exceed 16ms budget → jank.

**Correction**: Use `EventChannel` (Flutter) or `NativeEventEmitter` (RN) for continuous native data streams. Batch updates. Use Reanimated 3 worklets for animation-coupled logic.

```dart
// GOOD — EventChannel for continuous stream
class _SensorPageState extends State<SensorPage> {
  static const eventChannel = EventChannel('com.example/sensor');
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = eventChannel
      .receiveBroadcastStream()
      .listen((reading) => setState(() => _reading = reading));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

---

### Dependency Pinning Miss

**Definition**: Failing to pin native dependency versions, causing iOS and Android builds to pull different versions of transitive native dependencies that produce platform-divergent failures.

**Manifestations**:
```yaml
# BAD — no version pin, pulls latest
dependencies:
  firebase_core: ^2.0.0  # caret allows minor updates
  firebase_messaging: ^14.0.0
```

```json
// BAD — loose version range
{
  "dependencies": {
    "react-native-firebase": "^19.0.0"
  }
}
```

**Why it's dangerous**: A minor update to a native dependency may change iOS podspec requirements or Android Gradle module structure. CI builds start failing on one platform but not the other. The failure appears "random" because it depends on when the lockfile was last updated.

**Correction**: Pin to exact versions for production applications. Use lockfiles (`pubspec.lock`, `package-lock.json`, `yarn.lock`, `Podfile.lock`).

```yaml
# GOOD — exact version pin
dependencies:
  firebase_core: 2.27.1
  firebase_messaging: 14.7.19
```

```json
// GOOD — exact version with lockfile
{
  "dependencies": {
    "react-native-firebase": "19.0.1"
  }
}
```

---

### Platform Divergence Undocumented

**Definition**: Implementing a feature that behaves differently on iOS and Android without documenting the divergence.

**Manifestations**:
```dart
// BAD — platform branch with no explanation
if (Platform.isIOS) {
  await _requestIosPermission();
} else {
  await _requestAndroidPermission();
}
```

```tsx
// BAD — different behavior with no comment
const channelId = Platform.OS === 'android' ? 'orders' : undefined;
```

**Why it's dangerous**: Future maintainers (including yourself in 6 months) cannot understand why the branch exists. @code-review cannot verify correctness. @test-func tests against wrong expectations. Platform-specific bugs are misdiagnosed as framework bugs.

**Correction**: Every platform branch must have a comment explaining the divergence.

```dart
// GOOD — documented divergence
// iOS: Notification permission requested at app launch via APNs
// Android: Notification channels created in Application.onCreate;
//          POST_NOTIFICATIONS permission required for Android 13+
if (Platform.isIOS) {
  await _requestIosNotificationPermission();
} else {
  await _createAndroidNotificationChannels();
  if (await _requiresAndroidNotificationPermission()) {
    await _requestAndroidNotificationPermission();
  }
}
```

---

### Single-Store Mindset

**Definition**: Implementing Fastlane or Codemagic for one store while treating the other store as "we'll figure that out later."

**Manifestations**:
```ruby
# BAD — only iOS lane
lane :beta do
  match(type: "appstore")
  gym(scheme: "Runner")
  pilot
  # No Android lane!
end
```

**Why it's dangerous**: "Later" often means "never" or "rushed at deadline." Store-specific requirements (domestic push SDKs, privacy manifests, API level compliance) are discovered late. Release is delayed or ships with missing store coverage.

**Correction**: Every Fastfile must have both an iOS lane and an Android lane. Both are required deliverables.

```ruby
# GOOD — dual-store lanes
lane :ios_beta do
  match(type: "appstore")
  gym(scheme: "Runner", export_method: "app-store")
  pilot(distribute_external: false, groups: ["Internal Testers"])
end

lane :android_beta do
  gradle(task: "bundle", build_type: "Release")
  supply(track: "internal", aab: "../build/app/outputs/bundle/release/app-release.aab")
end

lane :beta do
  ios_beta
  android_beta
end
```

---

### Framework Mixup

**Definition**: Writing Flutter code in a React Native project or vice versa. Using Dart APIs in a TypeScript file or JSX in a Dart file.

**Manifestations**:
```tsx
// WRONG — Flutter widget in React Native
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text('Hello'));
  }
}
```

**Why it's dangerous**: The code doesn't compile. The framework mismatch indicates the developer didn't confirm the project technology before starting. Wastes implementation time.

**Correction**: Confirm framework before writing any code. Check `pubspec.yaml` (Flutter) or `package.json` (RN) to verify.

---

### Native Bridge Afterthought

**Definition**: Designing the native bridge interface AFTER writing the Dart/JS layer. The bridge contract is incomplete, missing error codes, or incompatible with one platform's capabilities.

**Manifestations**:
```dart
// BAD — bridge designed after Dart code written
// Dart calls this but iOS native side has different method name
final result = await platform.invokeMethod('scanBarcode');
```

**Why it's dangerous**: Integration failures discovered at runtime. Method not found errors. Type mismatches. The bridge contract is the integration boundary — defects here require rework on all three layers (Dart/JS, iOS native, Android native).

**Correction**: Design bridge contract BEFORE any implementation. Document method names, argument types, return types, error codes. Get @ios-dev and @android-dev confirmation before proceeding.
