#!/usr/bin/env bash
# sync-skills-to-codex.sh — Symlink Claude skills to Codex (minus the DENY set)
# Run: bash ~/.claude/scripts/sync-skills-to-codex.sh
# Safe to run repeatedly — creates missing symlinks AND prunes denied ones.
#
# Why DENY exists: Codex caps skill descriptions at a hardcoded 2% of the model
# context window (~5.4K tokens on gpt-5.5/272K). Once you have enough skills to
# overflow it, Codex truncates descriptions. The 2% is not configurable
# (openai/codex#19679), so the only fix is fewer loaded skills. Codex workers
# are coding hands — they never invoke Oracle-life/orchestration skills. We
# drop those (aligned with the arra 'standard' profile) to free the budget.
# ALL engineering, SOP, DB, review, and design skills are kept.

set -uo pipefail

CLAUDE_SKILLS="$HOME/.claude/skills"
# Resolve to the real path (CLAUDE_SKILLS is itself a symlink → your framework repo)
# so codex skill links point DIRECTLY at the source, not double-hopping through ~/.claude.
CLAUDE_SKILLS_REAL="$(readlink -f "$CLAUDE_SKILLS")"
CODEX_SKILLS="$HOME/.codex/skills"

# Forward-filter: skills a Codex coding worker never needs.
# addy = reference library (sub-skills); quality patterns are already absorbed
# into sop-frontend/sop-backend/sop-qa/sop-review/sop-cmmi — loading the raw
# reference would eat the 2% context budget for zero benefit.
DENY=(addy matt .retired)
is_denied() { local n="$1"; for d in "${DENY[@]}"; do [ "$d" = "$n" ] && return 0; done; return 1; }

[ -d "$CLAUDE_SKILLS" ] || { echo "No Claude skills dir"; exit 1; }
mkdir -p "$CODEX_SKILLS"

ADDED=0
SKIPPED=0
PRUNED=0

for skill in "$CLAUDE_SKILLS"/*/; do
  name=$(basename "$skill")
  [ "$name" = ".git" ] && continue
  [ "$name" = ".system" ] && continue

  if is_denied "$name"; then
    if [ -L "$CODEX_SKILLS/$name" ] || [ -e "$CODEX_SKILLS/$name" ]; then
      rm -rf "$CODEX_SKILLS/$name"
      echo "  - $name (denied — pruned)"
      PRUNED=$((PRUNED + 1))
    fi
    continue
  fi

  if [ -L "$CODEX_SKILLS/$name" ] && [ ! -e "$CODEX_SKILLS/$name" ]; then
    rm "$CODEX_SKILLS/$name"
    ln -s "$CLAUDE_SKILLS_REAL/$name" "$CODEX_SKILLS/$name"
    echo "  ~ $name (fixed broken symlink)"
    ADDED=$((ADDED + 1))
  elif [ -e "$CODEX_SKILLS/$name" ]; then
    SKIPPED=$((SKIPPED + 1))
  else
    ln -s "$CLAUDE_SKILLS_REAL/$name" "$CODEX_SKILLS/$name"
    echo "  + $name"
    ADDED=$((ADDED + 1))
  fi
done

# Reverse-prune pass: the forward loop only visits skills that STILL EXIST in
# Claude, so symlinks orphaned by a renamed/deleted skill are never seen there.
# Sweep the codex dir and remove any entry that is a broken symlink, has no real
# source dir in Claude skills, or is denied. (Fixes dead links left behind by
# past skills consolidations — e.g. a renamed/retired skill's old symlink.)
for link in "$CODEX_SKILLS"/*; do
  [ -e "$link" ] || [ -L "$link" ] || continue   # skip empty glob
  name=$(basename "$link")
  [ "$name" = ".system" ] && continue
  if { [ -L "$link" ] && [ ! -e "$link" ]; } || [ ! -d "$CLAUDE_SKILLS/$name" ] || is_denied "$name"; then
    rm -rf "$link"
    echo "  - $name (orphan/denied — pruned)"
    PRUNED=$((PRUNED + 1))
  fi
done

TOTAL=$(ls -d "$CODEX_SKILLS"/*/ 2>/dev/null | grep -v '.system' | wc -l | tr -d ' ')
echo "synced: +${ADDED} new, ${SKIPPED} existed, -${PRUNED} pruned, ${TOTAL} total"
