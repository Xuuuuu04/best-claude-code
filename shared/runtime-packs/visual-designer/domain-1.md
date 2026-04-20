# 视觉设计师 — Domain 1: Token System Architecture

## 1.1 Color Token Hierarchy

### 1.1.1 Primitive Color Scale Construction

Build 9-11 step hue scales using HSL or OKLCH color space:

| Step | Purpose | Example (Blue) |
|---|---|---|
| 50 | Near-white tint | #EFF6FF |
| 100 | Very light | #DBEAFE |
| 200 | Light | #BFDBFE |
| 300 | Light-medium | #93C5FD |
| 400 | Medium-light | #60A5FA |
| 500 | Base hue | #3B82F6 |
| 600 | Primary action | #2563EB |
| 700 | Dark | #1D4ED8 |
| 800 | Very dark | #1E40AF |
| 900 | Near-black shade | #1E3A8A |

**Construction principles**:
- 500 is the "base" hue — the color at full saturation/value
- Steps below 500 are tints (mixed with white)
- Steps above 500 are shades (mixed with black)
- Perceptual uniformity: visual difference between 50→100 should feel similar to 800→900
- Use OKLCH for better perceptual uniformity than HSL

**Required hues**:
- Primary brand color (1 hue)
- Neutral gray scale (1 hue, essential)
- Semantic hues: success (green), warning (amber), error (red), info (blue)
- Optional: secondary brand color, accent color

### 1.1.2 Semantic Color Mapping Strategy

Semantic tokens map primitives to UI roles. Each semantic token has light-mode and dark-mode values.

**Semantic role categories**:

| Category | Roles | Light Mode | Dark Mode |
|---|---|---|---|
| Interactive | primary, secondary, destructive | Blue-600 | Blue-400 |
| Surface | primary, secondary, overlay, elevated | White, Gray-50 | Gray-950, Gray-900 |
| Text | primary, secondary, disabled, inverse, on-interactive | Gray-900, Gray-600 | Gray-50, Gray-400 |
| Border | default, focused, error | Gray-200, Blue-500, Red-500 | Gray-700, Blue-400, Red-400 |
| Feedback | success, warning, error, info | Green-600, Amber-600, Red-600, Blue-600 | Green-400, Amber-400, Red-400, Blue-400 |

**Mapping example**:
```json
{
  "semantic": {
    "interactive-primary": {
      "light": "{primitive.blue.600}",
      "dark": "{primitive.blue.400}"
    },
    "text-primary": {
      "light": "{primitive.gray.900}",
      "dark": "{primitive.gray.50}"
    },
    "surface-primary": {
      "light": "#FFFFFF",
      "dark": "{primitive.gray.950}"
    }
  }
}
```

### 1.1.3 WCAG Contrast Verification

**Relative luminance formula**:
```
For sRGB color component C:
  C_srgb = C / 255
  if C_srgb <= 0.03928: C_lin = C_srgb / 12.92
  else: C_lin = ((C_srgb + 0.055) / 1.055) ^ 2.4

L = 0.2126 * R_lin + 0.7152 * G_lin + 0.0722 * B_lin
```

**Contrast ratio**:
```
CR = (L1 + 0.05) / (L2 + 0.05)
(where L1 is the lighter color, L2 is the darker color)
```

**WCAG 2.1 AA thresholds**:

| Element Type | Minimum Ratio | Example Pair |
|---|---|---|
| Body text (< 18pt regular, < 14pt bold) | 4.5:1 | #1A1A1A on #FFFFFF = 18.1:1 ✓ |
| Large text (≥ 18pt regular, ≥ 14pt bold) | 3:1 | #2563EB on #FFFFFF = 8.6:1 ✓ |
| UI components (borders, icons, graphs) | 3:1 | #6B7280 on #FFFFFF = 4.7:1 ✓ |
| Placeholder text | 4.5:1 (same as body) | #9CA3AF on #FFFFFF = 2.7:1 ✗ |

**Verification workflow**:
1. For each text/background semantic pair, compute contrast ratio
2. If ratio ≥ threshold → token approved
3. If ratio < threshold → adjust primitive value → recompute → repeat
4. Only write verified pairs to token file

## 1.2 Spacing and Typography Scale

### 1.2.1 Base-Unit Rhythm System

**Base unit selection**:
- 4px for dense B2B interfaces (data tables, dashboards)
- 8px for consumer interfaces (marketing, content)

**Spacing scale** (4px base):

| Token | Value | Common Use |
|---|---|---|
| spacing-1 | 4px | Tight gaps, icon padding |
| spacing-2 | 8px | Inline spacing, small gaps |
| spacing-3 | 12px | Button padding (vertical) |
| spacing-4 | 16px | Card padding, section gaps |
| spacing-5 | 20px | Button padding (horizontal) |
| spacing-6 | 24px | Form section gaps |
| spacing-8 | 32px | Card margins |
| spacing-10 | 40px | Section spacing |
| spacing-12 | 48px | Large section gaps |
| spacing-16 | 64px | Page sections |
| spacing-20 | 80px | Hero spacing |
| spacing-24 | 96px | Major divisions |

**Rule**: Never use values between steps. No 14px, no 18px, no 28px.

### 1.2.2 Modular Type Scale

**Ratio selection**:
- Minor Third (1.250): dense UIs, more sizes fit in small range
- Major Third (1.333): display-heavy, more dramatic hierarchy
- Perfect Fourth (1.414): marketing, maximum drama

**Type scale example** (Minor Third, 16px base):

| Token | Size | Line Height | Weight | Use Case |
|---|---|---|---|---|
| text-xs | 12px | 1.5 (18px) | 400 | Captions, helper text |
| text-sm | 14px | 1.5 (21px) | 400 | Secondary text, labels |
| text-base | 16px | 1.5 (24px) | 400 | Body text |
| text-lg | 18px | 1.5 (27px) | 400 | Lead paragraph |
| text-xl | 20px | 1.4 (28px) | 500 | Section heading |
| text-2xl | 24px | 1.3 (31px) | 600 | Subsection heading |
| text-3xl | 30px | 1.2 (36px) | 600 | Page heading |
| text-4xl | 36px | 1.1 (40px) | 700 | Hero heading |
| text-5xl | 48px | 1.1 (53px) | 700 | Display text |

**Line height principles**:
- Decreases as size increases (body 1.5, display 1.1)
- Prevents large headings from having excessive spacing
- Maintains readability at all sizes

### 1.2.3 Chinese/English Mixed Typography

**CJK considerations**:
- CJK glyphs have different x-height ratios than Latin
- Chinese text needs 1.7–1.8 line height (vs 1.5 for Latin)
- Minimum font size for Chinese: 12px (smaller becomes illegible)
- Use system font stack for Chinese: -apple-system, "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei"

**Punctuation spacing**:
- Full-width punctuation (。，！？) for Chinese text
- Half-width punctuation for English text
- Mixed content: follow the primary language of the sentence

**Font stack example**:
```css
/* Not written by visual-designer — this is reference for @frontend */
font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
  "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei",
  "Helvetica Neue", Arial, sans-serif;
```

## 1.3 Motion and Interaction Tokens

### 1.3.1 Duration Scale

| Token | Duration | Use Case | Perception |
|---|---|---|---|
| duration-fast | 100–150ms | Micro-feedback (button press, toggle) | Instant |
| duration-normal | 200–250ms | UI state transitions (hover, focus) | Snappy |
| duration-slow | 300–400ms | Emphasis (modal open, page transition) | Smooth |
| duration-emphasis | 500–600ms | Brand moments (success animation, onboarding) | Deliberate |

**Rule**: Above 600ms is typically experienced as broken or slow. Avoid unless intentionally dramatic.

### 1.3.2 Easing Semantics

| Easing | Curve | Use Case |
|---|---|---|
| ease-in | cubic-bezier(0.4, 0, 1, 1) | Elements exiting screen |
| ease-out | cubic-bezier(0, 0, 0.2, 1) | Elements entering screen |
| ease-in-out | cubic-bezier(0.4, 0, 0.2, 1) | Position changes within viewport |
| spring | Custom bezier or spring physics | Interactive/draggable elements |

**Easing selection guide**:
- **ease-out** for entering elements: arrives quickly, settles smoothly
- **ease-in** for exiting elements: starts slowly, accelerates out
- **ease-in-out** for toggles and switches: balanced feel
- **spring** for playful interactions: overshoot and settle

**Reduced motion**:
```json
{
  "motion": {
    "reduced": {
      "duration": { "$type": "duration", "$value": "0ms" },
      "easing": { "$type": "cubic-bezier", "$value": [0, 0, 0, 0] }
    }
  }
}
```

When `prefers-reduced-motion: reduce` is active, all transitions become instant.
