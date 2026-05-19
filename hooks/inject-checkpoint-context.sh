#!/usr/bin/env bash
# inject-checkpoint-context.sh
#
# Claude Code + Codex PostCompact hook. After compaction, inject the most
# recently updated topic-keyed checkpoint into the model's context so the
# next turn resumes the same workstream.
#
# Lookup order (first match wins):
#   1. Topic-keyed rolling checkpoints (preferred):
#      ~/.gstack/projects/<slug>/checkpoints/CURRENT-<topic-slug>.md
#      → pick the file with the latest mtime.
#   2. Legacy single-file checkpoint (gstack /context-save):
#      ~/.gstack/projects/<slug>/CONTEXT.md
#   3. Legacy timestamped snapshots (gstack /context-save older format):
#      ~/.gstack/projects/<slug>/checkpoints/20YYMMDD-HHMMSS-*.md
#      → pick the newest by filename sort.
#
# Output contract:
#   - On success: print a short header plus the file body to stdout. Exit 0.
#   - On any failure (no slug, no file, unreadable, no gstack): exit 0
#     silently. Never fail the compact flow.

set -u
set +e

# Hook runtimes may export CLAUDE_PROJECT_DIR for the active project.
PROJ_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$PROJ_DIR" 2>/dev/null || exit 0

# Resolve the gstack slug for this directory.
SLUG=""
if [ -x "$HOME/.claude/skills/gstack/bin/gstack-slug" ]; then
  eval "$("$HOME/.claude/skills/gstack/bin/gstack-slug" 2>/dev/null)" 2>/dev/null
fi

[ -z "${SLUG:-}" ] && exit 0

PROJECT_DIR="$HOME/.gstack/projects/$SLUG"
CHECKPOINT_DIR="$PROJECT_DIR/checkpoints"
CONTEXT_FILE=""
SOURCE_LABEL=""

# 1) Topic-keyed rolling checkpoint: pick newest CURRENT-*.md by mtime.
if [ -d "$CHECKPOINT_DIR" ]; then
  NEWEST_ROLLING=$(find "$CHECKPOINT_DIR" -maxdepth 1 -name "CURRENT-*.md" -type f \
    -exec stat -f '%m %N' {} \; 2>/dev/null \
    | sort -nr | head -1 | cut -d' ' -f2-)
  if [ -z "$NEWEST_ROLLING" ]; then
    # Linux/GNU stat fallback.
    NEWEST_ROLLING=$(find "$CHECKPOINT_DIR" -maxdepth 1 -name "CURRENT-*.md" -type f \
      -printf '%T@ %p\n' 2>/dev/null \
      | sort -nr | head -1 | cut -d' ' -f2-)
  fi
  if [ -n "$NEWEST_ROLLING" ] && [ -r "$NEWEST_ROLLING" ]; then
    CONTEXT_FILE="$NEWEST_ROLLING"
    SOURCE_LABEL="/context-save-rolling (topic-keyed)"
  fi
fi

# 2) Legacy single-file CONTEXT.md.
if [ -z "$CONTEXT_FILE" ]; then
  LEGACY_SINGLE="$PROJECT_DIR/CONTEXT.md"
  if [ -f "$LEGACY_SINGLE" ] && [ -r "$LEGACY_SINGLE" ]; then
    CONTEXT_FILE="$LEGACY_SINGLE"
    SOURCE_LABEL="gstack /context-save (legacy single-file)"
  fi
fi

# 3) Legacy timestamped snapshots.
if [ -z "$CONTEXT_FILE" ] && [ -d "$CHECKPOINT_DIR" ]; then
  NEWEST_LEGACY=$(find "$CHECKPOINT_DIR" -maxdepth 1 -name "20*.md" -type f 2>/dev/null \
    | sort -r | head -1)
  if [ -n "$NEWEST_LEGACY" ] && [ -r "$NEWEST_LEGACY" ]; then
    CONTEXT_FILE="$NEWEST_LEGACY"
    SOURCE_LABEL="gstack /context-save (legacy timestamped audit snapshot)"
  fi
fi

[ -z "$CONTEXT_FILE" ] && exit 0

LAST_MOD=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$CONTEXT_FILE" 2>/dev/null \
  || stat -c '%y' "$CONTEXT_FILE" 2>/dev/null \
  || echo "unknown")

cat <<HEADER
## Restored Working Context (from $SOURCE_LABEL)

Loaded automatically after compaction from \`$CONTEXT_FILE\` (last saved: $LAST_MOD).

This is the state the previous session ended with for this project's
most-recently-touched topic. Treat any **Open remaining work** /
**Remaining Work** list below as the to-do queue for this session — do
not start from a clean slate. If the user immediately asks something
unrelated, abandon this context; otherwise resume.

If you need to switch topics or load a different rolling checkpoint, use
\`/context-restore-rolling list\` to see all topic files, or
\`/context-restore-rolling <topic-fragment>\` to pick a specific one.

---

HEADER

cat "$CONTEXT_FILE"
