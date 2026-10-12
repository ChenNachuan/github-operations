# Issues & Projects

Issue lifecycle, labels, milestones, templates, and GitHub Projects.

---

## Create Issues

```bash
gh issue create \
  --title "Bug: login page crashes on empty input" \
  --body-file issue-body.md \
  --label bug \
  --assignee @me \
  --milestone "v1.2"

# Quick issue
gh issue create --title "..." --body "..."

# Prefill from URL
# https://github.com/owner/repo/issues/new?template=bug.md&title=...&body=...
```

**Use `--body-file`** for long bodies (URLs >8,000 chars are rejected).

---

## Issue Lifecycle

```bash
# List & search
gh issue list --state open --label bug --search "keyword in:title"
gh issue list --state open --json number,title,labels --jq '.[] | "\(.number): \(.title)"'

# View
gh issue view <number>
gh issue view <number> --web

# Update
gh issue edit <number> --add-label urgent --milestone "v1.3"
gh issue edit <number> --add-assignee @user
gh issue edit <number> --remove-label bug

# Comment
gh issue comment <number> --body "I can reproduce this"
gh issue comment <number> --body-file comment.md

# Close / Reopen
gh issue close <number> --reason completed
gh issue close <number> --reason not_planned
gh issue reopen <number>

# Link to development
gh issue develop <number>          # create/link a branch
```

---

## Issue Classification

| Type | Label | Action |
|------|-------|--------|
| Bug | `bug` | Reproduce → fix → close with PR |
| Regression | `regression` | Was working → broke; high priority |
| Feature | `enhancement` | New capability request |
| Works as designed | `wontfix` | Close with explanation |
| Environment | `env` | User-side issue, not code |
| **Security** | `security` | **Private vulnerability reporting — NEVER public issue** |

**Security issues**: use GitHub's private vulnerability reporting (`/security/advisories`), not public issues.

---

## Labels

```bash
gh label list
gh label create "priority:high" --color "D93F0B" --description "..."
gh label edit "old-name" --name "new-name"
```

**Gotcha**: labels are silently dropped for reporters without push access. Set labels after push access is confirmed.

---

## Milestones

```bash
# gh has no milestone subcommand — use API
gh api repos/owner/repo/milestones -f title="v1.2" -f state="open"
gh issue edit <number> --milestone "v1.2"
```

---

## Issue Templates

Place in `.github/ISSUE_TEMPLATE/`:

```markdown
---
name: Bug Report
about: Something is broken
title: "[Bug] "
labels: bug
assignees: ''
---
## Steps to reproduce
1. 
2. 

## Expected behavior
## Actual behavior
## Environment
```

Or YAML forms for structured input:

```yaml
name: Bug Report
description: File a bug report
body:
  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
    validations:
      required: true
```

---

## Bulk Operations

```bash
# Close stale issues
gh issue list --state open --json number,title,updatedAt --jq \
  '.[] | select(.updatedAt < "2026-01-01") | .number' | \
  xargs -I{} gh issue close {} --reason not_planned

# Add label to multiple
for n in 1 2 3; do gh issue edit $n --add-label triage; done
```

Watch rate limits in loops.

---

## Projects (v2)

Projects v2 requires GraphQL:

```bash
gh auth refresh -s project         # add project scope
gh project list --owner @me
gh project item-add <project-id> --owner @me --url <issue-url>
```

Classic Projects: `gh api` endpoints. Treat project boards as reference-level.

---

## Linking Issues to PRs

In PR body:
- `Fixes #123` → auto-closes on merge
- `Closes #123` → same
- `Refs #123` → links without closing

---

## Gotchas

| Pitfall | Fix |
|---------|-----|
| Labels dropped silently | Set after confirming push access |
| Long URLs in body | Use `--body-file` |
| Cross-repo automation | Use `--repo owner/repo` or `GH_REPO` |
| Milestones (no gh subcommand) | Use `gh api repos/.../milestones` |
| Security vulnerability | Private reporting, not public issue |
