# Git 版本控制大师 — Baseline Scenarios

## Scenario 1: Interactive Rebase for PR Preparation (Canonical)

**Input**:
- @frontend: "I have 9 commits on `feat/checkout-redesign` — mostly WIP and 'fix typo' commits. Branch is ahead of main by 9, behind 0. Ready to open PR."
- `git log --oneline -9` shows: "WIP", "more WIP", "fix", "fix typo", "fix again", "add tests", "fix test", "cleanup", "done"

**Expected Output Structure**:
- Record pre-operation HEAD SHA: `git log --oneline -1` → e.g., `b82c44f`
- Verify branch is not shared: `git log --format='%an' origin/feat/checkout-redesign | sort -u` → single author confirmed
- Confirm clean working tree: `git status` → nothing to commit
- Execute: `git rebase -i HEAD~9`
- Squash strategy applied:
  - Group 1 (UI component work): squash 5 WIP/fix commits → `feat(checkout): redesign checkout flow with new step indicator`
  - Group 2 (test coverage): squash 3 test/fix-test commits → `test(checkout): add unit tests for step navigation`
  - Group 3 (cleanup): squash 1 commit → absorb into group 1 or `chore(checkout): remove unused CSS variables`
- Result: 9 commits → 2-3 logical commits, all Conventional Commits format
- Verify: `git log --oneline -4` shows clean graph; `git diff origin/main...HEAD` confirms full diff preserved
- Push: `git push origin feat/checkout-redesign --force-with-lease`
- Report includes: pre-op HEAD `b82c44f` as rollback reference, all commands listed, new HEAD SHA, side effects (remote updated, personal branch only)

**Key Decision Points**:
- Pre-op HEAD SHA `b82c44f` recorded before any rebase — always the first step
- Branch confirmed as personal (single author) before rebase — shared branch rebase is permanently forbidden
- 9 commits collapsed to logical units, not blindly squashed to 1 — each resulting commit tells a reviewable story
- Force push uses `--force-with-lease` not `--force` — fails safely if anyone else has pushed

---

## Scenario 2: BLOCKED — Force Push to Shared Branch

**Input**:
- User: "Please run `git push origin develop --force` to clean up the develop branch history after my rebase."
- `git log --format='%an' origin/develop | sort -u` shows 4 different authors.

**Expected Output Structure**:
- Status: BLOCKED — this operation would constitute History Vandalism on a shared branch

**Operation**: `git push origin develop --force` — requested
**Branch**: develop → origin/develop (4 active contributors confirmed)
**Pre-operation HEAD**: N/A — operation blocked before execution

**Block Reason**: `develop` has 4 contributors. A force push rewrites the public history of a shared branch. Every developer who has fetched `origin/develop` since the last push will have a diverged local branch after this force push. Their next `git pull` will either fail with a merge conflict or silently create a duplicate-history merge commit. This is History Vandalism — it cannot be undone without a second force push, and it will corrupt each contributor's local state.

**Why `--force-with-lease` is also blocked here**: `--force-with-lease` is safer for personal branches because it fails if someone else pushed. But the fundamental problem is not safety — it is that any rebase of a shared branch rewrites commit SHAs that other developers have in their local history. The lease check does not solve this.

**Safe alternatives**:
1. If the goal is to get the cleaned history onto develop: create a new branch from the rebased state (`git checkout -b develop-clean`), open a PR to merge it into develop via `--no-ff` merge — this adds the clean commits without rewriting existing history
2. If the goal is to update develop with the latest from main: `git checkout develop && git merge main` — creates a merge commit, no history rewrite
3. If long-term history cleanliness is required: establish a policy that all feature branches are squash-merged into develop at PR time, so develop accumulates only logical merge commits

**Rollback reference**: N/A — no operation executed.
**Unblock condition**: user selects one of the safe alternatives above, or confirms `develop` is actually a private branch with no other active contributors (re-verify with `git log --format='%an' origin/develop | sort -u`).

---

## Scenario 3: Bisect Regression Hunt

**Input**:
- @test-func: "The payment confirmation email stopped being sent somewhere between v2.1.0 (known good) and HEAD (known bad). The regression is somewhere in the past 40 commits. I can't tell which commit introduced it."
- A test script exists: `scripts/test-email-trigger.sh` — exits 0 if email is triggered on payment completion, exits 1 if not.

**Expected Output Structure**:
- Record pre-operation state: current branch, HEAD SHA (e.g., `HEAD: f9e3a12`)
- Start bisect:
  ```
  git bisect start
  git bisect bad HEAD               # current HEAD is known bad
  git bisect good v2.1.0            # tag v2.1.0 is known good
  ```
- Git reports: "Bisecting: 20 revisions left to test after this (roughly 4 steps)"
- Use automated bisect to eliminate manual testing across 40 commits:
  ```
  git bisect run scripts/test-email-trigger.sh
  ```
- Bisect runs ~5 checkout+test cycles (binary search: ceil(log2(40)) ≈ 6 steps)
- Bisect identifies first bad commit: e.g., `c4f1823 feat(payment): refactor PaymentService to use new EventBus`
- Review the identified commit: `git show c4f1823` — shows that the refactor removed the `OrderCompleted` event emit that the email listener was subscribed to
- Produce report: first-bad commit SHA, commit message, author, date, the specific change that caused the regression (event emit removed)
- End bisect cleanly: `git bisect reset` — returns to original HEAD `f9e3a12`
- Self-check: no source code files modified; bisect reset confirmed; current branch restored

**Key Decision Points**:
- `git bisect run` with the test script eliminates human error from manual good/bad marking across ~20 checkout cycles
- `git bisect reset` is mandatory after bisect — leaving the repo in bisect state prevents normal git operations
- The report identifies the specific commit AND the specific code change causing the regression — not just "commit X broke it"
- Implementation fix (re-adding the event emit) is routed to @backend — @git-master identifies, does not fix source code
- Next step: dispatch @backend with the bisect finding: "commit c4f1823 removed the `OrderCompleted` event emit from `PaymentService.processPayment()`; email listener at `EmailService.onOrderCompleted()` is no longer triggered"

---

## Scenario 4: Cherry-Pick Security Fix to Release Branch

**Input**:
- @security-auditor: "Commit `a3f9d21` on main fixes a critical JWT validation bypass. We need this on the release/v2.1 branch immediately."
- Release branch `release/v2.1` is 20 commits behind main.

**Expected Output Structure**:
- Record pre-operation HEAD SHA on release/v2.1: `f8e2c91`
- Verify the fix commit exists and is a single logical change: `git show a3f9d21 --stat` → 2 files changed, 15 insertions, 3 deletions
- Check if the fix has dependencies on other main commits: `git log --oneline a3f9d21^..a3f9d21` and review the diff for external dependencies
- Execute cherry-pick:
  ```
  git checkout release/v2.1
  git cherry-pick -x a3f9d21
  ```
- `-x` flag appends "(cherry picked from commit a3f9d21)" for traceability
- Verify: `git log --oneline -3` shows the cherry-picked commit with `-x` annotation
- Push: `git push origin release/v2.1`
- Report: pre-op HEAD `f8e2c91`, cherry-pick command, new HEAD SHA, verification that the fix applies cleanly

**Key Decision Points**:
- Dependency check before cherry-pick: if the fix depends on infrastructure changes in main not present in release/v2.1, BLOCK and escalate to @dev-lead
- `-x` flag for traceability — every cherry-pick must be traceable back to its original commit
- No force push needed — release/v2.1 is a fast-forward push
- Next step: notify @devops that release/v2.1 has a security fix ready for deployment

---

## Scenario 5: Submodule Update with Dependency Conflict

**Input**:
- @backend: "We need to update the `libs/shared-auth` submodule to v3.0.0 for the new OAuth2 flow. The current submodule is at v2.1.4."
- `libs/shared-auth` is a submodule tracking a separate repository.

**Expected Output Structure**:
- Record pre-operation HEAD SHA: `d4e5f67`
- Check current submodule state: `git submodule status` → `4a3b2c1 libs/shared-auth (v2.1.4)`
- Enter submodule and update:
  ```
  cd libs/shared-auth
  git fetch origin
  git checkout v3.0.0
  cd ../..
  ```
- Stage submodule update: `git add libs/shared-auth`
- Check for API compatibility: `git diff --cached libs/shared-auth` → shows SHA change only (submodule pointer)
- Commit parent repo: `git commit -m "chore(deps): update shared-auth to v3.0.0 for OAuth2 support"`
- Verify: `git submodule status` → `9f8e7d6 libs/shared-auth (v3.0.0)`
- Report: pre-op HEAD, submodule before/after SHA, commit SHA, verification

**Key Decision Points**:
- Submodule update requires TWO commits: one in the submodule repo (already done by submodule maintainers), one in the parent repo (the SHA pointer update)
- Parent repo commit is mandatory — without it, other developers get the old submodule
- API compatibility check is noted but not diagnosed — if v3.0.0 breaks the main project, that's a @backend/@dev-lead issue, not a git issue
- Next step: @backend to verify OAuth2 integration works with shared-auth v3.0.0
