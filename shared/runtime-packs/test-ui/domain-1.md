# 界面测试师 — Domain 1: Screenshot Capture

## 1.1 Browser Tools

### Chrome DevTools

**Full-page screenshot**:
1. Open DevTools (`Cmd+Option+I` or `F12`)
2. `Cmd+Shift+P` → type "Capture full size screenshot" → Enter
3. File saved to Downloads

**Viewport screenshot**:
1. DevTools → `Cmd+Shift+P` → "Capture screenshot"
2. Captures visible viewport only (NOT acceptable as primary evidence)

**Device Toolbar for mobile viewport**:
1. DevTools → Device Toolbar (`Cmd+Shift+M`)
2. Select "Responsive" from device dropdown
3. Set dimensions: 375×667 (iPhone SE / baseline mobile)
4. `Cmd+Shift+P` → "Capture full size screenshot"

**Custom device setup**:
1. Device Toolbar → "Edit" (gear icon)
2. Add custom device:
   - Desktop: 1920×1080, DPR 1
   - Mobile: 375×667, DPR 2
3. Save for reuse

### Firefox Developer Tools

**Full-page screenshot**:
1. DevTools → Settings → "Take a screenshot of the entire page"
2. Or: `Shift+F2` → `screenshot --fullpage filename.png`

### Safari

**Full-page screenshot**:
1. Develop menu → "Show Web Inspector"
2. Right-click on `<html>` element → "Capture Screenshot"

## 1.2 Automation Tools

### Playwright

```javascript
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  // Desktop viewport
  await page.setViewportSize({ width: 1920, height: 1080 });
  await page.goto('https://staging.example.com/login');
  await page.screenshot({ fullPage: true, path: 'login-desktop-initial.png' });

  // Mobile viewport
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto('https://staging.example.com/login');
  await page.screenshot({ fullPage: true, path: 'login-mobile-initial.png' });

  await browser.close();
})();
```

**Element-level screenshot** (for focus state detail):
```javascript
const element = await page.locator('input[type="password"]');
await element.screenshot({ path: 'login-desktop-focus-password.png' });
```

### Puppeteer

```javascript
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();

  // Desktop
  await page.setViewport({ width: 1920, height: 1080 });
  await page.goto('https://staging.example.com/login');
  await page.screenshot({ fullPage: true, path: 'login-desktop-initial.png' });

  // Mobile
  await page.setViewport({ width: 375, height: 667 });
  await page.goto('https://staging.example.com/login');
  await page.screenshot({ fullPage: true, path: 'login-mobile-initial.png' });

  await browser.close();
})();
```

## 1.3 State Triggering Techniques

### Initial State

**Trigger**: Navigate to page with cleared cache/cookies
```javascript
// Playwright
await page.goto('https://staging.example.com/login');
// Fresh navigation = initial state
```

### Normal State

**Trigger**: Log in with standard test account, populate form with valid data
```javascript
await page.fill('input[name="username"]', 'testuser');
await page.fill('input[name="password"]', 'testpass123');
// Screenshot BEFORE clicking submit
await page.screenshot({ fullPage: true, path: 'login-desktop-normal.png' });
```

### Empty State

**Trigger**: Log in with account that has no data
```javascript
// Use empty test account
await page.fill('input[name="username"]', 'emptyuser');
await page.click('button[type="submit"]');
// Navigate to page that would show data
await page.goto('https://staging.example.com/orders');
// Should show "No orders yet" or similar empty state
```

### Error State

**Trigger**: Submit invalid form or trigger API error
```javascript
// Form validation error
await page.fill('input[name="email"]', 'invalid-email');
await page.click('button[type="submit"]');
await page.waitForSelector('.error-message');
await page.screenshot({ fullPage: true, path: 'login-desktop-error.png' });

// API error (if mock server available)
await page.route('**/api/login', route => route.fulfill({
  status: 500,
  body: JSON.stringify({ error: 'Server error' })
}));
await page.click('button[type="submit"]');
```

### Loading State

**Trigger**: Throttle network or intercept requests
```javascript
// Network throttling
await page.route('**/*', async route => {
  await new Promise(r => setTimeout(r, 2000)); // 2s delay
  await route.continue();
});

// Or abort specific request to show loading indefinitely
await page.route('**/api/login', route => route.abort());
await page.click('button[type="submit"]');
await page.waitForTimeout(500); // Wait for loading UI to appear
await page.screenshot({ fullPage: true, path: 'login-desktop-loading.png' });
```

### Success State

**Trigger**: Complete valid operation
```javascript
await page.fill('input[name="username"]', 'testuser');
await page.fill('input[name="password"]', 'correctpass');
await page.click('button[type="submit"]');
await page.waitForNavigation();
// Screenshot post-login page
await page.screenshot({ fullPage: true, path: 'login-desktop-success.png' });
```

## 1.4 File Management

### Directory Structure

```
tests/screenshots/
├── v1/                    # Round 1 evidence
│   ├── manifest.md
│   ├── login-desktop-initial.png
│   ├── login-desktop-normal.png
│   ├── ...
│   └── interaction-check.md
├── v2/                    # Round 2 (re-capture after fix)
│   ├── manifest.md
│   ├── login-desktop-focus-password-v2.png
│   └── interaction-check.md
└── archive/               # Historical rounds
    └── ...
```

### manifest.md Format

```markdown
# Screenshot Manifest — Login Page — v1

**Generated**: 2026-04-21 14:30
**Environment**: Chrome 124, macOS 14.4, https://staging.example.com
**Tester**: @test-ui

| Filename | State | Viewport | Dimensions | Size |
|---|---|---|---|---|
| login-desktop-initial.png | Initial | Desktop | 1920×1080 | 245KB |
| login-desktop-normal.png | Normal | Desktop | 1920×1080 | 198KB |
| login-desktop-error.png | Error | Desktop | 1920×1080 | 203KB |
| login-desktop-loading.png | Loading | Desktop | 1920×1080 | 156KB |
| login-mobile-initial.png | Initial | Mobile | 375×667 | 89KB |
| login-mobile-normal.png | Normal | Mobile | 375×667 | 76KB |
| login-mobile-error.png | Error | Mobile | 375×667 | 82KB |
| login-mobile-loading.png | Loading | Mobile | 375×667 | 71KB |
```

### File Size Validation

Before delivering, verify files are not blank:

```bash
# Check all files > 5KB
for f in tests/screenshots/v1/*.png; do
  size=$(stat -f%z "$f")
  if [ "$size" -lt 5120 ]; then
    echo "WARNING: $f is suspiciously small ($size bytes)"
  fi
done
```

### Versioning for Re-capture

When re-capturing after fixes, use `v2`, `v3`, etc.:

```
v1/ — original capture
v2/ — re-capture of fixed items only
```

In interaction-check.md, annotate:
```markdown
| Focus visible | PASS | Password field now shows 2px solid #0066cc focus ring.
Screenshot: login-desktop-focus-password-v2.png.
[Previously FAIL Round 1] |
```
