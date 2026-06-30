# Wind-Framework Templates

## Active Templates

| Path | Used by | Purpose |
|---|---|---|
| `cmmi/*.tmpl` | `scripts/init-project-docs.sh` | Per-project 7-doc stubs (SRS, SDD, UAT, CR, RISK, UXUI, PROJECT_PLAN) |
| `org/PROCESS.md` | `/sop-cmmi` §7b | Fleet SDLC lifecycle |
| `org/SDLC_LIFECYCLE.md` | `/sop-cmmi` §7b | CMMI L3 process flow + quality gates |
| `org/QA.md` | `/sop-cmmi` §7b | Process quality assurance cadence |
| `org/MEASUREMENT.md` | `/sop-cmmi` §7b | GQM metrics |
| `org/TAILORING.md` | `/sop-cmmi` §7b | Project tailoring rules |
| `project-agents-template.md` | `/sop-new-project` | AGENTS.md template for product repos |
| `project-claude-template.md` | `/sop-new-project` | CLAUDE.md template for product repos |
| `team-charters/sprint.yaml` | `/sop-maw` | Ephemeral team charter template |
| `start.md` | Bootstrap script | Fresh-machine Oracle setup |

## Superseded (Nothing is Deleted)

`templates/.superseded/` contains retired templates:
- `project-docs/` — old standalone doc versions that conflicted with `cmmi/*.tmpl` (different format)
- `cmmi-archive/` — old 35-doc CMMI system (retired for lean 7-doc standard)
- `github-actions/` — CI templates (unreferenced by any skill)

## How Projects Get Docs

```
scripts/init-project-docs.sh --project-name <NAME>
    → copies cmmi/*.tmpl → <project>/docs/*.md
    → substitutes {{PROJECT_NAME}}, {{DATE}}, {{REQ_ID_PREFIX}}
```

## Relationship: specs/ vs docs/

Projects may have BOTH `specs/` and `docs/`:
- `specs/<N>-slug.md` — design intent (written BEFORE coding via `/sop-design`)
- `docs/*.md` — CMMI compliance docs (written AFTER stabilization via `/doc-sync`)

`/doc-sync` reads specs/ as design context to write docs/. They are never duplicates.
