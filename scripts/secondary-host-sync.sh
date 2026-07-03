#!/usr/bin/env bash
# secondary-host-sync.sh — LOCAL doctrine/hook sync for a secondary machine
# (e.g. a laptop or mini PC used by only one oracle, separate from your
# primary machine).
#
# Why this exists: fleet-sync.sh runs on your primary machine and its remote
# secondary-host step may only rsync skills — hooks, settings hook-stanzas,
# the global ~/.claude/CLAUDE.md, and the codex FLEET-DOCTRINE block can end
# up with no update channel of their own and rot silently.
# If the secondary machine has its own clone of this framework repo, sync
# locally from it instead of waiting on the remote rsync.
#
# Run ON the secondary machine, from anywhere:
#   bash ~/ghq/github.com/<your-github-user>/Gale-Framework/scripts/secondary-host-sync.sh
set -euo pipefail

WF="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "── secondary-host-sync: $WF ──"

# 0. Current main
BRANCH=$(git -C "$WF" branch --show-current)
if [ "$BRANCH" != "main" ]; then
  echo "✗ clone is on '$BRANCH', not main — checkout main first (sync must track main)." >&2
  exit 1
fi
git -C "$WF" pull --ff-only

# 0b. Fail fast on local drift BEFORE deploying anything (adversarial review finding:
#     step 1 used to copy a drifted render globally before the later check could fire).
git -C "$WF" diff --quiet HEAD -- claude/CLAUDE.md 2>/dev/null || {
  echo "✗ clone has local edits to claude/CLAUDE.md — backport/resolve before syncing." >&2
  exit 1
}

# 1. Global doctrine (regular-file copy; the designed symlink layout is fine too,
#    but a copy can't dangle if the clone moves)
cp "$WF/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
echo "✓ ~/.claude/CLAUDE.md"

# 2. Hooks (all of them — pre-guard/post-tool/on-stop/prompt-inject/retro-extract/clipboard)
mkdir -p "$HOME/.claude/hooks"
for h in "$WF"/claude/hooks/*.sh; do
  cp "$h" "$HOME/.claude/hooks/$(basename "$h")"
done
echo "✓ ~/.claude/hooks/ ($(ls "$WF"/claude/hooks/*.sh | wc -l | tr -d ' ') scripts)"

# 3. Skills (additive rsync — never --delete: the secondary machine may also carry
#    non-framework skills that live outside this repo)
rsync -a "$WF/claude/skills/" "$HOME/.claude/skills/"
echo "✓ ~/.claude/skills/ (framework skills refreshed, other skills untouched)"

# 4. Codex FLEET-DOCTRINE block (render transiently, then upsert into ~/.codex/AGENTS.md)
if [ -f "$HOME/.codex/AGENTS.md" ]; then
  (cd "$WF" && bash scripts/oracle-build.sh --global >/dev/null)
  CODEX_RENDER="${WF_CODEX_DOCTRINE_RENDER:-${TMPDIR:-/tmp}/gale-framework-codex-doctrine.rendered.md}"
  python3 "$WF/scripts/inject-codex-doctrine.py" "$HOME/.codex/AGENTS.md" "$CODEX_RENDER"
  # oracle-build --global re-renders claude/CLAUDE.md from fragments; on a clean
  # pulled main this is a byte-identical no-op — verify, never assume.
  git -C "$WF" diff --quiet -- claude/CLAUDE.md || {
    echo "✗ render drift: claude/CLAUDE.md changed on rebuild — fragments and committed render disagree upstream. NOT syncing the drifted render." >&2
    git -C "$WF" checkout -- claude/CLAUDE.md
    exit 1
  }
  echo "✓ ~/.codex/AGENTS.md FLEET-DOCTRINE"
fi

# 5. Settings hook-stanza drift check (settings.json is machine-specific — never
#    auto-copied; surface differences in the hooks block only)
if command -v jq >/dev/null 2>&1; then
  if ! diff <(jq -S .hooks "$HOME/.claude/settings.json" 2>/dev/null) \
            <(jq -S .hooks "$WF/claude/settings.json" 2>/dev/null) >/dev/null 2>&1; then
    echo "⚠ hooks stanza differs between ~/.claude/settings.json and the repo's claude/settings.json — review:"
    diff <(jq -S .hooks "$HOME/.claude/settings.json") <(jq -S .hooks "$WF/claude/settings.json") | head -20 || true
  else
    echo "✓ settings.json hooks stanza matches"
  fi
fi

echo "── secondary-host-sync done ($(git -C "$WF" log --oneline -1)) ──"
