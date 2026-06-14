# Requirements Traceability Matrix — <project-name>

- **Document version**: 0.1 (template — unfilled)
- **Source markdown**: `docs/RTM.md`
- **Generated artifact**: `build/docs/rtm-<project-name>-v<ver>.xlsx` (Docs Pipeline)

The RTM is the glue document. It links every requirement in `SRS.md`
forward to design, implementation, test, and defect records so auditors
(and future engineers) can answer the question **"where is this
requirement satisfied, and how do we know?"** without reading the whole
codebase.

---

## How to use this file

### Adding a row

1. Start from `SRS.md` — every new `REQ-<AREA>-<NNN>` gets a new RTM row.
2. Fill columns left-to-right as the requirement progresses through the
   pipeline. A row is allowed to have blank right-hand columns while work
   is in flight; an unblocked row with blanks at release time is a defect.
3. Keep `Status` in sync with reality: `Draft` → `Approved` → `In Dev`
   → `In QA` → `Accepted` → `Released`. Use `Deferred` or `Rejected` as
   terminal statuses when appropriate.
4. Where a cell references another document, use markdown anchors:
   `[REQ-AREA-001](./SRS.md#req-area-001--short-title)`.

### Automated population

A future `scripts/auto-traceability.sh` may parse PR bodies and test file
headers to append rows. Until that script lands, rows are added by hand
by whoever merges the PR that introduces a new requirement.

### Auditing discipline

At every release cut:
- No row may have a blank `UAT case` column.
- `Defects` column links must all be in `Closed` status.
- Any row in `Deferred` must name the release it is deferred to.

---

## Traceability matrix

<!-- TEMPLATE: fill before commit -->

| REQ-ID            | Description                                   | Source (issue / PR)    | Design (SDD §)     | Code files                          | Test files                              | UAT case ID | Status   | Defects  |
|-------------------|-----------------------------------------------|------------------------|--------------------|-------------------------------------|-----------------------------------------|-------------|----------|----------|
| REQ-AREA-001      | <short title>                                 | #                      | §4.x, §4.y         |                                     |                                         | UAT-001     | Draft    | —        |
| REQ-PERF-001      | <perf target description>                     | #                      | §4.10              |                                     |                                         | UAT-002     | Draft    | —        |
| REQ-A11Y-001      | WCAG 2.1 AA conformance on all pages          | #                      | §4.1, §4.6         |                                     |                                         | UAT-003     | Draft    | —        |

*Delete the example rows above and populate with real <project-name>
requirements. Sort by REQ-ID within each AREA.*

---

## Column reference

| Column          | Meaning                                                     |
|-----------------|-------------------------------------------------------------|
| REQ-ID          | Unique ID from `SRS.md` (`REQ-<AREA>-<NNN>`)                |
| Description     | Short title from `SRS.md` — keep under 80 chars             |
| Source          | GitHub issue or PR where the requirement was agreed         |
| Design          | SDD section(s) that realise the requirement                 |
| Code files      | Paths relative to repo root; comma-separated                |
| Test files      | Paths to test suites that verify the requirement            |
| UAT case ID     | Matching row in `UAT.md` §6                                 |
| Status          | `Draft` / `Approved` / `In Dev` / `In QA` / `Accepted` / `Released` / `Deferred` / `Rejected` |
| Defects         | Links to GitHub issues tagged `bug` that blocked acceptance |
