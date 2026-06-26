---
name: sop-new-project
description: 'New project onboarding checklist — repo creation, tier assignment, AGENTS.md, docs, CI/CD, Linear, codex trust, deploy, fleet config. Triggers: "new project", "new repo", "onboard".'
---
# /sop-new-project — New Project Onboarding

## Step 1: Ask Wind for Classification

Before anything else, confirm these with Wind:

```
1. Tier?  → NWFTH (strict) / Solution Lab (preferred) / Oracle-tooling (unrestricted)
2. Owner? → Leaf (NWFTH) / Bamboo (SL) / Sky (trading) / other
3. Stack? → Rust/Go/Node/Python + frontend framework
4. Port?  → which port does the app run on?
5. New or existing repo?
```

Then follow the tier-specific path below. **Do NOT mix paths.**

---

## Step 2: Verify Production Structure (7 Concerns)

Before writing any code, verify the project addresses all 7 mandatory concerns. Load the full reference:

```bash
cat ~/ghq/github.com/deachawatss/gale-oracle/ψ/memory/reference-production-structure-checklist.md
```

**Quick checklist** (framework folder names vary — the CONCERNS are universal):

```
[ ] 1. Entry + Config    — main.*, config.*, Dockerfile
[ ] 2. Security          — input guard, content filter, output filter
[ ] 3. Observability     — tracer, feedback, cost tracker
[ ] 4. Tests             — CI-ready test suite
[ ] 5. Docs              — docs/architecture.md, api-reference.md, deployment.md
[ ] 6. Scripts           — scripts/seed.*, migrate.*, healthcheck.*
[ ] 7. AI Context        — CLAUDE.md, AGENTS.md, claude/rules/
```

**Key rule**: Never fight framework conventions. Next.js owns `app/`, Nuxt owns `pages/`, SvelteKit owns `src/routes/`. Place security/observability where the framework expects business logic.

For AI/RAG projects, add: retrieval components, agent layer, prompt management, evaluation pipeline, data pipeline — ON TOP of the framework structure.

---

## Path A: NWFTH Project (Strict Tier)

**Owner**: Leaf | **Worktree**: mandatory | **QA**: `/sop-qa` self-QA | **Docs**: mandatory | **Discord**: 2 channels

### A1. GitHub Repo

**New repo**:
```bash
gh repo create deachawatss/<repo-name> --private --description "<description>"
ghq get deachawatss/<repo-name>
cd ~/ghq/github.com/deachawatss/<repo-name>
git checkout -b main 2>/dev/null || true
```

**Existing repo**:
```bash
ghq get <repo-url>
cd ~/ghq/github.com/deachawatss/<repo>
```

### A2. Branch Protection

```bash
gh api repos/deachawatss/<repo>/branches/main/protection -X PUT \
  -f "required_pull_request_reviews[required_approving_review_count]=0" \
  -F "enforce_admins=false" \
  -F "required_pull_request_reviews[dismiss_stale_reviews]=false"
```

### A3. AGENTS.md (project context ONLY — layered model)

Copy `WF/templates/project-agents-template.md` → `<repo>/AGENTS.md` and fill the
project-specific section (stack, testing surface, ports, DB). **Do NOT add doctrine,
workflow, or role rules** — fleet doctrine reaches Codex via the FLEET-DOCTRINE
block in the global `~/.codex/AGENTS.md`, and project AGENTS.md OVERRIDES global on conflict,
so a doctrine copy here silently wins as it goes stale. Keep the managed
`FLEET-DOCTRINE:fan-out` pointer block intact (fleet-sync maintains it).

### A4. CLAUDE.md (project context ONLY — layered model)

Copy `WF/templates/project-claude-template.md` → `<repo>/CLAUDE.md` and fill:
Stack, Database, Development, Testing (URL + credentials), Theme skill,
project-specific rules. **Always detect the actual stack from the repo**
(package.json, Cargo.toml, go.mod, pyproject.toml, etc.) — never assume.
No doctrine — the global `~/.claude/CLAUDE.md` already loads in every session.

### A5. Docs (the 7-doc standard — see `/sop-cmmi`)

```bash
bash ~/ghq/github.com/deachawatss/gale-oracle/scripts/init-project-docs.sh --project-name <project>
# Creates the 7 docs: PROJECT_PLAN, SRS, SDD, CR, RISK, UXUI, UAT
```
Same 7 docs for every project — no tiers. Docs are written **after** the code (swarm Haiku), never before.

### A6. ψ/ Directory

```bash
mkdir -p ψ/memory/{learnings,retrospectives,mailbox,resonance}
mkdir -p ψ/inbox/{handoff,tracks}
touch ψ/.gitkeep
git add ψ/ && git commit -m "init: ψ/ memory structure"
```

### A7. Docker

Verify `docker-compose.yml` exists with resource limits (memory, CPU). Create if missing.

### A8. CI/CD (GitHub Actions)

If `.github/workflows/ci.yml` doesn't exist, create a basic CI:

```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Docker build
        run: docker compose build
```

### A9. Codex Trust — automatic

Codex trust is AUTO-PRIMED by the launch wrappers (`codex-launch`/`omx-launch` write cwd + repo-root trust entries before exec, 2026-06-13). No per-repo step needed.

### A9b. Linear Project

SDLC tracking runs through Linear (GitHub Issues sync — canonical source is `gh issues`; Discord forum posting is RETIRED 2026-06-12):

```bash
# 1. Add this repo to the Linear GitHub-integration repo list
#    (Linear Settings → Integrations → GitHub → Repositories — route to the
#    Wind team; ONE Linear team for everything, slice by repo in views)

# 2. Record the mapping
# In ~/ghq/github.com/deachawatss/gale-oracle/ψ/memory/linear-project-map.json:
# set the repo's entry to { "team": "Wind", "synced": true }
```

### A10. Deploy Integration

Add to `~/ghq/github.com/deachawatss/gale-oracle/scripts/deploy-project.sh` PROJECT_MAP (or `deploy-webhook.ts` if webhook is used):

```typescript
"deachawatss/<repo>": {
  path: "$HOME/ghq/github.com/deachawatss/<repo>",
  name: "<repo>",
},
```

### A11. Fleet Integration

1. **Project registry**: add entry to `Wind-Framework/fleet/projects.yaml` (name, lane, guard, family, status)
2. **Regenerate guards**: `bash Wind-Framework/scripts/generate-guard-patterns.sh` (or fleet-sync does it)
3. **Fleet config**: add to `~/.config/maw/fleet/<N>-<oracle>.json`
4. **Verify**: `is_product_repo <name>` returns 0 (sourced from `_generated-patterns.sh`)
5. **Owner CLAUDE.md**: add to project registry table if maintained

### A12. Notify

```bash
maw hey wind:leaf "New NWFTH project <name> onboarded. Port: <PORT>. Stack: <stack>. Tier: strict. Ready for maw workon."
maw hey wind:gale "New NWFTH project <name> added to fleet. Owner: Leaf. Tier: strict."
```

### A13. Smoke Test

```bash
bash ~/ghq/github.com/deachawatss/gale-oracle/scripts/smoke-test.sh ~/ghq/github.com/deachawatss/<repo> <PORT>
# Must pass all checks before declaring onboarding complete
```

### A-Checklist

```
[ ] GitHub repo created/cloned (ghq)
[ ] Branch protection on main
[ ] AGENTS.md — Rule Zero + Karpathy + Docker + localhost + MSSQL
[ ] CLAUDE.md — stack + dev + testing + /nwf-theme + worktree pipeline trigger
[ ] docs/ — 7-doc standard bootstrapped (PROJECT_PLAN/SRS/SDD/CR/RISK/UXUI/UAT)
[ ] ψ/ — memory structure initialized
[ ] Docker — docker-compose.yml with resource limits
[ ] CI/CD — .github/workflows/ci.yml
[ ] Discord — 2 channels created, channel map updated
[ ] Deploy — added to deploy-project.sh or deploy-webhook.ts
[ ] Registry — projects.yaml entry added + guards regenerated
[ ] Fleet config — <oracle>.json updated
[ ] Guards — is_product_repo returns 0 for new name
[ ] Owner CLAUDE.md — project in registry table
[ ] Notifications — Leaf + Gale notified
[ ] Smoke test — all checks pass
```

---

## Path B: Solution Lab Project (Preferred Tier)

**Owner**: Bamboo | **Worktree**: preferred | **QA**: `/sop-qa` self-QA | **Docs**: optional | **Discord**: 1 channel

### B1. GitHub Repo

Same as A1. Private repo.

### B2. AGENTS.md

Same as A3 but without MSSQL references. Use generic DB rules.

### B3. CLAUDE.md

```markdown
# <Project Name>

<one-line description>

## Stack
<detect from repo — e.g. Next.js, Nuxt, SvelteKit, Go, Python+FastAPI, etc.>

## Development
<detect from repo — npm run dev, docker compose up, bun dev, etc.>

## Testing
http://localhost:<PORT>

## Theme
invoke /sl-theme before any UI work

## Docs
invoke /sl-doc for documents

## Worktree Pipeline — DO NOT STOP AFTER COMMITTING

Your task is NOT done after `git commit`. You MUST continue through ALL steps below before stopping:

1. Run `/sop-qa` — fix all findings until PASS
2. Push branch and create PR: `git push -u origin HEAD && gh pr create`
3. Notify main session: `maw hey wind:<oracle> "[wt] PR #N ready. <url>"`
4. WAIT here — keep pane alive for `maw done` /rrr

If `maw hey` fails, retry once, then print the PR URL and say "NOTIFICATION FAILED — main session needs manual alert".

Skipping ANY step is a pipeline violation. The main session cannot merge what it doesn't know about.
```

**Always detect the actual stack from the repo** — never assume.

### B4. ψ/ Directory

Same as A6.

### B5. CI/CD

Same as A8 (adapt to project stack).

### B6. Discord (1 channel)

```bash
# Channel: #<project-name> — dev updates + QA results combined
# Update ψ/memory/discord-channel-map.json under sl_forums
```

### B7. Deploy Integration

Same as A10 (if Docker-based).

### B8. Fleet Integration

1. **Tier table**: add to gale-oracle shared-claude.md preferred tier list
2. **Fleet config**: add to `~/.config/maw/fleet/03-bamboo.json`
3. **sop-enforce.sh**: add to Solution Lab case pattern

### B9. Notify

```bash
maw hey wind:bamboo "New SL project <name> onboarded. Port: <PORT>. Ready."
maw hey wind:gale "New SL project <name> added. Owner: Bamboo. Tier: preferred."
```

### B10. Smoke Test

```bash
bash ~/ghq/github.com/deachawatss/gale-oracle/scripts/smoke-test.sh ~/ghq/github.com/deachawatss/<repo> <PORT>
```

### B-Checklist

```
[ ] GitHub repo created/cloned
[ ] AGENTS.md — Rule Zero + Karpathy + localhost
[ ] CLAUDE.md — stack + /sl-theme + /sl-doc
[ ] ψ/ — memory structure initialized
[ ] CI/CD — GitHub Actions configured
[ ] Discord — 1 channel, channel map updated
[ ] Deploy — added (if Docker)
[ ] Tier table — added to preferred list
[ ] Fleet config — bamboo fleet config updated
[ ] sop-enforce.sh — pattern matches
[ ] Notifications — Bamboo + Gale
[ ] Smoke test — passes
```

---

## Path C: Oracle/Tooling (Unrestricted Tier)

**Owner**: varies | **Worktree**: not required | **QA**: no | **Docs**: no | **Discord**: no

### C1. Repo + CLAUDE.md only

```bash
ghq get <repo-url>
cd ~/ghq/github.com/deachawatss/<repo>
# Create minimal CLAUDE.md with stack info
# AGENTS.md optional (recommended if Codex workers will touch it)
```

### C2. Fleet Integration (minimal)

1. **Fleet config**: add to owning oracle's fleet config if it will be `maw workon`'d
2. No tier table change, no hook changes, no Discord

### C-Checklist

```
[ ] CLAUDE.md exists
[ ] Fleet config updated (if applicable)
[ ] Owning oracle notified
```

---

## Anti-Patterns

| Don't | Do instead |
|-------|-----------|
| Skip classification — "I'll figure out the tier later" | Ask Wind first. Tier determines everything. |
| Use `localhost` anywhere | Use `localhost` |
| Copy AGENTS.md without customizing port/DB | Use the template, fill in project-specific values |
| Skip Discord setup for NWFTH | Every NWFTH project gets 2 channels — QA results go there |
| Skip `/sop-qa` setup | Dev oracles need QA checklist configured for new project |
| Create project and forget sop-enforce.sh | If the hook doesn't recognize it, SOPs won't fire |
| Skip ψ/ initialization | Oracle memory won't capture learnings from this project |
| Skip CI/CD | No automated checks on PRs = silent regressions |
| Forget deploy integration | After merge, deploy won't auto-trigger for this project |
| Skip smoke test | Onboarding isn't done until smoke-test.sh passes |
