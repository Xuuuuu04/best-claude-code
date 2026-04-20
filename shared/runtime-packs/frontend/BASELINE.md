# 前端开发师 — Baseline Scenarios

## Scenario 1: Invitation Management UI (Canonical)

**Input**:
- @dev-lead scheme: "Implement InvitationList component. API: GET /workspaces/:id/invitations (returns array of invitations). POST /workspaces/:id/invitations (send invitation). State: React Query. Form: React Hook Form + Zod. Stack: React + TypeScript + Tailwind + Zustand."
- Token file: `src/styles/tokens.css` provided by @visual-designer

**Expected Output Structure**:
- Verify prerequisites: token file exists and covers required styles? YES. API running? YES on staging.
- Explore project: Glob for existing React Query setup, existing form patterns — match conventions found.
- Component tree designed top-down: InvitationList (container, owns query) → InvitationCard (presentational) + EmptyInvitations (presentational) + InviteForm (container, owns mutation)
- Implement in layer order: API functions → React Query hooks → Zod schema → component structure → token-referenced styles (Tailwind classes only, no hardcoded values) → 5-state coverage → A11y
- 5-state coverage:
  - Initial: SkeletonList with 3 placeholder rows
  - Empty: EmptyInvitations with CTA "Invite your first member"
  - Loading: SkeletonList with animated pulse during refetch
  - Success: InvitationCard for each invitation
  - Error: ErrorState with "Could not load invitations" + Retry button calling `refetch()`
- Form: `mode: 'onChange'` for Layer 1; Zod resolver blocks submission for Layer 2; `useMutation onError` maps server `{errors: {email: [...]}}` to `setError('email', {...})` for Layer 3
- A11y: all interactive elements keyboard-navigable, visible focus rings via `focus-visible:ring-2 focus-visible:ring-primary-500`, `<label htmlFor="email">` for input, `aria-live="polite"` on invitation list status region, contrast 5.2:1 verified
- Self-check: console NONE, main flow PASS, mobile 375px PASS, tsc PASS
- Next step: @code-review + @test-ui (InvitationList 5 states at 375px and 1440px; InviteForm 5 states)

**Key Decision Points**:
- All Tailwind classes reference design system tokens (`bg-surface-subtle`, `p-spacing-md`) — no `bg-[#f8fafc]` or `p-[24px]`
- Empty state is NOT a blank container — it has explanatory text and a CTA
- Layer 3 maps server error to the specific field — not a generic toast
- BLOCK was NOT needed: token file and API both available
- No localStorage for auth token — existing httpOnly Cookie approach maintained

---

## Scenario 2: BLOCKED — Missing Design Tokens

**Input**:
- @dev-lead scheme: "Implement a pricing card component with gradient background, premium badge, and highlighted feature list. Card should have a distinct visual treatment for the 'recommended' tier."
- Token file check: existing `src/styles/tokens.css` has `--color-primary-*` and `--spacing-*` but no gradient tokens, no badge tokens, no "recommended" tier visual tokens.

**Expected Output Structure**:
- Status: BLOCKED — required design tokens not defined in current token file
- Response: "I cannot implement this component without the required design tokens. Before I can begin, @visual-designer needs to define:"
  - "1. Gradient background for pricing cards: what is the gradient direction, start color, and end color? These must be defined as a CSS custom property (e.g., `--gradient-pricing-card`) not as hardcoded values."
  - "2. Premium badge: what is the badge background color, text color, border radius, and typography token? (Is this a new variant of an existing badge component, or a new token?)"
  - "3. 'Recommended' tier visual treatment: what specifically is different about the recommended card? (Elevated shadow? Different border? Scale transform on hover? Each requires a token.)"
- Do NOT implement with guessed values "close to" what the design likely intends
- Do NOT use hardcoded gradient values from a design screenshot

**Key Decision Points**:
- BLOCK fires before a single line of styling is written
- Each missing token is named specifically with its purpose — not "the styles are missing"
- The gap routing is precise: @visual-designer is the correct person to answer these questions, not @dev-lead
- No speculation about what the gradient "probably" is from the design mockup

---

## Scenario 3: Bug Fix — 5-State Gap + A11y Defect

**Input**:
- @test-ui: "InvitationList shows a completely blank screen when GET /workspaces/:id/invitations returns an empty array. Also, the 'Remove' button on each InvitationCard is not reachable by keyboard Tab — it only works on mouse click."
- Source: InvitationCard's Remove button implemented as `<div onClick={onRemove}>Remove</div>`

**Expected Output Structure**:
- Issue 1 (5-state gap): Empty state is not implemented. When `invitations.length === 0 && !isLoading && !error`, the component renders nothing. Fix: add explicit empty state branch:
  ```tsx
  {!isLoading && !error && invitations.length === 0 && (
    <EmptyInvitations onInvite={onOpenInviteModal} />
  )}
  ```
  EmptyInvitations renders explanatory text + CTA button.

- Issue 2 (A11y defect — not keyboard accessible): `<div onClick={onRemove}>Remove</div>` is not keyboard accessible because `<div>` has no default keyboard behavior. Fix: replace with `<button>` (semantic HTML):
  ```tsx
  <button
    type="button"
    onClick={onRemove}
    className="btn-secondary text-sm focus-visible:ring-2 focus-visible:ring-primary-500"
    aria-label={`Remove invitation for ${invitation.email}`}
  >
    Remove
  </button>
  ```
  The `<button>` is natively focusable, activates on Enter/Space, and has the correct ARIA role.

- Self-check after fix: empty state renders correctly with 0 items; Remove button reachable by Tab, activates on Enter/Space, has visible focus ring.

- Do NOT add `tabIndex={0}` and `onKeyDown` to the `<div>` — this is a known A11y anti-pattern (ARIA role theater). Replace with semantic HTML.

- Next step: @code-review → verify the empty state + button replacement; @test-ui → re-capture screenshots of empty state + confirm keyboard navigation on Remove button

**Key Decision Points**:
- Two issues fixed separately — not one combined "accessibility fix"
- Issue 2 uses semantic `<button>` not `<div>` with ARIA patches — correct fix, not a workaround
- `aria-label` added to Remove button: the button content "Remove" alone is not sufficient without context — "Remove invitation for user@example.com" is the accessible name
- Self-check specifically verifies keyboard navigation after the fix

---

## Scenario 4: BLOCKED — Hydration Mismatch in Next.js 15

**Input**:
- @dev-lead scheme: "Implement a dashboard header showing current time and user's local timezone. Stack: Next.js 15 App Router + React 19 + Tailwind."
- Developer implementation:
  ```tsx
  // app/dashboard/header.tsx
  export default function DashboardHeader() {
    const now = new Date();
    const timeString = now.toLocaleTimeString();
    return <header>Current time: {timeString}</header>;
  }
  ```

**Expected Output Structure**:
- Status: BLOCKED — hydration mismatch detected
- Issue: `new Date()` produces different values on server (render time) and client (hydration time). Next.js 15 App Router with React 19 will throw a hydration mismatch error.
- Response: "The current time implementation causes a hydration mismatch because server-rendered HTML contains one timestamp and client hydration expects another. Two safe approaches:"

**Option A — Client-only rendering:**
```tsx
'use client';
import { useState, useEffect } from 'react';

export default function DashboardHeader() {
  const [time, setTime] = useState<string | null>(null);
  useEffect(() => {
    setTime(new Date().toLocaleTimeString());
    const interval = setInterval(() => {
      setTime(new Date().toLocaleTimeString());
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  return <header>Current time: {time ?? '--:--:--'}</header>;
}
```

**Option B — Server-rendered static + client update:**
```tsx
import { Suspense } from 'react';

export default function DashboardHeader() {
  return (
    <header>
      Current time: <Suspense fallback="--:--:--"><ClientTime /></Suspense>
    </header>
  );
}

'use client';
function ClientTime() {
  const [time, setTime] = useState(() => new Date().toLocaleTimeString());
  useEffect(() => {
    const interval = setInterval(() => setTime(new Date().toLocaleTimeString()), 1000);
    return () => clearInterval(interval);
  }, []);
  return <span>{time}</span>;
}
```

**Key Decision Points**:
- Hydration mismatch is a BLOCK condition, not a warning
- Server and client initial HTML must match exactly
- Time-dependent values must be wrapped in `useEffect` (client-only) or use `suppressHydrationWarning`
- React 19's improved hydration errors make this more visible — do not suppress the warning, fix the root cause

---

## Scenario 5: Performance Regression — Unnecessary Re-renders

**Input**:
- @test-ui: "The invitation list becomes sluggish when there are more than 20 invitations. Scrolling is jerky and clicking 'Resend' takes 500ms to respond."
- Source code inspection reveals:
  ```tsx
  function InvitationList() {
    const [selectedId, setSelectedId] = useState<number | null>(null);
    const { data: invitations } = useQuery({ queryKey: ['invitations'], queryFn: api.getInvitations });

    return (
      <div>
        {invitations?.map(inv => (
          <InvitationCard
            key={inv.id}
            invitation={inv}
            isSelected={selectedId === inv.id}
            onSelect={setSelectedId}
          />
        ))}
      </div>
    );
  }

  function InvitationCard({ invitation, isSelected, onSelect }) {
    // No memoization — every card re-renders when any state changes
    return (
      <div className={isSelected ? 'selected' : ''} onClick={() => onSelect(invitation.id)}>
        <img src={invitation.avatar} />
        <span>{invitation.email}</span>
        <button onClick={() => api.resend(invitation.id)}>Resend</button>
      </div>
    );
  }
  ```

**Expected Output Structure**:
- DIAGNOSIS: Every `InvitationCard` re-renders when `selectedId` changes (because `onSelect` reference changes and no memoization). With 50 invitations, clicking one card causes 50 re-renders.
- FIX — three optimizations:

1. **Memoize InvitationCard** (after profiler confirmation):
```tsx
const InvitationCard = React.memo(({ invitation, isSelected, onSelect }: InvitationCardProps) => {
  return (
    <div className={isSelected ? 'selected' : ''} onClick={() => onSelect(invitation.id)}>
      <img src={invitation.avatar} />
      <span>{invitation.email}</span>
      <ResendButton invitationId={invitation.id} />
    </div>
  );
});
```

2. **Stabilize onSelect callback**:
```tsx
function InvitationList() {
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const { data: invitations } = useQuery({ queryKey: ['invitations'], queryFn: api.getInvitations });

  // Stable callback reference — doesn't change between renders
  const handleSelect = useCallback((id: number) => {
    setSelectedId(id);
  }, []);

  return (
    <div>
      {invitations?.map(inv => (
        <InvitationCard
          key={inv.id}
          invitation={inv}
          isSelected={selectedId === inv.id}
          onSelect={handleSelect}
        />
      ))}
    </div>
  );
}
```

3. **Extract ResendButton to prevent re-render on parent state change**:
```tsx
const ResendButton = React.memo(({ invitationId }: { invitationId: number }) => {
  const { mutate: resend, isPending } = useResendInvitation();
  return (
    <button onClick={() => resend(invitationId)} disabled={isPending}>
      {isPending ? 'Sending...' : 'Resend'}
    </button>
  );
});
```

- Self-test: React Profiler records interaction before/after. Confirm re-render count drops from 50 to 1 on selection change.
- Next step: @code-review → verify memoization correctness (no stale closures), @test-ui → re-measure interaction responsiveness

**Key Decision Points**:
- Profiler measurement before optimization — do not memoize speculatively
- `useCallback` only when the callback is passed to memoized children
- `React.memo` only after profiler confirms unnecessary re-renders
- Extracting components is often better than adding memoization — smaller components naturally re-render less
