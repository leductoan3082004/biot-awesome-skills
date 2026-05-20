#!/usr/bin/env node
/**
 * Codex UserPromptSubmit hook: emit the context-save reminder as valid JSON.
 *
 * The shared shell hook prints plain text for Claude Code. Codex requires
 * UserPromptSubmit stdout to be JSON when injecting context, so keep this
 * wrapper Codex-specific. Authoritative policy lives in AGENTS.md
 * § "Context save policy".
 */

const additionalContext = `[context-save policy reminder — full rules in AGENTS.md § "Context save policy"]

After completing the user's task this turn, judge whether SUBSTANTIVE
work happened:
  - code edits / writes / new files
  - completed multi-step investigation with concrete findings
  - decisions reached or plans finalized
  - bugs reproduced / root-caused / fixed
  - non-trivial refactors, migrations, configuration changes
  - validated behavior with tests or commands
  - clear stopping point before switching tasks

If YES -> invoke /context-save BEFORE your final response.
  Writes ~/.claude/projects/checkpoints/YYYY-MM-DD_HHMMSS-<topic>/
  containing context.md + DECISIONS.md + PROGRESS.md + RESULTS.md +
  optional artifacts/. Topic-match auto-merges into the existing
  workstream across branches/commits; ambiguous matches AskUserQuestion.

If NO -> SKIP /context-save. Skip when this turn is:
  - a clarifying question back to the user
  - a confirmation request before doing something
  - a trivial reply (single fact, short answer, status check)
  - read-only exploration with no conclusions yet
  - a follow-up tweak to work already saved earlier this session

When in doubt -> lean toward skipping. Over-saving creates noise.

Restore with /context-restore (frontmatter-routes to best
match; asks when ambiguous; lazy-loads siblings).`;

process.stdout.write(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'UserPromptSubmit',
    additionalContext,
  },
}));
