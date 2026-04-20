> 源：core.md §Domain 1.2 Vue 3 + §Domain 1.3 TypeScript

# 前端开发师 — Vue 3 Stack

## Domain 1.2 Vue 3

├── 1.2.1 Composition API patterns
├── 1.2.2 Pinia patterns
└── 1.2.3 Vue Router discipline

---

## 1.2.1 Composition API Patterns

**ref vs reactive — and the destructuring trap**

```typescript
import { ref, reactive, computed, watch, watchEffect } from 'vue';

// ref for primitives — unwrapped automatically in template with .value in script
const count = ref(0);
const userName = ref('');
const isLoading = ref(false);

// reactive for objects — BUT: destructuring loses reactivity
const userState = reactive({
    id: null as number | null,
    email: '',
    roles: [] as string[],
});

// BAD: destructuring reactive — roles is no longer reactive
const { roles } = userState;
roles.push('admin'); // UI won't update

// GOOD: access through the reactive object, or use toRefs
import { toRefs } from 'vue';
const { id, email, roles: userRoles } = toRefs(userState);
userRoles.value.push('admin'); // reactive — UI updates
```

**defineProps + defineEmits with TypeScript**

```typescript
// In <script setup lang="ts">
interface Invitation {
    id: number;
    email: string;
    status: 'pending' | 'accepted' | 'expired';
    expiresAt: string;
}

const props = defineProps<{
    invitation: Invitation;
    isSelectable?: boolean;
}>();

const emit = defineEmits<{
    resend: [invitationId: number];
    revoke: [invitationId: number];
}>();

// Usage
emit('resend', props.invitation.id);
```

**computed, watch, watchEffect**

```typescript
// computed — derived values, cached
const isExpired = computed(() => {
    return new Date(props.invitation.expiresAt) < new Date();
});

// watch — explicit dependency, runs on change
watch(
    () => props.invitation.status,
    (newStatus, oldStatus) => {
        if (newStatus === 'accepted' && oldStatus === 'pending') {
            toast.success(`${props.invitation.email} accepted the invitation`);
        }
    }
);

// watchEffect — implicit dependency tracking, runs immediately
watchEffect(async () => {
    if (userId.value) {
        // userId.value tracked automatically — refires when userId changes
        const data = await fetchUserData(userId.value);
        userData.value = data;
    }
});
```

---

## 1.2.2 Pinia Patterns

**defineStore with state, getters, actions**

```typescript
// stores/invitation.ts
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';

export const useInvitationStore = defineStore('invitation', () => {
    // state
    const invitations = ref<Invitation[]>([]);
    const isLoading = ref(false);
    const error = ref<Error | null>(null);

    // getters
    const pendingInvitations = computed(() =>
        invitations.value.filter(inv => inv.status === 'pending')
    );

    const invitationCount = computed(() => invitations.value.length);

    // actions
    async function fetchInvitations() {
        isLoading.value = true;
        error.value = null;
        try {
            invitations.value = await api.getInvitations();
        } catch (e) {
            error.value = e as Error;
        } finally {
            isLoading.value = false;
        }
    }

    async function createInvitation(dto: CreateInvitationDto) {
        const newInvitation = await api.createInvitation(dto);
        invitations.value.push(newInvitation);
        return newInvitation;
    }

    return { invitations, isLoading, error, pendingInvitations, invitationCount, fetchInvitations, createInvitation };
});
```

**storeToRefs — destructure without losing reactivity**

```typescript
// In component <script setup>
import { storeToRefs } from 'pinia';
import { useInvitationStore } from '@/stores/invitation';

const store = useInvitationStore();

// BAD: direct destructure — invitations is no longer reactive
const { invitations } = store;

// GOOD: storeToRefs for state and getters; actions destructured directly
const { invitations, isLoading, error, pendingInvitations } = storeToRefs(store);
const { fetchInvitations, createInvitation } = store; // actions are plain functions
```

**$patch for multiple simultaneous state updates**

```typescript
// BAD: multiple individual assignments — may trigger multiple re-renders
store.isLoading = false;
store.error = null;
store.invitations = data;

// GOOD: single $patch — batched update
store.$patch({
    isLoading: false,
    error: null,
    invitations: data,
});

// Or $patch with function for complex updates
store.$patch((state) => {
    state.isLoading = false;
    state.invitations = [...state.invitations, ...newInvitations];
});
```

---

## 1.2.3 Vue Router Discipline

**Route guards for auth protection — in router, not components**

```typescript
// router/index.ts
import { createRouter, createWebHistory } from 'vue-router';
import { useAuthStore } from '@/stores/auth';

const router = createRouter({
    history: createWebHistory(),
    routes: [
        {
            path: '/invitations',
            component: () => import('@/views/InvitationView.vue'), // lazy
            meta: { requiresAuth: true, roles: ['admin'] },
        },
        {
            path: '/login',
            component: () => import('@/views/LoginView.vue'),
        },
    ],
});

// BAD: auth check inside component — bypassed by direct navigation
// onMounted(() => { if (!auth.isLoggedIn) router.push('/login') })

// GOOD: global before guard in router definition
router.beforeEach((to, from) => {
    const authStore = useAuthStore();
    if (to.meta.requiresAuth && !authStore.isAuthenticated) {
        return { path: '/login', query: { redirect: to.fullPath } };
    }
    if (to.meta.roles && !authStore.hasAnyRole(to.meta.roles)) {
        return { path: '/forbidden' };
    }
});
```

**Lazy loading — all routes**

```typescript
// BAD: eager loading — entire app JS in one bundle
import InvitationView from '@/views/InvitationView.vue';

// GOOD: lazy loading — route chunk loaded on navigation
const InvitationView = () => import('@/views/InvitationView.vue');
// Or inline in route config:
{ path: '/invitations', component: () => import('@/views/InvitationView.vue') }
```

**Named routes — not path strings**

```typescript
// BAD: path string — breaks if path changes
router.push('/invitations/42/edit');

// GOOD: named route — refactor-safe
router.push({ name: 'invitation-edit', params: { id: 42 } });
```

---

## Domain 1.3 TypeScript Discipline

**No `any` — use `unknown` for genuinely unknown types**

```typescript
// BAD
const handleError = (error: any) => {
    console.error(error.message); // no type safety
};

// GOOD
const handleError = (error: unknown) => {
    if (error instanceof Error) {
        console.error(error.message);
    } else {
        console.error('Unknown error', error);
    }
};
```

**Zod runtime validation at API boundaries**

```typescript
import { z } from 'zod';

const InvitationSchema = z.object({
    id: z.number(),
    email: z.string().email(),
    status: z.enum(['pending', 'accepted', 'expired']),
    expiresAt: z.string().datetime(),
});

const InvitationListSchema = z.array(InvitationSchema);

// API function with runtime validation
async function getInvitations(): Promise<Invitation[]> {
    const response = await api.get('/api/v1/invitations');
    // Parse validates at runtime — throws ZodError if shape doesn't match
    return InvitationListSchema.parse(response.data);
}
```
