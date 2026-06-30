---
name: sop-review
description: 'Six-step pre-merge review — intent questioning, two-axis review (Standards vs Spec), five-axis deep review, code path trace, live verification, and severity-labeled report. Consolidates scrutinize + code-review-and-quality + Matt review. Trigger on /sop-review and proactively whenever the user asks to review, audit, sanity-check, or get a second opinion on a plan, PR, diff, design doc, or proposed code change.'
---

# /sop-review — Pre-Merge Review

> Consolidation of scrutinize (intent + trace + Live-Behavior Gate), Addy's code-review-and-quality (five-axis review), and Matt's review (two-axis: Standards vs Spec).

Stand outside the change and ask whether it should exist at all, then verify it actually does what it claims end-to-end.

## Operating Stance

- **Outsider.** Forget who wrote it and why they think it's right. Read the artifact cold.
- **End-to-end, not diff-local.** The diff is the entry point, not the scope. Follow the call graph through real code paths.
- **Actionable, concise, with rationale.** Every finding states what to change, why, and what evidence led you there.

---

## Step 1: Intent — Simpler Alternative Pass (MANDATORY)

Before looking at code, understand the intent:

- State the goal in one sentence, in your own words. If you cannot, the artifact is underspecified — say so and stop.
- Ask: **is there a simpler, smaller, or more elegant way?** Consider:
  - Doing nothing (is the problem real / load-bearing?)
  - Using something that already exists in the codebase
  - A smaller change that solves 90% with 10% of the risk
  - Solving it at a different layer (config vs code, framework vs app, build vs runtime)
- If a better alternative exists, name it with rationale. This is the most valuable output — surface it BEFORE the line-by-line review.

---

## Step 2: Two-Axis Review

Run two independent perspectives. Keep them SEPARATE in the report — do NOT merge findings across axes.

### Axis A: Standards

Does the code follow this repo's coding standards?

- Naming conventions, code style, file organization
- Existing patterns followed (or new one justified)
- Module boundaries respected
- Error handling consistent with project conventions
- Linting and formatting pass

### Axis B: Spec Conformance

Does the code faithfully implement what was asked?

- Check against `specs/<N>-*.md` if design spec exists
- Check against GitHub Issue acceptance criteria
- Check against PR's `REQ:` line traceability
- Out-of-scope additions flagged (scope creep)
- Missing acceptance criteria identified

**Why two axes:** Code can pass Standards but fail Spec (wrong thing correctly written) or pass Spec but fail Standards (right thing poorly written). Mixing them hides failures.

---

## Step 3: Five-Axis Deep Review

For each file changed, evaluate across these dimensions:

### 1. Correctness
- Does it match the spec/task requirements?
- Are edge cases handled (null, empty, boundary values)?
- Are error paths handled (not just the happy path)?
- Are there off-by-one errors, race conditions, or state inconsistencies?

### 2. Readability & Simplicity
- Are names descriptive and consistent?
- Is control flow straightforward (no nested ternaries, deep callbacks)?
- Could this be done in fewer lines? (1000 lines where 100 suffice is a failure)
- Are abstractions earning their complexity?
- Is a new conditional bolted onto an unrelated flow? → design smell
- Do repeated conditionals on the same shape appear? → missing model or dispatcher

### 3. Architecture
- Does it follow existing patterns or introduce a justified new one?
- Does a refactor reduce complexity or just relocate it?
- Is feature-specific logic leaking into a shared module?
- Are type boundaries explicit?

### 4. Security
- Is user input validated and sanitized at boundaries?
- Are secrets kept out of code, logs, and version control?
- Is authentication/authorization checked where needed?
- Are SQL queries parameterized?
- Is external data treated as untrusted (including LLM output)?

### 5. Performance
- Any N+1 query patterns?
- Any unbounded loops or unconstrained data fetching?
- Any missing pagination on list endpoints?

---

## Step 4: Trace the Code Path

For each behavior the change claims, trace the path end-to-end through the REAL code:

- Entry point → call sites → branches taken → state mutated → exit / return / side effect
- Include the **unchanged code** on either side of the diff. Bugs hide at the seams.
- Note every place the trace surprises you. Surprises are signal.

### code-review-graph Integration

Before tracing, check for `.code-review-graph/` in the repo root. If it exists, use MCP tools FIRST (max 5 calls):
1. `get_minimal_context(task=<change summary>)`
2. `detect_changes` — risk-scored list
3. `get_impact_radius` — blast radius of changed symbols
4. `query_graph pattern="tests_for"` — test coverage mapping

Use `detail_level="minimal"` throughout. If the graph answers the question, stop there.

---

## Step 5: Verify

For each claim the change makes:

- **Does the code path you traced actually produce that behavior?** Walk it explicitly.
- **What inputs/states would break it?** Edge cases, concurrent callers, error paths, partial failures.
- **What does it silently change?** Performance, error semantics, observability, contract for other callers.
- **How is it tested?** Do tests exercise the traced path, or pass while skipping it?

### Live-Behavior Gate (MANDATORY for "make X work" changes)

A passing test is necessary but NOT sufficient — it verifies a proxy, not the thing. The change is unverified until the EXACT command/UI/endpoint the user runs has been run and its output observed.

Demand the artifact: `VERIFIED-LIVE: <command> → <observed output>`

If the only evidence is a green test or "it should work," the claim is **unverified** — say so.

---

## Step 6: Report

One tight section per finding. Order by severity (blocker → major → nit).

### Severity Labels (MANDATORY)

Every finding MUST carry a prefix:

| Prefix | Meaning | Author Action |
|--------|---------|---------------|
| **Critical:** | Blocks merge | Security vulnerability, data loss, broken functionality |
| *(no prefix)* | Required change | Must address before merge |
| **Nit:** | Minor, optional | Author may ignore |
| **Optional:** / **Consider:** | Suggestion | Worth considering but not required |
| **FYI** | Informational only | No action needed |

Lead with what matters: correctness and security first, then structural regressions, then everything else.

### Structural Remedies

When flagging a structural problem, propose the move:

- Replace a chain of conditionals → typed model or dispatcher
- Collapse duplicate branches → single clearer flow
- Separate orchestration from business logic
- Move feature-specific logic to its owning package
- Reuse the canonical helper instead of a near-duplicate
- Make a type boundary explicit
- Delete a pass-through wrapper

### Change Sizing

| Size | Guidance |
|------|----------|
| ~100 lines | Good |
| ~300 lines | Acceptable if single logical change |
| ~1000 lines | Too large — request a split |

### Dead Code Hygiene

List orphaned code explicitly. Ask before deleting.

### Dependency Discipline

For new dependencies: (1) Does existing stack solve this? (2) Bundle impact? (3) Actively maintained? (4) Known vulnerabilities? (5) License compatible?

### Verdict

One-line: **ship** | **fix-then-ship** | **rework** | **reject** — with the single biggest reason.

**`ship` is NOT allowed** for a "make X work" change without the `VERIFIED-LIVE:` artifact.

---

## Operating Rules

- **No rubber-stamps.** "LGTM" is not an output. State what you traced and checked.
- **Cite or it didn't happen.** Every claim references a specific path, file, or line.
- **Distinguish claim from verification.** "The PR says X" ≠ "I traced X and confirmed it."
- **One simpler-alternative pass is mandatory.** Skip only if user says "don't question scope."
- **Don't pad with nits when there's a structural problem.** Lead with it.
- **No flattery, no hedging.** State the finding directly.

### Relationship with `/code-review` Plugin

`/code-review` (external plugin) is a TOOL with `--comment`, `--fix`, and `ultra` mode. `/sop-review` is the PROCESS. Use `/code-review` for mechanical bug-finding within the sop-review flow when needed.

> **Quality backbone references:** See `addy/code-review-and-quality` for the full five-axis methodology, multi-model review pattern, and common rationalizations table. See `matt/review` for the two-axis parallel sub-agent pattern.
