---
installer: oracle-skills-cli v2.0.0
name: rrr
description: v2.0.0 L-SKLL | Create session retrospective with AI diary and lessons learned. Use when user says "rrr", "retrospective", "wrap up session", "session summary", or at end of work session.
---

# /rrr

> "Reflect to grow, document to remember."

```
/rrr              # Quick retro, main agent
/rrr --detail     # Full template, main agent
/rrr --dig        # Reconstruct past timeline from session .jsonl
/rrr --deep       # 5 parallel agents (read DEEP.md)
```

**NEVER spawn subagents or use the Task tool. Only `--deep` may use subagents.**
**`/rrr`, `/rrr --detail`, and `/rrr --dig` = main agent only. Zero subagents. Zero Task calls.**

---

## /rrr (Default)

### 1. Gather

```bash
date "+%H:%M %Z (%A %d %B %Y)"
git log --oneline -10 && git diff --stat HEAD~5
```

### 1.5. Read Pulse Context (optional)

```bash
cat ψ/data/pulse/project.json 2>/dev/null
cat ψ/data/pulse/heartbeat.json 2>/dev/null
```

If files don't exist, skip silently. Never fail because pulse data is missing.
Pulse data may not exist yet — the `2>/dev/null` handles this.

If found, extract:
- From `project.json`: `totalSessions`, `avgMessagesPerSession`, `sizes` (to categorize current session), `branches` (activity on current branch)
- From `heartbeat.json`: `streak.days` (momentum), `weekChange` (acceleration/slowdown), `today` (today's activity so far)

### 2. Write Retrospective

**Path**: `ψ/memory/retrospectives/YYYY-MM/DD/HH.MM_slug.md`

**WORKTREE SAFETY**: In a git worktree (`agents/` path), ψ/ is NOT a vault symlink — it's a real directory that gets deleted by `maw done`. Resolve to the MAIN repo's ψ/ first:

```bash
# Resolve ψ to main worktree (vault symlink lives there, not in agent worktrees)
_PSI_BASE="ψ"
if [[ "$(pwd)" == */agents/* ]]; then
  _MAIN_WT=$(git worktree list --porcelain 2>/dev/null | head -1 | sed 's/^worktree //')
  [ -n "$_MAIN_WT" ] && [ -d "$_MAIN_WT/ψ" ] && _PSI_BASE="$_MAIN_WT/ψ"
fi
mkdir -p "$_PSI_BASE/memory/retrospectives/$(date +%Y-%m/%d)"
```

Use `$_PSI_BASE` instead of bare `ψ` for ALL file writes in this skill (retrospectives + learnings).

Write immediately, no prompts. If pulse data was found, weave it into the narrative (don't add a separate dashboard). Include:
- Session Summary — if pulse data exists, add one line: "Session #X of Y in this project (Z-day streak)"
- Timeline
- Files Modified
- AI Diary (150+ words, first-person) — if pulse data exists, reference momentum naturally: "in a week with +X% messaging velocity" or "on day N of an unbroken streak"
- Honest Feedback (100+ words, 3 friction points)
- Lessons Learned
- Next Steps

### 3. Write Lesson Learned

**Path**: `$_PSI_BASE/memory/learnings/YYYY-MM-DD_slug.md` (uses the resolved `$_PSI_BASE` from step 2)

### 4. Oracle Sync

```
oracle_learn({ pattern: [lesson content], concepts: [tags], source: "rrr: REPO" })
```

### 5. Save

Retro files are written to the vault via `$_PSI_BASE` (resolved in step 2). In the main repo, ψ/ is a symlink to the vault. In worktrees, `$_PSI_BASE` resolves to the main repo's ψ/ so files survive `maw done`.

**Do NOT `git add ψ/`** — vault files are shared state, not committed to repos.

---

## /rrr --detail

Same flow as default but use full template:

```markdown
# Session Retrospective

**Session Date**: YYYY-MM-DD
**Start/End**: HH:MM - HH:MM GMT+7
**Duration**: ~X min
**Focus**: [description]
**Type**: [Feature | Bug Fix | Research | Refactoring]

## Session Summary
(If pulse data exists, add: "Session #X of Y in this project (Z-day streak)")
## Timeline
## Files Modified
## Key Code Changes
## Architecture Decisions
## AI Diary (150+ words, vulnerable, first-person)
(If pulse data exists, reference momentum: velocity changes, streak length)
## What Went Well
## What Could Improve
## Blockers & Resolutions
## Honest Feedback (100+ words, 3 friction points)
## Lessons Learned
## Next Steps
## Metrics (commits, files, lines)
### Pulse Context (if pulse data exists)
Project: X sessions | Avg: Y msgs/session | This session: Z msgs (category)
Streak: N days | Week trend: ±X% msgs | Branch: main (N sessions)
```

Then steps 3-5 same as default.

---

## /rrr --dig

**Retrospective powered by session goldminer. No subagents.**

### 1. Run `/trace --dig`

Follow the `/trace --dig` instructions (from the trace skill) to scan Claude Code session `.jsonl` files and get the session timeline JSON.

Also gather git context:

```bash
date "+%H:%M %Z (%A %d %B %Y)"
git log --oneline -10 && git diff --stat HEAD~5
```

### 2. Write Retrospective with Timeline

Use the session timeline data to write a full retrospective using the `--detail` template. Add the Past Session Timeline table after Session Summary, before Timeline.

Also run pulse context (step 1.5 from default mode) and weave into narrative.

### 3-5. Same as default steps 3-5

Write lesson learned, oracle sync.

**Do NOT `git add ψ/`** — vault files are shared state, not committed to repos.

---

## /rrr --deep

Read `DEEP.md` in this skill directory. Only mode that uses subagents.

---

## Rules

- **NO SUBAGENTS**: Never use Task tool or spawn subagents (only `--deep` may)
- AI Diary: 150+ words, vulnerability, first-person
- Honest Feedback: 100+ words, 3 friction points
- Oracle Sync: REQUIRED after every lesson learned
- Time Zone: GMT+7 (Bangkok)
