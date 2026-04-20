# iOS 开发师 — Baseline Scenarios

## Scenario 1: Push Notification Opt-In Flow (Canonical)

**Input**:
- @dev-lead scheme: "Implement push notification opt-in flow. New `NotificationPermissionView` SwiftUI view presenting permission rationale. New `NotificationService` with `requestAuthorization()`, `registerForRemoteNotifications()`, `sendTokenToBackend()`. Token registration endpoint: POST /devices/{id}/push-token. Triggered on second app launch."
- Existing project: @MainActor ObservableObject ViewModels, URLSession async/await, Keychain for auth token.

**Expected Output Structure**:
- Check prerequisites first: Push Notifications capability in Xcode target? YES — add if missing. `NSUserTrackingUsageDescription` — N/A (not IDFA). APNs key in App Store Connect — PENDING (flag for @devops).
- Implement in layer order: NotificationService (`async throws` functions, no UI dependencies) → NotificationPermissionViewModel (`@MainActor @Published` properties, calls NotificationService) → NotificationPermissionView (SwiftUI, `task(id:)` for async trigger)
- Concurrency: `requestAuthorization` uses `withCheckedThrowingContinuation` to bridge the completion handler to async/await; `sendTokenToBackend()` is `async throws`, called via `Task {}` in ViewModel on `@MainActor` — `await` crosses actor boundary to URLSession
- Token hex conversion: convert `Data` to hex string via `data.map { String(format: "%02.2hhx", $0) }.joined()`
- Retain cycles: all `Task {}` closures use `[weak self]`
- Security: APNs token is not sensitive (only sent to own backend) — UserDefaults acceptable for prompt timing; auth token itself stays in Keychain
- Privacy manifest: `PrivacyInfo.xcprivacy` updated with UserDefaults access reason for prompt timing storage
- Build: zero errors, zero warnings
- Unit tests: testTokenRegistrationCallsBackend, testPermissionDeniedStatePublished, testTokenHexConversion
- App Store readiness: APNs key (.p8) PENDING — flag to @devops for generation in App Store Connect; distribution provisioning profile requires regeneration after Push Notifications capability addition
- Next step: @code-review — review NotificationService async patterns, APNs token hex conversion, permission prompt timing logic

**Key Decision Points**:
- `withCheckedThrowingContinuation` used to bridge legacy callback API — not wrapping with `Task.detached` (not CPU-intensive)
- `sendTokenToBackend()` runs off main actor via `await` — not blocking main thread
- Provisioning profile regeneration requirement flagged to @devops — not hidden in handoff
- No force-unwrap in token hex conversion

---

## Scenario 2: BLOCKED — Missing Entitlements + Scheme Gap

**Input**:
- User: "implement background location tracking for the delivery app"
- No technical scheme provided, no existing entitlement configuration found in project

**Expected Output Structure**:
- Status: BLOCKED — multiple prerequisites unavailable before implementation can begin
- Block reason 1: "No technical scheme — background location tracking requires @dev-lead to define: (1) what triggers location collection (app launch / explicit user action / geofence entry), (2) location accuracy required (`kCLLocationAccuracyBest` or reduced for battery), (3) how location data is sent to backend (polling / streaming / upload on foreground), (4) what happens when location permission is denied"
- Block reason 2: "Background location entitlement requires explicit App Store review justification and a documented user-visible reason. @dev-lead must confirm this is in scope and provide the justification before I add the entitlement to the project"
- Block reason 3: "Missing required Info.plist keys: `NSLocationWhenInUseUsageDescription` (required for all location) AND `NSLocationAlwaysAndWhenInUseUsageDescription` (required for background location). These strings must be written by someone with authority on user-facing copy — route to @creative or @client for copy, or @dev-lead to provide placeholder text"
- Do NOT add background location entitlement speculatively
- Do NOT implement any location logic without the scheme

**Key Decision Points**:
- BLOCK fires before any entitlement is added to the project
- Three specific blocks identified separately — each blocks a different implementation decision
- Background location entitlement is flagged as requiring App Store justification — this is a rejection risk if not handled correctly
- Info.plist usage description strings require copy authority — not invented by the developer

---

## Scenario 3: Bug Fix — Retain Cycle in Payment Flow

**Input**:
- @test-func: "POST-DELIVERY BUG: Memory grows continuously during the payment flow. Each payment attempt adds ~2MB to memory and it is never released. Reproduction: start payment flow, complete 3 payments without navigating away, observe Instruments memory graph showing `PaymentViewController` instances not being deallocated."
- Source: `PaymentViewController` holds a strong reference to `PaymentViewModel`; `PaymentViewModel.processPayment()` closure captures `self` (PaymentViewController) strongly in a URLSession completion handler

**Expected Output Structure**:
- Reproduce: confirmed via Instruments Memory Graph — 3 `PaymentViewController` instances alive simultaneously after 3 payment completions; each holds `PaymentViewModel` which holds a reference back to `PaymentViewController` via the closure
- Root cause: `URLSession.shared.dataTask(with: request) { [self] data, response, error in self.handleResult(data) }` — strong capture of `self` in an escaping closure. URLSession holds the closure until completion. `PaymentViewModel` holds the closure. `PaymentViewController` holds `PaymentViewModel`. Retain cycle.
- Evaluate scope: implementation-only fix — change closure capture to `[weak self]`
- Implement minimum fix:
  ```swift
  URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      guard let self else { return }
      self.handleResult(data)
  }.resume()
  ```
- Alternative: if this code can be modernized, replacing the `dataTask` with `async`/`await` (`URLSession.data(for: request)`) eliminates the closure entirely and removes the retain cycle by design — recommend as follow-up modernization task to @dev-lead
- Verify: Instruments Memory Graph after fix shows `PaymentViewController` deallocated after navigation away from payment screen
- Next step: @code-review — review that `[weak self]` is applied to all other URLSession completion closures in the same file

**Key Decision Points**:
- Identifies retain cycle via Instruments Memory Graph — not just from reading the code
- Minimum fix applied: only the offending closure capture changed
- Modernization to async/await proposed as a SEPARATE follow-up task — not bundled into the bug fix
- Instruments verification is specific and observable: Memory Graph shows deallocation after fix
