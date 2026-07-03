#!/usr/bin/env bash
# _classify.sh — shared helper for maw git-guard hooks. Sourced, not run.
# Sets: GUARD_REPO (main-repo name, worktree-resolved), GUARD_IS_PRODUCT (0|1).
# Default classification is INFRA (permissive) — only known product patterns lock down.
#
# Product list derived from fleet/projects.yaml via generate-guards.sh.
# Do NOT hardcode repo names here — edit the registry, regenerate.

# Source the generated guard patterns (product list from registry)
_GUARD_PATTERNS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_generated-patterns.sh"
if [ -f "$_GUARD_PATTERNS" ]; then
  . "$_GUARD_PATTERNS"
fi

guard_classify() {
  local toplevel name common mr
  toplevel="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  name="$(basename "$toplevel")"
  common="$(git rev-parse --git-common-dir 2>/dev/null || echo "")"
  case "$common" in
    */.git) mr="$(basename "$(dirname "$common")")"; [ -n "$mr" ] && name="$mr" ;;
  esac
  GUARD_REPO="$name"
  GUARD_IS_PRODUCT=0
  if type is_product_repo >/dev/null 2>&1 && is_product_repo "$name"; then
    GUARD_IS_PRODUCT=1
  fi
}

# Chain to a pre-existing repo-local hook if one is installed (so we never silently
# disable Husky / .git/hooks). $1 = hook name, rest = original args. Returns only if
# no chainable hook exists.
guard_chain_noinput() {
  local hookname="$1"; shift
  local common toplevel cand
  common="$(git rev-parse --git-common-dir 2>/dev/null || echo "")"
  toplevel="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  for cand in "$common/hooks/$hookname" "$toplevel/.husky/$hookname"; do
    [ -x "$cand" ] && exec "$cand" "$@"
  done
}
