#!/bin/bash
# UserPromptSubmit hook: nudge the agent to run /checkpoint-save after substantive turns.
#
# Stdout from this hook is appended to the model's context for the current turn.
# The text is guidance, not enforcement — the model judges whether the turn
# warrants saving. See ~/.claude/CLAUDE.md for hook policy.

cat <<'EOF'
[checkpoint-save policy]
After completing the user's task this turn, judge whether substantive work happened:
  - code edits / writes / new files
  - completed multi-step investigation with concrete findings
  - decisions reached or plans finalized
  - bugs reproduced / root-caused / fixed
  - non-trivial refactors, migrations, configuration changes

If YES → invoke the /checkpoint-save skill before your final response so progress
lands in ~/.gstack/projects/<slug>/CONTEXT.md and survives session boundaries.

If NO → do NOT invoke /checkpoint-save. Skip it when this turn is:
  - a clarifying question back to the user
  - a confirmation request before doing something
  - a trivial reply (single fact, short answer, status check)
  - read-only exploration with no conclusions yet
  - a follow-up tweak to work that was already checkpointed this session

When in doubt, lean toward skipping — over-saving creates noise.
EOF
