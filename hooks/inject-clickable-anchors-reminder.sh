#!/usr/bin/env bash
# Inject clickable-file-anchors reminder. Used by Claude Code and Codex on
# any event that can cause context loss (SessionStart, PostCompact).
# Emits JSON: {"hookSpecificOutput":{"hookEventName":"<event>","additionalContext":"..."}}
# Usage: inject-clickable-anchors-reminder.sh <SessionStart|PostCompact>
#
# Hook stays small on purpose: full rules live in
# biot-awesome-skills/instructions/clickable-file-anchors.md and are wired
# into AGENTS.md's "On-demand instructions" table. The hook just nudges
# the agent to read that file before emitting file references.

EVENT="${1:-SessionStart}"

REMINDER=$(cat <<'EOF'
[clickable-file-anchors reminder]

Before emitting any file reference the user is meant to click, follow
the rules in:

  /Users/toale/Developer/biot-awesome-skills/instructions/clickable-file-anchors.md

If you have not read that file this session, read it now.

TL;DR — pick by AGENT, not by abstract surface:
  - Codex (web/desktop chat UI):  [label](/abs/path:line)
    Paths with spaces:            [label](</abs/path with spaces:line>)
  - Claude Code (terminal CLI):   backticked /abs/path:line — on its
                                  own line above a fenced block, or
                                  inline. Markdown brackets/parens
                                  break terminal semantic-history.

Universal: absolute path, single-integer line (no ranges), no file:// URLs.
EOF
)

jq -n --arg event "$EVENT" --arg ctx "$REMINDER" '{
  hookSpecificOutput: {
    hookEventName: $event,
    additionalContext: $ctx
  }
}'
