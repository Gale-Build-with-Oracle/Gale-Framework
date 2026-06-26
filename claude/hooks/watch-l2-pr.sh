#!/usr/bin/env bash
# watch-l2-pr.sh — Background monitor for L2 worktree PR creation.
# Run with `run_in_background: true` after every maw workon dispatch.
# Exits (notifying L1) when the PR appears on the dispatched branch.
#
# Usage: bash ~/.claude/hooks/watch-l2-pr.sh <owner/repo> <branch>
# Example: bash ~/.claude/hooks/watch-l2-pr.sh deachawatss/NWFTH-NPD-Forms agents/2-fix-ui-readability

REPO="$1"
BRANCH="$2"

if [ -z "$REPO" ] || [ -z "$BRANCH" ]; then
  echo "Usage: watch-l2-pr.sh <owner/repo> <branch>"
  exit 1
fi

MAX_WAIT=1800
POLL=45
elapsed=0

while [ $elapsed -lt $MAX_WAIT ]; do
  PR=$(gh pr list --repo "$REPO" --head "$BRANCH" --json number,title --jq '.[0]' 2>/dev/null)
  if [ -n "$PR" ] && [ "$PR" != "null" ]; then
    NUM=$(echo "$PR" | python3 -c "import sys,json; print(json.load(sys.stdin)['number'])")
    TITLE=$(echo "$PR" | python3 -c "import sys,json; print(json.load(sys.stdin)['title'])")
    echo "L2 PR READY: #${NUM} — ${TITLE} (${REPO}:${BRANCH}). Scrutinize and merge NOW."
    exit 0
  fi
  sleep $POLL
  elapsed=$((elapsed + POLL))
done

echo "Timeout: no PR on ${REPO}:${BRANCH} after 30m. Check L2 with maw capture."
exit 1
