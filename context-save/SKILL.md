---
name: context-save
description: Snapshot current Claude Code session state to a persistent file outside the repo. Captures branch, commits, uncommitted diff, decisions, investigation findings, open questions, and mental model. Use when user says "save context", "checkpoint this", "remember where we are", "/context-save", before switching tasks/branches, or before ending a session you may resume later. Also use proactively when a session has accumulated significant investigation or decisions that would be painful to reconstruct. Stores under ~/.claude/contexts/<repo-slug>/ — never writes inside the working repo.
---

# context-save

Persists session state so a future session (same or different day, same or different repo checkout) can resume with full context. Think of it as a bookmark for your brain — everything you'd need to tell a colleague picking up your work.

## Storage location

**Never write inside the working repo.** Always write to:

```
~/.claude/contexts/<repo-slug>/<timestamp>-<short-topic>.md
```

- `<repo-slug>` = absolute repo path with `/` replaced by `-`, leading `-` stripped.
  Example: `/Users/toale/Developer/iris` → `Users-toale-Developer-iris`
- `<timestamp>` = `YYYY-MM-DD-HHMM` (local time)
- `<short-topic>` = 2-5 word kebab-case slug of current task (e.g. `rms-109955-placeholder-visibility`)

Create the directory if it doesn't exist (`mkdir -p`). This lives in `~/.claude/`, not in the user's repo — it survives branch switches, rebases, and worktree cleanup.

## What to capture

A good save lets a future session pick up cold — no conversation history needed. Gather these before writing:

### Always capture

1. **Session metadata** — date/time, repo path, current branch, working directory, git user
2. **Task / goal** — one paragraph: what is the user trying to accomplish and why
3. **Branch state** — output of `git status --short`, `git log -10 --oneline`, list of uncommitted files and their nature (new/modified/deleted)
4. **Decisions made** — choices the user and agent made during the session and *why* (not just what). Include rejected alternatives and the reasoning.
5. **Investigation findings** — files read, key code locations (`path:line`), patterns discovered, how components connect. This is often the most valuable part — reconstructing investigation from scratch is expensive.
6. **Open questions / next steps** — what is unresolved, what to do first on resume, blockers

### Include when relevant

7. **Related links** — Jira tickets (RMS-####), PR URLs, design docs, Slack threads, Quip docs
8. **Failed approaches** — what was tried and rejected, with reason. Prevents re-treading dead ends.
9. **Mental model / insights** — non-obvious things learned about how the system works, hidden coupling, gotchas discovered
10. **Pending state** — long-running processes, dev servers running, agents in flight, test results waiting
11. **Key code snippets** — small (<20 line) code blocks that are central to the investigation or decision. Don't dump entire files — reference by path:line instead.
12. **Dependencies / blockers** — things that need to happen outside this session (PR review, backend deploy, team decision)

## How to gather

Run these commands in parallel to get repo state:

```bash
git rev-parse --show-toplevel
git branch --show-current
git status --short
git log -10 --oneline
git diff --stat
date '+%Y-%m-%d %H:%M %Z'
```

For task/decision/investigation content: extract from the conversation transcript. The user already said these things — don't ask them to repeat. Skim the full conversation and pull out:
- Every decision or choice point
- Every file that was read or modified
- Every finding or "aha" moment
- Every question that was asked but not fully resolved

If unsure whether something is worth capturing, include it. Storage is cheap; reconstructing lost context is expensive.

## File format

Use YAML frontmatter for machine-searchable metadata + structured markdown for the human-readable body.

```markdown
---
saved_at: 2026-05-04T14:32-07:00
repo: /Users/toale/Developer/iris
branch: toale_axoncorp/RMS-109955-searchable-placeholder-visibility
topic: searchable placeholder card visibility
tags: [iris, form-card, RMS-109955, placeholder, visibility]
jira: RMS-109955
pr: null
related_saves: []
---

# Searchable Placeholder Card Visibility

## Goal
<1-paragraph statement of what the user is trying to do and why>

## Branch & commits
- Branch: `toale_axoncorp/RMS-109955-searchable-placeholder-visibility`
- Base: `master` (`abc1234`)
- Recent commits:
  - `87ea60d` fix: keep unresolved entity-backed cards visible
  - ...
- Uncommitted changes: <list, or "clean working tree">

## Decisions
- **<decision>** — <why, what alternatives were considered>
- ...

## Investigation findings
- `packages/iris/src/pages/standards/foo.tsx:142` — <what was found, why it matters>
- ...

## Open questions / next steps
1. <concrete next action on resume>
2. <unresolved question>
- ...

## Failed approaches
- <approach> — <why rejected>

## Mental model / insights
- <non-obvious thing learned about how the system works>

## Related links
- [RMS-109955](https://taserintl.atlassian.net/browse/RMS-109955)

## Resume hints
- **Start by:** <first concrete action on resume>
- **Watch out for:** <gotchas, things easy to forget>
- **Dev environment state:** <servers running, build state, etc.>
```

## Linking related saves

If this save continues earlier work on the same topic/branch, populate `related_saves:` in frontmatter with prior filenames. This lets `context-restore` reconstruct a timeline across sessions.

Before writing, check for prior saves in the same `<repo-slug>/` directory matching the branch or topic:

```bash
ls ~/.claude/contexts/<repo-slug>/ | grep -i "<topic-keyword>"
```

If matches found, add their filenames to `related_saves:`.

## After saving

1. Print the absolute path of the saved file.
2. Print a 2-3 line summary of what was captured (how many decisions, findings, open items).
3. Do **not** commit the file — it lives outside the repo.
4. Mention that `/context-restore` can reload this later.

## When NOT to save

- Trivial sessions (one quick question, no investigation).
- User explicitly said "don't save" or "ephemeral".
- Session only involved reading docs or answering questions with no decisions/findings.

## Edge cases

- **Multiple worktrees for same repo**: repo-slug uses the worktree's absolute path, so `/Users/toale/Developer/iris` and `/Users/toale/Developer/iris-worktree-1` get separate slugs. Mention this if the user works with worktrees.
- **No git repo**: Use the working directory path as the slug. Note in the save that it's not a git repo.
- **Sensitive content**: If the session involved credentials, tokens, or other secrets — do NOT include them in the save. Note their existence without the values.
