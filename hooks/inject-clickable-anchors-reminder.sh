#!/usr/bin/env bash
# Inject clickable-file-anchors reminder. Used by Claude Code and Codex on
# any event that can cause context loss (SessionStart, PostCompact).
# Emits JSON in the format both tools accept:
#   {"hookSpecificOutput":{"hookEventName":"<event>","additionalContext":"..."}}
# Usage: inject-clickable-anchors-reminder.sh <SessionStart|PostCompact>

EVENT="${1:-SessionStart}"

REMINDER=$(cat <<'EOF'
[clickable-file-anchors reminder — full rules in biot-awesome-skills/clickable-file-anchors/SKILL.md]

When your response includes a file reference, emit it in the iTerm2 +
VSCode/Cursor cmd-clickable form so the user can jump straight to the
line. Raw markdown paths and relative paths are NOT clickable.

Required format (wrap in single backticks, bare absolute path, single
integer line anchor):

  `/Users/toale/Developer/<repo>/<path>:<line>`

Rules:
  - Path MUST be absolute, starting with `/` (e.g. `/Users/toale/...`).
  - Line anchor MUST be a single integer (NOT a range `:172-176`).
  - Do NOT wrap in a markdown link `[label](file://...)` — iTerm2 ignores
    the wrapper; only the bare backticked path triggers semantic history.
  - When the anchor introduces a fenced code block, place it on its own
    line directly above the block with a trailing colon, no prose between.
  - For inline prose mentions (no quoted block), short relative names are
    fine — the rule only binds anchors that precede a fenced block, or
    any "open this at line N" pointer the user is meant to click.

Wrong → Right:
  packages/iris/src/foo.ts:42         →  `/Users/toale/Developer/iris/packages/iris/src/foo.ts:42`
  personnel/service/personnel.go:150-197  →  `/Users/toale/Developer/personnel/service/personnel.go:150`
  [foo.ts](file:///abs/path/foo.ts#L42)   →  `/abs/path/foo.ts:42`
EOF
)

jq -n --arg event "$EVENT" --arg ctx "$REMINDER" '{
  hookSpecificOutput: {
    hookEventName: $event,
    additionalContext: $ctx
  }
}'
