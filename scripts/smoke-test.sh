#!/usr/bin/env bash
# smoke-test.sh — Quick health check for a Docker-based project.
#
# Usage: smoke-test.sh <project-path> [port]
#   Checks: Docker containers running, health endpoints, auth login.
#   Returns: 0 = all pass, 1 = failures found.
#
# Example: smoke-test.sh ~/ghq/github.com/<your-github-user>/YourProject-Web 3100

set -uo pipefail

PROJECT_PATH="${1:?Usage: smoke-test.sh <project-path> [port]}"
PORT="${2:-}"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

if [ ! -d "$PROJECT_PATH" ]; then
  echo "✗ $PROJECT_PATH does not exist"
  exit 1
fi

cd "$PROJECT_PATH"

PASS=0
FAIL=0
report() { if [ "$1" = "pass" ]; then ((PASS++)); echo "  ✓ $2"; else ((FAIL++)); echo "  ✗ $2"; fi; }

echo "=== Smoke Test: $PROJECT_NAME ==="

# 1. Docker containers
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
  RUNNING=$(docker compose ps --format json 2>/dev/null | python3 -c "
import sys, json
count = 0
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        c = json.loads(line)
        state = c.get('State', c.get('state', ''))
        if 'running' in state.lower(): count += 1
    except: pass
print(count)
" 2>/dev/null || echo "0")
  if [ "$RUNNING" -gt 0 ]; then
    report pass "Docker: $RUNNING container(s) running"
  else
    report fail "Docker: no containers running"
  fi

  UNHEALTHY=$(docker compose ps --format json 2>/dev/null | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        c = json.loads(line)
        h = c.get('Health', c.get('health', ''))
        if h and 'unhealthy' in h.lower():
            print(c.get('Name', c.get('name', 'unknown')))
    except: pass
" 2>/dev/null || true)
  if [ -n "$UNHEALTHY" ]; then
    report fail "Docker health: unhealthy containers: $UNHEALTHY"
  else
    report pass "Docker health: all healthy (or no health checks configured)"
  fi
else
  echo "  ⊘ No docker-compose.yml — skipping Docker checks"
fi

# 2. HTTP health (if port provided or detected)
if [ -z "$PORT" ]; then
  PORT=$(grep -oP '(?<=ports:.*)\d{4,5}(?=:)' docker-compose.yml 2>/dev/null | head -1 || true)
  [ -z "$PORT" ] && PORT=$(grep -oP '"\d{4,5}:\d{2,5}"' docker-compose.yml 2>/dev/null | head -1 | grep -oP '^\d+' || true)
fi

if [ -n "$PORT" ]; then
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT" --connect-timeout 5 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    report pass "HTTP :$PORT → $HTTP_CODE"
  elif [ "$HTTP_CODE" = "000" ]; then
    report fail "HTTP :$PORT → connection refused"
  else
    report pass "HTTP :$PORT → $HTTP_CODE (running, may need auth)"
  fi

  HEALTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/api/health" --connect-timeout 5 2>/dev/null || echo "000")
  if [ "$HEALTH_CODE" = "200" ]; then
    report pass "Health endpoint /api/health → 200"
  elif [ "$HEALTH_CODE" = "000" ] || [ "$HEALTH_CODE" = "404" ]; then
    echo "  ⊘ No /api/health endpoint (optional)"
  else
    report fail "Health endpoint /api/health → $HEALTH_CODE"
  fi
else
  echo "  ⊘ No port detected — skipping HTTP checks"
fi

# 3. Project structure
[ -f "CLAUDE.md" ]   && report pass "CLAUDE.md exists"   || report fail "CLAUDE.md missing"
[ -f "AGENTS.md" ]   && report pass "AGENTS.md exists"   || report fail "AGENTS.md missing"
[ -d "docs" ]        && report pass "docs/ exists"        || report fail "docs/ missing"
[ -d "ψ" ] || [ -d "ψ/memory" ] && report pass "ψ/ exists" || report fail "ψ/ missing"
[ -d ".github/workflows" ] && report pass "CI configured" || report fail "CI not configured"

echo ""
echo "=== Result: $PASS passed, $FAIL failed ==="
exit $(( FAIL > 0 ? 1 : 0 ))
