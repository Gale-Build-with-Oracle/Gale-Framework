---
name: sop-design
description: 'Lightweight design spec before coding — captures objective, decisions, data model, API shape, UI flow, and success criteria in specs/<N>-<slug>.md. Triggers: "design this", "spec this", "what''s the design", or automatically when L2 starts a TEAM task. Skip for SOLO (config/typo/env).'
---

# /sop-design — Design Spec (Before Coding)

> Design is not docs. A spec is not an SRS. Capture design intent BEFORE coding so /doc-sync can write docs that explain WHY, not just WHAT.

## When to Use

- **TEAM tasks (MANDATORY):** L2 writes the spec BEFORE spawning OMX workers. Workers receive the spec path in their brief.
- **SOLO tasks with logic:** Optional but recommended if the change involves architectural decisions.
- **Skip for:** Config/typo/env (≤2 files, zero logic). The Task Brief is sufficient.

Triggers: "design this", "spec this", "what's the design", or automatically when L2 starts a TEAM task.

## The Spec File

Lives in `specs/` at the project root. Named by issue number: `specs/<N>-<slug>.md`.

```
project-root/
├── docs/           # CMMI 7 docs (SRS, SDD, UAT...)
├── specs/          # Design specs (permanent history)
│   ├── 42-user-roles.md
│   ├── 45-cr-user-roles-3tier.md
│   └── 51-api-pagination.md
├── src/
└── CLAUDE.md
```

### Template

```markdown
# SPEC-<N>: [Feature/Change Title]

Issue: #N
Date: YYYY-MM-DD
Strategy: SOLO | TEAM
Supersedes: (only if CR changing prior design — e.g., SPEC-42 §Decision 1)

## Objective
What we're building and why. Who benefits. What success looks like.

## Seams (Test Surfaces)
Where will integration tests cross the codebase? Identify the fewest seams possible, preferring existing seams at the highest level.
- [ ] Seam 1: [e.g., API endpoint POST /users — tests hit this boundary]
- [ ] Seam 2: [e.g., DB query getAvailableLots — tests verify this returns correct data]

If only one seam is needed, that's ideal. Confirm with Wind before writing design decisions.

## Design Decisions
Key choices with rationale (these flow into RISK.md Decisions/DAR at doc-sync):

### Decision 1: [Title]
- **Chose:** [what]
- **Why:** [rationale]
- **Rejected:** [alternative and why not]

## Data Model Changes
(skip if none)
Tables/columns/relationships affected. Schema diff or description.

## API Shape
(skip if none)
New/changed endpoints. Request/response shape. Error semantics.

## UI Flow
(skip if none)
Screens, states, transitions. Key interaction patterns.

## Success Criteria
Testable conditions — reframed from vague requirements:
- [ ] [specific measurable criterion]
- [ ] [specific measurable criterion]

## Boundaries
- **Always:** [non-negotiable constraints]
- **Ask first:** [decisions that need Wind's input]
- **Never:** [explicit exclusions]

## Out of Scope
What this does NOT change (prevents scope creep).
```

## Rules

1. **Write before workers spawn.** L2 creates the spec before `maw team spawn`. Workers receive the spec path in their `--prompt` brief.
2. **Update when decisions change.** If implementation reveals the data model needs to change — update the spec FIRST, then code. Discipline, not a hook gate.
3. **Skip sections that don't apply.** Backend-only? Skip "UI Flow." No DB? Skip "Data Model." As short as possible.
4. **Commit to feature branch.** The spec rides the PR into main. Permanent (Nothing is Deleted).
5. **One spec per issue.** Each GitHub Issue gets ONE spec file. Never spec1/spec2/spec3.
6. **CRs create new specs.** When Wind changes requirements → new CR issue (#45) → new spec (`specs/45-cr-slug.md`) with `Supersedes: SPEC-42 §Decision 1`. Old spec stays untouched.
7. **PR references the spec.** PR description carries `SPEC: specs/<N>-<slug>.md` alongside `REQ: REQ-<PROJECT>-NNN`.
10. **Create CONTEXT.md if first spec.** When creating a project's first spec (no `specs/` directory yet), also create a `CONTEXT.md` at the project root — a pure domain glossary with terms from this feature. Format: `**Term**: definition. _Avoid_: synonym1, synonym2`. No implementation details — just shared vocabulary. See `matt/domain-modeling` for the full methodology.

## How Specs Connect to Docs

The spec is NOT a doc. It's a BRIDGE:

```
SPEC (design intent)  ──→  /doc-sync reads specs/  ──→  DOCS (SRS/SDD/UAT)
     ↑                                                        │
     └──── update when decisions change ───────────────────────┘
```

- **Design Decisions** → flow into RISK.md Decisions/DAR as ADR entries
- **Objective + Success Criteria** → inform SRS requirement descriptions (the WHY)
- **UI Flow** → inform UXUI.md
- **API Shape + Data Model** → inform SDD.md generation
- **Supersedes chain** → CR.md change tracking

## 5-Minute Rule

The spec should take ~5 minutes to write. If it's taking longer, the feature is too large — split it into smaller issues, each with its own spec.

If you're spending more time writing the spec than coding would take, you're over-engineering the spec. Write the minimum that captures design intent. Three sentences in "Objective" + one design decision + two success criteria is a valid spec.

> **Quality backbone reference:** See `addy/spec-driven-development` for the full 4-phase gated workflow (SPECIFY→PLAN→TASKS→IMPLEMENT) and `addy/documentation-and-adrs` for ADR methodology.
