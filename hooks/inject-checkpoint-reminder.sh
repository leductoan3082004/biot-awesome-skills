#!/bin/bash
# UserPromptSubmit hook: nudge the agent to run /context-save
# after substantive turns. Authoritative policy lives in
# biot-awesome-skills/instructions/context-save.md (routed from AGENTS.md).
#
# Stdout from this hook is appended to the model's context for the
# current turn. The text is a per-turn reminder, not enforcement.

cat <<'EOF'
[context-save policy reminder — full rules in biot-awesome-skills/instructions/context-save.md]

After completing the user's task this turn, judge whether SUBSTANTIVE
work happened:
  - code edits / writes / new files
  - completed multi-step investigation with concrete findings
  - decisions reached or plans finalized
  - bugs reproduced / root-caused / fixed
  - non-trivial refactors, migrations, configuration changes
  - validated behavior with tests or commands
  - clear stopping point before switching tasks

If YES → invoke /context-save BEFORE your final response.
  Writes ~/.claude/projects/checkpoints/YYYY-MM-DD_HHMMSS-<topic>/
  containing context.md + DECISIONS.md + PROGRESS.md + RESULTS.md +
  optional artifacts/. Topic-match auto-merges into the existing
  workstream across branches/commits; ambiguous matches AskUserQuestion.

If NO → SKIP /context-save. Skip when this turn is:
  - a clarifying question back to the user
  - a confirmation request before doing something
  - a trivial reply (single fact, short answer, status check)
  - read-only exploration with no conclusions yet
  - a follow-up tweak to work already saved earlier this session

When in doubt → lean toward skipping. Over-saving creates noise.

Restore with /context-restore (frontmatter-routes to best
match; asks when ambiguous; lazy-loads siblings).
EOF
