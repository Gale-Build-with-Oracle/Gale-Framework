---
name: doc-sync
description: 'Batch doc reconciliation at stabilization — reads merged PRs since the docs/.last-doc-sync marker, swarms Haiku to update SRS/UAT/CR (+RISK/UXUI), lands ONE docs-only PR, advances the marker. MUST run before any UAT session and before any release/deploy. Use when user says "doc-sync", "sync docs", "update project docs", or before UAT/release.'
---
# /doc-sync — Batch Doc Reconciliation at Stabilization

> Docs chase settled behavior, never moving targets. One sync, one PR, zero mismatch at the moments docs are read.

Part of the lean CMMI standard (`/sop-cmmi`). Tailoring decision 2026-06-05 (Wind-approved, recorded in `gale-oracle/docs/org/TAILORING.md`): the per-PR doc mandate was replaced by this batch sync because per-PR doc edits chased moving designs and produced mismatch.

## When this MUST run

1. **Before any UAT session** — the UAT.md script the testers hold MUST describe current behavior.
2. **Before any release/deploy** — `/sop-qa` Phase 7.5.2 release gate BLOCKS (P1) if the marker is behind.

No calendar cadence — these two gates are the only triggers (Wind decision 2026-06-05).

## Executable collection step

The runnable collector lives in Wind-Framework and is the first command to run from the target project repo:

```bash
bash ~/ghq/github.com/deachawatss/Wind-Framework/scripts/doc-sync.sh --write-report
```

It reads `docs/.last-doc-sync`, scans merged PRs on `main`, validates every merged PR has `REQ: ...` or `REQ: none`, and writes `docs/.doc-sync/merged-prs.md` for the doc-writing agents. If it reports missing/invalid REQ lines, fix the PR metadata or traceability record first; do not advance the marker.

After the docs are updated and `/sop-qa` traceability checks pass, advance the marker with:

```bash
bash ~/ghq/github.com/deachawatss/Wind-Framework/scripts/doc-sync.sh --apply-marker
git add docs/
```

`--apply-marker` refuses to run if PR traceability validation fails. Never hand-write `docs/.last-doc-sync`.

## The Flow

```bash
# 1. Collect merged PR numbers, titles, REQ lines, and validation status.
bash ~/ghq/github.com/deachawatss/Wind-Framework/scripts/doc-sync.sh --write-report

# 2. Read docs/.doc-sync/merged-prs.md.
# REQ: none PRs are SKIPPED. Group the rest by REQ-id.
```

3. **Swarm Haiku — one agent per doc, in parallel (HARD RULE: Opus MUST NOT write docs):**

```
Agent(subagent_type: general-purpose, model: haiku,
      prompt: "Update docs/SRS.md for these merged PRs: <PR list + REQ lines + diff summaries>.
               Append new/amended REQ sections + Revision History rows in the existing format.
               Append/patch only — never rewrite untouched sections. Nothing else.")
```

Routing (from `/sop-cmmi` §3): new REQ → SRS + UAT row · changed REQ → CR row + SRS amend + UAT · UI change → UXUI + UAT · decision → RISK/DAR · incident fix → RISK/CAR. Each Haiku agent owns ONE file — no write conflicts.

4. **Land + advance the marker:**

```bash
echo "$HEAD_SHA" > docs/.last-doc-sync
git checkout -b docs-sync-$(date +%Y%m%d)
git add docs/   # docs-only PR; stage by path
# commit, push, maw pr — docs-only = LOW RISK → self-merge per merge gate
```

5. **Verify**: run `/sop-qa` 7.5.4b (UAT REQ-id traceability) on the result before merging.

## SDD — generate on demand (never maintained)

`SDD.md` is NOT part of the routine sync. Regenerate it as a snapshot ONLY when needed (release, audit, onboarding):

```
Agent(subagent_type: general-purpose, model: haiku,
      prompt: "Regenerate docs/SDD.md as a design snapshot of <repo> at <SHA>:
               data model, API surface, key components, decisions (mine RISK.md DAR rows).
               Reference REQ-ids from SRS.md — never restate requirements.
               Header: 'Generated <date> at <SHA> — regenerate, do not hand-edit.'")
```

Prior versions live in git history — Nothing is Deleted via git, not hand-kept revision tables.

## Delta discipline (unchanged from /sop-cmmi §2)

- Each REQ stated ONCE in SRS; UAT cites it (REQ-id column = the RTM).
- Append/patch SRS/UAT/CR — a Haiku agent rewriting a section the merged diffs didn't touch is churn: stop it.
- Superseded REQ text moves to `#### vN — superseded`, never deleted.

## Cross-references

- `/sop-cmmi` — the 7-doc standard + REQ-line rule this skill serves
- `/sop-qa` Phase 7.5 — the gates (per-PR REQ line P2; release marker P1)
- `/sop-maw` — branch/PR/merge mechanics
