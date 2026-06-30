---
name: sop-cmmi
description: 'The lean project doc standard — ONE flat 7-doc set for EVERY project (no tiers). Per-PR: one REQ line in the description. Docs sync in batch at stabilization (/doc-sync before UAT & release). Use when user says "cmmi", "docs", "doc standard", "CR", "SRS", "SDD", "UAT", "doc-sync", or asks which docs a project needs.'
---
# /sop-cmmi — The Lean Project Doc Standard

> One standard. Every project. Seven documents. Code first, docs after.

This replaces the old 35-doc, 4-tier, gate-enforced CMMI machine. There are no phases, no `.maw/phase.json`, no doc-before-code hook gates, no per-project tiers. Every project — NWFTH, Solution Lab, oracle, client — keeps the **same seven documents**. That is the whole standard.

---

## 0. Software Delivery Lifecycle Checklist (Wind-approved 2026-06-24)

Use this as the default mental model for real software work. It is a checklist, not a heavy phase gate: adopt the parts that fit the project, explicitly mark what is deferred/out of scope, and keep the seven-doc standard lean.

| Lifecycle concern | What to decide/prove | Where it lives in the lean docs |
|---|---|---|
| PRD / scope | Goal, users, MVP boundary, business logic, success criteria | `PROJECT_PLAN.md`, `SRS.md` |
| UX/UI | Screens, flows, states, responsive behavior, usability | `UXUI.md` |
| Design spec | Objective, key decisions, data model, API shape, UI flow, success criteria | `specs/<N>-<slug>.md` — created by L2 before worker spawn |
| Design system / tokens | Reusable components, form/table/card patterns, brand tokens if the UI will grow | `UXUI.md` |
| ADR / architecture | Framework, DB, schema, deployment model, auth, integrations, multi-tenant choice | `RISK.md` → Decisions/DAR; `SDD.md` snapshot when needed |
| Infrastructure / pipeline | Git flow, CI/CD, deployment target, secrets, environment setup | `PROJECT_PLAN.md`, `RISK.md` |
| Functional coding | Features that satisfy each requirement | PR with `REQ:` line; later `/doc-sync` into `SRS.md`/`UAT.md` |
| Non-functional coding | Performance, scalability, caching, logging, operational quality | `SRS.md` for requirements; `RISK.md` for risks/decisions |
| Security | Authz/authn, injection protection, encryption, secret handling, permission boundaries | `SRS.md`, `RISK.md`, `UAT.md` |
| Smoke test | Integrated/deployed app still works and does not break critical flows | PR verification evidence; `UAT.md` if release-facing |
| UAT | User acceptance against requirements | `UAT.md` with REQ-id column |
| Post-MVP maintenance | Optimize, RBAC, monitoring/alerts, patching, cert renewal, backup/DR, PDPA/compliance, enhancement budget | `PROJECT_PLAN.md` maintenance scope; `RISK.md`; `CR.md` |

**Pricing / expectation rule:** MVP delivery is only the first cost block. For client or long-lived systems, call out the maintenance lane explicitly: optimization, RBAC growth, monitoring/alerts, dependency/security patches, certificate renewal, backup/DR, compliance, and enhancements. For SaaS/multi-tenant systems, require a DAR before build because data isolation, quotas, billing, and tenant operations change the architecture class.

---

## 1. The Seven Documents

All live in `docs/` at the project root. Create the set once with `scripts/init-project-docs.sh` (it stubs all seven). If a project has no `docs/`, make it.

| # | Document | Path | What it holds |
|---|---|---|---|
| 1 | **Project Plan** | `docs/PROJECT_PLAN.md` | Goal, scope, milestones, who owns what, deploy target. The "what are we building and why." |
| 2 | **SRS** | `docs/SRS.md` | Requirements. One `REQ-<PROJECT>-NNN` section per requirement. The source of truth for *what it must do*. |
| 3 | **SDD** | `docs/SDD.md` | Design snapshot. How each REQ is built — data model, API surface, key components, decisions. **GENERATED on demand, never hand-maintained** (see §2). |
| 4 | **CR** | `docs/CR.md` | Change requests. Every change to an approved requirement gets a `CR-NNN` row. Append-only. |
| 5 | **RISK** | `docs/RISK.md` | One file, three sections: **Risk Register** (open risks + mitigation), **Decisions/DAR** (weighted choices), **Corrective Actions/CAR** (post-incident root-cause). |
| 6 | **UXUI** | `docs/UXUI.md` | UI/UX spec — screens, flows, states, brand tokens. Frontend projects only; backend-only projects mark it `N/A`. |
| 7 | **UAT** | `docs/UAT.md` | Acceptance tests. Each test row carries a **REQ-id column** — that column IS the traceability (REQ → test). No separate RTM. |

**Traceability** lives in UAT's REQ-id column — every test cites the requirement it proves. That single column answers "did we test what we built." Nothing more is needed.

### `specs/` vs `docs/` — Different Artifacts, Different Purposes

A project may have BOTH a `specs/` directory and a `docs/` directory. They are NOT duplicates:

| | `specs/` (design intent) | `docs/` (CMMI compliance) |
|---|---|---|
| **When written** | BEFORE coding (by L2 via `/sop-design`) | AFTER stabilization (by Haiku via `/doc-sync`) |
| **Who writes** | Developer (L2/L3) | Haiku subagent |
| **Format** | Free-form spec per issue (`specs/42-user-roles.md`) | Structured 7-doc set (SRS, SDD, UAT...) |
| **Purpose** | Guide implementation, capture WHY | Prove compliance, capture WHAT was built |
| **Updates** | When design decisions change during build | At stabilization batch sync |
| **Feeds into** | `/doc-sync` reads specs/ as design context | Final documentation artifacts |

The relationship: `specs/` → feeds design intent into → `docs/` (via `/doc-sync`). Specs are the BRIDGE. They answer "why did we design it this way?" so docs can explain "what was built and why."

**Never duplicate specs into docs.** `/doc-sync` reads both specs/ and PR diffs to generate docs. Writing the same content in both places creates the mismatch this system exists to prevent.

---

## 2. The Flow — Code Per-PR, Docs at Stabilization (MANDATORY)

*(Tailoring decision 2026-06-05, Wind-approved — replaces the per-PR docs-in-same-PR mandate. Rationale: per-PR doc edits chased moving designs across the implement→pivot→polish cycle and produced mismatch; batch sync writes docs once, against settled behavior.)*

```
PER FEATURE PR (seconds):
1. Code + tests + verify live.  No docs/ edits in feature PRs.
2. PR description carries ONE line:  REQ: REQ-<PROJECT>-NNN[, …]  or  REQ: none
   (that line IS the traceability thread — /sop-qa checks it, P2 if missing)

AT STABILIZATION (before any UAT session, before any release/deploy):
3. /doc-sync.   Reads merged PRs since docs/.last-doc-sync (SHA marker),
                swarms Haiku to update SRS + UAT + CR (+ RISK/UXUI if triggered),
                lands ONE docs-only PR (low-risk → self-merge), advances the marker.
4. /sop-qa release gate: BLOCKED (P1) if the marker is behind any merged feature PR.
```

### Why stabilization-sync
Docs are a transcription of decisions the code already made — and decisions only become final when the feature stabilizes. Writing docs per-PR while the design is still moving means transcribing a draft, then re-transcribing it every PR. Sync once, when the target stops moving: zero mismatch window at exactly the moments docs are read (UAT, release, audit).

### SDD is GENERATED, never maintained
Design rots fastest and is read rarest. `SDD.md` is regenerated as a snapshot from current code + PR history only when needed — release, audit, onboarding (the `/doc-sync` skill has the recipe). Prior versions live in git history: Nothing is Deleted via git, not via hand-kept tables.

### Docs are a HAIKU job — never Opus (HARD RULE)
`/doc-sync` **swarms Haiku subagents to write the docs**. Doc-writing is mechanical: read the merged diffs, read the existing doc, append the REQ/CR/test rows in the existing format. That is exactly Haiku's lane. **Opus 4.8 MUST NOT edit docs** — Opus stays on code and design where its reasoning earns its cost.

Spawn pattern (one Haiku agent per doc, in parallel):
```
Agent(subagent_type: general-purpose, model: haiku,
      prompt: "Update docs/SRS.md for the merged PRs since <marker SHA>. Diffs + REQ
               lines: <...>. Append REQ sections + Revision History rows in the
               existing format. Nothing else.")
```
Batch all affected docs (SRS, UAT, RISK, CR, UXUI) in a single parallel fan-out. Each Haiku agent owns one file → no write conflicts.

### Delta discipline — keep doc work proportional to the diff (the speed rule)

The "docs take forever / one code change rewrites everything" pain has two causes, both banned here:

1. **No restating a fact in more than one doc (single source of truth).** A requirement is stated ONCE in SRS. SDD *references* the REQ-id and describes only the design — it never re-describes the requirement. UAT *cites* the REQ-id — it never restates it. So a requirement change touches SRS's REQ section + the SDD design note + the UAT row — three small edits, not three rewrites.
2. **Append/patch, never regenerate.** The Haiku swarm appends the new REQ section, the new CR row, the new UAT row, the new revision-history line. It does NOT rewrite whole documents. The size of the doc edit must match the size of the code edit — a one-endpoint change is a handful of lines across docs, never a full-doc pass.

Rule of thumb: **scope every doc edit to the diff.** If a Haiku agent is rewriting a section the diff didn't touch, stop it — that is churn, not documentation.

---

## 3. Definition of Done — Standing Quality Bar

A standing, project-wide bar that every change must clear before it counts as done. Unlike acceptance criteria (which vary per task), the Definition of Done is the same every time.

| | Acceptance Criteria | Definition of Done |
|---|---|---|
| Scope | Specific to one task | Every increment |
| Changes | Different for each item | Fixed and reused |
| Answers | "Did we build *this thing*?" | "Is it *ready*?" |

### The Standing Checklist

**Correctness:**
- [ ] All acceptance criteria for the task are met
- [ ] Code runs and behaves as intended, verified at runtime (not just compiled)
- [ ] New behavior covered by tests that fail without the change and pass with it
- [ ] Existing tests still pass; no regressions introduced

**Quality:**
- [ ] Code reveals intent through naming and structure
- [ ] No duplicated business logic, dead code, or commented-out blocks
- [ ] Changes are scoped to the task; no unrelated refactors
- [ ] Linting and formatting pass

**Integration:**
- [ ] Change works with the rest of the system, not just in isolation
- [ ] Database migrations, config changes, and feature flags accounted for

**Documentation:**
- [ ] PR description carries `REQ: REQ-<PROJECT>-NNN` or `REQ: none`
- [ ] Public interfaces and APIs documented
- [ ] Architectural decisions recorded in RISK.md Decisions/DAR section
- [ ] Design spec exists in `specs/` for TEAM tasks and is current with implementation
- [ ] PR description carries `SPEC: specs/<N>-<slug>.md` (TEAM tasks only)

**Ship-readiness:**
- [ ] Security implications reviewed for untrusted input, auth, or data handling
- [ ] Observability in place for new critical paths (logs, metrics)
- [ ] Rollback path exists for anything risky
- [ ] Human has reviewed and approved before merge

Apply per-task (Correctness + Quality), per-feature (+ Integration + Documentation), per-release (full checklist).

---

## 4. ADR — Architecture Decision Records

ADRs capture the reasoning behind significant technical decisions. They live in the **RISK.md Decisions/DAR** section (Document 5 in the Seven Documents).

### When to Write an ADR

- Choosing a framework, library, or major dependency
- Designing a data model or database schema
- Selecting an authentication strategy
- Deciding on an API architecture
- Any decision expensive to reverse

### ADR Format (inside RISK.md Decisions/DAR)

```markdown
### DAR-NNN: [Decision Title]

**Status:** Accepted | Superseded by DAR-XXX | Deprecated
**Date:** YYYY-MM-DD

**Context:** [Requirements and constraints that led to this decision]

**Decision:** [What we decided and why]

**Alternatives Considered:**
- [Alternative A] — Pros: ... / Cons: ... / Rejected because: ...
- [Alternative B] — Pros: ... / Cons: ... / Rejected because: ...

**Consequences:** [What follows from this decision — trade-offs accepted, capabilities gained, limitations imposed]
```

### ADR Lifecycle

```
PROPOSED → ACCEPTED → (SUPERSEDED or DEPRECATED)
```

Don't delete old ADRs — they capture historical context (Principle 1: Nothing is Deleted). When a decision changes, write a new DAR that references the superseded one.

### Inline Documentation Standard

- **Comment the WHY, not the WHAT.** Well-named identifiers already explain what. Only add comments when the reason is non-obvious: hidden constraints, workarounds, behavior that would surprise a reader.
- **No commented-out code.** Git has history.
- **Document known gotchas** inline where they matter — timing constraints, SSR traps, ordering dependencies.

> **Quality backbone reference:** See `addy/documentation-and-adrs` for the full ADR methodology and `addy/references/definition-of-done` for the standing bar philosophy.

---

## 5. Doc-Sync Mandate

Every feature PR carries its `REQ:` line (see §2) — that is the PR's ENTIRE doc obligation. `/doc-sync` MUST run before any UAT session and before any release/deploy; it routes the merged changes to docs:

| Merged change (since marker) | Docs the `/doc-sync` Haiku swarm updates |
|---|---|
| New requirement | SRS (new REQ section) + UAT (test w/ REQ-id) |
| Changed requirement | CR (CR-NNN row) + SRS (amend, keep old per §7) + UAT |
| UI change | UXUI + UAT |
| Architecture/vendor decision | RISK (Decisions/DAR section) |
| Post-incident fix | RISK (Corrective Actions/CAR section) |
| New/changed risk | RISK (Risk Register section) |
| Design view needed (release/audit/onboarding) | SDD regenerated as snapshot |

**`REQ: none` PRs** (pure refactors, typo fixes, dependency bumps, tests-only, build-config-only, cosmetic rerenders): `/doc-sync` skips them. When unsure which REQ a PR touches, ask Gale.

**Gates**: `/sop-qa` per-PR check = `REQ:` line present in the PR description (P2 if missing). `/sop-qa` release gate = P1 BLOCK if `docs/.last-doc-sync` is behind any merged feature PR at UAT/release time.

---

## 6. Lightweight Flows

### Change Request (CR)
```
# Wind: "change X to Y"
# The feature PR ships with `REQ: REQ-<PROJECT>-NNN` in its description.
# At the next /doc-sync (pre-UAT / pre-release), the Haiku swarm:
#   - appends a row to docs/CR.md:  | CR-NNN | date | REQ-id | reason | PR |
#   - amends the REQ section in SRS (old text retained per §7)
#   - updates UAT as the change requires (SDD regenerates on demand)
```

### Decision Analysis (DAR) — record significant choices
Trigger: choosing a framework / DB / cloud service, picking between architectures with different long-term cost, or any choice Wind flags as significant.
```
# In docs/RISK.md → Decisions/DAR section, append a row:
# | date | DAR-NNN | decision | alternatives | criteria | choice | rationale | PR |
```
Score ≥2 alternatives against weighted criteria (weights sum to 100), record the winner and why. Keep it to one table row + a short rationale — not a report.

### Corrective Action (CAR) — after an incident/escaped defect
```
# In docs/RISK.md → Corrective Actions/CAR section:
#   1. What happened + impact (who/what/when/how long)
#   2. Root cause (5 Whys, brief)
#   3. Immediate fix applied
#   4. Preventive change (so it can't recur)
#   5. Link to ψ/memory/learnings/<date>-<slug>.md
```
Pairs with `/post-mortem` (the engineering RCA) — CAR is the project-doc record, post-mortem is the brain record.

---

## 7. Revision History (Principle 1 — Nothing is Deleted)

Every doc under `docs/` carries a Revision History table at the top:

```markdown
## Revision History
| Version | Date | REQ/CR-id | Author | Change | PR |
|---------|------|-----------|--------|--------|----|
| 1.0.0   | 2026-06-01 | REQ-GALE-001 | Haiku/Gale | Initial | #NN |
```

On a CR, the superseded requirement text moves to a `#### v1 — superseded` subsection — never deleted. Versions are `major.minor.patch`: major on CR, minor on scope change, patch on clarification. The Haiku swarm appends these rows as part of writing the docs.

---

## 7b. The Org Layer — write once (this is what makes it genuine L3)

The 7 docs are **per-project**. CMMI L3 ("Defined") needs one more thing: a single **organizational** standard process every project tailors from — written ONCE for the fleet. The org-level TEMPLATES live in `Wind-Framework/templates/org/` and are COPIED (not symlinked) into each project's `docs/` by `init-project-docs.sh` as seed files — each project then tailors its own copy:

| Doc | What it defines |
|---|---|
| `PROCESS.md` | The defined fleet SDLC (lifecycle, roles, merge gate, stack-detection) |
| `SDLC_LIFECYCLE.md` | CMMI L3 process flow diagram with quality gates and traceability matrix |
| `TAILORING.md` | How a project adapts the 7 docs to its size/shape (what may/may not be tailored) |
| `MEASUREMENT.md` | The few metrics the fleet tracks (GQM) + the feedback loop |
| `QA.md` | Process quality assurance — per-PR gates + the periodic audit cadence |

This is the difference between "7 docs per project" (which is just *Managed*) and real L3 *Defined*: the org has a standard process, projects tailor it, and the tailoring + measurement are auditable. It costs ~4 docs **for the whole fleet**, not 4 per project — which is exactly why we don't regenerate org content per repo (the old 35-doc machine's mistake).

A project does NOT copy these. It references them and records its own tailoring in its `RISK.md` Decisions/DAR section.

---

## 8. What Changed From the Old CMMI Skill

| Old | Now |
|---|---|
| 35 documents, 4 tiers | **7 documents, 1 flat standard** |
| 8-phase state machine + `.maw/phase.json` | **None** — no phase tracking |
| 7 hook gates (G1–G7) blocking edits | **None** — gates retired (`/sop-qa` is the only check) |
| Per-project tier rules (NWFTH vs SL) | **Same 7 docs for every project** |
| RTM as a standalone doc | **REQ-id column inside UAT** |
| Risk Register + DECISION-LOG + CAR (3 docs) | **One `RISK.md`, three sections** |
| Doc-first (docs before code) | **Code-first (docs after, via Haiku swarm)** |
| `/cmmi-team` Sonnet officers during build | **Haiku doc-swarm after build** |
| Docs in the same PR as code (per-PR gate) | **`REQ:` line per PR + `/doc-sync` batch at stabilization** (2026-06-05 tailoring) |
| SDD hand-maintained every change | **SDD generated on demand** (release/audit/onboarding) |

---

## 9. Implementation Enforcement Audit

When Wind reports that the `REQ:` → PR → `/doc-sync` lifecycle is not behaving like this design, treat it as a **doctrine/tooling/enforcement mismatch**, not as agent forgetfulness. Audit all three layers before proposing a fix:

1. **Doctrine** — canonical rules say feature PRs carry `REQ:` and docs are batch-synced later.
2. **Tooling** — the actual PR creation path (`maw pr`, wrapper scripts, `gh pr create` helpers) writes the `REQ:` line, not only `Closes #N`.
3. **Enforcement** — missing `REQ:` and stale `docs/.last-doc-sync` are executable gates, not just prose examples inside `/sop-qa`.
4. **Runnability** — `/doc-sync` exists as a real skill/script; if it is only mentioned in doctrine, the migration is incomplete.
5. **Markers** — never blindly advance `docs/.last-doc-sync`; backfill/sync docs first, then advance the marker.

Detailed audit recipe: `references/doc-sync-enforcement-audit.md`.

---

## 10. Cross-References

- `/sop-qa` — the single quality gate. Runs after build, before `maw pr`. Includes doc-completeness.
- `/nwf-doc` / `/sl-doc` — branded document *generation* (PDF/DOCX/PPTX/XLSX deliverables), distinct from these markdown specs.
- `/sop-maw` — worktree, PR, merge, cleanup.
- `/post-mortem` — engineering RCA (pairs with the CAR section of RISK.md).
- `/sop-delegation` — the delegation + orchestration pipeline (same for every project; merge gate and stack are per-repo, not per-doctrine). Uses this same 7-doc standard.
