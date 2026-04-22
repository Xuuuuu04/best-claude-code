---
name: frontend-implementation
description: Browser-side implementation methodology for the Harness team. Covers 5-state UI contract, token fidelity, three-layer form validation, A11y baseline, component boundary discipline, and implementation layer order. Supports React/Vue/TypeScript stacks. Loaded by @frontend via skills: frontmatter.
type: skill
---

# Frontend Implementation Skill

## 1. 5-State UI Contract

Every interactive page/component MUST implement all five states. Missing any state = prototype, not production.

| State | Description | UI Treatment |
|-------|-------------|--------------|
| **Initial** | First load, before user interaction | Skeleton or placeholder layout |
| **Empty** | No data to display | Helpful empty state with action offered |
| **Loading** | Async operation in progress | Spinner/skeleton, disable submit buttons |
| **Success** | Normal operational state with data | Full content render |
| **Error** | Operation failed or validation error | Error message with retry/escape path |

## 2. Token Fidelity

Every style property MUST reference @visual-designer tokens. Hardcoded values are forbidden.

- CSS variable references: `var(--token-color-primary)`
- Tailwind token classes: `bg-primary text-body`
- If token does not exist → BLOCK and route to @visual-designer
- Building with invented values creates **token drift**

## 3. Three-Layer Validation Stack

| Layer | Trigger | Purpose |
|-------|---------|---------|
| **Layer 1** | onChange | Inline hints, real-time feedback for UX |
| **Layer 2** | onBlur/onSubmit | Pre-submit gate, blocks invalid submission |
| **Layer 3** | Server response | Display server-side errors without assumption |

Frontend validation is for UX only — never blocks server interactions based on frontend permission assumptions.

## 4. A11y Baseline (6 Items)

Present from day one, not added as afterthought:

1. **Keyboard navigable**: all interactive elements reachable via Tab
2. **Focus rings**: visible focus indicator on all interactive elements
3. **Alt on images**: meaningful alt text or decorative marking
4. **Labels on inputs**: every input has associated `<label>` or aria-label
5. **ARIA attributes**: appropriate roles, states, and properties
6. **Contrast ratio**: WCAG AA minimum (4.5:1 normal text, 3:1 large text/UI components)

## 5. Component Boundary Discipline

- **Container components**: own logic, state, data fetching
- **Presentational components**: receive props, render UI, emit events
- Mixing them creates components that cannot be tested in isolation

## 6. Implementation Layer Order

1. **API layer**: typed API function (request function, response type, error type)
2. **State layer**: React Query `useQuery`/`useMutation`, Zustand slice, or Pinia store
3. **Form schema (if applicable)**: Zod/Yup schema with field types, constraints, messages
4. **Component structure**: HTML/JSX/Vue Template with semantic tags (`<button>` not `<div onClick>`)
5. **Token-referenced styles**: CSS variables or Tailwind classes. Zero hardcoded values.
6. **5-state coverage**: implement each state explicitly
7. **A11y**: keyboard, focus, ARIA, alt, labels, contrast

## 7. Self-Check Before Handoff

Before recommending @code-review:
- [ ] 5-state check: open in browser, observe each state manually
- [ ] Console errors: zero errors in browser console
- [ ] TypeScript: `tsc --noEmit` passes
- [ ] Token compliance: verify no hardcoded values
- [ ] Mobile 375px: responsive at smallest breakpoint
- [ ] API discrepancies: document any endpoint deviations, route to @dev-lead

## 8. Auth Token Storage

NEVER store auth tokens in localStorage/sessionStorage when httpOnly Cookie is available.
- Tokens in JS-accessible storage = XSS-extractable
- If spec requires localStorage for justified reason, document security tradeoff explicitly

## 9. Anti-Patterns

**Token Drift**: hardcoded values instead of token references. Correction: BLOCK on missing tokens.
**5-State Amnesia**: implementing only happy path. Correction: all 5 states mandatory.
**Validation Theater**: frontend validation without server authority. Correction: 3-layer stack.
**A11y Afterthought**: adding accessibility post-implementation. Correction: baseline from day one.
**Boundary Violation**: frontend modifying API contracts unilaterally. Correction: route discrepancies to @dev-lead.
**Hydration Mismatch**: SSR/client render producing different HTML. Correction: ensure deterministic renders.
**Premature Memoization**: memoizing before measuring. Correction: profile first, optimize second.
**Memory Leak**: unsubscribed listeners, uncleaned intervals. Correction: cleanup in useEffect/destroyed.
