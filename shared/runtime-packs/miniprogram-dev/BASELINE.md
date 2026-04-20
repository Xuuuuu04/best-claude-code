# 小程序开发师 — Baseline Scenarios

## Scenario 1: WeChat Payment Flow Implementation (Canonical)

**Input**:
- @dev-lead scheme: "Implement WeChat Pay checkout on the order page. User taps 'Pay Now', backend creates an order and returns signed pay parameters, frontend calls wx.requestPayment. On success, navigate to order-success page. Backend has a configured notify_url that receives WeChat's payment notification. Orders table uses field `status` (PENDING/PAID/CANCELLED). Subpackage: pkgs/order. Main package currently 1.54 MB."

**Expected Output Structure**:
- Confirm environment prerequisites before any code:
  - Domain whitelist: confirm api.ourservice.com is registered for wx.request
  - Backend payment callback endpoint confirmed ready (notify_url)
  - Privacy popup: N/A (no new data collection in checkout)
  - AppID configured: confirm

- Subpackage architecture check: main package at 1.54 MB — safe. New payment-result page goes into pkgs/order subpackage (not main package). Main package stays under 2MB.

- Implementation in strict order:
  1. Add payment-result page files (WXML + WXSS + JS + JSON) to pkgs/order/pages/
  2. Update app.json: add payment-result to pkgs/order subPackages.pages
  3. Implement checkout.js: createOrder() → POST /orders/create, initiatePayment() → wx.requestPayment, pollOrderStatus() → GET /orders/{id}/status every 2s for max 30s

- Critical payment implementation pattern:
  - wx.requestPayment success callback: `this.setData({ paymentStatus: 'processing' })` + start polling
  - wx.requestPayment fail callback: `this.setData({ paymentStatus: 'cancelled' })` — do NOT cancel the order server-side
  - Order status confirmation comes from polling own backend only, not from wx.requestPayment callback

- setData discipline: only diff fields, never full state — `this.setData({ paymentStatus: 'processing' })` not `this.setData(this.data)`

- Security checklist:
  - session_key: N/A (not touched)
  - Payment confirmation: backend callback dependent (not wx.requestPayment success)
  - Privacy popup: N/A (no new data collection)
  - Domain whitelist: api.ourservice.com already registered

- Self-test results covering: happy path, cancel path, double-tap prevention

- Package report: main package 1.61 MB (PASS), pkgs/order 0.84 MB (PASS), total 2.45 MB (PASS)

- Next steps: @code-review (focus: payment idempotency, poll cleanup in onUnload) + @test-func (test: payment success, cancel, timeout, double-tap)

**Key Decision Points**:
- wx.requestPayment success = display only — this is the most critical correctness decision in the payment flow
- Payment-result page placed in subpackage (not main) — maintains package budget discipline
- Double-tap prevention via button disable after first tap — idempotency at the UI level
- Poll timeout (30s) + fallback message — handles delayed WeChat notification delivery
- fail callback does NOT cancel the order — user may retry; only the backend or user explicit cancel should change order status

---

## Scenario 2: BLOCKED — Payment Integration Without Backend Callback

**Input**:
- @dev-lead: "Implement WeChat payment for the subscription page. The backend isn't ready yet — just do the frontend part. On wx.requestPayment success, call POST /subscriptions/activate to activate the subscription."

**Expected Output Structure**:

**BLOCKED — two conditions prevent safe payment integration:**

**Block 1 — Backend payment callback endpoint not ready:**
"wx.requestPayment success callback fires when the user completes the WeChat Pay UI flow — it does NOT confirm that money was transferred. The only authoritative confirmation is WeChat's server-to-backend notification at the configured notify_url. Calling POST /subscriptions/activate from the wx.requestPayment success callback is architecturally incorrect: a user could potentially trigger subscription activation without actual payment (e.g., by intercepting or replaying the callback). I cannot implement payment integration safely until:
1. Backend has a configured notify_url endpoint that receives WeChat's payment notification
2. Backend has POST /subscriptions/activate guarded by actual payment verification (checking WeChat notification was received)
3. Frontend can poll GET /subscriptions/{id}/status to detect backend-confirmed activation"

**Block 2 — Frontend-only payment confirmation is a security defect:**
"Even if the backend endpoint exists as a simple HTTP call, 'activate on wx.requestPayment success' is a WeChat Pay integration requirement violation. WeChat's official documentation states that business logic activation must be triggered by the server-side payment notification, not by the client callback. Activating based on client callback alone creates a race condition (callback may arrive before WeChat notification) and a security hole (callback can be triggered without payment in certain attack scenarios)."

**Status**: BLOCKED
**Unblock conditions**:
1. Backend implements notify_url endpoint that receives and validates WeChat payment notification
2. Backend implements GET /subscriptions/{id}/status that returns PAID only after notification is validated
3. @dev-lead confirms the revised flow: frontend polls status, not calls activate directly

**Key Decision Points**:
- Two distinct block conditions — not collapsed into "we need the backend first"
- Block 1 is architectural (missing component) — routes to @dev-lead and @backend
- Block 2 is security (incorrect design even if built) — routes to @dev-lead for scheme revision
- No "here's a temporary implementation" draft offered — dangerous patterns are not provided as starters

---

## Scenario 3: setData Performance Optimization + Main Package Over Budget

**Input**:
- @dev-lead: "The product list page is laggy when scrolling. Users say it freezes when tapping items. Also, we just tried to upload to WeChat DevTools and got 'main package size limit exceeded' — we're at 2.3 MB."

**Expected Output Structure**:

**Part A — setData Performance Investigation**

1. Instrument first: use WeChat DevTools Timeline to confirm setData is the bottleneck before changing code

2. Grep for all setData calls in the product list page: `setData\(` — audit each call

3. Diagnosis (typical finding): product list toggleSelected handler is passing the full list:
   ```javascript
   // FOUND (BAD): serializes all 80+ items on every tap
   toggleSelected(e) {
     const items = this.data.items;
     items[e.currentTarget.dataset.index].selected = !items[...].selected;
     this.setData({ items });  // 80+ items serialized every tap
   }
   ```

4. Fix (diff-only setData):
   ```javascript
   // CORRECT: serializes only the one changed boolean
   toggleSelected(e) {
     const index = e.currentTarget.dataset.index;
     this.setData({
       [`items[${index}].selected`]: !this.data.items[index].selected
     });
   }
   ```
   The fix reduces IPC transfer from ~80 serialized objects to 1 boolean. Visible lag should disappear.

5. Additional audit: if list length > 100 items, recommend `<recycle-view>` or virtual scroll implementation

**Part B — Main Package Over Budget (2.3 MB)**

1. Run WeChat DevTools build analysis: "详情 → 本地代码" → identify largest items

2. Typical findings:
   - 3 feature pages in main package that belong in subpackages
   - 1 large npm library (e.g., moment.js, 270 KB) imported fully instead of tree-shaken

3. Restructuring plan:
   - Move product-list, product-detail, category pages → pkgs/product subpackage
   - Move order-related pages → pkgs/order subpackage (if not already there)
   - Replace `import moment from 'moment'` with `import dayjs from 'dayjs'` (only 2 KB) or date-fns individual functions

4. Size estimate after restructure: main package drops from 2.3 MB to ~1.5 MB; all feature pages in route-grouped subpackages

5. Verify: after restructure, run build and check "详情 → 本地代码" to confirm < 2MB before attempting upload

**Key Decision Points**:
- Instrument before fix — WeChat DevTools Timeline provides the before/after measurement
- Diff-only setData is not a style preference — it is a 50× performance difference on large lists
- Size restructure is route-grouped (by feature domain), not size-tetris (fitting pages wherever they fit)
- The 2MB limit cannot be uploaded — this blocks release, not just degrades performance
- moment.js example: one library decision can cost 270 KB of main package budget
