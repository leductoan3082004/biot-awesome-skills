---
name: context-restore
description: Use when user wants to resume work from a previously saved Claude Code session, recover state from a prior save, or pick up where they left off. Triggers on "restore context", "where were we", "resume <topic>", "load my last session", "pick up where I left off", "what was I working on", "/context-restore", or when the user begins a session referencing prior work without restating it. Searches ~/.claude/contexts/<repo-slug>/ exhaustively — no shortcutting to "newest only" — walks related_saves chains, merges multi-save timelines, verifies the saved branch/commits/files still exist, and only then produces a resume briefing. Branch checkouts and tree mutations are never silent.
---

# context-restore

Find one or more saved contexts for the current repo, validate them against the live tree, merge them if they form a chain, and produce a resume briefing the user can act on.

**Core principle:** A save is a snapshot — the world has moved since. The skill's job is not to read a file and dump it; it is to reconstruct a working state by reconciling the saved context with what the repo looks like *now*, and to surface every divergence to the user before they act on stale assumptions.

**Iron rule:** Never silently checkout a branch, never silently apply diffs, never silently overwrite a working state. Branch switches and tree mutations are destructive and require explicit user confirmation.

## Storage Location

Saves live at `~/.claude/contexts/<repo-slug>/*.md` where `<repo-slug>` is the current repo's absolute path with `/` → `-` (leading `-` stripped). Compute it from `git rev-parse --show-toplevel`.

If the directory does not exist or is empty:
1. Tell the user no saved context exists for this repo.
2. List sibling repo-slugs under `~/.claude/contexts/` (in case the user is in the wrong cwd or worktree).
3. Stop. Do not invent context. Do not "find something close" from a different repo without explicit user direction.

## Phase 1: Locate Candidates — Exhaustive

Match what the user asked for. Combine signals — do not pick one and ignore the rest.

| User signal | How to match |
|---|---|
| Explicit filename | Load that file directly, AND check its `related_saves` chain |
| Topic / feature name | grep across `topic:`, `tags:`, title, body |
| Jira ticket (RMS-####) | grep `jira:` field and body |
| Branch name | grep `branch:` field |
| "last", "most recent" | sort by `saved_at` desc, candidates = top N where saved_at within last 7 days |
| "yesterday", date hint | filter by `saved_at` |
| PR number / URL | grep `pr:` field and body |
| Nothing specific | List newest 5-10 with topic + saved_at, ask user to pick |

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SLUG=$(echo "$REPO_ROOT" | sed 's|^/||; s|/|-|g')
BRANCH=$(git branch --show-current 2>/dev/null)
DIR="$HOME/.claude/contexts/$SLUG"

ls -1t "$DIR/" 2>/dev/null
grep -l "branch: .*$BRANCH" "$DIR"/*.md 2>/dev/null
grep -ril "<keyword>" "$DIR/" 2>/dev/null
```

**Always also check the current branch.** Run `git branch --show-current`, then grep saves for that branch. If matches exist, surface them even if the user did not ask — they are almost always relevant.

### Hard rule: read every candidate fully

Candidates are not "the newest one". Candidates are **every save** that matched any of the signals above. Read every candidate file fully — frontmatter and body — before forming a briefing. Newest does not necessarily contain the deepest context; sometimes a 3-day-old save has the decision rationale and the newest save just has "next step".

If candidate count is high (>10), tell the user, show topic + saved_at + tags for each, ask which subset to load. Do not silently pick a subset for them.

## Phase 2: Walk the related_saves Chain

For each candidate, follow `related_saves:` recursively until fixed point (no unread file referenced). The chain reconstructs the work timeline.

```
candidate → related_saves: [A, B] → A.related_saves: [C] → ...
```

Read every file in the chain. Stop only when every referenced filename has been loaded.

### Hard rule: chain must be closed

Phase 3 (Verification) is **blocked** until the chain is closed — every `related_saves` reference resolved to a read file or documented as missing (file referenced but not present in `~/.claude/contexts/<repo-slug>/`). If a referenced save is missing, surface that to the user — it may have been deleted, moved, or renamed.

## Phase 3: Verify Against Live Tree

A saved context is a snapshot. Before recommending action on it, verify the world has not moved out from under it.

Run these:

```bash
git rev-parse --show-toplevel        # confirm correct repo
git branch --show-current             # current branch
git status --short                    # uncommitted state
git log -10 --oneline                 # recent commits
```

For the **latest save in the chain**, compare:

| Saved | Live | If diverged |
|-------|------|-------------|
| `branch` | current branch | Note divergence. Do not auto-checkout. Ask user. |
| Last commit SHA in save | `git log -1 --format=%H` | Show count of new commits since save. List subjects if ≤10. |
| Uncommitted files in save | `git status --short` | Show diff between saved set and live set. |

For every `path:line` reference in the save's Investigation section, verify the file still exists at that path. For each missing file, mark in the briefing: `⚠ <path> referenced in save no longer exists — possibly renamed, deleted, or moved`.

For every `path:line` that exists, sanity-check that the file is at least `line` long. Code rots between saves; deep verification of every line is excessive, but a file-existence + size check is required.

### Hard rule: never silently checkout

If the saved branch differs from the current branch:
1. Tell the user: "Saved branch was `<saved>`, you are on `<current>`."
2. Show the divergence (`git log <saved>..<current>` or vice versa).
3. Ask whether to switch branches, work without switching, or abort.
4. **Never run `git checkout` without explicit user confirmation.** Branch switches can lose uncommitted work.

If the saved branch no longer exists locally:
1. Tell the user.
2. Check if it exists on remote (`git branch -r | grep <branch>`).
3. Ask whether to fetch/recreate or proceed without it.

If commits referenced in the save are no longer in branch history (force-push, rebase, branch deletion):
1. Surface explicitly. The reasoning in the save may not apply to the current commit.
2. Suggest `git reflog` to locate the original commits if needed.

## Phase 4: Multi-Save Merge (if chain has >1 save)

When the chain has multiple saves, build a unified briefing — do not just read out the newest.

1. Order saves by `saved_at` ascending (oldest first).
2. **Goal**: take from the latest save (most current understanding).
3. **Decisions**: union across all saves, deduped, in chronological order. Note when a later save reverses an earlier decision — surface the reversal explicitly.
4. **Investigation**: union, with the source save annotated for each finding. Drop entries that were superseded.
5. **Open questions**: take from the latest save only (older ones are presumed resolved unless still appearing in the latest).
6. **Failed approaches**: union across all saves — these stay relevant indefinitely.
7. **Timeline**: short list of `<date>: <one-line summary>` pulled from each save's topic + goal. Gives the user a sense of how the work evolved.

If saves contradict each other (different branch, conflicting decisions, inconsistent investigation findings), surface the conflict to the user — do not silently pick one. The conflict itself is a finding.

## Phase 5: Briefing Preconditions

Do not emit a briefing until all are true:

- [ ] Phase 1 candidate set built from at least 2 signals (current branch always one of them, when the user is in a git repo)
- [ ] Phase 2 related_saves chain closed for every candidate
- [ ] Every candidate file read fully (not just frontmatter, not just summary)
- [ ] Phase 3 verification run: branch, recent commits, uncommitted state, file existence for every `path:line` reference
- [ ] Phase 4 merge produced (if chain has >1 save)
- [ ] Conflicts between saves explicitly identified or absence of conflicts confirmed
- [ ] No branch checkout has been performed without user confirmation
- [ ] No file has been modified

Skipping any precondition produces a briefing that points at stale state, and the user acts on stale assumptions. That is worse than no restore.

## Phase 6: Briefing Format

Concise. Not a dump. The user has the broad context — they just need their working state restored to active memory.

```
**Resumed: <topic>** (saved <relative time>, branch `<saved-branch>`)
Loaded <N> saves from chain (<oldest-date> → <newest-date>).

**Goal:** <1-2 lines>

**Where we left off:**
- <last decision / state>
- <last investigation finding>
- <last completed step>

**Open:**
- <next concrete step>
- <unresolved question>

**Verification:**
- Branch: ✓ on saved branch / ✗ on `<current>` (saved was `<saved>`)
- New commits since latest save: <N> [list 1-line subjects if ≤5, summary if more]
- Uncommitted: matches save / diverged: <details>
- Files referenced: <N> intact / <N> missing [list missing]

**Conflicts** (if multi-save):
- <date>: decided X. <date>: reversed to Y. Currently: Y.

**Timeline** (if multi-save):
- <date>: <one-line>
- <date>: <one-line>

Ready to continue. <Suggested first action OR explicit question if branch/state diverged>
```

After the briefing, hold the full save content (including older saves in the chain) in conversation context — the user may follow up with "wait, when did we decide X?".

If the save references specific files that are central to the work, proactively read the most important 1-2 to have them fresh in context. Do not read all referenced files (could be many) — pick by relevance to the next step.

## Cross-Repo Restore

User may want to restore from a different repo than the current one. Support this:

```bash
# List all repo contexts
ls ~/.claude/contexts/

# Search across all repos
grep -rl "<keyword>" ~/.claude/contexts/*/
```

If the match is in a different repo, tell the user which repo it belongs to, and whether they need to `cd` there before resuming code work.

## Rationalization Table — STOP if You Think These

| Excuse | Reality |
|--------|---------|
| "Newest save is enough, skip the chain" | Newest save's `related_saves` exists for a reason. The earlier saves contain the *why* the latest save assumes. Read them. |
| "User just said 'restore', any save works" | Wrong save = wrong briefing. If signals are ambiguous, ask. |
| "Skip verification — repo is probably the same" | "Probably" is exactly when stale assumptions cost time. Run the verifications. |
| "I'll auto-checkout the saved branch, that's what they want" | No. Checkout is destructive. Always ask. |
| "Save says file X is at path Y, just trust it" | Code rots. Verify path Y still exists before referencing it in the briefing. |
| "Conflicts between saves are confusing — pick the most recent" | Silently picking = lying about the work history. Surface the conflict; let user decide. |
| "Briefing is taking too long, just dump the latest save" | Dump ≠ briefing. The user can read the file themselves. The skill's value is reconciliation. |
| "Empty result — no saves match — invent something close" | No. Empty result is a real result. Tell the user, list available repo-slugs, stop. |
| "User is in a hurry, skip the verification phase" | Stale state acted on in a hurry breaks more than verification took. Verify. |
| "Investigation section is long, summarize" | Future-you needs the specifics. Preserve `path:line` references in the briefing or in held context. |
| "Latest save said decision X — use it" | If an earlier save said NOT X and was reversed, surface the reversal. The user may want to revisit. |
| "Skip checking sibling repo-slugs if dir is empty" | User may be in wrong worktree. Listing siblings takes 1 second. Do it. |
| "I'll silently load the file the user named, skip chain walk" | User named one file; the chain may extend to others they don't remember. Walk it. |
| "Chain has 5 saves, just read the newest 2" | Chain length is not a reason to truncate. Read all. The skipped saves contain the assumptions you'll silently violate. |

## Red Flags — STOP and Restart

| Red flag | What to do |
|----------|-----------|
| About to run `git checkout` without user confirmation | Stop. Ask first. Always. |
| Skipping verification because "the save is recent" | Stop. Recent ≠ unchanged. Run the checks. |
| Briefing emitted before chain is closed | Stop. Walk every `related_saves` ref. |
| Selected one of many candidates without telling user | Stop. Show the list. Let user pick. |
| Save references a file that no longer exists, briefing doesn't mention it | Stop. Add the warning. |
| Save references branch that doesn't exist locally, no warning | Stop. Check remote, ask user. |
| Multi-save merge that silently picks one save's decision over another | Stop. Surface the conflict. |
| Skipped reading older saves in chain because "newest is enough" | Stop. Read them all. The chain exists for a reason. |
| Modified any file or git state during restore | Stop. Restore is read-only by default. Reverse the change, ask user. |
| Save older than 30 days, briefing presented as authoritative | Add staleness warning. Suggest re-verifying key facts. |

## When NOT to Use This Skill

- The user is starting genuinely new work unrelated to any prior save — do not force-fit.
- No saves exist for this repo — say so, suggest using `context-save` going forward.
- User explicitly said "fresh start" / "ignore history" / "clean slate" — respect that.
- User is in a different repo than the saves are for — confirm before loading from sibling slugs.

## Edge Cases

- **Multiple repos with the same name** (e.g., two clones, fork + upstream): repo-slug uses absolute path so they don't collide. If the user is in the wrong worktree, they will see no saves — suggest `ls ~/.claude/contexts/` to find the right slug.
- **Save references a branch that no longer exists**: warn, list local branches, check remote, ask whether to fetch/recreate or proceed without checkout.
- **Save references a deleted file**: surface in briefing as `⚠ <path> referenced in save no longer exists`. Suggest `git log --diff-filter=D -- <path>` to find when it was removed.
- **Save's commits no longer in branch history** (force-push, rebase): surface explicitly. Suggest `git reflog` to locate originals if needed.
- **`related_saves` references a missing file**: note as `⚠ chain reference <filename> not found in contexts dir`. Continue with available saves.
- **Frontmatter parse error**: do not silently skip the save. Tell the user the file is malformed, show the offending file, ask how to handle. Try to parse the markdown body separately.
- **Very old saves (>30 days)**: add a staleness warning to the briefing. Suggest verifying key facts before acting on them.

## Related Skills

- **context-save** — The other half. Writes the files this skill reads.
- **deep-understand** — Restored saves often contain partial Search Ledgers from a prior deep-understand session. Treat the ledger as resumable: continue searching the unattempted rows, do not start over.
