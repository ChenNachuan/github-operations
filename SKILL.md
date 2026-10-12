---
name: github
description: >-
  GitHub and git operations skill. Use when the user wants to clone, push, pull,
  fork, or manage git branches; create, review, comment on, or merge pull
  requests; create, label, assign, or close GitHub issues; write, debug, or
  configure GitHub Actions workflows and CI/CD; manage repo settings, rename,
  transfer, or change visibility; use gh CLI commands or GitHub API; or
  troubleshoot CI failures and merge conflicts. Does NOT handle code review
  judgment, GitLab/Bitbucket operations, GitHub Enterprise admin, or general
  programming tasks.
metadata:
  uskill.icon: "🐙"
  uskill.category: developer
  uskill.display_name: GitHub Operations
  uskill.display_desc: Git, PRs, issues, Actions, and repo management
---

# GitHub Operations

## Hard rules

1. **No force-push to shared branches**: only `--force-with-lease`, after user confirmation. Never `--force` on `main`/`master`.
2. **Never commit secrets**: check diffs before push; never print tokens in output.
3. **Confirm before irreversible**: force-push, `reset --hard`, repo delete, visibility change, bulk close — state exactly what will happen.
4. **Rule zero — match existing conventions first**: read `git log`, templates, CODEOWNERS before applying defaults.
5. **Diagnose before configure**: inspect state before changing settings.
6. **Propose don't execute on shared remotes**: show the command, wait for approval.
7. **CI truth discipline**: never claim "tests pass" without evidence (`gh pr checks` output).
8. **Never `pull_request_target` + PR-head checkout** — security footgun.
9. **One request, one action**: don't push extra branches or open extra PRs.
10. **Conflicts go to the user**: surface conflicts, don't auto-resolve ambiguous ones.
11. **Never blind `git pull`**: use `git pull --ff-only`, escalate to `--rebase` explicitly.
12. **Verify repo identity**: `gh repo view --json nameWithOwner` before any remote write.

## When to use / When NOT

**Use**: git clone/push/pull/fork · branch management · merge/rebase · PR create/review/merge · issues · GitHub Actions · CI/CD debugging · repo settings · gh CLI.

**NOT**: code review judgment · GitLab/Bitbucket · GitHub Enterprise admin · general programming · teaching git theory.

## Workflow router

| Intent | Load reference |
|--------|---------------|
| git commands (clone/push/branch/merge/rebase) | `references/git-operations.md` |
| PR create/review/comment/merge | `references/pr-workflow.md` |
| Issues create/label/close | `references/issues-projects.md` |
| GitHub Actions / CI / workflow YAML | `references/actions-cicd.md` |
| Repo settings/protection/collaborators | `references/repo-admin.md` |
| gh CLI auth/API/scripting | `references/gh-cli.md` |

## Top commands

```bash
# Orientation — always first
gh auth status
gh repo view --json nameWithOwner,defaultBranchRef
git status -sb

# Git daily
git pull --ff-only
git push -u origin HEAD
git switch -c feat/<name>

# PRs
gh pr create --title "..." --body-file pr.md
gh pr checks <number>
gh pr merge <number> --squash --delete-branch

# Issues
gh issue create --title "..." --body-file issue.md
gh issue close <number> --reason completed

# CI debugging
gh run list --limit 5
gh run view <id> --log-failed

# Repo
gh repo view --json name,description,visibility
gh repo rename <new-name>
```

## Gotchas

| Pitfall | Fix |
|---------|-----|
| Wrong repo (implicit cwd resolution) | `gh repo view --json nameWithOwner` first |
| `gh pr create` hangs on prompts | Always pass `--title`/`--body` or `--body-file` |
| Labels silently dropped (non-collaborators) | Set labels after push access confirmed |
| Fork PR has no secrets | Design CI to not need secrets for PR validation |
| Default branch not `main` | Discover: `gh repo view --json defaultBranchRef` |
| URL too long in body | Use `--body-file` not `--body` with long URLs |
| UTC cron confusion | `schedule` is always UTC |
| Interactive prompts break automation | Set `GH_PROMPT_DISABLED=1` in scripts |

## Merge strategy

| Strategy | When |
|----------|------|
| `--squash` (default) | Small PRs, keep main linear |
| `--merge` | Preserve branch topology |
| `--rebase` | Linear history + per-commit granularity |
| `cherry-pick` | Port specific commits (hotfix) |

Repo settings may restrict strategies — check `gh pr view --json mergeStateStatus`.

## Verification gate

Before claiming any GitHub operation is complete:

1. **PR**: `gh pr checks <number>` — all green
2. **Merge**: `gh pr view <number> --json state,mergeStateStatus`
3. **CI**: `gh run view <id>` — conclusion is `success`
4. **Issue**: `gh issue view <number>` — state matches intent

## Tools & templates

| File | Purpose |
|------|---------|
| `scripts/check_ci.sh` | PR CI status + mergeStateStatus verdict |
| `scripts/pr_body_gen.sh` | Generate PR body from conventional commits |
| `assets/pr-template.md` | PR body skeleton |
| `assets/workflow-ci.yml` | CI workflow template (lint/test/build) |

## Reference files

| File | Load when |
|------|-----------|
| `references/git-operations.md` | git commands, branch management, merge/rebase mechanics, recovery (reflog/reset) |
| `references/pr-workflow.md` | PR create/review/comment/merge, inline comments, fork PRs, templates |
| `references/issues-projects.md` | Issue lifecycle, labels, milestones, templates, Projects |
| `references/actions-cicd.md` | Workflow YAML, triggers, secrets, matrix, caching, release automation |
| `references/repo-admin.md` | Repo settings, branch protection, collaborators, webhooks, rename/transfer |
| `references/gh-cli.md` | gh auth, API patterns, scripting, aliases, extensions, rate limits |
