# github-operations

> A Claude Code skill for git, GitHub PRs, issues, Actions/CI-CD, and repo management.

**Install**: `ln -s /path/to/github ~/.claude/skills/github` · **Language**: English

---

## What Is This

github-operations is a Claude Code skill that helps agents perform GitHub and git operations correctly and safely. It covers the full operational surface: cloning repos, managing branches, creating and reviewing pull requests, filing issues, debugging CI, writing GitHub Actions workflows, and managing repo settings.

Unlike command cheat-sheets, this skill combines **when/why** (policy) with **how** (commands) and **what not to do** (safety rules). It is designed to be loaded when a user asks for any GitHub operation, then route to the right deep reference.

---

## Design Principles

| Principle | Meaning |
|-----------|---------|
| **Rule zero** | Match existing conventions first — read `git log`, templates, CODEOWNERS before imposing defaults |
| **CI truth discipline** | Never claim "tests pass" without evidence |
| **Propose, don't execute** | On shared remotes, show the command and wait |
| **Verify before claiming done** | `gh pr checks` / `gh run view` output is required |
| **One request, one action** | Don't push extra branches or open extra PRs |

---

## Coverage

### Git Operations
- Clone, fetch, pull (`--ff-only` default), push (`-u origin HEAD`)
- Fork + upstream remote workflow
- Branch lifecycle (create/switch/delete)
- Merge vs rebase **mechanics** (not just policy)
- Conflict resolution (surface to user, never auto-resolve ambiguous)
- Stash, cherry-pick, tags, submodules
- Recovery: `git reflog`, `reset --soft/mixed/hard`, `revert`, decision tree

### Pull Requests
- Create with explicit content (avoid interactive prompts)
- PR body quality: truthful, evidence-backed, template-driven
- Review flow: approve, request changes, comment
- **Inline comments** via API (line number resolution trick)
- Fork PR handling (cross-org workaround)
- Merge strategies: squash (default) / merge / rebase
- Draft vs Ready, auto-merge, update-branch

### Issues
- Full lifecycle: create → label → assign → close/reopen
- Classification table (bug / regression / feature / env / **security**)
- Labels, milestones, templates
- Security issues → **private vulnerability reporting, never public**
- `Fixes #N` / `Closes #N` / `Refs #N` linking

### GitHub Actions / CI-CD
- **CI debugging** (most common task): `gh run view --log-failed`
- Workflow YAML anatomy (triggers, jobs, steps, needs)
- `pull_request` vs `pull_request_target` (security footgun)
- Secrets, environments, matrix builds, caching, artifacts
- Concurrency groups, job outputs
- Release automation
- Security rules: SHA pinning, least privilege, never `pull_request_target` + PR-head checkout

### Repo Management
- Settings, description, topics
- Visibility (public/private — confirm before change)
- Rename (`gh repo rename` + remote URL update)
- Branch protection / rulesets
- Collaborators (permission levels)
- Webhooks, deploy keys
- Fork sync, transfer, archive
- `.github` conventions (CODEOWNERS, templates, SECURITY.md)

### gh CLI
- Auth: `gh auth status` first, multi-account switching
- Exit codes: 0/1/2/**4** (needs auth)
- Scripting: `--json` + `--jq` + `--template` + `--paginate`
- REST + GraphQL patterns
- Aliases, extensions, rate limits

---

## Quick Start

### Install

```bash
ln -s /path/to/github-operations ~/.claude/skills/github
```

### Use

In a Claude Code session, say any of:

| Intent | Example |
|--------|---------|
| Git | "Push this branch and create a PR" |
| PR | "Create a PR from my current branch" |
| CI | "Why is CI failing on my PR?" |
| Issues | "File a bug for the login crash" |
| Actions | "Set up GitHub Actions for this project" |
| Repo | "Rename this repo to my-new-project" |
| Review | "Review PR #42 and leave comments" |

---

## Architecture

```
github/
├── SKILL.md                    # Thin routing body (~135 lines)
├── references/                 # Deep-dive guides (on-demand loading)
│   ├── git-operations.md       # Git commands + recovery (214 lines)
│   ├── pr-workflow.md          # PR full lifecycle (177 lines)
│   ├── issues-projects.md      # Issue management (180 lines)
│   ├── actions-cicd.md         # Workflow YAML + debug (260 lines)
│   ├── repo-admin.md           # Settings + protection (168 lines)
│   └── gh-cli.md               # gh auth/API/scripting (189 lines)
├── assets/                     # Templates
│   ├── pr-template.md          # PR body skeleton
│   └── workflow-ci.yml         # CI workflow template
└── scripts/                    # Deterministic tools
    ├── check_ci.sh             # PR CI status + merge verdict
    └── pr_body_gen.sh          # Generate PR body from commits
```

**Layering** (per skill-creator methodology):
- **Body** (SKILL.md): hard rules, workflow router, top commands, gotchas — what the model must NOT forget
- **References**: full command matrices, YAML anatomy, recovery trees, API patterns
- **Scripts**: deterministic operations (CI check, body generation) — testable, repeatable
- **Assets**: templates to copy and fill

---

## Key Recipes

### Create a PR (correct)

```bash
git push -u origin HEAD
gh pr create \
  --title "feat: add user auth" \
  --body-file pr-body.md \
  --base main \
  --reviewer @user1 \
  --label feature
gh pr checks <number>    # ALWAYS verify before claiming ready
```

### Debug CI

```bash
gh run list --limit 5
gh run view <id> --log-failed    # THE most useful command
gh pr checks <number>
```

### Merge with verification

```bash
gh pr checks <number>                          # all green?
gh pr view <number> --json mergeStateStatus    # CLEAN?
gh pr merge <number> --squash --delete-branch
```

### Safe git operations

```bash
git pull --ff-only          # never blind `git pull`
git push --force-with-lease # ONLY with confirmation
git rebase origin/main      # NEVER rebase shared remote
```

---

## Hard Rules

1. **No force-push to shared branches** — only `--force-with-lease`, after confirmation
2. **Never commit secrets** — check diffs before push
3. **Confirm before irreversible** — force-push, `reset --hard`, repo delete, visibility change
4. **Rule zero** — read `git log`, templates, CODEOWNERS first
5. **CI truth discipline** — never claim "tests pass" without evidence
6. **Never `pull_request_target` + PR-head checkout** — security footgun
7. **Verify repo identity** — `gh repo view --json nameWithOwner` before any remote write
8. **Conflicts go to the user** — surface, don't auto-resolve
9. **Never blind `git pull`** — use `--ff-only`
10. **One request, one action** — no extra pushes/PRs

---

## Scripts

### `check_ci.sh`

Wraps PR CI status + mergeStateStatus into a clear verdict:

```bash
./check_ci.sh [pr-number]
# Output: CLEAN / BLOCKED / BEHIND / DIRTY / UNSTABLE + explanation
```

### `pr_body_gen.sh`

Generates a PR body from conventional commits:

```bash
./pr_body_gen.sh [base-branch] [head-branch]
# Output: categorized changes (features/fixes/chores) + stats + test plan
```

---

## Gotchas

| Pitfall | Fix |
|---------|-----|
| Wrong repo (implicit cwd resolution) | `gh repo view --json nameWithOwner` first |
| `gh pr create` hangs on prompts | Always pass `--title`/`--body` or `--body-file` |
| Labels silently dropped (non-collaborators) | Set after push access confirmed |
| Fork PR has no secrets | Design CI without secrets for PR validation |
| Default branch not `main` | Discover via `gh repo view --json defaultBranchRef` |
| Long URLs in body | Use `--body-file` not `--body` |
| UTC cron confusion | `schedule` is always UTC |
| Interactive prompts in automation | `GH_PROMPT_DISABLED=1` |

---

## Sources & Inspiration

This skill synthesizes best practices from:

| Source | Key ideas borrowed |
|--------|-------------------|
| `ccwriter369-beep/claude-skill-github-best-practices` | Rule zero, anti-pattern lists, merge strategy table |
| `jMerta/codex-skills` (create-pr) | PR body truthfulness, evidence attachment, `--body-file` |
| `faceleg/claude-skill-git` | Atomic commit tests, approval rule, pre-flight checklist |
| `Faithfinder/claude-skill-github-pr-inline-comments` | Inline comment API (line number resolution) |
| `steeef/claude-skill-github-actions` | Multi-account gh auth, CI debugging |
| `TerminalSkills/skills` | Frontmatter schema, triage classification |
| `obra/superpowers` | Merge-verify-then-cleanup, confirmation patterns |
| `nanostack` | Report-only mode on shared remotes |

---

## License

MIT
