---
name: context-save
description: |
  Use when the user has finished a meaningful unit of work (code edit,
  decision, bug fix, completed investigation, validated behavior,
  refactor phase, stopping point before a switch, discovered blocker)
  AND you need to persist a structured snapshot a future agent can
  resume from. Also use when the user says "save progress", "save
  state", "save my work", "context save", or "/context-save".
  Writes a timestamped snapshot folder (v3 layout) with sibling files
  for context / decisions / progress / results / optional artifacts.
  Topic identity carries across branches and commits.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

# /context-save — Structured Topic-Snapshot Save (v3)

You are a Staff Engineer producing a structured, machine-friendly
snapshot of the current workstream. **One folder per save.** Sibling
files separate distinct concerns. The whole snapshot is self-contained
so a fresh agent can route to it and resume work without loss.

**HARD GATE:** No code changes. Snapshot only.

**HARD GATE:** Do NOT skip topic-match (Step 4). Creating a new
snapshot folder without first checking whether the current session
continues an existing topic fragments the same workstream across
multiple topic slugs — the failure this skill exists to prevent.

**HARD GATE:** Every snapshot is self-contained. All files belonging
to a snapshot live INSIDE its folder. Never write snapshot material
outside its folder.

---

## What changed vs prior versions

| Era | Layout | Why obsolete |
|-----|--------|--------------|
| gstack `/context-save` | one timestamped `.md` per save | restore loaded newest; older saves lost |
| rolling v1 (branch-keyed) | `CURRENT-<branch>.md` | branch-hopping fragmented the workstream |
| rolling v2 (topic-keyed file) | `CURRENT-<topic>.md` | one giant file; no decision/progress/results separation; no per-save history |
| **rolling v3 — this version** | `YYYY-MM-DD_HHMMSS-<topic-slug>/{context.md, DECISIONS.md, PROGRESS.md, RESULTS.md, artifacts/}` | per-save snapshot folders; structured siblings; full history preserved as separate folders; fast routing via `context.md` frontmatter |

Each save creates a NEW timestamped folder. The folder name embeds
the topic slug. Restore groups folders by topic slug and picks the
latest folder per topic.

---

## Folder layout (canonical)

**Single global checkpoint dir.** All topic snapshots from all projects /
working directories live side-by-side under one path — no per-project
segregation. Topic-slug uniqueness is the agent's responsibility (pick
slugs descriptive enough to not collide across unrelated workstreams).

```
~/.claude/projects/checkpoints/
  2026-05-20_143022-auth-middleware-refactor/
    context.md          # routing + summary, ≤500 lines
    DECISIONS.md        # full decision log (carry-forward + new)
    PROGRESS.md         # done / in-progress / open / blocked + session log
    RESULTS.md          # test outputs, validations, command results
    artifacts/          # OPTIONAL, free-form
      logs/             # long command outputs
      patches/          # diffs/intermediate patches
      research/         # external research, saved web pages
      snapshots/        # screenshots, design mocks
```

## Folder naming

`YYYY-MM-DD_HHMMSS-<topic-slug>`

- ISO date prefix → chronologically sortable with plain `ls -r`
- Underscore separator → parseable with `cut -d_`
- `<topic-slug>`: lowercase, alnum + hyphen only, ≤60 chars
- Same topic across multiple saves → same slug, different timestamp prefixes

Robustness:
- Repeated saves of the same topic create new sibling folders. The folder name conflict is impossible at second-resolution unless two saves fire in the same second — collision-safe suffix appended if so.
- Old snapshots are NEVER overwritten or deleted; the latest snapshot is the "current state" but every prior snapshot remains queryable.

## `context.md` — frontmatter (mandatory)

```yaml
---
schema: context-save/v3
topic: <topic-slug>                       # stable identity across snapshots
title: <stable human title>               # changes only on workstream pivot
summary: "<single line ≤200 chars; what this workstream is about; restore scans this line>"
keywords: [<3-7 routing tokens>]          # primary noun, sub-feature, verb of intent
created: <ISO-8601, snapshot folder creation>
last_updated: <ISO-8601, same as created on new snapshot>
session_number: <N>                       # parent.session_number + 1, or 1 if new topic
project_slug: <informational only — origin working dir slug; not used for routing>
repo_path: <absolute path to repo>
current_branch: <branch or empty>
head_commit: <7-char commit or empty>
related_branches: [<union from parent + current>]
related_commits: [<union from parent + current, cap last 50>]
parent_snapshot: <folder basename of prior snapshot, or empty>
status: in-progress | resolved | abandoned
---
```

## `context.md` — body (mandatory, ≤500 lines)

Fixed section order. The body must stay under 500 lines; push detail
into siblings if it grows.

```markdown
# <title>

> **Summary:** <verbatim mirror of frontmatter summary>

## Topic identity
<1-3 sentences: what this workstream is about, why it exists, definition of done>

## Quick state
- Branch: <current_branch>
- Commit: <head_commit>
- Session: <N>
- Status: <in-progress | resolved | abandoned>
- Last updated: <last_updated>

## What's in this snapshot
- `DECISIONS.md` — <count> decisions
- `PROGRESS.md` — <X done / Y open / Z blocked>
- `RESULTS.md` — <K validation entries>
- `artifacts/` — <present | empty>

## Active decisions (top 5)
- <one-line decision> — *(session K)*
- ...
*(See `DECISIONS.md` for the full log including superseded ones.)*

## Open work (top 5)
- <one-line item> — *(opened session J)*
- ...
*(See `PROGRESS.md` for the full backlog.)*

## Recently resolved (top 5)
- ~~<item>~~ `[done session K]` — <date>
- ...

## Notable gotchas / constraints
- <one-line gotcha future-you needs before resuming>
- ...

## How to resume
1. <concrete next action>
2. <concrete next action>
3. ...

## Routing hints
- **Matches if your task involves:** <comma list from keywords + summary>
- **Does NOT match if your task involves:** <one-line anti-keywords>
- **Adjacent topics:** <folder names of related snapshots, or "none">
```

`context.md` is **for routing + orientation**, not exhaustive detail.
Hard cap: **500 lines**. Step 7c enforces it.

## `DECISIONS.md`

```markdown
# Decisions — <title>

## Session <N> (<date>)
- <new decision>. **Why:** <reason>. **Tradeoff:** <what we gave up>.
- ~~<old decision>~~ → <replacement>. Superseded this session because <reason>.

## Session <N-1> (<date>)
- <prior decision> ... (carried forward verbatim from parent)
```

Newest session first. Carry-forward verbatim from parent; supersession
marks decisions with strike-through, never deletes.

## `PROGRESS.md`

```markdown
# Progress — <title>

## Done
- `[done session K, <date>]` <item>

## In progress
- <item> — started session J

## Open / next steps
- <item> — opened session J

## Blocked
- <item> — blocker: <reason>, since session K

## Session log

| # | Date       | Branch    | Commit | One-line summary             |
|---|------------|-----------|--------|------------------------------|
| N | YYYY-MM-DD | <branch>  | <sha>  | <this session>               |
| ...prior rows preserved from parent...                              |
```

## `RESULTS.md`

```markdown
# Results — <title>

## Session <N> (<date>)

### <validation name>
- Command: `<exact command>`
- Output (head):
  ```
  <≤20 lines>
  ```
- Verdict: pass | fail | inconclusive
- Full output: `artifacts/logs/<filename>` (if long)

## Session <N-1> (<date>)
... (carried forward)
```

## `artifacts/` (optional)

Free-form. Use when content is too long, too binary, or too specialized
for inline. Common subfolders: `logs/`, `patches/`, `research/`,
`snapshots/`. Everything inside `artifacts/` is referenced from one of
the sibling `.md` files so it's discoverable.

---

## Detect command

- `/context-save` or `/context-save <title>` → **Save**
- `/context-save list` → **List snapshot folders grouped by topic**
- `/context-save merge <topic-a> <topic-b>` → **Manual topic merge** (when two slugs cover the same workstream)
- `/context-save resume` or `restore` → tell user "Use `/context-restore`". Exit.

---

## Save flow

### Step 1: Resolve paths + gather state

`CHECKPOINT_DIR` is fixed and global — same path for every project. `SLUG`
is still captured as informational metadata (origin working dir) but is
NOT part of the storage path.

```bash
CHECKPOINT_DIR=~/.claude/projects/checkpoints
mkdir -p "$CHECKPOINT_DIR"

eval "$(~/.claude/skills/gstack/bin/gstack-slug 2>/dev/null)" 2>/dev/null || SLUG=$(basename "$PWD")
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
HEAD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "")
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
NOW_FOLDER=$(date +"%Y-%m-%d_%H%M%S")
REPO_PATH=$(pwd -P)

echo "CHECKPOINT_DIR=$CHECKPOINT_DIR  # global, shared across all projects"
echo "SLUG=$SLUG  # informational only"
echo "CURRENT_BRANCH=$CURRENT_BRANCH"
echo "HEAD_COMMIT=$HEAD_COMMIT"
echo "NOW_ISO=$NOW_ISO"
echo "NOW_FOLDER=$NOW_FOLDER"
echo "REPO_PATH=$REPO_PATH"

git status --short 2>/dev/null
git diff --stat 2>/dev/null
git diff --cached --stat 2>/dev/null
git log --oneline -10 2>/dev/null
```

### Step 2: Infer this session's topic + summary + keywords

From the conversation up to this point, infer:

- **session_topic_title** — short, stable, goal-oriented (e.g. "auth middleware refactor"). NOT branch-derived. Robust to renames.
- **session_topic_slug** — lowercase-kebab, ≤60 chars, alnum + hyphen only.
- **session_summary** — single line ≤200 chars. Plain English. Stable across sessions. Written so a future agent skimming only this line can decide "is this relevant to my new task?". Avoid branch names, SHAs, ticket IDs, jargon.
- **session_keywords** — 3-7 routing tokens: primary domain noun, sub-feature noun, verb of intent, related-tech, ticket-id-if-any.
- **session_goal** — 1-3 sentences for `## Topic identity`.
- **session_decisions** — architectural choices this session, with reasons + tradeoffs.
- **session_resolved** — items that closed this session.
- **session_open** — items still open / next steps.
- **session_blocked** — items blocked, with blocker reason.
- **session_gotchas** — notes future-you needs.
- **session_files** — files modified this session.
- **session_results** — list of `{name, command, output_head, verdict}` entries.

### Step 3: Enumerate prior snapshot folders + group by topic

```bash
# Build "topic|folder|last_updated|status|title|summary|keywords|branches|abs_path" per snapshot folder.
> /tmp/all-snapshots.txt
for d in $(find "$CHECKPOINT_DIR" -mindepth 1 -maxdepth 1 -type d -name "20*-*" 2>/dev/null); do
  CTX="$d/context.md"
  [ -f "$CTX" ] || continue
  T=$(grep -m1 '^topic:' "$CTX" | sed 's/topic: *//')
  TITLE=$(grep -m1 '^title:' "$CTX" | sed 's/title: *//')
  SUM=$(grep -m1 '^summary:' "$CTX" | sed 's/summary: *//' | sed 's/^"//; s/"$//')
  LU=$(grep -m1 '^last_updated:' "$CTX" | sed 's/last_updated: *//')
  KEYS=$(grep -m1 '^keywords:' "$CTX" | sed 's/keywords: *//')
  STATUS=$(grep -m1 '^status:' "$CTX" | sed 's/status: *//')
  RB=$(awk '/^related_branches:/{flag=1; next} flag && /^[a-z_]+:/{flag=0} flag' "$CTX" | grep '^  - ' | sed 's/^  - //' | tr '\n' ',' | sed 's/,$//')
  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s\n' "$T" "$(basename "$d")" "$LU" "$STATUS" "$TITLE" "$SUM" "$KEYS" "$RB" "$d" >> /tmp/all-snapshots.txt
done

# Latest snapshot per topic (lexicographic sort on folder name = chrono sort).
sort -t'|' -k1,1 -k2,2r /tmp/all-snapshots.txt | awk -F'|' '!seen[$1]++' > /tmp/latest-per-topic.txt

echo "--- ALL SNAPSHOTS ---"
sort -t'|' -k2,2r /tmp/all-snapshots.txt
echo "--- LATEST PER TOPIC (matching candidates) ---"
cat /tmp/latest-per-topic.txt
```

Also enumerate legacy v2 files (`CURRENT-<topic>.md`) for backward-compatible parenting:

```bash
> /tmp/legacy-v2.txt
for f in $(find "$CHECKPOINT_DIR" -maxdepth 1 -name "CURRENT-*.md" -type f 2>/dev/null); do
  T=$(grep -m1 '^topic:' "$f" | sed 's/topic: *//')
  TITLE=$(grep -m1 '^# CURRENT:' "$f" | sed 's/^# CURRENT: *//')
  SUM=$(grep -m1 '^summary:' "$f" | sed 's/summary: *//' | sed 's/^"//; s/"$//')
  LU=$(grep -m1 '^last_updated:' "$f" | sed 's/last_updated: *//')
  RB=$(awk '/^related_branches:/{flag=1; next} flag && /^[a-z_]+:/{flag=0} flag' "$f" | grep '^  - ' | sed 's/^  - //' | tr '\n' ',' | sed 's/,$//')
  printf 'legacy_v2|%s|%s|%s|%s|%s|%s\n' "$T" "$f" "$LU" "$TITLE" "$SUM" "$RB" >> /tmp/legacy-v2.txt
done
echo "--- LEGACY V2 FILES (still considered for parenting) ---"
cat /tmp/legacy-v2.txt
```

If both lists are empty → `MATCH_MODE=new_topic`, skip to Step 5.

### Step 4: Topic-match decision

Compare current session against each candidate (latest v3 folder per
topic + each legacy v2 file). For each candidate, score four signals:

- **Title overlap** — does `session_topic_title` describe the same workstream as the candidate's `title:` / `# CURRENT: <title>`?
  - **Strong**: verbatim / near-prefix / paraphrase of the same workstream.
  - **Weak**: a single common noun shared (e.g. "auth") but modifiers diverge.
- **Goal overlap** — does the candidate's `## Topic identity` (or v2 `## Goal`) cover the same problem this session is working on?
  - **Strong**: same problem statement; this session plausibly continues the same workstream.
  - **Weak**: same domain / subsystem, different problem.
- **File-path overlap** — `session_files` vs candidate's modified files (from PROGRESS.md session log or v2 cumulative).
  - **Strong**: ≥1 exact path match, OR ≥2 share a non-trivial directory prefix.
  - **Weak**: only top-level dir matches.
- **Branch/commit overlap** — `CURRENT_BRANCH` or `HEAD_COMMIT` in candidate's `related_branches` / `related_commits` as **exact string match** (no prefix, no substring).
  - **Strong**: exact match.
  - **Weak**: no exact match. Visual similarity = zero signal.
- **Keyword overlap** (v3 only) — `session_keywords` ∩ candidate `keywords:`.
  - **Strong**: ≥2 keyword matches.
  - **Weak**: 1 keyword match.

Decide:

| Outcome | When | Action |
|---------|------|--------|
| `MATCH_MODE=clear_match` | Exactly one candidate has **strong title AND strong goal**, OR exact branch/commit match. Independent paths — either suffices. | Save into new folder with that candidate's `topic` slug; that candidate becomes `parent_snapshot`. |
| `MATCH_MODE=ambiguous_match` | 2+ candidates with strong overlap, OR 1 candidate with mixed strong+weak signals, OR signals contradict each other. | AskUserQuestion. List candidates + summaries; offer "New topic" as an option. |
| `MATCH_MODE=new_topic` | No candidate has strong overlap on title OR goal OR exact branch/commit. Single shared common noun is NOT ambiguous. | Create new folder with new topic slug. No parent. |

Bias rules:
- **Bias toward clear_match.** Branch-hop / commit-hop is normal; same workstream stays in same topic.
- **Bias against silent merge into wrong topic.** Uncertain → ambiguous, not silent.
- **Single-word noun coincidence is not ambiguous.** `new_topic`, with a note in the answer if the user wants to reconsider.

For `ambiguous_match` AskUserQuestion shape:

```
Topic match for this session is ambiguous.

  A) <topic-a slug> — "<title>" — last_updated <date>, status <status>
     summary: <one line>
  B) <topic-b slug> — "<title>" — last_updated <date>, status <status>
     summary: <one line>
  C) New topic: "<session_topic_title>"  (no parent)

Pick the closest. C creates a separate workstream.
```

### Step 5: Resolve target folder path

```bash
# Inputs from Step 4:
#   MATCH_MODE = clear_match | ambiguous_match_user_picked_existing | new_topic | ambiguous_match_user_picked_new
#   MATCHED_TOPIC_SLUG = the topic slug to inherit (when continuing)
#   PARENT_SNAPSHOT_PATH = absolute path to parent folder OR legacy v2 file (when continuing)
#   PARENT_KIND = v3_folder | v2_legacy_file | none

case "$MATCH_MODE" in
  clear_match|ambiguous_match_user_picked_existing)
    TOPIC_SLUG="$MATCHED_TOPIC_SLUG"
    ;;
  new_topic|ambiguous_match_user_picked_new)
    TOPIC_SLUG=$(printf '%s' "$session_topic_title" | tr '[:upper:]' '[:lower:]' | tr -s ' \t/' '-' | tr -cd 'a-z0-9.-' | cut -c1-60)
    [ -z "$TOPIC_SLUG" ] && TOPIC_SLUG=untitled
    PARENT_SNAPSHOT_PATH=""
    PARENT_KIND="none"
    ;;
esac

TARGET_FOLDER="$CHECKPOINT_DIR/${NOW_FOLDER}-${TOPIC_SLUG}"
# Second-resolution collision: append 4-char random suffix.
if [ -e "$TARGET_FOLDER" ]; then
  TARGET_FOLDER="${TARGET_FOLDER}-$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 4)"
fi
TMP_FOLDER="${TARGET_FOLDER}.tmp.$$"
echo "TARGET_FOLDER=$TARGET_FOLDER"
echo "TMP_FOLDER=$TMP_FOLDER"
mkdir -p "$TMP_FOLDER"
```

### Step 6: Read parent (mandatory unless new_topic)

If `PARENT_KIND=v3_folder`, use `Read` to load all four files inside the parent folder:

1. `<parent>/context.md`
2. `<parent>/DECISIONS.md`
3. `<parent>/PROGRESS.md`
4. `<parent>/RESULTS.md`

Read in full, line by line. Do NOT skip. Do NOT summarize from memory.
Sub-agent digests would silently drop items — read inline.

If `PARENT_KIND=v2_legacy_file`, use `Read` on the single `CURRENT-<topic>.md` file. Treat it as the parent equivalent. Map sections:
- v2 `## Goal` → seeds v3 `context.md` `## Topic identity`
- v2 `## Active decisions` → seeds v3 `DECISIONS.md`
- v2 `## Open remaining work` → seeds v3 `PROGRESS.md`
- v2 `## Notes & gotchas` → seeds v3 `context.md` `## Notable gotchas`
- v2 `## Files modified` → seeds v3 `PROGRESS.md` session log
- v2 `## Session timeline` → seeds v3 `PROGRESS.md` session log

Do NOT delete or modify the v2 file. It stays in place as a backup.

If `PARENT_KIND=none`, skip Step 6.

### Step 7: Write the four files into `$TMP_FOLDER`

Use the `Write` tool. Each file goes to `$TMP_FOLDER/<name>`.

#### 7a — `context.md`

Compose frontmatter from:
- `topic` = `$TOPIC_SLUG`
- `title` = inherited from parent unless workstream pivoted (then strike-through old, add new in parent's title row + use new)
- `summary` = inherited unless workstream pivoted
- `keywords` = union of parent + session_keywords (dedup, cap at 7)
- `created` = `$NOW_ISO` (snapshot folder creation; identical across siblings inside this folder)
- `last_updated` = `$NOW_ISO`
- `session_number` = parent.session_number + 1, or 1 if new
- `project_slug` = `$SLUG` (informational metadata; not used for storage path)
- `repo_path` = `$REPO_PATH`
- `current_branch` = `$CURRENT_BRANCH`
- `head_commit` = `$HEAD_COMMIT`
- `related_branches` = union of parent + `$CURRENT_BRANCH` (skip if empty)
- `related_commits` = union of parent + `$HEAD_COMMIT` (skip if empty; cap last 50, oldest rolled to `related_commits_archived` if exceeding)
- `parent_snapshot` = parent folder basename (or v2 filename) or empty
- `status` = `in-progress` unless user explicitly marks otherwise

Compose body per the template under "context.md — body" above. Top-N
lists (decisions, open, resolved) pull from the corresponding sibling
files. Use the actual values you wrote there.

#### 7b — `DECISIONS.md`

Newest session first. New session block at top:

```markdown
## Session <N> (<YYYY-MM-DD>)
- <each session_decision>. **Why:** ... **Tradeoff:** ...
```

Below it: parent's `DECISIONS.md` content verbatim (or seeded from v2
`## Active decisions` if parent is legacy).

#### 7c — `PROGRESS.md`

Build sections from:
- Parent's `## Done` + new resolved items (session_resolved).
- Parent's `## In progress` + new in-progress items.
- Parent's `## Open / next steps` + new open items.
- Parent's `## Blocked` + new blocked items.
- Session log table: parent's rows + new row prepended.

Resolved items get `[done session <N>, <date>]` marker; never deleted.

#### 7d — `RESULTS.md`

New session block at top:

```markdown
## Session <N> (<YYYY-MM-DD>)

### <validation name>
- Command: `...`
- Output (head):
  ```
  ...
  ```
- Verdict: ...
- Full output: `artifacts/logs/<filename>`  (only if too long for inline)
```

Below it: parent's `RESULTS.md` content verbatim.

If any output exceeds ~20 lines inline, write the full output to
`$TMP_FOLDER/artifacts/logs/<name>-<timestamp>.log` and reference it
from the inline block. Create `artifacts/logs/` only if at least one
log goes there.

#### 7e — Carry-forward checklist (mandatory)

- [ ] Every decision in parent `DECISIONS.md` appears in new `DECISIONS.md` (verbatim or marked superseded).
- [ ] Every item in parent `PROGRESS.md` appears (open AND `[done session N]`).
- [ ] Every entry in parent `RESULTS.md` appears.
- [ ] Session log table has parent rows + new row prepended.
- [ ] `session_number` incremented (or `1` if new).
- [ ] `related_branches` / `related_commits` are unions with current.
- [ ] `parent_snapshot` set to parent folder basename (or v2 filename) — empty only when `new_topic`.
- [ ] `context.md` body sections present in fixed order.
- [ ] `context.md` ≤500 lines.
- [ ] `summary:` ≤200 chars and present.
- [ ] `keywords:` 3-7 entries.

### Step 7f: Mechanical sanity check

```bash
if [ -n "$PARENT_SNAPSHOT_PATH" ]; then
  case "$PARENT_KIND" in
    v3_folder)
      P_DEC=$(grep -c '^- ' "$PARENT_SNAPSHOT_PATH/DECISIONS.md" 2>/dev/null || echo 0)
      P_PROG=$(grep -c '^- ' "$PARENT_SNAPSHOT_PATH/PROGRESS.md" 2>/dev/null || echo 0)
      P_RES=$(grep -c '^### ' "$PARENT_SNAPSHOT_PATH/RESULTS.md" 2>/dev/null || echo 0)
      ;;
    v2_legacy_file)
      P_DEC=$(awk '/^## Active decisions/,/^## /' "$PARENT_SNAPSHOT_PATH" | grep -c '^- ' || echo 0)
      P_PROG=$(awk '/^## Open remaining work/,/^## /' "$PARENT_SNAPSHOT_PATH" | grep -cE '^[0-9]+\. ' || echo 0)
      P_RES=0  # v2 had no RESULTS section
      ;;
  esac
  N_DEC=$(grep -c '^- ' "$TMP_FOLDER/DECISIONS.md" 2>/dev/null || echo 0)
  N_PROG=$(grep -c '^- ' "$TMP_FOLDER/PROGRESS.md" 2>/dev/null || echo 0)
  N_RES=$(grep -c '^### ' "$TMP_FOLDER/RESULTS.md" 2>/dev/null || echo 0)
  echo "PRIOR  decisions=$P_DEC  progress=$P_PROG  results=$P_RES"
  echo "DRAFT  decisions=$N_DEC  progress=$N_PROG  results=$N_RES"
  if [ "$N_DEC" -lt "$P_DEC" ] || [ "$N_PROG" -lt "$P_PROG" ] || [ "$N_RES" -lt "$P_RES" ]; then
    echo "ERROR: draft dropped entries vs parent — STOP, fix merge, do NOT publish"
    exit 1
  fi
fi
CTX_LINES=$(wc -l < "$TMP_FOLDER/context.md")
if [ "$CTX_LINES" -gt 500 ]; then
  echo "ERROR: context.md is $CTX_LINES lines (>500) — push detail into siblings"
  exit 1
fi
```

If any check fails: stop, fix the draft, re-check. Do NOT publish a
broken snapshot.

### Step 8: Atomic publish

```bash
mv "$TMP_FOLDER" "$TARGET_FOLDER"
ls -la "$TARGET_FOLDER"
```

`mv` of a directory on the same filesystem is atomic. Readers either
see the old layout or the complete new layout — never a half-written
folder.

### Step 9: Confirm

```
CONTEXT SAVED (rolling v3, topic-snapshot folder)
═════════════════════════════════════════════════
Topic:           {title}
Topic slug:      {topic-slug}
Snapshot folder: {YYYY-MM-DD_HHMMSS-<slug>}
Match mode:      {clear_match | ambiguous_match | new_topic}
Parent snapshot: {parent basename, or "(new topic)"}
Session #:       {N}
Branch:          {branch or "(none)"}
Commit:          {commit or "(none)"}
Files this run:  {count}  (cumulative across all sessions: {count})
Decisions:       {total} (new this session: {n})
Open work:       {open} (new this session: {n})
Results:         {entries this session: {n}}
context.md:      {lines}/500
artifacts/:      {present | empty}
═════════════════════════════════════════════════

Resume with /context-restore.
```

---

## List flow

`/context-save list`

```bash
for d in $(find "$CHECKPOINT_DIR" -mindepth 1 -maxdepth 1 -type d -name "20*-*" 2>/dev/null); do
  CTX="$d/context.md"
  [ -f "$CTX" ] || continue
  # ... extract frontmatter same as Step 3 ...
done | sort -t'|' -k1,1 -k2,2r | awk -F'|' '!seen[$1]++'
```

Present as: `TOPIC | LATEST FOLDER | SESSIONS | STATUS | SUMMARY`.

Add `--all` to list every snapshot (not just latest per topic).

---

## Manual merge flow

`/context-save merge <topic-a-slug> <topic-b-slug>`

When two topic slugs cover the same workstream:

1. AskUserQuestion: "Merge `<topic-a>` into `<topic-b>`? Pick canonical slug."
2. Read the latest folder of each.
3. Build a new snapshot folder under the canonical slug with `parent_snapshot` set to the loser's latest folder. Merge content (union of decisions, progress, results).
4. Move all loser folders to `archived/` (never delete — recovery path):
   `mv "$CHECKPOINT_DIR/<folder>" "$CHECKPOINT_DIR/archived/<folder>--merged-into-<canonical>-<date>"`
5. Confirm.

---

## Important rules

- **Never modify code.** Read-only on the repo; write only into the checkpoint folder.
- **Topic is the partition.** Folder name encodes topic slug + timestamp. Branches/commits live inside `context.md` as lists.
- **Never skip topic-match.** Step 4 is load-bearing.
- **Never skip parent read.** Reading parent in full (line by line) is the only way to carry forward without dropping items.
- **Carry forward verbatim.** No paraphrase. No silent deletion of resolved or superseded items.
- **Atomic publish via `.tmp.$$` + `mv`.** Never write directly into the target folder name.
- **Bias toward merge into matched topic.** Branch- or commit-hopping is normal.
- **context.md is for routing.** ≤500 lines, scannable, with pointers to siblings. Detail lives in DECISIONS / PROGRESS / RESULTS / artifacts.
- **All snapshot material stays inside the snapshot folder.** Never reference paths outside `$TARGET_FOLDER` for snapshot-owned artifacts.

---

## Anti-pattern: do NOT use parallel sub-agents on save

Save is sequential. Parent must be read literally, line by line, in
main context. A sub-agent digest is a summary, and summaries silently
drop items.

Restore is allowed to parallelize (it dispatches across **separate**
files with no merge required). Save merges one file into another and
must see every line.

---

## Red flags — STOP and restart the step

- "Branch is `feat/auth-b` now, last save was on `feat/auth-a`, must be a new topic." → STOP. Branches don't define topics. Re-check Step 4.
- "I remember the parent's `DECISIONS.md`, I don't need to Read it." → STOP. Read.
- "Two candidates match weakly, I'll pick the closer one." → STOP. Ambiguous → ask.
- "Topic slug almost matches, I'll just create a new file." → STOP. Slug match is one signal; check title + goal + files + keywords + branches.
- "Resolved items are clutter, drop them." → STOP. `[done session N]` + strike-through, never delete.
- "context.md hit 700 lines; I'll leave it." → STOP. Push detail to siblings.
- "I'll dispatch a sub-agent to do the merge in parallel." → STOP. Save is sequential.
- "Skip the `summary:` or `keywords:` fields — title is enough." → STOP. Restore routes on these.
- "I'll write `RESULTS.md` outside the snapshot folder, into a shared logs dir." → STOP. All snapshot material stays inside the folder.
- "I'll overwrite the parent v2 `CURRENT-<topic>.md` while migrating." → STOP. Leave it in place as backup; the new v3 folder is independent.
