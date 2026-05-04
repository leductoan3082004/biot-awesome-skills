---
name: context-restore
description: Find and load previously saved session context for the current repo (or any repo), then resume work where it left off. Searches ~/.claude/contexts/ by branch, topic, tags, Jira ticket, or date range. Can merge multiple related saves into a unified resume briefing. Use when user says "restore context", "where were we", "resume <topic>", "load my last session", "what was I working on", "/context-restore", or starts a session referencing prior work without full context. Also trigger when user switches to a branch and seems to need context about prior work on it.
---

# context-restore

Loads one or more saved contexts and reconstructs the prior session's state so work can continue without the user having to re-explain everything.

## Storage location

Saves live at:
```
~/.claude/contexts/<repo-slug>/*.md
```

Where `<repo-slug>` is the repo's absolute path with `/` replaced by `-` (leading `-` stripped). Compute it from `git rev-parse --show-toplevel` (or `pwd` if not a git repo).

## First steps on invocation

1. Compute repo-slug for current directory.
2. Check if `~/.claude/contexts/<repo-slug>/` exists and has files.
3. If missing or empty: tell user no saved context exists for this repo. List sibling repo-slugs under `~/.claude/contexts/` in case they're in the wrong directory. Stop.
4. If files exist: proceed to search.

## Search strategy

Match based on whatever signal the user provides. Combine signals when multiple are available.

| User signal | How to match |
|---|---|
| Explicit filename | Load directly |
| Topic / feature name | `grep -ril "<keyword>" ~/.claude/contexts/<repo-slug>/` across topic, tags, title, body |
| Jira ticket (RMS-####) | `grep -rl "RMS-####" ~/.claude/contexts/<repo-slug>/` |
| Branch name | `grep -rl "<branch>" ~/.claude/contexts/<repo-slug>/` |
| "last" / "most recent" | Sort by filename (timestamp-prefixed), take newest |
| "yesterday" / date hint | Filter by timestamp in filename |
| PR number / URL | `grep -rl "PR-URL-or-number" ~/.claude/contexts/<repo-slug>/` |
| Nothing specific | List newest 5-10 saves with topic + date, ask user to pick |

**Auto-detect**: Always check the **current branch** (`git branch --show-current`). If saves exist for it, surface those even if user didn't ask — they're almost always relevant.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SLUG=$(echo "$REPO_ROOT" | sed 's|^/||; s|/|-|g')
BRANCH=$(git branch --show-current 2>/dev/null)
CONTEXT_DIR="$HOME/.claude/contexts/$SLUG"

# List all saves, newest first
ls -1t "$CONTEXT_DIR/" 2>/dev/null

# Search by branch
grep -rl "branch: .*$BRANCH" "$CONTEXT_DIR/" 2>/dev/null

# Search by keyword
grep -ril "<keyword>" "$CONTEXT_DIR/" 2>/dev/null
```

## Multi-save merging

A single task often spans several saves (checkpoints over hours or days). When multiple saves match:

1. Walk `related_saves:` chains in frontmatter to find the full set.
2. Also check for saves with matching branch or topic that weren't explicitly linked.
3. Order by `saved_at` ascending (chronological).
4. Build a unified briefing:
   - **Goal** from the latest save (most current understanding of what we're doing).
   - **Decisions** from all saves, deduplicated, in chronological order. If one save reversed an earlier decision, note that explicitly ("Originally chose X, later switched to Y because...").
   - **Investigation findings** unioned across all saves. Remove entries that were superseded.
   - **Open questions** from the latest save only (older ones likely resolved by subsequent sessions).
   - **Timeline** — short chronological list: "on <date>: <what happened>" pulled from each save.

If saves **contradict** each other (e.g. branch differs, decision reversed without explanation), surface the conflict to the user. Don't silently merge.

## Verifying freshness

Saved context is a snapshot — the repo may have moved since the save. **Before acting on restored content**, verify current state:

```bash
git branch --show-current
git log -5 --oneline
git status --short
```

Check:
- **Branch match**: Still on the saved branch? If not, tell user and ask whether to switch or proceed.
- **New commits**: Have commits landed since the save? Show the delta. New commits might resolve some open questions or invalidate some findings.
- **Working tree**: Does uncommitted state match? Note any divergence.
- **File existence**: For any specific file:line referenced in the save, confirm the file still exists before recommending action on it. Code changes between saves.

**Do not silently checkout a branch.** Branch switches can lose uncommitted work. Always ask first.

## Briefing format

After loading, present a concise resume briefing — don't dump raw save content. Structure it so the user can get oriented in 30 seconds:

```
**Resumed: <topic>** (saved <relative time ago>, branch `<branch>`)

**Goal:** <1-2 sentences>

**Where we left off:**
- <most recent decision or state>
- <last key finding>

**Open items:**
1. <next step from save>
2. <unresolved question>

**Verification:**
- Branch: ✓ matches / ✗ now on `<current>` (saved: `<saved>`)
- New commits since save: <N> — <notable ones if any>
- Working tree: clean / <N> modified files

**Timeline** (if multi-save):
- <date>: <what happened>
- <date>: <what happened>

Ready to continue. Suggest starting with: <concrete next action>
```

Keep it tight. User already has broad context — they need the specific state restored to working memory, not a lecture.

## After restoring

- Hold full save content in conversation context for follow-up reference.
- If multi-save merge: keep the timeline available — user may ask "when did we decide X?".
- Continue from the **Resume hints** / **Open questions** of the latest save.
- If the save references specific files, proactively read the most important 1-2 to have them fresh in context.

## Cross-repo restore

User might want to restore context from a different repo than the current one. Support this:

```bash
# List all repo contexts
ls ~/.claude/contexts/

# Search across all repos
grep -rl "<keyword>" ~/.claude/contexts/*/
```

If the match is in a different repo, tell the user which repo it's from and whether they need to `cd` there first.

## When NOT to restore

- User is starting genuinely new work unrelated to any prior saves. Don't force old context.
- User explicitly says "fresh start" / "ignore history" / "clean slate".
- No saves exist — say so, suggest `/context-save` for future sessions.

## Edge cases

- **Multiple repos with same name** (forks, worktrees): repo-slug uses absolute path so they don't collide. If user sees no saves, suggest `ls ~/.claude/contexts/` to find right slug.
- **Save references a deleted branch**: Warn, show local branches, ask whether to recreate or proceed without checkout.
- **Save references files that no longer exist**: Flag in briefing as "warning: `<path>` referenced in save no longer exists — may have been renamed or deleted".
- **Very old saves**: If save is >30 days old, add a note that findings may be stale. Suggest verifying key facts before acting on them.
- **Corrupted or partial saves**: If YAML frontmatter is broken, still try to parse the markdown body. Mention the parse issue to user.
