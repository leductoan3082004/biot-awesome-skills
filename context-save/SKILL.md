---
name: context-save
description: Use when user wants to checkpoint or persist the current Claude Code session state to disk so it can be resumed later — same session, new session, or different machine. Triggers on "save context", "checkpoint this", "remember where we are", "snapshot the session", "save my progress", "/context-save", or before known interruption points (switching branches, ending session, switching tasks). Captures branch, commits, uncommitted diff, decisions, investigation findings, open questions, and mental model. Stores under ~/.claude/contexts/<repo-slug>/ — never writes inside the working repo. The saved file is exhaustive by design — required fields are required, no shortcuts.
---

# context-save

Persist enough of the current session state that a future session — same person or different agent — can resume the work without re-doing investigation, re-asking the user, or re-discovering decisions.

**Core principle:** A save is a contract with future-you. If a required field is empty, the contract is broken — the resume will fail in subtle ways that look like progress.

**Iron rule:** Never write inside the working repo. Saves go to `~/.claude/contexts/<repo-slug>/`. This isolates session memory from project history, survives branch switches, survives clones, and avoids polluting the user's PRs with planning artifacts.

## Storage Location

```
~/.claude/contexts/<repo-slug>/<timestamp>-<short-topic>.md
```

- `<repo-slug>` = absolute path of the repo with `/` → `-`, leading `-` stripped.
  Example: `/Users/toale/Developer/iris` → `Users-toale-Developer-iris`
- `<timestamp>` = `YYYY-MM-DD-HHMM` in local time
- `<short-topic>` = 2-5 word kebab-case slug of the current task

Compute repo slug from `git rev-parse --show-toplevel`. If the user is not in a git repo, use the cwd absolute path with the same transformation, and note this in the save's frontmatter.

`mkdir -p` the directory. The directory lives in `~/.claude/`, never in the repo. This is non-negotiable — see Red Flags.

## Required Fields (no shortcuts)

A save is incomplete if ANY of these is missing or empty. "Couldn't find" is acceptable when documented; silently skipping is not.

### Frontmatter (machine-readable)
- `saved_at` — ISO 8601 timestamp with timezone offset
- `repo` — absolute path
- `branch` — current branch (or `null` outside git)
- `topic` — one short phrase
- `tags` — list, may be empty `[]`
- `jira` — ticket ID or `null`
- `pr` — PR URL or `null`
- `related_saves` — list of prior save filenames in same `<repo-slug>/` dir on the same topic/branch, may be empty `[]`

### Body sections (human-readable)
- **Goal** — one paragraph: what the user is trying to accomplish and why
- **Branch & commits** — branch name, base/merge-base SHA, last 10 commits, uncommitted file list
- **Decisions** — every choice made and the *why* (not just the *what*). Empty = "no decisions made yet, just exploring" written explicitly.
- **Investigation** — files read, key code locations as `path:line`, patterns discovered. Empty = "no investigation yet" written explicitly.
- **Open questions / next steps** — what is unresolved, what to do first on resume. Empty = no save needed (nothing to resume).
- **Resume hints** — first concrete action on resume + known gotchas

### Conditional (include when relevant)
- **Failed approaches** — what was tried and rejected, with reason
- **Mental model / insights** — non-obvious things learned about the system
- **Related links** — Jira tickets, PR URLs, design docs, Slack threads
- **Pending tool state** — long-running processes, dev servers, agents in flight
- **Key code snippets** — small (<20 line) blocks central to the investigation. Reference larger code by `path:line`, do not dump.

## Gather (before drafting)

Run these in parallel:

```bash
git rev-parse --show-toplevel
git branch --show-current
git status --short
git log -10 --oneline
git diff --stat
git merge-base HEAD master 2>/dev/null || git merge-base HEAD main 2>/dev/null
date '+%Y-%m-%dT%H:%M%z'
```

Pull task / decision / investigation content from the conversation transcript — do not ask the user to repeat themselves. Skim the transcript and extract:
- Every decision or choice point
- Every file read or modified
- Every finding or "aha" moment
- Every question asked but not fully resolved
- Every dead end ruled out

If unsure whether something is worth capturing, include it. Storage is cheap; reconstructing lost context is expensive.

## File Format

```markdown
---
saved_at: 2026-05-05T14:32-07:00
repo: /Users/toale/Developer/iris
branch: toale_axoncorp/RMS-109955-searchable-placeholder-visibility
topic: searchable placeholder card visibility
tags: [iris, form-card, RMS-109955]
jira: RMS-109955
pr: null
related_saves: [2026-05-04-1820-form-card-visibility.md]
---

# Searchable placeholder card visibility

## Goal
<1-paragraph statement of what the user is trying to do and why>

## Branch & commits
- Branch: `<branch>`
- Base: `<merge-base branch>` (`<sha>`)
- Recent commits:
  - `<sha>` <subject>
  - ...
- Uncommitted: <list, or "clean">

## Decisions
- **<decision>** — <why, alternatives considered>
- ...

## Investigation
- `<path:line>` — <what was found / why it matters>
- ...

## Open questions
- <question or next step>
- ...

## Failed approaches
- <approach> — <why rejected>

## Mental model / insights
- <non-obvious thing learned>

## Related links
- [RMS-####](url)

## Resume hints
- Start by: <first concrete action on resume>
- Watch out for: <gotchas>
- Dev environment state: <servers running, agents in flight, etc.>
```

## Linking Related Saves

Before writing, list existing saves in `~/.claude/contexts/<repo-slug>/`. If any prior save matches the current topic, branch, or Jira ticket, include its filename in `related_saves`. This lets `context-restore` reconstruct a timeline rather than treating each save as orphan.

```bash
ls -1 ~/.claude/contexts/<repo-slug>/ 2>/dev/null
grep -l "branch: .*<current-branch>" ~/.claude/contexts/<repo-slug>/*.md 2>/dev/null
grep -l "jira: <ticket>" ~/.claude/contexts/<repo-slug>/*.md 2>/dev/null
```

## Required Save Checklist

Do **not** write the file until ALL of these are true:

- [ ] Repo slug computed from `git rev-parse --show-toplevel` (or documented absolute cwd if not a repo)
- [ ] `~/.claude/contexts/<repo-slug>/` exists (created via `mkdir -p`)
- [ ] Filename uses `<timestamp>-<short-topic>.md` pattern
- [ ] All frontmatter fields populated (`null` allowed only when truly absent, e.g. `pr: null` if no PR exists; placeholders like `<TODO>` are forbidden)
- [ ] Goal paragraph written from conversation context, not from memory of similar sessions
- [ ] Branch & commits captured from real `git` output, not guessed
- [ ] Decisions section either lists decisions with *why*, or explicitly states "no decisions yet, exploration only"
- [ ] Investigation section either lists `path:line` findings, or explicitly states "no investigation yet"
- [ ] Open questions section has at least one concrete next step (otherwise — why save?)
- [ ] Resume hints written for someone who walks in cold
- [ ] Prior saves in same `<repo-slug>/` dir checked for `related_saves` links
- [ ] Path is under `~/.claude/contexts/`, NOT inside the working repo

After writing, **read the file back** and verify the frontmatter parses and required sections are populated. A save you didn't verify is a save you didn't actually save.

## Output to User

After saving:

1. Print the absolute path of the saved file.
2. Print a 2-3 line summary: topic, branch, count of decisions / findings / open items.
3. Mention any related saves linked.
4. Mention that `/context-restore` can reload it.
5. Do not commit the file (it's outside the repo by design).

## Rationalization Table — STOP if You Think These

| Excuse | Reality |
|--------|---------|
| "Session is short, skip the save" | Then user wouldn't have asked. If they invoked context-save, save it. |
| "I'll capture only the highlights" | Future-you doesn't know which detail mattered. Required fields are required. |
| "Decisions are obvious, skip that section" | Obvious to current-you ≠ obvious to next-session-you. Document the why. |
| "Branch state is in git anyway, skip" | Save makes the snapshot atomic with the reasoning. Without it, restore can't know which commit the reasoning matched. |
| "I'll write this directly into a doc in the repo" | No. Saves go to `~/.claude/contexts/`. Writing inside the repo pollutes PRs and history. |
| "git status takes time, just paraphrase" | Paraphrase ≠ truth. Run the command. Cost: 1 second. |
| "Open questions is just my todo list, skip" | The todo list IS the resume value. Without it, resume = re-derive what to do next from scratch. |
| "Existing save is recent enough, no need" | A new save with `related_saves` link to the old one is cheap and lossless. Make a new one. |
| "User said 'quick save', skip required fields" | "Quick save" = save without delay, not save with skipped fields. The fields are the contract. |
| "Failed approaches don't matter once we move on" | They prevent next-session-you from re-trying them. Document them. |
| "I read the file back? Trust the write" | File systems lie sometimes (perms, full disk, wrong path). Read back. |
| "Investigation findings are too granular, summarize" | `path:line` references are the highest-value content for resume. Preserve them. |

## Red Flags — STOP and Restart

| Red flag | What to do |
|----------|-----------|
| About to write inside the working repo | Stop. Path must be under `~/.claude/contexts/`. Re-derive. |
| Frontmatter has placeholder values like `<TODO>` or `???` | Stop. Either fill in or mark explicitly null. No placeholders ship. |
| Decisions / Investigation sections empty without "(none)" note | Stop. Either populate or document the empty explicitly. |
| Skipped `git status` / `git log` because "I remember" | Stop. Run the commands. Memory of git state is unreliable. |
| Filename collision with existing save | Don't overwrite. Append `-2`, `-3` to topic, OR check if it's a duplicate-save attempt and ask the user. |
| Path under `~/.claude/contexts/` doesn't yet exist | `mkdir -p` first. Don't fail silently. |
| User in a non-git directory | Use cwd absolute path as repo-slug, document this in frontmatter. Do not abort. |
| `related_saves` is empty but a prior save on same branch / Jira clearly exists | Stop. List the contexts dir, find the link, populate. |
| Sensitive content (tokens, credentials, PII) about to be written | Stop. Reference its existence without value. Ask user before persisting. |

## When NOT to Use This Skill

- Trivial sessions (one quick question, no investigation, nothing to resume).
- User explicitly said "don't save" / "ephemeral".
- The user asked for documentation IN the repo (they want a real doc, not a session save) — point them at the right place; do not save here.
- Sensitive content the user marked private — flag and ask before persisting.

## Edge Cases

- **Multiple worktrees of the same repo**: repo-slug uses the worktree's absolute path, so `/Users/toale/Developer/iris` and `/Users/toale/Developer/iris-worktree-1` get separate slugs. Mention this if relevant.
- **No git repo**: Use cwd absolute path as the slug. Note `branch: null` and `repo` set to cwd in frontmatter.
- **Sensitive content in conversation**: do not include credentials, tokens, or other secrets in the save. Note their existence ("API key handled in step 3") without the value.
- **Filename collision**: do not overwrite. Append `-2`, `-3` to topic slug, or check if duplicate save attempt and ask user.

## Related Skills

- **context-restore** — The other half. Reads what this skill writes, reconstructs session state.
- **deep-understand** — Saves are exactly the right place to checkpoint deep-understand findings during long investigations. The Search Ledger and decision table belong in the Investigation and Decisions sections.
