#!/usr/bin/env bash
# maw-check.sh — verify the FULL maw-js system + L3 ephemeral worktree layer
# works after Gale-Framework setup, with ZERO manual config.
#
# Run any time:  bash scripts/maw-check.sh
# Exit 0 = all critical checks pass; exit 1 = at least one critical failure.
#
# The L3 worktree layer (maw workon -> maw team spawn --wt --engine omx --exec
# -> maw done) depends on a chain of pieces. A silent gap in any one of them
# makes OMX workers fall back to Claude or fail to spawn. This script surfaces
# every gap explicitly instead of letting it fail at sprint time.

GRN='\033[1;32m'; RED='\033[1;31m'; YLW='\033[1;33m'; RST='\033[0m'
pass=0; fail=0; warn=0
ok()   { printf "  ${GRN}✓${RST} %s\n" "$1"; pass=$((pass+1)); }
bad()  { printf "  ${RED}✗${RST} %s\n" "$1"; fail=$((fail+1)); }
note() { printf "  ${YLW}!${RST} %s\n" "$1"; warn=$((warn+1)); }
sect() { printf "\n== %s ==\n" "$1"; }

# maw loads ~/.config/maw/maw.config.json AND numbered variants maw.config.<N>.json
# (the numbered variants layer on top). Resolve whichever file actually carries
# the engine map so this check matches real maw behavior, not just the base name.
resolve_maw_cfg() {
  local dir="$HOME/.config/maw" f
  for f in "$dir"/maw.config.json "$dir"/maw.config.*.json; do
    [ -f "$f" ] || continue
    if jq -e '.commands' "$f" >/dev/null 2>&1; then echo "$f"; return 0; fi
  done
  echo "$dir/maw.config.json"  # canonical fallback for the error message
  return 1
}
MAW_CFG="$(resolve_maw_cfg)"

sect "1. Core binaries on PATH"
for b in maw git gh tmux jq; do
  if command -v "$b" >/dev/null 2>&1; then ok "$b"; else bad "$b NOT on PATH"; fi
done
if command -v bun >/dev/null 2>&1; then ok "bun"; elif command -v node >/dev/null 2>&1; then ok "node"; else bad "no bun/node runtime"; fi

sect "2. Engine launchers (L3 spawn depends on these)"
for b in codex-launch omx-launch; do
  if command -v "$b" >/dev/null 2>&1; then ok "$b -> $(command -v "$b")"; else bad "$b NOT on PATH — L3 workers cannot spawn"; fi
done
for b in codex omx; do
  if command -v "$b" >/dev/null 2>&1; then ok "$b engine installed"; else bad "$b NOT installed — '$b' engine key will fail to launch"; fi
done

sect "3. maw config + engine map (silent-fallback guard)"
if [ -f "$MAW_CFG" ] && jq -e '.commands' "$MAW_CFG" >/dev/null 2>&1; then
  ok "maw config present: $MAW_CFG"
  # The 4 keys whose ABSENCE causes silent fallback to the default (Claude) engine.
  for key in codex omx codex-resume omx-resume; do
    if jq -e ".commands.\"$key\"" "$MAW_CFG" >/dev/null 2>&1; then
      ok "commands.$key defined"
    else
      bad "commands.$key MISSING — '$key' workers silently fall back to Claude (the #1 L3 gotcha)"
    fi
  done
else
  bad "no maw.config*.json with a commands map under ~/.config/maw — engine map never loaded; L3 layer dead"
fi

sect "4. Claude config + fan-out hooks"
[ -e "$HOME/.claude/settings.json" ] && ok "~/.claude/settings.json" || bad "~/.claude/settings.json missing"
[ -e "$HOME/.claude/hooks/pre-guard.sh" ] && ok "pre-guard.sh hook" || bad "pre-guard.sh missing"
if [ -f "$HOME/.claude/hooks/pre-guard.sh" ] && grep -q 'strategy.json' "$HOME/.claude/hooks/pre-guard.sh" 2>/dev/null; then
  ok "fan-out gate present (strategy.json TEAM enforcement)"
else
  note "fan-out gate not detected in pre-guard.sh (TEAM self-downgrade not blocked)"
fi
[ -e "$HOME/.claude/hooks/prompt-inject.sh" ] && ok "prompt-inject.sh hook" || note "prompt-inject.sh missing (no SessionStart context injection)"

sect "5. Codex trust pre-prime (worktree workers boot without trust prompt)"
if [ -f "$HOME/.codex/config.toml" ]; then
  ok "~/.codex/config.toml present"
else
  note "~/.codex/config.toml missing — first codex/omx worker may hit an interactive trust prompt (codex-launch/omx-launch pre-prime mitigates per-cwd)"
fi

sect "6. maw-js worktree + team support"
if command -v maw >/dev/null 2>&1; then
  if maw --help 2>/dev/null | grep -qiE 'workon'; then ok "maw workon (L2 worktree spawn)"; else note "maw workon not listed in --help"; fi
  if maw --help 2>/dev/null | grep -qiE 'team'; then ok "maw team (L3 worker spawn)"; else note "maw team not listed in --help"; fi
  if maw --help 2>/dev/null | grep -qiE '(^|[^a-z])done'; then ok "maw done (teardown)"; else note "maw done not listed in --help"; fi
else
  bad "maw not on PATH — cannot verify workon/team/done"
fi

sect "7. fleet roster"
[ -e "$HOME/.maw/fleet/projects.yaml" ] && ok "fleet/projects.yaml seeded" || note "fleet/projects.yaml not seeded (single-oracle use is fine without it)"

printf "\n== Result ==\n"
printf "  ${GRN}%d passed${RST}, ${RED}%d failed${RST}, ${YLW}%d warnings${RST}\n" "$pass" "$fail" "$warn"
if [ "$fail" -eq 0 ]; then
  printf "  ${GRN}L3 ephemeral worktree layer is ready — maw workon -> team spawn --wt --engine omx -> maw done will work.${RST}\n"
  exit 0
else
  printf "  ${RED}L3 layer has gaps. Re-run scripts/setup.sh or fix the ✗ items above.${RST}\n"
  exit 1
fi
