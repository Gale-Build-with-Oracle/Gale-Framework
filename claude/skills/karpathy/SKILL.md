---
name: karpathy
description: 'Behavioral guidelines to reduce common LLM coding mistakes.'
license: MIT
source: https://github.com/forrestchang/andrej-karpathy-skills (forked → deachawatss/andrej-karpathy-skills)
adopted: 2026-04-18 by Gale (Wind's fleet)
---

# Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

> **In the Gale fleet**, this overlaps with `shared-claude.md` §"Before You Diagnose or Build" (audit existing state first). The Karpathy framing extends that rule to *intent* ambiguity, not just state ambiguity.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

> **In the Gale fleet**, the Claude Code default system prompt already covers this at the harness level. This skill restates it explicitly so Oracles see it on demand.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

> **In the Gale fleet**, this is a NEW rule. Field-test trigger: when delegating a "fix X" task, devs sometimes ship a PR that also touches unrelated formatting/types/comments. Use `/karpathy` in --prompt when scope discipline matters.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

> **In the Gale fleet**, translate Wind's task into testable acceptance criteria BEFORE writing code, not after — verifiable artifacts are what `/sop-review` checks the PR against.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

**Original repo**: https://github.com/forrestchang/andrej-karpathy-skills (MIT)
**Examples**: see EXAMPLES.md in the source repo for 522 lines of before/after Python.
