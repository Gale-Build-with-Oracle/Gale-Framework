---
name: sop-maw
description: 'maw command reference + ephemeral team lifecycle + monitoring protocol + merge/cleanup. TRIGGER when: using any maw command, spawning/monitoring ephemeral OMX workers, merging PRs, cleaning worktrees, or user says "merge"/"cleanup"/"maw done"/"team spawn". DO NOT TRIGGER for: CR routing & task-brief writing (→ /sop-delegation), in-session subagent teams (→ /team-agents), QA audits (→ /sop-qa).'
---
# /sop-maw — maw Commands, Team Lifecycle, Merge & Cleanup

Full flag reference: `maw --help` / `maw <command> --help`. Below is the non-obvious knowledge.

## The Daily Loop (adapted from The Oracle Pattern, ch.15)

```
maw wake <oracle>                 # 1. soul awakens (L1)
maw fleet pr-queue                # 2. drain pending reviews from crashed L2s
maw workon <repo> <slug>          # 3. per task: spawn the L2 IN the project worktree
                                  #    (independent issues → N PARALLEL workon L2s — core ## Fan-Out → Parallel L2s)
maw team spawn <slug> worker-N --wt --engine omx --exec --prompt "Issue #N: …"   # 4. L2 fans out ephemeral OMX workers
maw team status <slug>            # 5. monitor on ~5-min cadence
gh pr list                        # 6. review queue → /scrutinize → merge (L1 only)
maw done <window>                 # 7. cleanup — SERIALIZED, one window at a time (parallel
                                  #    maw done = shared-git lock corruption, 2026-04-12)
```

Everything flows through the oracle (single coordination path); workers run autonomous between dispatch and DONE (no check-in ceremony). No one waits on anyone. **Ephemeral is the only mode** — standing/warm pools RETIRED 2026-06-10 (a warm session idling outside a project loads the WRONG context; enter each project per-task via `maw workon`).

## Ephemeral Team Setup (sprint charters)

**Codex trust is AUTO-PRIMED** by `codex-launch`/`omx-launch` (cwd + main repo root, 2026-06-13) — no manual pre-seeding. A trust prompt appearing = the spawn bypassed the wrappers (check maw config `engines.*` does not shadow the wrapper commands).

OMX workers are spawned per-task in fresh per-project worktrees — there are no warm pools to reconcile. Two ways to fan out:

- **Direct (DEFAULT, no charter file):** `maw team create <slug>` → `maw team spawn <slug> worker-N --wt --engine omx --exec --prompt "Issue #N: …"` (one per slice, max 4) → `maw team shutdown <slug>` after the PR.
- **Charter (for a repeatable multi-worker sprint):** copy `WF/templates/team-charters/sprint.yaml` to `<worktree>/.maw/teams/sprint-<slug>.yaml` →
```bash
maw team plan .maw/teams/sprint-<slug>.yaml      # MUST print zero "unsupported key" warnings
maw team preflight .maw/teams/sprint-<slug>.yaml # collision/governance checks
maw team load .maw/teams/sprint-<slug>.yaml --no-spawn   # REQUIRED: registers team — without it `maw team status` says "team not found"
maw team up <slug>                                # spawn; re-run until all members live
```
Charters are ephemeral — torn down by `maw done` / `maw team shutdown`.

**Reconciliation states** (`maw team up` classifies every member each run):

| State | Meaning | Action taken |
|---|---|---|
| `live` | engine running (CMD=`node` for omx) | skip — never touched |
| `dead` | pane exists, engine exited (CMD=`bash`) | resume IN PLACE via `commands.<engine>-resume` — worktree + branch survive |
| `missing` | no pane | fresh wake (new window + worktree) |
| `skipped` | `node:` guard or `--only` filter | skip |

**Charter resolution order**: `.maw/teams/<t>.yaml` → `ψ/teams/<t>.yaml` → `.maw/<node>.yaml`, relative to the repo root of your cwd. `project: <org>/<repo>` routes WORKER worktrees into the product repo's `agents/`; the lead stays put. `node: <machine>` per member = multi-machine charters from one file.

**Parser is a YAML SUBSET — these WILL silently break a charter:**
- NO `defaults:` block — unknown top-level keys are silently ignored → workers spawn WITHOUT worktrees (shared cwd, the maw-tile bug class). Set `worktree: true` PER worker.
- NO YAML anchors (`&x`/`*x`) — literal text. Repeat prompt blocks per member.
- Lead members are special-cased (`keep (lead)`) — NOT auto-spawned by `team up`; the lead pane is your existing `maw workon` L2 pane.

**Spawn-loop gotchas (observed)**:
- Auto-kickoff is the delivery path for OMX/Codex workers: `--prompt` writes the spawn-prompt file and maw delivers the kickoff once the composer is ready. Do NOT manually re-send large briefs unless spawn prints the explicit "composer not ready after 50s" recovery command.
- A worker with CMD=`bash` is dead — re-spawn (`maw team spawn`) or reconcile (`maw team up <team>`). A live OMX worker usually shows CMD=`node`; use `maw peek`/`capture` to confirm real work on ambiguity.
- Resume requires `omx-resume`/`codex-resume` keys in the maw config commands map. Missing key → dead OMX worker silently relaunches as **Claude** (`commands.default` fallback).

## Monitoring Protocol (replaces serial capture polling)

1. **Post-brief sweep** (MANDATORY, immediately after last brief): `maw team status <team>` is the coarse table; for OMX, `idle`/ambiguous status is not truth. Confirm suspicious workers with `maw peek <member>` or one `maw capture <member> --lines 40`. `dead` (CMD=`bash`) → re-spawn (`maw team spawn`) or `maw team up <team>` to reconcile.
2. **Cadence**: `maw team status <team>` every ~5 min until all DONE. One command, all workers, minimal context.
3. **`maw capture <member> --lines 40` ONLY on anomaly** — status dead/stuck/missing/idle-while-expected-working, or no commit past the expected window.
4. DONE arrives by `maw hey` push; the status poll is the backstop, not the channel.

**Anti-patterns (all from real failures):**
- **Serial capture polling** — ~15 manual `maw capture` calls per sprint (observed 2026-06-08) burned orchestrator context for zero signal. Use `team status`.
- **`maw team bring --gather`** — NOT adopted: on team v2.1.0 it enumerates role+name duplicates (6 wake targets for 3 members) and tries to wake unresolvable names (verified 2026-06-10 dry-run).
- **`defaults:` block in a charter** — workers spawned without worktree isolation.
- **Missing `omx-resume` config key** — dead OMX worker resumed as Claude, silently.
- **Standing/warm pools** — RETIRED 2026-06-10; a warm session idling outside a project loads the WRONG context. Spawn fresh ephemeral workers per task.
- **`maw tile`** — RETIRED 2026-06-07 after 6 recurring problem classes; all fan-out uses `maw team`.

## Multi-Agent Tier Selection

| Tier | When | Tool | Survives? |
|------|------|------|-----------|
| **0 — `maw team spawn`** | Ephemeral parallel coding (the L3 default) | `maw team spawn <team> <role> --wt --engine omx --exec --prompt "…"` | Yes (until shutdown) |
| **1 — Agent tool** | 2-5 parallel reads/debates, <5 min | `Agent({subagent_type})` | No |
| **2 — `/team-agents`** | In-session coordinated research/review | TeamCreate + SendMessage | No |
| **3 — `maw workon` / `maw wake`** | >30 min, overnight, cross-machine | `maw workon <repo> <slug>` | Yes |

Prefer the lowest tier that works. Structured coordination → `/team-agents`; raw parallel → `maw team`; cross-session → `workon`/`wake`; quick research → Agent tool.

## Quality Rules

- Split ownership BEFORE spawning — two writers on the same files conflict.
- Every worker brief: exact repo path, issue #, write scope, verify step, report expectation.
- `arra_search` before any work — include in every worker prompt.
- NWFTH work still needs worktree + `/sop-qa` + `/scrutinize` before merge — multi-agent doesn't bypass the pipeline.
- Aggregate gate: lint/build/test green on the merged branch → `touch .maw/aggregate-verified` → THEN `maw pr` (hook-blocked without the marker when `.maw/strategy.json` route is TEAM).
- REQ traceability: `maw pr` always writes a PR body with `REQ: none` by default. For feature/behavior PRs, set `MAW_PR_REQ='REQ-<PROJECT>-NNN[, REQ-<PROJECT>-MMM]'` or write `.maw/req-line` before running `maw pr`; invalid REQ values fail before `gh pr create`.
- `maw done <window>`: MUST target a window DIFFERENT from the caller.
- Self-diagnostic before STUCK: `maw capture <self-window> --lines 50`, paste last 20 lines.

## NEVER Raw tmux / ps / kill

| Instead of | Use |
|---|---|
| `tmux send-keys` | `maw send` / `maw run` / `maw hey` |
| `tmux capture-pane` | `maw capture` / `maw peek` |
| `tmux list-sessions/windows` | `maw ls` / `maw panes` |
| `tmux kill-window/pane` | `maw kill` / `maw tmux kill <target>` |
| `tmux split-window` | `maw split` / `maw team spawn` |
| `tmux resize-pane -Z` | `maw zoom` |
| `tmux join-pane / break-pane` | `maw open` / `maw close` |
| `tmux rename-window` | `maw rename` |
| `tmux attach-session` | `maw attach` / `maw a` |
| `ps aux \| grep \| kill` | `maw cleanup --zombie-agents --fix` |

## Commands by Workflow Phase

### Session start
`maw health` · `maw preflight` · `maw doctor --fix` · `maw overview` · `maw ls [-v|-a]` · `maw locate <oracle>` · `maw costs` · `maw whoami` · `maw snapshots`

### Starting work
| Task | Command |
|---|---|
| Start worktree (L2) | `maw workon <repo> <slug>` |
| Wake an oracle | `maw wake <oracle> [--task "..."]` |
| Assign GitHub issue | `maw assign --issue N <oracle>` |
| Auto-route by domain | `maw dispatch "task"` |

### Team & communication
| Task | Command |
|---|---|
| Spawn ephemeral worker | `maw team spawn <team> <role> --wt --engine omx --exec` |
| Charter parse / checks / register | `maw team plan <file>` / `preflight <file>` / `load <file> --no-spawn` |
| Status (monitoring core) | `maw team status <team>` |
| Reassign wedged member | `maw team reassign <member> '#issue'` |
| Crash recovery | `maw team resume <team>` |
| Message (signed + inbox) | `maw hey <target> "msg"` (= `maw send`) |
| Type text + Enter (no envelope) | `maw run <target> "text"` / `maw send-text` |
| Enter only (stuck composer) | `maw send-enter <target> [--N 3]` |
| Persistent thread | `maw talk-to <oracle>` |
| Broadcast all agents | `maw broadcast "msg"` |

### Monitoring
`maw team status <team>` (primary) · `maw capture <target> --lines N` (anomaly only) · `maw peek <target>` (visual last-resort) · `maw panes` · `maw bg '<cmd>'` (long builds)

### Finishing
| Task | Command |
|---|---|
| Open PR | `maw pr` |
| Shutdown team (MANDATORY after every batch) | `maw team shutdown <team>` (from the L2 pane that created it) |
| Clean worktree + rrr | `maw done <window>` (L1, from OUTSIDE the window) |
| Zombie panes | `maw cleanup --zombie-agents [--fix]` |
| Park / resume | `maw park <agent>` / `maw resume <agent>` |

### Fleet & federation
`maw fleet doctor [--fix]` · `maw bud <name> --dry-run` · `maw soul-sync` · `maw signals` · `maw oracle ls/scan/fleet` · `maw federation` / `maw ping` / `maw peers` / `maw pair` · `maw t oracle-invite <oracle> --team <T>` (cross-machine; trust is scope-bound — a `hey` trust does NOT permit `team-invite`)

### Infrastructure
`maw on <event> "<action>"` (session-scoped triggers) · `maw triggers` · `maw restart` · `maw check` · `maw ui` · config-file triggers in `~/.config/maw/maw.config.50.json` for persistent fleet-wide

## Merge & Cleanup Lifecycle

### Merge Gate

**The owning oracle's L1 pane runs `/scrutinize` and merges — worktree panes (L2) NEVER merge** (decided 2026-06-06: the L2 authored or aggregated the code; merge authority lives only in the permanent L1 pane). The L2 stops at PR(s) with `Closes #N` + DONE ping. Risk changes how hard L1 scrutinizes, NOT who merges. L1 is the only reviewer + merger (no escalation reviewer — Kati RETIRED 2026-06-11).

| PR touches | Risk | L1 action |
|-----------|------|--------|
| Frontend only · Docs only · Config (non-security) · Deps-only | Low | quick `/scrutinize` → merge → notify owner |
| Backend / API / DB / Rust / SQL · Security · Cross-boundary · P0/P1 bug | High | `/scrutinize` **harder** → merge |

Infra/oracle repo direct-push is allowed only when the permanent L1 pane authored the verified change. If an L2/worktree pane authored or aggregated it, the worktree still opens a PR + DONE-pings and the permanent L1 pane runs `/scrutinize` + merge.

### Merge checklist (L1)
1. Confirm the L2/worktree DONE-ping says `L2 RRR done` (or equivalent), or inspect the pane/worktree for a retrospective/lesson marker before cleanup; if missing, bounce back to L2 for `/rrr` before `maw done`. L3 OMX worker `/rrr` is not required in Wind-Framework; L2 aggregate `/rrr` is sufficient.
2. `/scrutinize` the PR — trace the actual code path, not just the diff.
3. Prove the requested behavior works in the target context (`VERIFIED-LIVE: <command/UI/endpoint> → <observed output>`), not only with proxy tests.
4. Verify the `/sop-qa` report via `gh pr view <URL> --comments` (product repos).
5. CI green; no conflicting in-flight work.
6. `gh pr merge --merge --delete-branch`.
7. Close linked GitHub issue(s) if GitHub did not auto-close them via `Closes #N`.
8. `/post-mortem` for bug PRs (gh issues canonical; Linear mirrors automatically).
9. `maw done <worktree-window>` — tears down the session + worktree (clean state for the next task); run only from OUTSIDE the worktree after `/rrr` + merge + issue closeout.
10. Docker rebuild + smoke test if merged code runs in a container.

### Cleanup escalation
| Level | Command | When |
|---|---|---|
| Normal | `maw done <window>` | Ephemeral worktree finished, PR merged |
| Graceful | `maw sleep <oracle> <window>` | Stop one agent |
| Team | `maw team shutdown <team> [--force\|--merge]` | Ephemeral team done (`--merge` archives findings to vault first) |
| Zombies | `maw cleanup --zombie-agents --fix` | Orphan panes |
| Nuclear | `maw stop` | ALL sessions (DANGEROUS) |

### Post-merge retro survival
The L2/worktree must finish aggregate `/rrr` (or at minimum write a concise retrospective/lesson and call `oracle_learn`) **before** it DONE-pings L1 as ready for `maw done`: PR(s) ready → L2 `/rrr` while the worktree context still exists → `maw hey <L1> "DONE: ... L2 RRR done ..."` → `mkdir -p .maw && touch .maw/done-pinged` → STOP. L1 treats L2 `RRR done` as a closeout precondition; if an AUTO-DONE ping arrives without it, L1 must inspect/bounce before cleanup. L3 OMX workers only report slice DONE to L2; L2 aggregate `/rrr` is enough for Wind-Framework. `maw done` removes the L2 worktree immediately, so retro after cleanup is impossible.

## Worktree Naming

| Thing | Pattern |
|-------|---------|
| Directory | `<oracle-repo>/agents/<N>-<slug>` |
| Branch | `agents/<N>-<slug>` |
| tmux window | `<oracle>-<slug>` |

Session: `NN-<oracle>`. Target alias: short name — `maw hey wind:leaf` routes to `02-leaf:leaf-oracle`.

## Storage Locations

```
.maw/teams/sprint-<slug>.yaml                   ← ephemeral sprint charters (worktree-local; the only kind)
~/.claude/teams/<team>/config.json              ← live registry (created by team load --no-spawn)
~/.claude/teams/<team>/inboxes/<agent>/*.json   ← per-message inbox
~/.maw/teams/<team>.jsonl                       ← append-only save/resume log
ψ/memory/mailbox/teams/<team>/manifest.json     ← durable vault identity (removed by team shutdown)
.maw/strategy.json                              ← {route,justification} — SOLO/TEAM record (escalation gate reads it)
.maw/solo-justified                             ← override marker: conscious solo-deep decision (disables the gate)
.maw/aggregate-verified                         ← marker: aggregate lint/build/test green (PR hook gate)
.maw/heartbeat.json / .maw/sprint-state.json    ← L2 crash-recovery state
```

## Event Triggers

Config file (persistent, fleet-wide): `pr_merged`, `worktree_ready`, `maw_done`, `oracle_awake` → all notify gale. Session-scoped: `maw on <oracle> idle --once "maw hey wind:gale '...'"`.

## Misc Operational Notes

- `maw bud`: always `--dry-run` first; needs `--org` / `config.githubOrg` / `$MAW_DEFAULT_ORG`.
- Reinstalling maw-js: `bun link` (not `bun install -g .`).
- pm2 + nvm migration: `pm2 save` → `pm2 kill` → `nvm use <new>` → `pm2 resurrect`.
- rtk token proxy: `rtk init -g`; `rtk gain` for analytics.
- Fleet roster: discover live via `maw ls` — never hardcode (the fleet grows).
- Web UI `http://localhost:3456/office/`; event feed `curl -s http://localhost:47778/api/feed?limit=50`.
