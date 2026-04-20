# 界面测试师 — Output Contract (Detailed)

## Evidence Package Structure

Every delivery produces:

```
tests/screenshots/v{N}/
├── manifest.md
├── {page}-desktop-initial.png
├── {page}-desktop-normal.png
├── {page}-desktop-error.png
├── {page}-desktop-empty.png
├── {page}-desktop-loading.png
├── {page}-desktop-success.png
├── {page}-mobile-initial.png
├── {page}-mobile-normal.png
├── {page}-mobile-error.png
├── {page}-mobile-empty.png
├── {page}-mobile-loading.png
├── {page}-mobile-success.png
└── interaction-check.md
```

### manifest.md

```markdown
# Screenshot Manifest — {Page Name} — v{N}

**Generated**: [YYYY-MM-DD HH:MM]
**Environment**: [browser + version, OS, URL]
**Tester**: [agent name]

| Filename | State | Viewport | Size | Checksum |
|---|---|---|---|---|
| login-desktop-initial.png | Initial | 1920×1080 | 245KB | sha256:abc... |
| login-desktop-normal.png | Normal | 1920×1080 | 198KB | sha256:def... |
| ... | ... | ... | ... | ... |
```

### interaction-check.md

```markdown
## UI Evidence Package — {Page Name} — v{N}

**Environment**: [browser + version, OS, URL]
**Date**: [YYYY-MM-DD HH:MM]
**Test account**: [account role used, no credentials]
**Preceding test round**: [test-func round N passed / initial capture]

### Screenshot Matrix

| State | Desktop | Mobile |
|---|---|---|
| Initial | login-desktop-initial.png | login-mobile-initial.png |
| Normal (logged in) | login-desktop-normal.png | login-mobile-normal.png |
| Error (wrong password) | login-desktop-error.png | login-mobile-error.png |
| Empty (no data) | login-desktop-empty.png | login-mobile-empty.png |
| Loading (during auth) | login-desktop-loading.png | login-mobile-loading.png |
| Success (post-login) | login-desktop-success.png | login-mobile-success.png |

### Interaction Checklist

| # | Item | Result | Notes |
|---|------|--------|-------|
| 1 | Tab traversal | PASS/FAIL/UNSURE/N/A | [details] |
| 2 | Focus visible | PASS/FAIL/UNSURE/N/A | [details] |
| 3 | Hover feedback | PASS/FAIL/UNSURE/N/A | [details] |
| 4 | Click/active feedback | PASS/FAIL/UNSURE/N/A | [details] |
| 5 | Error state visible | PASS/FAIL/UNSURE/N/A | [details] |
| 6 | Loading state | PASS/FAIL/UNSURE/N/A | [details] |
| 7 | Toast/notification | PASS/FAIL/UNSURE/N/A | [details] |
| 8 | Disabled state | PASS/FAIL/UNSURE/N/A | [details] |

### WCAG Spot-Check

| Check | Result | Notes |
|---|---|---|
| Text contrast | PASS/FAIL/UNSURE | [details] |
| Focus ring visibility | PASS/FAIL/UNSURE | [details] |
| Mobile tap targets | PASS/FAIL/UNSURE | [details] |

### Obvious Defects

1. **[Severity] — [Description]** `[screenshot-filename.png]` [observable details]

### Verdict Recommendation

Evidence package complete/incomplete. Recommending @测试总监师 for verdict.
```

## Screenshot Naming Convention

Format: `{page}-{viewport}-{state}.png`

| Segment | Values | Example |
|---|---|---|
| page | lowercase, hyphenated page name | `login`, `checkout`, `user-profile` |
| viewport | `desktop` (1920×1080) or `mobile` (375×667) | `desktop`, `mobile` |
| state | `initial`, `normal`, `empty`, `error`, `loading`, `success` | `error`, `loading` |

**Valid examples**:
- `login-desktop-initial.png`
- `checkout-mobile-error.png`
- `user-profile-desktop-empty.png`

**Invalid examples**:
- `screenshot1.png` — no semantic information
- `login.png` — missing viewport and state
- `Login_Desktop_Error.png` — wrong case, wrong separator
- `login-1920x1080-initial.png` — viewport should be `desktop`, not resolution

## State Definitions

| State | Definition | Trigger Method |
|---|---|---|
| Initial | Page first load, no user interaction | Navigate to URL, clear form data |
| Normal | Page with typical data populated | Log in with standard test account |
| Empty | Page with no data to display | Log in with empty test account, clear localStorage |
| Error | Failure state displayed | Submit invalid form, trigger API error |
| Loading | Async operation in progress | Throttle network to 3G, submit form |
| Success | Operation completed successfully | Submit valid form, wait for completion |

## Interaction Checklist Details

### 1. Tab Traversal

**PASS criteria**:
- All interactive elements (buttons, links, inputs, selects, checkboxes, radios) are reachable via Tab key
- Tab order follows visual reading order (left-to-right, top-to-bottom)
- No keyboard traps (can Tab into and out of every component)
- Enter/Space activates focused controls
- Escape closes modals and dropdowns

**Verification method**:
```
1. Click on page background
2. Press Tab repeatedly
3. Record each focused element in order
4. Verify logical sequence
5. Verify Enter/Space activates
6. Verify Escape closes overlays
```

### 2. Focus Visible

**PASS criteria**:
- Every focused element has a visible focus indicator
- Focus indicator is distinguishable from default state
- Focus indicator is visible against element background

**FAIL examples**:
- Focus ring completely absent
- Focus ring same color as background (invisible)
- Focus ring clipped by overflow:hidden container

### 3. Hover Feedback

**PASS criteria**:
- Buttons change visually on hover (background, border, shadow, cursor)
- Links show underline or color change
- Interactive cards lift or highlight

**Verification method**:
```
Chrome DevTools → Elements → :hov → hover (force state)
Screenshot and compare with default state
```

### 4. Click/Active Feedback

**PASS criteria**:
- Button visually depresses or changes within ~100ms of click
- Active state is distinct from hover and default
- User receives immediate visual confirmation of click

### 5. Error State Visible

**PASS criteria**:
- Form validation errors appear near the relevant field
- Error message is readable and not obscured
- Error styling is distinct from normal state
- Multiple errors are all visible simultaneously

### 6. Loading State

**PASS criteria**:
- Operations > 300ms show a loading indicator
- Loading indicator does not block entire page unnecessarily
- Loading state is visually distinct
- Loading indicator has appropriate ARIA attributes

### 7. Toast/Notification

**PASS criteria**:
- Success operations show confirmation
- Failure operations show error notification
- Toast is visible and readable
- Toast auto-dismisses or can be manually dismissed

**N/A criteria**:
- Page has no async operations that produce toast
- Success/failure is shown inline instead

### 8. Disabled State

**PASS criteria**:
- Disabled controls are visually distinct (opacity, grayscale, cursor)
- Disabled controls do not respond to click
- Disabled state is communicated to assistive technology

## WCAG Spot-Check Details

### Text Contrast

**Method**: Chrome DevTools → Accessibility panel → select text element → view contrast ratio

**Thresholds**:
- Normal text (< 18pt regular, < 14pt bold): ≥ 4.5:1 (WCAG AA)
- Large text (≥ 18pt regular, ≥ 14pt bold): ≥ 3:1 (WCAG AA)
- UI components (borders, icons): ≥ 3:1 (WCAG AA)

**Flag**: Obviously failing contrast — white text on light yellow, light gray text on white, etc.

### Focus Ring Visibility

**Method**:
1. Chrome DevTools → Elements → :hov → :focus-visible
2. Screenshot focused element
3. Verify ring is visible against background

**Minimum spec**: 2px solid outline, 2px offset, 3:1 contrast against adjacent colors

### Mobile Tap Targets

**Method**: Chrome DevTools → Elements → select element → view box model dimensions

**Thresholds**:
- WCAG 2.5.5 (AAA): ≥ 44×44px
- WCAG 2.5.5 (AA): ≥ 44×44px for essential targets
- Flag obviously below: < 20×20px is clearly insufficient

## Quality Checklist (Pre-Submission)

Before delivering the evidence package:

- [ ] Every state in the matrix has a corresponding screenshot file
- [ ] Both viewports captured for every state
- [ ] All files follow naming convention `{page}-{viewport}-{state}.png`
- [ ] All files exist and have size > 5KB
- [ ] All 8 checklist items have PASS/FAIL/UNSURE/N/A classification
- [ ] Every FAIL has screenshot reference and observable description
- [ ] Every UNSURE has specific reason and information needed
- [ ] WCAG spot-check completed
- [ ] No aesthetic opinions in the report
- [ ] manifest.md lists all files
- [ ] interaction-check.md ends with @测试总监师 recommendation
