# 视觉设计师 — Domain 3: Accessibility and Layout

## 3.1 WCAG 2.1 AA Compliance

### 3.1.1 Contrast Requirements by Element Type

| Element Type | Size | Minimum Ratio | WCAG Criterion |
|---|---|---|---|
| Body text | < 18pt regular, < 14pt bold | 4.5:1 | 1.4.3 Contrast (Minimum) |
| Large text | ≥ 18pt regular, ≥ 14pt bold | 3:1 | 1.4.3 Contrast (Minimum) |
| UI components | Any size | 3:1 | 1.4.11 Non-text Contrast |
| Placeholder text | Any size | 4.5:1 | 1.4.3 (treated as regular text) |
| Focus indicator | Any size | 3:1 | 2.4.7 Focus Visible |
| Graphical objects | Any size | 3:1 | 1.4.11 Non-text Contrast |

**Common failures to avoid**:
- Placeholder text at #9CA3AF on white = 2.7:1 (fails 4.5:1)
- Disabled buttons at 30% opacity (often fails 3:1 against background)
- Icon-only buttons with insufficient icon contrast
- Error text in light red on white (may fail 4.5:1)

### 3.1.2 Focus Ring Specification

**WCAG 2.4.7 (AA) requirements**:
- Focus indicator is visible
- At least 2px thick
- At least 3:1 contrast against element background
- At least 3:1 contrast against page background

**Specification template**:

```markdown
## Focus Ring Specification

| Property | Value | Token Reference |
|---|---|---|
| Style | 2px solid | — |
| Color | --color-interactive-primary | Semantic token |
| Offset | 2px | --spacing-1 |
| Border radius | matches element radius | — |
| Transition | --duration-fast | Motion token |

### Exceptions

- Buttons: outline-offset: 2px
- Inputs: outline-offset: 0px (outline hugs element)
- Cards: outline-offset: 4px (larger offset for elevated elements)
- Links: underline + outline (dual indicator)
```

**Anti-pattern to avoid**:
```css
/* NEVER do this */
*:focus {
  outline: none;
}
/* Without providing a visible alternative, this violates WCAG 2.4.7 */
```

### 3.1.3 Color Independence

Information conveyed by color must have a secondary non-color indicator:

| Color Signal | Required Secondary Indicator | Example |
|---|---|---|
| Error (red) | Error icon + error text | Red border + ⚠️ icon + "Invalid email" |
| Success (green) | Checkmark icon + success text | Green border + ✓ icon + "Saved" |
| Warning (amber) | Warning icon + warning text | Amber border + ▲ icon + "Unsaved changes" |
| Info (blue) | Info icon + info text | Blue border + ℹ icon + "Tip: ..." |

**Grayscale test**:
1. Convert design to grayscale
2. Verify all information is still decipherable
3. If state relies solely on color → add secondary indicator

## 3.2 Layout Specification

### 3.2.1 Grid System

**Standard grid**:

| Breakpoint | Width | Columns | Margin | Gutter |
|---|---|---|---|---|
| Mobile | < 640px | 4 | 16px | 16px |
| Tablet | 640–1024px | 8 | 24px | 20px |
| Desktop | 1024–1440px | 12 | 24px | 24px |
| Wide | > 1440px | 12 | 32px | 24px |

**Container max-widths**:

| Container | Max Width | Use Case |
|---|---|---|
| sm | 640px | Narrow content, forms |
| md | 768px | Reading width |
| lg | 1024px | Standard content |
| xl | 1200px | Wide content |
| full | 100% | Edge-to-edge sections |

**Responsive behavior**:
- Fluid below max-width (scales with viewport)
- Fixed at max-width (centers with auto margins)
- Content reflows at breakpoints

### 3.2.2 Density Mode Design

**Compact mode** (B2B, data-dense):

| Property | Adjustment | Rationale |
|---|---|---|
| Spacing | scale - 1 step | More content per screen |
| Font size (secondary) | - 1 step | Smaller labels, headers |
| Line height | 1.4 | Tighter text blocks |
| Table row height | 40px | More rows visible |
| Button height | 32px (sm) | Compact controls |

**Comfortable mode** (consumer, content):

| Property | Adjustment | Rationale |
|---|---|---|
| Spacing | default | Balanced whitespace |
| Font size | default | Readable at standard size |
| Line height | 1.6 | Comfortable reading |
| Table row height | 56px | Easier row targeting |
| Button height | 40px (md) | Easy to tap/click |

**Spacious mode** (marketing, hero):

| Property | Adjustment | Rationale |
|---|---|---|
| Spacing | scale + 1 step | Dramatic whitespace |
| Font size (display) | + 1 step | Impactful headlines |
| Line height | 1.2 | Tight display text |
| Section padding | 96px+ | Breathing room |

### 3.2.3 Breakpoint Specification

```markdown
## Breakpoints

| Name | Min | Max | Target Devices |
|---|---|---|---|
| xs | 0px | 639px | Phones |
| sm | 640px | 767px | Large phones, small tablets |
| md | 768px | 1023px | Tablets |
| lg | 1024px | 1279px | Small laptops |
| xl | 1280px | 1439px | Desktops |
| 2xl | 1440px | ∞ | Large desktops |

## Container Behavior

| Container | xs | sm | md | lg | xl | 2xl |
|---|---|---|---|---|---|---|
| sm | 100% | 100% | 640px | 640px | 640px | 640px |
| md | 100% | 100% | 100% | 768px | 768px | 768px |
| lg | 100% | 100% | 100% | 100% | 1024px | 1024px |
| xl | 100% | 100% | 100% | 100% | 100% | 1200px |
```

## 3.3 A11y Annotation Standards

### Component A11y Checklist

Every component spec must include:

```markdown
### A11y Requirements

- [ ] **Role**: Appropriate ARIA role or native semantic element
- [ ] **Keyboard**: All functionality available via keyboard
- [ ] **Focus**: Visible focus indicator for all interactive states
- [ ] **Label**: Accessible name for all interactive elements
- [ ] **State**: ARIA states communicated (aria-expanded, aria-selected, etc.)
- [ ] **Live regions**: Status updates announced (aria-live)
- [ ] **Color**: Information not conveyed by color alone
- [ ] **Motion**: Respects prefers-reduced-motion
```

### A11y Annotation Examples

**Button**:
```markdown
- Role: button (native)
- Keyboard: Enter/Space activates
- Focus: 2px solid outline, 2px offset
- Label: Visible text or aria-label for icon-only
- State: aria-disabled when disabled, aria-busy when loading
```

**Input**:
```markdown
- Role: textbox (native)
- Keyboard: Tab to focus, type to input
- Focus: 2px solid outline, 0px offset
- Label: <label> element associated via for/id
- State: aria-invalid when error, aria-describedby for helper text
- Required: aria-required or required attribute
```

**Modal**:
```markdown
- Role: dialog
- Keyboard: Tab traps within modal, Escape closes
- Focus: Initial focus on first focusable element or title
- Label: aria-labelledby pointing to modal title
- State: aria-modal="true"
- Return focus: On close, return focus to trigger element
```

**Table**:
```markdown
- Role: table (native)
- Keyboard: Arrow keys navigate cells
- Focus: Row focus for interactive rows
- Label: <caption> or aria-label
- State: aria-sort for sortable columns
- Selection: aria-selected for selectable rows
```

## 3.4 Design System Maintenance

### Versioning

```markdown
## Design System Versioning

Format: v{major}.{minor}.{patch}

- Major: Breaking token changes (renames, removals)
- Minor: New tokens, new components, non-breaking additions
- Patch: Token value corrections, documentation fixes

Changelog requirements:
- Every version documents: added / changed / deprecated / removed
- Migration guide for major versions
- Token deprecation: keep for 2 minor versions before removal
```

### Token Deprecation

```markdown
## Deprecation Process

1. Mark token as deprecated in token file:
   ```json
   {
     "color": {
       "semantic": {
         "old-token": {
           "$value": "{color.primitive.blue.600}",
           "$deprecated": true,
           "$replacement": "color.semantic.interactive-primary"
         }
       }
     }
   }
   ```

2. Update all component specs to use replacement

3. Notify @frontend of deprecation

4. Remove after 2 minor versions
```

### Quality Checklist (Pre-Delivery)

- [ ] All tokens follow three-layer hierarchy
- [ ] Every semantic color pair passes WCAG AA in both modes
- [ ] Dark mode mappings exist for all semantic tokens
- [ ] Spacing values are all multiples of base unit
- [ ] Every interactive component has complete states matrix
- [ ] Component specs use token references, not raw values
- [ ] Layout spec includes grid, breakpoints, density modes
- [ ] A11y notes include contrast table, focus ring spec, motion reduction
- [ ] Component inventory ≤ 12 core components
- [ ] All values traceable to brand mood board
- [ ] No CSS, no implementation technology specified
