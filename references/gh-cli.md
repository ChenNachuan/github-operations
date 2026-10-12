# gh CLI Reference

Authentication, API patterns, scripting, aliases, and extensions.

---

## Auth

```bash
gh auth status                   # check FIRST — exit 4 = auth needed
gh auth login                    # interactive
gh auth refresh -s project       # add scopes
gh auth switch                   # switch between accounts
```

**Exit codes**: 0 = success, 1 = failure, 2 = cancelled, 4 = needs auth.

Multi-account: `gh auth switch` after `gh auth login` for each account.

---

## Environment Variables

```bash
GH_REPO=owner/repo gh ...        # override implicit repo
GH_TOKEN=xxx                     # env-based auth (CI)
GH_PROMPT_DISABLED=1             # disable interactive prompts
GIT_TERMINAL_PROMPT=0            # disable git prompts
```

`-R/--repo [HOST/]OWNER/REPO` on nearly every command for cross-repo ops.

---

## Scripting Patterns

```bash
# JSON output + jq filtering
gh pr list --json number,state,title --jq '.[] | select(.state=="OPEN")'
gh issue list --json number,title,labels --jq '.[].number'
gh run list --json databaseId,conclusion --jq '.[] | select(.conclusion=="failure")'

# Template output
gh pr list --template '{{range .}}{{.number}}: {{.title}}{{"\n"}}{{end}}'

# Pagination
gh api repos/owner/repo/issues --paginate

# REST API
gh api repos/owner/repo --jq '.default_branch'
gh api repos/owner/repo/issues --method POST -f title="..." -f body=@file.txt

# GraphQL
gh api graphql -f query='
  query($owner: String!, $repo: String!) {
    repository(owner: $owner, name: $repo) {
      pullRequests(first: 10, states: OPEN) {
        nodes { number title }
      }
    }
  }
' -f owner=owner -f repo=repo

# Search
gh search issues "bug in:title" --repo owner/repo --json number,title
gh search prs "is:open is:approved" --json number,title
```

**Field flags**: `-f` raw string, `-F` magic typing (`-F n=5` → number, `-F key=@file` → file contents).

**Placeholders**: `{owner}`, `{repo}`, `{branch}` auto-fill from cwd repo.

---

## Common Command Map

### PRs
```bash
gh pr create [--title] [--body] [--body-file] [--draft] [--base] [--reviewer] [--label]
gh pr list [--state] [--author] [--label] [--json] [--jq]
gh pr view <number> [--json] [--web]
gh pr checks <number>
gh pr diff <number>
gh pr review <number> [--approve|--request-changes|--comment] [--body]
gh pr comment <number> [--body|--body-file]
gh pr merge <number> [--squash|--merge|--rebase] [--delete-branch] [--auto]
gh pr ready <number>
gh pr update-branch <number>
gh pr close <number> / gh pr reopen <number>
```

### Issues
```bash
gh issue create [--title] [--body|--body-file] [--label] [--assignee] [--milestone]
gh issue list [--state] [--label] [--search] [--json] [--jq]
gh issue view <number> [--web]
gh issue comment <number> [--body|--body-file]
gh issue edit <number> [--add-label] [--add-assignee] [--milestone]
gh issue close <number> [--reason completed|not_planned]
gh issue reopen <number>
gh issue develop <number>
```

### Runs & Workflows
```bash
gh run list [--limit] [--workflow] [--branch] [--json]
gh run view <id> [--log-failed] [--json]
gh run watch <id>
gh run rerun <id> [--failed]
gh run download <id> [-n name]
gh workflow list
gh workflow run <name> [-f key=value]
```

### Repos
```bash
gh repo create [name] [--public|--private] [--add-readme] [--clone]
gh repo clone <owner/repo> [dir]
gh repo fork <owner/repo> [--clone]
gh repo view [--json] [--web]
gh repo edit [--description] [--add-topic] [--visibility]
gh repo rename <new-name>
gh repo sync [branch]
gh repo set-default <owner/repo>
gh repo transfer <owner/repo>
gh repo archive <owner/repo>
gh repo deploy-key list|add|delete
```

### API
```bash
gh api <endpoint> [--method] [-f] [-F] [--jq] [--paginate]
gh api graphql -f query='...' [-f var=value]
gh search issues|prs|repos|code "query" [--json]
```

---

## Aliases

```bash
gh alias set pv 'pr view --web'
gh alias set logs 'run view --log-failed'
gh alias set mine 'pr list --author @me'
gh alias set status 'status'
```

---

## Extensions

```bash
gh extension install owner/gh-extension
gh extension list
```

---

## Rate Limits

```bash
gh api /rate_limit
```

Backoff in loops. Secondary limits on abuse.

---

## Other Useful Commands

```bash
gh status                          # cross-repo dashboard
gh config set -h github.com git_protocol ssh
gh cache list / gh cache delete <keys>
gh release create <tag> --generate-notes
gh label list / gh label create <name> --color <color>
```

---

## Gotchas

| Pitfall | Fix |
|---------|-----|
| Implicit repo resolution | `gh repo view --json nameWithOwner` first |
| Interactive prompts in automation | `GH_PROMPT_DISABLED=1` + pass all flags |
| `--json` field names vary | `gh pr view --json` (no arg) lists fields |
| GraphQL needed for Projects v2 | REST is fine for most ops |
| Token in command output | Never echo tokens; use `gh auth` |
