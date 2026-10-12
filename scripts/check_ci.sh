#!/usr/bin/env bash
# check_ci.sh — PR CI status + mergeStateStatus wrapper
# Usage: ./check_ci.sh [pr-number]
# If no PR number given, checks the current branch's PR.

set -euo pipefail

PR_NUM="${1:-}"

# If no PR number, find one for current branch
if [[ -z "$PR_NUM" ]]; then
  BRANCH=$(git branch --show-current)
  PR_NUM=$(gh pr list --head "$BRANCH" --json number --jq '.[0].number // empty')
  if [[ -z "$PR_NUM" ]]; then
    echo "ERROR: No PR found for branch '$BRANCH'. Pass PR number as argument."
    exit 1
  fi
fi

echo "=== PR #$PR_NUM ==="
gh pr view "$PR_NUM" --json title,state,mergeable,mergeStateStatus,url \
  --jq '"Title: \(.title)\nState: \(.state)\nMergeable: \(.mergeable)\nMerge state: \(.mergeStateStatus)\nURL: \(.url)"'

echo ""
echo "=== CI Checks ==="
gh pr checks "$PR_NUM"

echo ""
echo "=== Verdict ==="
MERGE_STATE=$(gh pr view "$PR_NUM" --json mergeStateStatus --jq '.mergeStateStatus')
case "$MERGE_STATE" in
  CLEAN)
    echo "✅ CLEAN — ready to merge"
    ;;
  BLOCKED)
    echo "❌ BLOCKED — required checks or reviews missing"
    ;;
  BEHIND)
    echo "⚠️  BEHIND — branch needs update (gh pr update-branch)"
    ;;
  DIRTY)
    echo "❌ DIRTY — merge conflict"
    ;;
  UNSTABLE)
    echo "⚠️  UNSTABLE — some checks failed (non-blocking)"
    ;;
  *)
    echo "❓ UNKNOWN — check manually"
    ;;
esac

exit 0
