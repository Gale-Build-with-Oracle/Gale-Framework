#!/bin/bash
# Claude Code UserPromptSubmit hook: detect image in clipboard, save + inject path.
# Adds ~50ms when no image (wl-paste -l check only). ~2s when image found (PowerShell save).
# Only runs on WSL2.

grep -q microsoft /proc/version 2>/dev/null || exit 0

# Fast check: does clipboard have an image?
has_image=0
if wl-paste -l 2>/dev/null | grep -qE "image/(png|jpeg|jpg|gif|webp|bmp)"; then
  has_image=1
elif powershell.exe -NoProfile -NonInteractive -Command 'Add-Type -AssemblyName System.Windows.Forms; if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) { exit 1 }' 2>/dev/null; then
  has_image=1
fi

[ "$has_image" -eq 0 ] && exit 0

# Save it
path=$(ss 2>/dev/null)
[ -z "$path" ] || [ ! -s "$path" ] && exit 0

echo "[clipboard-image] Saved clipboard image to: $path — use Read tool to view it."
