---
name: git-engineering
description: Git version control methodology for the Harness team. Covers commit graph integrity, destructive operation protocols, branch topology fitness (Gitflow / Trunk-based / GitHub Flow), interactive rebase, commit splitting, bisect automation, reflog recovery, merge vs rebase decisions, cherry-pick strategy, conflict resolution with diff3, Conventional Commits, tag strategy, and PR preparation discipline.
type: skill
---

# Git Engineering Skill

## 1. Commit Graph Integrity

Every commit must be:
- **Bisectable**: any regression can be isolated to a single commit via `git bisect`
- **Reviewable**: any PR can be understood in one reading
- **Rollback-safe**: any bad commit can be reverted without side effects

Atomic commit design: one logical change per commit, independently revertable. A "God Commit" bundling 12 features across 500 files with message "stuff" is a history landmine.

Conventional Commits format: `type(scope): description`
- Types: feat, fix, docs, refactor, test, chore, perf, ci, build, revert
- No "WIP", no "fix stuff", no "update"

## 2. Destructive Operation Protocol

Before any operation that rewrites history or discards state (`reset`, `rebase`, `clean`, `branch -D`, `push --force-with-lease`):

1. `git status` — check working tree cleanliness
2. `git diff` — review uncommitted changes
3. `git log --oneline -10` — review recent history
4. Record current HEAD SHA — the rollback lifeline
5. Confirm branch is NOT shared (for history-rewriting ops)
6. Execute

Skipping pre-flight is how "I thought I was on my branch" incidents happen.

## 3. Branch Topology Fitness

| Strategy | Team Size | Release Cadence | Branch Structure |
|---|---|---|---|
| **Gitflow** | Medium-Large | Versioned, scheduled | main + develop + feature/* + release/* + hotfix/* |
| **Trunk-based** | Any | Continuous deployment | main + short-lived feature branches (< 2 days) |
| **GitHub Flow** | Small (< 5) | No versioning overhead | main + feature branches + PRs |

Match topology to reality, not the same template everywhere.

## 4. Interactive Rebase and Commit Cleanup

`git rebase -i HEAD~N` operations:
- `squash` — combine WIP commits into logical units
- `reword` — fix messages without losing content
- `edit` — pause and split a commit with `git add -p` + `git commit --amend`
- `drop` — remove commits that should not reach main

**ONLY on branches not yet pushed to shared remotes.**

Commit splitting: `git reset HEAD~1` (soft) → `git add -p` (hunk-level) → multiple `git commit` calls.

## 5. Merge vs Rebase Decision

| Operation | When to Use |
|---|---|
| **Rebase** | Personal branches before PR; maintaining linear history on team branches |
| **Merge** | Integrating long-lived branches; preserving merge-point context; branch shared with teammates |
| **`--no-ff` merge** | Preserving feature branch topology in log even when fast-forward is possible |
| **`--squash` merge** | Collapsing branch to single commit on main — use only when branch history is intentionally throwaway |

Prevent Merge Commit Graffiti: `git pull --rebase` or `git config --global pull.rebase true`.

## 6. History Operations

**Cherry-pick**: `git cherry-pick <sha>` for porting specific fixes across branches. `-n` flag for multi-commit cherry-picks without auto-commit.

**Bisect**: `git bisect start` → `git bisect bad HEAD` → `git bisect good <known-good-sha>` → binary search. `git bisect run <test-script>` for automated regression hunting (script exits 0 for good, non-zero for bad).

**History archaeology**:
- `git log --follow -p -- <file>` — for renamed files
- `git blame -L <line>,<line>` — for authorship
- `git reflog` — for recovering lost commits (90-day history)

**Reflog recovery**: `git checkout <sha>` to inspect lost commit; `git branch recover-xyz <sha>` to restore dropped branch; `git cherry-pick <sha>` to port single commit back.

## 7. Conflict Resolution

1. Read both sides: `git diff --conflict=diff3` shows BASE (common ancestor) + OURS + THEIRS
2. Understanding BASE reveals the original intent
3. Determine precedence based on semantics
4. Verify no semantic merge (both changes logically correct but structurally conflicting)
5. Use `git mergetool` for complex conflicts
6. Escalate to implementer when business logic understanding is required

NEVER use `git checkout --theirs` or `--ours` blindly without reading both sides.

## 8. Tag Strategy

- **Annotated tags** for releases: `git tag -a v1.2.0 -m "Release v1.2.0"` — carry tagger, date, message
- **Lightweight tags** for internal bookmarks only
- Semver discipline: MAJOR.MINOR.PATCH — breaking.new-feature.bugfix
- Push tags: `git push origin --tags`

## 9. PR Preparation

- **Branch naming**: `type/scope-short-description` (e.g., `feat/user-auth`, `fix/payment-timeout`)
- **Pre-PR rebase**: rebase onto current main to eliminate merge conflicts before review
- **Squash strategy**: squash WIP commits into logical commits; keep multi-commit PRs only when each commit tells a separate reviewable story
- **PR description**: linked issue, change summary, test evidence, rollback procedure

## 10. Remote Hygiene

- `git fetch --prune` — sync remote-tracking refs, remove deleted remote branches
- `git push --force-with-lease` — safe force push: fails if remote has commits not in local tracking ref
- NEVER `--force` push to shared branches. `--force-with-lease` on personal branches only.

## 11. Anti-Patterns

| Name | Symptom | Correction |
|---|---|---|
| **Force-Push Blast** | `git push origin main --force` — overwrites teammates' commits | Never force-push to shared branches |
| **History Vandalism** | Rebasing shared branches — breaks all downstream clones | Interactive rebase ONLY for local/private branches |
| **Blind Conflict Resolution** | `git checkout --theirs` without reading | Read diff3 output, understand both sides |
| **God Commit** | One commit with 47 files across multiple concerns | Split into atomic commits per logical change |
| **Merge Commit Graffiti** | Every `git pull` creates a merge commit | Use `git pull --rebase` |
| **Stash Graveyard** | Dozens of old stash entries | Clean stashes regularly, or commit WIP to feature branch |
