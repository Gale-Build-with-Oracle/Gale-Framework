# Fork Patches

This page lists optional reliability patches you can apply to your own forks. They are intentionally generic. Review upstream licenses and keep a clear commit history in each fork.

## Bash strictness

For setup scripts and operational helpers, use strict Bash defaults when practical:

```bash
set -Eeuo pipefail
IFS=$'\n\t'
```

Recommended conventions:

- fail fast when required commands or paths are missing;
- print the command being executed only when it does not expose secrets;
- prefer explicit paths over changing global shell state;
- keep cleanup handlers idempotent;
- avoid destructive wildcard removal.

## Codex launch wrappers

A launch wrapper can make worker startup more predictable. Common wrapper responsibilities:

- set the working directory before launching the model runtime;
- mark the current project path as trusted in the local runtime configuration;
- pass through only the environment variables needed by the session;
- write a small startup log for debugging failed launches;
- avoid embedding personal tokens or machine-specific paths in the repository.

Keep wrappers small. The wrapper should prepare the process environment, not implement task logic.

## pm2 process management

If you use `pm2` for local services, define explicit process names and startup commands:

```bash
pm2 start ecosystem.config.cjs
pm2 status
pm2 logs <process-name>
```

Recommended conventions:

- one process entry per service;
- stable names for dashboards and logs;
- explicit working directories;
- restart policies that do not hide repeated boot failures;
- separate development and production process files when the commands differ.

## Patch hygiene

Keep optional patches easy to audit:

- one concern per commit;
- no private hostnames, credentials, or organization-specific paths;
- note whether the patch should be proposed upstream or remain local;
- rebase local patches after upstream updates instead of mixing generated changes with hand edits.
