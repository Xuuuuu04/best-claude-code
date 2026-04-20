# 跨平台移动开发师 — Output Contract Template

## Cross-Platform Mobile Implementation Output

**Task**: [Task ID] — [one-sentence description]
**Status**: READY-FOR-NEXT | BLOCKED | FAILED

**Framework**: [Flutter X.X.X (Dart X.X) / React Native X.X (Expo SDK XX / bare)]
**Target Platforms**: [iOS XX+ / Android API XX+ / Web (if applicable)]

**Changed Files**:
- `[file path]`: [what changed]

**Dependency Changes**:
- [package name]: [version] — [reason]

**Platform Divergence Register**:
| Behavior | iOS | Android | Branch Used |
|---|---|---|---|
| [e.g., Notification permission] | [Requested at launch] | [Channel creation + POST_NOTIFICATIONS] | `Platform.isIOS` / `Platform.OS` |

**Native Bridge** (if applicable):
- Bridge contract: [documented / N/A]
- iOS native side: [routed to @ios-dev with contract / N/A]
- Android native side: [routed to @android-dev with contract / N/A]

**Rebuild Storm / Re-render Self-Check**:
- Flutter const constructors: [PASS / issues found]
- RN React.memo + useCallback: [PASS / issues found]

**CI/CD Configuration**:
- Fastlane iOS lane: [CONFIGURED / PENDING / N/A]
- Fastlane Android lane: [CONFIGURED / PENDING / N/A]
- Codemagic workflow: [CONFIGURED / PENDING / N/A]

**Dual-Store Release Checklist**:
iOS: [ ] Info.plist permissions | [ ] Archive builds | [ ] TestFlight upload
Android: [ ] Manifest permissions | [ ] AAB builds | [ ] Google Play | [ ] Domestic (if applicable)

**Known Limitations / Discovered Issues**:
- [spec assumption flagged]

**Recommended Next Step**: @code-review — [review focus]

---

## Filled Example — T-055 Flutter Push with Domestic Market

```
## Cross-Platform Mobile Implementation Output

**Task**: T-055 — Push notification support with domestic Android market
**Status**: READY-FOR-NEXT

**Framework**: Flutter 3.22.0 (Dart 3.4.0)
**Target Platforms**: iOS 16+ / Android API 24+

**Changed Files**:
- `lib/services/notification_service.dart`: New — platform-neutral notification service
- `lib/providers/notification_provider.dart`: New — Riverpod provider for notification state
- `lib/widgets/notification_banner.dart`: New — const constructor banner widget
- `lib/main.dart`: Modified — notification channel init (Android), permission request (iOS)
- `android/app/src/main/AndroidManifest.xml`: Added RECEIVE_BOOT_COMPLETED, POST_NOTIFICATIONS
- `ios/Runner/Info.plist`: Added NSUserNotificationsUsageDescription

**Dependency Changes**:
- `firebase_messaging`: 14.9.3 — FCM baseline
- `huawei_push`: 6.11.0.300 — HMS Push for Huawei devices

**Platform Divergence Register**:
| Behavior | iOS | Android | Branch Used |
|---|---|---|---|
| Permission request | Request at app launch via APNs | POST_NOTIFICATIONS for API 33+; channels created in Application.onCreate | `Platform.isIOS` |
| Push provider | APNs only | FCM (GMS) + HMS (non-GMS Huawei) | `Platform.isAndroid` + vendor detection |
| Notification channels | N/A | Required for Android 8+; created 3 channels | `Platform.isAndroid` |

**Native Bridge**: N/A — firebase_messaging and huawei_push packages cover all channels

**Rebuild Storm / Re-render Self-Check**:
- Flutter const constructors: PASS — NotificationBanner uses const constructor
- RN React.memo: N/A — Flutter project

**CI/CD Configuration**:
- Fastlane iOS lane: CONFIGURED — match + gym + pilot
- Fastlane Android lane: CONFIGURED — gradle bundle + supply
- Codemagic workflow: PENDING

**Dual-Store Release Checklist**:
iOS: [x] Info.plist permissions | [x] Archive builds | [ ] TestFlight upload
Android: [x] Manifest permissions | [x] AAB builds | [ ] Google Play | [ ] Domestic stores

**Known Limitations**:
- OPPO/vivo Push SDKs not yet integrated — HMS + MiPush cover 80% of domestic market
- Codemagic workflow pending @devops configuration

**Recommended Next Step**: @code-review — review notification provider state management, platform divergence register completeness
```

---

## BLOCKED Example — BLE Bridge Required, Framework Not Confirmed

```
## Cross-Platform Mobile Implementation Output

**Task**: T-060 — Bluetooth HID health data integration
**Status**: BLOCKED

**Blocked on**: Framework not confirmed + native bridge required

**Block reasons**:
1. **Framework not specified**: Flutter or React Native? Must be confirmed before any code is written. MethodChannel vs NativeModule are incompatible.

2. **Native bridge required**: BLE HID GATT notification streams require native implementation on both platforms. No satisfactory cross-platform package exists.

**Proposed Bridge Contract** (pending framework confirmation):
```
EventChannel: com.example.app/ble_hr
Events:
  { "type": "hrReading", "deviceId": String, "bpm": Int, "timestamp": Int }
  { "type": "deviceDiscovered", "deviceId": String, "name": String, "rssi": Int }
  { "type": "connectionLost", "deviceId": String, "reason": String }

MethodChannel: com.example.app/ble_hr
Methods:
  startScan(): void
  stopScan(): void
  connectToDevice({ "deviceId": String }): { "success": Bool }
  disconnect({ "deviceId": String }): void
Errors:
  DEVICE_NOT_FOUND | CONNECTION_TIMEOUT | PERMISSION_DENIED | ALREADY_CONNECTED
```

**What I need to proceed**:
1. User confirms Flutter or React Native
2. Route bridge contract to @ios-dev (CoreBluetooth) and @android-dev (Android BLE)
3. Both native sides confirm contract is implementable
4. Begin shared layer implementation

**Do NOT begin implementing**: No code without framework confirmation. No bridge without contract approval.
```
