#!/usr/bin/env bash
# init-project-docs.sh — Bootstrap a project's docs/ with the lean 7-doc standard.
#
# ONE flat standard for EVERY project (no tiers). See /sop-cmmi. The seven docs:
#   PROJECT_PLAN, SRS, SDD, CR, RISK (Register+DAR+CAR), UXUI, UAT (REQ-id traceability).
#
# Usage:
#   init-project-docs.sh [options]
#
# Options:
#   --project-name <name>   Required. Project repository name (e.g., YourProduct-Web).
#   --req-prefix <prefix>   Optional. Uppercase prefix for REQ-ids (default: derived from project-name).
#   --target-dir <path>     Optional. Override target project directory (default: ~/ghq/github.com/${GITHUB_USER}/<name>).
#   --dry-run               Optional. Print plan without creating any files.
#   --force                 Optional. Overwrite existing files (default: skip existing).
#   --tier <x>              DEPRECATED no-op (kept for backward compat). All projects get the same 7 docs.
#   --help, -h              Show this help message.
#
# Examples:
#   init-project-docs.sh --project-name YourProduct-Web
#   init-project-docs.sh --project-name YourProduct-Site --dry-run
#   init-project-docs.sh --project-name YourProduct-Web --req-prefix YOURPRODWEB --force
#
# What it does:
#   Copies .md.tmpl files from templates/cmmi/ into <project>/docs/,
#   substituting {{PROJECT_NAME}}, {{DATE}}, {{REQ_ID_PREFIX}} placeholders.
#   Idempotent by default — skips files that already exist unless --force is passed.
#
# Standards:
#   Templates follow: SRS=IEEE 29148:2018, SDD=IEEE 1016-2009, UAT=IEEE 829-2008.
#
# History:
#   2026-04-18 — original project document bootstrap
#   2026-05-20 — extended to broader document scaffolding, --tier redesign
#   2026-06-01 — flattened to the lean 7-doc standard; tiers retired (--tier now a no-op)

set -euo pipefail

# ---- Defaults ----
DRY_RUN=0
FORCE=0
PROJECT_NAME=""
REQ_PREFIX=""
TIER="1"
TARGET_DIR_OVERRIDE=""
DATE_TODAY="$(date +%Y-%m-%d)"
GITHUB_USER="${GITHUB_USER:-$(gh api user -q .login 2>/dev/null || git config github.user 2>/dev/null || printf '<your-github-user>')}"

# ---- Parse args ----
while [ $# -gt 0 ]; do
  case "$1" in
    --project-name)
      shift
      PROJECT_NAME="${1:-}"
      shift
      ;;
    --req-prefix)
      shift
      REQ_PREFIX="${1:-}"
      shift
      ;;
    --tier)
      shift
      TIER="${1:-1}"
      shift
      ;;
    --target-dir)
      shift
      TARGET_DIR_OVERRIDE="${1:-}"
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//' | head -40
      exit 0
      ;;
    -*)
      echo "error: unknown flag: $1" >&2
      echo "  run with --help for usage" >&2
      exit 1
      ;;
    *)
      # Legacy positional argument support (backwards compatibility)
      if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME="$1"
      fi
      shift
      ;;
  esac
done

# ---- Validate required args ----
if [ -z "$PROJECT_NAME" ]; then
  echo "error: --project-name is required" >&2
  echo "  run with --help for usage" >&2
  exit 1
fi

# --tier is deprecated and ignored — every project gets the same 7-doc standard.
if [ "$TIER" != "1" ]; then
  echo "note: --tier is deprecated and ignored; installing the standard 7 docs." >&2
fi

# ---- Derive REQ prefix ----
if [ -z "$REQ_PREFIX" ]; then
  # Uppercase, remove hyphens: YourProduct-Web → YOURPRODWEBAWAY
  REQ_PREFIX="$(echo "$PROJECT_NAME" | tr '[:lower:]' '[:upper:]' | tr -d '-')"
fi

# ---- Locate my-oracle repo ----
# Support being run from inside a worktree of my-oracle
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
GALE_REPO="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$HOME/ghq/github.com/${GITHUB_USER}/my-oracle")"
TEMPLATE_DIR="$GALE_REPO/templates/cmmi"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "error: CMMI template directory not found: $TEMPLATE_DIR" >&2
  echo "  ensure you are running from inside my-oracle or a worktree of it" >&2
  exit 1
fi

# ---- Resolve target project directory ----
if [ -n "$TARGET_DIR_OVERRIDE" ]; then
  PROJECT_REPO="$TARGET_DIR_OVERRIDE"
else
  # Worktree-aware resolution (2026-04-18 worktree bug fix):
  # If CWD is inside a git repo whose basename matches PROJECT_NAME, write there.
  CWD_TOPLEVEL="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$CWD_TOPLEVEL" ] && [ "$(basename "$CWD_TOPLEVEL")" = "$PROJECT_NAME" ]; then
    PROJECT_REPO="$CWD_TOPLEVEL"
  else
    PROJECT_REPO="$HOME/ghq/github.com/${GITHUB_USER}/$PROJECT_NAME"
  fi
fi

DOCS_DIR="$PROJECT_REPO/docs"

# ---- Validate project directory ----
if [ ! -d "$PROJECT_REPO" ] && [ "$DRY_RUN" -eq 0 ] && [ -n "$TARGET_DIR_OVERRIDE" ]; then
  mkdir -p "$PROJECT_REPO"
fi

if [ ! -d "$PROJECT_REPO" ] && [ "$DRY_RUN" -eq 0 ]; then
  echo "error: project directory not found: $PROJECT_REPO" >&2
  echo "  is the project cloned? try: ghq get github.com/${GITHUB_USER}/$PROJECT_NAME" >&2
  echo "  or pass --target-dir <path> to override" >&2
  exit 1
fi

# ---- Helper: substitute template vars ----
substitute_template() {
  local src="$1"
  local dst="$2"
  local tmp
  tmp="$(mktemp)"
  sed \
    -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
    -e "s|{{DATE}}|${DATE_TODAY}|g" \
    -e "s|{{REQ_ID_PREFIX}}|${REQ_PREFIX}|g" \
    "$src" > "$tmp"
  mv "$tmp" "$dst"
}

# ---- Helper: install one template ----
FILES_PLANNED=()
FILES_WRITTEN=()
FILES_SKIPPED=()

plan_file() {
  local tmpl_rel="$1"   # relative to TEMPLATE_DIR, e.g. SRS.md.tmpl
  local dst_rel="$2"    # relative to DOCS_DIR, e.g. SRS.md
  local src="$TEMPLATE_DIR/$tmpl_rel"
  local dst="$DOCS_DIR/$dst_rel"

  FILES_PLANNED+=("$dst_rel")

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -f "$dst" ] && [ "$FORCE" -eq 0 ]; then
      echo "  skip (exists)  docs/$dst_rel"
    else
      echo "  write          docs/$dst_rel"
    fi
    return
  fi

  # Create parent directory
  mkdir -p "$(dirname "$dst")"

  if [ -f "$dst" ] && [ "$FORCE" -eq 0 ]; then
    FILES_SKIPPED+=("$dst_rel")
    return
  fi

  if [ -f "$src" ]; then
    substitute_template "$src" "$dst"
    FILES_WRITTEN+=("$dst_rel")
  elif [ "$src" = "__gitkeep__" ]; then
    # Special marker: create empty .gitkeep
    touch "$dst"
    FILES_WRITTEN+=("$dst_rel")
  else
    echo "  warning: template not found: $src (skipping)" >&2
    FILES_SKIPPED+=("$dst_rel")
  fi
}

# ---- Print header ----
echo ""
echo "init-project-docs.sh — lean 7-doc standard"
echo "  project      : $PROJECT_NAME"
echo "  req prefix   : $REQ_PREFIX"
echo "  target       : $DOCS_DIR"
echo "  template dir : $TEMPLATE_DIR"
echo "  mode         : $([ "$DRY_RUN" -eq 1 ] && echo dry-run || echo execute)"
echo "  force        : $([ "$FORCE" -eq 1 ] && echo yes || echo no)"
echo ""

# ---- The 7-doc standard (every project, no tiers) ----
echo "-- project documents (7-doc standard) --"
plan_file "PROJECT_PLAN.md.tmpl"  "PROJECT_PLAN.md"
plan_file "SRS.md.tmpl"           "SRS.md"
plan_file "SDD.md.tmpl"           "SDD.md"
plan_file "CR.md.tmpl"            "CR.md"
plan_file "RISK.md.tmpl"          "RISK.md"
plan_file "UXUI.md.tmpl"          "UXUI.md"
plan_file "UAT.md.tmpl"           "UAT.md"
echo ""

# ---- .gitignore patch ----
if [ "$DRY_RUN" -eq 0 ] && [ -d "$PROJECT_REPO" ]; then
  GITIGNORE="$PROJECT_REPO/.gitignore"
  if [ ! -f "$GITIGNORE" ] || ! grep -qx "build" "$GITIGNORE" 2>/dev/null; then
    {
      echo ""
      echo "# Doc pipeline (generated DOCX/PPTX/XLSX deliverables)"
      echo "build"
    } >> "$GITIGNORE"
    echo "patched .gitignore (added 'build')"
  fi
fi

# ---- Summary ----
if [ "$DRY_RUN" -eq 1 ]; then
  echo ""
  echo "dry-run complete — no files written"
  echo "  planned: ${#FILES_PLANNED[@]} files"
  echo "  re-run without --dry-run to execute"
else
  echo ""
  echo "done"
  echo "  written : ${#FILES_WRITTEN[@]} files"
  echo "  skipped : ${#FILES_SKIPPED[@]} files (already exist; use --force to overwrite)"
  echo ""
  echo "next steps:"
  echo "  1. cd $PROJECT_REPO"
  echo "  2. Review and fill TEMPLATE markers:"
  echo "     grep -rn '\[' docs/ | grep -v '.git' | head -30"
  echo "  3. git add docs/ && git commit -m 'docs: scaffold the 7-doc standard'"
  echo "  4. git push"
  echo ""
  echo "  delegate content fill:"
  echo "    maw hey <my-oracle|my-oracle> 'Fill $PROJECT_NAME/docs/ — maw workon $PROJECT_NAME docs-fill'"
fi
