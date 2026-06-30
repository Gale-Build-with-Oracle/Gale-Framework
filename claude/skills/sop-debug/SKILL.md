---
name: sop-debug
description: 'Seven-phase debugging discipline — build a feedback loop, localize, trace, falsify, breadcrumb, fix at root cause, guard. Consolidates debug-mantra + fix-permanently + Addy/Matt debugging patterns. Trigger on /sop-debug and proactively whenever debugging starts — user reports a bug, says something is broken/throwing/failing, asks to debug/diagnose/investigate an issue, or pastes a stack trace or error log.'
---

# /sop-debug — Debugging & Root Cause Fix

> Consolidation of debug-mantra (falsification), fix-permanently (root cause fix), Addy's debugging-and-error-recovery (layer localization), and Matt's diagnosing-bugs (feedback loop taxonomy).

## Recite this — verbatim, as the first thing in your first response

> **Mantra:**
> 1. **First is the feedback loop.** Can I make this bug fire on command?
> 2. **Know the fail path.** Which layer? Debugger first; then trace; then instrument.
> 3. **Question your hypothesis.** What would disprove it?
> 4. **Every run is a breadcrumb.** Cross-reference all of them.

Then begin work.

---

## Phase 1: Build a Feedback Loop

**This phase IS the skill. Everything after is mechanical.**

Build a command that makes the bug fire reliably. Techniques in preference order:

1. **Failing test** at the bug's seam
2. **curl/HTTP script** against running dev server
3. **CLI invocation** with fixture input + stdout diff against known-good
4. **Headless browser script** (Playwright)
5. **Replay a captured trace** (HAR file, log dump, event log)
6. **Throwaway harness** (minimal system subset, single function call)
7. **Property/fuzz loop** (1000 random inputs looking for failure)
8. **Bisection harness** (`git bisect run` with the loop as the test)
9. **Differential loop** (old-version vs new-version, diff outputs)
10. **Manual-loop bash script** (human-in-the-loop — last resort)

**Completion criterion:** Name ONE command. Paste its invocation and output. Confirm it is:
- **Red-capable** — it drives the actual bug code path (not "runs without erroring")
- **Deterministic** — same result every run
- **Fast** — seconds, not minutes
- **Agent-runnable** — no manual steps

**Non-deterministic bugs:** Don't aim for clean repro. Aim for higher reproduction rate. Loop the trigger 100x, parallelize, add stress, narrow timing windows. 50% flake is debuggable; 1% is not.

**Cannot build a loop:** STOP. Say so explicitly. Ask for environment access, captured artifacts (HAR, log dump, core file), or permission to instrument. Do NOT proceed to hypothesize without a red-capable command.

---

## Phase 2: Localize

Which layer is the bug in?

```
Where is the failure?
├── UI rendering / client-side JS
├── API / route handler / middleware
├── Database / query / migration
├── Build tooling / bundler / config
├── External service / third-party API
└── The test itself (false positive)
```

**For regressions:** Use `git bisect run <your-loop-command>` to find the exact commit.

**Reduce to minimal case:** Strip unrelated code until every remaining element is load-bearing for the failure. This is the cheapest way to eliminate false hypotheses.

---

## Phase 3: Trace the Fail Path

Once localized, find WHERE the code breaks and WHAT stops it from breaking. Try in this order — escalate only when the prior tactic fails:

1. **Attach a debugger.** One breakpoint beats ten logs. Do this FIRST.
2. **Source trace + knob enumeration.** Trace the code path end-to-end. List every knob (config flags, env vars, feature toggles, branch conditions, input shape). Flip one at a time.
3. **In-code instrumentation.** Tag every probe with a unique prefix: `[DEBUG-a4f2]`. Cleanup is one grep: `grep -rn '\[DEBUG-' | xargs ...`. Untagged logs survive indefinitely.

---

## Phase 4: Falsify the Hypothesis

When a candidate root cause surfaces, scrutinize it BEFORE testing.

- Does it actually explain the symptom end-to-end? Walk it through.
- What is the simplest **disproof**? Run that FIRST.
- **Generate 3-5 ranked hypotheses**, not one. Single-hypothesis thinking anchors on the first plausible idea.
- Show the ranked list to Wind before testing — cheap checkpoint, often reranks instantly.

If the hypothesis survives disproof, it's real. If it dies, you saved yourself from chasing a phantom.

---

## Phase 5: Breadcrumb Ledger

Maintain a running ledger of every experiment:

| # | Changed | Observed | Ruled in/out |
|---|---------|----------|-------------|
| 1 | ... | ... | ... |

- When a new hypothesis surfaces, walk the ledger. Does it hold for EVERY prior observation?
- If any past run contradicts it, the hypothesis is wrong or incomplete.
- Design the **single decisive experiment** whose outcome makes it certain. Run that next.
- Update the ledger after every run.

---

## Phase 6: Fix at Root Cause

> แก้ที่ต้นเหตุ — fix at root cause, not where it manifests.

**ALWAYS:**
- Fix the source, not the symptom
- Write a regression test (at the correct seam — see Phase 7)
- Check for sister bugs (same pattern elsewhere)
- Verify the fix explains ALL prior breadcrumbs

**NEVER:**
- Patch the renderer when the data is wrong
- Silence the error instead of fixing the cause
- Add a special-case branch for one input
- "Reset state" instead of preventing corruption
- Wrap in try/catch without handling the underlying failure

**Anti-pattern detection** — these phrases signal symptom-patching:
- "just add a null check"
- "wrap it in try/catch"
- "default to empty"
- "skip if undefined"
- "only happens sometimes, so..."
- "let's just restart"
- "add a timeout"
- "filter out the bad data"
- "ignore that case"
- "it works if you clear the cache"

---

## Phase 7: Guard + Cleanup

- [ ] **Regression test** at the correct seam. The seam must exercise the real bug pattern at the actual call site. If no correct seam exists, that itself is a finding — flag for architecture review.
- [ ] **Remove all `[DEBUG-*]` tags** — one grep: `grep -rn '\[DEBUG-'`
- [ ] **Delete throwaway harnesses** created in Phase 1
- [ ] **Winning hypothesis in commit message** — so the next debugger learns
- [ ] **Original repro command now passes** (loop it — must be green)
- [ ] → `/post-mortem` for bug PRs (mandatory per doctrine)

---

## Operating Rules

- Recite the mantra block ONCE per debug session, in your first response. Verbatim.
- Apply the seven phases IN ORDER. Do not skip ahead.
- If you catch yourself proposing a fix without a red-capable command (Phase 1), STOP and return.
- If you catch yourself testing a hypothesis without 3-5 ranked alternatives (Phase 4), STOP and generate more.
- The mantra is a constraint YOU carry — not advice to deliver back to the user.

> **Quality backbone references:** See `addy/debugging-and-error-recovery` for the Stop-the-Line rule and `matt/diagnosing-bugs` for the full 10-technique taxonomy with HITL template.
