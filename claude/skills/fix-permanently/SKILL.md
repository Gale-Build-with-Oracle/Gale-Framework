---
name: fix-permanently
description: 'Root-cause fix discipline (แก้ที่ต้นเหตุ) — the FAST path for fixing a KNOWN cause correctly without the full /sop-debug loop. ALWAYS/NEVER fix rules, anti-pattern detection, permanence check. Trigger on /fix-permanently, or whenever you already know where a bug originates and just want to fix the source, not the symptom.'
---

# /fix-permanently — Root Cause Fix Discipline

> "แก้ที่ต้นเหตุ — Fix at the root cause. If you patch the symptom, the disease spreads."

This skill exists because the same mistake keeps happening: Oracle finds a problem, applies a quick workaround, and the real bug survives to bite again. The rule is absolute — **fix the source code, not the symptoms.**

## When to use this vs /sop-debug

They answer different questions — don't reach for the heavy one when you don't need it.

| Situation | Use |
|---|---|
| You **don't know where** the bug comes from — need to reproduce, localize, trace, falsify a hypothesis | **`/sop-debug`** (the 7-phase find-the-cause loop) |
| You **already know the root cause** (obvious, or you just localized it) and want the guardrails to fix it RIGHT — not patch the symptom | **`/fix-permanently`** (this skill) |

If mid-fix you realize you don't actually understand the cause, stop and switch to `/sop-debug` — a fix applied to the wrong spot is just another symptom patch.

## The Protocol

When you already have a cause in hand, follow this sequence. Do not skip the verification steps.

### Step 1: Confirm the cause (not just the symptom)

You should be able to state, in one sentence: "The bug happens because `<X>` at `<file:line>`." If you can't, you haven't found the root cause — go to `/sop-debug`.

Ask yourself: "If I fix this spot, will the problem be **impossible** to recur?" If the answer is no, the cause is deeper.

### Step 2: Check for a Working Version

Before concluding something is broken, check if another instance of the same thing works on this machine. If it does, the fix is in the DIFF between working and broken — not in adding new code.

```bash
# Find working versions
which <tool>; type <tool>
ls -la <path>; readlink -f <path>
diff <working> <broken>
```

### Step 3: Fix the Source

Apply the fix at the origin point. These are the rules:

**ALWAYS:**
- Fix the actual source code that produces the error
- Fix the data/config that causes the bad state
- Add validation at the boundary where bad input enters
- Make the fix so the error CANNOT recur (structural fix)

**NEVER:**
- `|| true` / `2>/dev/null` / `catch {}` to silence errors
- `--no-verify` / `--force` / `--skip-checks` to bypass gates
- Wrapping broken code in try-catch without fixing the throw
- Adding a "if broken, use fallback" path (that's two bugs now)
- Removing or weakening CI checks, lint rules, or type checks
- Adding comments like "TODO: fix later" or "workaround for X"
- Renaming unused variables with `_` prefix to dodge lint

### Step 4: Verify the Fix is Permanent

```
- Does the original reproduction path now succeed?
- Does the fix survive a clean rebuild / restart? (verify live, not on a proxy)
- Are there other places with the same pattern? (grep for siblings)
- Would a new developer hit this again? If yes, add a guard.
```

### Step 5: Prevent Recurrence

If the bug class can happen again elsewhere, add structural prevention:

- Type system constraints that make the bad state unrepresentable
- Validation at the input boundary
- A test that would catch regression
- CI check if the pattern is widespread

## Real Examples from Our History

| Problem | Wrong Fix | Right Fix |
|---------|-----------|-----------|
| CI clippy warnings fail build | Remove `-D warnings` flag | Fix the actual clippy warnings in source |
| Cargo.lock out of sync after feature change | Delete Cargo.lock | `cargo update -p <crate>` to regenerate properly |
| .NET missing namespace | Add NuGet package | Add `using Microsoft.AspNetCore.RateLimiting;` |
| HMAC comparison timing attack | `===` string compare | `timingSafeEqual()` |
| Worktree gate blind to legacy layout | Add a special-case for the one machine | One `_is_wt()` matching the union of layouts, routed through every guard |
| PR queue never drains | Hand-edit the state file each time | Wire the dead reconcile fn so the queue self-heals against GitHub |
| doc-sync finds 0 squash-merged PRs | Manually list PRs | Drop `--merges` so the scan walks the first-parent mainline |

## Anti-Pattern Detection

If you catch yourself typing any of these, STOP and reconsider:

```
"as a workaround..."
"for now, we can..."
"to get around this..."
"let's just skip..."
"we can suppress..."
"ignore this error..."
"disable the check..."
"fallback to..."
"temporary fix..."
```

These phrases are symptoms of not having found the root cause yet. If you're unsure of the cause, go to `/sop-debug`.

## The Mindset

Every bug is a gift — it reveals where the system is weak. A workaround hides the weakness. A root-cause fix makes the system stronger than before the bug existed.

The goal is not "make the error go away." The goal is "make the error impossible."

## Cross-references

- `/sop-debug` — the full 7-phase discipline for FINDING an unknown cause (feedback loop → localize → trace → falsify → breadcrumb → fix → guard). This skill is the fix-phase on its own, for when the cause is already known.
- `/post-mortem` — run after a notable bug fix to capture the lesson.
