# GitHub Actions & CI/CD

Workflow YAML authoring, debugging, security, and common CI/CD patterns.

---

## Debugging CI (most common agent task)

```bash
# List recent runs
gh run list --limit 10 --json databaseId,status,conclusion,workflowName,headBranch

# THE most useful debug command
gh run view <id> --log-failed

# See job outcomes
gh run view <id> --json jobs --jq '.jobs[] | {name, conclusion}'

# Watch live
gh run watch <id>

# Rerun failed jobs only
gh run rerun <id> --failed

# Download artifacts
gh run download <id> [-n artifactName]

# Workflows
gh workflow list
gh workflow run <name> -f key=value    # workflow_dispatch trigger
```

---

## Workflow YAML Anatomy

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 9 * * 1'    # UTC!
  workflow_dispatch:

permissions:
  contents: read            # least privilege

env:
  NODE_VERSION: '20'

jobs:
  test:
    runs-on: ubuntu-latest
    needs: lint             # dependency
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm ci
      - run: npm test
        env:
          API_KEY: ${{ secrets.API_KEY }}
```

---

## Triggers

| Trigger | When | Notes |
|---------|------|-------|
| `push` | Push to branches/tags | Filter with `branches:`, `tags:` |
| `pull_request` | PR opened/synchronize/reopened | Types: `opened`, `synchronize`, `reopened`, `closed` |
| `schedule` | Cron (UTC!) | Must be on default branch to register |
| `workflow_dispatch` | Manual trigger | Inputs: string/boolean/choice |
| `release` | Release published | For release automation |
| `workflow_call` | Reusable workflow | Called by other workflows |
| `merge_group` | Merge queue | Not `push` |

**`schedule` caveat**: workflow must exist on default branch to be registered. PRs adding workflows don't register schedulers.

---

## pull_request vs pull_request_target

| | `pull_request` | `pull_request_target` |
|---|---|---|
| Token | Read-only for fork PRs | **Write token + secrets** |
| Context | PR head code | Base repo code |
| Safe for fork PRs | Yes | **No — security footgun** |

**NEVER `pull_request_target` + `checkout` of PR head** — runs untrusted code with write access.

---

## Secrets & Variables

```bash
gh secret set NAME                  # repo secret
gh secret set --env prod NAME       # environment secret
gh variable set KEY --body "value"  # non-sensitive variables
```

- Secrets masked in logs, not passed to fork-PR workflows
- Prefer OIDC (`id-token: write` + `role-to-assume`) over long-lived cloud keys
- Environment secrets: protected by environment rules (required reviewers, wait timers)

---

## Matrix Builds

```yaml
jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
        node: [18, 20]
        include:
          - os: ubuntu-latest
            node: 20
            coverage: true
        exclude:
          - os: macos-latest
            node: 18
    runs-on: ${{ matrix.os }}
```

---

## Caching

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-
```

Or built-in: `setup-node`/`setup-python` with `cache:` parameter.

---

## Artifacts

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: test-results
    path: reports/
    retention-days: 30

- uses: actions/download-artifact@v4
  with:
    name: test-results
```

Cross-job: use artifacts (not workspace) unless `needs` same runner.

---

## Concurrency

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

---

## Job/Step Outputs

```yaml
- id: version
  run: echo "version=1.2.0" >> "$GITHUB_OUTPUT"

- run: echo "Using ${{ steps.version.outputs.version }}"
```

Also: `$GITHUB_ENV`, `$GITHUB_STATE`, `$GITHUB_PATH`.

---

## Release Automation

```yaml
on:
  release:
    types: [published]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - run: gh release create ${{ github.ref_name }} --generate-notes
```

---

## Security Rules

1. **Pin actions by SHA** with version comment: `uses: actions/checkout@a1b2c3d # v4.1.0`
2. **Least privilege**: `permissions: contents: read` at workflow level
3. **Never `pull_request_target` + PR-head checkout**
4. **Never `permissions: write-all`**
5. **No secrets in logs**: use secrets context, not echo
6. **Audit third-party actions**: prefer official `actions/*`

---

## Common Patterns

### Lint + Test + Build + Deploy

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps: [...]
  test:
    needs: lint
    runs-on: ubuntu-latest
    steps: [...]
  deploy:
    needs: [lint, test]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production
    steps: [...]
```

### Status Badge

```markdown
![CI](https://github.com/owner/repo/actions/workflows/ci.yml/badge.svg)
```

---

## Gotchas

| Pitfall | Fix |
|---------|-----|
| Schedule not firing | Workflow must be on default branch |
| UTC cron confusion | `schedule` is always UTC |
| Fork PR has no secrets | Design CI to not need secrets for PR validation |
| `on` parsed as boolean | Quote carefully in scripts writing YAML |
| `if:` expression syntax | Use bare `if: github.ref == ...` not `${{ }}` |
