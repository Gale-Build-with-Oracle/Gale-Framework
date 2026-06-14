# Org Tailoring Guide — adapting the 7-doc standard per project (write-once)

> Written ONCE for the fleet. CMMI L3 requires a *defined* way to tailor the standard process to each project — this is it. Tailoring is bounded: you choose depth, never skip traceability or the merge gate.

## Revision History
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2026-06-01 | My Oracle | Initial tailoring guide |
| 1.1.0 | 2026-06-05 | My Oracle (Your Name-approved) | Org tailoring: per-PR doc mandate → `/doc-sync` batch at stabilization; SDD generated on demand |

## Org-level tailoring decisions (the L3 audit record)

| DAR | Date | Decision | Rationale | Approved |
|---|---|---|---|---|
| ORG-DAR-001 | 2026-06-05 | Docs sync in BATCH at stabilization (`/doc-sync` before any UAT session and any release/deploy) instead of per-PR doc edits. Per-PR obligation = one `REQ:` line in the PR description. | Per-PR doc edits chased moving designs across the implement→pivot→polish cycle, producing doc↔code mismatch and rework (observed: dev-oracle 2026-04-19, fleet experience). Batch sync writes docs once against settled behavior — zero mismatch window at the moments docs are read. CMMI L3 requires a defined+followed process, not per-PR docs; this tailoring is the defined process. | Your Name |
| ORG-DAR-002 | 2026-06-05 | `SDD.md` is a GENERATED snapshot (regenerated at release/audit/onboarding), not a maintained doc. | Design rots fastest and is read rarest; hand-maintenance produced the worst mismatch. Git history preserves prior versions (Nothing is Deleted via git). | Your Name |

## What you MAY tailor

| Project shape | Tailoring allowed |
|---|---|
| **Backend-only** (no UI) | `UXUI.md` = `N/A` with a one-line reason. Everything else stands. |
| **Trivial change** (typo, dep bump, refactor, tests-only, build-config, cosmetic rerender) | **`REQ: none`** in the PR description — `/doc-sync` skips it. (See `/sop-cmmi` §3 exempt list.) |
| **Small project / single feature** | SRS/SDD may be a few sections; PROJECT_PLAN a half page. Depth matches scope. |
| **Spike / throwaway** | `PROJECT_PLAN.md` only, marked `spike`. Promote to full 7 if it graduates to a product. |
| **Library / CLI (no deploy)** | PROJECT_PLAN "deploy target" = the publish/release mechanism. |

## What you MUST NOT tailor away

- **Traceability** — every feature PR carries its `REQ:` line; every UAT test cites its REQ-id. Never dropped.
- **The merge gate** — per repo (Your Name-gated / auto / self-merge). Never bypassed.
- **`/sop-qa`** before PR. Never skipped for non-exempt changes.
- **`/doc-sync` before any UAT session and any release/deploy** — the P1 release gate. Never skipped.
- **Revision History** on each touched living doc (Principle 1 — Nothing is Deleted; SDD's history lives in git).
- **Code-first** order: code settles, then docs transcribe (via the `/doc-sync` Haiku swarm).

## How to record a tailoring decision

Tailoring is itself a decision — record it in the project's `RISK.md` → Decisions/DAR section as a one-row entry (`DAR-NNN | tailoring | <what> | <why>`). That keeps the project's deviation from the org standard auditable, which is the L3 requirement.

## Default (no tailoring)

If nothing above applies, run the full 7-doc standard at depth proportional to the change. When unsure, ask My Oracle.
