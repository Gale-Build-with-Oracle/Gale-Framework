---
name: sop-delegation
description: 'CR recognition → route to the right oracle → write the brief → delegate → close the lifecycle. TRIGGER when: human reports a bug/feature/change for a product repo, or says "cr", "route", "which oracle", "delegate", "task brief", "send to leaf/bamboo". DO NOT TRIGGER for: maw command help / team lifecycle / merge-cleanup (→ /sop-maw), in-session agent teams (→ /team-agents), questions or musing that are not a CR.'
---
# /sop-delegation — CR Routing & Task Delegation (any orchestrator Oracle)

## General Orchestration Pattern (ALL Oracles)

This is not Gale-only. **Any** Oracle that takes on a task follows the same shape — only the routing table below (who gets NWFTH vs SL) is Gale's head-Oracle job.

**Two roles, never collapsed into one:**

| Role | Who | Does |
|---|---|---|
| **Orchestrator** | the Oracle that owns the task (the "main oracle") | Stays in her home session. Briefs the worker, monitors, then closes: `/sop-review` → merge → `maw done`. |
| **Worker** | the Oracle (or codex) doing the build | Runs `maw workon <repo> <slug>` so the work lands in an **isolated worktree** (`maw workon` creates the worktree by default — that IS the `--wt` isolation), builds there, `/sop-qa`, `maw pr`, then reports the PR back and WAITS. |

**The rule**: normal task → the worker does it in a `maw workon` worktree at the project location, never on `main`. The orchestrator Oracle stays orchestrator **until the task is finished** — she does NOT hand off mid-flight. Close order is always: worker reports PR ready → orchestrator runs **`/sop-review`** → merges ANY tier (low or high) → **`maw done <window>`**. High risk means scrutinize harder, same merger — L1 is the only reviewer + merger (no escalation reviewer).

When orchestrator and worker are the **same** Oracle on her **own** infra/oracle repo (meta, fleet kernel, docs), she may work in the permanent L1 pane and direct-push after focused verification. If she uses `maw workon`, the worktree pane still stops at PR + DONE-ping and the permanent L1 pane merges after `/sop-review` — no worktree self-merge.

**Engine rule**: the L2 orchestrator is ALWAYS Claude (enforced in maw-js since 2026-06-05 — workon defaults to Claude regardless of caller engine). Do NOT pass `--codex`/`--engine` to the orchestrator pane; engine flags are worker-spawn-only (`maw team spawn <team> <role> --wt --engine omx --exec`). No `--claude` flag is needed.

## CR Pattern Recognition (autonomous trigger)

When Wind describes a feature/change/bug for an EXISTING project, recognize as a CR and route through SDLC chain WITHOUT asking permission. The downstream chain (dev → `/sop-qa` self-QA → PR → merge) is autonomous. **Doc conversion (md→DOCX/PPTX) is NOT part of this chain.**

**Triggers**:
| Wind says... | Parse |
|---|---|
| "hey for `<project>` I want / I need / can you / let's add / let's implement `<X>`" | CR feature |
| "for `<project>`, `<X>` doesn't / breaks / should `<Y>`" | BUG |
| "change `<X>` to `<Y>` in `<project>`" / "remove" / "instead of" | CR change/removal/replacement |

**NOT a CR** (keep conversation): "what does X do?", "explain Y", "should we maybe", "I'm thinking", "thanks/cool". If ambiguous → ASK Wind: "Reading this as a CR for `<project>` (feature: `<X>`). Confirm?"

## Project Name Resolution

| Wind says | Repo | Tier |
|---|---|---|
| bulk-picking | BME-Bulk-Picking | NWFTH |
| partial-picking | Partial-Picking | NWFTH |
| putaway | BME-Putaway | NWFTH |
| run-creation | BME-Run-Creation | NWFTH |
| HR-Leave | HR-Leave | NWFTH |
| FG-Label | FG-Label | NWFTH |
| wind-diary, blog, diary | wind-diary | SL |
| portfolio | Wind-Portfolio | SL |
| structura | STRUCTURA | SL |
| social-listening, social | Social-Listening | SL |

Unknown name → ASK before delegating.

## Routing Decision Tree

1. Confirm parse with Wind (one short sentence, blocks)
2. `gh issue create --repo deachawatss/<repo> --title "[CR|BUG] ..." --label CR|bug` — GitHub Issues is canonical. The issue number rides the PR description (`Closes #N`).

### Issue Discipline (Vertical Slices + Prefactor)

**Before creating implementation issues**, scan for prefactoring opportunities — structural improvements that make the planned changes easier. "Make the change easy, then make the easy change." Prefactors get their own issues and block the main slices.

**Issues MUST be vertical slices** — each cuts through ALL integration layers end-to-end (schema + API + UI + tests). A completed slice is demoable or verifiable on its own. Do NOT create horizontal layer issues ("add migration for X", "add API for X", "add UI for X" separately).

3. Write Task Brief at `~/ghq/github.com/deachawatss/<project>/TASK-<slug>.md` (template below)
4. Route by OWNERSHIP: **another oracle's domain** → `maw hey wind:<owner>` — NEVER `maw workon` their repo from your session (head-oracle table: NWFTH→Leaf, SL→Bamboo, LINE→Line, trading→Sky; discover live via `maw ls`). **YOUR own domain** → `maw workon <repo> <slug>` from your session — you are the orchestrator; steps 2–4 still apply.
5. Ack Wind: "Filed #N. Routed to <Oracle|window>. Will report when done."
6. Monitor through pipeline. Surface only blockers.
7. On completion: report DONE to Wind — gh issue closes via the PR's `Closes #N`; Linear mirrors automatically.

**Multi-issue? Analyze independence FIRST (Parallel L2s — Wind directive 2026-06-13)**: issues with DISJOINT files/modules each get their OWN concurrent `maw workon` L2 (no single-L2 queue); coupled/overlapping-file issues go to ONE L2. PRs land in parallel; L1 merges sequentially (rebase between); `maw done` one window at a time. Full rule: core.md ## Fan-Out Strategy → Parallel L2s.

**Routing — SOLO or TEAM (one question, per L2)**: can one person do this in under 30 minutes, in 1-2 files, with no research? YES → SOLO (`maw workon <repo> issue-N`, the worktree pane codes it directly — no workers). NO or unsure → TEAM: `maw workon <repo> <slug>` → the L2 (Claude, in the project worktree) spawns ephemeral OMX workers, one issue each, max 4: `maw team create <slug>` + `maw team spawn <slug> worker-N --wt --engine omx --exec --prompt "Issue #N: <title>. <slice>"` (brief baked at spawn — `.maw/briefs/` does NOT cross the worker's isolated worktree). 1-2-line follow-ups via `maw hey <member>`. Workers commit sub-branches → L2 aggregates → ONE consolidated PR with all `Closes #N` → `maw team shutdown` → DONE-ping. Ephemeral is the ONLY mode — standing/warm pools RETIRED 2026-06-10 (a warm session idling outside a project loads the WRONG context). Full contract: core.md ## Fan-Out Strategy.

**Break the autonomous flow** (escalate to Wind) when: project repo missing, tier ambiguous, UI/UX needs design discussion, CR conflicts with in-flight work.

## Delegation Pattern (the ONLY correct flow)

### Pre-Delegation
- `maw preflight` — verify target oracle health before dispatching
- `maw dispatch "task description"` — auto-route to best Oracle by domain (alternative to manual `maw hey wind:<oracle>`)
- `maw assign --issue N <oracle>` — route GitHub issue directly

`maw workon` spawns the worktree window in **the calling session**. So the orchestrator Oracle must NEVER run `maw workon` directly when delegating — the worktree would land in HER session, not the worker's. Always:

```bash
maw hey wind:<oracle> "First run: maw workon <repo> <slug>  (spawns your worktree window). I'll send the task brief to that window next. Follow the lifecycle closer."
```

The worker Oracle runs `maw workon` from HER home base → worktree spawns in HER session. The orchestrator only runs `maw workon` directly when SHE is also the worker (her own infra/oracle repo).

`maw workon <repo> <slug>` takes a positional **slug**. The L2 orchestrator is ALWAYS Claude (default engine); do NOT pass `--codex`/`--engine` to the orchestrator pane — engine flags are worker-spawn-only. It does NOT take a `--prompt` flag — deliver the task brief to the spawned worktree window with `maw hey wind:<window-name> "<task>"` once it is up.

`maw done` MUST target a window DIFFERENT from the caller (fork preflight refuses self-target, exit 2). Run from HOME BASE, never from inside the worktree.

## Task Brief (template)

Saved at `~/ghq/github.com/deachawatss/<PROJECT>/TASK-<slug>.md`:

```markdown
# TASK-<slug>.md
## What            — 1-3 sentences
## Design Spec     — specs/<N>-<slug>.md (L2 creates before worker spawn; skip for SOLO)
## Acceptance      — checklist
## File Ownership  — table (multi-Oracle only)
## API Contract    — backend writes shared types first; frontend reads, never modifies
## Phases          — table with deps (multi-Oracle only)
## Edit-Set Planning — by EDIT SETS not FILE SETS. Two agents touching same file = ONE edit owned by ONE agent.
## Constraints     — use localhost (you ARE on localhost), NEVER .0.12, theme, ports
## Report Contract — ≤500 words, sections Done/Issues/Next, file:line citations, 5-min heartbeat
## References      — screenshots, mockups
```

Routing: bug fix = no Task Brief. Single-Oracle feature = light brief. Multi-Oracle = phased + contract. Enterprise = arch review first.

## Delegation Checklist (in EVERY task brief)

**Prompt shape rule for NWFTH/project repos**: every delegation instructs `maw workon <repo> <slug>` as the FIRST step (the worker then works inside that worktree). NEVER write "clone the repo" / "cd into the repo" / "commit to main" for NWFTH/project prompts.

**Non-NWFTH tooling repos** (`Gale-Oracle`, `*-oracle`, `oracle`, `maw-js`, `maw-ui`, plugins): do not force the NWFTH pipeline by habit. Direct Codex work, subagents, or `$team-agents`; commit and push directly when hooks/repo policy allow.

Every NWFTH/project prompt MUST include: (1) what+acceptance, (2) `maw pr` rule with `MAW_PR_REQ='REQ-<PROJECT>-NNN'` for feature/behavior PRs or `REQ: none` only for true refactor/chore, (3) self-QA via `/sop-qa`, (4) Task Brief path, (5) use localhost (you ARE on localhost), (6) port, (7) theme/skill, (8) heartbeat 5-min, (9) lifecycle closer, (10) **no `git add -A` or `git add .`** — stage by name only. NWFTH test creds: `/nwf-sql`.

## Lifecycle / Full Pipeline

```
Wind requests → Orchestrator classifies CR/REQ/BUG → GitHub issue (canonical)
  → maw hey wind:<worker> (worktree+PR prompt)
  → WORKTREE: worker maw workon → build → /sop-qa (self-QA) → fix until PASS
    → maw pr → gh pr comment (QA report)
    → maw hey wind:<orchestrator> "[wt] PR #N ready. <pr-url>" → WAIT
  → ORCHESTRATOR SESSION: /sop-review PR → merge per gate
    → maw done <worktree-window> (rescues ψ/, kills worktree)
    → report DONE to Wind in the active Discord/thread surface
  → Orchestrator: /post-mortem (bug PRs only, run by L1 after merge)
```

The orchestrator stays orchestrator the WHOLE way — she does not hand the task off after briefing. She owns it through `/sop-review` → merge → `maw done`.

**Doc deltas are NOT per-feature-PR work.** Feature PRs carry only the `REQ:` traceability line. `/doc-sync` runs later at stabilization/release/UAT and opens one docs-only PR that updates SRS/UAT/CR from merged PR history; SDD is generated as a snapshot when needed.

**Flavor A (PR)**: WORKTREE: build → `/sop-qa` → `maw pr` → tell orchestrator `maw hey wind:<orchestrator> "[wt] PR #N ready"` → WAIT. ORCHESTRATOR SESSION: `/sop-review` → merge → `maw done <window>` (rescues ψ/) → report DONE.

**Flavor B (audit/no PR)**: do work → deliver report → WAIT. Main session: `maw done <window>` (rescues ψ/) → tell Gale DONE.

The L2 sends the DONE-ping before `/rrr` (canonical — see sop-maw §Worktree Completion): `maw hey <L1> "DONE: PR #N ready..."` then `mkdir -p .maw && touch .maw/done-pinged`, then `/rrr` while context is still alive. This prevents session-limit failures from blocking L1 review; `oracle_learn` indexes lessons via MCP before `maw done` removes the worktree.

**Config-only exception**: `.env` (gitignored) deploys directly — no worktree/PR.

L1 is the only reviewer + merger — there is no escalation reviewer in the pipeline loop.

## CRITICAL Rules

- NO GSD. Devs build directly from Task Briefs.
- NWFTH project repos: worktree-only, NEVER direct main.
- Non-NWFTH tooling repos: direct main allowed when verified from the permanent L1 pane; worktree panes still PR + DONE-ping.
- Oracle family repos: direct push to main allowed only from the permanent L1 pane after focused verification; L2/worktree panes never self-merge.
- PR before merge (project repos always; infra/oracle worktree panes too). The owning oracle runs `/sop-review` → merges ANY tier after self-QA PASS (`/sop-qa`); high risk = scrutinize harder, same merger. L1 is the only reviewer + merger (no escalation reviewer).
- Report completion in the active Discord/thread surface; GitHub Issues/PRs remain canonical state, no retired Discord forum tracker ceremony.
- Always specify theme/skill + include reference screenshots.
- Review the result yourself (Playwright) before reporting done to Wind.
- **Anti-pattern (Gale-side)**: "the diff looks obvious, I'll just merge" — still run `/sop-qa` self-QA before merge.
- **NEVER touch `Soul-Brews-Studio/*`** — no issues, PRs, comments, pushes. Read-only allowed.
- **NEVER include**: "run GSD", "/gsd:*", model profiles, planning instructions.
