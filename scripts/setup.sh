#!/usr/bin/env bash
set -euo pipefail

# Gale-Framework public starter bootstrap.
# Usage: bash scripts/setup.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOUL_REPOS=(
  maw-js
  maw-ui
  arra-oracle-v3
  arra-oracle-skills-cli
  maw-plugin-registry
  ui-oracle
)

section() {
  printf '\n==> %s\n' "$1"
}

warn() {
  printf '  ⚠ %s\n' "$1" >&2
}

ok() {
  printf '  ✓ %s\n' "$1"
}

backup_path() {
  local path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    if [ ! -L "$path" ]; then
      local backup="${path}.bak.$(date +%Y%m%d%H%M%S)"
      mv "$path" "$backup"
      ok "backed up $path -> $backup"
    fi
  fi
}

link_path() {
  local source="$1"
  local target="$2"
  local label="$3"
  if [ ! -e "$source" ] && [ ! -L "$source" ]; then
    warn "$label skipped; missing source: $source"
    return 0
  fi
  mkdir -p "$(dirname "$target")"
  backup_path "$target"
  ln -sfn "$source" "$target"
  ok "$label -> $target"
}

copy_if_absent() {
  local source="$1"
  local target="$2"
  local label="$3"
  if [ ! -e "$source" ]; then
    warn "$label skipped; missing source: $source"
    return 0
  fi
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ]; then
    ok "$label already present: $target"
    return 0
  fi
  cp "$source" "$target"
  ok "$label seeded -> $target"
}

# Phase 0: OS detection
section "Phase 0: OS detection"
UNAME_S="$(uname -s)"
OS_FAMILY="unknown"
case "$UNAME_S" in
  Darwin) OS_FAMILY="macos" ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      OS_FAMILY="wsl2"
    else
      OS_FAMILY="linux"
    fi
    ;;
  *) OS_FAMILY="unknown" ;;
esac
ok "detected $OS_FAMILY ($UNAME_S)"

# Phase 1: Preflight
section "Phase 1: preflight"
missing=()
for tool in git gh tmux jq; do
  command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if command -v bun >/dev/null 2>&1; then
  JS_RUNTIME="bun"
elif command -v node >/dev/null 2>&1; then
  JS_RUNTIME="node"
  command -v npm >/dev/null 2>&1 || missing+=("npm")
else
  JS_RUNTIME=""
  missing+=("bun-or-node")
fi
if [ ${#missing[@]} -gt 0 ]; then
  warn "missing required tools: ${missing[*]}"
  cat <<'HELP' >&2
Install the missing tools, then re-run this script.
  macOS: brew install git gh tmux jq node
  Linux/WSL2: use your package manager for git gh tmux jq nodejs npm
  Bun alternative: https://bun.sh/docs/installation
After installing gh, run: gh auth login
HELP
  exit 1
fi
if ! gh auth status >/dev/null 2>&1; then
  warn "GitHub CLI is installed but not authenticated. Run: gh auth login"
  exit 1
fi
GITHUB_USER="${GITHUB_USER:-$(gh api user -q .login)}"
WORKSPACE_DIR="${GALE_WORKSPACE_DIR:-$HOME/ghq/github.com/$GITHUB_USER}"
ok "tools present; JavaScript runtime: $JS_RUNTIME"
ok "GitHub user: $GITHUB_USER"
ok "workspace: $WORKSPACE_DIR"

# Phase 2: Fork guidance
section "Phase 2: fork the upstream repositories"
cat <<'FORKS'
Create a fork of each upstream repository in your GitHub account before cloning:
  https://github.com/Soul-Brews-Studio/maw-js
  https://github.com/Soul-Brews-Studio/maw-ui
  https://github.com/Soul-Brews-Studio/arra-oracle-v3
  https://github.com/Soul-Brews-Studio/arra-oracle-skills-cli
  https://github.com/Soul-Brews-Studio/maw-plugin-registry
  https://github.com/Soul-Brews-Studio/ui-oracle
FORKS

# Phase 3: Clone user forks
section "Phase 3: clone your forks"
mkdir -p "$WORKSPACE_DIR"
for repo in "${SOUL_REPOS[@]}"; do
  dest="$WORKSPACE_DIR/$repo"
  url="https://github.com/$GITHUB_USER/$repo"
  if [ -d "$dest/.git" ]; then
    ok "$repo already cloned"
    continue
  fi
  if gh repo view "$GITHUB_USER/$repo" >/dev/null 2>&1; then
    git clone "$url" "$dest"
    ok "$repo cloned"
  else
    warn "$GITHUB_USER/$repo not found; fork Soul-Brews-Studio/$repo, then re-run"
  fi
done

# Phase 4: Install maw-js
section "Phase 4: install maw-js"
MAW_JS_DIR="$WORKSPACE_DIR/maw-js"
if [ -d "$MAW_JS_DIR/.git" ]; then
  if [ "$JS_RUNTIME" = "bun" ]; then
    (cd "$MAW_JS_DIR" && bun install && bun link)
    ok "maw-js linked with bun"
  else
    (cd "$MAW_JS_DIR" && npm install && npm link)
    ok "maw-js linked with npm"
  fi
else
  warn "maw-js fork is not cloned; skipping global link"
fi

# Phase 5: Symlink Claude config
section "Phase 5: symlink Claude config"
mkdir -p "$HOME/.claude"
link_path "$ROOT_DIR/claude/hooks" "$HOME/.claude/hooks" "Claude hooks"
link_path "$ROOT_DIR/claude/settings.json" "$HOME/.claude/settings.json" "Claude settings"
link_path "$ROOT_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md" "Claude doctrine"
link_path "$ROOT_DIR/claude/doctrine" "$HOME/.claude/doctrine" "Claude doctrine fragments"
link_path "$ROOT_DIR/claude/skills" "$HOME/.claude/skills" "Claude skills"

# Phase 6: Symlink Codex config
section "Phase 6: symlink Codex config"
mkdir -p "$HOME/.codex"
link_path "$ROOT_DIR/codex/config.toml" "$HOME/.codex/config.toml" "Codex config"
link_path "$ROOT_DIR/codex/agents" "$HOME/.codex/agents" "Codex agents"
link_path "$ROOT_DIR/codex/prompts" "$HOME/.codex/prompts" "Codex prompts"
link_path "$ROOT_DIR/codex/skills" "$HOME/.codex/skills" "Codex skills"

# Phase 7: Inject fleet doctrine into Codex AGENTS.md
section "Phase 7: inject Codex doctrine"
if [ -f "$ROOT_DIR/scripts/inject-codex-doctrine.py" ] && [ -f "$ROOT_DIR/codex/instructions.md" ]; then
  python3 "$ROOT_DIR/scripts/inject-codex-doctrine.py" "$HOME/.codex/AGENTS.md" "$ROOT_DIR/codex/instructions.md"
  ok "Codex doctrine injected into ~/.codex/AGENTS.md"
else
  warn "doctrine injection skipped; missing script or codex/instructions.md"
fi

# Phase 8: Symlink maw config and tmux config
section "Phase 8: symlink maw + tmux config"
mkdir -p "$HOME/.config/maw"
link_path "$ROOT_DIR/maw/maw.config.50.json" "$HOME/.config/maw/maw.config.50.json" "maw config"
link_path "$ROOT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf" "tmux config"

# Phase 9: Seed fleet roster
section "Phase 9: seed fleet roster"
mkdir -p "$HOME/.maw/fleet"
if [ -f "$ROOT_DIR/fleet/projects.yaml" ]; then
  copy_if_absent "$ROOT_DIR/fleet/projects.yaml" "$HOME/.maw/fleet/projects.yaml" "fleet projects"
else
  warn "fleet/projects.yaml missing; create it before relying on fleet roster commands"
fi

# Phase 10: Optional pm2 setup
section "Phase 10: optional pm2 setup"
if command -v pm2 >/dev/null 2>&1; then
  if [ -f "$ROOT_DIR/ecosystem.config.js" ]; then
    pm2 start "$ROOT_DIR/ecosystem.config.js"
    pm2 save
    ok "pm2 processes started and saved"
  else
    warn "pm2 present but ecosystem.config.js is absent; skipping"
  fi
else
  warn "pm2 not installed; skipping optional process manager setup"
fi

# Phase 11: Verify + final checklist
section "Phase 11: verify"
checks=(
  "$HOME/.claude"
  "$HOME/.codex"
  "$HOME/.config/maw"
  "$HOME/.tmux.conf"
)
for path in "${checks[@]}"; do
  if [ -e "$path" ] || [ -L "$path" ]; then
    ok "$path exists"
  else
    warn "$path missing"
  fi
done
if command -v maw >/dev/null 2>&1; then
  ok "maw command available"
else
  warn "maw command not found yet; confirm maw-js link completed and shell PATH is refreshed"
fi
cat <<CHECKLIST

Final checklist:
  1. Confirm each Soul-Brews-Studio fork exists under: $WORKSPACE_DIR
  2. Open a new shell so linked commands and shell config are refreshed.
  3. Run: maw --help
  4. Run: tmux source-file ~/.tmux.conf  # optional for existing tmux sessions
  5. If you use pm2, verify with: pm2 status

Gale-Framework setup complete.
CHECKLIST
