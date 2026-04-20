# Git 版本控制大师 — Domain 3: PR Preparation and Submodule Management

## 3.1 PR Preparation Checklist

Before opening a PR, the branch must pass the following checks.

### Pre-PR Checklist

```bash
# 1. Branch is up-to-date with target branch
$ git fetch origin
$ git rebase origin/main

# 2. Commits are atomic and follow Conventional Commits
$ git log --oneline origin/main..HEAD
# Verify: each commit is one logical change, messages follow type(scope): description

# 3. No WIP, fixup, or temporary commits remain
$ git log --oneline origin/main..HEAD | grep -iE "wip|fixup|tmp|temp|debug"
# Should return empty

# 4. Tests pass on the branch
$ ./scripts/test.sh   # or equivalent test command

# 5. Diff is reviewable (not too large)
$ git diff --stat origin/main..HEAD
# If > 20 files or > 500 lines, consider splitting into multiple PRs

# 6. No unrelated changes
$ git diff --name-only origin/main..HEAD
# Every changed file should relate to the PR's stated purpose
```

### Branch Naming Convention

```
type/scope-short-description

Examples:
feat/auth-oauth2-pkce
fix/payment-webhook-timeout
docs/api-authentication-examples
refactor/user-service-extract-repository
test/payment-integration-coverage
```

### PR Description Template

```markdown
## Summary
One-paragraph description of what this PR does and why.

## Changes
- List of specific changes (can reference commit messages)
- Link to related issue: Fixes #123

## Testing
- How the changes were tested
- Test output or coverage report

## Rollback
- How to revert this change if needed
- Any database migrations or state changes to consider
```

## 3.2 Submodule Management

Submodules allow embedding one git repository inside another. They are powerful but error-prone.

### Submodule Basics

```bash
# Add a submodule
$ git submodule add https://github.com/example/shared-lib.git libs/shared-lib
# Creates .gitmodules entry and clones the submodule

# Clone a repo with submodules
$ git clone --recurse-submodules https://github.com/example/main-project.git

# Initialize submodules in an existing clone
$ git submodule update --init --recursive

# Update submodule to track latest remote commit
$ cd libs/shared-lib
$ git pull origin main
$ cd ../..
$ git add libs/shared-lib
$ git commit -m "chore(deps): update shared-lib to latest"
```

### Submodule Anti-Patterns

**Detached HEAD in submodule**: After `git submodule update`, the submodule is in detached HEAD state (not on a branch). Changes made here are easy to lose.

```bash
# BAD — making changes in detached HEAD submodule
$ cd libs/shared-lib
$ git checkout -b fix-bug           # Create branch to preserve work
# Make changes, commit, push
$ cd ../..
$ git add libs/shared-lib
$ git commit -m "fix: patch shared-lib bug"
```

**Forgetting to commit parent repo after submodule update**: The parent repo tracks the submodule's commit SHA. If you update the submodule but forget to commit the parent repo, other developers will get the old submodule commit.

```bash
# GOOD — always commit parent after submodule change
$ cd libs/shared-lib
$ git pull origin main
$ cd ../..
$ git add libs/shared-lib           # Stage the submodule commit SHA change
$ git status                        # Verify submodule is staged
$ git commit -m "chore(deps): update shared-lib to v2.3.1"
```

### Submodule vs. Subtree Decision

| Factor | Submodule | Subtree |
|--------|-----------|---------|
| Repository size | Smaller (only SHA stored) | Larger (full history embedded) |
| Contributor complexity | Higher (must understand submodule commands) | Lower (looks like normal files) |
| Upstream contribution | Easy (submodule is separate repo) | Requires split command |
| Version pinning | Explicit (SHA tracked) | Implicit (merge commit) |
| Build system integration | May need special handling | Seamless |

**Recommendation**: Use submodules for external dependencies that evolve independently. Use subtrees for internal shared code that most contributors need to modify. For most teams, avoiding submodules entirely (use package managers instead) is the safest default.

## 3.3 Pre-Flight Protocol (Destructive Operations)

The full pre-flight sequence is mandatory before any destructive operation.

### Pre-Flight Sequence

```bash
# Step 1: Record current state
$ git status
# → working tree clean (or stash WIP)

# Step 2: Review pending changes
$ git diff
# → understand what would be affected

# Step 3: Review recent history
$ git log --oneline -10
# → confirm you're on the expected branch, understand context

# Step 4: Record HEAD SHA (rollback lifeline)
$ git rev-parse HEAD
# → a3f9d21b8c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f

# Step 5: Check if branch is shared (for rebase/amend operations)
$ git log --format='%an' origin/$(git branch --show-current) | sort -u
# → if multiple authors, branch is shared — DO NOT REBASE

# Step 6: Execute the operation
$ git rebase -i HEAD~5
# (or reset, amend, etc.)

# Step 7: Verify result
$ git log --oneline -5
$ git status
$ git diff origin/main...HEAD       # confirm diff is preserved
```

### Destructive Operation Classification

| Operation Class | Examples | Pre-Flight Required |
|-----------------|----------|---------------------|
| Read-only | `log`, `blame`, `show`, `diff` | Step 4 only |
| Branch ops | `checkout`, `branch`, `merge` | Steps 1-4 |
| History rewrite | `rebase`, `reset`, `amend`, `filter-branch` | Steps 1-6 |
| Remote ops | `push`, `fetch`, `pull` | Steps 1-4 + remote verification |

## 3.4 Git Hooks and Verification Bypass

### Hook F (Gitleaks) Protocol

Hook F runs gitleaks on every commit to detect credential leaks. Bypassing it is a security risk.

```bash
# NEVER do this without explicit user authorization
$ git commit -m "feat: add AWS config" --no-verify
# → bypasses gitleaks scan, may commit credentials

# If gitleaks is failing on false positives:
# 1. Verify the flagged content is NOT a credential
# 2. Add to .gitleaksignore if legitimate
# 3. Re-commit WITHOUT --no-verify
```

### When --no-verify is Acceptable

- Pre-commit hook has a known bug that is blocking urgent work
- User has explicitly authorized the bypass with a stated reason
- The bypass is logged and the hook bug is reported for fixing

Even when authorized, prefer fixing the root cause over repeated bypasses.
