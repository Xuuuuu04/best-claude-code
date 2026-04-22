---
name: visual-design
description: Design system specification methodology for the Harness team. Covers the three-layer token hierarchy (primitive / semantic / component), color scale construction with WCAG contrast verification, spacing and typography scale systems, motion and interaction tokens, component anatomy and states matrix specification, layout grids and breakpoints, density modes, and A11y compliance integration as a design constraint.
type: skill
---

# Visual Design Skill

## 1. Token Hierarchy

Three-layer cascade enforced on every token:

| Layer | Naming | Example |
|---|---|---|
| **Primitive** | Named for what it IS | `--color-blue-600: #2563EB` |
| **Semantic** | Named for what it DOES | `--color-interactive-primary: var(--color-blue-600)` |
| **Component** | Named for role in component | `--button-primary-bg: var(--color-interactive-primary)` |

Breaking this hierarchy — referencing primitives directly from components — is the most common design system anti-pattern and the root cause of most token drift.

## 2. Color Token System

**Primitive scale**: 9-11 steps per hue (50 through 900). Use HSL or OKLCH; verify perceptual uniformity. Design dark mode palettes simultaneously.

**Semantic mapping**: each semantic token maps to a light-mode primitive + a dark-mode primitive.

Key semantic roles:
- Interactive: primary, secondary, destructive
- Surface: primary, secondary, overlay
- Text: primary, secondary, disabled, inverse
- Border: default, focused, error
- Feedback: success, warning, error, info

## 3. WCAG Contrast Verification

Contrast ratio formula: `(L1 + 0.05) / (L2 + 0.05)` where `L = 0.2126R + 0.7152G + 0.0722B`

| Element Type | WCAG 2.1 AA Ratio |
|---|---|
| Body text | ≥ 4.5:1 |
| Large text (≥18pt regular or ≥14pt bold) | ≥ 3:1 |
| UI components (borders, icons) | ≥ 3:1 |
| Placeholder text | ≥ 4.5:1 (treated as regular text) |

A11y check at semantic token layer: every text/background pair must pass in both light and dark modes before the token is finalized.

## 4. Spacing and Typography

**Spacing**: base unit (4px for dense B2B, 8px for consumer). Scale: 1x, 1.5x, 2x, 3x, 4x, 5x, 6x, 8x, 10x, 12x, 16x. Never values between steps.

**Typography scale**: Minor Third (1.250) for dense UIs, Major Third (1.333) for display-heavy. Line height decreases as size increases (body 1.6-1.8, display 1.1-1.2).

**CJK considerations**: Chinese text needs 1.7-1.8 line height vs 1.5 for Latin. Specify punctuation spacing (全角 vs 半角).

## 5. Motion and Interaction Tokens

**Duration scale**:
- Fast 100-150ms: micro-feedback
- Normal 200-250ms: UI state transitions
- Slow 300-400ms: emphasis
- Emphasis 500-600ms: brand moments
- Above 600ms typically experienced as broken

**Easing semantics**:
- ease-in: elements exiting screen
- ease-out: elements entering (arrive and settle)
- ease-in-out: position changes within visible area
- spring: interactive/draggable elements

## 6. Component Specification

**Minimum inventory**: Button, Input, Checkbox/Radio, Select, Card, Modal, Table/List, Form Layout, Navigation.

**Anatomy**: decompose into named parts with token references (e.g., Button: container, label, icon, focus-ring).

**States matrix** (every interactive component):

| State | Visual Change | Token Ref | Notes |
|---|---|---|---|
| default | [desc] | --token | |
| hover | [desc] | --token | cursor: pointer |
| focus | [desc] | focus ring spec | WCAG 2.4.7 |
| active | [desc] | --token | |
| disabled | [desc] | opacity + cursor | WCAG 1.4.3 |
| loading | [desc] | spinner/skeleton | |
| error | [desc] | --feedback-error | |

## 7. Layout Specification

**Grid system**:
- Mobile: 4 columns, 16px margin/gutter
- Tablet: 8 columns, 24px margin, 20px gutter
- Desktop: 12 columns, 24px margin/gutter

**Breakpoints**: <640px / 640-1024px / 1024-1440px / >1440px

**Density modes**:
- Compact (B2B): spacing scale −1 step, font size −1 step for secondary
- Comfortable (consumer): spacing scale +1 step, higher line height

## 8. A11y Compliance Requirements

- **Focus ring**: minimum 2px solid, 2px offset, 3:1 contrast against element AND page background. Never remove outline without visible alternative.
- **Color independence**: information conveyed by color must have secondary non-color indicator (shape, pattern, label, icon). Grayscale test: all info still decipherable?
- **Motion reduction**: `prefers-reduced-motion` accommodation for all animated transitions.

## 9. Anti-Patterns

| Name | Symptom | Correction |
|---|---|---|
| **Token Drift** | Tokens not honoring upstream brand concept | Every token traceable to brand mood board |
| **Magic-Number** | Spacing values not on scale (e.g., 12px 18px padding) | All spacing values must be on the spacing scale |
| **A11y Afterthought** | Contrast check after complete system delivery | Verify every semantic pair at definition time |
| **Inventory Explosion** | 40+ components when 12 composable ones suffice | One component with variant/size/loading props |
| **State Amnesia** | Only default state defined, others vague | Complete states matrix before spec is deliverable |
| **Light-Only Delivery** | No dark-mode mappings | Dark mode is a design constraint, not a retrofit |
