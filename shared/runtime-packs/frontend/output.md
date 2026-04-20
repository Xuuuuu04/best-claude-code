> 源：core.md §Output Contract + §Dispatch Signals + §Skill References

# 前端开发师 — Output Contract & Dispatch Signals

## Output Contract

```
## Frontend Implementation Handoff: [Task ID] — [Feature Name]

**Status**: READY-FOR-NEXT | BLOCKED | FAILED

**Changed Files**: [file path: what changed]

**5-State Coverage**:
- Initial: [IMPLEMENTED — description]
- Empty: [IMPLEMENTED — description + what action offered]
- Loading: [IMPLEMENTED — skeleton/spinner used]
- Success: [IMPLEMENTED — description]
- Error: [IMPLEMENTED — error display + retry mechanism]

**Token Compliance**: All style properties reference tokens [YES / NO — list exceptions with @visual-designer routing]
**A11y Baseline**: keyboard navigable / focus rings / alt on images / labels on inputs / aria-live / contrast ratio
**Form Validation** (if applicable): Layer 1 (onChange hints) / Layer 2 (pre-submit gate) / Layer 3 (server error display)

**Self-Check Results**:
- Console errors: [NONE / list]
- Main flow walkthrough: [PASS / FAIL]
- Mobile viewport (375px): [PASS / FAIL]
- TypeScript type check: [PASS / FAIL]

**API Discrepancies Found**: [endpoint: expected vs. actual — routed to @dev-lead] / NONE

**Recommended Next Steps**:
- @code-review: [one-sentence summary]
- @test-ui: capture screenshots for [screens + states + viewports]
```

---

## Filled-In Example — T-019 Invitation Management UI

```
## Frontend Implementation Handoff: T-019 — Invitation Management UI

**Status**: READY-FOR-NEXT

**Changed Files**:
- src/views/InvitationView.vue: new page container with route guard and 5-state logic
- src/components/InvitationList.vue: list component with skeleton/empty/error states
- src/components/InvitationCard.vue: individual invitation card with status badge
- src/components/InviteForm.vue: form with 3-layer validation + server error mapping
- src/stores/invitation.ts: Pinia store with fetchInvitations and createInvitation actions
- src/api/invitation.ts: typed API functions with Zod validation

**5-State Coverage**:
- Initial: IMPLEMENTED — SkeletonList with 3 placeholder rows rendered before first fetch completes
- Empty: IMPLEMENTED — EmptyState component with envelope icon, "No invitations sent yet", "Invite your first member" CTA button
- Loading: IMPLEMENTED — SkeletonList with animated pulse on list refresh; spinner in Send button during mutation
- Success: IMPLEMENTED — InvitationList rendering InvitationCard per invitation (email, status badge, expiry date)
- Error: IMPLEMENTED — ErrorState with "Could not load invitations" message + Retry button calling store.fetchInvitations()

**Token Compliance**: All style properties reference tokens: YES
- All spacing uses var(--spacing-*) tokens
- All colors use var(--color-*) tokens from @visual-designer token file
- Border radius uses var(--radius-card) token

**A11y Baseline**:
- keyboard navigable: YES — all interactive elements reachable by Tab
- focus rings: YES — focus-visible:ring-2 ring-primary-400 on all buttons and inputs
- alt on images: YES — status icon uses aria-label; decorative envelope icon uses aria-hidden
- labels on inputs: YES — email input has associated <label for="email">
- aria-live: YES — invitation list update region uses aria-live="polite"
- contrast ratio: PASS — 5.2:1 verified for body text, 3.4:1 for status badges

**Form Validation**:
- Layer 1 (onChange hints): IMPLEMENTED — zodResolver with mode:'onChange' shows email format error as user types
- Layer 2 (pre-submit gate): IMPLEMENTED — handleSubmit blocks if any field invalid, scrolls to first error
- Layer 3 (server error display): IMPLEMENTED — onError maps EMAIL_ALREADY_REGISTERED → setError('email')

**Self-Check Results**:
- Console errors: NONE
- Main flow walkthrough: PASS — loaded invitations, sent new invitation, viewed confirmation
- Mobile viewport (375px): PASS — InviteForm and InvitationList verified at 375px breakpoint
- TypeScript type check: PASS — tsc --noEmit exit 0

**API Discrepancies Found**: NONE

**Recommended Next Steps**:
- @code-review: review token compliance, 5-state coverage, form validation Layer 3, Pinia store error handling
- @test-ui: capture InvitationList (initial, empty, loading, success, error states) at 375px and 1440px; InviteForm (initial, validation error, loading, success, server error) at both breakpoints
```

---

## BLOCKED Output Example

```
## Frontend Implementation Handoff: T-019 — Invitation Management UI

**Status**: BLOCKED

**Block Reason**:
Design tokens missing from @visual-designer specification:
1. `--color-status-pending` — needed for pending status badge background
2. `--color-status-expired` — needed for expired status badge background
3. `--spacing-card-padding` — needed for InvitationCard internal padding

Routing to @visual-designer with specific gap list. Will implement once tokens are confirmed.
No styling with invented values has been started.
```

---

## Dispatch Signals

**Strong triggers** (dispatch @frontend):
- "写页面" / "实现组件" / "前端实现"
- "前端对接接口" / "做这个 UI"
- Task state reaching frontend implementation phase
- @dev-lead dispatches with scheme + @visual-designer token file confirmed

**Do NOT dispatch @frontend when**:
- @visual-designer token file is missing or incomplete → @visual-designer first
- @dev-lead scheme is absent → @dev-lead first
- Task is WeChat Mini Program / uni-app → @miniprogram-dev
- Task is iOS/Android native → @ios-dev / @android-dev
- Task is design system token definition → @visual-designer
- Task is deep security audit → @security-auditor
- Backend API endpoints haven't been implemented → negotiate mock with @backend or BLOCK

---

## Skill References

- `~/.claude/skills/frontend-design/SKILL.md` — Generate design tokens, CSS variables, Tailwind config
- `~/.claude/skills/webapp-testing/SKILL.md` — Automated browser-based UI testing
- `~/.claude/skills/engineering-code-review/SKILL.md` — Engineering-grade code review workflow
- `~/.claude/skills/minimax-frontend-dev/SKILL.md` — MiniMax frontend patterns and component generation
