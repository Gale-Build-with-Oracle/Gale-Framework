#!/usr/bin/env bash
# prompt-inject.sh — Unified UserPromptSubmit + SessionStart hook
# Replaces: search-before-answer.sh, sop-enforce.sh, discord-wake-inbox.sh,
#           workflow-reminder.sh, spawn-inject.sh
#
# Claude Code injects ugrep as grep — breaks regex patterns with --flag-like strings
unset -f grep 2>/dev/null
# Takes event name from $1 (SessionStart or UserPromptSubmit)
# Outputs JSON additionalContext

set -uo pipefail

# Source registry-derived guard patterns (product list from fleet/projects.yaml)
_GUARD_PATTERNS="$HOME/.config/git/hooks/_generated-patterns.sh"
[ -f "$_GUARD_PATTERNS" ] && . "$_GUARD_PATTERNS"

EVENT="${1:-UserPromptSubmit}"
PARTS=()

# ─── SESSION START ──────────────────────────────────────────────────
if [ "$EVENT" = "SessionStart" ]; then
  # Workflow reminder
  PARTS+=("⚡ Workflow Reminder (3-layer ephemeral — Your Name directive 2026-06-13):\n  Product CR/BUG → gh issue create → maw workon <repo> <slug> (L2 spawns IN the project worktree) → L2 routes STRATEGY: SOLO|TEAM (TEAM → ephemeral OMX workers via maw team spawn --wt --engine omx --exec) → aggregate → ONE consolidated PR (Closes #N) → maw team shutdown → DONE-ping L1 → L1 /scrutinize → merge → Docker rebuild → L1 maw done <window> from OUTSIDE\n  Infra fix → L1 inline (lightweight lane) or maw workon for isolation\n  Claude LEADS (L1 + L2 orchestrator), OMX CODES (ephemeral L3). gh issues canonical — Linear mirrors automatically, never hand-create Linear issues.\n  ❌ No multi-project from one window\n  ❌ No cd to ghq paths directly\n  ❌ Secrets in .env only, never hardcode")

  # code-review-graph enforcement — if this repo has a graph, reviews/exploration
  # MUST go through it (Your Name directive 2026-06-12: graph review is the default,
  # hook-enforced not advisory). Cheap check: directory existence only.
  CRG_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  if [ -d "$CRG_ROOT/.code-review-graph" ]; then
    PARTS+=("📊 CODE-REVIEW-GRAPH ACTIVE in this repo. MANDATORY for /scrutinize + code exploration: use the code-review-graph MCP tools FIRST (get_minimal_context → detect_changes/get_impact_radius, detail_level=\"minimal\", ≤5 graph calls) BEFORE any full-file Read sweep. Full-corpus reads in a graph-enabled repo = token waste = doctrine violation.")
  fi

  # Ghost respawn-job guard — failed daemon jobs spray inert panes into the active tmux window (my-oracle#34)
  JOBS_DIR="${CLAUDE_JOBS_DIR:-$HOME/.claude/jobs}"
  if [ -d "$JOBS_DIR" ]; then
    STATE_FILES=("$JOBS_DIR"/*/state.json)
    if [ -e "${STATE_FILES[0]:-}" ]; then
      PURGED_JOBS=0
      PURGE_DIR=""
      for STATE_FILE in "${STATE_FILES[@]}"; do
        JOB_STATE=$(jq -r '.state // empty' "$STATE_FILE" 2>/dev/null || true)
        if [ "$JOB_STATE" = "failed" ]; then
          if [ -z "$PURGE_DIR" ]; then
            PURGE_DIR="/tmp/claude-failed-jobs-$(date +%Y%m%d)"
            mkdir -p "$PURGE_DIR"
          fi
          JOB_DIR=$(dirname "$STATE_FILE")
          JOB_NAME=$(basename "$JOB_DIR")
          TARGET_DIR="$PURGE_DIR/$JOB_NAME"
          if [ -e "$TARGET_DIR" ]; then
            TARGET_DIR="$PURGE_DIR/${JOB_NAME}-$(date +%H%M%S)-$$-$PURGED_JOBS"
          fi
          mv "$JOB_DIR" "$TARGET_DIR" && PURGED_JOBS=$((PURGED_JOBS + 1))
        fi
      done
      if [ "$PURGED_JOBS" -gt 0 ]; then
        PARTS+=("🧹 GHOST GUARD: purged ${PURGED_JOBS} failed respawn job(s) to ${PURGE_DIR} — these spray inert panes into the active window (issue #34)")
      fi
    fi
  fi

  # Spawn context injection
  ORACLE_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  SPAWN_FILE=""
  for candidate in "$ORACLE_ROOT/ψ/memory/spawn-context.md" "$(pwd)/ψ/memory/spawn-context.md"; do
    [ -f "$candidate" ] && SPAWN_FILE="$candidate" && break
  done
  if [ -n "$SPAWN_FILE" ]; then
    FILE_MTIME=$(stat -c %Y "$SPAWN_FILE" 2>/dev/null || stat -f %m "$SPAWN_FILE" 2>/dev/null || echo 0)
    FILE_AGE=$(( $(date +%s) - FILE_MTIME ))
    if [ "$FILE_AGE" -lt 604800 ]; then
      CONTEXT=$(cat "$SPAWN_FILE")
      PARTS+=("$CONTEXT")
    fi
  fi

  # Sync Claude skills → Codex (creates missing symlinks only, <10ms)
  bash "$HOME/.claude/scripts/sync-skills-to-codex.sh" >/dev/null 2>&1 || true

  # Retro extract injection
  RETRO_SCRIPT="$HOME/.claude/hooks/retro-extract.sh"
  if [ -f "$RETRO_SCRIPT" ]; then
    bash "$RETRO_SCRIPT" 2>/dev/null || true
  fi

  # PR queue drain reminder — surface pending reviews from crashed workers
  PRQUEUE="$HOME/.maw/pr-queue.jsonl"
  if [ -s "$PRQUEUE" ]; then
    PENDING=$(grep -c '"pending"' "$PRQUEUE" 2>/dev/null || echo 0)
    if [ "$PENDING" -gt 0 ]; then
      PARTS+=("🔴 PR QUEUE: ${PENDING} pending PR(s) from worker DONE-pings awaiting review+merge. Run 'maw fleet pr-queue' and drain FIRST before accepting new work.")
    fi
  fi

  # Federation inbox — surface-then-ack (kills the phantom "N unread" pileup).
  # Live pings now auto-mark read on delivery (maw-js comm-send 57805ffb); this
  # catches the residual case — messages that arrived while the pane was DOWN
  # (read:false, never live-delivered). Surface every unread subject into context
  # FIRST (nothing hidden), THEN flip read:false→true in place (file kept on disk,
  # Principle 1 — Nothing is Deleted). SAFE: this inbox is oracle↔oracle/cron
  # federation only; Your Name-the-human's directives arrive via the Claude chat, never
  # via maw inbox. awk rewrite (frontmatter-scoped, ~1ms/file) keeps it well inside
  # the SessionStart timeout even on a first-wake backlog.
  INBOX_DIR="$ORACLE_ROOT/ψ/inbox"
  if [ -d "$INBOX_DIR" ]; then
    INBOX_DIGEST=""
    INBOX_N=0
    READ_AT=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      from=$(sed -n 's/^from:[[:space:]]*//p' "$f" | head -1)
      subj=$(awk 'body&&NF{print;exit} /^---[[:space:]]*$/{d++} d==2{body=1}' "$f" | cut -c1-70)
      INBOX_DIGEST="${INBOX_DIGEST}\n  • [${from:-unknown}] ${subj}"
      # Ack in place: within frontmatter only, flip the first read:false → read:true
      # and stamp readAt. Temp-file + mv so a kill mid-write can't corrupt the .md.
      awk -v ts="$READ_AT" '
        /^---[[:space:]]*$/ { d++; print; next }
        d==1 && !done && /^read:[[:space:]]*false[[:space:]]*$/ { print "read: true"; print "readAt: " ts; done=1; next }
        { print }
      ' "$f" > "$f.acktmp" 2>/dev/null && mv "$f.acktmp" "$f" 2>/dev/null
      INBOX_N=$((INBOX_N + 1))
    done < <(grep -lE '^read: false[[:space:]]*$' "$INBOX_DIR"/*.md 2>/dev/null | sort)
    if [ "$INBOX_N" -gt 0 ]; then
      PARTS+=("📬 ${INBOX_N} federation inbox message(s) surfaced + auto-acked at wake (bodies kept in ψ/inbox/, re-read with 'maw inbox show'):${INBOX_DIGEST}")
    fi
  fi
fi

# ─── USER PROMPT SUBMIT ────────────────────────────────────────────
if [ "$EVENT" = "UserPromptSubmit" ]; then
  # Search-before-answer reminder
  PARTS+=("MANDATORY: Your FIRST action on any task MUST be arra_search(). Search Oracle knowledge base BEFORE reading files, editing code, or answering. No exceptions — even for simple fixes. Skip = repeat known mistakes.")

  # Stale codex pane detection — enforce cleanup before new work
  if [ -n "${TMUX:-}" ]; then
    WINDOW=$(tmux display-message -p '#{window_index}' 2>/dev/null || echo "")
    SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "")
    LEADER_PANE=$(tmux display-message -p '#{pane_index}' 2>/dev/null || echo "")
    if [ -n "$WINDOW" ] && [ -n "$SESSION" ]; then
      # Count only IDLE non-leader panes (bare shell = finished/zombie worker).
      # Panes running an agent process (claude/codex/node/python) are ACTIVE tile
      # workers — the doctrinal fan-out — and must NOT trigger the warning (my-oracle#30).
      IDLE_PANES=$(tmux list-panes -t "${SESSION}:${WINDOW}" -F '#{pane_index} #{pane_current_command}' 2>/dev/null \
        | awk -v leader="$LEADER_PANE" '$1 != leader && $2 ~ /^(bash|zsh|sh|dash)$/' | wc -l | tr -d ' ')
      if [ "$IDLE_PANES" -gt 0 ]; then
        PARTS+=("🛑 STALE PANES: ${IDLE_PANES} idle non-leader pane(s) sitting at a bare shell in this window (active agent panes are fine). BEFORE any new work: (1) DONE-ping L1 if you have results to report. (2) a project worker mid-task at its engine prompt is fine — only bare-shell (dead) panes count. (3) list panes with 'maw tmux ls', kill each stale non-leader with 'maw tmux kill <session:window.pane>'. (4) /rrr if session had meaningful work. Do NOT start new tasks until cleanup completes.")
      fi
    fi
  fi

  # SOP enforcement
  REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
  if [ -n "$REPO_ROOT" ]; then
    REPO_NAME=$(basename "$REPO_ROOT")
    SOP="" EXTRA="" FRONTEND_SOP=""
    if type is_hook_blocked >/dev/null 2>&1 && is_hook_blocked "$REPO_NAME"; then
      SOP="/sop-delegation"
      EXTRA="Product repo: PR required (push-to-main hook-blocked) — L1 runs /scrutinize → merge (L1 is the only reviewer). Bug? /debug-mantra FIRST. After bug fix: /post-mortem."
    elif type is_product_repo >/dev/null 2>&1 && is_product_repo "$REPO_NAME" && ! is_hook_blocked "$REPO_NAME" 2>/dev/null; then
      SOP="/sop-delegation"
      EXTRA="Product repo (permissive): direct push OK."
    fi
    # Frontend/theme SOP detection by repo family
    # Example: route repo families to a frontend/theme SOP. Replace these globs
    # with your own product naming. (Generic placeholders — no real project names.)
    case "$REPO_NAME" in
      YourProduct-*)   FRONTEND_SOP="/sop-frontend + /your-project-theme. DB → /your-db-skill." ;;
      YourSite-*)      FRONTEND_SOP="/sop-frontend + /your-site-theme." ;;
      *-erp|*-odoo)    FRONTEND_SOP="/sop-frontend (ERP/QWeb views)." ;;
    esac
    # Also detect from file presence (catches repos not in the case list)
    if [ -z "$FRONTEND_SOP" ] && [ -n "$REPO_ROOT" ]; then
      if [ -f "$REPO_ROOT/package.json" ] || [ -d "$REPO_ROOT/src/app" ] || [ -d "$REPO_ROOT/frontend" ] || [ -d "$REPO_ROOT/pages" ]; then
        FRONTEND_SOP="/sop-frontend (detected: package.json/app/frontend/pages)."
      fi
    fi
    if [ -n "$SOP" ]; then
      PARTS+=("⚡ SOP REQUIRED: ${REPO_NAME} — load ${SOP} BEFORE starting work. ${EXTRA}${FRONTEND_SOP:+ Frontend/UI work MUST load ${FRONTEND_SOP}}")
    elif [ ! -f "$REPO_ROOT/AGENTS.md" ] && [[ "$REPO_NAME" != *-oracle ]] && [[ "$REPO_NAME" != maw-* ]]; then
      PARTS+=("⚠️ NO AGENTS.md in ${REPO_NAME} — consider /sop-new-project.")
    fi
  fi

  # Worktree enforcement — DONE-ping + minor-bound escalation guard + fan-out gate
  CWD_WT=$(pwd)
  if [[ "$CWD_WT" == */agents/* ]]; then
    WT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
    if [ -n "$WT_BRANCH" ] && [ "$WT_BRANCH" != "main" ] && [ "$WT_BRANCH" != "master" ]; then
      WT_HAS_COMMITS=$(git log origin/main..HEAD --oneline 2>/dev/null | head -1)
      if [ -n "$WT_HAS_COMMITS" ]; then
        PARTS+=("🔴 YOU ARE IN A WORKTREE PANE. You MUST NOT merge PRs (hook-blocked). Your LAST action MUST be: maw hey <L1-oracle-pane> \"DONE: PR ready for /scrutinize + merge + maw done <window>\". Then STOP. Do NOT run maw done on your own window.")
      fi
    fi
    # Fan-out gate reminder: L2 MUST write strategy.json before any code edit.
    # The pre-guard BLOCKS Edit/Write when strategy=TEAM + no workers spawned.
    STRATEGY_F="$CWD_WT/.maw/strategy.json"
    if [ ! -f "$STRATEGY_F" ]; then
      PARTS+=("⚡ FAN-OUT GATE ACTIVE: you MUST write .maw/strategy.json BEFORE any code edit. Run: mkdir -p .maw && printf '{\"route\":\"SOLO|TEAM\",\"justification\":\"...\"}' > .maw/strategy.json — if route=TEAM, spawn OMX workers BEFORE coding (Edit/Write is hook-BLOCKED until workers exist). See core.md ## Fan-Out Strategy.")
    elif [ -f "$STRATEGY_F" ]; then
      ROUTE_WT=$(jq -r '.route // empty' "$STRATEGY_F" 2>/dev/null)
      if [ "$ROUTE_WT" = "TEAM" ]; then
        PARTS+=("⚡ strategy.json says TEAM — you MUST spawn OMX workers via maw team before any code edit. Edit/Write is hook-BLOCKED until workers exist. Override: printf '{\"justification\":\"...\"}' > .maw/solo-justified")
      fi
    fi
  fi

  # Discord inbox
  NAME="${CLAUDE_AGENT_NAME:-}"
  if [ -z "$NAME" ] && [ -n "${TMUX:-}" ]; then
    NAME=$(tmux display-message -p '#{window_name}' 2>/dev/null || echo '')
  fi
  if [ -n "$NAME" ]; then
    INBOX="$HOME/.oracle/inbox/${NAME}.jsonl"
    if [ -s "$INBOX" ]; then
      TEMP=$(mktemp -t "discord-inbox-${NAME}-XXXXXX")
      if mv "$INBOX" "$TEMP" 2>/dev/null; then
        EVENTS=$(cat "$TEMP")
        rm -f "$TEMP"
        if [ -n "$EVENTS" ]; then
          COUNT=$(printf '%s\n' "$EVENTS" | grep -c '.' || echo 1)
          PARTS+=("📨 Pending inbox: ${COUNT} wake event(s).\n${EVENTS}")
        fi
      fi
    fi
  fi
fi

# ─── OUTPUT ─────────────────────────────────────────────────────────
if [ ${#PARTS[@]} -eq 0 ]; then
  exit 0
fi

COMBINED=""
for part in "${PARTS[@]}"; do
  [ -n "$COMBINED" ] && COMBINED="${COMBINED}\n\n"
  COMBINED="${COMBINED}${part}"
done

jq -n --arg ctx "$COMBINED" --arg evt "$EVENT" '{
  hookSpecificOutput: {
    hookEventName: $evt,
    additionalContext: $ctx
  }
}'
