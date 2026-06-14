# Org Measurement Approach (write-once)

> Written ONCE for the fleet. CMMI L3 wants measurement tied to objectives, not vanity metrics. This defines the few numbers the fleet tracks and why. Keep it lean — a metric nobody acts on is churn.

## Revision History
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2026-06-01 | My Oracle | Initial measurement approach |

## Goal → Question → Metric (GQM)

| Goal | Question | Metric | Source |
|---|---|---|---|
| Ship fast | How long from intake to merge? | **Cycle time** (intake → merge) | git/PR timestamps |
| Ship correct | How often do defects escape to production? | **Defect-escape rate** (prod bugs ÷ merged PRs) | RISK.md CAR entries vs PR count |
| Keep docs honest | Do non-exempt PRs carry their doc deltas? | **Doc-completeness** (% non-exempt PRs with required docs) | `/sop-qa` Phase 7.5 |
| Keep review real | Is `/scrutinize` actually run before merge? | **Review coverage** (% merges with a scrutinize verdict) | PR comments |
| Keep docs cheap | Is doc work proportional to the diff? | **Doc/code line ratio** per PR (watch for churn spikes) | diff stats |

## How it's collected

- **Cheap + automatic first.** Prefer numbers derivable from git, PRs, and `/sop-qa` output. No manual spreadsheets.
- **Cadence**: reviewed monthly (see `QA.md`). A metric is only worth keeping if a number moving triggers an action.
- **Owner**: My Oracle aggregates; Research Oracle assists on reporting (per fleet cadence).

## Acting on the numbers

The point of measurement is the **feedback loop**, not the dashboard:
- Cycle time climbing → look for a process bottleneck (review wait, doc churn).
- Defect-escape rising → tighten `/sop-qa` or `/debug-mantra` discipline; write the CAR.
- Doc/code ratio spiking → delta-discipline is slipping (full rewrites instead of deltas) — see `/sop-cmmi` §2.

Targets and process-performance baselines are deferred until there are enough data points to be meaningful (don't invent baselines from noise).
