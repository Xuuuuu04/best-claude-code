# 鸿蒙开发师 — Output Contract Template

## HarmonyOS Implementation Delivery

**Task**: [One-sentence description]
**API Level Target**: [e.g., API 11 (HarmonyOS 4.2)]
**Device Type**: [phone / tablet / watch / car / PC / multi-device]
**Application Model**: [Stage / FA (legacy)]

**Primary Files Changed**:
- `[ets/entryability/AbilityStage.ts — HMS init]`
- `[ets/pages/ProfilePage.ets — UI component]`
- `[entry/module.json5 — permission declarations]`
- `[entry/oh-package.json5 — new dependencies]`

**Permission Declarations (module.json5)**:
- `ohos.permission.INTERNET` (install-time)
- `ohos.permission.LOCATION` (runtime, user-facing rationale required)

**HMS Kit Dependencies (oh-package.json5)**:
- `@hw-agconnect/push: ^1.4.0`
- `@hw-agconnect/auth: ^1.4.0`

**Distributed Capability Used**: [None / List APIs]

**Atomic Service Size Budget**: [N/A / Current: X.X MB / Limit: 10 MB / Status: PASS|FAIL]

**Test Coverage**: [hypium file paths or "pending"]

**Known Limitations / Discovered Issues**:
- [spec assumption flagged]

**Recommended Next Step**: [code-auditor / security-auditor / backend / devops]

---

## Filled Example — Push Notification Opt-In with Account Kit

```
## HarmonyOS Implementation Delivery

**Task**: Implement push notification opt-in flow with HMS Account Kit silent sign-in on app first launch
**API Level Target**: API 11 (HarmonyOS 4.2)
**Device Type**: phone
**Application Model**: Stage

**Primary Files Changed**:
- ets/entryability/AppAbilityStage.ets — AGConnect init + push token registration
- ets/entryability/EntryAbility.ets — first-launch detection, sign-in trigger
- ets/pages/OnboardingPage.ets — notification permission rationale UI
- entry/module.json5 — INTERNET + GET_BUNDLE_INFO permissions
- entry/oh-package.json5 — @hw-agconnect/push ^1.4.0, @hw-agconnect/auth ^1.4.0

**Permission Declarations (module.json5)**:
- ohos.permission.INTERNET (install-time)
- ohos.permission.GET_BUNDLE_INFO (install-time, required by HMS Auth)

**HMS Kit Dependencies (oh-package.json5)**:
- @hw-agconnect/push: ^1.4.0
- @hw-agconnect/auth: ^1.4.0

**Distributed Capability Used**: None

**Atomic Service Size Budget**: N/A (standard app, not atomic service)

**Test Coverage**: ets/test/OnboardingTest.ets (hypium, 3 cases: silent sign-in success, sign-in fallback, push token failure)

**Known Limitations**:
- HMS Pay sandbox not testable on emulator — requires physical device
- Scheme does not specify notification channel importance levels — implemented HIGH for order updates, DEFAULT for messages

**Recommended Next Step**: backend — Push Kit server-side token registration endpoint; security-auditor — Account Kit token storage review
```

---

## BLOCKED Example — Android Port + GMS Dependency

```
## HarmonyOS Implementation Delivery

**Task**: Port Android push notification module to HarmonyOS
**Status**: BLOCKED

**Blocked on**: Three separate issues require resolution

**Block 1 — "Port" assumption is incorrect**:
HarmonyOS NEXT is not Android. ArkTS is not Kotlin/Java. There is no Android runtime on HarmonyOS NEXT — no AOSP, no APK, no JVM. Android code cannot be "ported" — it must be rewritten from scratch in ArkTS using HarmonyOS Stage Model APIs.

**Block 2 — FCM does not exist on HarmonyOS NEXT**:
Firebase Cloud Messaging (FCM) is a Google service that runs on Google Mobile Services (GMS). HarmonyOS NEXT has no GMS layer — Firebase is completely unavailable. The replacement is HMS Push Kit, which requires:
- HMS Push API v3 server endpoint (different from FCM)
- AGConnect project setup in AppGallery Connect
- Backend push sending integration update by @backend

**Block 3 — play-services-maps does not exist**:
Google Maps SDK is not available on HarmonyOS NEXT. The replacement is HMS Map Kit, requiring UI component changes and API call changes.

**What I need to proceed**:
1. @dev-lead confirms full rewrite (not port) is authorized
2. @backend confirms they will update push sending server to use HMS Push API v3
3. @dev-lead confirms HMS Map Kit as the replacement

**Do NOT begin implementing**: No speculative code while blocked. No Android-to-ArkTS translation drafts.
```
