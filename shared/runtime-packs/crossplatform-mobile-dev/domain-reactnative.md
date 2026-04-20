# Cross-Platform Domain — React Native (New Architecture, State Management, Native Modules)

## 1. New Architecture (Fabric + TurboModules)

### 1.1 TurboModules via Codegen

```typescript
// Spec definition: src/specs/NativeCalculator.ts
import type { TurboModule } from 'react-native/Libraries/TurboModule/RCTExport';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  add(a: number, b: number): Promise<number>;
  getConstants(): { PI: number };
}

export default TurboModuleRegistry.getEnforcing<Spec>('NativeCalculator');
```

```objc
// iOS implementation: NativeCalculator.mm
#import "NativeCalculator.h"
#import <React/RCTUtils.h>

@interface NativeCalculator () <NativeCalculatorSpec>
@end

@implementation NativeCalculator

RCT_EXPORT_MODULE(NativeCalculator)

- (NSNumber *)add:(double)a b:(double)b {
  return @(a + b);
}

- (NSDictionary *)getConstants {
  return @{ @"PI": @3.14159 };
}

- (std::shared_ptr<TurboModule>)getTurboModule:(const ObjCTurboModule::InitParams &)params {
  return std::make_shared<NativeCalculatorSpecJSI>(params);
}

@end
```

```kotlin
// Android implementation: NativeCalculatorModule.kt
class NativeCalculatorModule(reactContext: ReactApplicationContext) :
    NativeCalculatorSpec(reactContext) {

    override fun getName() = "NativeCalculator"

    override fun add(a: Double, b: Double, promise: Promise) {
        promise.resolve(a + b)
    }

    override fun getTypedExportedConstants(): Map<String, Any> {
        return mapOf("PI" to 3.14159)
    }
}
```

### 1.2 Reanimated 3 Worklets

```typescript
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
  withSequence,
  runOnJS,
} from 'react-native-reanimated';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';

function DraggableCard({ onSwipeComplete }: { onSwipeComplete: () => void }) {
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);
  const context = useSharedValue({ x: 0, y: 0 });

  const gesture = Gesture.Pan()
    .onStart(() => {
      context.value = { x: translateX.value, y: translateY.value };
    })
    .onUpdate((event) => {
      // Runs on UI thread via worklet
      translateX.value = context.value.x + event.translationX;
      translateY.value = context.value.y + event.translationY;
    })
    .onEnd((event) => {
      if (Math.abs(event.translationX) > 150) {
        translateX.value = withSpring(event.translationX > 0 ? 500 : -500);
        runOnJS(onSwipeComplete)(); // Callback to JS thread
      } else {
        translateX.value = withSpring(0);
        translateY.value = withSpring(0);
      }
    });

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [
      { translateX: translateX.value },
      { translateY: translateY.value },
    ],
  }));

  return (
    <GestureDetector gesture={gesture}>
      <Animated.View style={[styles.card, animatedStyle]}>
        {/* Card content */}
      </Animated.View>
    </GestureDetector>
  );
}
```

---

## 2. State Management

### 2.1 Redux Toolkit with RTK Query

```typescript
// API slice
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';

export const productsApi = createApi({
  reducerPath: 'productsApi',
  baseQuery: fetchBaseQuery({
    baseUrl: 'https://api.example.com/',
    prepareHeaders: (headers, { getState }) => {
      const token = (getState() as RootState).auth.token;
      if (token) headers.set('authorization', `Bearer ${token}`);
      return headers;
    },
  }),
  tagTypes: ['Product'],
  endpoints: (builder) => ({
    getProducts: builder.query<Product[], void>({
      query: () => 'products',
      providesTags: ['Product'],
    }),
    addProduct: builder.mutation<Product, Partial<Product>>({
      query: (body) => ({
        url: 'products',
        method: 'POST',
        body,
      }),
      invalidatesTags: ['Product'],
    }),
  }),
});

export const { useGetProductsQuery, useAddProductMutation } = productsApi;

// Store configuration
import { configureStore } from '@reduxjs/toolkit';

export const store = configureStore({
  reducer: {
    [productsApi.reducerPath]: productsApi.reducer,
    auth: authReducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware().concat(productsApi.middleware),
});

// Component usage
function ProductList() {
  const { data: products, isLoading, error } = useGetProductsQuery();
  const [addProduct] = useAddProductMutation();

  if (isLoading) return <ActivityIndicator />;
  if (error) return <Text>Error loading products</Text>;

  return (
    <FlatList
      data={products}
      renderItem={({ item }) => <ProductCard product={item} />}
    />
  );
}
```

### 2.2 Zustand for Client State

```typescript
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { MMKV } from 'react-native-mmkv';

const storage = new MMKV();

interface AuthState {
  token: string | null;
  user: User | null;
  isAuthenticated: boolean;
  setToken: (token: string) => void;
  setUser: (user: User) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      isAuthenticated: false,
      setToken: (token) => set({ token, isAuthenticated: true }),
      setUser: (user) => set({ user }),
      logout: () => set({ token: null, user: null, isAuthenticated: false }),
    }),
    {
      name: 'auth-storage',
      storage: createJSONStorage(() => ({
        getItem: (name) => storage.getString(name) ?? null,
        setItem: (name, value) => storage.set(name, value),
        removeItem: (name) => storage.delete(name),
      })),
    }
  )
);
```

---

## 3. Native Bridge Development

### 3.1 NativeEventEmitter Pattern

```typescript
// JS side
import { NativeEventEmitter, NativeModules } from 'react-native';
import { useEffect, useRef } from 'react';

const { BLEModule } = NativeModules;
const bleEmitter = new NativeEventEmitter(BLEModule);

export function useBLEScanner() {
  const [devices, setDevices] = useState<BLEDevice[]>([]);
  const subscriptionRef = useRef<ReturnType<typeof bleEmitter.addListener>>();

  useEffect(() => {
    subscriptionRef.current = bleEmitter.addListener(
      'onDeviceDiscovered',
      (device: BLEDevice) => {
        setDevices((prev) => [...prev, device]);
      }
    );

    BLEModule.startScan();

    return () => {
      subscriptionRef.current?.remove();
      BLEModule.stopScan();
    };
  }, []);

  return devices;
}
```

### 3.2 When to Bridge vs When Not To

| Bridge Required | Don't Bridge |
|----------------|-------------|
| CameraX full pipeline | HTTP requests (use fetch/axios) |
| ARKit / ARCore | Local storage (use MMKV/AsyncStorage) |
| Vendor push SDK (HMS/MiPush) | Standard push (use react-native-firebase) |
| Device attestation | Navigation (use React Navigation) |
| System-level Bluetooth HID | Standard animations (use Reanimated) |
| Custom hardware integration | Form handling (use React Hook Form) |

---

## 4. CI/CD and Release

### 4.1 Fastfile Dual-Store Configuration

```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Build and upload to TestFlight"
  lane :beta do
    setup_ci if ENV['CI']
    
    match(
      type: "appstore",
      readonly: is_ci
    )
    
    increment_build_number(xcodeproj: "MyApp.xcodeproj")
    
    build_app(
      workspace: "MyApp.xcworkspace",
      scheme: "MyApp",
      export_method: "app-store"
    )
    
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      notify_external_testers: false
    )
  end
end

platform :android do
  desc "Build and upload to Google Play"
  lane :beta do
    gradle(
      task: "bundle",
      build_type: "Release",
      project_dir: "android/"
    )
    
    upload_to_play_store(
      track: "internal",
      aab: "android/app/build/outputs/bundle/release/app-release.aab"
    )
  end

  desc "Build APKs for domestic stores"
  lane :domestic do
    gradle(
      task: "assemble",
      build_type: "Release",
      flavor: "domestic",
      project_dir: "android/"
    )
    # Upload to 华为, 小米, OPPO, vivo, 应用宝 separately
  end
end
```

### 4.2 Codemagic Configuration

```yaml
# codemagic.yaml
workflows:
  ios-android-workflow:
    name: iOS & Android Build
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
    scripts:
      - name: Get Flutter packages
        script: flutter packages pub get
      - name: Flutter analyze
        script: flutter analyze
      - name: Run tests
        script: flutter test
      - name: Build iOS
        script: flutter build ios --release --no-codesign
      - name: Build Android
        script: flutter build appbundle --release
    artifacts:
      - build/ios/ipa/*.ipa
      - build/app/outputs/bundle/release/*.aab
    publishing:
      app_store_connect:
        api_key: $APP_STORE_CONNECT_KEY
        key_id: $APP_STORE_CONNECT_KEY_ID
        issuer_id: $APP_STORE_CONNECT_ISSUER_ID
      google_play:
        credentials: $GOOGLE_PLAY_CREDENTIALS
        track: internal
```
