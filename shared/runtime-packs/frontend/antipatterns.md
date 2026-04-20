> 源：core.md §Anti-Patterns (Named) + §Rules (Primacy Anchor)

# 前端开发师 — Anti-Patterns (Named)

## Five Named Anti-Patterns

---

### Token Drift

**Definition**: Accumulating hardcoded style values that diverge from the design token system.

**Manifestation**:
```tsx
// BAD — three hardcoded values
<div style={{ padding: '16px', color: '#3b82f6', borderRadius: '8px' }}>

// BAD — hardcoded Tailwind classes that bypass token system
<div className="p-4 text-blue-500 rounded-lg">

// GOOD — token references (CSS variables via Tailwind token classes)
<div className="p-spacing-md text-primary-500 rounded-card">
```

**Why it compounds**: Each exception proves the next. The first hardcoded value is "just this once." After six months, 30% of style properties are hardcoded. When the design system updates primary blue from `#3b82f6` to `#2563eb`, the token update catches 70% of usages. The other 30% requires manual hunt-and-fix across the codebase.

**Why each exception feels justified**:
- "The token doesn't exist yet, I'll add it later" → it never gets added
- "The designer gave me a hex code, so I used a hex code" → the token system was bypassed at the source
- "It's just a one-off style for this component" → every drift starts as a "one-off"

**Correction**: When no token exists for a style need, BLOCK and route to @visual-designer with the specific gap. Do not start implementing with an invented value and "wait for the token."

---

### 5-State Amnesia

**Definition**: Delivering a component that handles the success state well but has no implementation for loading, empty, or error states.

**Manifestation**:
```tsx
// BAD — success-only implementation
function InvitationList() {
    const { data: invitations } = useQuery({ queryKey: ['invitations'], queryFn: api.getInvitations });
    return (
        <ul>
            {invitations?.map(inv => <InvitationCard key={inv.id} item={inv} />)}
        </ul>
    );
    // Loading state: renders empty <ul> — looks broken
    // Error state: undefined.map() crash or silent empty list
    // Empty state: empty <ul> — user doesn't know if data is loading or truly empty
}

// GOOD — all 5 states
function InvitationList() {
    const { data, isLoading, error, refetch } = useQuery(...);
    if (isLoading) return <SkeletonList count={3} />;
    if (error) return <ErrorState error={error} onRetry={refetch} />;
    if (!data || data.length === 0) return <EmptyInvitations />;
    return <ul>{data.map(inv => <InvitationCard key={inv.id} item={inv} />)}</ul>;
}
```

**Why users experience all five states every session**:
- Initial: page first renders
- Loading: every network request in progress
- Empty: new users, or after deleting all items
- Success: the state the developer tested
- Error: network failure, server error, timeout — happens more than developers expect

**Correction**: Implement all five states simultaneously with the success state. They are not optional — they are user experiences that happen in every session.

---

### Validation Theater

**Definition**: Frontend validation that creates the appearance of validation without real coverage.

**Manifestation**:
```tsx
// BAD — only Layer 2 (submit block), no Layer 1 or Layer 3
const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (!email) {
        toast.error('Please enter an email'); // toast, not field-level
        return;
    }
    api.createInvitation({ email }).catch(() => {
        toast.error('Something went wrong'); // catches ALL server errors the same way
    });
};
```

**What's missing**:
- Layer 1 missing: user gets no feedback as they type — typos discovered only on submit
- Layer 3 collapsed: "something went wrong" toast covers "email already registered", "invalid domain", "rate limit exceeded" all the same way — user has no actionable information

**Full three-layer requirement**:
- Layer 1 (onChange hints): feedback as user types, without blocking
- Layer 2 (pre-submit gate): block submission + show all field errors at once
- Layer 3 (server error display): map server error fields to correct form field, not a generic toast

**Correction**:
```tsx
// All three layers required
<form onSubmit={handleSubmit(onSubmit)}>  {/* Layer 2: handleSubmit blocks if validation fails */}
    <input
        {...register('email')}                     // Layer 1: zodResolver in mode:'onChange'
        aria-invalid={!!errors.email}
        aria-describedby="email-error"
    />
    {errors.email && (
        <span id="email-error" role="alert">{errors.email.message}</span>  // Layer 1+2 display
    )}
</form>
// onError: setError('email', { message: serverError }) — Layer 3
```

---

### A11y Afterthought

**Definition**: Implementing full visual design and interaction, then attempting to "add accessibility" as a final step.

**Manifestation**:
```tsx
// BAD — built with divs, accessibility added as afterthought
// Step 1: built interactive dropdown with <div> elements
<div onClick={toggleDropdown}>Actions</div>
<div className={`dropdown ${isOpen ? 'open' : ''}`}>
    <div onClick={handleEdit}>Edit</div>
    <div onClick={handleDelete}>Delete</div>
</div>

// Step 2: "added accessibility"
<div onClick={toggleDropdown} role="button" aria-expanded={isOpen}>Actions</div>
<div className={`dropdown ${isOpen ? 'open' : ''}`} role="menu">
    <div onClick={handleEdit} role="menuitem">Edit</div>  // still not keyboard navigable
    <div onClick={handleDelete} role="menuitem">Delete</div>
</div>
// Problem: role="button" added but Tab doesn't focus it, Enter doesn't activate it
// Arrow key navigation within menu not implemented
// Focus not restored to trigger when menu closes
```

**Why afterthought fails**: Semantic HTML provides keyboard accessibility, focus management, and ARIA roles for free. Retrofitting custom widgets to match native semantics requires implementing the full ARIA Authoring Practices Guide keyboard pattern — which requires the same work as building it correctly from the start.

**Correction**: Start with semantic HTML. Use `<button>`, `<a>`, `<select>`, `<input>` first. Only use custom patterns when semantic HTML is genuinely insufficient (complex custom components). Reference ARIA Authoring Practices Guide for any custom pattern.

```tsx
// GOOD — semantic from the start
<button onClick={toggleDropdown} aria-expanded={isOpen} aria-haspopup="menu">
    Actions
</button>
{isOpen && (
    <ul role="menu">
        <li><button role="menuitem" onClick={handleEdit}>Edit</button></li>
        <li><button role="menuitem" onClick={handleDelete}>Delete</button></li>
    </ul>
)}
```

---

### Business Logic Boundary Violation

**Definition**: Implementing business rules in frontend code as if the frontend were the authority. Frontend calculates permissions, blocks API calls based on frontend state.

**Manifestation**:
```tsx
// BAD — frontend assumes it is the authority
function DeleteButton({ invitation }: { invitation: Invitation }) {
    const { user } = useAuth();

    // Frontend blocks the API call entirely based on client-side check
    if (user.role !== 'admin') return null; // UI element hidden

    const handleDelete = () => {
        if (user.role !== 'admin') return; // also blocking the API call
        api.deleteInvitation(invitation.id);
    };

    return <button onClick={handleDelete}>Delete</button>;
}
```

**Why it's dangerous**: The backend becomes dependent on frontend enforcement that can be bypassed (developer tools, direct API calls, stale client state). When the permission logic inevitably diverges between frontend and backend, one of two bad outcomes: (a) backend no longer enforces the rule — security regression; (b) frontend shows controls that the backend denies — confusing UX.

**Correction**: Frontend can hide UI elements for UX (the Delete button doesn't appear). The Delete endpoint MUST still return 403 for unauthorized requests. Both must be true independently.

```tsx
// GOOD — frontend manages UX, backend manages authority
function DeleteButton({ invitation }: { invitation: Invitation }) {
    const { user } = useAuth();
    const { mutate: deleteInvitation, isPending } = useDeleteInvitation();

    // UI element hidden for UX — but this is NOT the security enforcement
    if (!user.permissions.includes('invitation:delete')) return null;

    const handleDelete = () => {
        // API call always goes through — backend enforces authorization
        // Backend returns 403 if unauthorized regardless of frontend state
        deleteInvitation(invitation.id, {
            onError: (error) => {
                if (error.status === 403) {
                    // Handle unexpected permission denial gracefully
                    toast.error('You no longer have permission to delete invitations');
                }
            }
        });
    };

    return (
        <button onClick={handleDelete} disabled={isPending}>
            {isPending ? 'Deleting...' : 'Delete'}
        </button>
    );
}
```
