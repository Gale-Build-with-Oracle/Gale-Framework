#!/usr/bin/env bash
set -euo pipefail

# Gale-Framework public starter bootstrap.
# Usage: bash scripts/setup.sh
# Goal: after this script + a fresh shell, the FULL maw-js system including the
# L3 ephemeral worktree layer (maw workon -> maw team spawn --wt --engine omx
# --exec -> maw done) works with ZERO manual config. Verify with maw-check.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOUL_REPOS=(
  maw-js
  maw-ui
  arra-oracle-v3
  arra-oracle-skills-cli
  maw-plugin-registry
  ui-oracle
)

section() { printf '\n==> %s\n' "$1"; }
warn() { printf '  ⚠ %s\n' "$1" >&2; }
ok() { printf '  ✓ %s\n' "$1"; }

backup_path() {
  local path="$1"
  if { [ -e "$path" ] || [ -L "$path" ]; } && [ ! -L "$path" ]; then
    local backup="${path}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$path" "$backup"
    ok "backed up $path -> $backup"
  fi
}

link_path() {
  local source="$1" target="$2" label="$3"
  if [ ! -e "$source" ] && [ ! -L "$source" ]; then
    warn "$label skipped; missing source: $source"; return 0
  fi
  mkdir -p "$(dirname "$target")"; backup_path "$target"
  ln -sfn "$source" "$target"; ok "$label -> $target"
}

copy_if_absent() {
  local source="$1" target="$2" label="$3"
  if [ ! -e "$source" ]; then warn "$label skipped; missing source: $source"; return 0; fi
  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ]; then ok "$label already present: $target"; return 0; fi
  cp "$source" "$target"; ok "$label seeded -> $target"
}

# Phase 0: OS detection
section "Phase 0: OS detection"
UNAME_S="$(uname -s)"; OS_FAMILY="unknown"
case "$UNAME_S" in
  Darwin) OS_FAMILY="macos" ;;
  Linux) if grep -qi microsoft /proc/version 2>/dev/null; then OS_FAMILY="wsl2"; else OS_FAMILY="linux"; fi ;;
esac
ok "detected $OS_FAMILY ($UNAME_S)"

# Phase 1: Preflight
section "Phase 1: preflight"
missing=()
for tool in git gh tmux jq; do command -v "$tool" >/dev/null 2>&1 || missing+=("$tool"); done
if command -v bun >/dev/null 2>&1; then JS_RUNTIME="bun"
elif command -v node >/dev/null 2>&1; then JS_RUNTIME="node"; command -v npm >/dev/null 2>&1 || missing+=("npm")
else JS_RUNTIME=""; missing+=("bun-or-node"); fi
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
  warn "GitHub CLI installed but not authenticated. Run: gh auth login"; exit 1
fi
GITHUB_USER="${GITHUB_USER:-$(gh api user -q .login)}"
WORKSPACE_DIR="${GALE_WORKSPACE_DIR:-$HOME/ghq/github.com/$GITHUB_USER}"
ok "tools present; JS runtime: $JS_RUNTIME"
ok "GitHub user: $GITHUB_USER"
ok "workspace: $WORKSPACE_DIR"

# Phase 2: Fork guidance
section "Phase 2: fork the upstream repositories"
cat <<'FORKS'
Fork each upstream repo into your GitHub account before cloning:
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
  dest="$WORKSPACE_DIR/$repo"; url="https://github.com/$GITHUB_USER/$repo"
  if [ -d "$dest/.git" ]; then ok "$repo already cloned"; continue; fi
  if gh repo view "$GITHUB_USER/$repo" >/dev/null 2>&1; then
    git clone "$url" "$dest"; ok "$repo cloned"
  else
    warn "$GITHUB_USER/$repo not found; fork Soul-Brews-Studio/$repo, then re-run"
  fi
done

# Phase 4: Install maw-js
section "Phase 4: install maw-js"
MAW_JS_DIR="$WORKSPACE_DIR/maw-js"
if [ -d "$MAW_JS_DIR/.git" ]; then
  if [ "$JS_RUNTIME" = "bun" ]; then (cd "$MAW_JS_DIR" && bun install && bun link); ok "maw-js linked with bun"
  else (cd "$MAW_JS_DIR" && npm install && npm link); ok "maw-js linked with npm"; fi
else
  warn "maw-js fork not cloned; skipping global link (L1/L2 layer needs this)"
fi

# Phase 5: Install the L3 engines (codex + omx) — REQUIRED for the OMX worker layer
section "Phase 5: install L3 engines (codex + omx)"
# Without these, the 'codex'/'omx' engine keys resolve to launchers that exec a
# missing binary, and L3 workers die at spawn. Install globally, idempotent.
gpkg() { # gpkg <bin> <package>
  local bin="$1" pkg="$2"
  if command -v "$bin" >/dev/null 2>&1; then ok "$bin already installed"; return 0; fi
  if [ "$JS_RUNTIME" = "bun" ]; then bun add -g "$pkg" >/dev/null 2>&1 || warn "bun add -g $pkg failed; install manually"
  else npm install -g "$pkg" >/dev/null 2>&1 || warn "npm i -g $pkg failed; install manually"; fi
  command -v "$bin" >/dev/null 2>&1 && ok "$bin installed ($pkg)" || warn "$bin still missing after install; install $pkg manually"
}
gpkg codex "@openai/codex"
gpkg omx "oh-my-codex"

# Phase 6: Put the trust-prime launchers on PATH (L3 spawn depends on these)
section "Phase 6: wire engine launchers to PATH"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
for launcher in codex-launch omx-launch; do
  link_path "$ROOT_DIR/bin/$launcher" "$LOCAL_BIN/$launcher" "$launcher"
  chmod +x "$ROOT_DIR/bin/$launcher" 2>/dev/null || true
done
case ":$PATH:" in
  *":$LOCAL_BIN:"*) ok "$LOCAL_BIN already on PATH" ;;
  *)
    for profile in "$HOME/.bashrc" "$HOME/.zshrc"; do
      [ -f "$profile" ] || continue
      if ! grep -q 'Gale-Framework: .local/bin on PATH' "$profile" 2>/dev/null; then
        printf '\n# Gale-Framework: .local/bin on PATH (engine launchers)\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$profile"
        ok "added $LOCAL_BIN to PATH in $(basename "$profile")"
      fi
    done
    warn "open a NEW shell (or: export PATH=\"\$HOME/.local/bin:\$PATH\") so launchers resolve"
    ;;
esac

# Phase 7: Symlink Claude config
section "Phase 7: symlink Claude config"
mkdir -p "$HOME/.claude"
link_path "$ROOT_DIR/claude/hooks" "$HOME/.claude/hooks" "Claude hooks"
link_path "$ROOT_DIR/claude/settings.json" "$HOME/.claude/settings.json" "Claude settings"
link_path "$ROOT_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md" "Claude doctrine"
link_path "$ROOT_DIR/claude/doctrine" "$HOME/.claude/doctrine" "Claude doctrine fragments"
link_path "$ROOT_DIR/claude/skills" "$HOME/.claude/skills" "Claude skills"

# Phase 8: Seed Codex config (copy so you fill in your own values; never a symlink to .example)
section "Phase 8: seed Codex config"
mkdir -p "$HOME/.codex"
copy_if_absent "$ROOT_DIR/codex/config.toml.example" "$HOME/.codex/config.toml" "Codex config (edit it with your values)"
link_path "$ROOT_DIR/codex/agents" "$HOME/.codex/agents" "Codex agents"
link_path "$ROOT_DIR/codex/prompts" "$HOME/.codex/prompts" "Codex prompts"

# Phase 9: Seed maw config + tmux config — THE engine map for L3
section "Phase 9: seed maw + tmux config"
mkdir -p "$HOME/.config/maw"
# maw loads ~/.config/maw/maw.config.json — seed it from the example so the
# codex/omx/codex-resume/omx-resume engine keys are present (no silent fallback).
copy_if_absent "$ROOT_DIR/maw/maw.config.example.json" "$HOME/.config/maw/maw.config.json" "maw config (engine map)"
link_path "$ROOT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf" "tmux config"

# Phase 10: Seed fleet roster
section "Phase 10: seed fleet roster"
mkdir -p "$HOME/.maw/fleet"
copy_if_absent "$ROOT_DIR/fleet/projects.yaml" "$HOME/.maw/fleet/projects.yaml" "fleet projects"

# Phase 11: Optional pm2
section "Phase 11: optional pm2 setup"
if command -v pm2 >/dev/null 2>&1 && [ -f "$ROOT_DIR/ecosystem.config.cjs" ]; then
  pm2 start "$ROOT_DIR/ecosystem.config.cjs" && pm2 save && ok "pm2 started + saved"
else
  warn "pm2 or ecosystem.config.cjs absent; skipping (maw serve can run standalone)"
fi

# Phase 12: Verify the full L3 layer
section "Phase 12: verify (maw-check)"
if [ -x "$ROOT_DIR/scripts/maw-check.sh" ] || [ -f "$ROOT_DIR/scripts/maw-check.sh" ]; then
  bash "$ROOT_DIR/scripts/maw-check.sh" || warn "maw-check reported gaps — see ✗ items above. Open a NEW shell and re-run: bash scripts/maw-check.sh"
else
  warn "scripts/maw-check.sh missing; cannot self-verify"
fi

cat <<CHECKLIST

Final checklist:
  1. Open a NEW shell so linked commands + PATH refresh.
  2. Re-run the verifier: bash scripts/maw-check.sh   (expect all ✓)
  3. Smoke the L3 layer:
       maw workon <your-repo> test-slice
       # in the L2 pane: maw team spawn test-team w1 --wt --engine omx --exec --prompt "echo hello"
       # then: maw done <window>
  4. If launchers are 'not found', your shell PATH has not refreshed — open a new terminal.

Gale-Framework setup complete. The L3 ephemeral worktree layer is configured.
CHECKLIST
