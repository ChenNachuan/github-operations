# Git Operations

Complete command reference for git operations. Covers clone/sync, branching, merge/rebase mechanics, and recovery.

---

## Orientation (always first)

```bash
git status -sb                    # where am I, what changed
git remote -v                     # what remotes exist
git log --oneline --graph --decorate -20   # recent history
git branch -vv                    # tracking state
gh repo view --json nameWithOwner,defaultBranchRef   # repo identity + default branch
```

**Rule zero**: read `git log` and any templates/CODEOWNERS before applying conventions.

---

## Clone & Sync

```bash
git clone <url>                    # full clone
git clone --depth 1 <url>          # shallow (only tip)
git fetch origin                   # get updates without merging
git status -sb                     # see how far behind
git pull --ff-only                 # safe default — never blind `git pull`
git pull --rebase                  # explicit rebase on divergent branches
```

**Why `--ff-only`**: `git pull` = fetch + merge, can create surprise merge commits. `--ff-only` fails cleanly if divergent; escalate deliberately.

---

## Branch Management

```bash
# Create from correct base
git switch main && git pull --ff-only && git switch -c feat/<name>

# Or branch from a specific remote
git switch -c feat/<name> origin/main

# Inspect
git branch -vv                    # tracking info
git log --oneline main..HEAD      # commits ahead of main

# Cleanup
git branch -d <name>              # delete merged branch
git branch -D <name>              # force delete (confirm with user)
git push origin --delete <name>   # delete remote branch
```

---

## Push & Upstream

```bash
git push -u origin HEAD           # push current branch, set upstream
git push                          # subsequent pushes
git push --force-with-lease       # ONLY after confirmation, only for local-only rewrites
```

**NEVER**: `git push --force` on `main`/`master`/shared branches.

---

## Merge vs Rebase Mechanics

### Merge

```bash
git switch main
git merge feat/<name>             # creates merge commit, preserves history
git merge --no-ff feat/<name>     # force merge commit (if fast-forward possible)
```

- Preserves branch topology and commit SHAs
- Safe for shared history
- Can create complex graphs

### Rebase

```bash
git switch feat/<name>
git rebase origin/main            # replay commits on top of main
git rebase --abort                # panic button
git rebase --continue             # after resolving conflict
```

- Linearizes history
- **Rewrites SHAs** — never rebase commits already on shared remote
- Use `--force-with-lease` to push after rebase

### Decision table

| Situation | Use |
|-----------|-----|
| Feature branch, want linear main | squash merge |
| Feature branch, want full history | merge commit |
| Updating stale feature branch | rebase onto origin/main |
| Hotfix, port one commit | cherry-pick |

---

## Conflict Resolution

1. `git merge` or `git rebase` → conflict markers appear
2. **Surface conflicts to user** — don't auto-resolve ambiguous ones
3. For clear conflicts: edit files, remove `<<<<<<<` markers
4. `git add <resolved-files>`
5. `git merge --continue` or `git rebase --continue`
6. Panic: `git merge --abort` / `git rebase --abort`

---

## Stash

```bash
git stash push -m "descriptive label"    # always label!
git stash list                           # see what's stashed
git stash pop                            # apply + drop (careful!)
git stash apply                          # apply, keep stash
git stash drop <id>                      # remove old stash
```

**Stash is not a backup**: `stash pop` drops on success. For anything longer than minutes, use a WIP commit on a throwaway branch.

---

## Cherry-Pick

```bash
git cherry-pick <sha>              # port one commit
git cherry-pick <sha1> <sha2>      # port multiple
git cherry-pick --abort            # cancel
```

Use for hotfixes when you can't merge the full branch.

---

## Tags

```bash
git tag -a v1.2.0 -m "Release description"
git push origin v1.2.0
git push origin --tags            # push all tags
```

---

## Submodules

```bash
git clone --recurse-submodules <url>
git submodule update --init --recursive   # after pull when pointer moved
```

Detached HEAD inside submodules is normal — that's the pinned commit.

---

## Recovery

### git reflog — the universal undo

```bash
git reflog                        # see all HEAD movements
git reset --hard HEAD@{2}         # go back 2 steps
```

### Reset semantics

| Command | Working tree | Staging | History |
|---------|-------------|---------|---------|
| `git reset --soft <sha>` | Keep | Keep | Move HEAD |
| `git reset --mixed <sha>` | Keep | Unstage | Move HEAD |
| `git reset --hard <sha>` | **Discard** | **Discard** | Move HEAD |

### Revert (safe for shared history)

```bash
git revert <sha>                  # creates undo commit, safe to push
```

### Restore uncommitted changes

```bash
git restore <file>                # discard uncommitted changes to file
git restore --staged <file>       # unstage
```

### Decision tree

| Symptom | Command |
|---------|---------|
| Wrong commit on unpushed branch | `git reset --soft HEAD~1` |
| Wrong commit on pushed branch | `git revert <sha>` |
| Lost a branch | `git reflog` → `git switch -c <name> <sha>` |
| Accidentally deleted file | `git restore <file>` |
| Merged wrong branch | `git revert -m 1 <merge-sha>` |
| Detached HEAD | `git switch -c <name>` |

---

## Gotchas

- **Detached HEAD**: any commit not on a branch is lost on switch — `git switch -c <name>` before committing
- **Default branch name varies**: `main`, `master`, `trunk` — discover via `git remote show origin` or `gh repo view --json defaultBranchRef`
- **Commit hygiene**: never commit secrets; check `git diff --staged` before commit; `git commit -s` for sign-off
- **Amend only unpushed**: amending pushed commits requires coordinated rewrite + `--force-with-lease`
- **Worktrees**: `GIT_DIR` vs `GIT_COMMON_DIR` distinguishes a worktree; detached-HEAD worktrees can't merge back
