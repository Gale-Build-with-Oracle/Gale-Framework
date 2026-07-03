#!/bin/bash
# code-review-graph freshness + lazy build — the graph DB is per-repo
# (.code-review-graph/ = Tree-sitter index of THAT repo). The binary/MCP is
# user-scope (installed once); this hook makes the per-repo DB fully automatic:
#   - graph exists      → incremental update (keep it fresh)
#   - no graph + OUR repo (<your-github-user>/*) → full build, first touch only
# Runs in background — never blocks git. Silent no-op everywhere else.
ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
CRG="$HOME/.local/bin/code-review-graph"
[ -x "$CRG" ] || exit 0
if [ -d "$ROOT/.code-review-graph" ]; then
  ( cd "$ROOT" && nohup "$CRG" update >/dev/null 2>&1 & ) >/dev/null 2>&1
else
  REMOTE=$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)
  case "$REMOTE" in
    # Edit the placeholder below to your own GitHub account/org so first-touch
    # auto-build only fires for repos you own (not every repo you clone).
    *github.com[:/]"<your-github-user>"/*)
      ( cd "$ROOT" && nohup "$CRG" build >/dev/null 2>&1 & ) >/dev/null 2>&1 ;;
  esac
fi
exit 0
