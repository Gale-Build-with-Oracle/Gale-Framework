# Org Process Quality Assurance (write-once)

> Written ONCE for the fleet. CMMI L3 PPQA wants objective evidence that the defined process is actually followed — not a separate bureaucracy. The fleet's PQA is mostly automated through the existing gates; this defines the cadence and the escalation.

## Revision History
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2026-06-01 | Gale | Initial PQA cadence |
| 1.0.1 | 2026-06-02 | Gale | High-risk row: `/sop-review` before merge (Kati only on escalation), replacing "Kati / no merge without SHIP" |

## Per-change assurance (automatic, every PR)

The process is enforced at the point of work, not audited after the fact:

| Check | Gate | Blocks |
|---|---|---|
| Code quality + security + a11y + perf | `/sop-qa` | P0/P1 block the PR |
| Traceability thread (PR description carries its `REQ:` line) | `/sop-qa` Phase 7.5.1 | flagged (P2) |
| Doc-sync freshness (`docs/.last-doc-sync` current at UAT/release) | `/sop-qa` Phase 7.5.2 release gate | **P1 blocks UAT/release** |
| Independent review before merge | `/sop-review` | no merge without a verdict |
| High-risk (backend/API/DB/security) | `/sop-review` (harder) | merge after a clean verdict; Kati only on escalation (verdict inconclusive or Wind asks) |
| Root cause after an escaped defect | `/post-mortem` + RISK.md CAR | issue stays open until written |

## Quality is enforced by gates, not audits

The per-change gates above ARE the assurance. No separate periodic audit is needed — the hooks and skills enforce the process at the point of work. If a gate is missing or weak, fix the gate (add a hook, tighten a skill), not schedule a review meeting.

**Three repeats of the same friction → fix the root cause** (a gate, a reminder, a skill edit) — not another manual rule. Non-compliance is a process problem, not a person problem.
