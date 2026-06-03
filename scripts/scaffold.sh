#!/usr/bin/env bash
# scaffold.sh — bootstrap a new project with the standard setup
# (beads + uv + CLAUDE.md/AGENTS.md + CI). Non-destructive by default.
#
# Usage:
#   scaffold.sh <target-dir> [options]
#
# Options:
#   --name NAME        Project name (default: basename of target dir)
#   --profile P        data | python | minimal  (default: data)
#   --python X.Y       Python version (default: 3.11)
#   --no-data          Skip data/{bronze,silver,gold} dirs (data profile only)
#   --no-github        Skip GitHub Actions CI + smoke test
#   --no-mcp           Skip .mcp.json (playwright/context7)
#   --backup           Back up existing files to <file>.bak-<ts> before writing
#   --force            Overwrite existing files
#   --dry-run          Print actions, change nothing
#
# Templates are resolved relative to this script, or via $PROJECT_KIT_HOME.
set -euo pipefail

# --- locate templates -------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_KIT_HOME="${PROJECT_KIT_HOME:-$(dirname "$SCRIPT_DIR")}"
TPL="$PROJECT_KIT_HOME/templates"
if [[ ! -d "$TPL" ]]; then
  echo "error: templates dir not found at $TPL (set PROJECT_KIT_HOME)" >&2
  exit 1
fi

# --- defaults / arg parsing -------------------------------------------------
TARGET=""; NAME=""; PROFILE="data"; PYTHON="3.11"
NO_DATA=false; NO_GITHUB=false; NO_MCP=false
FORCE=false; BACKUP=false; DRYRUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)     NAME="$2"; shift 2 ;;
    --profile)  PROFILE="$2"; shift 2 ;;
    --python)   PYTHON="$2"; shift 2 ;;
    --no-data)  NO_DATA=true; shift ;;
    --no-github) NO_GITHUB=true; shift ;;
    --no-mcp)   NO_MCP=true; shift ;;
    --force)    FORCE=true; shift ;;
    --backup)   BACKUP=true; shift ;;
    --dry-run)  DRYRUN=true; shift ;;
    -h|--help)  sed -n '2,22p' "$0"; exit 0 ;;
    -*)         echo "error: unknown option $1" >&2; exit 1 ;;
    *)          if [[ -z "$TARGET" ]]; then TARGET="$1"; else echo "error: unexpected arg $1" >&2; exit 1; fi; shift ;;
  esac
done

[[ -n "$TARGET" ]] || { echo "error: target dir required" >&2; exit 1; }
case "$PROFILE" in data|python|minimal) ;; *) echo "error: --profile must be data|python|minimal" >&2; exit 1 ;; esac
[[ -n "$NAME" ]] || NAME="$(basename "$TARGET")"

PKG="$(printf '%s' "$NAME" | sed -e 's/[^A-Za-z0-9]/_/g' | tr 'A-Z' 'a-z')"
TARGET_VERSION="py${PYTHON//./}"
TS="$(date +%Y%m%d-%H%M%S)"

# profile gates
WANT_PY=true;   [[ "$PROFILE" == minimal ]] && WANT_PY=false
WANT_DATA=false; { [[ "$PROFILE" == data ]] && [[ "$NO_DATA" == false ]]; } && WANT_DATA=true
WANT_GITHUB=true; { [[ "$NO_GITHUB" == true ]] || [[ "$PROFILE" == minimal ]]; } && WANT_GITHUB=false
WANT_MCP=true;  [[ "$NO_MCP" == true ]] && WANT_MCP=false

# dependency set per profile
case "$PROFILE" in
  data)    DEPS=$'    "polars>=1.0",\n    "duckdb>=1.2",\n    "pyarrow>=15.0",\n    "rich>=13.0",' ;;
  python)  DEPS=$'    "rich>=13.0",' ;;
  minimal) DEPS="" ;;
esac

# --- helpers ----------------------------------------------------------------
CREATED=0; SKIPPED=0; BACKED=0
note() { printf '  %s\n' "$*"; }

render() { # substitute single-line placeholders, then the multi-line {{deps}}
  sed -e "s|{{name}}|${NAME}|g" \
      -e "s|{{pkg}}|${PKG}|g" \
      -e "s|{{python}}|${PYTHON}|g" \
      -e "s|{{target_version}}|${TARGET_VERSION}|g" "$1" \
  | awk -v d="$DEPS" '{ if ($0 ~ /\{\{deps\}\}/) { print d } else { print } }'
}

mkdirp() { if $DRYRUN; then note "would mkdir: $1"; else mkdir -p "$1"; fi; }
runin() { # run a command inside a dir, honoring dry-run
  local dir="$1"; shift
  if $DRYRUN; then note "would run (in $dir): $*"; else ( cd "$dir" && "$@" ); fi
}

emit_render() { # render template $1 → dest $2 (no pipe, so counters persist)
  local tmp; tmp="$(mktemp)"; render "$1" > "$tmp"; emit "$2" < "$tmp"; rm -f "$tmp"
}

emit() { # reads content from stdin → $1, honoring the safety model
  local dest="$1"
  if [[ -e "$dest" && "$FORCE" == false && "$BACKUP" == false ]]; then
    note "skip (exists): $dest"; SKIPPED=$((SKIPPED+1)); cat >/dev/null; return 0
  fi
  if [[ -e "$dest" && "$BACKUP" == true && "$FORCE" == false ]]; then
    if $DRYRUN; then note "would backup: $dest -> ${dest}.bak-${TS}"; else cp -f "$dest" "${dest}.bak-${TS}"; fi
    BACKED=$((BACKED+1))
  fi
  if $DRYRUN; then note "would create: $dest"; CREATED=$((CREATED+1)); cat >/dev/null; return 0; fi
  mkdir -p "$(dirname "$dest")"
  cat > "$dest"
  note "create: $dest"; CREATED=$((CREATED+1))
}

# --- scaffold ---------------------------------------------------------------
echo "project-kit: scaffolding '$NAME' (profile=$PROFILE, python=$PYTHON) into $TARGET"
$DRYRUN && echo "  [dry-run — no changes will be made]"

mkdirp "$TARGET"

$WANT_PY  && mkdirp "$TARGET/src/$PKG"
if $WANT_DATA; then mkdirp "$TARGET/data/bronze"; mkdirp "$TARGET/data/silver"; mkdirp "$TARGET/data/gold"; fi

# 2. git
[[ -d "$TARGET/.git" ]] || runin "$TARGET" git init -q

# 3. pyproject + gitignore
if $WANT_PY; then emit_render "$TPL/pyproject.toml.tmpl" "$TARGET/pyproject.toml"; fi
emit "$TARGET/.gitignore" < "$TPL/gitignore"

# 4. .claude settings
mkdirp "$TARGET/.claude"
emit "$TARGET/.claude/settings.json" < "$TPL/claude-settings.json"
if [[ -e "$TARGET/.claude/settings.local.json" ]]; then
  note "skip (exists): $TARGET/.claude/settings.local.json"; SKIPPED=$((SKIPPED+1))
else
  emit "$TARGET/.claude/settings.local.json" < "$TPL/claude-settings.local.json"
fi

# 5. instruction files
emit "$TARGET/AGENTS.md" < "$TPL/AGENTS.md"
emit_render "$TPL/CLAUDE.md.tmpl" "$TARGET/CLAUDE.md"

# 6. beads (guarded)
if [[ -d "$TARGET/.beads" ]]; then
  note "skip (exists): .beads/ — not running bd init"
elif command -v bd >/dev/null 2>&1; then
  runin "$TARGET" bd init
else
  note "bd not found on PATH — install beads, then run 'bd init' here"
fi

# 7. CI + smoke test
if $WANT_GITHUB; then
  mkdirp "$TARGET/.github/workflows"; mkdirp "$TARGET/tests"
  emit_render "$TPL/ci.yml.tmpl" "$TARGET/.github/workflows/ci.yml"
  emit "$TARGET/tests/test_smoke.py" < "$TPL/test_smoke.py"
fi

# 8. MCP
if $WANT_MCP; then emit "$TARGET/.mcp.json" < "$TPL/mcp.json.tmpl"; fi

# 9. uv sync
if $WANT_PY; then
  if command -v uv >/dev/null 2>&1; then runin "$TARGET" uv sync --extra dev
  else note "uv not found on PATH — install uv, then run 'uv sync --extra dev' here"; fi
fi

# 10. summary
echo
echo "Done: $CREATED created, $SKIPPED skipped, $BACKED backed up."
$DRYRUN && echo "(dry-run — nothing was written)"
cat <<EOF

Next steps:
  cd $TARGET
  - Fill in CLAUDE.md (Domain Context, Architecture, Key Files)
  - bd ready                 # start tracking work
  - git add -A && git commit # first commit
EOF
