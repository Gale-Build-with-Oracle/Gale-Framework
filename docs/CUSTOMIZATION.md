# Customization

Use Gale-Framework as a starting point, then replace placeholder names, repositories, and projects with your own public or private workspace.

## Add your own projects

Create or edit `fleet/projects.yaml` to list the repositories your Oracle workflow can route to.

Example:

```yaml
projects:
  - name: YourProject
    repo: <your-github-user>/YourProject
    path: ~/src/YourProject
    type: product
    default_branch: main
```

Suggested fields:

- `name` — short project name used in task briefs;
- `repo` — GitHub owner and repository name;
- `path` — local checkout path;
- `type` — `product`, `infra`, `docs`, or another local category;
- `default_branch` — usually `main`.

Keep this file free of secrets. Store credentials in your normal credential manager or environment-specific configuration.

## Add an Oracle

An Oracle is a durable operator identity with a clear responsibility boundary. Start with one general-purpose Oracle, then add more only when responsibilities are genuinely distinct.

Example placeholder structure:

```text
oracles/
  my-oracle/
    CLAUDE.md
    AGENTS.md
    memory/
```

Recommended identity notes:

- mission and scope;
- projects owned;
- escalation paths;
- communication style;
- local commands that are safe for that Oracle to run.

Do not copy global doctrine into every Oracle file. Keep shared workflow rules in one source and keep Oracle files focused on identity and ownership.

## Fleet config

A fleet config usually answers four questions:

1. Which projects exist?
2. Which Oracle owns each project?
3. Which commands launch each runtime?
4. Where are logs, memory, and generated state stored?

Use placeholders until your real paths are known:

```yaml
fleet:
  owner: <your-github-user>
  default_oracle: my-oracle
  worktree_root: ~/worktrees
```

Avoid committing machine-specific absolute paths if the repository is shared. Prefer documented placeholders and a local override file ignored by Git.

## Doctrine edits

Doctrine is the shared operating contract. Edit it carefully because every session that loads it will inherit the change.

Recommended process:

1. Edit the doctrine source file, not generated outputs.
2. Keep changes imperative and specific.
3. Remove duplicated rules instead of restating them in multiple places.
4. Run the sync script.
5. Review the generated Claude and Codex surfaces.
6. Commit source and generated outputs together only when your repository intentionally tracks both.

Example:

```bash
bash scripts/fleet-sync.sh
```

## Local overrides

Use local override files for machine-specific details:

```text
.env.local
fleet/local.yaml
.maw/local.json
```

Add those files to `.gitignore` in your own fork if they contain hostnames, usernames, tokens, or private paths.

## Safe naming examples

Use neutral placeholders in public docs and templates:

- `<your-github-user>`
- `my-oracle`
- `YourProject`
- `~/src/YourProject`

Avoid publishing customer names, private database names, internal hostnames, or personal credentials.
