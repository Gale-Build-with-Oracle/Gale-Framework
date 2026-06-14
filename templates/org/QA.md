# Org Process Quality Assurance (write-once)

> Written ONCE for the fleet. CMMI L3 PPQA wants objective evidence that the defined process is actually followed — not a separate bureaucracy. The fleet's PQA is mostly automated through the existing gates; this defines the cadence and the escalation.

## Revision History
| Version | Date | Author | Change |
|---------|------|--------|--------|
| 1.0.0 | 2026-06-01 | My Oracle | Initial PQA cadence |
| 1.0.1 | 2026-06-02 | My Oracle | High-risk row: `/scrutinize` before merge (QA Oracle only on escalation), replacing "QA Oracle / no merge without SHIP" |

## Per-change assurance (automatic, every PR)

The process is enforced at the point of work, not audited after the fact:

| Check | Gate | Blocks |
|---|---|---|
| Code quality + security + a11y + perf | `/sop-qa` | P0/P1 block the PR |
| Traceability thread (PR description carries its `REQ:` line) | `/sop-qa` Phase 7.5.1 | flagged (P2) |
| Doc-sync freshness (`docs/.last-doc-sync` current at UAT/release) | `/sop-qa` Phase 7.5.2 release gate | **P1 blocks UAT/release** |
| Independent review before merge | `/scrutinize` | no merge without a verdict |
| High-risk (backend/API/DB/security) | `/scrutinize` (harder) | merge after a clean verdict; QA Oracle only on escalation (verdict inconclusive or Your Name asks) |
| Root cause after an escaped defect | `/post-mortem` + RISK.md CAR | issue stays open until written |

## Periodic assurance (cadence — lightweight)

| Activity | Frequency | Owner | Output |
|---|---|---|---|
| **Process audit** — sample N recent PRs: was the lifecycle followed (code-first, `REQ:` line, `/sop-qa`, `/scrutinize`)? Was `/doc-sync` run before each UAT/release? | Monthly | My Oracle | a short note in this file's audit log below; non-compliances become process fixes |
| **Measurement review** — read `MEASUREMENT.md` numbers, act on movement | Monthly | My Oracle | actions, not a dashboard |
| **Standard-process review** — is `PROCESS.md` still matching reality? | Quarterly | My Oracle | patch the org docs (Patterns over Intentions) |

## Escalation

A non-compliance is a **process** problem first, not a person problem. The fix is to make the right thing the easy/automatic thing (a gate, a reminder, a skill edit) — not another manual rule. Three repeats of the same friction → fix the root cause (parent CLAUDE.md Self-Evaluation Loop).

## Audit log

First audit due **2026-07-01** (monthly cadence anchored to the 2026-06-01 v1.0.0 start). Schedule a recurring reminder with `/schedule` (monthly) or a crontab ping to `01-my-oracle:my-oracle.1`; sample 5 recent PRs and record below.

| Date | Sample | Finding | Action |
|------|--------|---------|--------|
| _(first monthly audit due 2026-07-01)_ | | | |
