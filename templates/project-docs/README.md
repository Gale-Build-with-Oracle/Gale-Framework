# Project Docs — Canonical Template

This directory is the **canonical fleet-wide template** for project
engineering documentation. It is **not** scaffolding for any specific
project. Every new project in the 7-Oracle fleet copies this directory
into its own `docs/` folder as the starting point.

## What's in here

| File     | Standard                        | Purpose |
|----------|---------------------------------|---------|
| `SRS.md` | ISO/IEC/IEEE 29148:2018         | What the product must do, and how each requirement is verified |
| `SDD.md` | IEEE 1016-2009                  | How the product is structured to satisfy the SRS |
| `UAT.md` | IEEE 829-2008 (Test Plan)       | How stakeholders confirm the product is acceptable |
| `RTM.md` | (internal — traceability matrix) | One-to-many links REQ → design → code → test → defect |

These four documents are the minimum viable set for CMMI Level 3
readiness — defined, repeatable process artifacts that hold across every
fleet project regardless of stack.

## How to bootstrap a new project

Use the bootstrap script (created separately by My Oracle):

```bash
My Oracle-Oracle/scripts/init-project-docs.sh <project-name> <target-repo-path>
```

The script copies all five files into `<target-repo-path>/docs/`,
substitutes `<project-name>` placeholders with the real project name, and
prints the count of remaining `TEMPLATE:` markers (prose + Mermaid) for
the dev Oracle to fill.

Manual bootstrap (without the script):

```bash
cp -r My Oracle-Oracle/templates/project-docs/* <target-repo>/docs/
cd <target-repo>/docs/
# substitute the project name everywhere
sed -i 's/<project-name>/my-project/g' *.md
# count remaining fill-points
grep -rn 'TEMPLATE:' .
```

## Mermaid mandate

**All diagrams are embedded as Mermaid code-blocks inside the markdown.**
There are no separate `.svg`, `.png`, `.drawio`, or `.puml` files. This
is a fleet-wide rule with three reasons:

1. **Diff cleanly in git**: text diffs over binary blobs.
2. **Render natively on GitHub**: PR review surface includes the diagram.
3. **Single source of truth**: no drift between "the diagram file" and
   "the markdown that describes it".

Mermaid blocks live in the IEEE-correct sections:

| File | Section | Diagram type |
|------|---------|--------------|
| SRS  | §2.1 Product Perspective | `flowchart LR` — System Context |
| SRS  | §3.2 Functional Requirements | `flowchart LR` — Use Case overview |
| SDD  | §4.1 Context View | `flowchart LR` — System Context (detailed) |
| SDD  | §4.2 Composition View | `flowchart TD` — Subsystem Decomposition |
| SDD  | §4.4 Information View | `erDiagram` — Entity-Relationship |
| SDD  | §4.7 Interaction View | `sequenceDiagram` — Key user flow |
| SDD  | §4.11 Database Architecture | `flowchart TD` — Deployment Topology |
| UAT  | §8 Approach | `flowchart TD` — Test flow |

Each Mermaid block is marked `%% TEMPLATE: replace with project-specific
entities/flows`. Grep for `TEMPLATE:` to find every fill-point.

### Mermaid → image rendering

- **GitHub** renders Mermaid inline in the rendered markdown view. No
  pre-rendering needed.
- **Pandoc DOCX/PPTX** (Docs Pipeline's publishing pipeline) does **not** render
  Mermaid by default. Two paths:
  - **v1 (today)**: DOCX shows the raw Mermaid code-block as monospace
    text. Acceptable for the first pipeline pass — auditors can read the
    structure even unrendered.
  - **v2 (Docs Pipeline upgrade)**: install `mermaid-filter` Pandoc
    plugin so DOCX/PPTX get embedded PNGs at build time. Tracked
    separately by Docs Pipeline.

Either way, the markdown stays the single source of truth.

## Versioning convention

The template itself is **unversioned** — it lives at HEAD on
`My Oracle-Oracle/main` and updates propagate to new projects on next
bootstrap. The template is not retroactively re-applied to projects that
have already filled it in.

**Per-project versioning** (defined in each project's own `docs/`
folder):

```
SRS.md                        ← always the latest draft (PR-able)
srs-<project-name>-v1.0.md    ← frozen snapshot at v1.0 release
srs-<project-name>-v1.1.md    ← frozen snapshot at v1.1 release
```

Pattern: `<doctype>-<project-name>-vMAJOR.MINOR.md` (lowercase doctype).

Generated binary deliverables (DOCX for SRS/SDD, PPTX for exec briefings,
PDF bundles) are **not** committed. They live under `build/docs/` which
should be covered by each project's `.gitignore`. Regenerate from
markdown via the Docs Pipeline when needed.

## Format Strategy

Each document type has a designated output format matching its primary consumer:

| Doc | Output format | Rationale |
|-----|--------------|-----------|
| `SRS.md` | `.docx` (DOCX, branded, paginated) | Narrative prose — auditors and stakeholders read linearly |
| `SDD.md` | `.docx` (DOCX, design views with embedded Mermaid) | Design views benefit from page layout and section headers |
| `UAT.md` | `.xlsx` (XLSX, multi-sheet) | Test cases and pass-fail tracking are tabular; customers fill Status per cycle in Excel |
| `RTM.md` | `.xlsx` (XLSX, single sheet) | Traceability matrix is naturally a wide spreadsheet; filter/sort are essential |
| Exec briefing | `.pptx` (optional) | Kick-off or steering committee presentations; generated on request |

**Pandoc baseline is BANNED for production output.** Raw pandoc produces unstyled, unbranded
documents that fail the CMMI L3 presentation standard. All artifact generation MUST go through
the fleet skills:

- `/document-skills:docx` — branded DOCX with correct styles, headers, footers
- `/document-skills:xlsx` — structured XLSX with locked headers, dropdowns, conditional formatting
- `/document-skills:pptx` — branded PPTX with master slides

Docs Pipeline's publishing pipeline calls these skills automatically post-merge. Dev Oracles must never
invoke pandoc directly for deliverable generation.

## Ownership

- **Author of first drafts**: assigned dev Oracle (Dev Oracle for Solution
  Lab, Dev Oracle for YourProject)
- **Reviewer**: My Oracle (orchestration + standards compliance)
- **QA sign-off on UAT**: QA Oracle (QA & compliance Oracle)
- **Publisher**: Docs Pipeline (content + branding pipeline)
