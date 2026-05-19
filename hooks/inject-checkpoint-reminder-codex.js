#!/usr/bin/env node
/**
 * Codex UserPromptSubmit hook: emit the context-save reminder as valid JSON.
 *
 * The shared shell hook prints plain text for Claude Code. Codex requires
 * UserPromptSubmit stdout to be JSON when injecting context, so keep this
 * wrapper Codex-specific.
 */

const additionalContext = `[context-save policy]
After completing the user's task this turn, judge whether substantive work happened:
  - code edits / writes / new files
  - completed multi-step investigation with concrete findings
  - decisions reached or plans finalized
  - bugs reproduced / root-caused / fixed
  - non-trivial refactors, migrations, configuration changes

If YES -> invoke the /context-save-rolling skill before your final response.
It writes a topic-keyed living file to
~/.gstack/projects/<slug>/checkpoints/CURRENT-<topic-slug>.md and merges
into the matching topic instead of creating a fresh file per session.
Branch and commit are recorded inside the file (related_branches / related_commits
lists), so branch-hopping during the same workstream stays in one file.
A timestamped audit snapshot is also written alongside.

The skill performs topic-match automatically -- do NOT skip its Step 4
(topic-match decision). When the topic match is genuinely ambiguous it
will ask via AskUserQuestion; otherwise it merges silently.

If NO -> do NOT invoke /context-save-rolling. Skip it when this turn is:
  - a clarifying question back to the user
  - a confirmation request before doing something
  - a trivial reply (single fact, short answer, status check)
  - read-only exploration with no conclusions yet
  - a follow-up tweak to work that was already saved this session

When in doubt, lean toward skipping -- over-saving creates noise.

Note: the legacy gstack /context-save skill (single-file CONTEXT.md) is
still installed but deprecated for this user. Prefer /context-save-rolling.
Restore with /context-restore-rolling.`;

process.stdout.write(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: 'UserPromptSubmit',
    additionalContext,
  },
}));
