> 源：core.md §Anti-Patterns + §Rules (Primacy Anchor)

# Git 版本控制大师 — Anti-Patterns

## Named Anti-Patterns

---

### Force-Push Blast

**Definition**: Using `git push --force` on a shared branch, silently overwriting commits that teammates have pushed since your last fetch. This destroys work that exists on the remote but not in your local history.

**Manifestations**:
```bash
# BAD — permanently forbidden
$ git push origin main --force
# → overwrites any commits teammates pushed to main since your last fetch

# BAD — even on personal branch, --force is unsafe
$ git push origin feat/user-auth --force
# → if a teammate pushed a fix to your branch, it's gone
```

**Why it's dangerous**: Force-push blast is silent data loss. The overwritten commits may contain critical bug fixes, security patches, or code review feedback. There is no notification to the pusher that work was destroyed. Recovery requires someone who still has the overwritten commits in their local reflog.

**Correction**: Always use `--force-with-lease` on personal branches. It fails safely if the remote has commits your local tracking ref doesn't know about. Never force-push to shared branches (main, develop, release/*).

```bash
# GOOD — fails safely if remote changed
$ git push origin feat/user-auth --force-with-lease
# → error if someone else pushed; success only if you have the latest
```

---

### History Vandalism

**Definition**: Rebasing or amending commits that have already been pushed to a shared branch, then force-pushing the rewritten history. This breaks every downstream clone.

**Manifestations**:
```bash
# BAD — rebasing a shared branch
$ git checkout develop
$ git rebase main
$ git push origin develop --force-with-lease
# → every developer with a local develop now has diverged history

# BAD — amending a commit already on origin/main
$ git commit --amend
$ git push origin main --force-with-lease
# → all branches based on the old commit SHA are now orphaned
```

**Why it's dangerous**: History vandalism corrupts the collaborative state. Developers who pulled the old history will create merge commits that re-introduce the "cleaned" commits, or worse, will have unresolvable conflicts. The team's history becomes a tangle of duplicate commits and phantom merges.

**Correction**: Interactive rebase is ONLY for local branches that have not been pushed, or your own personal feature branches. Once commits are on a shared branch, they are permanent. Use merge commits to add fixes.

```bash
# GOOD — merge main into develop instead of rebasing
$ git checkout develop
$ git merge main
# → creates a merge commit, preserves all existing history
```

---

### Blind Conflict Resolution

**Definition**: Resolving merge conflicts with `--ours` or `--theirs` without reading both sides of the conflict, or accepting an automatic merge resolution without understanding the semantic implications.

**Manifestations**:
```bash
# BAD — discarding entire file without reading
$ git checkout --theirs -- src/api/user.js
$ git add src/api/user.js

# BAD — accepting merge without inspection
$ git merge feature/payment-integration
# Auto-merging src/services/payment.js
# CONFLICT in src/services/payment.js
$ git add src/services/payment.js
$ git commit -m "merge payment feature"
# → may have silently deleted a security fix from the other branch
```

**Why it's dangerous**: Blind conflict resolution can silently delete security fixes, revert bug fixes, or merge incompatible logic paths. The merge commit appears clean in the log, but the code is broken. This is particularly dangerous when the conflicting changes are both logically correct but structurally incompatible — the automatic resolution may produce syntactically valid but semantically wrong code.

**Correction**: Always read both sides. Use diff3 conflict style to see the common ancestor.

```bash
# GOOD — inspect with diff3
$ git config --global merge.conflictstyle diff3
# Conflict markers now show: <<<<<<< ours | ||||||| base | ======= theirs >>>>>>>

# GOOD — manual resolution with understanding
$ git diff --conflict=diff3 src/services/payment.js
# Read all three sides, understand what each branch changed and why
# Then edit the file to preserve both intended behaviors
$ git add src/services/payment.js
$ git commit -m "merge: integrate payment webhook with existing retry logic"
```

---

### God Commit

**Definition**: A single commit that bundles multiple unrelated concerns across many files, making it impossible to bisect, revert, or review independently.

**Manifestations**:
```bash
# BAD — 47 files, 12 features, 1 commit
$ git log --oneline -1
a3f9d21 feat: implement user system
# Files changed: auth.py, profile.py, permissions.py, email.py, 
#   models.py, migrations/, tests/, config.py, requirements.txt
```

**Why it's dangerous**: God commits are unbisectable — if a regression appears in this commit, you cannot isolate which of the 12 features caused it. They are unreviewable — no reviewer can hold 47 files in working memory. They are unrevertable — reverting the commit removes all 12 features, not just the buggy one.

**Correction**: Split into atomic commits, each representing one logical change that can be independently reverted.

```bash
# GOOD — atomic commits, each independently revertable
$ git log --oneline -4
c7e1b44 feat(auth): add JWT generation and validation
b2d8a91 feat(profile): add user profile CRUD endpoints
9f4c2e3 feat(permissions): add role-based access guard
1a8e5d7 feat(email): add verification email on signup
```

---

### Merge Commit Graffiti

**Definition**: Accumulating meaningless merge commits ("Merge branch 'main' into feature/xyz") throughout a feature branch's history, obscuring the actual feature work and making bisect and log reading noisy.

**Manifestations**:
```bash
# BAD — every pull creates a merge commit
$ git log --oneline --graph feature/user-auth
*   a3f9d21 Merge branch 'main' into feature/user-auth
|\
| * b2d8a91 fix: correct login validation
* | 9f4c2e3 feat: add OAuth callback
* | 1a8e5d7 Merge branch 'main' into feature/user-auth
|\
| * c7e1b44 docs: update API spec
* | 8d2f3a1 feat: add user registration
```

**Why it's dangerous**: Merge commit graffiti makes `git log --oneline` unreadable, makes `git bisect` skip over meaningful commits, and obscures the actual feature development narrative. Code archaeology becomes unnecessarily difficult.

**Correction**: Use `git pull --rebase` to replay local commits on top of updated remote. Configure once globally.

```bash
# GOOD — linear history with rebased pulls
$ git config --global pull.rebase true
$ git pull origin main
# → replays your local commits on top of latest main, no merge commits

# Result:
$ git log --oneline --graph feature/user-auth
* 9f4c2e3 feat: add OAuth callback
* 8d2f3a1 feat: add user registration
* b2d8a91 fix: correct login validation
* c7e1b44 docs: update API spec
```

---

### Stash Graveyard

**Definition**: Creating multiple stashes without descriptive messages, then being unable to determine which stash contains what work, leading to lost or duplicated effort.

**Manifestations**:
```bash
# BAD — no message, no context
$ git stash
$ git stash
$ git stash
$ git stash list
stash@{0}: WIP on feature/auth: a3f9d21
stash@{1}: WIP on feature/auth: a3f9d21
stash@{2}: WIP on feature/auth: a3f9d21
# → which is which? impossible to tell
```

**Why it's dangerous**: Stash graveyards lead to code loss (discarding the wrong stash), duplicated work (re-implementing because the stash was forgotten), or incorrect merges (applying a stale stash to a changed codebase).

**Correction**: Always use descriptive stash messages. Treat stashes as temporary — convert to commits or discard within 24 hours.

```bash
# GOOD — descriptive stash messages
$ git stash push -m "WIP: OAuth callback handler, tests failing on redirect URI"
$ git stash push -m "WIP: password reset email template, waiting on copy review"
$ git stash list
stash@{0}: On feature/auth: WIP: password reset email template, waiting on copy review
stash@{1}: On feature/auth: WIP: OAuth callback handler, tests failing on redirect URI
```
