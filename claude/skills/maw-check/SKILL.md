---
name: maw-check
description: '/maw-check'
---

# /maw-check

> Comprehensive maw ecosystem health check. Covers fleet, plugins, MCP, embeddings, processes, config, orphans, and zombies.

Use when: "check maw", "health check", "is everything working", "system status", "kill zombies", "check fleet", or at session start to verify infrastructure.

## Usage

```
/maw-check              # Full check — all sections
/maw-check --quick      # Fast check — skip slow sections (embeddings, plugin verify)
/maw-check --fix        # Auto-fix what can be fixed (zombies, stale tasks, orphan worktrees)
```

## Instructions

Run ALL sections below in order. Collect results into a summary table at the end.

**Important**: Run the bash blocks in each section. Do NOT skip sections unless `--quick` is specified. Report each section as PASS / WARN / FAIL with details.

---

### Section 1: Fleet Health

```bash
maw fleet doctor 2>&1
```

Check output for:
- Oracle count (discover live via `maw ls` — never assume a fixed number)
- Session count
- Any issues reported

---

### Section 2: Active Sessions

```bash
maw ls 2>&1
```

Check:
- Which oracles are running (gale, leaf, bamboo, pien, doctor, etc.)
- Any unexpected windows or missing sessions
- Worktree windows (active work in progress)

---

### Section 3: pm2 Services

```bash
pm2 ls 2>&1
```

Expected services (all should be `online`):
- `oracle-http` — arra-oracle HTTP API (knowledge base)
- `oracle-studio` — arra-oracle dashboard UI (:47780)
- `maw-serve` — maw backend server (:3456)
- `ollama` — embedding model server (GPU)

Report any stopped/errored services.

---

### Section 4: MCP Servers

```bash
echo "=== MCP Config ==="
cat ~/.claude/.mcp.json 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
for name,cfg in d.get('mcpServers',{}).items():
    cmd = cfg.get('command','?')
    args = ' '.join(cfg.get('args',[])) if cfg.get('args') else ''
    print(f'  {name}: {cmd} {args[:80]}')
"

echo ""
echo "=== Oracle API ==="
curl -sf http://localhost:47778/api/stats 2>&1 | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    total=d.get('total',0)
    print(f'  Documents: {total}')
    print(f'  Types: {d.get(\"by_type\",\"?\")}')
    v=d.get('vector',{})
    vcount=v.get('count',0)
    print(f'  Vectors: {vcount} ({v.get(\"collection\",\"?\")})')
    if isinstance(total,int) and isinstance(vcount,int) and total>vcount:
        gap=total-vcount
        print(f'  ⚠ EMBEDDING GAP: {gap} docs missing vectors — run: cd ~/ghq/github.com/deachawatss/arra-oracle-v3 && bun src/scripts/index-model.ts bge-m3 --incremental')
        print(f'  ⚠ NEVER use --full unless collection is corrupt. NEVER kill a running reindex (corrupts LanceDB).')
    print(f'  Stale: {d.get(\"is_stale\",\"?\")}')
except: print('  UNREACHABLE — oracle-http may be down')
" 2>&1
```

**CRITICAL**: The `index-model.ts` script defaults to `--incremental` (safe). Only use `--full` when the LanceDB collection is corrupt (vector search returns 0 for all queries). Never kill a running reindex process — it leaves LanceDB data files incomplete and breaks vector search entirely until a full rebuild completes.

---

### Section 5: Embeddings (skip if `--quick`)

```bash
echo "=== Ollama Models ==="
ollama list 2>&1 | head -10

echo ""
echo "=== Embedding Test ==="
curl -sf http://localhost:11434/api/embeddings -d '{"model":"bge-m3","prompt":"test"}' 2>&1 | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    dims = len(d.get('embedding',[]))
    print(f'  bge-m3: OK ({dims} dimensions)')
except: print('  bge-m3: FAILED — model may not be loaded')
" 2>&1
```

---

### Section 6: maw-js Health

```bash
echo "=== maw version ==="
maw --version 2>&1

echo ""
echo "=== Plugin count ==="
maw --help 2>&1 | grep -E "loaded|plugins" | head -2

echo ""
echo "=== Config validation ==="
cat ~/.config/maw/maw.config.json 2>/dev/null | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    triggers = d.get('triggers',[])
    plugins = d.get('plugins',[])
    peers = d.get('peers',[])
    pulse = d.get('pulseProjects',{})
    print(f'  Triggers: {len(triggers)}')
    print(f'  Declared plugins: {len(plugins)}')
    print(f'  Peers: {len(peers)}')
    print(f'  Pulse projects: {list(pulse.keys()) if pulse else \"none\"}')
    for t in triggers:
        print(f'    trigger: {t.get(\"event\",\"?\")} → {t.get(\"action\",\"?\")[:60]}')
except Exception as e: print(f'  CONFIG ERROR: {e}')
" 2>&1

echo ""
echo "=== Fleet config files ==="
ls ~/.config/maw/fleet/*.json 2>/dev/null | wc -l
echo "fleet JSON files"
```

---

### Section 7: Plugin Verification (skip if `--quick`)

```bash
echo "=== Symlinked plugins ==="
ls ~/.config/maw/plugins/ 2>/dev/null | wc -l
echo "installed plugins"

echo ""
echo "=== Broken symlinks ==="
find ~/.config/maw/plugins/ -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | head -10
BROKEN=$(find ~/.config/maw/plugins/ -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l)
echo "$BROKEN broken symlink(s)"

echo ""
echo "=== Core commands smoke ==="
for cmd in fleet pulse team wake sleep stop done capture; do
    if maw $cmd --help >/dev/null 2>&1; then
        echo "  $cmd: OK"
    else
        echo "  $cmd: MISSING"
    fi
done
# hey doesn't support --help — test with dry run (check for usage output)
if command -v maw >/dev/null 2>&1 && [ -n "$(maw hey 2>&1)" ]; then
    echo "  hey: OK"
else
    echo "  hey: MISSING"
fi
```

---

### Section 8: Zombie Processes

```bash
echo "=== Zombie maw hey / maw-pty ==="
ZOMBIES=$(ps aux | grep -E "maw hey|maw-pty" | grep -v grep)
if [ -z "$ZOMBIES" ]; then
    echo "No zombies found."
else
    echo "$ZOMBIES"
    COUNT=$(echo "$ZOMBIES" | wc -l)
    echo ""
    echo "Found $COUNT zombie process(es)"
fi

echo ""
echo "=== High CPU processes (maw-related) ==="
ps aux --sort=-%cpu | grep -i maw | grep -v grep | head -5
```

If `--fix` and zombies found:
```bash
PIDS=$(ps aux | grep -E "maw hey|maw-pty" | grep -v grep | awk '{print $2}')
if [ -n "$PIDS" ]; then
    kill $PIDS
    sleep 1
    REMAINING=$(ps aux | grep -E "maw hey|maw-pty" | grep -v grep | wc -l)
    if [ "$REMAINING" -gt 0 ]; then kill -9 $PIDS 2>/dev/null; fi
    echo "Killed $PIDS"
fi
```

---

### Section 9: Orphans & Stale Artifacts

```bash
echo "=== Team doctor ==="
bash ~/.claude/skills/team-agents/scripts/doctor.sh 2>&1

echo ""
echo "=== Orphan worktrees (all oracle repos) ==="
for repo in ~/ghq/github.com/deachawatss/*-oracle/; do
    WTS=$(git -C "$repo" worktree list 2>/dev/null | grep -v "$(basename $repo)" | grep -v "\[main\]" | grep -v "\[master\]")
    if [ -n "$WTS" ]; then
        echo "  $(basename $repo): $WTS"
    fi
done
echo "  (none = clean)"

echo ""
echo "=== Stale mailbox teams ==="
ls ~/ghq/github.com/deachawatss/gale-oracle/ψ/memory/mailbox/teams/ 2>/dev/null || echo "  (none)"
```

If `--fix` and stale tasks found:
```bash
bash ~/.claude/skills/team-agents/scripts/doctor.sh --fix 2>&1
```

---

### Section 10: Git State (all oracle repos)

```bash
echo "=== Oracle repo git status ==="
for repo in ~/ghq/github.com/deachawatss/*-oracle/; do
    NAME=$(basename "$repo")
    STATUS=$(git -C "$repo" status --short 2>/dev/null | wc -l)
    BRANCH=$(git -C "$repo" branch --show-current 2>/dev/null)
    AHEAD=$(git -C "$repo" rev-list --count origin/$BRANCH..$BRANCH 2>/dev/null || echo "?")
    if [ "$STATUS" -gt 0 ] || [ "$AHEAD" -gt 0 ] 2>/dev/null; then
        echo "  $NAME: branch=$BRANCH dirty=$STATUS ahead=$AHEAD"
    fi
done
echo "  (only repos with changes shown)"
```

---

### Section 11: Command Smoke Test (skip if `--quick`)

Test every maw command to verify it loads and responds. Each command is invoked with `--help` (or a safe dry-run for commands that don't support `--help`). A command PASSES if it exits 0 and produces output. A command FAILS if it crashes, hangs, or returns "command not found".

```bash
echo "=== Command Smoke Test ==="

# Extract all command names from maw --help
COMMANDS=$(maw --help 2>&1 | grep -E '^\s+maw ' | awk '{print $2}' | sort -u)
TOTAL=$(echo "$COMMANDS" | wc -l)
PASS=0
FAIL=0
SKIP=0
FAILED_LIST=""

for cmd in $COMMANDS; do
  # Skip commands blocked by safety hook from Gale session
  case "$cmd" in
    workon)
      SKIP=$((SKIP + 1))
      continue
      ;;
  esac

  # Try --help with 3s timeout. A command PASSES if it produces output
  # (even with non-zero exit — some commands like `hey` exit 1 on bare usage).
  OUTPUT=$(timeout 3 maw $cmd --help 2>&1)
  if [ -n "$OUTPUT" ]; then
    PASS=$((PASS + 1))
  else
    # Fallback: bare invocation with 3s timeout
    OUTPUT=$(timeout 3 maw $cmd 2>&1)
    if [ -n "$OUTPUT" ]; then
      PASS=$((PASS + 1))
    else
      FAIL=$((FAIL + 1))
      FAILED_LIST="$FAILED_LIST $cmd"
    fi
  fi
done

echo "  Total: $TOTAL | Pass: $PASS | Fail: $FAIL | Skip: $SKIP"
if [ $FAIL -gt 0 ]; then
  echo "  FAILED commands:$FAILED_LIST"
fi
```

Report as:
- **PASS**: all commands responded (FAIL=0)
- **WARN**: 1-3 commands failed (may be transient)
- **FAIL**: 4+ commands failed (broken plugin or install issue)

---

### Summary

After running all sections, produce a summary table:

```
## /maw-check — Health Report

| Section | Status | Detail |
|---------|--------|--------|
| Fleet | PASS/WARN/FAIL | N oracles, N sessions |
| Sessions | PASS/WARN/FAIL | which running |
| pm2 | PASS/WARN/FAIL | N/N services online |
| MCP | PASS/WARN/FAIL | N servers, API reachable |
| Embeddings | PASS/WARN/FAIL | bge-m3 dims |
| maw-js | PASS/WARN/FAIL | version, N plugins |
| Plugins | PASS/WARN/FAIL | N installed, N broken |
| Zombies | PASS/WARN/FAIL | N found |
| Orphans | PASS/WARN/FAIL | stale tasks, worktrees |
| Git | PASS/WARN/FAIL | dirty/ahead repos |
| Commands | PASS/WARN/FAIL | N/N pass, N fail, N skip |

**Overall**: PASS / WARN (N issues) / FAIL (N critical)
```

If any section is FAIL, suggest specific fix commands.
