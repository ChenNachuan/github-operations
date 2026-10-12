#!/usr/bin/env bash
# pr_body_gen.sh — Generate PR body from conventional commits
# Usage: ./pr_body_gen.sh [base-branch] [head-branch]
# Defaults: base=main (or repo default), head=current branch

set -euo pipefail

BASE="${1:-}"
HEAD="${2:-$(git branch --show-current)}"

# Detect default branch if not specified
if [[ -z "$BASE" ]]; then
  BASE=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
fi

echo "Generating PR body: $BASE...$HEAD"
echo ""

# Get commit messages
COMMITS=$(git log --oneline "$BASE..$HEAD" --no-merges)

if [[ -z "$COMMITS" ]]; then
  echo "ERROR: No commits between $BASE and $HEAD"
  exit 1
fi

# Categorize commits
FEATURES=$(echo "$COMMITS" | grep -E "^\w+ (feat|feature)" || true)
FIXES=$(echo "$COMMITS" | grep -E "^\w+ (fix|bugfix)" || true)
CHORES=$(echo "$COMMITS" | grep -E "^\w+ (chore|refactor|docs|style|test|ci|build)" || true)
OTHER=$(echo "$COMMITS" | grep -vE "^\w+ (feat|feature|fix|bugfix|chore|refactor|docs|style|test|ci|build)" || true)

# Count
TOTAL=$(echo "$COMMITS" | wc -l | tr -d ' ')
DIFF_STAT=$(git diff --stat "$BASE..$HEAD" | tail -1)

cat <<EOF
## Summary

<!-- Describe what changed and why -->

## Changes

EOF

if [[ -n "$FEATURES" ]]; then
  echo "### ✨ Features"
  echo "$FEATURES" | sed 's/^/- /'
  echo ""
fi

if [[ -n "$FIXES" ]]; then
  echo "### 🐛 Fixes"
  echo "$FIXES" | sed 's/^/- /'
  echo ""
fi

if [[ -n "$CHORES" ]]; then
  echo "### 🔧 Chores"
  echo "$CHORES" | sed 's/^/- /'
  echo ""
fi

if [[ -n "$OTHER" ]]; then
  echo "### 📝 Other"
  echo "$OTHER" | sed 's/^/- /'
  echo ""
fi

cat <<EOF
## Stats

- $TOTAL commits
- $DIFF_STAT

## Test Plan

- [ ] Tests pass
- [ ] No breaking changes
- [ ] Documentation updated (if needed)
EOF
