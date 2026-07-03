#!/usr/bin/env bash
set -euo pipefail

# deploy-project.sh — git pull + Docker rebuild with health-check rollback.
# Usage: deploy-project.sh <project-path> <project-name> [health-wait-seconds]
# Optional: set DEPLOY_NOTIFY_TARGET (a `maw hey` target, e.g. "my-oracle") to
# get a ping on rollback/success; defaults to "my-oracle" and is skipped
# silently if `maw` isn't installed.

PROJECT_PATH="$1"
PROJECT_NAME="$2"
HEALTH_WAIT="${3:-30}"
NOTIFY_TARGET="${DEPLOY_NOTIFY_TARGET:-my-oracle}"

if [ ! -d "$PROJECT_PATH" ]; then
  echo "ERROR: $PROJECT_PATH does not exist"
  exit 1
fi

LOCKFILE="/tmp/deploy-${PROJECT_NAME}.lock"
exec 200>"$LOCKFILE"
flock -n 200 || { echo "ERROR: Deploy already in progress for $PROJECT_NAME"; exit 1; }

cd "$PROJECT_PATH"

PREV_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
echo "=== Deploying $PROJECT_NAME (current: ${PREV_SHA:0:7}) ==="

echo "=== Pulling latest ==="
git pull origin main

NEW_SHA=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
if [ "$PREV_SHA" = "$NEW_SHA" ]; then
  echo "=== No new commits — skipping rebuild ==="
  exit 0
fi

echo "=== Rebuilding Docker containers (${PREV_SHA:0:7} → ${NEW_SHA:0:7}) ==="
docker compose up -d --build

echo "=== Pruning stale Docker resources ==="
docker image prune -f 2>/dev/null || true
docker volume prune -f 2>/dev/null || true

echo "=== Waiting ${HEALTH_WAIT}s for health checks ==="
sleep "$HEALTH_WAIT"

UNHEALTHY=$(docker compose ps --format json 2>/dev/null | \
  python3 -c "
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
  echo "=== UNHEALTHY containers detected: $UNHEALTHY ==="
  echo "=== Rolling back to ${PREV_SHA:0:7} ==="
  git checkout "$PREV_SHA" 2>/dev/null
  docker compose up -d --build
  echo "=== Rollback complete — containers restored to ${PREV_SHA:0:7} ==="
  git checkout main 2>/dev/null

  maw hey "$NOTIFY_TARGET" "[deploy] ROLLBACK: $PROJECT_NAME rolled back ${NEW_SHA:0:7} → ${PREV_SHA:0:7}. Unhealthy: $UNHEALTHY" 2>/dev/null || true
  exit 1
fi

echo "=== Container status ==="
docker compose ps || echo "WARNING: Could not retrieve container status"

echo "=== Deploy succeeded: $PROJECT_NAME (${NEW_SHA:0:7}) ==="

maw hey "$NOTIFY_TARGET" "[deploy] OK: $PROJECT_NAME deployed ${NEW_SHA:0:7}" 2>/dev/null || true
