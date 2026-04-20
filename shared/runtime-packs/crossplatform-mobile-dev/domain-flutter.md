# Cross-Platform Domain — Flutter (Dart 3+, BLoC, Riverpod, Platform Channels, FFI)

## 1. Widget Architecture and State Management

### 1.1 Const Constructor Discipline

```dart
// BAD — missing const causes unnecessary rebuilds
class ProductCard extends StatelessWidget {
  final Product product;
  ProductCard({required this.product}); // NOT const

  @override
  Widget build(BuildContext context) {
    return Card(child: Text(product.name));
  }
}

// GOOD — const constructor enables widget tree optimization
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product}); // const!

  @override
  Widget build(BuildContext context) {
    return Card(child: Text(product.name));
  }
}

// Usage: const where possible
const ProductCard(product: product) // Skips rebuild if product hasn't changed
```

### 1.2 BLoC Pattern Depth

```dart
// State
@freezed
class ProductState with _$ProductState {
  const factory ProductState.loading() = ProductLoading;
  const factory ProductState.loaded(List<Product> products) = ProductLoaded;
  const factory ProductState.error(String message) = ProductError;
}

// Event
@freezed
class ProductEvent with _$ProductEvent {
  const factory ProductEvent.load() = ProductLoad;
  const factory ProductEvent.refresh() = ProductRefresh;
}

// Cubit (simple state, no events)
class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;

  ProductCubit(this._repository) : super(const ProductState.loading());

  Future<void> loadProducts() async {
    emit(const ProductState.loading());
    try {
      final products = await _repository.getProducts();
      emit(ProductState.loaded(products));
    } catch (e) {
      emit(ProductState.error(e.toString()));
    }
  }
}

// Bloc (event-driven)
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _repository;

  ProductBloc(this._repository) : super(const ProductState.loading()) {
    on<ProductLoad>(_onLoad);
    on<ProductRefresh>(_onRefresh);
  }

  Future<void> _onLoad(ProductLoad event, Emitter<ProductState> emit) async {
    emit(const ProductState.loading());
    try {
      final products = await _repository.getProducts();
      emit(ProductState.loaded(products));
    } catch (e) {
      emit(ProductState.error(e.toString()));
    }
  }

  Future<void> _onRefresh(ProductRefresh event, Emitter<ProductState> emit) async {
    // Refresh logic with optimistic update
  }
}

// UI
class ProductListView extends StatelessWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        return state.when(
          loading: () => const CircularProgressIndicator(),
          loaded: (products) => ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) => ProductCard(product: products[index]),
          ),
          error: (message) => ErrorWidget(message: message),
        );
      },
    );
  }
}
```

### 1.3 Riverpod 2.x

```dart
// Provider definition
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(dioProvider));
});

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(() {
  return ProductsNotifier();
});

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final repository = ref.read(productRepositoryProvider);
    return repository.getProducts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchProducts);
  }
}

// UI
class ProductListView extends ConsumerWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (products) => ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}
```

---

## 2. Platform Channels and FFI

### 2.1 MethodChannel Contract Discipline

```dart
// Dart side — formal contract
class BatteryChannel {
  static const MethodChannel _channel =
      MethodChannel('com.example.app/battery');

  /// Returns battery level (0-100) or throws PlatformException
  /// Error codes: BATTERY_LEVEL_UNAVAILABLE, PERMISSION_DENIED
  static Future<int> getBatteryLevel() async {
    try {
      final level = await _channel.invokeMethod<int>('getBatteryLevel');
      return level ?? -1;
    } on PlatformException catch (e) {
      throw BatteryException(e.code, e.message ?? 'Unknown error');
    }
  }
}
```

```kotlin
// Android side
class BatteryPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.example.app/battery")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getBatteryLevel" -> {
                val batteryLevel = getBatteryLevel()
                if (batteryLevel != -1) {
                    result.success(batteryLevel)
                } else {
                    result.error(
                        "BATTERY_LEVEL_UNAVAILABLE",
                        "Battery level not available",
                        null
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryStatus = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { filter ->
            context.registerReceiver(null, filter)
        }
        val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        return if (level != -1 && scale != -1) level * 100 / scale else -1
    }
}
```

```swift
// iOS side
public class BatteryPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.app/battery",
            binaryMessenger: registrar.messenger()
        )
        let instance = BatteryPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getBatteryLevel":
            let device = UIDevice.current
            device.isBatteryMonitoringEnabled = true
            if device.batteryState != .unknown {
                result(Int(device.batteryLevel * 100))
            } else {
                result(FlutterError(
                    code: "BATTERY_LEVEL_UNAVAILABLE",
                    message: "Battery level not available",
                    details: nil
                ))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

### 2.2 Dart FFI for C Libraries

```dart
// Dart FFI
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

// Load the dynamic library
final DynamicLibrary nativeLib = Platform.isAndroid
    ? ffi.DynamicLibrary.open('libnative.so')
    : ffi.DynamicLibrary.process();

// C function signature: int process_image(uint8_t* data, int length)
typedef ProcessImageNative = ffi.Int32 Function(ffi.Pointer<ffi.Uint8>, ffi.Int32);
typedef ProcessImageDart = int Function(ffi.Pointer<ffi.Uint8>, int);

final processImage = nativeLib
    .lookup<ffi.NativeFunction<ProcessImageNative>>('process_image')
    .asFunction<ProcessImageDart>();
```

---

## 3. Performance Optimization

### 3.1 DevTools Performance Tab

```bash
# Profile mode — required for accurate performance measurement
flutter run --profile

# Key metrics:
# - Frame time: target < 16ms (60fps), < 8ms (120fps)
# - Raster time: GPU thread work
# - Build time: widget tree construction
# - Jank: frames exceeding budget
```

### 3.2 ListView.builder vs Column

```dart
// BAD — Column creates all widgets eagerly
Column(
  children: products.map((p) => ProductCard(product: p)).toList(), // 1000+ widgets!
)

// GOOD — ListView.builder lazily creates visible widgets only
ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) => ProductCard(product: products[index]),
)

// GOOD — CustomScrollView with slivers for complex layouts
CustomScrollView(
  slivers: [
    SliverAppBar(title: Text('Products')),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ProductCard(product: products[index]),
        childCount: products.length,
      ),
    ),
  ],
)
```

### 3.3 GoRouter Navigation

```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'product/:id',
          builder: (context, state) {
            final productId = state.pathParameters['id']!;
            return ProductDetailScreen(productId: productId);
          },
        ),
      ],
    ),
  ],
);

// Usage
textButton(
  onPressed: () => context.go('/product/123'),
  child: Text('View Product'),
)
```
