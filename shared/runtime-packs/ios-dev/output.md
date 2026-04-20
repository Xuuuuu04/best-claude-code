# iOS 开发师 — Output Contract Template

## iOS Implementation Output

**Task**: [Task ID] — [one-sentence description]
**Status**: READY-FOR-NEXT | BLOCKED | FAILED

**Changed Files**:
- `[file path]`: [what changed — new file / modified / deleted]

**Xcode Project Impact**:
- New capabilities: [Push Notifications / Background Location / In-App Purchase / etc.]
- New entitlements: [entitlement name + value]
- New Info.plist keys: [key + value]
- Deployment target change: [from X to Y — reason]
- SPM dependencies added: [package name + version]

---

**Concurrency Self-Check**:
- Main-thread I/O: [NONE detected / FIXED — see below]
- Task [weak self] captures: [PASS — all escaping closures use weak self]
- Actor boundary crossings: [PASS — all async ops cross with await]
- URLSession async/await usage: [PASS / N/A]

**Memory Management Self-Check**:
- Escaping closure [weak self]: [PASS — verified in all completion handlers]
- NotificationCenter observers: [PASS — removed in deinit / cancellables stored]
- Instruments retain cycle check: [PASS / NOT RUN — reason]
- Timer invalidation: [PASS — invalidated in deinit / N/A]

**Security Self-Check**:
- Keychain for secrets: [PASS / N/A]
- ATT consent before IDFA: [PASS / N/A]
- ATS compliance (no arbitrary loads): [PASS]
- No hardcoded credentials: [PASS]
- Privacy manifest (PrivacyInfo.xcprivacy): [PASS — updated / N/A]

**Build Status**:
- Clean build: [PASS — 0 errors, 0 warnings]
- Unit tests: [PASS — X tests, X new tests / N/A]

**App Store Submission Readiness** (if release-relevant):
- Bundle ID: [verified]
- Provisioning profile: [development / ad-hoc / app-store]
- Required capabilities: [list]
- App Store Connect alignment: [verified / pending]

**Known Limitations / Discovered Issues**:
- [spec assumption flagged — e.g., "scheme does not specify error state for network timeout"]
- [out-of-scope issue discovered — logged as future task, not touched]

**Recommended Next Step**: @code-review — [specific focus]

---

## Filled Example — T-041 Push Notification Opt-In

```
## iOS Implementation Output

**Task**: T-041 — Push notification opt-in flow with APNs token registration
**Status**: READY-FOR-NEXT

**Changed Files**:
- `Sources/Notifications/NotificationPermissionView.swift`: New SwiftUI view — permission rationale
- `Sources/Notifications/NotificationService.swift`: New service — requestAuthorization, registerForRemoteNotifications, sendTokenToBackend
- `Sources/Notifications/NotificationViewModel.swift`: New @MainActor ObservableObject
- `Info.plist`: Added NSUserNotificationsUsageDescription
- `App.entitlements`: Added aps-environment development
- `PrivacyInfo.xcprivacy`: Added UserDefaults access reason for prompt timing

**Xcode Project Impact**:
- New capabilities: Push Notifications
- New entitlements: aps-environment = development
- New Info.plist keys: NSUserNotificationsUsageDescription = "We use notifications to alert you about order updates and messages."
- Deployment target: unchanged (iOS 16.0)
- SPM dependencies: none

**Concurrency Self-Check**:
- Main-thread I/O: NONE — all network in NotificationService async/await
- Task [weak self] captures: PASS — all Task closures use [weak self]
- Actor boundary crossings: PASS — URLSession.data(for:) crosses off main actor
- URLSession async/await: PASS

**Memory Management Self-Check**:
- Escaping closure [weak self]: PASS
- NotificationCenter observers: N/A
- Instruments retain cycle check: NOT RUN — no complex ownership chains
- Timer invalidation: N/A

**Security Self-Check**:
- Keychain for secrets: PASS — auth token in Keychain (existing)
- ATT consent: N/A — not collecting IDFA
- ATS compliance: PASS — HTTPS only
- No hardcoded credentials: PASS
- Privacy manifest: PASS — PrivacyInfo.xcprivacy updated with UserDefaults reason

**Build Status**:
- Clean build: PASS — 0 errors, 0 warnings
- Unit tests: PASS — 3 new tests (testTokenRegistration, testPermissionDenied, testTokenHexConversion)

**App Store Submission Readiness**:
- Bundle ID: com.example.app (verified)
- Provisioning profile: needs regeneration after Push capability addition — flagged to @devops
- Required capabilities: Push Notifications (added)
- App Store Connect: APNs key (.p8) PENDING — flagged to @devops

**Known Limitations**:
- Scheme does not specify notification permission prompt timing — implemented on second app launch
- APNs key generation in App Store Connect pending @devops

**Recommended Next Step**: @code-review — review NotificationService async patterns, APNs token hex conversion, permission prompt timing logic
```

---

## BLOCKED Example — Missing Entitlements + Background Location

```
## iOS Implementation Output

**Task**: T-048 — Background location tracking for delivery app
**Status**: BLOCKED

**Blocked on**: Technical scheme incomplete + missing entitlements

**Block reasons**:
1. **Missing technical scheme**: Background location tracking requires @dev-lead to define:
   - What triggers location collection (app launch / explicit user action / geofence entry)
   - Location accuracy required (kCLLocationAccuracyBest or reduced for battery)
   - How location data is sent to backend (polling / streaming / upload on foreground)
   - What happens when location permission is denied

2. **Missing background location entitlement justification**: Background location entitlement requires explicit App Store review justification and a documented user-visible reason. @dev-lead must confirm this is in scope.

3. **Missing required Info.plist keys**:
   - NSLocationWhenInUseUsageDescription (required for all location)
   - NSLocationAlwaysAndWhenInUseUsageDescription (required for background location)
   These strings must be written by someone with authority on user-facing copy.

**What I need to proceed**:
1. @dev-lead to provide complete technical scheme for background location
2. @dev-lead to confirm App Store justification is prepared
3. @creative or @client to provide usage description strings

**Do NOT begin implementing**: No location logic without scheme. No entitlement addition without justification.
```
