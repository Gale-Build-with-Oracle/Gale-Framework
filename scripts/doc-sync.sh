#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
doc-sync.sh — collect merged PR traceability for /doc-sync

Usage:
  scripts/doc-sync.sh [--base main] [--marker docs/.last-doc-sync] [--write-report] [--apply-marker]

Default mode prints the merged PRs since docs/.last-doc-sync and validates REQ lines.
--write-report writes docs/.doc-sync/merged-prs.md for the Haiku doc-swarm.
--apply-marker writes the current base SHA to docs/.last-doc-sync; use ONLY after docs were updated and verified.
USAGE
}

BASE=main
MARKER_FILE="docs/.last-doc-sync"
WRITE_REPORT=0
APPLY_MARKER=0

while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:?--base needs a ref}"; shift 2 ;;
    --marker) MARKER_FILE="${2:?--marker needs a file}"; shift 2 ;;
    --write-report) WRITE_REPORT=1; shift ;;
    --apply-marker) APPLY_MARKER=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "P1: not inside a git repository" >&2
  exit 1
fi
ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT"

if [ ! -d docs ]; then
  echo "P1: docs/ missing — run Wind-Framework/scripts/init-project-docs.sh first" >&2
  exit 1
fi

BASE_SHA=$(git rev-parse "$BASE")
MARKER=""
if [ -f "$MARKER_FILE" ]; then
  MARKER=$(tr -d '[:space:]' < "$MARKER_FILE")
fi

if [ -n "$MARKER" ] && git cat-file -e "$MARKER^{commit}" 2>/dev/null; then
  RANGE="$MARKER..$BASE_SHA"
else
  RANGE="$BASE_SHA"
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

{
  echo "# Doc-sync input"
  echo
  echo "- Repo: $(basename "$ROOT")"
  echo "- Base: $BASE ($BASE_SHA)"
  echo "- Marker file: $MARKER_FILE"
  echo "- Previous marker: ${MARKER:-<missing or invalid>}"
  echo
  echo "## Merged PRs"
  echo
} > "$TMP"

FAIL=0
COUNT=0
SYNC_COUNT=0

# Merge subjects normally contain (#N). Keep first parent history only for release branch hygiene.
while IFS= read -r line; do
  [ -n "$line" ] || continue
  sha=${line%% *}
  subject=${line#* }
  pr=$(printf '%s\n' "$subject" | grep -oE '#[0-9]+' | tail -1 | tr -d '#' || true)
  [ -n "$pr" ] || continue
  COUNT=$((COUNT + 1))

  body=$(gh pr view "$pr" --json body --jq .body 2>/dev/null || true)
  title=$(gh pr view "$pr" --json title --jq .title 2>/dev/null || printf '%s' "$subject")
  req=$(printf '%s\n' "$body" | grep -E '^REQ: ' | tail -1 || true)

  if [ -z "$req" ]; then
    echo "P1: PR #$pr missing REQ line: $title" >&2
    FAIL=1
    req="REQ: <missing>"
  elif ! printf '%s\n' "$req" | grep -Eq '^REQ: (none|REQ-[A-Z][A-Z0-9]*-[0-9]+(, *REQ-[A-Z][A-Z0-9]*-[0-9]+)*)$'; then
    echo "P1: PR #$pr has invalid REQ line: $req" >&2
    FAIL=1
  fi

  if [ "$req" != "REQ: none" ]; then
    SYNC_COUNT=$((SYNC_COUNT + 1))
  fi

  {
    echo "### PR #$pr — $title"
    echo
    echo "- Merge SHA: $sha"
    echo "- $req"
    echo
  } >> "$TMP"
done < <(git log --first-parent --merges --format='%H %s' "$RANGE")

# --- Spec context: scan specs/ for design intent ---
if [ -d specs ]; then
  SPEC_COUNT=0
  {
    echo
    echo "## Design Specs (from specs/)"
    echo
  } >> "$TMP"

  for spec in specs/*.md; do
    [ -f "$spec" ] || continue
    spec_name=$(basename "$spec")
    issue_num=$(echo "$spec_name" | grep -oE '^[0-9]+' || true)
    if [ -n "$issue_num" ]; then
      {
        echo "### SPEC: $spec_name (Issue #$issue_num)"
        echo
        echo '```markdown'
        cat "$spec"
        echo '```'
        echo
      } >> "$TMP"
      SPEC_COUNT=$((SPEC_COUNT + 1))
    fi
  done

  echo "- Design specs found: $SPEC_COUNT" >> "$TMP"
fi

{
  echo "## Summary"
  echo
  echo "- Merged PRs scanned: $COUNT"
  echo "- PRs requiring docs sync: $SYNC_COUNT"
  echo "- Validation: $([ "$FAIL" -eq 0 ] && echo PASS || echo FAIL)"
} >> "$TMP"

cat "$TMP"

if [ "$WRITE_REPORT" -eq 1 ]; then
  mkdir -p docs/.doc-sync
  cp "$TMP" docs/.doc-sync/merged-prs.md
  echo "wrote docs/.doc-sync/merged-prs.md" >&2
fi

if [ "$APPLY_MARKER" -eq 1 ]; then
  if [ "$FAIL" -ne 0 ]; then
    echo "refusing to advance marker while PR traceability validation fails" >&2
    exit 1
  fi
  printf '%s\n' "$BASE_SHA" > "$MARKER_FILE"
  echo "advanced $MARKER_FILE to $BASE_SHA" >&2
fi

exit "$FAIL"
