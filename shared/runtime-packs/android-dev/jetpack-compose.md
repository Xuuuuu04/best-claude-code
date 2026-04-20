# Android Domain — Jetpack Compose Lifecycle and State Architecture

## 1. Compose State Management

### 1.1 State Hoisting Discipline

State lives at the **lowest level that owns it**. Hoist state to where it needs to be shared. Stateless composables take state as parameters and report events via lambdas.

```kotlin
// BAD — state inside leaf composable, not reusable
@Composable
fun CounterButton() {
    var count by remember { mutableIntStateOf(0) }  // state trapped inside
    Button(onClick = { count++ }) {
        Text("Count: $count")
    }
}

// GOOD — state hoisted to caller, composable is stateless
@Composable
fun CounterButton(count: Int, onIncrement: () -> Unit) {
    Button(onClick = onIncrement) {
        Text("Count: $count")
    }
}

// Caller owns state
@Composable
fun ParentScreen(viewModel: MyViewModel = hiltViewModel()) {
    val count by viewModel.count.collectAsStateWithLifecycle()
    CounterButton(count = count, onIncrement = viewModel::increment)
}
```

### 1.2 remember vs rememberSaveable

| API | Survives config change? | Use case |
|-----|------------------------|----------|
| `remember` | No | UI-only transient state (scroll position, animation state) |
| `rememberSaveable` | Yes | User input that must survive rotation (form text, selected tab) |
| `ViewModel` + `StateFlow` | Yes | Business logic state (loading, data, errors) |

```kotlin
@Composable
fun SearchScreen(viewModel: SearchViewModel = hiltViewModel()) {
    // Business state → ViewModel
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    // User input survives rotation
    var query by rememberSaveable { mutableStateOf("") }

    // Transient UI state does not need to survive
    var isSearchFocused by remember { mutableStateOf(false) }
}
```

### 1.3 Side Effects in Compose

```kotlin
// LaunchedEffect — coroutine tied to composition, restarts when key changes
@Composable
fun UserProfile(userId: String) {
    val viewModel: ProfileViewModel = hiltViewModel()

    LaunchedEffect(userId) {  // restarts when userId changes
        viewModel.loadProfile(userId)
    }
}

// DisposableEffect — cleanup when composition leaves
@Composable
fun CameraPreview() {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current

    DisposableEffect(lifecycleOwner) {
        val cameraController = LifecycleCameraController(context)
        cameraController.bindToLifecycle(lifecycleOwner)

        onDispose {
            cameraController.unbind()  // cleanup
        }
    }
}

// SideEffect — synchronize non-Compose state on each successful recomposition
@Composable
fun AnalyticsScreen(screenName: String) {
    SideEffect {
        analytics.logScreenView(screenName)  // called after every successful recomposition
    }
}

// rememberCoroutineScope — scope tied to composition, for callbacks
@Composable
fun RefreshableList(viewModel: ListViewModel = hiltViewModel()) {
    val scope = rememberCoroutineScope()

    PullToRefreshContainer(
        onRefresh = {
            scope.launch {
                viewModel.refresh()
            }
        }
    )
}
```

### 1.4 collectAsStateWithLifecycle (Mandatory)

Always use `collectAsStateWithLifecycle()` instead of `collectAsState()` for Flow/StateFlow in Compose. It respects lifecycle and pauses collection when UI is in background.

```kotlin
// BAD — collects even in background
val state by viewModel.uiState.collectAsState()

// GOOD — lifecycle-aware, pauses in background
val state by viewModel.uiState.collectAsStateWithLifecycle()

// With explicit lifecycle state (default = STARTED)
val state by viewModel.uiState.collectAsStateWithLifecycle(
    lifecycleOwner = LocalLifecycleOwner.current,
    minActiveState = Lifecycle.State.STARTED
)
```

Dependency: `androidx.lifecycle:lifecycle-runtime-compose:2.8.0+`

---

## 2. Compose Recomposition Optimization

### 2.1 Stability Annotations

```kotlin
// BAD — var properties make class unstable
data class Product(var name: String, var price: Double)

// GOOD — val + @Immutable = stable, skips unnecessary recompositions
@Immutable
data class Product(val name: String, val price: Double)

// For classes from external modules that you cannot modify
@Stable
class ExternalProductWrapper(val product: ExternalProduct)
```

### 2.2 Lambda Stability with remember

```kotlin
// BAD — new lambda reference every recomposition
ProductCard(
    product = product,
    onClick = { viewModel.onProductClick(product) }  // unstable reference
)

// GOOD — remembered lambda
val onProductClick = remember(product.id) {
    { viewModel.onProductClick(product) }
}
ProductCard(product = product, onClick = onProductClick)

// EVEN BETTER — pass ID, let ViewModel resolve
ProductCard(
    product = product,
    onClick = { viewModel.onProductClick(product.id) }  // primitive is stable
)
```

### 2.3 Key and ContentType in Lazy Lists

```kotlin
LazyColumn {
    items(
        items = products,
        key = { it.id },           // stable key for item reuse
        contentType = { it.type }  // different types don't compare
    ) { product ->
        ProductCard(product = product)
    }
}
```

---

## 3. Navigation-Compose with Type-Safe Args

### 3.1 Type-Safe Navigation (Navigation 2.8+)

```kotlin
// Define routes as @Serializable objects
@Serializable
object Home

@Serializable
data class ProductDetail(val productId: String)

@Serializable
data class Checkout(val orderId: String, val amount: Double)

// NavHost with type-safe navigation
@Composable
fun AppNavHost(navController: NavHostController) {
    NavHost(navController = navController, startDestination = Home) {
        composable<Home> {
            HomeScreen(
                onProductClick = { productId ->
                    navController.navigate(ProductDetail(productId = productId))
                }
            )
        }
        composable<ProductDetail> { backStackEntry ->
            val detail: ProductDetail = backStackEntry.toRoute()
            ProductDetailScreen(productId = detail.productId)
        }
        composable<Checkout> { backStackEntry ->
            val checkout: Checkout = backStackEntry.toRoute()
            CheckoutScreen(orderId = checkout.orderId, amount = checkout.amount)
        }
    }
}
```

### 3.2 Deep Links

```xml
<!-- AndroidManifest.xml -->
<activity android:name=".MainActivity">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https"
              android:host="example.com"
              android:pathPrefix="/product" />
    </intent-filter>
</activity>
```

```kotlin
// NavGraphBuilder
composable<ProductDetail>(
    deepLinks = listOf(
        navDeepLink<ProductDetail>(basePath = "https://example.com/product")
    )
) { ... }
```

### 3.3 Back Stack Management

```kotlin
// Navigate with popUpTo — clear back stack up to destination
navController.navigate(Checkout(orderId)) {
    popUpTo(Home) { inclusive = false }  // keep Home, remove intermediates
    launchSingleTop = true               // avoid duplicate
}

// Navigate up — respects back stack
navController.navigateUp()

// Pop back stack with result
navController.previousBackStackEntry
    ?.savedStateHandle
    ?.set("result_key", resultValue)
```

---

## 4. ViewModel and UiState Pattern

### 4.1 UiState Sealed Class

```kotlin
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Error(val message: String, val retry: () -> Unit) : UiState<Nothing>
}

@HiltViewModel
class ProductViewModel @Inject constructor(
    private val repository: ProductRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow<UiState<List<Product>>>(UiState.Loading)
    val uiState: StateFlow<UiState<List<Product>>> = _uiState.asStateFlow()

    fun loadProducts() {
        viewModelScope.launch {
            _uiState.value = UiState.Loading
            when (val result = repository.getProducts()) {
                is Result.Success -> _uiState.value = UiState.Success(result.data)
                is Result.Error -> _uiState.value = UiState.Error(
                    message = result.message,
                    retry = ::loadProducts
                )
            }
        }
    }
}
```

### 4.2 Compose UI with Exhaustive When

```kotlin
@Composable
fun ProductScreen(viewModel: ProductViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    when (val state = uiState) {
        is UiState.Loading -> LoadingIndicator()
        is UiState.Success -> ProductList(products = state.data)
        is UiState.Error -> ErrorMessage(
            message = state.message,
            onRetry = state.retry
        )
    }
}
```

### 4.3 viewModelScope Discipline

```kotlin
@HiltViewModel
class OrderViewModel @Inject constructor(
    private val repository: OrderRepository
) : ViewModel() {

    fun pollOrderStatus(orderId: String) {
        viewModelScope.launch {
            repeat(15) {  // max 30 seconds
                delay(2000)
                val status = repository.getOrderStatus(orderId)
                if (status.isTerminal) {
                    _uiState.value = OrderUiState.Completed(status)
                    return@launch  // cancel polling
                }
            }
            _uiState.value = OrderUiState.Timeout
        }
        // Automatically cancelled when ViewModel is cleared
    }

    override fun onCleared() {
        super.onCleared()
        // viewModelScope is cancelled automatically — no manual cleanup needed
    }
}
```

---

## 5. Interop: Compose in Views, Views in Compose

### 5.1 ComposeView in Fragment/Activity

```kotlin
class LegacyFragment : Fragment() {
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View = ComposeView(requireContext()).apply {
        setViewCompositionStrategy(
            ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed
        )
        setContent {
            MaterialTheme {
                ModernComposable()
            }
        }
    }
}
```

### 5.2 AndroidView in Compose

```kotlin
@Composable
fun MapViewContainer(
    latitude: Double,
    longitude: Double
) {
    val context = LocalContext.current

    AndroidView(
        factory = {
            MapView(context).apply {
                // initialize map
            }
        },
        update = { mapView ->
            mapView.moveCamera(latitude, longitude)
        },
        modifier = Modifier.fillMaxSize()
    )
}
```

---

## 6. Window Insets and Edge-to-Edge

### 6.1 Edge-to-Edge (Android 15+ mandatory)

```kotlin
// Activity.onCreate
enableEdgeToEdge()

// In Compose — use WindowInsets
@Composable
fun EdgeToEdgeScreen() {
    val insets = WindowInsets.systemBars

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(insets.asPaddingValues())
    ) {
        // Content
    }
}

// Or use Scaffold with built-in inset handling
@Composable
fun ScaffoldScreen() {
    Scaffold(
        topBar = { TopAppBar(title = { Text("Title") }) },
        contentWindowInsets = WindowInsets.systemBars
    ) { paddingValues ->
        Column(modifier = Modifier.padding(paddingValues)) {
            // Content respects insets automatically
        }
    }
}
```

### 6.2 IME Keyboard Insets

```kotlin
@Composable
fun FormScreen() {
    val imeInsets = WindowInsets.ime

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(WindowInsets.systemBars.asPaddingValues())
            .imePadding()  // adds padding when keyboard opens
    ) {
        // Form fields
    }
}
```
