# Repo Administration

Settings, protection, collaborators, webhooks, rename/transfer, and `.github` conventions.

---

## Repo Info & Settings

```bash
gh repo view --json name,description,defaultBranchRef,visibility,url,topics
gh repo edit --description "New description" --add-topic api --delete-topic old
gh repo edit --enable-issues --enable-wiki --enable-projects
```

---

## Visibility

```bash
gh repo edit --visibility public
gh repo edit --visibility private
```

**Private → public is a data-exposure event.** Never without explicit user confirmation. State what will become public.

---

## Rename

```bash
gh repo rename new-name
# Old URL redirects automatically — update remote URL after
git remote set-url origin git@github.com:owner/new-name.git
```

---

## Transfer

```bash
gh repo transfer owner/new-name
# Destructive: breaks clone URLs, CI secrets need migration
# Always confirm with user
```

---

## Archive

```bash
gh repo archive owner/repo --yes
```

Makes repo read-only. High impact — confirm first.

---

## Default Branch

```bash
gh api repos/owner/repo -X PATCH -f default_branch=new-branch
```

---

## Branch Protection

```bash
# Read protection state
gh api repos/owner/repo/branches/main/protection

# Rulesets (modern alternative)
gh ruleset list
gh ruleset view <id>
```

Common protections:
- Required reviews (≥1 approval)
- Required status checks
- Linear history
- Force-push block
- Branch deletion block
- Require signed commits

`gh ruleset` is view-only — changes go through `gh api` or UI.

---

## Collaborators

```bash
gh api repos/owner/repo/collaborators
gh api repos/owner/repo/collaborators/username -X PUT -f permission=push
```

Roles: `read` < `triage` < `write` < `maintain` < `admin`

Outside collaborators vs teams — teams get access via org membership.

---

## Webhooks

```bash
gh api repos/owner/repo/hooks
gh api repos/owner/repo/hooks -X POST -f config[url]="https://..." -f events[]="push"
```

Signing secret handling: store in environment, verify payload signature.

---

## Deploy Keys

```bash
gh repo deploy-key list
gh repo deploy-key add key.pub --title "CI Deploy Key"
```

---

## .github Conventions

| File | Purpose |
|------|---------|
| `PULL_REQUEST_TEMPLATE.md` | PR body template |
| `ISSUE_TEMPLATE/` | Issue templates (md or YAML forms) |
| `CODEOWNERS` | Auto-assign reviewers |
| `SECURITY.md` | Security policy + private reporting |
| `dependabot.yml` | Dependency updates |
| `FUNDING.yml` | Sponsor links |
| `CONTRIBUTING.md` | Contribution guidelines |
| `workflows/` | GitHub Actions |

### Repo bootstrap checklist

- [ ] `README.md` — what, why, how to use
- [ ] `LICENSE` — legal clarity
- [ ] `CODEOWNERS` — review assignment
- [ ] `SECURITY.md` — vulnerability reporting
- [ ] `.gitignore` — exclude artifacts
- [ ] Branch protection on default branch
- [ ] CI workflow running

---

## Fork Workflows

```bash
gh repo fork owner/repo --clone
gh repo set-head origin/main        # set default branch
gh repo sync                        # sync fork with upstream

# PR from fork
gh pr create --repo upstream/repo --head fork-owner:branch-name
```

---

## Gotchas

| Pitfall | Fix |
|---------|-----|
| Visibility change is data exposure | Confirm with user first |
| Rename breaks remote URL | `git remote set-url` after rename |
| Transfer breaks clone URLs | Notify user, update all clones |
| Protection is read-only in gh | Use `gh api` for changes |
| `gh ruleset` is view-only | Changes via `gh api` or UI |
