# 小程序开发师 — Output Contract Template

## Miniprogram Implementation Output

**Task**: [Task ID] — [one-sentence description]
**Status**: READY-FOR-NEXT | BLOCKED | FAILED
**Technical Stack**: [Native WeChat miniprogram / uni-app (targets: mp-weixin / H5 / App)]

**Package Report**:
- Main package: [X.XX MB / budget: <2MB] — [PASS / AT RISK / FAIL]
- Subpackages: [name (root): X.XX MB — page list]
- Total: [X.XX MB / budget: <20MB]

**Changed Files**:
- `[path]`: [description]

**WeChat Ecosystem Integration**:
- Login: [integrated / N/A]
- Payment: [integrated / N/A]
- Cloud functions: [list / N/A]

**Security Checklist**:
- session_key storage: [backend-only / N/A]
- Payment confirmation: [backend callback dependent / N/A]
- Privacy popup: [implemented / N/A]
- Domain whitelist: [domains added / no new domains]

**Self-Test Results**:
- Happy path: [PASS / FAIL]
- Error path: [PASS / FAIL]
- Edge case: [description + result]

**Known Limitations / Discovered Issues**:
- [spec assumption flagged]

**Next Step**: @code-review ([focus]) + @test-func ([key test scenarios])

---

## Filled Example — T-030 WeChat Payment Flow

```
## Miniprogram Implementation Output

**Task**: T-030 — WeChat Pay checkout on order page
**Status**: READY-FOR-NEXT
**Technical Stack**: Native WeChat miniprogram

**Package Report**:
- Main package: 1.61 MB / budget: <2MB — PASS
- Subpackages: pkgs/order (0.84 MB — order-list, order-detail, payment-result)
- Total: 2.45 MB / budget: <20MB — PASS

**Changed Files**:
- `pkgs/order/pages/payment-result/payment-result.wxml`: New — payment status display
- `pkgs/order/pages/payment-result/payment-result.wxss`: New — payment result styles
- `pkgs/order/pages/payment-result/payment-result.js`: New — payment status logic + polling
- `pkgs/order/pages/payment-result/payment-result.json`: New — page config
- `pkgs/order/pages/checkout/checkout.js`: Modified — integrated payment flow
- `app.json`: Modified — added payment-result to pkgs/order subPackages

**WeChat Ecosystem Integration**:
- Login: N/A
- Payment: INTEGRATED — wx.requestPayment with backend callback confirmation
- Cloud functions: N/A

**Security Checklist**:
- session_key storage: N/A (not touched)
- Payment confirmation: backend callback dependent (not wx.requestPayment success)
- Privacy popup: N/A (no new data collection in checkout)
- Domain whitelist: api.ourservice.com already registered

**Self-Test Results**:
- Happy path: PASS — payment completes, polls backend, navigates to success
- Error path: PASS — network error shows retry button
- Edge case: PASS — double-tap prevention works, cancel callback handled

**Known Limitations**:
- Scheme does not specify timeout for payment status polling — implemented 30s max with 2s interval
- Order retry logic not specified — implemented single retry

**Next Step**: @code-review (focus: payment idempotency, poll cleanup in onUnload) + @test-func (test: payment success, cancel, timeout, double-tap)
```

---

## BLOCKED Example — Missing Backend Payment Callback

```
## Miniprogram Implementation Output

**Task**: T-031 — Subscription payment with WeChat Pay
**Status**: BLOCKED

**Blocked on**: Backend payment callback endpoint not ready + incorrect payment confirmation design

**Block reasons**:
1. **Backend payment callback endpoint not ready**: wx.requestPayment success callback fires when the user completes the WeChat Pay UI flow — it does NOT confirm that money was transferred. The only authoritative confirmation is WeChat's server-to-backend notification at the configured notify_url. Calling POST /subscriptions/activate from the wx.requestPayment success callback is architecturally incorrect.

2. **Frontend-only payment confirmation is a security defect**: Even if the backend endpoint exists, "activate on wx.requestPayment success" violates WeChat Pay integration requirements. The server-side payment notification must trigger business logic activation.

**What I need to proceed**:
1. Backend implements notify_url endpoint that receives and validates WeChat payment notification
2. Backend implements GET /subscriptions/{id}/status that returns PAID only after notification is validated
3. @dev-lead confirms the revised flow: frontend polls status, not calls activate directly

**Do NOT begin implementing**: No payment integration without backend callback. No "temporary" frontend-only confirmation.
```
