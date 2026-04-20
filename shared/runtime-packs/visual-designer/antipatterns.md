> 源：core.md §Anti-Patterns + §Rules (Primacy Anchor)

# 视觉设计师 — Anti-Patterns

## Named Anti-Patterns

---

### Token Drift

**Definition**: Tokens that do not honor the upstream brand concept from @creative. Values chosen for personal preference or convenience rather than brand alignment.

**Manifestations**:

```json
// BAD — token drift
{
  "color": {
    "interactive-primary": "#FF5733" // Orange-red chosen because designer likes it
  }
}
// Brand mood board specifies: "cool blue — trust and precision"
// The orange-red is a drift from the brand concept.
```

```json
// BAD — semantic token references wrong primitive
{
  "semantic": {
    "text-primary": "#000000" // Hardcoded black instead of referencing primitive
  }
}
// Breaks hierarchy: changing primitive scale doesn't update semantic token.
```

**Why it's dangerous**: Token drift compounds. After 20 components, the system no longer reflects the brand. When the brand updates, changes don't cascade because tokens are hardcoded or misaligned. The design system becomes unmaintainable.

**Correction**: Every token value must be traceable to a statement in the brand mood board.

```json
// GOOD — brand-aligned token
{
  "primitive": {
    "blue": {
      "600": "#2563EB" // From brand mood board: "primary blue"
    }
  },
  "semantic": {
    "interactive-primary": "{primitive.blue.600}" // References primitive
  }
}
// Traceability: mood board "trust and precision" → blue family → blue-600 → semantic
```

---

### Magic-Number Proliferation

**Definition**: Spacing values in component specs that are not on the spacing scale. Arbitrary values that break rhythm and composability.

**Manifestations**:

```markdown
// BAD — magic numbers
Button padding: 12px 18px  // 12 and 18 are not on 4px scale
Card padding: 14px         // 14 is not on 4px scale
Modal margin-top: 23px     // 23 is not on 4px scale
```

**Why it's dangerous**: Magic numbers create visual inconsistency. Components don't align to the grid. Spacing feels arbitrary. When the base unit changes (e.g., 4px → 8px for rebrand), magic numbers must be manually updated one by one.

**Correction**: Any spacing value in a component spec must be on the spacing scale.

```markdown
// GOOD — scale values only
Spacing scale (4px base): 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96

Button padding: --spacing-3 --spacing-5  // 12px 20px ✓
Card padding: --spacing-6                // 24px ✓
Modal margin-top: --spacing-10           // 40px ✓
```

---

### A11y Afterthought

**Definition**: Delivering a complete component system then running a contrast check that fails, requiring foundational token revisions with cascade effects.

**Manifestations**:

```markdown
// BAD — A11y afterthought
Week 1: Design all tokens and components
Week 2: Deliver to @frontend
Week 3: @test-ui runs accessibility check
Week 4: Discover 12 contrast failures
Week 5: Revise primitive colors, cascade changes through all components
Week 6: Re-deliver to @frontend

// 5 weeks of rework because A11y was not built in.
```

**Why it's dangerous**: A11y failures at the token level require changing primitive values, which cascade through semantic tokens, component tokens, and all component specs. This is the most expensive type of design system revision.

**Correction**: Verify every semantic text/background color pair at definition time.

```markdown
// GOOD — A11y at token definition time
Step 1: Define --color-text-primary and --color-surface-primary
Step 2: Compute contrast ratio
Step 3: If >= 4.5:1 → write token
Step 4: If < 4.5:1 → adjust primitive value → recompute → repeat
Step 5: Only write verified pairs

Result: Zero contrast failures at delivery time.
```

---

### Component Inventory Explosion

**Definition**: Designing 40+ components when 12 composable ones would cover the same UI surface. Creating narrowly specialized components instead of flexible, variant-driven ones.

**Manifestations**:

```markdown
// BAD — inventory explosion
Components designed:
- PrimaryButton
- SecondaryButton
- DangerButton
- GhostButton
- SmallPrimaryButton
- SmallSecondaryButton
- LargePrimaryButton
- IconPrimaryButton
- IconSecondaryButton
- LoadingPrimaryButton
- LoadingSecondaryButton
- ... (40+ components)

// Each is a separate component with separate specs.
// Maintenance nightmare: change button radius → update 40 specs.
```

**Why it's dangerous**: Component inventory explosion creates maintenance burden, increases bundle size, and reduces consistency. Every "special" component is an opportunity for drift.

**Correction**: One component with variant/size/loading/icon-position props.

```markdown
// GOOD — composable component
Button component with props:
- variant: primary | secondary | danger | ghost
- size: sm | md | lg
- loading: true | false
- icon: left | right | none
- iconName: string (when icon != none)

// One spec, one implementation, infinite combinations.
// Change radius → update one spec.
```

---

### State Amnesia

**Definition**: Component specs defining only the default state and leaving other states as vague annotations ("error state: red"). Frontend developers must invent the unspecified states.

**Manifestations**:

```markdown
// BAD — state amnesia
## Button Component

Default: blue background, white text
Hover: slightly darker
Disabled: 50% opacity

// Missing: focus, active, loading, error states
// "Slightly darker" is not a token reference.
// "50% opacity" is not a token reference.
```

**Why it's dangerous**: When states are unspecified, @frontend invents them. Each developer invents differently. The result is inconsistent focus rings, unpredictable disabled states, and accessibility failures.

**Correction**: Complete states matrix for every interactive component.

```markdown
// GOOD — complete states matrix
## Button Component

| State | Background | Text | Border | Shadow | Transform | Transition | Notes |
|---|---|---|---|---|---|---|---|
| default | --color-interactive-primary | --color-text-on-interactive | none | none | none | --duration-fast | |
| hover | --color-interactive-primary-hover | --color-text-on-interactive | none | --shadow-low | translateY(-1px) | --duration-normal --easing-ease-out | cursor: pointer |
| focus | --color-interactive-primary | --color-text-on-interactive | 2px solid --color-interactive-primary | none | none | --duration-fast | outline-offset: 2px; WCAG 2.4.7 |
| active | --color-interactive-primary-active | --color-text-on-interactive | none | none | translateY(0) | --duration-fast | |
| disabled | --color-interactive-primary @ --opacity-disabled | --color-text-on-interactive @ --opacity-disabled | none | none | none | none | cursor: not-allowed |
| loading | --color-interactive-primary | --color-text-on-interactive | none | none | none | none | spinner replaces label |
| error | --feedback-error-bg | --feedback-error-text | 1px solid --feedback-error-border | none | none | --duration-fast | |
```

---

### Light-Only Delivery

**Definition**: Delivering light-mode tokens without simultaneous dark-mode mappings, treating dark mode as a future enhancement.

**Manifestations**:

```json
// BAD — light-only delivery
{
  "semantic": {
    "text-primary": "#1A1A1A",
    "surface-primary": "#FFFFFF"
    // No dark mode mappings
  }
}
```

**Why it's dangerous**: Dark mode is not a retrofit. When added later, every semantic token must be revisited, and every component spec must be updated. The "quick" dark mode addition becomes a multi-week project.

**Correction**: Design light and dark mode simultaneously.

```json
// GOOD — simultaneous light+dark
{
  "semantic": {
    "text-primary": {
      "light": "#1A1A1A",  // References primitive.gray.900
      "dark": "#F5F5F5"    // References primitive.gray.50
    },
    "surface-primary": {
      "light": "#FFFFFF",   // References primitive.white
      "dark": "#0A0A0A"    // References primitive.gray.950
    }
  }
}
```

---

### Raw-Hex-in-Component

**Definition**: Using raw hex values directly in component specs instead of referencing component or semantic tokens.

**Manifestations**:

```markdown
// BAD — raw hex in component spec
## Card Component

Background: #FFFFFF        // Raw hex!
Border: 1px solid #E5E7EB  // Raw hex!
Shadow: 0 1px 3px #0000001A // Raw hex!
```

**Why it's dangerous**: Raw hex values in component specs bypass the token hierarchy. When the brand color changes, these values are missed. When dark mode is added, these values are wrong. The component becomes inconsistent with the system.

**Correction**: Every value in a component spec must reference a token.

```markdown
// GOOD — token references only
## Card Component

Background: --color-surface-primary      // Semantic token
Border: 1px solid --color-border-default // Semantic token
Shadow: --shadow-low                      // Primitive token
Padding: --spacing-6                      // Primitive token
Radius: --radius-lg                       // Primitive token
```
