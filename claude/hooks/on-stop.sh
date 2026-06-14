#!/usr/bin/env bash
# on-stop.sh — Unified Stop hook
# Replaces: arra-reindex-on-stop.sh, feed-hook.sh (Stop)
#
# 1. Auto DONE-ping: if a worktree session dies with open PRs, notify L1
# 2. Runs arra FTS reindex in background on session end

set -uo pipefail

export PATH="$HOME/.bun/bin:$HOME/.local/bin:$PATH"

# ─── AUTO DONE-PING (worktree crash safety net) ──────────────────
# If this session is in an agents/ worktree AND has work (commits or PRs),
# send a DONE-ping to the parent L1 oracle pane automatically.
# This catches the recurring failure (5+ occurrences 2026-06-06/07/08):
# A worktree pane finishes work, pushes, but dies or stops before maw hey DONE-ping.
CWD="$(pwd)"
GH_LOGIN="$(gh api user -q .login 2>/dev/null || echo "<your-github-user>")"
if [[ "$CWD" == */agents/* ]] && command -v maw >/dev/null 2>&1; then
  SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "")
  WINDOW=$(tmux display-message -p '#{window_name}' 2>/dev/null || echo "")
  if [ -n "$SESSION" ]; then
    ORACLE_PANE="${SESSION}:1.0"
    REPO=$(echo "$CWD" | grep -oP "${GH_LOGIN}/\K[^/]+(?=/agents)" || echo "unknown")
    BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    DONE_MARKER="$CWD/.maw/done-pinged"
    # Skip if the pane already sent a manual DONE-ping (marker file exists)
    if [ -f "$DONE_MARKER" ]; then
      exit 0
    fi
    if [ -n "$BRANCH" ]; then
      # Check for open PRs
      PR_NUMS=$(gh pr list --repo "${GH_LOGIN}/${REPO}" --head "$BRANCH" --state open --json number -q '.[].number' 2>/dev/null | tr '\n' ' ')
      # Check for commits ahead of main (catches direct-push infra work)
      COMMITS_AHEAD=$(git log origin/main..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
      # Check for recently pushed commits on main from this worktree
      PUSHED_TO_MAIN=$(git log origin/main --oneline -3 2>/dev/null | head -1)
      if [ -n "$PR_NUMS" ] || [ "${COMMITS_AHEAD:-0}" -gt 0 ]; then
        MSG="[AUTO-DONE] worktree session ended in ${WINDOW} (${REPO})."
        [ -n "$PR_NUMS" ] && MSG="$MSG Open PR(s): ${PR_NUMS}."
        [ "${COMMITS_AHEAD:-0}" -gt 0 ] && MSG="$MSG ${COMMITS_AHEAD} commit(s) ahead of main."
        MSG="$MSG Ready for /scrutinize + merge + maw done ${WINDOW}."
        maw hey "$ORACLE_PANE" "$MSG" 2>/dev/null &
      fi
    fi
  fi
fi

# ─── ARRA REINDEX ───────────────────────────────────────────────────
ARRA_DIR="$HOME/ghq/github.com/${GH_LOGIN}/arra-oracle-v3"
LOCK="/tmp/arra-reindex.lock"

# Reindex arra in background (non-blocking, ~10s)
if [ -d "$ARRA_DIR" ] && [ ! -f "$LOCK" ]; then
  (
    flock -n 9 || exit 0
    cd "$ARRA_DIR" || exit 1
    ORACLE_FORCE_REINDEX=1 bun run index > /tmp/arra-reindex-last.log 2>&1
  ) 9>"$LOCK" &
fi

exit 0
