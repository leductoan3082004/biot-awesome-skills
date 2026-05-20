#!/usr/bin/env bash
# inject-checkpoint-context.sh
#
# Claude Code + Codex PostCompact hook. After compaction, inject the
# most-recently-updated topic-keyed checkpoint into the model's context so
# the next turn resumes the same workstream.
#
# Single global checkpoint dir — no per-project scoping. All saved topics
# from all working directories live side-by-side under
# ~/.claude/projects/checkpoints/.
#
# Lookup order (first match wins):
#   1. v3 topic-snapshot folder (current /context-save layout):
#      ~/.claude/projects/checkpoints/YYYY-MM-DD_HHMMSS-<topic-slug>/context.md
#      → pick the folder whose name sorts highest (newest timestamp).
#   2. v2 topic-keyed file (legacy v2 layout):
#      ~/.claude/projects/checkpoints/CURRENT-<topic-slug>.md
#      → pick the file with the latest mtime.
#   3. Legacy timestamped snapshots (older gstack format):
#      ~/.claude/projects/checkpoints/20YYMMDD-HHMMSS-*.md
#      → pick the newest by filename sort.
#
# Output contract:
#   - On success: print a short header plus the file body to stdout. Exit 0.
#   - On any failure (no file, unreadable): exit 0 silently. Never fail the
#     compact flow.

set -u
set +e

CHECKPOINT_DIR="$HOME/.claude/projects/checkpoints"
[ -d "$CHECKPOINT_DIR" ] || exit 0

CONTEXT_FILE=""
SOURCE_LABEL=""

# 1) v3 topic-snapshot folder: pick newest by folder-name sort (timestamp prefix).
NEWEST_V3=$(find "$CHECKPOINT_DIR" -mindepth 1 -maxdepth 1 -type d -name "20*-*" 2>/dev/null \
  | sort -r | head -1)
if [ -n "$NEWEST_V3" ] && [ -f "$NEWEST_V3/context.md" ] && [ -r "$NEWEST_V3/context.md" ]; then
  CONTEXT_FILE="$NEWEST_V3/context.md"
  SOURCE_LABEL="/context-save v3 topic-snapshot folder"
fi

# 2) v2 topic-keyed file: pick newest CURRENT-*.md by mtime.
if [ -z "$CONTEXT_FILE" ]; then
  NEWEST_V2=$(find "$CHECKPOINT_DIR" -maxdepth 1 -name "CURRENT-*.md" -type f \
    -exec stat -f '%m %N' {} \; 2>/dev/null \
    | sort -nr | head -1 | cut -d' ' -f2-)
  if [ -z "$NEWEST_V2" ]; then
    NEWEST_V2=$(find "$CHECKPOINT_DIR" -maxdepth 1 -name "CURRENT-*.md" -type f \
      -printf '%T@ %p\n' 2>/dev/null \
      | sort -nr | head -1 | cut -d' ' -f2-)
  fi
  if [ -n "$NEWEST_V2" ] && [ -r "$NEWEST_V2" ]; then
    CONTEXT_FILE="$NEWEST_V2"
    SOURCE_LABEL="legacy v2 topic-keyed file"
  fi
fi

# 3) Legacy timestamped snapshots.
if [ -z "$CONTEXT_FILE" ]; then
  NEWEST_LEGACY=$(find "$CHECKPOINT_DIR" -maxdepth 1 -name "20*.md" -type f 2>/dev/null \
    | sort -r | head -1)
  if [ -n "$NEWEST_LEGACY" ] && [ -r "$NEWEST_LEGACY" ]; then
    CONTEXT_FILE="$NEWEST_LEGACY"
    SOURCE_LABEL="legacy timestamped audit snapshot"
  fi
fi

[ -z "$CONTEXT_FILE" ] && exit 0

LAST_MOD=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$CONTEXT_FILE" 2>/dev/null \
  || stat -c '%y' "$CONTEXT_FILE" 2>/dev/null \
  || echo "unknown")

cat <<HEADER
## Restored Working Context (from $SOURCE_LABEL)

Loaded automatically after compaction from \`$CONTEXT_FILE\` (last saved: $LAST_MOD).

This is the most-recently-touched topic across ALL projects (single global
checkpoint dir — no per-project scoping). If this topic doesn't match what
you're about to work on, abandon it and use \`/context-restore <topic-fragment>\`
to load a different one. Use \`/context-restore list\` to see all topics.

---

HEADER

cat "$CONTEXT_FILE"
