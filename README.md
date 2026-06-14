# Gale-Framework

Gale-Framework is a public starter template for a 3-layer ephemeral multi-agent Oracle workflow system for Claude Code + Codex.

It helps teams reduce LLM session amnesia and context loss by making every task enter a fresh project-scoped worktree, capture decisions in durable files, and route implementation through short-lived workers that commit their slice before disappearing.

## Why this exists

Long-running AI coding sessions lose context, mix projects, and make it hard to prove who changed what. Gale-Framework packages a repeatable operating pattern:

- one permanent Oracle layer for intake, dispatch, review, and merge decisions;
- one task-scoped orchestrator layer for planning and worker coordination;
- one ephemeral worker layer for focused code changes and commits;
- local knowledge and documentation files that survive session restarts.

The goal is not to hide automation. The goal is to make AI-assisted work auditable, restartable, and easy to fork for your own projects.

## Quick start

```bash
git clone https://github.com/<your-github-user>/Gale-Framework.git
cd Gale-Framework
bash scripts/setup.sh
```

After setup, fork the upstream repositories you plan to use, point the template configuration at your forks, and add your projects in `fleet/projects.yaml`.

### Verify the full system (including the L3 worktree layer)

`scripts/setup.sh` wires the complete maw-js system with **zero manual config** — the L1 oracle, the L2 `maw workon` orchestrator, and the **L3 ephemeral OMX worker layer** (`maw team spawn --wt --engine omx`). It installs the `codex` + `omx` engines, puts the trust-prime launchers on `PATH`, and seeds the maw engine map so OMX workers never silently fall back to Claude.

Confirm it end to end at any time:

```bash
bash scripts/maw-check.sh    # expect all ✓
```

`maw-check` verifies: core binaries, the `codex`/`omx` launchers + engines, the four engine-map keys (`codex`, `omx`, `codex-resume`, `omx-resume`) that guard against silent fallback, the Claude hooks + fan-out gate, codex trust pre-prime, and `maw workon` / `team` / `done`. A green run means `maw workon <repo> <slug>` → `maw team spawn <team> w1 --wt --engine omx --exec` → `maw done` works out of the box.

## Upstream repositories

Users fork these upstream repositories themselves and keep their forks under their own account or organization.

| Upstream Repo | Purpose |
| --- | --- |
| `Soul-Brews-Studio/maw-js` | tmux orchestration CLI (BUSL-1.1) |
| `Soul-Brews-Studio/maw-ui` | Web dashboard |
| `Soul-Brews-Studio/arra-oracle-v3` | Oracle brain / knowledge base |
| `Soul-Brews-Studio/arra-oracle-skills-cli` | Skills installer |
| `Soul-Brews-Studio/maw-plugin-registry` | Plugin ecosystem |
| `Soul-Brews-Studio/ui-oracle` | UI oracle interface |

See [docs/UPSTREAM-REPOS.md](docs/UPSTREAM-REPOS.md) for fork commands and dependency order.

## Documentation

- [Architecture](docs/ARCHITECTURE.md) — the L1/L2/L3 workflow model, merge gate, project-scope injection, and SOLO vs TEAM routing.
- [Upstream repos](docs/UPSTREAM-REPOS.md) — what each upstream component does and how to fork it.
- [Fork patches](docs/FORK-PATCHES.md) — optional reliability patches to apply in your own forks.
- [Cross-platform notes](docs/CROSS-PLATFORM.md) — Linux, WSL2, and macOS setup differences.
- [Customization](docs/CUSTOMIZATION.md) — adding projects, oracles, fleet config, and doctrine changes.
- [Notice](NOTICE.md) — license and upstream attribution.

## Repository status

This repository is a wrapper template. It does not vendor the upstream tools. Keep upstream repositories as separate forks so their histories, licenses, and update paths remain clear.

## License

Gale-Framework is released under the MIT License. See [LICENSE](LICENSE).
