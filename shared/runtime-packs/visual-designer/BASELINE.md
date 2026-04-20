# 视觉设计师 — Baseline Scenarios

## Scenario 1: Full Design System Build (Canonical)

**Input**:
- Brand mood board from @creative: "cold precision — Scandinavian minimalism — surgical authority" — cool blue primary, geometric sans-serif, tight spacing
- Tech stack: React + shadcn/ui
- A11y target: WCAG AA
- Platform: web (desktop + mobile)

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Token file: W3C Design Tokens format
  - Primitive color: blue scale (50-900) + neutral scale (50-900) + semantic colors (success/warning/error/info)
  - Both light + dark mode semantic mappings
  - All contrast pairs verified: text.primary on surface.primary: 18.1:1 ✓ | interactive.primary on surface.primary: 8.59:1 ✓
  - Spacing: 4px base (B2B dense), scale: 4px to 96px
  - Typography: Minor Third ratio (1.250), xs-5xl, line heights, weights
  - Radius: none / sm(2px) / md(4px) / lg(8px) / xl(12px) / full(9999px)
  - Shadow: 5 elevation levels
  - Motion: 4 durations + 3 easings
- Component specs: 9 core components with full states matrices (each component: anatomy + token refs + all states)
- Layout: 4/8/12 column grid at mobile/tablet/desktop with pixel breakpoints
- A11y statement: all critical pairs PASS, focus ring: 2px solid --color-interactive-primary offset 2px, motion: prefers-reduced-motion respected
- Deliverable files: design-tokens.json + component-spec.md + layout-spec.md + a11y-notes.md
- Next step: @frontend for implementation

**Key Decision Points**:
- Token hierarchy strictly enforced — no raw hex in component specs
- Dark mode semantic tokens designed simultaneously (blue-600 light → blue-400 dark)
- States matrix completed before any component marked done
- shadcn/ui compatibility noted: extending existing CSS variables, not replacing

---

## Scenario 2: Incremental Component Addition (Complex)

**Input**:
- Existing design system v1.2 in place
- Request: add a Data Table component with sorting, filtering, pagination, and empty state
- Current system has: Button, Input, Select, Card, Modal — but no Table

**Expected Output Structure**:
- Status: READY-FOR-NEXT
- Read existing design-tokens.json → confirmed all needed tokens exist (text, surface, border, interactive, feedback)
- No new tokens needed — all states use existing semantic tokens
- Component spec — Data Table anatomy: table container, column header (sort indicator), row (hover, selected, disabled), cell, pagination bar, empty state, filter row
- States matrix: default rows, row-hover, row-selected, column-header-sort-asc/desc, loading skeleton, empty state
- Composition: Data Table contains Button (pagination actions) + Select (rows-per-page) + Checkbox (row selection) — all from existing inventory
- A11y: `role="table"`, `aria-sort` on sortable headers, `aria-label` on pagination
- No token file changes — component-spec.md updated only
- Next step: @frontend for implementation

**Key Decision Points**:
- Did NOT add new tokens because existing semantic tokens covered all states
- Did NOT invent a new "TableButton" variant — reused existing Button component
- States matrix included empty state explicitly (often forgotten)

---

## Scenario 3: No Brand Mood Board (Blocked)

**Input**:
- Request: "Build the design system for our new product"
- No mood board document exists
- User says "just make it look professional and modern"

**Expected Output Structure**:
- Status: BLOCKED
- Blocked on: Brand mood board from @creative not available
- Blocked by: @creative / user / @pm
- Rationale: "A design system built without a brand brief is aesthetic guesswork. 'Professional and modern' is not a specification — it describes roughly 60% of current design systems. Without specific direction on color personality (warm vs cool, saturated vs muted), typography character (geometric vs humanist vs transitional), spacing rhythm (dense vs airy), and motion character (snappy vs smooth vs playful), I would be making brand decisions that belong to @creative. Any system I build now will require revision when brand direction is established."
- What I need from @creative:
  1. Primary color family and emotional intent (e.g., "cool blue — trust and precision" or "warm amber — energy and creativity")
  2. Typography personality (geometric, humanist, transitional, serif/sans preference)
  3. Design movement references (2-3 products or design systems with similar character)
  4. Interaction character (snappy/responsive vs smooth/considered vs playful)
  5. Density default (information-dense B2B vs spacious consumer)
