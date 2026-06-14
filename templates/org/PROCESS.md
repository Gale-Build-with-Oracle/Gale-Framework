# Org Standard Process — Fleet SDLC (write-once)

> This is the **organizational** layer of the doc standard. It is written ONCE for the whole fleet and **referenced** by every project — never copied into a project repo. Together with the per-project 7 docs (see `/sop-cmmi`), it is what makes the standard genuinely CMMI L3 "Defined": one defined process every project tailors from, not 35 documents re-typed per repo.

## Revision History
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2026-06-01 | My Oracle | Initial org standard process |

## 1. The defined lifecycle

Every project — YourProject, Internal Tools, oracle, client — follows the same lifecycle. Stack and merge gate differ per repo; the *process* does not.

```
PER PR:            intake → build (code-first) → /sop-qa → /scrutinize → merge → maw done
                   (PR description carries its REQ: line — that is the PR's entire doc obligation)
AT STABILIZATION:  /doc-sync (Haiku swarm) → docs-only PR → marker advance
                   (MUST run before any UAT session and before any release/deploy)
```

- **Code-first**: build and verify the change against the real command/UI. Docs transcribe decisions the code already made — and only once the feature settles.
- **Docs at stabilization, by Haiku** (org tailoring ORG-DAR-001, 2026-06-05): `/doc-sync` reads merged PRs since the `docs/.last-doc-sync` marker and swarms Haiku to update SRS/UAT/CR (+RISK/UXUI) in ONE docs-only PR. `SDD.md` is regenerated on demand (ORG-DAR-002). Opus never writes docs. See `/sop-cmmi` + `/doc-sync`.
- **Two quality gates**: `/sop-qa` per PR (REQ-line check, P2) and the `/sop-qa` release gate (doc-sync marker current, P1). There are no doc-before-code hook gates.

## 2. The seven per-project documents

`PROJECT_PLAN, SRS, SDD, CR, RISK, UXUI, UAT` — defined in `/sop-cmmi`. Traceability lives in the UAT REQ-id column. These are the only per-project documents.

## 3. Roles (who does what)

| Role | Who | Responsibility |
|---|---|---|
| **Orchestrator** | the Oracle that owns the task | Briefs the worker, monitors, closes: `/scrutinize` → merge → `maw done`. Stays orchestrator until done. |
| **Worker** | an Oracle or codex in a `maw workon` worktree | Builds the change, runs `/sop-qa`, opens the PR, reports back. Never self-merges product code. |
| **Reviewer** | `/scrutinize` (+ QA Oracle for high-risk YourProject/Internal Tools) | Independent end-to-end review before merge. |

Full delegation mechanics: `/sop-delegation`.

## 4. Merge gate (per repo, not per doctrine)

- **YourProject** (production): Your Name approves the merge; direct push to `main` is hook-blocked.
- **Internal Tools**: dev oracle auto-merges after `/sop-qa` PASS.
- **Infra / oracle repos**: self-merge (lightweight).
- Risk classification (frontend/docs/config = low; backend/API/DB/security/cross-boundary = high → QA Oracle) lives in the fleet CLAUDE.md "Merge gate classification".

## 5. Stack is detected, never assumed

Detect a project's DB, deploy target, and framework from the repo (`package.json`, `Cargo.toml`, `compose.yml`, `vercel.json`, `supabase/`, …). Do not assume MSSQL/Docker or Supabase/Vercel — those are *current* project realities, not the standard.

## 6. Cross-references (the rest of the org library)

- `TAILORING.md` — how a project adapts these 7 docs to its size/shape.
- `MEASUREMENT.md` — what the fleet measures and how.
- `QA.md` — process quality assurance cadence.
- `/sop-cmmi` — the per-project doc standard + the code-first / delta-discipline flow.
