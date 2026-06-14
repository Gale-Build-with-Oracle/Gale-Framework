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

# --- Code-ship verify nudge (non-blocking; Your Name 2026-06-05) ---
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
fi

# Only care about PR creation in worktrees
echo "$COMMAND" | grep -qE '(maw pr|gh pr create)' || exit 0
echo "$PWD" | grep -qE '\.wt-[0-9]+-' || exit 0

PR_URL=$(echo "$STDOUT" | grep -oE 'https://github\.com/[^[:space:]]+/pull/[0-9]+' | head -1)
[ -z "$PR_URL" ] && exit 0

PR_NUM=$(echo "$PR_URL" | grep -oE '[0-9]+$')
ORACLE_HOME=$(echo "$PWD" | grep -oE '[a-z]+-oracle' | head -1 || echo "my-oracle")

YLW='\033[1;33m'; RST='\033[0m'
echo -e "${YLW}⚠️ PR #${PR_NUM} created. Notify main session:${RST}" >&2
echo -e "${YLW}  maw hey <human>:${ORACLE_HOME} \"[wt] PR #${PR_NUM} ready. ${PR_URL}\"${RST}" >&2

exit 0
