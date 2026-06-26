---
name: doall-pending-task
description: 'Autonomously execute ALL pending tasks — harvest session-level pending (recap Next? lists, watch items, open asks) and route each, then housekeeping: commit untracked ψ/ files, check inbox, trigger auto-rebuilds after recent merges, push, and report results.'
---

# /do-all-pending-task

Autonomous pending-task executor for ANY oracle. Housekeeping is DONE without asking; session-level pending is ROUTED — executed when cheap+safe, reported with a one-line ask when dispatch-scale. Silently dropping a known pending item is the failure mode this skill MUST prevent.

## Philosophy

Principle 3 (External Brain, Not Command) — surface and resolve what's obviously pending so Wind doesn't have to manage housekeeping. Ambiguous or risky → report it with a route, don't act.

## Step 0: Harvest SESSION pending (MANDATORY FIRST)

"Pending" is NOT just git state. Before any housekeeping, enumerate every open item from the live session:

- the most recent recap / "Next?" list in this conversation
- watch items declared this session (monitors, follow-ups, in-flight reviews)
- questions you asked the human that are still unanswered
- DONE pings or briefs received but not fully closed out

Route each item — every one lands in exactly one bucket:

| Bucket | Rule |
|---|---|
| **DO NOW** | cheap + safe + read-mostly (a verify, a `maw capture`, a status check) — execute in this run |
| **ASK** | dispatch-scale (sprint, workon, cross-oracle, merge) — one-line ask; NEVER auto-dispatch |
| **WATCHING** | blocked on others — name who/what unblocks it |

The final report MUST include this session-pending table. An empty table MUST mean "I checked and found none", never "I skipped Step 0".

## Execution Sequence (housekeeping)

Run in order. Each step is independent — if one fails, continue.

### Step 1: Commit untracked ψ/ files

FIRST verify ψ is a real directory: `ls -ld ψ`. If ψ is a SYMLINK (vault), SKIP this step — vault files are shared state, never committed from a repo.

```bash
git status --short | grep '^?? ψ/'
```

If there are untracked ψ/ files (learnings, retros, inbox, handoffs):
1. Stage by explicit path (`git add ψ/inbox/ ψ/memory/...` — `git add -A` is hook-blocked)
2. Also include MODIFIED tracked ψ/ files (e.g. session-metrics.md) — half-committed brain state is worse than none
3. Commit message by content type: `brain: capture <inbox|learnings|retros> from <date range>`
4. Identity: `Co-Authored-By: <YOUR oracle name>` — name ONLY. Never an email, never another oracle's name, never "Claude Code".

**Do NOT commit**: `.env`, credentials, or files outside ψ/.

### Step 2: Check and process inbox

```bash
ls -t ψ/inbox/*.md 2>/dev/null | head -5
```

- Task briefs → report as "ready to start" — do NOT auto-start
- Messages from other oracles → confirm each was actioned this session; unactioned → into the Step 0 table
- Handoff notes → report as context available

### Step 3: Check for needed rebuilds (container-owning oracles ONLY)

Skip entirely when this oracle owns no containers. Otherwise: a merge in the last hours + the corresponding container running a stale image → rebuild on THIS machine only. Never rebuild on a remote host.

```bash
git log --all --oneline --since="4 hours ago" --grep="Merge pull request" 2>/dev/null
docker ps --format '{{.Names}} {{.Image}} {{.Status}}' 2>/dev/null
```

If a merge happened recently and the corresponding container is running an old image:
- Run the rebuild: `docker compose -f <path> up -d --build <service>`

### Step 4: Check for stale branches

```bash
git branch --merged main | grep -v '^\*\|main' 2>/dev/null
```

Report stale branches but do NOT delete without confirmation.

### Step 5: Push if ahead of remote

```bash
git status -sb | head -1
```

If the branch is ahead of origin after committing ψ/ files, push.

## Output Format

After completing all steps, report:

```
## Done

| Step | Action | Result |
|------|--------|--------|
| ψ/ commit | Committed N files | ✓ hash |
| Inbox | N items | actioned/reported |
| Rebuilds | ... or N/A | ✓ |
| Branches | N stale | listed |
| Push | Pushed to origin | ✓ |

## Session pending (Step 0)

| Item | Bucket | Status |
|------|--------|--------|
| ... | DO NOW / ASK / WATCHING | done ✓ / awaiting your call / blocked on X |
```

Closing line MUST be scoped: `Housekeeping clear. Session: X done, Y awaiting your call, Z watching.`
You MUST NOT output "Nothing left pending" unless BOTH tables are empty — a recap "Next?" list one message up while claiming "nothing pending" is a false report.

If genuinely nothing in either table: `All clear — nothing to do.`

## Safety Rules

- NEVER commit files outside ψ/ without explicit request
- NEVER commit through a ψ vault symlink
- NEVER delete branches
- NEVER rebuild on a remote machine
- NEVER auto-start task briefs or auto-dispatch sprints/workons — only report them
- NEVER force-push
- If unsure about any action, report it instead of doing it
