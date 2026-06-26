#!/usr/bin/env bash
# pre-guard.sh — Unified PreToolUse guard
# Replaces: safety-check.sh, production-db-guard.sh, workdir-guard.sh,
#           worktree-guard.sh, orchestrator-guard.sh, arra-query-guard.sh,
#           team-agents-reminder.sh

# Claude Code injects a ugrep shell function that shadows grep.
# ugrep misinterprets regex patterns containing --flag-like strings
# (e.g., --repo in a pattern becomes ugrep's own --repo flag).
# Use real grep in all hooks.
unset -f grep 2>/dev/null
#
# Exit 2 = block, Exit 0 = allow

set -uo pipefail

RED='\033[1;31m'
YLW='\033[1;33m'
RST='\033[0m'

# Source registry-derived guard patterns (defines is_hook_blocked / is_product_repo
# from fleet/projects.yaml). This is the SAME file git-guard + prompt-inject source.
_GUARD_PATTERNS="$HOME/.config/git/hooks/_generated-patterns.sh"
[ -f "$_GUARD_PATTERNS" ] && . "$_GUARD_PATTERNS"

INPUT=$(cat)
if ! printf '%s' "$INPUT" | jq empty 2>/dev/null; then
  exit 0
fi
TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
[ -z "$TOOL" ] && exit 0
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# ─── ORCHESTRATOR GUARD ─────────────────────────────────────────────
# Block direct edits from gale-codex orchestrator panes
if [ -n "${TMUX_PANE:-}" ] || [ -n "${TMUX:-}" ]; then
  PANE_TITLE=$(tmux display-message -p '#{pane_title}' 2>/dev/null || true)
  if [[ "$PANE_TITLE" == *gale-codex* ]]; then
    case "$TOOL" in
      Edit|Write|MultiEdit|git-commit)
        echo -e "${RED}BLOCKED: gale-codex orchestrator must not edit/commit directly. Delegate to workers.${RST}" >&2
        exit 2 ;;
      Bash)
        if printf '%s\n' "$CMD" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+commit([[:space:]]|$)'; then
          echo -e "${RED}BLOCKED: gale-codex orchestrator must not commit directly.${RST}" >&2
          exit 2
        fi ;;
    esac
  fi
fi

# ─── WORKTREE SENDMESSAGE GATE ──────────────────────────────────────
# L2 worktree sessions are standalone — SendMessage can't reach L1.
# Block SendMessage from worktree panes and redirect to maw hey.
if [ "$TOOL" = "SendMessage" ]; then
  CWD_SM=$(pwd)
  if [[ "$CWD_SM" == */agents/* ]]; then
    _SM_TO=$(printf '%s' "$INPUT" | jq -r '.tool_input.to // ""' 2>/dev/null)
    echo -e "${RED}BLOCKED: SendMessage cannot reach L1 from a worktree session (separate tmux session).${RST}" >&2
    echo -e "${RED}Use from L2/worktree: run /rrr first, then maw hey <L1-oracle-pane> \"DONE: PR ready for /scrutinize + live proof + merge + issue close + maw done <window>. L2 RRR done.\"${RST}" >&2
    exit 2
  fi
fi

# ─── BASH SAFETY ────────────────────────────────────────────────────
if [ "$TOOL" = "Bash" ]; then
  # Strip heredoc bodies to avoid false positives on commit message content
  if printf '%s' "$CMD" | grep -qE '<<'; then
    _stripped=$(printf '%s\n' "$CMD" | perl -0777 -pe "s/<<-?['\x22]?(\w+)['\x22]?\n.*?\n([ \t]*\\1)/<<\$1\n\$2/gms" 2>/dev/null)
    [ -n "$_stripped" ] && CMD="$_stripped"
  fi

  # Block raw tmux — use maw
  TMUX_SUB=""
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*tmux[[:space:]]'; then
    TMUX_SUB=$(echo "$CMD" | grep -oE 'tmux[[:space:]]+(send-keys|send-key|capture-pane|list-windows|list-sessions|kill-window|kill-session|kill-pane|new-window|new-session|split-window|select-window|select-pane|switch-client|attach-session|attach|rename-window|resize-pane)' | awk '{print $2}' | head -1)
  fi
  if [ -n "$TMUX_SUB" ]; then
    case "$TMUX_SUB" in
      send-keys|send-key)       ALT="maw hey <target> \"msg\"" ;;
      capture-pane)             ALT="maw capture <target>" ;;
      list-windows|list-sessions) ALT="maw ls / maw panes" ;;
      kill-window|kill-pane)    ALT="maw sleep <oracle> <window>" ;;
      kill-session)             ALT="maw kill <session>" ;;
      new-window)               ALT="maw wake <oracle>" ;;
      new-session)              ALT="maw wake <oracle>" ;;
      split-window)             ALT="maw split" ;;
      select-*|switch-*|attach*) ALT="maw view <target>" ;;
      rename-window)            ALT="maw rename <target> <name>" ;;
      resize-pane)              ALT="maw zoom" ;;
      *)                        ALT="maw <equivalent>" ;;
    esac
    echo -e "${RED}BLOCKED: raw 'tmux ${TMUX_SUB}' — use maw instead. → ${ALT}${RST}" >&2
    exit 2
  fi

  # Block bun src/cli.ts — use maw binary
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*bun[[:space:]]+(run[[:space:]]+)?src/(cli|server)\.ts'; then
    echo -e "${RED}BLOCKED: Never run maw via bun src/cli.ts. Use: maw <command>${RST}" >&2
    exit 2
  fi

  # rm -rf — ALLOWED for cleanup (Wind 2026-06-05: single-source-of-truth hygiene needs it),
  # but BLOCK catastrophic targets where the delete is irreversible disaster.
  # Detect rm with both recursive+force (any short-flag order, or long flags).
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|-r[[:space:]]+-f|-f[[:space:]]+-r|--recursive[[:space:]].*--force|--force[[:space:]].*--recursive)'; then
    # Isolate the rm invocation's args (best-effort: up to the next shell separator).
    RM_SEG=$(echo "$CMD" | grep -oE 'rm[[:space:]]+-[^;&|]*' | head -1)
    RM_DANGER=0
    # / , ~ , $HOME , ${HOME} — as a whole target (bare, trailing slash, or /*)
    echo "$RM_SEG" | grep -qE '([[:space:]]|=)(/|~|\$HOME|\$\{HOME\})(/?[[:space:]]|/?$|/\*([[:space:]]|$))' && RM_DANGER=1
    # bare . / .. / *  (wipe cwd, parent, or everything in cwd)
    echo "$RM_SEG" | grep -qE '[[:space:]](\.|\.\.|\*)([[:space:]]|$)' && RM_DANGER=1
    # the user home dir by absolute path, with nothing deeper (/home/<user> , /Users/<user>)
    echo "$RM_SEG" | grep -qE '[[:space:]](/home|/Users)/[^/[:space:]]+(/?[[:space:]]|/?$|/\*([[:space:]]|$))' && RM_DANGER=1
    # top-level system dirs with no deep subpath
    echo "$RM_SEG" | grep -qE '[[:space:]](/etc|/usr|/var|/bin|/sbin|/lib|/lib64|/boot|/root|/opt|/sys|/proc|/dev|/home|/Users)(/?[[:space:]]|/?$)' && RM_DANGER=1
    if [ "$RM_DANGER" = "1" ]; then
      echo -e "${RED}BLOCKED: rm -rf on a catastrophic target (/, ~, \$HOME, a home dir, a system dir, or a bare . .. *). Delete a specific subpath instead, or mv to /tmp.${RST}" >&2
      exit 2
    fi
  fi

  # Block dangerous git push --force (segment-scoped: extract EVERY push segment up to the
  # next shell separator to avoid false-positives on e.g. 'git push -q && maw hey "...--force..."')
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+push'; then
    while IFS= read -r PUSH_SEG; do
      if echo "$PUSH_SEG" | grep -qE '([[:space:]]--force([[:space:]]|$)|[[:space:]]-f([[:space:]]|$))'; then
        echo -e "${RED}BLOCKED: git push --force not allowed. Use --force-with-lease if needed.${RST}" >&2
        exit 2
      fi
    done < <(echo "$CMD" | grep -oE '(^|[;&|]+)[[:space:]]*git[[:space:]]+push[^;&|]*')
  fi

  # Block reset --hard
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+reset[[:space:]]+--hard'; then
    echo -e "${RED}BLOCKED: git reset --hard not allowed. Use git stash.${RST}" >&2
    exit 2
  fi

  # Block direct push to main in NWFTH repos
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+push[[:space:]]+(origin[[:space:]]+)?main([[:space:]]|$)'; then
    EFFECTIVE_DIR=""
    if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*cd[[:space:]]+'; then
      EFFECTIVE_DIR=$(echo "$CMD" | grep -oE '(^|;|&&)[[:space:]]*cd[[:space:]]+[^[[:space:]];&|]+' | sed 's/.*cd[[:space:]]*//' | tail -1)
      EFFECTIVE_DIR="${EFFECTIVE_DIR/#\~/$HOME}"
    fi
    [ -z "$EFFECTIVE_DIR" ] && EFFECTIVE_DIR="$PWD"
    REPO_ROOT=$(git -C "$EFFECTIVE_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$EFFECTIVE_DIR")
    REPO_NAME=$(basename "$REPO_ROOT" 2>/dev/null || echo "")
    if type is_hook_blocked >/dev/null 2>&1 && is_hook_blocked "$REPO_NAME"; then
      echo -e "${RED}BLOCKED: product repo '${REPO_NAME}' requires PR flow.${RST}" >&2
      exit 2
    fi
  fi

  # Block git commit --amend
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+commit[[:space:]]+.*--amend'; then
    echo -e "${RED}BLOCKED: Never use --amend. Create a NEW commit.${RST}" >&2
    exit 2
  fi

  # Block git checkout -- (discards changes)
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+checkout[[:space:]]+--[[:space:]]'; then
    echo -e "${RED}BLOCKED: git checkout -- discards changes. Use git stash.${RST}" >&2
    exit 2
  fi

  # Block git restore .
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+restore[[:space:]]+\.'; then
    echo -e "${RED}BLOCKED: git restore . discards all changes. Use git stash.${RST}" >&2
    exit 2
  fi

  # Block git clean -f
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+clean[[:space:]]+.*-[a-zA-Z]*f'; then
    echo -e "${RED}BLOCKED: git clean -f deletes untracked files. Move to /tmp.${RST}" >&2
    exit 2
  fi

  # Block git stash drop/clear
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+stash[[:space:]]+(drop|clear)'; then
    echo -e "${RED}BLOCKED: git stash drop/clear loses work. Nothing is Deleted.${RST}" >&2
    exit 2
  fi

  # Block --no-verify
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+(commit|push)[[:space:]]+.*--no-verify'; then
    echo -e "${RED}BLOCKED: --no-verify skips safety hooks. Fix the hook issue.${RST}" >&2
    exit 2
  fi

  # Block gh pr create to non-owned repos
  ORGS_CACHE="/tmp/gh-my-orgs.txt"
  ORGS_MTIME=$(stat -c %Y "$ORGS_CACHE" 2>/dev/null || stat -f %m "$ORGS_CACHE" 2>/dev/null || echo 0)
  # GNU stat -f treats %m as a file and pollutes stdout ("File: ...") while exiting 1,
  # so the || chain can capture garbage → "File: unbound variable" in the arithmetic below.
  case "$ORGS_MTIME" in *[!0-9]*|"") ORGS_MTIME=0 ;; esac
  if [ ! -f "$ORGS_CACHE" ] || [ $(( $(date +%s) - ORGS_MTIME )) -gt 86400 ]; then
    HTTPS_PROXY="" GIT_SSL_NO_VERIFY=1 gh api user/orgs --jq '.[].login' > "$ORGS_CACHE" 2>/dev/null || true
    HTTPS_PROXY="" GIT_SSL_NO_VERIFY=1 gh api user --jq '.login' >> "$ORGS_CACHE" 2>/dev/null || true
    echo "nazt" >> "$ORGS_CACHE"
    echo "Soul-Brews-Studio" >> "$ORGS_CACHE"
  fi
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*gh[[:space:]]+pr[[:space:]]+create'; then
    REPO=$(echo "$CMD" | grep -oE -- '--repo[[:space:]]+[^[:space:]]+' | awk '{print $2}' || true)
    if [ -n "$REPO" ]; then
      ORG=$(echo "$REPO" | cut -d/ -f1)
      if ! grep -qix "$ORG" "$ORGS_CACHE" 2>/dev/null; then
        echo -e "${RED}BLOCKED: Cannot create PR to upstream repo '$REPO'. Not your org.${RST}" >&2
        exit 2
      fi
    fi
  fi

  # Block gh pr merge from worktree sessions (workers/worktree panes MUST NOT merge — L1 only)
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*gh[[:space:]]+pr[[:space:]]+merge'; then
    CWD_CHECK=$(pwd)
    if [[ "$CWD_CHECK" == */agents/* ]]; then
      echo -e "${RED}BLOCKED: worktree sessions MUST NOT merge PRs (L1 only). From L2/worktree, run /rrr first, then DONE-ping L1 instead: maw hey <L1-pane> \"DONE: PR ready for /scrutinize + live proof + merge + issue close + maw done <window>. L2 RRR done.\"${RST}" >&2
      exit 2
    fi
  fi

  # Trace-before-filing nudge (ADVISORY, never blocks) — #2596 lesson:
  # never file an issue from assumption; dig the codebase first.
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*gh[[:space:]]+issue[[:space:]]+create'; then
    echo -e "${YLW}⚡ TRACE-BEFORE-FILING: did you /trace --deep (or verify in code) before filing? Never file from assumption (#2596 — issue claimed verbs missing; all 15 were shipped).${RST}" >&2
  fi

  # Block push to Soul-Brews-Studio remotes
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+push'; then
    PUSH_REMOTE=$(echo "$CMD" | grep -oE 'git[[:space:]]+push[[:space:]]+([^[:space:]]+)' | awk '{print $3}')
    if [ -n "$PUSH_REMOTE" ] && [ "$PUSH_REMOTE" != "origin" ]; then
      REMOTE_URL=$(git remote get-url "$PUSH_REMOTE" 2>/dev/null || echo "")
      if echo "$REMOTE_URL" | grep -qi "Soul-Brews-Studio"; then
        echo -e "${RED}BLOCKED: Push to Soul-Brews-Studio. Push to 'origin' instead.${RST}" >&2
        exit 2
      fi
    fi
  fi

  # NWFTH worktree enforcement — block direct commits on main
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+commit'; then
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
    REPO_NAME=$(basename "$REPO_ROOT" 2>/dev/null || echo "")
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
    if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
      if type is_hook_blocked >/dev/null 2>&1 && is_hook_blocked "$REPO_NAME"; then
        echo -e "${RED}BLOCKED: Direct commit on main in product repo '${REPO_NAME}'. Use worktree.${RST}" >&2
        exit 2
      fi
    fi
    # Fleet-sync reminder — doctrine fragment edits must propagate fleet-wide
    if [ "$REPO_NAME" = "gale-oracle" ] || [ "$REPO_NAME" = "Wind-Framework" ]; then
      STAGED=$(git diff --cached --name-only 2>/dev/null || echo "")
      if echo "$STAGED" | grep -qE '(doctrine/(core|claude|codex)\.md|oracle-build\.sh|oracle-.*-(claude|agents)\.md)'; then
        echo -e "${YLW}⚡ DOCTRINE FILES STAGED: run \`gale-oracle/scripts/fleet-sync.sh\` after this commit to propagate to all oracles.${RST}" >&2
      fi
    fi
  fi

  # Docker compose validation
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*docker[[:space:]]+compose[[:space:]]+(up|build|create)'; then
    COMPOSE_FILE=""
    for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
      [ -f "$f" ] && COMPOSE_FILE="$f" && break
    done
    if [ -n "$COMPOSE_FILE" ] && [ -f "$COMPOSE_FILE" ]; then
      CONFIG_ERR=$(docker compose -f "$COMPOSE_FILE" config --quiet 2>&1) || {
        echo -e "${RED}BLOCKED: docker compose config validation failed: $CONFIG_ERR${RST}" >&2
        exit 2
      }
    fi
  fi

  # BLOCK: cd to product repos (L1 must use maw workon).
  # Exception: cd + docker compose (L1 rebuilds after merge per doctrine).
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*cd[[:space:]]+~/?(ghq|home/[^/]+/ghq)/github\.com/[^/]+/'; then
    _CD_TARGET=$(echo "$CMD" | grep -oE 'cd[[:space:]]+[^;&|]+' | head -1 | sed 's/^cd[[:space:]]*//' | sed "s|^~|$HOME|" | sed 's/[[:space:]]*$//')
    _CD_REPO=$(basename "$_CD_TARGET" 2>/dev/null)
    # Walk up path components to find the repo name (cd might target a subdir)
    _CD_WALK="$_CD_TARGET"
    while [ -n "$_CD_WALK" ] && [ "$_CD_WALK" != "/" ]; do
      _CD_CHECK=$(basename "$_CD_WALK")
      if type is_product_repo >/dev/null 2>&1 && is_product_repo "$_CD_CHECK"; then
        _CD_REPO="$_CD_CHECK"
        break
      fi
      _CD_WALK=$(dirname "$_CD_WALK")
    done
    if type is_product_repo >/dev/null 2>&1 && is_product_repo "$_CD_REPO"; then
      if echo "$CMD" | grep -qE 'docker[[:space:]]+compose'; then
        echo -e "${YLW}⚡ L1 docker rebuild in product repo '${_CD_REPO}' — allowed (post-merge deploy).${RST}" >&2
      else
        echo -e "${RED}BLOCKED: cd to product repo '${_CD_REPO}'. Use: maw workon ${_CD_REPO} <slug>${RST}" >&2
        exit 2
      fi
    fi
  fi

  # Warn: git branch -D
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*git[[:space:]]+branch[[:space:]]+-D[[:space:]]'; then
    echo -e "${YLW}WARNING: git branch -D force-deletes (recoverable via reflog 90d).${RST}" >&2
  fi

  # Production DB guard for SQL CLI tools
  if echo "$CMD" | grep -iqE "(sqlcmd|mssql-cli|osql).*TFCLIVE"; then
    if echo "$CMD" | grep -iqE '(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE)([^[:alnum:]_]|$)'; then
      echo -e "${RED}BLOCKED: SQL CLI write targeting TFCLIVE (production). Read-only.${RST}" >&2
      exit 2
    fi
  fi
fi

# ─── TEAM PR AGGREGATE GATE ──────────────────────────────────────────
# TEAM L2s must prove the merged aggregate actually built/tested before opening
# a PR. The edit gate above prevents TEAM from becoming hidden SOLO; this gate
# prevents an unverified TEAM aggregate from entering the L1 review queue.
if [ "$TOOL" = "Bash" ]; then
  if echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*(maw[[:space:]]+pr|gh[[:space:]]+pr[[:space:]]+create)\b'; then
    CWD_NOW=$(pwd)
    if [[ "$CWD_NOW" == */agents/* ]] && echo "$CMD" | grep -qE '(^|;|&&|\|\|)[[:space:]]*gh[[:space:]]+pr[[:space:]]+create\b'; then
      if ! echo "$CMD" | grep -qE 'REQ:[[:space:]]+(none|REQ-[A-Z][A-Z0-9]*-[0-9]+)' && ! echo "$CMD" | grep -qE -- '--body-file[[:space:]]+'; then
        echo -e "${RED}BLOCKED: direct gh pr create from a worktree must include a REQ: line in the PR body.${RST}" >&2
        echo -e "${RED}Use maw pr (auto-adds REQ: none) or pass --body with REQ: REQ-<PROJECT>-NNN / REQ: none. If using --body-file, that file must contain the REQ line.${RST}" >&2
        exit 2
      fi
    fi
    if [[ "$CWD_NOW" == */agents/* ]] && [ -f "$CWD_NOW/.maw/strategy.json" ]; then
      ROUTE=$(jq -r '.route // empty' "$CWD_NOW/.maw/strategy.json" 2>/dev/null)
      if [ "$ROUTE" = "TEAM" ] && [ ! -f "$CWD_NOW/.maw/aggregate-verified" ]; then
        echo -e "${RED}BLOCKED: TEAM strategy PR requires .maw/aggregate-verified.${RST}" >&2
        echo -e "${RED}Run aggregate lint/build/test on the merged branch, then: touch .maw/aggregate-verified${RST}" >&2
        exit 2
      fi
    fi
  fi
fi

# ─── FAN-OUT GATE (anti-#157) ───────────────────────────────────────
# When .maw/strategy.json says route:"TEAM", block code edits in L2 worktrees
# until at least one OMX worker pane exists. Doctrine claimed this gate existed
# since 2026-06-08; it didn't — L2s self-downgraded to SOLO 3+ times (leaf
# 2026-06-11, erp 2026-06-13). NOW it does.
#
# Fires on: Edit, Write, MultiEdit (code edits that build a SOLO context)
# Skips: Bash (needed for maw team spawn), Read (research is fine)
# Override: .maw/solo-justified (with justification inside)
case "$TOOL" in
  Edit|Write|MultiEdit)
    CWD_NOW=$(pwd)
    if [[ "$CWD_NOW" == */agents/* ]]; then
      STRATEGY_FILE="$CWD_NOW/.maw/strategy.json"
      if [ -f "$STRATEGY_FILE" ]; then
        ROUTE=$(jq -r '.route // empty' "$STRATEGY_FILE" 2>/dev/null)
        if [ "$ROUTE" = "TEAM" ]; then
          if [ -f "$CWD_NOW/.maw/solo-justified" ]; then
            echo -e "${YLW}⚡ FAN-OUT: strategy=TEAM but solo-justified override found. Allowing.${RST}" >&2
          else
            WORKER_COUNT=0
            if [ -n "${TMUX:-}" ]; then
              WORKER_COUNT=$(tmux list-panes -a -F '#{pane_current_path}' 2>/dev/null | grep -c "^${CWD_NOW}/agents/" || echo 0)
            fi
            if [ "$WORKER_COUNT" -eq 0 ]; then
              echo -e "${RED}BLOCKED: strategy.json says TEAM but no OMX workers spawned yet.${RST}" >&2
              echo -e "${RED}Spawn workers first: maw team create <team> + maw team spawn <team> <role> --wt --engine omx --exec${RST}" >&2
              echo -e "${RED}Override (rare): printf '{\"justification\":\"...\"}' > .maw/solo-justified${RST}" >&2
              exit 2
            fi
          fi
        fi
      fi
    fi
    ;;
esac

# ─── EDIT/WRITE GUARDS ──────────────────────────────────────────────
case "$TOOL" in
  Edit|Write|MultiEdit)
    FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

    # Workdir guard: block edits outside project
    if [ -n "$FILE_PATH" ]; then
      PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
      if [ -n "$PROJECT_ROOT" ]; then
        PROJECT_ROOT=$(realpath -m "$PROJECT_ROOT" 2>/dev/null || echo "$PROJECT_ROOT")
        FILE_ABS=$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
        HOME_ROOT=$(realpath -m "$HOME" 2>/dev/null || echo "$HOME")
        case "$FILE_ABS" in
          "$PROJECT_ROOT"/*|"$PROJECT_ROOT") ;;
          /tmp/*|/private/tmp/*|"$HOME_ROOT"/.claude/*|"$HOME_ROOT"/.*) ;;
          "$HOME_ROOT"/Library/*) ;;
          */ghq/github.com/deachawatss/*|*/ghq/github.com/vibe-hub-co/*) ;;
          *)
            echo -e "${RED}BLOCKED: Editing outside project ($(basename "$PROJECT_ROOT")). Target: $(dirname "$FILE_ABS")${RST}" >&2
            exit 2 ;;
        esac
      fi
    fi

    # L1 PRODUCT-CODE GATE: block editing product repo files on main branch.
    # Uses the file's git context (not cwd) to catch cross-repo edits.
    if [ -n "$FILE_PATH" ]; then
      _FILE_DIR=$(dirname "$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")")
      _WALK="$_FILE_DIR"
      while [ -n "$_WALK" ] && [ "$_WALK" != "/" ] && [ ! -d "$_WALK" ]; do
        _WALK=$(dirname "$_WALK")
      done
      _FILE_REPO_ROOT=$(git -C "$_WALK" rev-parse --show-toplevel 2>/dev/null || echo "")
      if [ -n "$_FILE_REPO_ROOT" ]; then
        _FILE_REPO_NAME=$(basename "$_FILE_REPO_ROOT")
        _FILE_BRANCH=$(git -C "$_FILE_REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        if [ "$_FILE_BRANCH" = "main" ] || [ "$_FILE_BRANCH" = "master" ]; then
          if type is_product_repo >/dev/null 2>&1 && is_product_repo "$_FILE_REPO_NAME"; then
            _CWD_GATE=$(pwd)
            _FILE_ABS_GATE=$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
            _REL_SUFFIX=${_FILE_ABS_GATE#"$_FILE_REPO_ROOT"/}
            # Allow L1 to edit gitignored files (e.g. .env, .maw/) on main
            if git -C "$_FILE_REPO_ROOT" check-ignore -q "$_FILE_ABS_GATE" 2>/dev/null; then
              : # gitignored file — not tracked, safe to edit on main
            elif [[ "$_CWD_GATE" == */"$_FILE_REPO_NAME"/agents/* ]]; then
              # Session IS in a worktree of this repo — the file path is wrong (points to main copy).
              _WT_ROOT=$(echo "$_CWD_GATE" | sed "s|/\(${_FILE_REPO_NAME}/agents/[^/]*\).*|/\1|")
              echo -e "${RED}BLOCKED: File path points to main branch copy, but you're in a worktree.${RST}" >&2
              echo -e "${YLW}Use worktree path: ${_WT_ROOT}/${_REL_SUFFIX}${RST}" >&2
              exit 2
            else
              echo -e "${RED}BLOCKED: Editing product repo '${_FILE_REPO_NAME}' on main — no worktree.${RST}" >&2
              echo -e "${RED}Use: maw workon ${_FILE_REPO_NAME} <slug>${RST}" >&2
              exit 2
            fi
          fi
        fi
      fi
    fi

    # Production DB guard: block setting TFCLIVE as default in TRACKED config
    # Gitignored files (.env) are excluded — they hold legitimate connection strings
    CONTENT=$(printf '%s' "$INPUT" | jq -r '.tool_input.new_string // .tool_input.content // ""' 2>/dev/null)
    if echo "$FILE_PATH" | grep -iqE '\.(yaml|yml|env|toml|json)$'; then
      FILE_DIR=$(dirname "$FILE_PATH" 2>/dev/null)
      FILE_BASE=$(basename "$FILE_PATH" 2>/dev/null)
      IS_GITIGNORED=$(git -C "$FILE_DIR" check-ignore -q "$FILE_PATH" 2>/dev/null && echo "yes" || echo "no")
      if [ "$IS_GITIGNORED" = "no" ]; then
        if echo "$CONTENT" | grep -iqE "(database|MSSQL_DATABASE).*TFCLIVE"; then
          echo -e "${RED}BLOCKED: Cannot set TFCLIVE (production) as default database in tracked config.${RST}" >&2
          exit 2
        fi
      fi
    fi

    ;;
esac

# ─── MCP SQL GUARD ──────────────────────────────────────────────────
case "$TOOL" in
  mcp__bme-mssql*|mcp__nwfth-sql*)
    SQL=$(printf '%s' "$INPUT" | jq -r '.tool_input.sql // ""' 2>/dev/null)
    if echo "$SQL" | grep -iqE "TFCLIVE"; then
      if echo "$SQL" | grep -iqE '^[[:space:]]*(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|EXEC|MERGE|GRANT|REVOKE)([^[:alnum:]_]|$)'; then
        echo -e "${RED}BLOCKED: Write operation on TFCLIVE (production). Read-only.${RST}" >&2
        exit 2
      fi
      if echo "$SQL" | grep -iqE '^[[:space:]]*USE[[:space:]]+.*TFCLIVE'; then
        echo -e "${RED}BLOCKED: Cannot switch to production database.${RST}" >&2
        exit 2
      fi
    fi
    ;;
esac

exit 0
