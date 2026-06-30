# SDLC Lifecycle — Oracle Fleet (CMMI L3)

**Version**: 1.0
**Date**: 2026-05-14
**Standard**: CMMI v3.0 (2023) Level 3 — Defined

---

## Process Flow

```
┌──────────────┐    ┌─────────────┐    ┌────────────────┐    ┌──────────────┐
│  REQUIREMENTS │───▶│   DESIGN    │───▶│ IMPLEMENTATION │───▶│ VERIFICATION │
│  Wind → Gale  │    │ L2 Oracle   │    │   Worktree     │    │   /sop-qa    │
│  gh issue     │    │ specs/*.md  │    │   Code + PR    │    │  QA Report   │
└──────────────┘    └─────────────┘    └────────────────┘    └──────┬───────┘
                                                                    │
┌──────────────┐    ┌─────────────┐    ┌────────────────┐          │
│  MONITORING  │◀───│  DEPLOYMENT │◀───│  INTEGRATION   │◀─────────┘
│  Health Check │    │ deploy.sh   │    │ Main Session   │
│  Docker logs  │    │ Auto-rollback│    │ Review + Merge │
└──────────────┘    └─────────────┘    └────────────────┘
```

## CMMI L3 Process Area Coverage

### Level 2 — Managed

| Process Area | How Oracle Fleet Implements It |
|-------------|-------------------------------|
| **REQM** (Requirements Management) | Wind → Gale CR routing (`/sop-cr-routing`). Task Briefs with acceptance criteria. SRS.md per project. |
| **PP** (Project Planning) | `PROJECT_PLAN.md` template. Milestone tracking in ψ/. Delegation via `/sop-delegation`. |
| **PMC** (Project Monitoring & Control) | Heartbeat protocol (5-min progress). `maw peek`/`maw capture` for live monitoring. |
| **CM** (Configuration Management) | Git + worktrees. `maw workon` for isolation. Safety hooks block direct main. Fleet-propagate for config sync. |
| **MA** (Measurement & Analysis) | Smoke test metrics. Docker health checks. Session retros with commit counts. |
| **PPQA** (Process & Product Quality Assurance) | `/sop-qa` — OWASP 2025, WCAG 2.2, PDPA, NIST CSF 2.0, CWE Top 25, SOC 2, ISO 25010. |

### Level 3 — Defined

| Process Area | How Oracle Fleet Implements It |
|-------------|-------------------------------|
| **RD** (Requirements Development) | SRS.md (functional), SDD.md (technical). Doc-update mandate enforced per PR. |
| **TS** (Technical Solution) | Dev oracle architecture decisions. `/nwfth-sql` for DB schema. `/nwfth-theme` for UI. |
| **PI** (Product Integration) | Worktree → PR → review → merge → deploy. Docker compose orchestrates services. |
| **VER** (Verification) | `/sop-qa` self-QA. CI/CD (GitHub Actions). `smoke-test.sh` health checks. |
| **VAL** (Validation) | UAT.md test cases. Docker-based testing on the dev server (`<DEV_SERVER_IP>`). |
| **OPF** (Organizational Process Focus) | Shared-claude.md (fleet-wide rules). `/sop-nwfth` (universal pipeline). Skills as codified processes. |
| **OPD** (Organizational Process Definition) | This document. SOPs as skills. SDLC phases mapped to oracle workflow. |
| **OT** (Organizational Training) | Oracle KB (7000+ docs via arra_search). ψ/memory/learnings/. Cross-oracle knowledge sharing. |
| **IPM** (Integrated Project Management) | Gale orchestration. `maw team` for multi-agent coordination. Fleet-propagate for consistency. |
| **DAR** (Decision Analysis & Resolution) | Architecture decisions documented in SDD.md. PR review before merge. |

## Traceability Matrix (RTM)

```
Requirement (GitHub Issue + specs/<N>.md)
  └─▶ Design (specs/<N>.md Design Decisions)
       └─▶ Code (file paths in PR)
            └─▶ Test (UAT.md test case)
                 └─▶ Evidence (PR SHA + SPEC: line + QA report)
```

Each PR that touches user-facing functionality carries:
- `REQ: REQ-<PROJECT>-NNN` — requirement traceability
- `SPEC: specs/<N>-<slug>.md` — design traceability (TEAM tasks)
- `Closes #N` — issue traceability

/doc-sync reads specs/ + PR diffs at stabilization to update SRS/SDD/UAT/RISK.

## Quality Gates

```
Gate 1: /sop-qa PASS        ──▶ Can create PR
Gate 2: CI green             ──▶ Can merge
Gate 3: Docker health check  ──▶ Deploy confirmed
Gate 4: docs/ updated        ──▶ CMMI compliance
```

## Artifact Inventory

| Artifact | Location | Created By | Updated |
|----------|----------|-----------|---------|
| SRS (Requirements) | `<project>/docs/SRS.md` | Dev oracle | Per feature PR |
| SDD (Design) | `<project>/docs/SDD.md` | Dev oracle | Per feature PR |
| UAT (Test Cases) | `<project>/docs/UAT.md` | Dev oracle | Per feature PR |
| RTM (Traceability) | `<project>/docs/RTM.md` | Dev oracle | Per feature PR |
| Project Plan | `<project>/docs/PROJECT_PLAN.md` | Gale | Per milestone |
| QA Report | PR comment | Dev oracle (/sop-qa) | Per PR |
| Retro | `ψ/memory/retrospectives/` | Oracle (/rrr) | Per session |
| Learnings | `ψ/memory/learnings/` | Oracle (arra_learn) | Continuous |

---

*Oracle Fleet SDLC — CMMI L3 Defined Process*
*"Patterns Over Intentions" — we observe what happens, document what works.*
