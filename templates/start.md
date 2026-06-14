# Oracle Full Stack Bootstrap

> Give this entire file as a prompt to Claude Code on a fresh machine.
> It will install maw-js, arra-oracle-v3 MCP, and 94 skills (full profile).

---

## Instructions for AI

You are setting up the Oracle ecosystem on this machine. Follow each phase in order. Do NOT skip steps. Verify each phase works before moving to the next.

### Prerequisites Check

Run these first. If any fail, install the missing tool before continuing.

```bash
bun --version    # need >= 1.3.0 — install: curl -fsSL https://bun.sh/install | bash
gh --version     # need GitHub CLI — install: https://cli.github.com/
git --version    # need git
tmux -V          # need tmux for fleet management
```

Also ensure `ghq` is installed for repo management:
```bash
ghq --version    # install: go install github.com/x-motemen/ghq@latest
# OR: brew install ghq
# Set ghq root: git config --global ghq.root ~/ghq
```

---

### Phase 1: Clone repos

```bash
ghq get https://github.com/Soul-Brews-Studio/maw-js
ghq get https://github.com/Soul-Brews-Studio/arra-oracle-v3
```

---

### Phase 2: Install maw-js (fleet CLI)

```bash
cd "$(ghq root)/github.com/Soul-Brews-Studio/maw-js"
bun install
bun link
```

Verify:
```bash
maw --version
```

If `maw: command not found`, add bun's global bin to PATH:
```bash
echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
maw --version
```

---

### Phase 3: Install arra-oracle-v3 (knowledge base + MCP)

```bash
cd "$(ghq root)/github.com/Soul-Brews-Studio/arra-oracle-v3"
bun install
bun run db:push
```

Create the MCP start script:
```bash
cat > start-mcp.sh << 'SCRIPT'
#!/bin/bash
export PATH="$HOME/.bun/bin:$PATH"
export ORACLE_PROJECT_ROOTS="$HOME/ghq/github.com"
export ORACLE_VECTOR_DB="lancedb"
cd "$(dirname "$0")"
exec bun src/index.ts "$@"
SCRIPT
chmod +x start-mcp.sh
```

Verify HTTP server works:
```bash
bun run server &
sleep 2
curl -s http://localhost:47778/api/health
kill %1
```

---

### Phase 4: Register arra-oracle-v3 as MCP server for Claude Code

```bash
ARRA_PATH="$(ghq root)/github.com/Soul-Brews-Studio/arra-oracle-v3"

# Add to Claude Code's MCP config
claude mcp add arra-oracle-v3 -- "$ARRA_PATH/start-mcp.sh"
```

If `claude mcp add` is not available, manually add to `~/.claude.json`:
```json
{
  "mcpServers": {
    "arra-oracle-v3": {
      "type": "stdio",
      "command": "<FULL_PATH_TO>/arra-oracle-v3/start-mcp.sh",
      "args": [],
      "env": {}
    }
  }
}
```

Replace `<FULL_PATH_TO>` with the actual absolute path from `echo $ARRA_PATH`.

Verify by restarting Claude Code and running:
```
arra_search("hello")
```

---

### Phase 5: Install Oracle Skills (full profile — 94 skills)

Skills are installed via `arra-oracle-skills-cli`, which ships inside arra-oracle-v3.

```bash
cd "$(ghq root)/github.com/Soul-Brews-Studio/arra-oracle-v3"
bun src/skills/cli.ts install --profile full --target ~/.claude/skills/
```

If the skills CLI path has changed, try:
```bash
# Alternative: direct from the published skills package
bunx --bun arra-cli@github:Soul-Brews-Studio/arra-oracle-v3 skills install --profile full
```

Verify:
```bash
ls ~/.claude/skills/ | wc -l
# Should be 90+ skills
```

---

### Phase 6: Configure Claude Code settings

Add to `~/.claude/settings.json` (create if doesn't exist):

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  },
  "permissions": {
    "allow": [
      "mcp__arra-oracle-v3__*",
      "Bash(maw *)",
      "Bash(ghq *)",
      "Bash(git status*)",
      "Bash(git log*)",
      "Bash(git diff*)",
      "Bash(git branch*)",
      "Bash(ls *)",
      "Bash(find *)",
      "Bash(cat *)",
      "Bash(grep *)"
    ]
  }
}
```

---

### Phase 7: Start services

Start the arra HTTP server as a background service:
```bash
# Option A: PM2 (recommended for persistent)
pm2 start "$(ghq root)/github.com/Soul-Brews-Studio/arra-oracle-v3/src/server.ts" \
  --name oracle-http \
  --interpreter bun \
  --env ORACLE_PROJECT_ROOTS="$HOME/ghq/github.com" \
  --env ORACLE_VECTOR_DB=lancedb

# Option B: Simple background
cd "$(ghq root)/github.com/Soul-Brews-Studio/arra-oracle-v3"
ORACLE_PROJECT_ROOTS="$HOME/ghq/github.com" ORACLE_VECTOR_DB=lancedb \
  nohup bun run server > /tmp/oracle-http.log 2>&1 &
```

---

### Phase 8: Index your repos

```bash
cd "$(ghq root)/github.com/Soul-Brews-Studio/arra-oracle-v3"
ORACLE_PROJECT_ROOTS="$HOME/ghq/github.com" bun run index
```

This scans all repos under your ghq root and indexes ψ/ files, learnings, retros, and principles into the knowledge base.

---

### Verification Checklist

Run these to confirm everything works:

```bash
# 1. maw CLI
maw --version

# 2. arra HTTP API
curl -s http://localhost:47778/api/health

# 3. arra MCP (restart Claude Code, then test)
# In Claude Code: arra_search("oracle principles")

# 4. Skills installed
ls ~/.claude/skills/ | wc -l  # expect 90+

# 5. Agent teams enabled
grep AGENT_TEAMS ~/.claude/settings.json
```

If all 5 pass, the machine is ready. Create an Oracle repo with `/awaken` or clone an existing one.

---

### Troubleshooting

| Problem | Fix |
|---------|-----|
| `maw: command not found` | `bun link` in maw-js dir, add `~/.bun/bin` to PATH |
| MCP server won't connect | Check `start-mcp.sh` has correct absolute paths, `chmod +x` |
| `arra_search` returns empty | Run `bun run index` to populate the DB |
| Skills not showing | Verify `~/.claude/skills/` has folders, restart Claude Code |
| `AGENT_TEAMS` tools missing | Check `~/.claude/settings.json` has the env var, restart session |
| Port 47778 in use | `lsof -i :47778` and kill, or set `ORACLE_PORT=47779` |
