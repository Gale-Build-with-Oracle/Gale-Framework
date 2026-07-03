#!/usr/bin/env bash
# sync-product-agents.sh — keep product-repo AGENTS.md aligned with the LAYERED CONTEXT model.
#
# Layered context: fleet doctrine reaches Codex via the GLOBAL
# ~/.codex/AGENTS.md FLEET-DOCTRINE block — product AGENTS.md carries ONLY project-specific rules.
# The managed block is therefore a THIN POINTER, not a doctrine copy (a copy would
# double-load, drift, and — because project AGENTS.md overrides global — silently win).
#
# Reads fleet/projects.yaml (the single source of truth) and for each active project
# with family: product:
#   • PERMISSIVE repos (guard: permissive): managed-block sync (auto-push to main)
#   • HOOK-BLOCKED repos: managed-block PR (branch → PR → owner merges)
#
# Also detects and reports content drift in AGENTS.md (stale patterns that
# need fixing inside the managed block or surrounding content).
#
# Idempotent: re-run with unchanged fragment makes zero commits/PRs.
# Usage: sync-product-agents.sh [--dry-run] [--no-push]
set -uo pipefail

DRY=0; PUSH=1
for a in "$@"; do case "$a" in --dry-run) DRY=1 ;; --no-push) PUSH=0 ;; esac; done

WF_ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"

GITHUB_USER="${GITHUB_USER:-$(gh api user -q .login 2>/dev/null || git config github.user 2>/dev/null || true)}"
if [ -z "$GITHUB_USER" ]; then
  echo "sync-product-agents.sh: set GITHUB_USER or authenticate gh (gh auth login)" >&2
  exit 1
fi
GHQ="${GHQ:-$HOME/ghq/github.com/$GITHUB_USER}"
REGISTRY="$WF_ROOT/fleet/projects.yaml"
GUARD_FILE="$WF_ROOT/claude/git-guard/_generated-patterns.sh"

# Source generated guard patterns (only present if you've run generate-guard-patterns.sh)
[ -f "$GUARD_FILE" ] && . "$GUARD_FILE"

# Thin pointer block (layered context — doctrine is GLOBAL, never copied here)
START="<!-- FLEET-DOCTRINE:fan-out — managed by fleet-sync; thin pointer, never a doctrine copy -->"
END="<!-- /FLEET-DOCTRINE:fan-out -->"
POINTER="Fleet doctrine (Fan-Out Strategy, Work Pattern, Merge Gate, hard constraints) is GLOBAL:
codex loads it from the FLEET-DOCTRINE block in your ~/.codex/AGENTS.md (rendered from
Gale-Framework claude/doctrine/{core,codex}.md; codex reads AGENTS.md, and has no standalone instructions file).
This file carries ONLY project-specific rules (stack, schema, commands, testing surface).
Do NOT copy fleet doctrine into this file — project AGENTS.md overrides global, so a stale copy silently wins."

# Parse registry with python3 (always available, no yaml deps needed for flat schema)
REPO_DATA=$(python3 - "$REGISTRY" << 'PYEOF'
import sys
projects = []
current = {}
with open(sys.argv[1]) as f:
    for line in f:
        line = line.rstrip()
        if line.startswith('- name:'):
            if current: projects.append(current)
            current = {'name': line.split(':', 1)[1].strip()}
        elif ':' in line and current and not line.startswith('#'):
            key, val = line.strip().split(':', 1)
            current[key.strip()] = val.strip()
    if current: projects.append(current)

for p in projects:
    if p.get('family') == 'product' and p.get('status') == 'active':
        print(f"{p['name']}\t{p.get('guard','permissive')}\t{p.get('family','')}")
PYEOF
)

SYNCED=0; OKM=0; DRIFT=0; OKB=0; ARCHIVED=0; CONTENT_ISSUES=0

echo "⚡ sync-product-agents ($([ "$DRY" = 1 ] && echo DRY-RUN || echo EXECUTE))"

# Build the expected managed block content
WANT_BLOCK="$(printf '%s\n\n%s\n\n%s' "$START" "$POINTER" "$END")"

# ── Content checks: detect drift patterns in AGENTS.md ──────────────
check_content_drift() {
  local ag="$1" name="$2" family="${3:-}"
  local issues=()

  grep -qiE '(--engine|-e)[[:space:]]+codex' "$ag" && issues+=("stale '-e codex' engine (canonical: --engine omx)")
  grep -qiE 'solo\+announce|solo \+ announce' "$ag" && issues+=("stale 'solo+announce' (use STRATEGY: SOLO|TEAM)")
  grep -qiE 'Doc.*(Update|update).*(same|SAME)[[:space:]]+(PR|pr)' "$ag" && issues+=("per-PR doc mandate (use batch /doc-sync + REQ-line)")
  grep -qiE 'RTM\.md' "$ag" && issues+=("references RTM.md (abolished — UAT IS the traceability)")
  grep -qiE '## Subagent Strategy' "$ag" && issues+=("has stale '## Subagent Strategy' section (replace with Fan-Out)")
  grep -qiE 'git add \.' "$ag" && issues+=("documents 'git add .' (hard-constraint violation)")
  grep -qiE 'NO AI attribution' "$ag" && ! grep -qiE 'NO generic AI attribution' "$ag" && issues+=("'NO AI attribution' should be 'NO generic AI attribution — use Co-Authored-By'")
  if [ "$family" = "product" ]; then
    # Flag only an INSTRUCTION to use dev mode — NOT the prohibition rule itself
    # ("never npm run dev" / "Docker only — never npm run dev" is correct doctrine).
    grep -iE '(npm run dev|bun dev|dev:all)' "$ag" | grep -viE 'never|docker (is )?(the )?only|do not|don.t|instead of' | grep -q .       && issues+=("instructs npm run dev (Docker-only testing convention)")
  fi

  # curl-first framing check: curl listed as routine, not EMERGENCY-ONLY
  if grep -qiE 'curl.*localhost:47778' "$ag" && ! grep -qiE 'EMERGENCY' "$ag"; then
    issues+=("curl listed as routine HTTP fallback (should be EMERGENCY-ONLY)")
  fi

  if [ ${#issues[@]} -gt 0 ]; then
    CONTENT_ISSUES=$((CONTENT_ISSUES + ${#issues[@]}))
    for iss in "${issues[@]}"; do
      echo "    ⚠ $iss"
    done
  fi
}

# ── Sync function: managed block write + commit ──────────────────────
sync_managed_block() {
  local repo_dir="$1" ag="$2" name="$3"

  # Extract body before any managed block or fan-out heading
  local body
  body=$(awk '/^<!-- FLEET-DOCTRINE:fan-out/{exit} /^## Fan-Out Strategy/{exit} {print}' "$ag")

  # Also strip any "## Subagent Strategy" section (contradicts fan-out)
  body=$(echo "$body" | awk '/^## Subagent Strategy/{skip=1} skip && /^## /{skip=0} !skip{print}')

  # Strip the legacy doctrine-pointer paragraph (layered context): it points at
  # a retired ~/.codex/instructions.md AND duplicates what the thin block below already says.
  body=$(echo "$body" | grep -vF 'Your full Codex doctrine is the global' | cat -s)

  { printf '%s\n\n%s\n\n' "$body" "$START"; printf '%s' "$POINTER"; printf '\n\n%s\n' "$END"; } > "$ag"
}

# ── Check if block is current ────────────────────────────────────────
block_is_current() {
  local ag="$1"
  grep -qF "$START" "$ag" || return 1
  local existing
  existing=$(awk '/^<!-- FLEET-DOCTRINE:fan-out/{f=1} f{print} /^<!-- \/FLEET-DOCTRINE:fan-out/{f=0}' "$ag")
  [ "$existing" = "$WANT_BLOCK" ]
}

# ── Process each product repo ────────────────────────────────────────
echo ""
echo "── permissive product repos — managed block (auto-push) ──"
while IFS=$'\t' read -r name guard family; do
  [ "$guard" = "permissive" ] || continue
  REPO="$GHQ/$name"
  [ -d "$REPO/.git" ] || { echo "  ○ $name (not cloned)"; continue; }
  AG="$REPO/AGENTS.md"
  [ -f "$AG" ] || { echo "  ○ $name (no AGENTS.md)"; continue; }

  if [ "$DRY" = 1 ]; then
    if block_is_current "$AG"; then
      echo "  ✓ $name (current)"
      check_content_drift "$AG" "$name" "$family"
      OKM=$((OKM+1))
    else
      echo "  [dry] would sync $name"
      check_content_drift "$AG" "$name" "$family"
      SYNCED=$((SYNCED+1))
    fi
    continue
  fi

  sync_managed_block "$REPO" "$AG" "$name"
  git -C "$REPO" add AGENTS.md
  if ! git -C "$REPO" diff --cached --quiet 2>/dev/null; then
    git -C "$REPO" commit -q -m "doctrine: sync Fan-Out Strategy from fleet canonical (managed block)" -m "Co-Authored-By: my-oracle"
    if [ "$PUSH" = 1 ] && git -C "$REPO" push -q 2>/dev/null; then
      echo "  ⟳ $name synced + pushed"
    else
      echo "  ⟳ $name synced (push skipped/failed)"
    fi
    SYNCED=$((SYNCED+1))
  else
    echo "  ✓ $name (current)"
    OKM=$((OKM+1))
  fi
  check_content_drift "$AG" "$name"
done <<< "$REPO_DATA"

echo ""
echo "── hook-blocked product repos — managed via PR ──"
while IFS=$'\t' read -r name guard family; do
  [ "$guard" = "hook-blocked" ] || continue
  REPO="$GHQ/$name"
  [ -d "$REPO/.git" ] || { echo "  ○ $name (not cloned)"; continue; }
  AG="$REPO/AGENTS.md"

  # AGENTS.md gitignored = local-only by the repo's own choice (e.g. a project that
  # keeps machine-specific worker rules out of version control).
  # Codex still reads the local file; we just can't version-control it via PR. Skip
  # gracefully instead of failing the sync every run.
  if git -C "$REPO" check-ignore -q AGENTS.md 2>/dev/null; then
    echo "  ⊘ $name (AGENTS.md gitignored — local-only, skipping PR)"
    continue
  fi

  # Check if archived (skip)
  if [ "$(gh repo view "$GITHUB_USER/$name" --json isArchived --jq .isArchived 2>/dev/null)" = "true" ]; then
    echo "  ⊘ $name (archived — skipping)"
    ARCHIVED=$((ARCHIVED+1))
    continue
  fi

  # A stale/diverged LOCAL clone can be missing an AGENTS.md that exists on origin
  # (e.g. a clone that has fallen behind origin by many commits). Self-heal the one
  # file from the remote default branch so a stale checkout isn't a false "no AGENTS.md".
  if [ ! -f "$AG" ]; then
    _DBR=$(gh repo view "$GITHUB_USER/$name" --json defaultBranchRef --jq .defaultBranchRef.name 2>/dev/null); _DBR="${_DBR:-main}"
    git -C "$REPO" fetch -q origin "$_DBR" 2>/dev/null
    git -C "$REPO" cat-file -e "origin/$_DBR:AGENTS.md" 2>/dev/null && git -C "$REPO" checkout -q "origin/$_DBR" -- AGENTS.md 2>/dev/null || true
  fi
  if [ ! -f "$AG" ]; then
    echo "  ✗ DRIFT $name (no AGENTS.md on origin either)"
    DRIFT=$((DRIFT+1))
    continue
  fi

  # Check if block is current
  if block_is_current "$AG"; then
    echo "  ✓ $name (current)"
    check_content_drift "$AG" "$name" "$family"
    OKB=$((OKB+1))
    continue
  fi

  if [ "$DRY" = 1 ]; then
    echo "  [dry] would PR-sync $name"
    check_content_drift "$AG" "$name" "$family"
    SYNCED=$((SYNCED+1))
    continue
  fi

  # Check for existing sync PR
  if gh pr list --repo "$GITHUB_USER/$name" --state open --json headRefName --jq '.[].headRefName' 2>/dev/null | grep -q '^doctrine/agents-fanout-sync$'; then
    echo "  ⏳ $name (sync PR already open)"
    check_content_drift "$AG" "$name" "$family"
    continue
  fi

  # Create PR via temp worktree
  DEFBR=$(gh repo view "$GITHUB_USER/$name" --json defaultBranchRef --jq .defaultBranchRef.name 2>/dev/null)
  DEFBR="${DEFBR:-main}"
  TMPWT="/tmp/agents-sync-$name-$$"
  git -C "$REPO" fetch -q origin "$DEFBR" 2>/dev/null
  git -C "$REPO" worktree prune 2>/dev/null
  # DETACHED worktree — create no local branch. A leftover or checked-out
  # 'doctrine/agents-fanout-sync' in the main clone used to make `worktree add -b`
  # fail "already exists" and wedge every future run; a detached worktree can't collide.
  _WT_ERR=$(git -C "$REPO" worktree add -q --detach "$TMPWT" "origin/$DEFBR" 2>&1)
  if [ $? -ne 0 ]; then
    echo "  ✗ $name (could not create temp worktree): ${_WT_ERR:-unknown}"
    continue
  fi

  if [ -f "$TMPWT/AGENTS.md" ]; then
    sync_managed_block "$TMPWT" "$TMPWT/AGENTS.md" "$name"
  else
    printf '# %s — Codex Worker Rules\n\n%s\n\n' "$name" "$START" > "$TMPWT/AGENTS.md"
    printf '%s' "$POINTER" >> "$TMPWT/AGENTS.md"
    printf '\n\n%s\n' "$END" >> "$TMPWT/AGENTS.md"
  fi

  # Auto-discover open issue
  ISSUE=$(gh issue list --repo "$GITHUB_USER/$name" --state open --search "AGENTS.md in:title" --json number --jq '.[0].number' 2>/dev/null)
  CLOSES=""
  [ -n "$ISSUE" ] && CLOSES="Closes #$ISSUE"$'\n\n'

  git -C "$TMPWT" add AGENTS.md
  # block_is_current checks the LOCAL clone, but sync_managed_block ran on the temp
  # worktree built from origin. A stale/diverged local clone can flag drift while
  # origin's managed block is already current → the sync is a no-op. Guard the empty
  # commit here (the permissive loop already does the same), else gh pr create fails
  # "No commits between" on an empty PR.
  if git -C "$TMPWT" diff --cached --quiet; then
    echo "  ✓ $name (managed block already current on origin — no PR needed)"
    OKB=$((OKB+1))
    check_content_drift "$AG" "$name"
    git -C "$REPO" worktree remove --force "$TMPWT" 2>/dev/null
    continue
  fi
  git -C "$TMPWT" commit -q -m "doctrine: align AGENTS.md with fleet fan-out canonical (managed block)" -m "Co-Authored-By: my-oracle"
  # Clear any stale remote sync branch before pushing. No OPEN PR exists (checked
  # above), so a leftover branch from a merged PR or an aborted run would otherwise
  # reject the push as non-fast-forward.
  git -C "$REPO" push -q origin --delete doctrine/agents-fanout-sync 2>/dev/null || true
  # Detached HEAD → the destination ref MUST be fully qualified (refs/heads/…),
  # else git errors "must fully qualify the ref". Capture push AND PR errors
  # SEPARATELY (never swallow) so a future failure names the real failing step.
  if ! _PUSH_ERR=$(git -C "$TMPWT" push -q origin HEAD:refs/heads/doctrine/agents-fanout-sync 2>&1); then
    echo "  ✗ $name (push failed): $(printf '%s' "$_PUSH_ERR" | grep -iE 'error|rejected|denied|remote:' | tail -1)"
  elif _PR_OUT=$(gh pr create --repo "$GITHUB_USER/$name" --base "$DEFBR" --head doctrine/agents-fanout-sync \
          --title "doctrine: align AGENTS.md with fleet fan-out canonical" \
          --body "${CLOSES}Script-driven alignment (sync-product-agents.sh): managed FLEET-DOCTRINE:fan-out block is now a thin pointer to the global doctrine (FLEET-DOCTRINE block in ~/.codex/AGENTS.md) — layered context, no doctrine copies in project files. Also strips the legacy 'doctrine is ~/.codex/instructions.md' header (retired symlink + duplicate of the block). Future syncs manage the marked block only. Owner L1 reviews + merges.

REQ: none

⚡ Generated by sync-product-agents.sh" 2>&1); then
    echo "  ⇪ $name (sync PR opened${ISSUE:+, Closes #$ISSUE})"
    SYNCED=$((SYNCED+1))
  else
    echo "  ✗ $name (PR creation failed): $(printf '%s' "$_PR_OUT" | tail -1)"
  fi
  check_content_drift "$AG" "$name"

  git -C "$REPO" worktree remove --force "$TMPWT" 2>/dev/null || mv "$TMPWT" "/tmp/agents-sync-stale-$$" 2>/dev/null
done <<< "$REPO_DATA"

echo ""
echo "── summary ──"
echo "  managed-synced: $SYNCED"
echo "  managed-ok: $OKM"
echo "  pr-ok: $OKB"
echo "  drift: $DRIFT"
echo "  archived-skipped: $ARCHIVED"
echo "  content-issues: $CONTENT_ISSUES"
[ "$DRIFT" -gt 0 ] && echo "  ⚠ $DRIFT repo(s) missing AGENTS.md entirely"
[ "$CONTENT_ISSUES" -gt 0 ] && echo "  ⚠ $CONTENT_ISSUES content issue(s) detected (fix in the AGENTS.md PR or directly)"
exit 0
