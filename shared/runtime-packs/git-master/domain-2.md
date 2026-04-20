# Git 版本控制大师 — Domain 2: Branch Topology and Merge Mechanics

## 2.1 Branch Strategy Selection

Branch strategy must fit team size, release cadence, and deployment model.

### Decision Matrix

| Strategy | Team Size | Release Cadence | Deployment Model | Complexity |
|----------|-----------|-----------------|------------------|------------|
| **Gitflow** | 5+ developers | Versioned, scheduled (weekly/monthly/quarterly) | Manual or gated releases | High |
| **GitHub Flow** | 2-5 developers | Continuous, on-demand | CI/CD auto-deploy from main | Low |
| **Trunk-based** | 3-8 developers | Multiple times per day | Feature flags required | Medium |
| **Release Branching** | Any | Hotfix-driven | Long-term support versions | Medium |

### Gitflow (Detailed)

```
main          ●────●────●────●────●────●────●────●
              ↑    ↑              ↑         ↑
           v1.0  v1.1           v1.2      v1.3

develop       ●────●────●────●────●────●────●────●
                   ↑         ↑    ↑         ↑
              feature/a  feature/b  release/1.2
                            ↑
                         hotfix/1.1.1
```

**Branch rules**:
- `main`: production-ready, only merge from `release/*` or `hotfix/*`
- `develop`: integration branch, merge feature branches here
- `feature/*`: branch from `develop`, merge back to `develop` via PR
- `release/*`: branch from `develop` when release is frozen, merge to `main` and `develop`
- `hotfix/*`: branch from `main`, merge to `main` and `develop`

### Trunk-based Development

```
main          ●────●────●────●────●────●────●────●
                   ↑    ↑    ↑    ↑    ↑
              feature/a  feature/b  feature/c  feature/d
              (< 1 day each, feature flags for incomplete work)
```

**Rules**:
- All work branches from `main`
- Feature branches live < 2 days
- Incomplete features are hidden behind feature flags
- No long-lived integration branches
- Requires comprehensive CI/CD and feature flag infrastructure

### GitHub Flow

```
main          ●────●────●────●────●────●────●────●
                   ↑              ↑
              feature/login   feature/payment
              (PR → review → merge to main → deploy)
```

**Rules**:
- `main` is always deployable
- All work on feature branches
- PR required for every merge to `main`
- Merge to `main` triggers deployment
- No separate develop or release branches

## 2.2 Merge Mechanics

### Fast-Forward vs. No-Fast-Forward vs. Squash

```bash
# Fast-forward merge (default when possible)
# Result: linear history, no merge commit
$ git checkout main
$ git merge feature/auth
# main now points to the same commit as feature/auth

# --no-ff merge (always create merge commit)
# Result: preserves branch topology, visible in log
$ git checkout main
$ git merge --no-ff feature/auth
# Creates explicit merge commit: "Merge branch 'feature/auth'"

# Squash merge (collapse branch to single commit)
# Result: clean linear history, loses individual commit granularity
$ git checkout main
$ git merge --squash feature/auth
$ git commit -m "feat(auth): add complete authentication system"
# All changes from feature/auth in one commit on main
```

### Merge Strategy Selection

| Scenario | Recommended Strategy | Rationale |
|----------|---------------------|-----------|
| Personal feature branch → main | Fast-forward or rebase-then-ff | Clean history |
| Team feature branch → develop | `--no-ff` | Preserve branch topology for audit |
| Release branch → main | `--no-ff` | Mark release point explicitly |
| Hotfix → main + develop | `--no-ff` | Traceability for security fixes |
| Long-lived feature with messy history | Squash | Clean main, details in PR |
| Short-lived feature with clean atomic commits | Fast-forward | Preserve commit granularity |

## 2.3 Conflict Anatomy with diff3

Understanding the three-way merge structure is essential for correct resolution.

```bash
# Enable diff3 conflict style
$ git config --global merge.conflictstyle diff3

# Conflict markers in a file:
<<<<<<< HEAD                          # OURS: current branch
function validateToken(token) {
  return jwt.verify(token, SECRET);
}
||||||| a3f9d21                       # BASE: common ancestor
function validateToken(token) {
  return jwt.verify(token, SECRET, { expiresIn: '1h' });
}
=======
function validateToken(token) {
  return jwt.verify(token, PUBLIC_KEY, { algorithm: 'RS256' });
}
>>>>>>> feature/auth                  # THEIRS: incoming branch
```

### Resolution Decision Tree

1. **Read BASE**: What did the code look like before either branch changed it?
2. **Read OURS**: What did the current branch change? Why?
3. **Read THEIRS**: What did the incoming branch change? Why?
4. **Determine precedence**: Which change is more correct for the target branch's context?
5. **Check for semantic merge**: Are both changes logically correct but structurally conflicting? If so, combine them.
6. **Verify**: After editing, does the file compile? Do tests pass?

### When to Escalate

Escalate to the relevant implementer when:
- Both sides changed business logic and you cannot determine which is correct
- The conflict involves security-critical code (auth, encryption, input validation)
- The conflict is in a file you do not recognize or understand
- Both changes appear correct but are mutually exclusive architectural decisions

## 2.4 Remote Hygiene

### Pruning and Cleanup

```bash
# Remove remote-tracking branches that no longer exist on remote
$ git fetch --prune

# Explicit prune
$ git remote prune origin

# List branches merged to main (candidates for deletion)
$ git branch --merged main

# Delete local branches that have been merged
$ git branch --merged main | grep -v "^\*" | grep -v "main" | xargs -n 1 git branch -d

# Force delete unmerged branch (use with caution)
$ git branch -D feature/abandoned
```

### Force-With-Lease Safety

```bash
# Standard force push (DANGEROUS — overwrites remote without checking)
$ git push origin feat/auth --force

# Safe force push (RECOMMENDED — fails if remote has unknown commits)
$ git push origin feat/auth --force-with-lease
# Equivalent to: "only force-push if the remote ref still points to what I think it points to"

# Force-with-lease with explicit expected ref
$ git push origin feat/auth --force-with-lease=feat/auth:origin/feat/auth
```

### Tag Strategy

```bash
# Annotated tag (RECOMMENDED for releases — carries tagger, date, message)
$ git tag -a v1.2.0 -m "Release v1.2.0: OAuth2 support, payment webhooks"

# Lightweight tag (bookmark only — no metadata)
$ git tag v1.2.0
# Use only for internal/temporary markers

# Push single tag
$ git push origin v1.2.0

# Push all tags
$ git push origin --tags

# Delete remote tag
$ git push origin --delete v1.2.0

# Semantic Versioning discipline
# MAJOR.MINOR.PATCH
# MAJOR: breaking API changes
# MINOR: new features, backward compatible
# PATCH: bug fixes, backward compatible
```

## 2.5 Cherry-Pick Strategy

Cherry-pick ports specific commits from one branch to another.

```bash
# Single commit cherry-pick
$ git checkout release/v2.1
$ git cherry-pick a3f9d21

# Cherry-pick without auto-commit (stage only)
$ git cherry-pick -n a3f9d21
# Allows combining multiple cherry-picks into one commit

# Cherry-pick range
$ git cherry-pick a3f9d21^..c7e1b44   # from a3f9d21 to c7e1b44 inclusive

# Cherry-pick with original commit message
$ git cherry-pick -x a3f9d21
# Appends "(cherry picked from commit a3f9d21)" to message
```

### Cherry-Pick Conflict Handling

When cherry-pick conflicts:
1. Resolve conflicts manually
2. `git add <resolved-files>`
3. `git cherry-pick --continue`
4. Or abort: `git cherry-pick --abort`

If the cherry-pick depends on infrastructure not present in the target branch, do NOT resolve by adapting the code. Escalate to @dev-lead — cherry-picking without dependencies creates broken code.
