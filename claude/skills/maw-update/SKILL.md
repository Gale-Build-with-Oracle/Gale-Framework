---
name: maw-update
description: 'Sync our forks of the 6 active Soul-Brews-Studio repos (maw-js, arra-oracle-v3, maw-plugin-registry, ui-oracle, arra-oracle-skills-cli, maw-ui).'
---

# /maw-update

> "Fleet-wide upstream resync. Upstream first, our patches layer on top."

Wind's stance (2026-04-19): when we fork from `Soul-Brews-Studio/*`, we track upstream as the source of truth. On conflicts we **take upstream** first, then re-apply our specific changes on top as new commits.

## Usage

```
/maw-update                          # Dry-run: show which repos are behind
/maw-update --apply                  # Fetch + merge all behind repos
/maw-update --repo <name>            # Only this repo
/maw-update --apply --repo maw-js    # Single repo merge
/maw-update --report                 # After sync, print what got overwritten
```

## Scope — 4 tracked upstreams

| Local (`deachawatss/`) | Upstream (`Soul-Brews-Studio/`) | Purpose |
|---|---|---|
| `maw-js` | `maw-js` | CLI backend + 64 bundled plugins |
| `arra-oracle-v3` | `arra-oracle-v3` | Oracle MCP + knowledge layer |
| `maw-plugin-registry` | `maw-plugin-registry` | Registry plugins (dream, contacts, costs, health, etc.) |
| `ui-oracle` | `ui-oracle` | ARRA dashboard (oracle-studio pm2, port 47780) |
| `arra-oracle-skills-cli` | `arra-oracle-skills-cli` | Oracle skills installer — `/go install`, `/go update` |
| `maw-ui` | `maw-ui` | ARRA Office — web dashboard for maw fleet control |

**Previously tracked repos removed (2026-05-14)**:
- `maw-core-plugins`, `maw-plugins` — absorbed; all plugins now sourced from maw-js or maw-plugin-registry
- `maw-park`, `maw-rename`, `maw-bg`, `maw-shellenv`, `maw-cross-team-queue` — plugins absorbed into maw-js
- `arra-mcp-installation-guide-oracle`, `indexer-pro`, `maw-studio-oracle` — reference-only, not runtime

**Clone-not-fork pattern**: we do NOT use GitHub's "Fork" button. Instead: clone upstream → create fresh private repo under `deachawatss/` → set `origin=deachawatss/X`, `upstream=Soul-Brews-Studio/X` (read-only). See §"First-time setup" below.

## Step 0: Discover Repos

```bash
date "+🕐 %H:%M %Z (%A %d %B %Y)"

ALLOWLIST=(
  "maw-js|maw-js"
  "arra-oracle-v3|arra-oracle-v3"
  "maw-plugin-registry|maw-plugin-registry"
  "ui-oracle|ui-oracle"
  "arra-oracle-skills-cli|arra-oracle-skills-cli"
  "maw-ui|maw-ui"
)

REPOS=()
MISSING=()
for entry in "${ALLOWLIST[@]}"; do
  local_name="${entry%%|*}"
  upstream_name="${entry##*|}"
  repo="$HOME/ghq/github.com/deachawatss/$local_name"
  # submodule-aware: a submodule's .git is a FILE (gitdir pointer), not a dir
  if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    MISSING+=("$local_name (upstream: $upstream_name)")
    continue
  fi
  if ! git -C "$repo" remote get-url upstream >/dev/null 2>&1; then
    MISSING+=("$local_name (no upstream remote — run §First-time setup)")
    continue
  fi
  REPOS+=("$local_name")
done

echo "Scope: ${#REPOS[@]} tracked / ${#ALLOWLIST[@]} in allowlist"
[ ${#MISSING[@]} -gt 0 ] && {
  echo "Missing (needs §First-time setup):"
  printf '  - %s\n' "${MISSING[@]}"
}
```

## Step 0a: Guardrail verification (MANDATORY)

```bash
echo "== Guardrail audit =="
FAIL=0
for entry in "${ALLOWLIST[@]}"; do
  local_name="${entry%%|*}"
  repo="$HOME/ghq/github.com/deachawatss/$local_name"
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || continue  # submodule-aware

  up_fetch=$(git -C "$repo" remote get-url upstream 2>/dev/null)
  up_push=$(git -C "$repo" remote get-url --push upstream 2>/dev/null)
  push_default=$(git -C "$repo" config --get branch.main.pushRemote 2>/dev/null)

  [[ "$up_fetch" != *"Soul-Brews-Studio"* ]] && { echo "  ⚠ $local_name: upstream fetch URL NOT Soul-Brews-Studio ($up_fetch)"; FAIL=1; }
  [[ "$up_push" != "no_push_readonly_upstream" ]] && { echo "  ⚠ $local_name: upstream push URL NOT disabled ($up_push)"; FAIL=1; }
  [[ "$push_default" != "origin" ]] && {
    git -C "$repo" config branch.main.pushRemote origin
    echo "  ✓ $local_name: set branch.main.pushRemote=origin (was unset/wrong)"
  }
done

if [ "$FAIL" != "0" ]; then
  echo "Guardrail audit FAILED — fix before syncing."
  echo "  git -C <repo> remote set-url --push upstream no_push_readonly_upstream"
  exit 1
fi
echo "  ✓ all upstream remotes are fetch-only; default push = origin on all"
```

## Step 1: Dry-Run Status (default)

```bash
for name in "${REPOS[@]}"; do
  REPO_PATH="$HOME/ghq/github.com/deachawatss/$name"
  git -C "$REPO_PATH" fetch upstream --quiet 2>&1 | tail -1

  # maw-js tracks upstream/alpha (active dev branch); others track upstream/main
  if [ "$name" = "maw-js" ]; then
    UP_HEAD="alpha"
  else
    UP_HEAD=$(git -C "$REPO_PATH" symbolic-ref refs/remotes/upstream/HEAD 2>/dev/null | sed 's|refs/remotes/upstream/||')
    if [ -z "$UP_HEAD" ]; then
      git -C "$REPO_PATH" remote set-head upstream --auto 2>/dev/null
      UP_HEAD=$(git -C "$REPO_PATH" symbolic-ref refs/remotes/upstream/HEAD 2>/dev/null | sed 's|refs/remotes/upstream/||')
    fi
  fi
  if [ -z "$UP_HEAD" ]; then
    echo "  ⊘ $name — upstream has no commits yet (empty repo)"
    continue
  fi

  BEHIND=$(git -C "$REPO_PATH" rev-list --count "HEAD..upstream/$UP_HEAD" 2>/dev/null)
  AHEAD=$(git -C "$REPO_PATH" rev-list --count "upstream/$UP_HEAD..HEAD" 2>/dev/null)

  if [ "$BEHIND" = "0" ]; then
    echo "  ✓ $name — up to date (ahead $AHEAD, branch $UP_HEAD)"
  else
    echo "  ⚠ $name — BEHIND by $BEHIND commits (ahead $AHEAD, branch $UP_HEAD)"
  fi
done
```

**Stop here unless `--apply` is set.**

## Step 2: Apply (with `--apply` flag)

### 2a. maw-js: merge upstream/alpha into our fork (MANDATORY)

**maw-js is `bun link`ed — our repo IS the global CLI.** Never use `maw update alpha --yes` (that reinstalls from upstream, breaking the link). Instead, merge upstream/alpha directly into our fork.

**Why alpha, not main?** Alpha is the active development branch with the latest features and coverage. Main lags behind. We track alpha as our upstream target.

```bash
if [ "$name" = "maw-js" ]; then
  cd "$REPO_PATH"
  BEFORE=$(maw --version 2>/dev/null)

  git fetch upstream --quiet
  BEHIND_MAIN=$(git rev-list --count "HEAD..upstream/main" 2>/dev/null)
  BEHIND_ALPHA=$(git rev-list --count "HEAD..upstream/alpha" 2>/dev/null)
  echo "  maw-js: behind main by $BEHIND_MAIN, behind alpha by $BEHIND_ALPHA"

  if [ "$BEHIND_ALPHA" -eq 0 ]; then
    echo "  ✓ maw-js — up to date with upstream/alpha"
  else
    echo "  ⚠ maw-js: $BEHIND_ALPHA commits behind upstream/alpha"
    echo "  → Use worktree for merge: maw workon maw-js upstream-sync"
    echo "  → In worktree: git merge upstream/alpha --no-ff"
    echo "  → FORK POLICY (Wind 2026-06-13): NO upstream PRs; our fixes live in the"
    echo "    plugin layer (~/.maw/plugins → vendor/mpr-plugins); core divergences ONLY"
    echo "    per FORK_PATCHES.md. Re-apply any dropped TRUE-CORE patch after the merge."
    echo "  → Run: bun run test:all  (includes test/fork-divergence.test.ts — fails LOUDLY"
    echo "    if the merge dropped a fork patch)"
    echo "  → Then: maw pr + merge + maw done"
    echo ""
    echo "  After merge, verify bun link is intact:"
    echo "    readlink -f \$(which maw)  # must point to repo src/cli.ts"
    echo "    maw --version              # must match repo package.json"
  fi

  AFTER=$(maw --version 2>/dev/null)
  echo "  maw-js: $BEFORE (global CLI = repo via bun link)"
  continue
fi
```

### 2b. Cherry-pick new upstream commits (arra-oracle-v3, maw-plugin-registry)

```bash
git tag "rollback-maw-update-$(date +%Y%m%d-%H%M%S)"
git fetch upstream --quiet
UP_HEAD=$(git symbolic-ref refs/remotes/upstream/HEAD 2>/dev/null | sed 's|refs/remotes/upstream/||')
[ -z "$UP_HEAD" ] && UP_HEAD=main

NEW_COMMITS=$(git rev-list --reverse HEAD..upstream/$UP_HEAD)
COMMIT_COUNT=$(echo "$NEW_COMMITS" | grep -c . 2>/dev/null || echo 0)

if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo "  ✓ $name — no new commits"
  continue
fi

echo "  $name: $COMMIT_COUNT new upstream commits to cherry-pick"

PICKED=0; SKIPPED=0; FAILED=()
for commit in $NEW_COMMITS; do
  SUBJECT=$(git log --format='%s' -1 $commit)
  if git cherry-pick $commit --no-edit 2>/dev/null; then
    PICKED=$((PICKED + 1))
  else
    git cherry-pick --abort 2>/dev/null
    SKIPPED=$((SKIPPED + 1))
    FAILED+=("$commit: $SUBJECT")
  fi
done

echo "  $name: picked $PICKED, skipped $SKIPPED"
[ ${#FAILED[@]} -gt 0 ] && {
  echo "  ⚠ Skipped commits (conflict with our patches — manual review needed):"
  printf '    - %s\n' "${FAILED[@]}"
}
```

### 2c. Build + test if the repo has a build script

```bash
if [ -f package.json ] && grep -q '"build"' package.json; then
  bun install 2>&1 | tail -2
  bun run build 2>&1 | tail -5
fi
```

### 2d. Push to origin

```bash
git push origin main 2>&1 | tail -3
```

### 2e. Fork Patch Verification (maw-js only)

After merging upstream, check if our fork-specific patches survived.
**Plugin layout**: running plugins resolve via `readlink -f ~/.maw/plugins/<name>` — most live in `src/vendor/mpr-plugins/`, a few (swarm/tmux/channel/pane) in `src/commands/plugins/`. Verify the path, not the noun.

```bash
if [ "$name" = "maw-js" ] && [ -f FORK_PATCHES.md ]; then
  echo "  Verifying fork patches..."
  PATCH_FAIL=0

  # Fork-divergence harness (maw-js#84) — one loud test per merge-exposed patch.
  # This SUPERSEDES the old hand-maintained grep list (which went stale: it still
  # checked the retired tile patch and missed half the active set).
  if [ -f test/fork-divergence.test.ts ]; then
    bun test test/fork-divergence.test.ts || { echo "    ⚠ FORK PATCH DROPPED by merge — see failing asserts above"; PATCH_FAIL=1; }
  else
    echo "    ⚠ test/fork-divergence.test.ts missing — verify FORK_PATCHES.md Active set by hand"
    PATCH_FAIL=1
  fi

  # bun link integrity (environment, not a patch)
  LINKED_PATH=$(readlink -f "$(which maw)" 2>/dev/null)
  [[ "$LINKED_PATH" == *"deachawatss/maw-js"* ]] || { echo "    ⚠ BROKEN: global maw not linked to our repo ($LINKED_PATH)"; PATCH_FAIL=1; }

  if [ "$PATCH_FAIL" -gt 0 ]; then
    echo "    → STOP: re-apply missing patches from FORK_PATCHES.md (TRUE-CORE set) before declaring the sync done"
  else
    echo "    ✓ Fork-divergence tests green + bun link intact"
  fi
fi
```

## Step 2f: Service Restart

**maw-js merge → restart ALL pm2 processes** (not a hand-picked subset). Long-running pm2 processes (pien-bridge, maw-serve, etc.) cache maw-js modules in memory at boot — a disk-level merge does NOT reach them until restart. Forgetting one process = stale code running silently (pien-bridge missed the isCodexPane submit fix for hours, 2026-06-12).

```bash
# After maw-js merge — restart everything that uses maw internally:
bunx pm2 restart all
```

For non-maw-js repos, restart only the affected service:

| Repo synced | Restart command |
|---|---|
| `arra-oracle-v3` | `bunx pm2 restart oracle-http` |
| `maw-plugin-registry` | No restart needed — symlinks are live |
| `ui-oracle` | `cd ui-oracle/apps/studio && bunx vite build && bunx pm2 restart oracle-studio` |

Verify after restart:
```bash
maw --version
bunx pm2 list   # all services online
curl -s http://localhost:47778/api/health | grep -oE '"server":"[^"]+"'
```

## First-Time Setup for a New Upstream Repo

```bash
UPSTREAM_NAME="<repo-name>"
LOCAL_PATH="$HOME/ghq/github.com/deachawatss/$UPSTREAM_NAME"

git clone "https://github.com/Soul-Brews-Studio/${UPSTREAM_NAME}.git" "$LOCAL_PATH"
cd "$LOCAL_PATH"
git remote rename origin upstream
git remote set-url --push upstream no_push_readonly_upstream
gh repo create "deachawatss/$UPSTREAM_NAME" --private \
  --description "Fork of Soul-Brews-Studio/$UPSTREAM_NAME (clone-not-fork)"
git remote add origin "https://github.com/deachawatss/${UPSTREAM_NAME}.git"
git push -u origin "$(git symbolic-ref --short HEAD)"
git remote set-head upstream --auto
```

## Hard Rules

1. **Never `git push --force`** — safety hook blocks it.
2. **Never touch `Soul-Brews-Studio/*` directly** — fetch-only.
3. **Build failures are reported, not fixed.**
4. **Always tag a rollback point** before merging.

## Quick Reference

| Flag | Effect |
|---|---|
| (none) | Dry-run — show behind status |
| `--apply` | Execute merge on all behind repos |
| `--repo <name>` | Scope to one repo |
| `--report` | Show what got overwritten on last sync |
