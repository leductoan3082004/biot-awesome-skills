#!/usr/bin/env bash
# inject-checkpoint-context.sh
#
# Claude Code SessionStart hook. Fires on `startup`, `resume`, `clear`,
# and `compact`. If the current project has a saved checkpoint at
# ~/.gstack/projects/<slug>/CONTEXT.md, print it to stdout so the
# harness injects it as additional context for the new/resumed session.
#
# Paired with the `checkpoint-save` skill, which writes that file.
#
# Output contract:
#   - On success with a checkpoint file present: print a short header
#     plus the file body to stdout. Exit 0.
#   - On any failure (no slug, no file, unreadable, no gstack): exit 0
#     silently. Never fail the session start.

set -u
set +e

# Claude Code exports CLAUDE_PROJECT_DIR for the active project.
PROJ_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$PROJ_DIR" 2>/dev/null || exit 0

# Resolve the gstack slug for this directory.
SLUG=""
if [ -x "$HOME/.claude/skills/gstack/bin/gstack-slug" ]; then
  eval "$("$HOME/.claude/skills/gstack/bin/gstack-slug" 2>/dev/null)" 2>/dev/null
fi

[ -z "${SLUG:-}" ] && exit 0

CONTEXT_FILE="$HOME/.gstack/projects/$SLUG/CONTEXT.md"
[ ! -f "$CONTEXT_FILE" ] && exit 0
[ ! -r "$CONTEXT_FILE" ] && exit 0

# Stat the file once so the header tells the agent how fresh the
# checkpoint is. Stale checkpoints are common when switching projects.
LAST_MOD=$(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$CONTEXT_FILE" 2>/dev/null \
  || stat -c '%y' "$CONTEXT_FILE" 2>/dev/null \
  || echo "unknown")

cat <<HEADER
## Restored Working Context (from /checkpoint-save)

Loaded automatically at session start from \`$CONTEXT_FILE\` (last saved: $LAST_MOD).

This is the state the previous session ended with. Treat the **Remaining Work** list below as the to-do queue for this session — do not start from a clean slate. If the user immediately asks something unrelated, abandon this context; otherwise resume.

---

HEADER

cat "$CONTEXT_FILE"
