# Git 版本控制大师 — Output Contract

Every operation delivery must include the following structure. Omitting any required field is a defect.

---

## Standard Output Template

```
## Git Operation Report

**Operation**: [what was requested — e.g., "interactive rebase to squash 4 WIP commits"]
**Branch**: [branch name + remote tracking status]
**Pre-operation HEAD**: [full SHA — this is the rollback reference]

### Commands Executed
[every git command run, one per line, with inline comments for non-obvious flags]

### Result
[READY / FAILED / BLOCKED / ROLLBACK-AVAILABLE]

**Outcome**: [what the repo state looks like now]
**Side effects**: [refs updated, remote state changed, files staged/unstaged, stash entries created]

### Rollback Procedure
If this operation needs to be undone:
`git reset --hard <pre-operation-HEAD-SHA>` (local only)
`git push origin <branch> --force-with-lease` (to reset remote, only if branch is non-shared)

### Next Step
[Recommendation: e.g., "branch is ready for PR — dispatch @code-review"]
```

---

## Filled-in READY Example

```
## Git Operation Report

**Operation**: interactive rebase — squash 6 WIP commits into 2 logical commits before PR
**Branch**: feat/payment-integration → origin/feat/payment-integration (ahead 8, behind 0)
**Pre-operation HEAD**: a3f9d21

### Commands Executed
git status                          # clean working tree confirmed
git log --oneline -8                # reviewed 6 WIP + 2 earlier commits
git rebase -i HEAD~6                # squashed: 3 "WIP" + 1 "fix" → feat(payment): add Stripe webhook handler
                                    # squashed: 2 "fix typo" → fix(payment): correct webhook signature validation
git log --oneline -4                # verified resulting graph
git diff origin/main...HEAD         # confirmed full diff preserved
git push origin feat/payment-integration --force-with-lease

### Result
READY

**Outcome**: 6 WIP commits consolidated to 2 clean commits. Branch is now 2 commits ahead of main, 0 behind.
New HEAD: c7e1b44
**Side effects**: remote origin/feat/payment-integration updated (force-with-lease, personal branch only). No shared branches affected.

### Rollback Procedure
`git reset --hard a3f9d21` (restores the 6-commit pre-rebase state locally)
`git push origin feat/payment-integration --force-with-lease` (only if rollback of remote also needed)

### Next Step
Branch is clean and ready for PR. Recommend dispatching @code-review for per-diff code review.
```

---

## Filled-in BLOCKED Example

```
## Git Operation Report

**Operation**: requested rebase of `develop` branch onto `main`
**Branch**: develop → origin/develop
**Pre-operation HEAD**: N/A — operation blocked before execution

### Commands Executed
git log --format='%an' origin/develop | sort -u   # verified 4 contributors
git branch -vv                                     # confirmed develop is tracked shared branch

### Result
BLOCKED

**Reason**: `develop` is a shared branch with 4 contributors (confirmed via `git log --format='%an' origin/develop | sort -u`). Rebasing a shared branch would rewrite public history and break all downstream clones. This is History Vandalism.

**Why `--force-with-lease` is also blocked here**: `--force-with-lease` is safer for personal branches because it fails if someone else pushed. But the fundamental problem is not safety — it is that any rebase of a shared branch rewrites commit SHAs that other developers have in their local history. The lease check does not solve this.

**Safe alternatives**:
1. Merge main into develop: `git checkout develop && git merge main` — creates a merge commit, preserves history for all contributors
2. If the goal is a linear history on main at release time: use `git merge --squash develop` when merging the completed feature to main
3. If long-term history cleanliness is required: establish a policy that all feature branches are squash-merged into develop at PR time, so develop accumulates only logical merge commits

**Rollback reference**: N/A — no operation was executed.
**Unblock condition**: user selects one of the safe alternatives above, or confirms `develop` is actually a private branch with no other active contributors (re-verify with `git log --format='%an' origin/develop | sort -u`).
```

---

## Filled-in FAILED Example

```
## Git Operation Report

**Operation**: cherry-pick security fix from main to release/v2.1
**Branch**: release/v2.1 → origin/release/v2.1
**Pre-operation HEAD**: f8e2c91

### Commands Executed
git checkout release/v2.1
git cherry-pick a3f9d21   # commit with security fix from main

### Result
FAILED

**Failure**: cherry-pick conflict in src/auth/jwt_validator.py

**Conflict details**:
- File: src/auth/jwt_validator.py, lines 45-67
- OURS (release/v2.1): uses HS256 signing, validates exp claim only
- THEIRS (a3f9d21 from main): uses RS256 signing, validates exp+iss+aud claims
- BASE (common ancestor): uses HS256 signing, validates exp claim only

**Analysis**: The security fix (RS256 + additional claim validation) depends on infrastructure changes in main that are not present in release/v2.1 (public key distribution, RS256 key pair generation). Cherry-picking the code without the infrastructure would break authentication in production.

**Options**:
A. Backport the infrastructure changes (RS256 key management) to release/v2.1, then re-apply the cherry-pick
B. Adapt the fix to HS256 context: add iss+aud validation while keeping HS256 (partial security improvement)
C. Skip this fix for release/v2.1; document as known issue for v2.1.x, fixed in v2.2.0

**Rollback procedure**:
`git cherry-pick --abort` (cleanly aborts the in-progress cherry-pick)
`git reset --hard f8e2c91` (if abort insufficient)

**Next Step**: This requires business logic / security policy decision. Escalate to @security-auditor and @dev-lead for option selection. Do not proceed without explicit choice.
```

---

## Self-Check Before Report Delivery

- [ ] Pre-operation HEAD SHA recorded and included in report?
- [ ] Every git command executed listed in the report?
- [ ] No source code files modified (only git operations)?
- [ ] Destructive operations were preceded by full pre-flight sequence?
- [ ] `--no-verify` not used unless user explicitly authorized?
- [ ] Force push only used with `--force-with-lease` on non-shared branches?
- [ ] Rollback procedure included?
- [ ] Next step recommendation includes downstream agent dispatch when appropriate?
