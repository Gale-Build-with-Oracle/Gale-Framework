# Upstream Repositories

Gale-Framework is a wrapper template. It orchestrates upstream tools rather than vendoring them. Fork the upstream repositories you need, install from your forks, and keep license notices intact.

## Repository list

| Upstream Repo | Purpose | Typical role in the stack |
| --- | --- | --- |
| `Soul-Brews-Studio/maw-js` | tmux orchestration CLI (BUSL-1.1) | Starts worktrees, panes, teams, and messages |
| `Soul-Brews-Studio/maw-ui` | Web dashboard | Shows fleet status and operator-facing state |
| `Soul-Brews-Studio/arra-oracle-v3` | Oracle brain / knowledge base | Stores searchable learnings, traces, and handoffs |
| `Soul-Brews-Studio/arra-oracle-skills-cli` | Skills installer | Installs and updates workflow skills |
| `Soul-Brews-Studio/maw-plugin-registry` | Plugin ecosystem | Lists and distributes maw-compatible plugins |
| `Soul-Brews-Studio/ui-oracle` | UI oracle interface | Provides a user interface surface for Oracle workflows |

## Forking with GitHub CLI

Replace `<your-github-user>` with your own account or organization.

```bash
gh repo fork Soul-Brews-Studio/maw-js --clone=false
gh repo fork Soul-Brews-Studio/maw-ui --clone=false
gh repo fork Soul-Brews-Studio/arra-oracle-v3 --clone=false
gh repo fork Soul-Brews-Studio/arra-oracle-skills-cli --clone=false
gh repo fork Soul-Brews-Studio/maw-plugin-registry --clone=false
gh repo fork Soul-Brews-Studio/ui-oracle --clone=false
```

Then clone your forks:

```bash
git clone https://github.com/<your-github-user>/maw-js.git
git clone https://github.com/<your-github-user>/maw-ui.git
git clone https://github.com/<your-github-user>/arra-oracle-v3.git
git clone https://github.com/<your-github-user>/arra-oracle-skills-cli.git
git clone https://github.com/<your-github-user>/maw-plugin-registry.git
git clone https://github.com/<your-github-user>/ui-oracle.git
```

## Forking with plain Git

If you do not use GitHub CLI, create forks in the GitHub web UI and clone each fork manually:

```bash
git clone https://github.com/<your-github-user>/<repo-name>.git
```

Add upstream remotes so you can review and pull upstream changes intentionally:

```bash
cd <repo-name>
git remote add upstream https://github.com/Soul-Brews-Studio/<repo-name>.git
git fetch upstream
```

## Suggested dependency order

1. `arra-oracle-v3` — start the knowledge base first so searches and handoffs have a backing service.
2. `arra-oracle-skills-cli` — install workflow skills after the knowledge base exists.
3. `maw-js` — install the orchestration CLI once the local brain and skills paths are known.
4. `maw-plugin-registry` — connect plugin discovery after the core CLI is available.
5. `maw-ui` — add the dashboard after CLI state exists to display.
6. `ui-oracle` — add the UI oracle interface last, after backend services and CLI wiring are stable.

This order keeps setup errors local: storage first, skills second, orchestration third, user interfaces last.
