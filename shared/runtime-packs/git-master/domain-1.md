# Git 版本控制大师 — Domain 1: History Rewriting and Cleanup

## 1.1 Interactive Rebase

Interactive rebase (`git rebase -i`) is the primary tool for cleaning up commit history before PR. It is ONLY for local/personal branches.

### Available Commands

| Command | Action | Use Case |
|---------|--------|----------|
| `pick` | Keep commit as-is | Default — use for commits that are already clean |
| `reword` | Change commit message only | Fix typos, add scope, improve description |
| `squash` | Combine with previous commit, keep both messages | Merge related commits, edit combined message |
| `fixup` | Combine with previous commit, discard this message | Merge fix commits into the commit they fix |
| `edit` | Pause to amend commit | Split a commit, add forgotten files, fix staged content |
| `drop` | Remove commit entirely | Delete WIP commits that should not reach main |
| `exec` | Run shell command after this commit | Run tests, linting, or validation at each step |

### Squash Strategy for PR Preparation

```bash
# Scenario: 9 commits on feature branch, messy history
$ git log --oneline -9
a3f9d21 WIP
b2d8a91 more WIP
9f4c2e3 fix
c7e1b44 fix typo
1a8e5d7 fix again
8d2f3a1 add tests
7e4c5f2 fix test
6b3a8e1 cleanup
5f2d1a0 done

# Group into logical units:
# Group 1 (UI component work): a3f9d21 + b2d8a91 + 9f4c2e3 + c7e1b44 + 1a8e5d7
# Group 2 (test coverage): 8d2f3a1 + 7e4c5f2
# Group 3 (cleanup): 6b3a8e1

$ git rebase -i HEAD~9
# In editor:
pick a3f9d21 WIP
squash b2d8a91 more WIP
squash 9f4c2e3 fix
squash c7e1b44 fix typo
squash 1a8e5d7 fix again
pick 8d2f3a1 add tests
fixup 7e4c5f2 fix test
pick 6b3a8e1 cleanup

# Result after editing combined messages:
$ git log --oneline -3
f1e2d3c feat(checkout): redesign checkout flow with new step indicator
e4b5a6d test(checkout): add unit tests for step navigation
d7c8e9f chore(checkout): remove unused CSS variables
```

### Commit Splitting with Edit

```bash
# A commit bundles two unrelated changes
$ git rebase -i HEAD~3
# Change "pick" to "edit" for the commit to split

# Rebase pauses at the commit
$ git reset HEAD~1                    # soft reset — changes stay in working tree
$ git add -p src/services/auth.py     # stage only the auth changes
$ git commit -m "feat(auth): add JWT refresh token endpoint"
$ git add -p src/services/email.py    # stage only the email changes
$ git commit -m "feat(email): add password reset email template"
$ git rebase --continue
```

## 1.2 Reflog Recovery

The reflog is the safety net for every git operation. It records every HEAD position for 90 days (default).

```bash
# View reflog
$ git reflog
a3f9d21 HEAD@{0}: rebase -i (finish): returning to refs/heads/feature/auth
b2d8a91 HEAD@{1}: rebase -i (pick): feat(auth): add JWT refresh token endpoint
9f4c2e3 HEAD@{2}: rebase -i (start): checkout HEAD~3
c7e1b44 HEAD@{3}: commit: WIP: password reset

# Recover a dropped commit
$ git checkout c7e1b44              # inspect the lost commit
$ git branch recover-password-reset c7e1b44   # restore as named branch

# Recover a deleted branch
$ git reflog | grep "checkout: moving from feature/auth to"
# Find the SHA before the checkout that deleted the branch
$ git branch recovered-feature-auth <sha>

# Cherry-pick a single recovered commit
$ git cherry-pick c7e1b44
```

## 1.3 Commit Message Discipline

### Conventional Commits Format

```
type(scope): description

[optional body]

[optional footer]
```

**Types**: `feat` (new feature), `fix` (bug fix), `docs` (documentation), `style` (formatting, no logic change), `refactor` (code change neither fix nor feature), `perf` (performance improvement), `test` (adding tests), `chore` (build/process/tooling), `ci` (CI configuration), `build` (build system), `revert` (revert previous commit)

**Scope**: the module, component, or domain affected. Examples: `auth`, `payment`, `api`, `db`, `ci`, `docs`

**Description**: imperative mood, lowercase, no period at end. "add" not "added", "fix" not "fixed".

```bash
# GOOD
feat(auth): add OAuth2 PKCE flow for mobile clients
fix(payment): correct webhook signature validation for Stripe
test(api): add integration tests for rate-limited endpoints
chore(deps): upgrade PostgreSQL driver to v15.2

# BAD
added new feature                    # no type, no scope
fix: fixed the bug                   # redundant "fixed", no scope
feat: implement user system          # too broad, no specific scope
WIP                                  # completely uninformative
```

## 1.4 Bisect Automation

Bisect performs binary search through commit history to find the first bad commit.

```bash
# Manual bisect
$ git bisect start
$ git bisect bad HEAD                # current HEAD is known bad
$ git bisect good v2.1.0             # tag v2.1.0 is known good
# Git checks out middle commit, you test and mark good/bad
$ git bisect good                    # or "git bisect bad"
# Repeat until first bad commit is identified
$ git bisect reset                   # mandatory — returns to original HEAD

# Automated bisect with test script
$ git bisect start
$ git bisect bad HEAD
$ git bisect good v2.1.0
$ git bisect run ./scripts/test-email-trigger.sh
# Script must exit 0 for good, non-zero for bad
# Bisect runs ~log2(N) iterations automatically
$ git bisect reset

# Bisect skip (for commits that cannot be tested)
$ git bisect skip                    # marks current commit as untestable
```

### Bisect Report Requirements

When bisect identifies the first bad commit, the report must include:
1. First bad commit SHA
2. Commit message and author
3. The specific code change causing the regression
4. Why the change broke the behavior (root cause analysis)
5. Recommendation for fix (escalate to implementer)
