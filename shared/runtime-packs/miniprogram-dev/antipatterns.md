# 小程序开发师 — Anti-Patterns

## Named Anti-Patterns

---

### Web-Import Hopes

**Definition**: Using npm packages or web APIs that depend on DOM/BOM access in the miniprogram runtime. The miniprogram environment is not a browser — `window`, `document`, `localStorage`, and `XMLHttpRequest` do not exist.

**Manifestations**:
```javascript
// BAD — axios uses XMLHttpRequest, not available in miniprogram
import axios from 'axios'; // CRASH at runtime

// BAD — DOM manipulation
const div = document.createElement('div'); // document is undefined

// BAD — localStorage
localStorage.setItem('token', token); // localStorage is undefined

// BAD — window object access
const width = window.innerWidth; // window is undefined
```

**Why it's dangerous**: The miniprogram runtime throws `ReferenceError` at the point of access. The error may not surface during development if the code path is not exercised. Users see white screens or silent failures.

**Correction**: Use wx.* APIs and miniprogram-compatible packages.

```javascript
// GOOD — wx.request for HTTP
wx.request({
  url: 'https://api.example.com/products',
  method: 'GET',
  success: (res) => { console.log(res.data); }
});

// GOOD — wx.setStorage for persistence
wx.setStorage({ key: 'token', data: token });

// GOOD — wx.getSystemInfo for screen dimensions
wx.getSystemInfo({
  success: (res) => { console.log(res.windowWidth); }
});
```

---

### Size-Limit Blindness

**Definition**: Not tracking main package size during development until WeChat DevTools upload fails with "main package exceeds 2MB limit."

**Manifestations**:
```javascript
// Developer adds 15 pages to main package without checking size
// After 3 weeks of development: upload fails at 2.3MB
// Restructuring requires moving files, updating imports, re-testing navigation
```

**Why it's dangerous**: The 2MB limit is a hard platform constraint — not a performance recommendation. A main package over 2MB cannot be uploaded. Restructuring after the fact is more expensive than planning subpackages upfront.

**Correction**: Check size after every major page addition. Set 1.8MB soft limit.

```bash
# WeChat DevTools: 详情 → 本地代码 → 查看各包大小
# Or analyze build output:
ls -la dist/build/mp-weixin/
```

---

### Subpackage Tetris

**Definition**: Assigning pages to subpackages by trial-and-error size fitting rather than route-grouped strategy. Pages from the same feature domain end up scattered across multiple subpackages.

**Manifestations**:
```json
// BAD — subpackages organized by size, not by feature
{
  "subPackages": [
    { "root": "pkg1", "pages": ["pages/order-list", "pages/settings"] },
    { "root": "pkg2", "pages": ["pages/order-detail", "pages/profile"] }
  ]
}
```

**Why it's dangerous**: Maintainability degrades. Developers cannot find related pages. Navigation logic becomes scattered. Code sharing between related pages requires moving files between subpackages.

**Correction**: Group pages by feature domain (route), not by size.

```json
// GOOD — route-grouped subpackages
{
  "subPackages": [
    { "root": "pkgs/order", "pages": ["pages/order-list", "pages/order-detail", "pages/order-track"] },
    { "root": "pkgs/user", "pages": ["pages/profile", "pages/settings", "pages/address-list"] }
  ]
}
```

---

### Token-Storage Naive

**Definition**: Storing WeChat `openid`, `session_key`, or raw WeChat credentials in client storage (`wx.setStorage`).

**Manifestations**:
```javascript
// BAD — storing sensitive WeChat credentials
wx.login({
  success: (res) => {
    wx.setStorageSync('code', res.code); // code is single-use, but still
    // Sending session_key to frontend is the real danger
  }
});
```

**Why it's dangerous**: `session_key` is a server-side secret used to decrypt user data. If leaked, an attacker can decrypt any user data (phone numbers, addresses) encrypted with that session. This is a critical security violation.

**Correction**: The login chain ends with the own-service token. Frontend stores only the JWT.

```javascript
// GOOD — correct login chain
wx.login({
  success: (res) => {
    // 1. Send code to own backend
    wx.request({
      url: 'https://api.ourservice.com/auth/wechat',
      method: 'POST',
      data: { code: res.code },
      success: (backendRes) => {
        // 2. Backend calls code2session, stores session_key
        // 3. Backend returns own-service JWT
        const token = backendRes.data.token;
        // 4. Frontend stores ONLY the JWT
        wx.setStorageSync('token', token);
      }
    });
  }
});
```

---

### Payment No-Idempotency

**Definition**: Not deduplicating WeChat payment notification callbacks. WeChat retries `notify_url` if no success response is received, causing duplicate order processing.

**Manifestations**:
```javascript
// BAD — backend processes payment notification without deduplication
// WeChat retries notify_url after 5s, 10s, 30s...
// Each retry creates a new shipment / unlocks feature again
```

**Why it's dangerous**: Duplicate payments cause inventory errors, duplicate shipments, and customer complaints. The business logic assumes each notification is a unique event.

**Correction**: Check `transaction_id` in database before processing.

```javascript
// Backend (Node.js example)
app.post('/wechat/notify', async (req, res) => {
  const { transaction_id, out_trade_no } = req.body;
  
  // Deduplication: check if already processed
  const existing = await Order.findOne({ transactionId: transaction_id });
  if (existing && existing.status === 'PAID') {
    return res.status(200).send('SUCCESS'); // Already processed
  }
  
  // Process payment
  await Order.updateOne(
    { orderNo: out_trade_no },
    { status: 'PAID', transactionId: transaction_id }
  );
  
  res.status(200).send('SUCCESS');
});
```

---

### setData Avalanche

**Definition**: Calling `setData` with large nested objects, inside loops, or in rapid succession without debouncing.

**Manifestations**:
```javascript
// BAD — setData inside loop (N IPC calls)
for (let i = 0; i < 100; i++) {
  this.setData({ [`items[${i}].loaded`]: true }); // 100 IPC calls!
}

// BAD — full state object on every keystroke
onInput(e) {
  this.data.form.email = e.detail.value;
  this.setData(this.data); // Serializes entire page state
}
```

**Why it's dangerous**: Each `setData` serializes data and sends it across the logic-to-rendering IPC boundary. Inside a loop, this causes N serializations. On large pages, a single full-state `setData` can transfer megabytes of data, causing visible frame drops.

**Correction**: Batch changes into a single object. Use diff-only paths.

```javascript
// GOOD — batch all changes into one setData
const updates = {};
for (let i = 0; i < 100; i++) {
  updates[`items[${i}].loaded`] = true;
}
this.setData(updates); // Single IPC call

// GOOD — diff-only path for form input
onInput(e) {
  this.setData({ 'form.email': e.detail.value }); // Only one field
}
```

---

### uni-app Platform Leak

**Definition**: Using WeChat-specific APIs (`wx.*`) without conditional compilation in a uni-app project that targets multiple platforms (H5, App).

**Manifestations**:
```vue
<script>
// BAD — wx.login without platform guard
export default {
  methods: {
    login() {
      wx.login({ success: (res) => { /* ... */ } }); // Crashes on H5!
    }
  }
}
</script>
```

**Why it's dangerous**: `wx.*` APIs only exist in the WeChat miniprogram runtime. On H5 or App platforms, `wx` is undefined and the code crashes.

**Correction**: Use conditional compilation or `uni.*` APIs.

```vue
<script>
export default {
  methods: {
    login() {
      // #ifdef MP-WEIXIN
      wx.login({ success: (res) => { /* ... */ } });
      // #endif
      
      // #ifdef H5
      // H5 login logic
      // #endif
      
      // #ifdef APP-PLUS
      uni.login({ provider: 'weixin', success: (res) => { /* ... */ } });
      // #endif
    }
  }
}
</script>
```
