> 源：core.md §Domain 1.1 React + §Domain 2.1 Five-State Implementation + §Domain 2.2 Three-Layer Form Validation

# 前端开发师 — React Stack

## Domain 1.1 React

├── 1.1.1 Hook selection discipline
├── 1.1.2 Server state management (React Query)
└── 1.1.3 Performance discipline

---

## 1.1.1 Hook Selection Discipline

| Hook | When to use |
|---|---|
| `useState` | UI state that triggers re-render |
| `useReducer` | Complex state machines with multiple sub-values |
| `useRef` | DOM references and values that must NOT trigger re-render |
| `useMemo` | Expensive derived values — only after profiler confirms cost |
| `useCallback` | Stable function references passed to memoized children |
| `useEffect` | Side effects — dependency arrays must be exhaustive |

**useEffect dependency array discipline**

```tsx
// BAD: missing dependency — stale closure
useEffect(() => {
    fetchUser(userId);
    // userId used but not listed — userId updates don't retrigger
}, []);

// GOOD: exhaustive dependencies
useEffect(() => {
    fetchUser(userId);
}, [userId, fetchUser]);

// Use useCallback to stabilize fetchUser reference if needed
const fetchUser = useCallback(async (id: number) => {
    const data = await api.getUser(id);
    setUser(data);
}, []); // stable reference — safe in dep array
```

---

## 1.1.2 Server State Management — React Query

**useQuery — data fetching**

```tsx
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

function InvitationList() {
    const { data: invitations, isLoading, error, refetch } = useQuery({
        queryKey: ['invitations'],
        queryFn: () => api.getInvitations(),
        staleTime: 30_000,  // data fresh for 30s — no refetch on window focus
        gcTime: 5 * 60_000, // keep in cache for 5 min after unmount
    });

    // 5-State implementation
    if (isLoading) return <SkeletonList count={3} />;
    if (error) return <ErrorState error={error} onRetry={refetch} />;
    if (!invitations || invitations.length === 0) return <EmptyInvitations />;
    return <>{invitations.map(inv => <InvitationCard key={inv.id} item={inv} />)}</>;
}
```

**useMutation — optimistic updates + error rollback**

```tsx
function useCreateInvitation() {
    const queryClient = useQueryClient();

    return useMutation({
        mutationFn: (dto: CreateInvitationDto) => api.createInvitation(dto),
        onMutate: async (newInvitation) => {
            // Cancel in-flight queries to avoid overwriting optimistic update
            await queryClient.cancelQueries({ queryKey: ['invitations'] });

            // Snapshot previous value for rollback
            const previousInvitations = queryClient.getQueryData<Invitation[]>(['invitations']);

            // Optimistically update cache
            queryClient.setQueryData<Invitation[]>(['invitations'], (old = []) => [
                ...old,
                { ...newInvitation, id: Date.now(), status: 'pending' },
            ]);

            return { previousInvitations }; // returned as context
        },
        onError: (err, variables, context) => {
            // Rollback to snapshot on error
            if (context?.previousInvitations) {
                queryClient.setQueryData(['invitations'], context.previousInvitations);
            }
        },
        onSettled: () => {
            // Always invalidate — refetch from server regardless of success/failure
            queryClient.invalidateQueries({ queryKey: ['invitations'] });
        },
    });
}
```

---

## 1.1.3 Performance Discipline

**React.memo — only with profiler evidence**

```tsx
// WRONG: premature optimization
const UserCard = React.memo(({ user }: { user: User }) => {
    // Wrap before profiler shows re-render problem
    return <div>{user.name}</div>;
});

// RIGHT: use React Profiler first
// 1. Open React DevTools Profiler
// 2. Record interaction that feels slow
// 3. Identify components with unnecessary re-renders (gray bars = re-renders)
// 4. Apply memo only to confirmed culprits
```

**Route-level code splitting — mandatory**

```tsx
import { lazy, Suspense } from 'react';
import { Routes, Route } from 'react-router-dom';

// GOOD: route-level splitting — each route chunk loaded on demand
const InvitationPage = lazy(() => import('./pages/InvitationPage'));
const UserSettingsPage = lazy(() => import('./pages/UserSettingsPage'));
const AdminDashboard = lazy(() => import('./pages/AdminDashboard'));

function AppRouter() {
    return (
        <Suspense fallback={<PageSkeleton />}>
            <Routes>
                <Route path="/invitations" element={<InvitationPage />} />
                <Route path="/settings" element={<UserSettingsPage />} />
                <Route path="/admin" element={<AdminDashboard />} />
            </Routes>
        </Suspense>
    );
}
```

---

## Domain 2.2 — Three-Layer Form Validation (React Implementation)

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const invitationSchema = z.object({
    email: z.string().email('Invalid email format').max(254, 'Email too long'),
    role: z.enum(['member', 'admin'], { errorMap: () => ({ message: 'Invalid role' }) }),
});

type InvitationFormData = z.infer<typeof invitationSchema>;

function InviteForm() {
    const { register, handleSubmit, formState: { errors, isSubmitting }, setError } = useForm<InvitationFormData>({
        resolver: zodResolver(invitationSchema),
        mode: 'onChange',  // Layer 1: inline hints as user types
    });

    const { mutate: createInvitation } = useCreateInvitation();

    const onSubmit = (data: InvitationFormData) => {
        createInvitation(data, {
            onError: (error) => {
                // Layer 3: map server errors to specific fields
                if (error.code === 'EMAIL_ALREADY_REGISTERED') {
                    setError('email', { message: 'This email is already registered' });
                } else if (error.code === 'VALIDATION_ERROR' && error.fields) {
                    Object.entries(error.fields).forEach(([field, message]) => {
                        setError(field as keyof InvitationFormData, { message: String(message) });
                    });
                }
            },
        });
    };

    return (
        <form onSubmit={handleSubmit(onSubmit)} noValidate>
            {/* Layer 1 + Layer 2: errors.email shows both onChange and pre-submit errors */}
            <div>
                <label htmlFor="email">Email address</label>
                <input
                    id="email"
                    type="email"
                    aria-describedby={errors.email ? 'email-error' : undefined}
                    aria-invalid={!!errors.email}
                    {...register('email')}
                />
                {errors.email && (
                    <span id="email-error" role="alert">{errors.email.message}</span>
                )}
            </div>
            <button type="submit" disabled={isSubmitting}>
                {isSubmitting ? 'Sending...' : 'Send Invitation'}
            </button>
        </form>
    );
}
```

---

## Domain 2.1 — Five-State Implementation (React)

```tsx
// Complete 5-state component pattern
function InvitationListContainer() {
    const { data: invitations, isLoading, error, refetch } = useQuery({
        queryKey: ['invitations'],
        queryFn: api.getInvitations,
    });

    // State 1: Initial — shown before first fetch completes (covered by isLoading on mount)
    // State 2: Loading — async operation in progress
    if (isLoading) return <SkeletonList count={3} />;

    // State 3: Error — operation failed
    if (error) return (
        <ErrorState
            message="Could not load invitations"
            onRetry={refetch}
        />
    );

    // State 4: Empty — no data to display
    if (!invitations || invitations.length === 0) return (
        <EmptyState
            title="No invitations yet"
            description="Invite your first team member to get started."
            action={<button onClick={onOpenInviteModal}>Send first invitation</button>}
        />
    );

    // State 5: Success — normal operational state
    return (
        <ul aria-label="Invitations list">
            {invitations.map(inv => (
                <InvitationCard key={inv.id} invitation={inv} />
            ))}
        </ul>
    );
}
```
