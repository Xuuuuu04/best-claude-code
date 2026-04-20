# 界面测试师 — Domain 2: Interaction Verification

## 2.1 Keyboard Navigation

### Tab Order Verification

**Procedure**:
1. Click on page background (not on any interactive element)
2. Press Tab key repeatedly
3. Record each focused element in order
4. Verify the sequence follows visual reading order

**Expected tab order for login page**:
```
1. Logo (if linked) or skip link
2. Username/email input
3. Password input
4. "Show password" toggle (if present)
5. "Remember me" checkbox (if present)
6. Submit button
7. "Forgot password" link
8. "Register" link
9. Language selector (if present)
```

**Common tab order defects**:
- Tab skips interactive elements (missing tabindex or negative tabindex)
- Tab order does not match visual order (confusing for keyboard users)
- Hidden elements receive focus (off-screen modals, collapsed menus)
- Focus gets trapped (cannot Tab out of a component)

### Enter/Space Activation

**Procedure**:
1. Tab to each interactive element
2. Press Enter (for links, buttons, form submission)
3. Press Space (for buttons, checkboxes, toggles)
4. Verify element activates

**Expected behavior**:
- Button: Enter or Space triggers click
- Link: Enter navigates
- Checkbox: Space toggles
- Radio: Space selects
- Select dropdown: Enter opens, arrow keys navigate, Enter selects

### Escape Key Behavior

**Procedure**:
1. Open modal, dropdown, or overlay
2. Press Escape
3. Verify overlay closes and focus returns to trigger element

## 2.2 Visual Feedback States

### Hover State

**Chrome DevTools force-state**:
1. Inspect element
2. Elements panel → `:hov` button
3. Check "hover"
4. Screenshot the forced state

**Expected hover changes**:
- Button: background color darkens/lightens, cursor changes to pointer
- Link: underline appears, color changes
- Card: shadow increases, slight lift (translateY)
- Interactive row: background highlight

### Active/Pressed State

**Chrome DevTools force-state**:
1. Inspect element
2. Elements panel → `:hov` button
3. Check "active"
4. Screenshot the forced state

**Expected active changes**:
- Button: visually depresses (translateY(1px)), darker background
- Link: color changes to active color
- Duration: visual response within ~100ms of click

### Focus State

**Chrome DevTools force-state**:
1. Inspect element
2. Elements panel → `:hov` button
3. Check ":focus-visible" (not ":focus" — focus-visible is the modern standard)
4. Screenshot the forced state

**Expected focus indicators**:
- Outline: 2px solid, visible color, 2px offset
- Background change: distinct from hover
- Ring: box-shadow or border that is clearly visible

**Focus defects to flag**:
- No focus indicator at all
- Focus indicator same color as background (invisible)
- Focus indicator clipped by overflow:hidden container
- Focus indicator removed without replacement (`outline: none` with no alternative)

### Disabled State

**Verification methods**:

**Method 1: Visual inspection**
- Element has reduced opacity (typically 40-50%)
- Cursor shows not-allowed
- Color is muted/gray

**Method 2: Functional verification (Playwright)**:
```javascript
// Attempt to click disabled button
const button = page.locator('button[disabled]');
await button.click({ force: true }); // force bypasses actionability check
// If click succeeds, disabled state is not properly implemented
```

**Method 3: Attribute check**:
```javascript
const isDisabled = await page.locator('button').isDisabled();
// Should return true for disabled elements
```

## 2.3 WCAG Spot-Check

### Contrast Ratio Check

**Chrome DevTools method**:
1. Inspect text element
2. Styles panel → color swatch
3. Click swatch → "Contrast ratio" section
4. View AA/AAA compliance indicators

**Manual calculation** (when DevTools unavailable):
```
Relative luminance: L = 0.2126R + 0.7152G + 0.0722B
(where R, G, B are sRGB values normalized to 0-1)

Contrast ratio: (L1 + 0.05) / (L2 + 0.05)
(where L1 is lighter, L2 is darker)

WCAG 2.1 AA thresholds:
- Normal text: ≥ 4.5:1
- Large text (≥ 18pt regular or ≥ 14pt bold): ≥ 3:1
- UI components (borders, icons): ≥ 3:1
```

**Flag obviously failing pairs**:
- White text on light yellow
- Light gray text on white (#999 on #fff ≈ 2.8:1)
- Red text on dark red
- Any combination where you struggle to read the text

### Focus Ring Visibility

**Minimum specification** (WCAG 2.4.7):
- Focus indicator is visible
- At least 2px thick
- At least 3:1 contrast against adjacent colors
- Not obscured by other elements

**Verification**:
1. Force :focus-visible state in DevTools
2. Screenshot
3. Verify ring is clearly visible
4. If ring is thin or low-contrast, flag as FAIL or UNSURE

### Mobile Tap Targets

**Measurement method**:
1. Chrome DevTools → Device Toolbar (375×667)
2. Inspect element
3. Elements panel → Computed → box model
4. View width × height

**Thresholds**:
| Standard | Minimum Size | Flag If Below |
|---|---|---|
| WCAG 2.5.5 AAA | 44×44px | < 44px |
| WCAG 2.5.5 AA | 44×44px (essential) | < 44px |
| Practical minimum | — | < 20×20px (clearly insufficient) |

**Common undersized targets**:
- Icon-only buttons (16×16px icon with no padding)
- Inline delete links (text-size hit area)
- Pagination numbers (tight spacing)
- Custom checkboxes (too small)

## 2.4 UNSURE Classification

### When to Use UNSURE

UNSURE applies when:

1. **Design context needed**: The classification requires knowledge of the project's design specification that is not available
   ```
   UNSURE: Focus ring is 1px dashed #9e9e9e.
   Cannot classify without knowing project's accessibility baseline.
   ```

2. **Flaky behavior**: The element behaves inconsistently across attempts
   ```
   UNSURE: Loading spinner appears intermittently.
   Sometimes visible, sometimes not. May be timing-dependent.
   Recommend re-test with consistent network throttling.
   ```

3. **Ambiguous rule applicability**: The checklist item does not clearly apply to this element type
   ```
   UNSURE: Toast/notification for this page.
   Page uses inline success message instead of toast.
   Cannot determine if this satisfies the notification requirement.
   ```

### UNSURE Format

```markdown
UNSURE: [element description] — [specific ambiguity]
[What information is needed to resolve]
[Screenshot reference if applicable]
```

### UNSURE vs. N/A

| | UNSURE | N/A |
|---|---|---|
| Meaning | Could be PASS or FAIL, cannot determine | Item does not apply to this page |
| Example | "Focus ring color unclear if accessible" | "No toast on login page" |
| Resolution | Needs design spec or clarification | No resolution needed |

Never suppress UNSURE to avoid "noise." An honest UNSURE is more valuable than a false PASS.
