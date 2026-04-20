# 视觉设计师 — Domain 2: Component Specification

## 2.1 Component Anatomy

### 2.1.1 Named Parts Methodology

Decompose each component into named parts with token references:

**Button anatomy**:

| Part | Token Reference | Description |
|---|---|---|
| container | --button-primary-bg | Background fill |
| container-border | --button-primary-border | Border stroke (if any) |
| container-radius | --radius-md | Corner rounding |
| label | --button-primary-text | Text content color |
| label-typography | --typography-sm / --weight-medium | Font properties |
| icon | --button-primary-icon | Icon glyph color |
| icon-size | --icon-sm | Icon dimensions |
| focus-ring | --color-interactive-primary | Focus indicator color |
| focus-ring-offset | --spacing-1 | Gap between element and focus ring |

**Input anatomy**:

| Part | Token Reference | Description |
|---|---|---|
| container | --input-bg | Background fill |
| container-border | --input-border | Border stroke |
| container-radius | --radius-md | Corner rounding |
| label | --input-label-text | Field label color |
| label-typography | --typography-sm / --weight-medium | Label font |
| text | --input-text | User input color |
| text-typography | --typography-base / --weight-normal | Input font |
| placeholder | --input-placeholder-text | Placeholder color |
| helper-text | --input-helper-text | Helper/error text color |
| icon-leading | --input-icon | Leading icon color |
| icon-trailing | --input-icon | Trailing icon/button color |

### 2.1.2 States as Design Problems

Every state is a design problem as important as the default state:

**Hover state**: Affordance signal
- Must be clearly different from default
- Indicates interactivity
- Common pattern: background darkens/lightens, shadow increases

**Focus state**: Must be clearly visible (WCAG 2.4.7)
- Minimum: 2px solid outline
- Offset: 2px from element edge
- Contrast: 3:1 against element background AND page background
- Never remove outline without visible alternative

**Active/pressed state**: Physically responsive
- Visually depresses (translateY(0) from hover's translateY(-1px))
- Darker than hover
- Immediate feedback (duration-fast)

**Disabled state**: Non-interactivity without rejection
- Reduced opacity (40-50%)
- Cursor: not-allowed
- Still readable (contrast requirements apply)
- No hover/active effects

**Loading state**: Progress indication
- Spinner or skeleton replaces content
- aria-busy="true" for screen readers
- Disabled interaction while loading

**Error state**: Problem indication
- Border color changes to error color
- Error message appears below field
- Icon may indicate error state
- Still interactive (user can correct)

### 2.1.3 Composition Rules

Define what components can nest and how:

**Allowed compositions**:
- Card can contain: Button, Input, Text, Image, Icon
- Modal can contain: Card, Button, Form, Header
- Form Layout can contain: Input, Select, Checkbox, Button
- Table can contain: Button (actions), Checkbox (selection), Badge (status)

**Forbidden compositions** (prevent UX anti-patterns):
- Modal inside Modal (dialog stacking)
- Card inside Card (excessive nesting)
- Button inside Button (invalid HTML, confusing interaction)
- Select inside Select (cascading dropdowns)

## 2.2 Component Inventory Management

### 2.2.1 Core Component Set

Minimum 8 composable components cover 80%+ of UI needs:

| # | Component | States | Variants | Complexity |
|---|---|---|---|---|
| 1 | Button | 7 | 4 variants × 3 sizes | Medium |
| 2 | Input | 6 | 3 sizes, with/without icon | Medium |
| 3 | Checkbox/Radio | 5 | 2 sizes | Low |
| 4 | Select | 6 | 3 sizes, single/multi | High |
| 5 | Card | 4 | 3 elevations | Low |
| 6 | Modal | 5 | 3 sizes | Medium |
| 7 | Table/List | 5 | sortable, selectable | High |
| 8 | Form Layout | 3 | 2 densities | Low |
| 9 | Navigation | 4 | horizontal/vertical | Medium |

### 2.2.2 New Component Evaluation

Before adding a new component, answer three questions:

1. **Can this be composed from existing components?**
   - Example: "Date picker" → Compose Input + Calendar overlay (existing)
   - Example: "File upload" → Compose Button + Hidden input + Progress (existing)

2. **Will it be used in ≥3 places?**
   - One-off components belong in the feature, not the system
   - System components must earn their maintenance cost

3. **Does it require a new token?**
   - If yes: evaluate if the token belongs in the system
   - If no: compose from existing tokens

**Evaluation matrix**:

| Can compose? | ≥3 places? | New token? | Decision |
|---|---|---|---|
| Yes | — | — | Compose, don't add |
| No | No | — | Feature-level component |
| No | Yes | No | Add to system |
| No | Yes | Yes | Add token + component |

## 2.3 Design System Design Movements

### 2.3.1 Reference Systems

Know these systems to follow or deliberately diverge:

| System | Strengths | When to Reference |
|---|---|---|
| Material Design 3 | Comprehensive, well-documented, dynamic color | Android apps, Google ecosystem |
| Apple HIG | Polished, motion-rich, platform-native | iOS/macOS apps |
| Fluent Design 2 | Productivity-focused, accessible, modular | Windows apps, Microsoft ecosystem |
| Ant Design | Enterprise-focused, dense data, Chinese market | B2B web apps |
| shadcn/ui | Composable, Tailwind-native, unopinionated | React web apps |
| Radix UI | Headless, accessible, primitive-focused | Custom design systems |

### 2.3.2 Existing System Compatibility

When product uses an existing library, the design system spec should extend, not compete:

| Library | Strategy | Notes |
|---|---|---|
| shadcn/ui | Extend CSS variables, add semantic tokens | Compatible with Tailwind |
| Ant Design | Override theme tokens, add custom components | Less flexible token system |
| MUI | Override theme, use styled API | Heavy customization needed |
| Radix UI | Add visual layer on top of primitives | Maximum flexibility |
| Bootstrap | Override Sass variables | Limited token hierarchy |

**Compatibility documentation**:
```markdown
## shadcn/ui Compatibility

Extended tokens:
- --color-primary → mapped to --color-interactive-primary
- --color-secondary → mapped to --color-interactive-secondary

Added tokens:
- --color-surface-overlay (not in shadcn default)
- --shadow-floating (not in shadcn default)

Overridden values:
- --radius-md: 4px (shadcn default: 6px)
```
