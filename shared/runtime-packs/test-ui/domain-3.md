# 界面测试师 — Domain 3: Anomaly Capture and Evidence Integrity

## 3.1 Broken or Unreachable Pages

### HTTP Error Pages

When a page returns an HTTP error, capture the error page itself:

```markdown
**Status**: BLOCKED (page unreachable)
**Captured**: `checkout-desktop-500-error.png`
**HTTP Status**: 500
**Error Message**: "Internal Server Error"
**Reason**: "The checkout page returns HTTP 500 for all test accounts.
Cannot capture normal/error/empty states for checkout."
**Unblock condition**: "@frontend or @backend must resolve the server error
on the checkout endpoint. After unblock, re-capture full state matrix."
```

**Key rule**: Did NOT list any states as covered (avoided coverage fabrication). DID capture the broken state as evidence.

### Partial Page Load

When a page loads partially (some sections missing or broken):

```markdown
**Status**: PARTIAL (page loads but incomplete)
**Captured**: `dashboard-desktop-partial.png`
**Observed**: Header and sidebar load correctly. Main content area is blank.
Console shows: "TypeError: Cannot read property 'map' of undefined"
**Reason**: "Dashboard main content fails to render. JavaScript error prevents
component mount. Can capture header/sidebar states but not main content."
**Unblock condition**: "@frontend to fix dashboard data loading."
```

### Environment Blockers

When the test environment prevents testing:

```markdown
**Status**: BLOCKED (environmental)
**Blocker**: Staging environment at https://staging.example.com is
returning 503 Service Unavailable for all requests.
**Captured**: `error-503.png` (browser default error page)
**Unblock condition**: "@devops to restore staging environment."
**ETA requested**: Yes, from @devops
```

## 3.2 Targeted Re-capture After Fix

### Scope Definition

When @test-lead issues a verdict with specific BLOCKED items, re-capture only those items:

```markdown
**Round**: 2 (targeted re-capture)
**Prior verdict**: `verdicts/verdict-T019-v1.md`
**Previously BLOCKED items**:
1. Password field focus ring absent
2. Mobile error state missing

**Scope**: Re-capture ONLY the 2 previously failed items.
Do NOT re-run full 8-item checklist.
```

### File Versioning

Use `v2` suffix for re-captured files:

```
v2/
├── login-desktop-focus-password-v2.png
├── login-mobile-error-v2.png
└── interaction-check.md
```

### Annotation Format

```markdown
| Item | Result | Notes |
|---|---|---|
| Focus visible | PASS | Password field now shows 2px solid #0066cc focus ring.
Screenshot: login-desktop-focus-password-v2.png.
[Previously FAIL Round 1] |
```

## 3.3 Evidence Integrity Verification

### Pre-Delivery Checklist

Before delivering the evidence package, verify:

**File existence**:
```bash
# Verify every referenced file exists
for file in $(grep -oE '\S+\.png' interaction-check.md); do
  if [ ! -f "tests/screenshots/v1/$file" ]; then
    echo "MISSING: $file"
  fi
done
```

**File size**:
```bash
# Flag suspiciously small files
find tests/screenshots/v1/*.png -size -5k
```

**Naming convention**:
```bash
# Verify naming pattern
for f in tests/screenshots/v1/*.png; do
  if ! echo "$f" | grep -qE '^[a-z0-9-]+-(desktop|mobile)-(initial|normal|empty|error|loading|success)\.png$'; then
    echo "INVALID NAME: $f"
  fi
done
```

**Viewport verification**:
```bash
# Check image dimensions (requires ImageMagick or similar)
for f in tests/screenshots/v1/*-desktop-*.png; do
  identify -format "%w %h %f\n" "$f"
  # Desktop should be 1920 width
done
```

### Evidence Package Completeness

A complete evidence package must contain:

- [ ] `manifest.md` with file listing
- [ ] `interaction-check.md` with all sections
- [ ] At least 4 states captured per page
- [ ] Both viewports for every state
- [ ] All 8 checklist items classified
- [ ] WCAG spot-check completed
- [ ] No aesthetic opinions
- [ ] Ends with @测试总监师 recommendation

### Common Evidence Gaps

| Gap | Risk | Detection |
|---|---|---|
| Missing mobile viewport | Mobile-specific defects missed | Check for `*-mobile-*.png` files |
| Missing error state | Error UI defects missed | Verify error state in matrix |
| Missing loading state | Loading UI defects missed | Check if async operations exist |
| Partial screenshots | Below-fold defects missed | Verify fullPage capture |
| Unnamed files | Cannot correlate to states | Enforce naming convention |
| Blank files | False coverage | Check file size > 5KB |

## 3.4 Collaboration and Routing

### Defect Discovery Path

```
@test-ui discovers defect
    ↓
Document in interaction-check.md (with screenshot reference)
    ↓
Deliver evidence package to @test-lead
    ↓
@test-lead renders verdict
    ↓
If BLOCKED: @test-lead routes to @frontend with specific defect description
    ↓
@frontend fixes defect
    ↓
@test-lead re-dispatches @test-ui for targeted re-capture
    ↓
@test-ui captures fixed state only, annotates [Previously FAIL Round N]
```

### Communication Rules

- @test-ui does NOT contact @frontend directly
- @test-ui produces evidence; @test-lead translates into actionable verdicts
- All findings must be observable and measurable
- UNSURE items are escalated to @test-lead or @visual-designer for resolution
