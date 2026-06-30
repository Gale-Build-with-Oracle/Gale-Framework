#!/usr/bin/env bash
# post-tool.sh — Unified PostToolUse hook
# Replaces: wt-pr-notify.sh, feed-hook.sh (PostToolUse)
#
# Advisory PR notification after maw pr / gh pr create in worktrees

# Claude Code injects ugrep as grep — breaks regex patterns with --flag-like strings
unset -f grep 2>/dev/null

set -uo pipefail

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
STDOUT=$(printf '%s' "$INPUT" | jq -r '.tool_output.stdout // ""' 2>/dev/null)

# --- Code-ship verify nudge (non-blocking; Wind 2026-06-05) ---
# Root pattern: "committed/merged CODE without running the changed function" hit
# 4 of 7 recent sessions (rrr metrics error column). On a code-ship command,
# remind to show the changed function actually RAN. Fires ONLY when real code
# files (not ψ/docs/md) are in the shipped commit — so it never nags on /rrr or
# doc commits (that noise is exactly what got the old blocking verify-gate killed
# 2026-06-01). Pure stderr advisory: never blocks, fail-safe to silence.
if echo "$COMMAND" | grep -qE '(^|;|&&|\|\|)[[:space:]]*(git[[:space:]]+(commit|push)|maw[[:space:]]+pr)\b'; then
  ship_dir=$(echo "$COMMAND" | grep -oE 'git[[:space:]]+-C[[:space:]]+[^[:space:]]+' | head -1 | awk '{print $3}')
  [ -z "$ship_dir" ] && ship_dir=$(echo "$COMMAND" | grep -oE '(^|&&|;)[[:space:]]*cd[[:space:]]+[^;&|]+' | head -1 | sed -E 's/.*cd[[:space:]]+//' | tr -d "\"'" | xargs 2>/dev/null)
  [ -z "$ship_dir" ] && ship_dir="$PWD"
  ship_dir="${ship_dir/#\~/$HOME}"
  code_files=$(git -C "$ship_dir" diff-tree --no-commit-id --name-only -r -m HEAD 2>/dev/null \
    | grep -ivE '(^|/)(docs|\.claude)/|/ψ/|\.(md|txt)$|FORK_PATCHES' \
    | grep -iE '\.(ts|tsx|js|jsx|mjs|cjs|rs|py|go|sql|sh|rb|java|c|cpp|h|hpp|vue|svelte)$' | head -3)
  if [ -n "$code_files" ]; then
    YLW='\033[1;33m'; RST='\033[0m'
    echo -e "${YLW}🔬 Code shipped. Before declaring done: name the ONE function/line this change exists to make work, and show it EXECUTING (a real run/test of THAT function — not a stub, proxy, or symptom). 'shipped-without-running-the-changed-function' hit 4 of 7 recent sessions.${RST}" >&2
  fi
  # Spec-update nudge: if specs/ exists in the project, remind to keep spec current
  if [ -d "specs" ] && ls specs/*.md >/dev/null 2>&1; then
    DIM='\033[2m'; RST='\033[0m'
    echo -e "${DIM}💡 specs/ exists — if your implementation diverged from the spec, update specs/<N>.md first.${RST}" >&2
  fi
fi

# --- Post-merge branch sweep (sop-debug Phase 7: stale agent branches) ---
# After gh pr merge, sweep stale remote agent branches + fetch --prune.
# Root cause: maw done only cleans ONE branch; delete_branch_on_merge may
# be off or gh merge may not use --delete-branch. This catches leftovers.
if echo "$COMMAND" | grep -qE 'gh[[:space:]]+pr[[:space:]]+merge'; then
  sweep_repo=$(echo "$COMMAND" | grep -oE '\-\-repo[[:space:]]+[^[:space:]]+' | head -1 | awk '{print $2}')
  if [ -z "$sweep_repo" ]; then
    sweep_repo=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || true)
  fi
  if [ -n "$sweep_repo" ]; then
    repo_name=$(echo "$sweep_repo" | sed 's|.*/||')
    repo_path="$HOME/ghq/github.com/$sweep_repo"
    if [ -d "$repo_path" ]; then
      (
        git -C "$repo_path" fetch --prune 2>/dev/null
        for br in $(git -C "$repo_path" branch -r --list 'origin/agents/*' --list 'origin/fix/*' --format='%(refname:short)' 2>/dev/null); do
          short="${br#origin/}"
          merged=$(gh pr list --repo "$sweep_repo" --head "$short" --state merged --json number --limit 1 -q '.[0].number' 2>/dev/null)
          if [ -n "$merged" ]; then
            git -C "$repo_path" push origin --delete "$short" 2>/dev/null
            git -C "$repo_path" branch -D "$short" 2>/dev/null
          fi
        done
        git -C "$repo_path" fetch --prune 2>/dev/null
      ) &
    fi
  fi
fi

# Only care about PR creation in worktrees
if ! echo "$COMMAND" | grep -qE '(maw pr|gh pr create)'; then exit 0; fi
if ! echo "$PWD" | grep -qE '(/agents/[^/]+|\.wt-[0-9]+-)'; then exit 0; fi

PR_URL=$(echo "$STDOUT" | grep -oE 'https://github\.com/[^[:space:]]+/pull/[0-9]+' | head -1)
[ -z "$PR_URL" ] && exit 0

PR_NUM=$(echo "$PR_URL" | grep -oE '[0-9]+$')
REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")
BRANCH=$(git branch --show-current 2>/dev/null || echo "")

YLW='\033[1;33m'; GRN='\033[1;32m'; RST='\033[0m'

# Auto-send DONE-ping to L1 oracle pane (SESSION:1.0 = L1 pane, same as on-stop.sh)
SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "")
WINDOW=$(tmux display-message -p '#{window_name}' 2>/dev/null || echo "")

if [ -n "$SESSION" ]; then
  ORACLE_PANE="${SESSION}:1.0"
  MSG="[AUTO-PR-DONE] PR #${PR_NUM} opened in ${WINDOW} (${REPO}). ${PR_URL}. L2 /rrr status: check before maw done. Ready for /sop-review + live proof + merge + issue close + maw done ${WINDOW}."
  maw hey "$ORACLE_PANE" "$MSG" 2>/dev/null &

  mkdir -p .maw && touch .maw/done-pinged

  # Enqueue to PR queue so maw fleet pr-queue catches it
  QUEUE_DIR="${MAW_STATE_DIR:-${MAW_HOME:-$HOME/.maw}}"
  mkdir -p "$QUEUE_DIR"
  python3 - "$QUEUE_DIR/pr-queue.jsonl" "$SESSION" "$REPO" "$BRANCH" "$PR_NUM" <<'PY' 2>/dev/null || true
import json, sys, time
path, session, repo, branch, pr = sys.argv[1:]
with open(path, "a", encoding="utf-8") as f:
    f.write(json.dumps({"ts": int(time.time()*1000), "from": session, "repo": repo, "prNumbers": [int(pr)], "branch": branch, "status": "pending"}) + "\n")
PY

  echo -e "${GRN}✓ AUTO DONE-ping sent to L1 (${ORACLE_PANE}). PR #${PR_NUM} queued for /sop-review.${RST}" >&2
else
  ORACLE_HOME=$(echo "$PWD" | grep -oE '[a-z]+-oracle' | head -1 || echo "leaf")
  echo -e "${YLW}⚠️ PR #${PR_NUM} created. Notify main session:${RST}" >&2
  echo -e "${YLW}  maw hey wind:${ORACLE_HOME} \"DONE: PR #${PR_NUM} ready. ${PR_URL}\"${RST}" >&2
fi

exit 0
