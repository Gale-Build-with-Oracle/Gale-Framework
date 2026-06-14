# <Project-Name> — Codex Worker Rules

<!-- LAYERED CONTEXT: this file = PROJECT CONTEXT ONLY (Layer 3).
     Fleet doctrine is GLOBAL (FLEET-DOCTRINE block in ~/.codex/AGENTS.md) and loads alongside this
     file in every session. Project AGENTS.md OVERRIDES global on conflict — so a
     doctrine copy here would silently win as it goes stale. NEVER copy doctrine. -->

## <Project-Name>-Specific Rules

<!-- stack, testing surface (Docker-only for YourProject), ports, env quirks — facts only -->

<!-- FLEET-DOCTRINE:fan-out — managed by fleet-sync; thin pointer, never a doctrine copy -->

Fleet doctrine (Fan-Out Strategy, Work Pattern, Merge Gate, hard constraints) is GLOBAL:
codex loads it from the FLEET-DOCTRINE block in ~/.codex/AGENTS.md (rendered from <framework-repo> codex/instructions.md; codex reads AGENTS.md, not instructions.md).
This file carries ONLY project-specific rules (stack, schema, commands, testing surface).
Do NOT copy fleet doctrine into this file — project AGENTS.md overrides global, so a stale copy silently wins.

<!-- /FLEET-DOCTRINE:fan-out -->
