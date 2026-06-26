# Doc-sync enforcement audit pattern

Use this when Wind reports that the intended `REQ:` → PR → `/doc-sync` workflow is not behaving like the design.

## Intended design

Feature PRs should carry traceability only:

```text
Closes #N

REQ: REQ-<PROJECT>-NNN
```

or, for true refactor/chore/no-contract changes:

```text
REQ: none
```

Docs are then updated in one docs-only `/doc-sync` batch at stabilization/UAT/release. The batch reads merged PRs since `docs/.last-doc-sync`, updates SRS/UAT/CR/RISK/UXUI as needed, and advances the marker only after docs match reality.

## Audit checklist

1. **Doctrine exists**
   - Check the canonical doctrine/skill says feature PRs need `REQ:` and docs are batch-synced later.
   - Watch for stale project `AGENTS.md` or `CLAUDE.md` that still says docs must be updated in the same PR or references `RTM.md`.

2. **PR creation path actually writes the line**
   - Inspect the PR creation tool (`maw pr`, `gh pr create` wrapper, scripts) and confirm the body includes a `REQ:` line.
   - A common drift shape is `maw pr` only emitting `Closes #N`, while doctrine assumes `REQ:` exists.

3. **Gate is executable, not only written in prose**
   - A `grep` example inside `/sop-qa` is not hard enforcement unless it is actually run and surfaced as a failing/blocking condition in the workflow.
   - Prefer preventing bad PR body creation over relying on every worker to remember the checklist.

4. **`/doc-sync` exists as a runnable skill/script**
   - Search for a real skill or script implementation, not just references in doctrine.
   - If missing, the system is half-migrated: doctrine changed but tooling did not follow.

5. **Marker reality check**
   - Check each project has `docs/.last-doc-sync`.
   - Count merged PRs after the marker. A missing marker or marker behind many merge commits means doc-sync lifecycle is not operating.
   - Do not blindly advance the marker; that hides drift. First run/backfill docs to match merged behavior.

## Root-cause framing

Treat this class as a **doctrine/tooling/enforcement mismatch**, not as agent forgetfulness. The durable fix is to make the happy path (`maw pr` and `/doc-sync`) produce the expected artifacts automatically, then use QA as a guardrail.