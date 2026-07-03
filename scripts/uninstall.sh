#!/bin/bash
set -euo pipefail

# Gale-Framework uninstall — removes symlinks created by scripts/setup.sh,
# restores backups if they exist (setup.sh's link_path backs up any pre-existing
# real file/dir to <path>.bak.<timestamp> before symlinking over it).

echo "Removing Gale-Framework symlinks..."

# Remove symlinks (only if they ARE symlinks — don't delete real files).
# This list must match the link_path targets in scripts/setup.sh.
for target in ~/.claude/hooks ~/.claude/settings.json ~/.claude/CLAUDE.md ~/.claude/doctrine ~/.claude/skills ~/.codex/agents ~/.codex/prompts ~/.tmux.conf; do
  if [ -L "$target" ]; then
    rm "$target"
    echo "  removed: $target"
    # Restore backup if exists
    if [ -e "${target}.bak" ]; then
      mv "${target}.bak" "$target"
      echo "  restored: ${target}.bak → $target"
    elif [ -d "${target}.bak" ]; then
      mv "${target}.bak" "$target"
      echo "  restored: ${target}.bak → $target"
    fi
  else
    echo "  skipped: $target (not a symlink)"
  fi
done

echo "Done. Gale-Framework symlinks removed."
