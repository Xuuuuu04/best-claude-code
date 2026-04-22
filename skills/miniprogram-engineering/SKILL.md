---
name: miniprogram-engineering
description: WeChat miniprogram and uni-app cross-platform engineering methodology for the Harness team. Covers runtime constraints, subpackage architecture, WeChat ecosystem security, setData performance, and platform compliance. Loaded by @miniprogram-dev via skills: frontmatter.
type: skill
---

# Miniprogram Engineering Skill

## 1. Runtime Constraint Map

The miniprogram runtime is NOT a browser. Key differences:

| Browser API | Miniprogram Equivalent | Notes |
|-------------|------------------------|-------|
| `window`, `document` | None | No DOM/BOM access. Rendering layer is WebView, JS runs in separate logic layer. |
| `localStorage` | `wx.setStorage` / `wx.getStorage` | Sync variants available but prefer async |
| `cookie` | None | Use own-service token in storage |
| `setTimeout` | `wx.` prefix in component contexts | Global timer may not work in component |
| `navigator.getUserMedia` | `wx.` media APIs | Platform-specific |

**Restricted CSS**: no `*` selector, limited pseudo-elements, no `calc()` in some contexts.
**Page stack limit**: 10 levels max.

## 2. Package Budget Discipline

| Limit | Value | Action |
|-------|-------|--------|
| Main package hard limit | 2MB | Upload fails if exceeded |
| Warning threshold | 1.8MB | Restructure subpackages before continuing |
| Total limit | 20MB | All packages combined |
| Per-subpackage limit | 2MB | Each subpackage |

**Subpackage Architecture**:
- Main package = TabBar pages + global utilities + genuinely shared components
- All feature pages → subpackage candidates
- Route-grouped subpackages preferred over functionality-grouped
- Plan subpackage architecture BEFORE writing any pages

## 3. setData Performance

setData crosses logic-to-rendering IPC boundary. Cost scales with data size transferred.

**Discipline**:
- Pass ONLY changed field paths: `this.setData({ 'list[3].selected': true })`
- NEVER pass full state: `this.setData(this.data)` causes frame drops
- Avoid nesting setData in loops
- Debounce rapid sequential updates
- Use WXS for rendering-layer computations that don't need to cross boundary

## 4. WeChat Ecosystem Security Chain

### Login Flow
1. Frontend: `wx.login()` → gets `code`
2. Frontend → Own backend: POST `/auth/wechat-login` with `code`
3. Own backend → WeChat API: `code2session(code)` → gets `session_key` + `openid`
4. Own backend: store `session_key` server-side (NEVER send to frontend), create own-service JWT
5. Own backend → Frontend: JWT
6. Frontend: store JWT in `wx.setStorage` (NOT `session_key`, NOT `openid` directly)

### Payment Flow
1. Frontend → Own backend: POST `/orders/create`
2. Own backend: creates order, calls WeChat Pay unified order API → returns pay params
3. Frontend: `wx.requestPayment(payParams)`
4. Frontend success callback: UI update ONLY ("Payment being processed...")
5. Own backend receives WeChat server notification at `notify_url` → validates signature → updates order status
6. Frontend polls own backend for order status → updates UI to confirmed

**CRITICAL**: `wx.requestPayment` success callback ≠ confirmed transaction. Backend callback is the ONLY authoritative signal.

### User Data Decryption
`wx.getPhoneNumber` → encrypted data sent to own backend → backend decrypts using `session_key` → backend validates → returns decrypted data.

## 5. Compliance

**Privacy Consent Popup**: REQUIRED before any data collection since 2023. Missing → WeChat review rejection.
- Must link to privacy policy URL registered with miniprogram
- Must be explicit user consent (not implicit)

**Domain Whitelist**: All request/uploadFile/downloadFile/socket domains must be registered in WeChat console.

## 6. Stack Selection

| Stack | When to Use |
|-------|-------------|
| Native WeChat | WeChat-only, maximum performance, direct API access |
| uni-app | Cross-platform (mp-weixin + H5 + App), Vue 3 syntax, conditional compilation |

## 7. Anti-Patterns

**Web-Import Hopes**: using npm packages that require DOM/BOM. Correction: verify every dependency against miniprogram runtime.
**Size-Limit Blindness**: ignoring 2MB ceiling until upload fails. Correction: monitor size continuously, plan subpackages early.
**Subpackage Tetris**: poorly organized subpackages requiring cross-subpackage imports. Correction: route-grouped subpackages.
**Token-Storage Naive**: storing `session_key` in client storage. Correction: `session_key` never leaves backend.
**Payment No-Idempotency**: treating frontend success as confirmed. Correction: backend callback is authoritative.
**setData Avalanche**: passing full state object. Correction: diff-only discipline.
**uni-app Platform Leak**: H5-specific code leaking into miniprogram build. Correction: `#ifdef` conditional compilation.
