---
name: fix-permanently
description: 'Root-cause fix discipline — แก้ที่ต้นเหตุ.'
---

# /fix-permanently — Root Cause Fix Discipline

> "แก้ที่ต้นเหตุ — Fix at the root cause. If you patch the symptom, the disease spreads."

This skill exists because the same mistake keeps happening: Oracle finds a problem, applies a quick workaround, and the real bug survives to bite again. Wind's rule is absolute — **fix the source code, not the symptoms.**

## The Protocol

When you encounter a bug or error, follow this sequence. Do not skip steps.

### Step 1: Reproduce and Observe

Before touching any code, confirm the problem exists and understand its shape.

```
- What is the exact error message or broken behavior?
- When did it start? (git log, timestamps, recent changes)
- Does it happen consistently or intermittently?
- What is the minimal reproduction path?
```

### Step 2: Trace to Root Cause

Find WHERE the problem originates, not where it surfaces. The symptom and the cause are rarely in the same file.

```bash
# Trace the error backward through the call chain
# Read the actual source code — don't guess from memory
# Check git blame — who changed this and when?
# Diff against the last known working state
```

Ask yourself: "If I fix this spot, will the problem be impossible to recur?" If the answer is no, you haven't found the root cause yet.

### Step 3: Check for a Working Version

Before concluding something is broken, check if another instance of the same thing works on this machine. If it does, the fix is in the DIFF between working and broken — not in adding new code.

```bash
# Find working versions
which <tool>; type <tool>
ls -la <path>; readlink -f <path>
diff <working> <broken>
```

### Step 4: Fix the Source

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

### Step 5: Verify the Fix is Permanent

```
- Does the original reproduction path now succeed?
- Does the fix survive a clean rebuild / restart?
- Are there other places with the same pattern? (grep for siblings)
- Would a new developer hit this again? If yes, add a guard.
```

### Step 6: Prevent Recurrence

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
| Stale team dirs after shutdown | Manual cleanup script | Fix `cleanupTeamDir()` to clean all 3 write locations |
| Codex workers leave zombie processes | Ignore them | Kill stale processes + fix spawn lifecycle |

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

These phrases are symptoms of not having found the root cause yet. Go back to Step 2.

## The Mindset

Every bug is a gift — it reveals where the system is weak. A workaround hides the weakness. A root-cause fix makes the system stronger than before the bug existed.

The goal is not "make the error go away." The goal is "make the error impossible."
