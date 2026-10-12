# PR Workflow

Create, review, comment on, and merge pull requests. Covers fork PRs, inline comments, merge strategies, and templates.

---

## Create a PR

```bash
# Push branch first
git push -u origin HEAD

# Create with explicit content (avoids interactive prompts)
gh pr create \
  --title "feat: add user authentication" \
  --body-file pr-body.md \
  --base main \
  --reviewer @user1,@user2 \
  --label feature

# Draft PR (not ready for review)
gh pr create --draft --title "..." --body "..."

# Fill from commits (title/body auto-populated)
gh pr create --fill
```

**Always pass `--title`/`--body` or `--body-file`** — `gh pr create` prompts interactively without them.

### PR body quality

Use `assets/pr-template.md`. A truthful PR body includes:
- **Summary**: what changed and why
- **Test plan**: how you verified
- **Risk**: what could break
- **Screenshots**: if UI changes

**CI truth discipline**: never claim "tests pass" without running them. Re-verify test counts before claiming them. Delete stale numbers.

### Fork PRs

```bash
# When working from a fork
gh pr create --repo upstream/repo --head fork-owner:branch-name

# Cross-org fork (gh limitation): use API
gh api --method POST repos/upstream/repo/pulls \
  -f head="org-name:branch" \
  -f head_repo="fork-owner/repo" \
  -f title="..." -f body="..."
```

**Fork PR limitations**:
- Secrets NOT available to workflows triggered from fork PRs
- `pull_request` from forks runs with read-only token
- Maintainer can push to head branch (unless `--no-maintainer-edit`)

---

## PR Status & Checks

```bash
gh pr view <number> --json state,mergeable,mergeStateStatus,reviews
gh pr checks <number>                     # CI status — always before claiming ready
gh pr diff <number>                       # see changes
gh pr view <number> --web                 # open in browser
```

**mergeStateStatus values**: `CLEAN`, `BLOCKED`, `BEHIND`, `DIRTY`, `UNSTABLE`, `UNKNOWN` — machine-readable answer for "can I merge?"

---

## Review

```bash
gh pr review <number> --approve --body "LGTM"
gh pr review <number> --request-changes --body "Needs tests"
gh pr review <number> --comment --body "Just a note"
```

**Rules**:
- Request changes must include actionable feedback
- Can't approve your own PR
- Re-review after pushes (dismissals may be configured)

---

## Inline Comments (via API)

Line numbers must match the **file content in the PR branch**, not diff positions:

```bash
# Get the line number in the PR branch's file
gh api repos/owner/repo/contents/path/to/file?ref=branch-name \
  -q '.content' | base64 -d | grep -n "target code" | head -1

# Create review with inline comment
gh api repos/owner/repo/pulls/<number>/reviews --method POST \
  -f event="COMMENT" \
  -f body="Overall looks good" \
  -f comments[0][path]="path/to/file" \
  -f comments[0][line]=42 \
  -f comments[0][body]="Consider extracting this into a function"
```

**Critical**: use `line` only — never `position`, `side`, `subject_type`. Multi-line: specify only the ending line. Batch multiple comments in one review.

---

## Comment on PR

```bash
gh pr comment <number> --body "Looks good overall"
gh pr comment <number> --body-file comment.md
```

---

## Merge

```bash
gh pr merge <number> --squash --delete-branch     # default: squash + cleanup
gh pr merge <number> --merge --delete-branch      # preserve branch topology
gh pr merge <number> --rebase --delete-branch     # linear + per-commit

# Auto-merge (merges when requirements met)
gh pr merge <number> --auto --squash
```

**Repo settings may restrict strategies** — `gh pr merge` fails if the chosen one is disabled. Fall back to an allowed strategy.

### Merge strategy decision

| Strategy | History | When |
|----------|---------|------|
| `--squash` | One commit on base | Small PRs; keeps main linear; loses internal SHAs |
| `--merge` | Preserves topology | Feature branches worth keeping |
| `--rebase` | Linear + individual commits | Want linear history AND granularity |

---

## PR Lifecycle

```bash
gh pr ready <number>              # draft → ready for review
gh pr update-branch <number>      # refresh against base
gh pr edit <number> --title "..." # update title/body
gh pr close <number>              # close without merging
gh pr reopen <number>             # reopen closed PR
```

---

## PR Templates

Place `.github/pull_request_template.md` in the repo. Auto-applied to new PRs — read and fill, don't replace with freeform.

---

## Evidence Attachment

For PRs with screenshots/images:
1. Inventory existing screenshots
2. Upload via GitHub attachment UI (drag into comment)
3. Replace placeholders with GitHub URLs
4. Verify images render before claiming they exist

`--body-file` publishes Markdown text — does not upload local file paths.

---

## Multi-PR Scripting

```bash
gh pr list --json number,state,title,mergeable --jq '.[] | select(.state=="OPEN")'
gh pr list --author @me --json number,title --jq '.[].number' | xargs -I{} gh pr view {} --json title
```
