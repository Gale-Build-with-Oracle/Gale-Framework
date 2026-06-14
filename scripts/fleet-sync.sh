#!/usr/bin/env bash
# fleet-sync.sh — ONE idempotent fleet doctrine sync.
# Supersedes fleet-propagate-shared.sh + fleet-propagate-agents.sh.
#
#   LAYERED CONTEXT (2026-06-13): doctrine lives at the GLOBAL layer ONLY.
#   Every session loads global + cwd files together natively:
#     Claude: ~/.claude/CLAUDE.md (doctrine) + cwd CLAUDE.md (identity / project context)
#     Codex:  ~/.codex/AGENTS.md FLEET-DOCTRINE block (doctrine) + cwd AGENTS.md (identity / project context)
#   Per-oracle files = identity ONLY. Per-project files = project context ONLY.
#   Doctrine text inside an oracle/project file = lint FAILURE (double-load + drift).
#
#   1. render global targets (Gale-Framework/claude/CLAUDE.md, codex/instructions.md)
#   2. ensure git-guard installed (global core.hooksPath)
#   3. skill-sync to Codex (machine-level)
#   4. oracle repos: sweep retired render-indirection cruft (fragment/build/doctrine symlink).
#      Per-oracle CLAUDE.md/AGENTS.md are HAND-EDITED identity — fleet-sync does NOT render them.
#   4b. product AGENTS.md: managed block = thin pointer to global doctrine
#       (manage permissive repos · drift-detect hook-blocked product mains)
#   5. structural guard: no doctrine text in any per-oracle CLAUDE.md/AGENTS.md (hand-edited)
#   6. reconcile Gale-Framework submodule pointers (commit clean+pushed gitlink drift,
#      e.g. after /maw-update bumps a submodule) so WF's recorded state stays exact
#   7. single-source maw config: re-heal the ~/.config/maw/maw.config.50.json symlink and
#      snapshot the ~/.maw/fleet roster into WF/maw/fleet (git history; live dir stays writable)
#
# NOTE: codex 0.139 reads user_instructions from AGENTS.md ONLY (never ~/.codex/instructions.md).
# Step 1c injects the fleet doctrine as a FLEET-DOCTRINE block into ~/.codex/AGENTS.md (the
# omx-preserved zone). The OMX-generated sections of that file are left untouched.
#
# Usage: fleet-sync.sh [--dry-run] [--no-push]
set -uo pipefail

DRY=0; PUSH=1
for a in "$@"; do case "$a" in --dry-run) DRY=1 ;; --no-push) PUSH=0 ;; esac; done

GITHUB_USER="${GITHUB_USER:-$(gh api user -q .login 2>/dev/null || git config github.user 2>/dev/null || true)}"
if [ -z "$GITHUB_USER" ]; then
  echo "fleet-sync.sh: set GITHUB_USER or authenticate gh (gh auth login)" >&2
  exit 1
fi
GHQ="${GHQ:-$HOME/ghq/github.com/$GITHUB_USER}"
WF="${GALE_FRAMEWORK_DIR:-$GHQ/Gale-Framework}"
CANON="$WF/claude/doctrine"
BUILD="$WF/scripts/oracle-build.sh"
run(){ if [ "$DRY" = 1 ]; then echo "  [dry] $*"; else eval "$*"; fi; }
# Upstream forks whose CLAUDE.md/AGENTS.md are hand-maintained by upstream — not fleet-linted.
is_skip_oracle(){ case "$(basename "$1")" in ui-oracle) return 0;; *) return 1;; esac; }

echo "⚡ fleet-sync ($([ "$DRY" = 1 ] && echo DRY-RUN || echo EXECUTE))"

echo "── 1. global render (Gale-Framework) ──"
if [ "$DRY" = 0 ]; then ( cd "$WF" && bash "$BUILD" --global ); else echo "  [dry] oracle-build.sh --global"; fi

echo "── 1b. guard patterns from registry ──"
if [ "$DRY" = 0 ]; then bash "$WF/scripts/generate-guard-patterns.sh"; else echo "  [dry] generate-guard-patterns.sh"; fi

echo "── 1c. codex fleet doctrine → ~/.codex/AGENTS.md ──"
# Codex 0.139 reads user_instructions from AGENTS.md ONLY — it does NOT read
# ~/.codex/instructions.md (verified via codex-rs source). So the rendered codex
# doctrine (WF/codex/instructions.md = core+codex) is injected as a FLEET-DOCTRINE
# managed block into ~/.codex/AGENTS.md, in the zone omx preserves (above the
# omx:generated marker). Idempotent; self-heals if an omx setup ever clobbers it.
if [ "$DRY" = 0 ]; then
  python3 "$WF/scripts/inject-codex-doctrine.py" "$HOME/.codex/AGENTS.md" "$WF/codex/instructions.md" | sed 's/^/  /'
else echo "  [dry] inject-codex-doctrine.py → ~/.codex/AGENTS.md"; fi

echo "── 2. git-guard ──"
if [ "$(git config --global --get core.hooksPath 2>/dev/null)" = "$HOME/.config/git/hooks" ] && [ -e "$HOME/.config/git/hooks/pre-commit" ]; then
  echo "  ✓ core.hooksPath set + hooks present"
else
  run "mkdir -p '$HOME/.config/git'"
  run "ln -sfn '$WF/claude/git-guard' '$HOME/.config/git/hooks'"
  run "git config --global core.hooksPath '$HOME/.config/git/hooks'"
  echo "  ✓ git-guard installed"
fi

echo "── 2b. hooks/skills parity (~/.claude ↔ WF sources) ──"
# Hooks + skills live in ~/.claude as hardlinks of WF sources. A broken/diverged link is a
# silent single-point-of-failure (oracle loses hook enforcement / runs a stale skill with no
# DRIFT warning). Heal direction: WF → ~/.claude only; local-only entries are left alone.
HOK=0; HHL=0; SOK=0; SHL=0
for SRC in "$WF"/claude/hooks/*.sh; do
  B=$(basename "$SRC"); DST="$HOME/.claude/hooks/$B"
  if [ "$SRC" -ef "$DST" ] || cmp -s "$SRC" "$DST" 2>/dev/null; then HOK=$((HOK+1));
  else run "ln -f '$SRC' '$DST'"; echo "  ↻ healed hook $B"; HHL=$((HHL+1)); fi
done
for SRC in "$WF"/claude/skills/*/SKILL.md; do
  SK=$(basename "$(dirname "$SRC")"); DST="$HOME/.claude/skills/$SK/SKILL.md"
  [ -d "$HOME/.claude/skills/$SK" ] || continue  # profile-filtered skills absent by design
  if [ "$SRC" -ef "$DST" ] || cmp -s "$SRC" "$DST" 2>/dev/null; then SOK=$((SOK+1));
  else run "ln -f '$SRC' '$DST'"; echo "  ↻ healed skill $SK"; SHL=$((SHL+1)); fi
done
echo "  ✓ hooks $HOK ok / $HHL healed · skills $SOK ok / $SHL healed"

echo "── 3. skill-sync (Codex) ──"
if [ "$DRY" = 0 ]; then bash "$WF/claude/scripts/sync-skills-to-codex.sh" | tail -1; else echo "  [dry] sync-skills-to-codex.sh"; fi

echo "── 4. oracle repos — stale-cruft cleanup (NO build; CLAUDE.md is hand-edited identity) ──"
# The per-oracle render is RETIRED (2026-06-13): each oracle's CLAUDE.md / AGENTS.md IS its
# hand-edited identity (Claude/Codex read it directly; doctrine arrives via global). fleet-sync
# no longer touches those files — it only sweeps the dead indirection (doctrine symlink,
# per-repo oracle-build copy, leftover oracle-<name>-*.md fragments) if any linger. The
# structural-guard lint (step 5) keeps the hand-edited files identity-only.
BUILT=0; NOID=()
for REPO in "$GHQ"/*-oracle; do
  [ -d "$REPO/.git" ] || continue
  NAME=$(basename "$REPO" | sed -E 's/-oracle$//I' | tr '[:upper:]' '[:lower:]')
  STALE=()
  [ -L "$REPO/doctrine" ] || [ -d "$REPO/doctrine" ] && STALE+=("doctrine")
  { [ -L "$REPO/scripts/oracle-build.sh" ] || { [ -f "$REPO/scripts/oracle-build.sh" ] && cmp -s "$REPO/scripts/oracle-build.sh" "$BUILD" 2>/dev/null; }; } && STALE+=("scripts/oracle-build.sh")
  [ -f "$REPO/oracle-${NAME}-claude.md" ] && STALE+=("oracle-${NAME}-claude.md")
  [ -f "$REPO/oracle-${NAME}-agents.md" ] && STALE+=("oracle-${NAME}-agents.md")
  [ ${#STALE[@]} -eq 0 ] && continue
  echo "  • $NAME — sweeping: ${STALE[*]}"
  if [ "$DRY" = 0 ]; then
    for p in "${STALE[@]}"; do
      if [ -e "$REPO/$p" ] || [ -L "$REPO/$p" ]; then
        SAFE_NAME="$(printf '%s' "$p" | tr '/ ' '__')"
        mv "$REPO/$p" "/tmp/gale-framework-stale-$(basename "$REPO")-$SAFE_NAME-$(date +%s)"
      fi
      git -C "$REPO" rm -q --cached -r "$p" 2>/dev/null || true
    done
    if ! git -C "$REPO" diff --cached --quiet 2>/dev/null; then
      git -C "$REPO" commit -q -m "cleanup: remove retired per-oracle render indirection (fragment+build) — CLAUDE.md is the identity" -m "Co-Authored-By: my-oracle" && echo "    ✓ committed"
      [ "$PUSH" = 1 ] && { git -C "$REPO" push -q 2>/dev/null && echo "    ✓ pushed" || echo "    ⚠ push failed"; }
    fi
  fi
done

echo "── 4b. product AGENTS.md fan-out (manage permissive · detect hook-blocked) ──"
# Codex worktrees obey the PROJECT AGENTS.md; a repo missing/contradicting the team-spawn
# fan-out routing makes codex default to solo. Permissive product repos get the managed
# block auto-synced from doctrine/core.md; hook-blocked product mains (PR-only) are
# drift-DETECTED so a missing block is visible instead of silent.
SP="$WF/scripts/sync-product-agents.sh"
if [ "$DRY" = 1 ]; then bash "$SP" --dry-run
elif [ "$PUSH" = 0 ]; then bash "$SP" --no-push
else bash "$SP"; fi

echo "── 5. structural guard (no doctrine below the global layer) ──"
# Identity/project files re-embedding doctrine = double-load + the drift bug returning.
# Marker: '## The 5 Principles' exists ONLY in core.md and its global renders.
STRUCT_FAIL=0
for REPO in "$GHQ"/*-oracle; do
  [ -d "$REPO/.git" ] || continue
  is_skip_oracle "$REPO" && continue
  for F in "$REPO/CLAUDE.md" "$REPO/AGENTS.md"; do
    [ -f "$F" ] || continue
    if grep -q '^## The 5 Principles' "$F"; then
      echo "  ✗ $(basename "$REPO")/$(basename "$F") contains doctrine (must be identity-only)"
      STRUCT_FAIL=$((STRUCT_FAIL + 1))
    fi
  done
done
[ "$STRUCT_FAIL" -eq 0 ] && echo "  ✓ all per-oracle files identity-only"

echo "── 5b. retired-term lint (CLAUDE.md/AGENTS.md + skills + hooks + fragments source) ──"
# When a workflow is retired, the term MUST NOT survive as LIVE GUIDANCE anywhere —
# rendered CLAUDE.md/AGENTS.md, skills, hooks, identity files, or the source fragments.
# This is the structural guard against the drift that breaks the fleet workflow
# (doctrine consolidation 2026-06-11: some surfaces updated, others kept the old story).
# A term is a violation ONLY when used as guidance; DOCUMENTING its retirement is allowed
# (NOTICE_RE excludes those lines + this lint's own definition).
# Era: 3-layer ephemeral (L1 → workon L2 → ephemeral OMX L3), public starter directive 2026-06-13.
# Retired sets: maw-tile era · standing-team era (2026-06-10) · on-demand-team era (2026-06-12).
# LIVE terms (must NOT appear here): L2 orchestrator, STRATEGY: SOLO/TEAM, strategy.json,
# aggregate-verified, maw team shutdown, consolidated PR, maw workon pipeline.
RETIRED_TERMS=(
  "maw tile [0-9]" "maw tile clean" "tile workflow" "tile pane" "@maw_tile"
  "STANDING PROJECT TEAM" "standing team" "standing worker" "idling between briefs"
  "PERMANENT worker" "MAW_ALLOW_STANDING_DOWN" "standing\.yaml" "Session refresh"
  "maw team down" "on-demand project team" "ON-DEMAND project team"
  "project-team\.yaml" "lazy-create the charter"
)
NOTICE_RE='RETIRED|retired|no longer|deprecated|NOT a |no separate|is the only mode|never (spawn|tear|warm)|RETIRED_TERMS|NOTICE_RE|superseded|_lint|does NOT cross|no per-oracle|still banned|no L2|removed|REMOVED'
LINT_FAIL=0
_lint() {  # $1 = file, $2 = label
  local f="$1" label="$2" pat hits
  [ -f "$f" ] || return 0
  for pat in "${RETIRED_TERMS[@]}"; do
    hits=$(grep -inE "$pat" "$f" 2>/dev/null | grep -viE "$NOTICE_RE" || true)
    if [ -n "$hits" ]; then
      echo "  ✗ $label: retired term '$pat'"
      printf '%s\n' "$hits" | head -2 | sed 's/^/      /'
      LINT_FAIL=$((LINT_FAIL + 1))
    fi
  done
}
# Per-oracle hand-edited CLAUDE.md/AGENTS.md — every fleet oracle (skip upstream forks
# like ui-oracle whose files are upstream-maintained, not ours).
for REPO in "$GHQ"/*-oracle; do
  [ -d "$REPO/.git" ] || continue
  is_skip_oracle "$REPO" && continue
  NAME=$(basename "$REPO")
  _lint "$REPO/CLAUDE.md" "$NAME/CLAUDE.md"
  _lint "$REPO/AGENTS.md" "$NAME/AGENTS.md"
done
# WF source surfaces — the drift ORIGINATES here, so lint them too (skills + hooks were
# never covered before; that is why retired routing survived in /sop-maw + /sop-delegation).
for F in "$WF"/claude/doctrine/*.md "$WF"/claude/skills/*/SKILL.md "$WF"/claude/hooks/*.sh "$WF"/AGENTS.md; do
  _lint "$F" "WF/${F#$WF/}"
done
# Structural: the guard-patterns source must EXIST — its absence silently disabled
# push-to-main blocking (2026-06-11). A hook sourcing a missing file is a lint failure.
GP="$HOME/.config/git/hooks/_generated-patterns.sh"
if grep -q '_generated-patterns.sh' "$WF/claude/hooks/pre-guard.sh" 2>/dev/null && [ ! -f "$GP" ]; then
  echo "  ✗ pre-guard.sh sources _generated-patterns.sh but $GP is MISSING (guard silently disabled)"
  LINT_FAIL=$((LINT_FAIL + 1))
fi
[ "$LINT_FAIL" -eq 0 ] && echo "  ✓ no retired terms / broken sources" || echo "  ✗ $LINT_FAIL lint hit(s) — fix the SOURCE before this sync is clean (see ── lint summary ── below)"

echo "── 6. Gale-Framework submodule pointers ──"
# After an infra-repo sync (e.g. /maw-update bumps a WF/repos submodule via its ghq
# symlink), the superproject gitlinks drift. Reconcile them — but ONLY for submodules
# that are clean AND pushed, so we never record a dirty/unpushed commit that would break
# `git clone Gale-Framework --recursive` on another machine. Stage by explicit path
# (git add -A is hook-blocked).
if [ "$DRY" = 1 ]; then
  echo "  [dry] would reconcile drifted WF submodule pointers (clean+pushed only)"
else
  RECON=0
  for p in $(git -C "$WF" diff --name-only -- repos/ 2>/dev/null); do
    sub="$WF/$p"
    [ -e "$sub/.git" ] || { echo "  ⚠ $p not a submodule — skipped"; continue; }
    if [ -n "$(git -C "$sub" status --porcelain 2>/dev/null)" ]; then
      echo "  ⚠ $p dirty — skipped (commit inside the submodule first)"; continue; fi
    if [ -n "$(git -C "$sub" log '@{u}..HEAD' --oneline 2>/dev/null)" ]; then
      echo "  ⚠ $p unpushed — skipped (push the submodule first)"; continue; fi
    git -C "$WF" add "$p" && { RECON=$((RECON + 1)); echo "  • staged $p → $(git -C "$sub" rev-parse --short HEAD)"; }
  done
  if [ "$RECON" -gt 0 ]; then
    git -C "$WF" commit -q -m "fleet-sync: reconcile submodule pointers" -m "Co-Authored-By: my-oracle" && echo "  ✓ committed $RECON pointer(s)"
    [ "$PUSH" = 1 ] && { git -C "$WF" push -q origin HEAD 2>/dev/null && echo "  ✓ pushed" || echo "  ⚠ push failed"; }
  else
    echo "  ✓ no clean+pushed pointer drift"
  fi
fi

echo "── 7. maw config/fleet single-source ──"
# Single source = WF/maw/. The active weighted config (~/.config/maw/maw.config.50.json)
# is a SYMLINK to WF/maw/maw.config.50.json, so edits auto-track. The fleet roster
# (~/.maw/fleet, WRITTEN by maw on wake/bud) is the live writable source — snapshot it
# into WF/maw/fleet for git history (NOT symlinked, to avoid churning this tree).
WFMAW="$WF/maw"
# self-heal the config symlink if a real file or wrong link shadows the single source
if [ "$DRY" = 0 ] && [ -f "$WFMAW/maw.config.50.json" ]; then
  if [ ! -L ~/.config/maw/maw.config.50.json ] || [ "$(readlink ~/.config/maw/maw.config.50.json)" != "$WFMAW/maw.config.50.json" ]; then
    [ -e ~/.config/maw/maw.config.50.json ] && mv ~/.config/maw/maw.config.50.json ~/.config/maw/maw.config.50.json.bak
    ln -sfn "$WFMAW/maw.config.50.json" ~/.config/maw/maw.config.50.json
    echo "  ⟳ config symlink re-healed → WF/maw/maw.config.50.json"
  else echo "  ✓ config symlink intact"; fi
fi
if [ "$DRY" = 1 ]; then
  echo "  [dry] would snapshot ~/.maw/fleet → WF/maw/fleet + commit WF/maw changes"
else
  mkdir -p "$WFMAW/fleet"
  [ -n "$(ls -A ~/.maw/fleet/*.json 2>/dev/null)" ] && cp ~/.maw/fleet/*.json "$WFMAW/fleet/" 2>/dev/null
  git -C "$WF" add maw/ 2>/dev/null
  if ! git -C "$WF" diff --cached --quiet -- maw/ 2>/dev/null; then
    git -C "$WF" commit -q -m "fleet-sync: snapshot maw config + fleet roster" -m "Co-Authored-By: my-oracle" && echo "  ✓ committed maw config/fleet snapshot"
    [ "$PUSH" = 1 ] && { git -C "$WF" push -q origin HEAD 2>/dev/null && echo "  ✓ pushed" || echo "  ⚠ push failed"; }
  else echo "  ✓ maw config/fleet in sync"; fi
fi

echo ""
echo "── summary ── per-oracle CLAUDE.md/AGENTS.md are hand-edited identity (no render step)"

# ── lint summary ── — fail the sync (nonzero exit) if any retired term / broken source /
# structural violation survived. This is what makes drift structurally impossible to ship silently.
TOTAL_FAIL=$(( ${LINT_FAIL:-0} + ${STRUCT_FAIL:-0} ))
if [ "$TOTAL_FAIL" -gt 0 ]; then
  echo ""
  echo "✗ fleet-sync NOT clean: $TOTAL_FAIL hit(s) above (retired-term/broken-source/doctrine-below-global). Fix the SOURCE and re-run."
  exit 1
fi
echo "  ✓ lint clean"
exit 0
