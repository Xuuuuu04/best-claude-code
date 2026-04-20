# 视觉设计师 — Output Contract (Detailed)

## Delivery Structure

```
## Visual Designer Delivery

**Design System Version**: [vX.Y — YYYY-MM-DD]
**Brand Direction Source**: [path to creative mood board]
**Technology Stack**: [framework + component library, if specified]
**A11y Target**: [WCAG AA / AAA]
**Platform**: [web / mobile web / miniprogram / all]

**Deliverable Files**:
- `docs/design-tokens.json` — canonical token file (W3C Design Tokens format)
- `docs/component-spec.md` — anatomy, states, variants, A11y annotations
- `docs/layout-spec.md` — grid, breakpoints, density modes
- `docs/a11y-notes.md` — contrast ratios + focus ring + motion + color-independence
- `docs/design-rationale.md` — decisions and justifications

**Token Coverage**:
- Color: [N primitives × K steps + P semantic, light+dark]
- Spacing: [base unit, N steps]
- Typography: [N sizes, ratio, line heights, weights]
- Radius: [N steps]
- Shadow: [N elevation levels]
- Motion: [N durations + N easings]

**Component Inventory**: [list of all specified components]

**A11y Verification Summary**:
- Critical pairs: [N verified, all PASS / N failures]
- Focus ring: [specification]
- Color independence: [PASS / N items flagged]
- Motion reduction: [supported / not applicable]

**Next Step**: @frontend for implementation / @test-ui for visual verification
```

## design-tokens.json (W3C Format Example)

```json
{
  "$schema": "https://design-tokens.github.io/community-group/format/schemas/schema.json",
  "color": {
    "primitive": {
      "blue": {
        "50": { "$type": "color", "$value": "#EFF6FF" },
        "100": { "$type": "color", "$value": "#DBEAFE" },
        "200": { "$type": "color", "$value": "#BFDBFE" },
        "300": { "$type": "color", "$value": "#93C5FD" },
        "400": { "$type": "color", "$value": "#60A5FA" },
        "500": { "$type": "color", "$value": "#3B82F6" },
        "600": { "$type": "color", "$value": "#2563EB" },
        "700": { "$type": "color", "$value": "#1D4ED8" },
        "800": { "$type": "color", "$value": "#1E40AF" },
        "900": { "$type": "color", "$value": "#1E3A8A" }
      },
      "gray": {
        "50": { "$type": "color", "$value": "#F9FAFB" },
        "100": { "$type": "color", "$value": "#F3F4F6" },
        "200": { "$type": "color", "$value": "#E5E7EB" },
        "300": { "$type": "color", "$value": "#D1D5DB" },
        "400": { "$type": "color", "$value": "#9CA3AF" },
        "500": { "$type": "color", "$value": "#6B7280" },
        "600": { "$type": "color", "$value": "#4B5563" },
        "700": { "$type": "color", "$value": "#374151" },
        "800": { "$type": "color", "$value": "#1F2937" },
        "900": { "$type": "color", "$value": "#111827" }
      }
    },
    "semantic": {
      "interactive": {
        "primary": {
          "light": { "$type": "color", "$value": "{color.primitive.blue.600}" },
          "dark": { "$type": "color", "$value": "{color.primitive.blue.400}" }
        },
        "primary-hover": {
          "light": { "$type": "color", "$value": "{color.primitive.blue.700}" },
          "dark": { "$type": "color", "$value": "{color.primitive.blue.300}" }
        }
      },
      "text": {
        "primary": {
          "light": { "$type": "color", "$value": "{color.primitive.gray.900}" },
          "dark": { "$type": "color", "$value": "{color.primitive.gray.50}" }
        },
        "secondary": {
          "light": { "$type": "color", "$value": "{color.primitive.gray.600}" },
          "dark": { "$type": "color", "$value": "{color.primitive.gray.400}" }
        }
      },
      "surface": {
        "primary": {
          "light": { "$type": "color", "$value": "#FFFFFF" },
          "dark": { "$type": "color", "$value": "{color.primitive.gray.950}" }
        }
      }
    }
  },
  "spacing": {
    "base": { "$type": "dimension", "$value": "4px" },
    "1": { "$type": "dimension", "$value": "4px" },
    "2": { "$type": "dimension", "$value": "8px" },
    "3": { "$type": "dimension", "$value": "12px" },
    "4": { "$type": "dimension", "$value": "16px" },
    "5": { "$type": "dimension", "$value": "20px" },
    "6": { "$type": "dimension", "$value": "24px" },
    "8": { "$type": "dimension", "$value": "32px" },
    "10": { "$type": "dimension", "$value": "40px" },
    "12": { "$type": "dimension", "$value": "48px" },
    "16": { "$type": "dimension", "$value": "64px" },
    "20": { "$type": "dimension", "$value": "80px" },
    "24": { "$type": "dimension", "$value": "96px" }
  },
  "typography": {
    "scale": {
      "xs": { "$type": "dimension", "$value": "12px" },
      "sm": { "$type": "dimension", "$value": "14px" },
      "base": { "$type": "dimension", "$value": "16px" },
      "lg": { "$type": "dimension", "$value": "18px" },
      "xl": { "$type": "dimension", "$value": "20px" },
      "2xl": { "$type": "dimension", "$value": "24px" },
      "3xl": { "$type": "dimension", "$value": "30px" },
      "4xl": { "$type": "dimension", "$value": "36px" },
      "5xl": { "$type": "dimension", "$value": "48px" }
    },
    "line-height": {
      "tight": { "$type": "number", "$value": 1.25 },
      "normal": { "$type": "number", "$value": 1.5 },
      "relaxed": { "$type": "number", "$value": 1.625 }
    },
    "weight": {
      "normal": { "$type": "number", "$value": 400 },
      "medium": { "$type": "number", "$value": 500 },
      "semibold": { "$type": "number", "$value": 600 },
      "bold": { "$type": "number", "$value": 700 }
    }
  },
  "radius": {
    "none": { "$type": "dimension", "$value": "0px" },
    "sm": { "$type": "dimension", "$value": "2px" },
    "md": { "$type": "dimension", "$value": "4px" },
    "lg": { "$type": "dimension", "$value": "8px" },
    "xl": { "$type": "dimension", "$value": "12px" },
    "full": { "$type": "dimension", "$value": "9999px" }
  },
  "shadow": {
    "none": { "$type": "shadow", "$value": "none" },
    "low": { "$type": "shadow", "$value": "0 1px 3px rgba(0,0,0,0.1)" },
    "medium": { "$type": "shadow", "$value": "0 4px 6px rgba(0,0,0,0.1)" },
    "high": { "$type": "shadow", "$value": "0 10px 15px rgba(0,0,0,0.1)" },
    "floating": { "$type": "shadow", "$value": "0 25px 50px rgba(0,0,0,0.15)" }
  },
  "motion": {
    "duration": {
      "fast": { "$type": "duration", "$value": "100ms" },
      "normal": { "$type": "duration", "$value": "200ms" },
      "slow": { "$type": "duration", "$value": "300ms" },
      "emphasis": { "$type": "duration", "$value": "500ms" }
    },
    "easing": {
      "ease-in": { "$type": "cubic-bezier", "$value": [0.4, 0, 1, 1] },
      "ease-out": { "$type": "cubic-bezier", "$value": [0, 0, 0.2, 1] },
      "ease-in-out": { "$type": "cubic-bezier", "$value": [0.4, 0, 0.2, 1] }
    }
  }
}
```

## component-spec.md Template

```markdown
# Component Specification

## Button

### Anatomy

| Part | Token Reference | Description |
|---|---|---|
| container | --button-primary-bg | Background color |
| container-border | --button-primary-border | Border (if applicable) |
| container-radius | --radius-md | Corner radius |
| label | --button-primary-text | Text color |
| label-typography | --typography-sm / --weight-medium | Font size and weight |
| icon | --button-primary-icon | Icon color |
| icon-size | --icon-sm | Icon dimensions |
| focus-ring | --color-interactive-primary | Focus indicator |

### States Matrix

| State | Background | Text | Border | Shadow | Transform | Transition | Notes |
|---|---|---|---|---|---|---|---|
| default | --color-interactive-primary | --color-text-on-interactive | none | none | none | --duration-fast | |
| hover | --color-interactive-primary-hover | --color-text-on-interactive | none | --shadow-low | translateY(-1px) | --duration-normal --easing-ease-out | cursor: pointer |
| focus | --color-interactive-primary | --color-text-on-interactive | 2px solid --color-interactive-primary | none | none | --duration-fast | outline-offset: 2px; WCAG 2.4.7 |
| active | --color-interactive-primary-active | --color-text-on-interactive | none | none | translateY(0) | --duration-fast | |
| disabled | --color-interactive-primary @ --opacity-disabled | --color-text-on-interactive @ --opacity-disabled | none | none | none | none | cursor: not-allowed; WCAG 1.4.3 |
| loading | --color-interactive-primary | --color-text-on-interactive | none | none | none | none | Spinner replaces label; aria-busy="true" |
| error | --feedback-error-bg | --feedback-error-text | 1px solid --feedback-error-border | none | none | --duration-fast | |

### Variants

| Variant | Background Token | Text Token | Use Case |
|---|---|---|---|
| primary | --color-interactive-primary | --color-text-on-interactive | Main CTA |
| secondary | --color-surface-secondary | --color-interactive-primary | Secondary action |
| danger | --color-interactive-destructive | --color-text-on-interactive | Destructive action |
| ghost | transparent | --color-interactive-primary | Low-emphasis action |

### Sizes

| Size | Padding | Typography | Height |
|---|---|---|---|
| sm | --spacing-2 --spacing-4 | --typography-xs | 32px |
| md | --spacing-3 --spacing-5 | --typography-sm | 40px |
| lg | --spacing-4 --spacing-6 | --typography-base | 48px |

### A11y Requirements

- Role: button (native)
- Keyboard: Enter/Space activates
- Focus: visible focus ring (see states matrix)
- Disabled: aria-disabled="true" when disabled
- Loading: aria-busy="true" when loading
- Icon-only: aria-label required

### Composition Rules

- Button can contain: icon + label, icon only, label only
- Icon position: left (default) or right
- Maximum one primary button per form/section
- Minimum 8px gap between adjacent buttons
```

## layout-spec.md Template

```markdown
# Layout Specification

## Grid System

| Breakpoint | Width | Columns | Margin | Gutter | Container Max |
|---|---|---|---|---|---|
| Mobile | < 640px | 4 | 16px | 16px | 100% |
| Tablet | 640–1024px | 8 | 24px | 20px | 100% |
| Desktop | 1024–1440px | 12 | 24px | 24px | 1200px |
| Wide | > 1440px | 12 | 32px | 24px | 1400px |

## Density Modes

| Mode | Spacing Adjustment | Typography Adjustment | Use Case |
|---|---|---|---|
| Compact | scale - 1 step | secondary text - 1 size | B2B, data-dense |
| Comfortable | default | default | Consumer, content-heavy |
| Spacious | scale + 1 step | default | Marketing, hero sections |

## Fixed Element Dimensions

| Element | Height | Notes |
|---|---|---|
| Header | 64px | Fixed top |
| Footer | 48px | Fixed bottom (if applicable) |
| Sidebar | 100vh - 64px | Below header |
| Modal max | 90vh | Max height with scroll |
| Toast | auto | Min 48px height |
```

## a11y-notes.md Template

```markdown
# Accessibility Compliance Notes

## Contrast Ratio Table

| Foreground | Background | Ratio | AA Body | AA Large | AA UI |
|---|---|---|---|---|---|
| --text-primary | --surface-primary | 18.1:1 | ✓ | ✓ | ✓ |
| --text-secondary | --surface-primary | 7.2:1 | ✓ | ✓ | ✓ |
| --interactive-primary | --surface-primary | 8.59:1 | ✓ | ✓ | ✓ |
| --text-disabled | --surface-primary | 3.1:1 | ✗ | ✓ | ✓ |

## Focus Ring Specification

- Style: 2px solid --color-interactive-primary
- Offset: 2px
- Contrast: 3:1 against element background AND page background
- WCAG: 2.4.7 (AA)

## Motion

- Respect prefers-reduced-motion
- Default: transitions enabled
- Reduced motion: instant state changes (duration: 0ms)

## Color Independence

- Error states: red color + error icon + error text
- Success states: green color + checkmark icon + success text
- Warning states: amber color + warning icon + warning text
- Grayscale test: all information decipherable without color
```

## Quality Checklist (Pre-Delivery)

Before delivering the design system:

- [ ] All tokens follow three-layer hierarchy (primitive → semantic → component)
- [ ] Every semantic color pair passes WCAG AA contrast in both light and dark modes
- [ ] Dark mode mappings exist for all semantic tokens
- [ ] Spacing values are all multiples of base unit
- [ ] Every interactive component has complete states matrix
- [ ] Component specs use token references, not raw values
- [ ] Layout spec includes grid, breakpoints, density modes
- [ ] A11y notes include contrast table, focus ring spec, motion reduction
- [ ] Component inventory ≤ 12 core components (apply inventory discipline)
- [ ] All values traceable to brand mood board
- [ ] No CSS, no implementation technology specified
