---
name: ui-testing
description: UI evidence collection and interaction verification methodology for the Harness team. Covers full-page screenshot capture discipline, state matrix documentation, 8-item interaction checklist, WCAG baseline spot-check, viewport coverage (desktop + mobile), file naming convention, and anomaly capture. Loaded by @test-ui via skills: frontmatter.
type: skill
---

# UI Testing Skill

## 1. Screenshot Capture Discipline

- **Full page only**: never substitute partial/cropped for full-page. Partial = incomplete evidence.
- **Both viewports mandatory**: desktop (1920×1080) AND mobile (375×667). Desktop-only = incomplete.
- **Naming convention**: `{page}-{viewport}-{state}.png` (lowercase, hyphen-separated). `screenshot1.png` is invalid evidence.
- **Archive path**: `tests/screenshots/vN/`
- **State matrix per page**: minimum 4 states — initial, normal, empty, error, loading (where applicable)
- **Manifest**: include `manifest.md` listing every file with the state it represents

## 2. State Triggering Techniques

| State | Trigger Method |
|---|---|
| Loading | Network intercept/throttling, DevTools throttling |
| Error | Submit invalid form, trigger API error via mock |
| Empty | Log in with account that has no data, clear localStorage |
| Normal | Navigate with populated data |
| Initial | First load, no interaction |

## 3. Browser and Automation Tools

**Chrome DevTools**:
- Full-page: `Cmd+Shift+P → "Capture full size screenshot"`
- Viewport switch: Device Toolbar (`Cmd+Shift+M`)
- Custom viewport: Edit device list for exact 1920×1080 and 375×667
- Force states: Elements → :hov → hover/active/focus/focus-visible
- Contrast: Accessibility panel shows ratio for selected text

**Playwright**:
```javascript
page.screenshot({fullPage: true, path: 'name.png'})
page.setViewportSize({width: 375, height: 667})
```

**Puppeteer**:
```javascript
page.screenshot({fullPage: true})
```

## 4. Eight-Item Interaction Checklist

| # | Item | PASS Criteria |
|---|---|---|
| 1 | Tab traversal | All interactive elements reachable via keyboard, logical order |
| 2 | Focus visible | Keyboard focus produces visible indicator (outline/background/ring) |
| 3 | Hover feedback | Buttons and links change visually on hover |
| 4 | Click/active feedback | Buttons respond visually within ~100ms of click |
| 5 | Error state visible | Form validation errors appear near relevant field |
| 6 | Loading state | Operations > 300ms show loading indicator |
| 7 | Toast/notification | Success/failure operations produce user feedback |
| 8 | Disabled state | Disabled controls visually distinct and non-interactive |

## 5. WCAG Baseline Spot-Check

Check only obvious failures — not a full accessibility audit:

| Check | Obvious FAIL Criteria | Tool |
|---|---|---|
| Text contrast | White text on light yellow, light gray on white | DevTools Accessibility panel |
| Focus ring visibility | No visible indicator on focused element | Force `:focus-visible`, screenshot |
| Mobile tap targets | Interactive elements obviously below ~20×20px | DevTools box model (WCAG recommends ≥44×44px) |

WCAG AA ratios: 4.5:1 normal text, 3:1 large text, 3:1 interactive elements.

## 6. Classification Rules

- **PASS**: item clearly meets criteria with observable evidence
- **FAIL**: item clearly violates criteria — include screenshot reference and observable description
- **UNSURE**: requires design context to classify, element behavior is flaky, or rule is ambiguous for this element type. Format: `UNSURE: [element] — [specific ambiguity]`
- **N/A**: item does not apply to this page/feature

Never suppress UNSURE to avoid "noise." An honest UNSURE is evidence.

## 7. Obvious Defect Threshold

Flag only clearly broken items:
- Overlapping text making content unreadable
- Buttons cut off by viewport
- Interactive elements with no visible focus indicator
- Disabled buttons that respond to clicks
- Form error messages appearing far from relevant field

Do NOT flag subjective preferences: "looks cluttered," "spacing feels off," "color is too bright."

## 8. Evidence Package Structure

```
tests/screenshots/vN/
├── {page}-desktop-initial.png
├── {page}-desktop-normal.png
├── {page}-desktop-error.png
├── {page}-desktop-empty.png
├── {page}-mobile-initial.png
├── {page}-mobile-normal.png
├── {page}-mobile-error.png
├── manifest.md
└── interaction-check.md
```

`interaction-check.md` contains: screenshot matrix table, 8-item checklist results, WCAG spot-check results, obvious defects list, verdict recommendation.

## 9. Anti-Patterns

| Name | Symptom | Correction |
|---|---|---|
| **Partial-Screenshot Substitution** | Capturing above-the-fold only and claiming full coverage | Full page, every time |
| **Coverage Fabrication** | Listing a state as tested without corresponding screenshot | Every listed state must have a file in the evidence package |
| **Opinion Leak** | "Looks cluttered," "color is too bright" | Observable, measurable defects only |
| **UNSURE Aversion** | Forcing PASS/FAIL on ambiguous items | UNSURE exists precisely to handle ambiguity without false signal |
