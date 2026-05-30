---
name: context-save
description: |
  Use when the user finished a meaningful unit of work (code edit,
  decision, bug fix, completed investigation, validated behavior,
  refactor phase, stopping point before switch, blocker discovered)
  AND a structured snapshot is needed for resume. Also when user says
  "save progress", "save state", "save my work", "context save",
  "/context-save". Writes a timestamped folder (v3) with sibling
  context / decisions / progress / results / optional artifacts.
  Topic identity carries across branches and commits.
allowed-tools: [Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion]
---

# /context-save — Topic-Snapshot Save (v3)

Produce a self-contained, machine-friendly snapshot of the current
workstream. **One folder per save.** Sibling files separate concerns.
A fresh agent can route to it and resume without loss.

**HARD GATES:**
1. No code changes — snapshot only.
2. Do NOT skip topic-match (Step 4). Creating a new folder without checking whether this session continues an existing topic fragments the workstream.
3. Every snapshot is self-contained — all files live INSIDE its folder. Never write snapshot material outside.

---

## Layout

Single global checkpoint dir: `~/.claude/projects/checkpoints/`. All topic snapshots from every project live side-by-side. Topic-slug uniqueness is the agent's job (pick slugs descriptive enough to not collide across unrelated workstreams).

```
~/.claude/projects/checkpoints/
  YYYY-MM-DD_HHMMSS-<topic-slug>/
    context.md     # routing + summary, ≤500 lines
    DECISIONS.md   # full decision log (carry-forward + new)
    PROGRESS.md    # done / in-progress / open / blocked + session log
    RESULTS.md     # validation outputs
    artifacts/     # optional: logs/, patches/, research/, snapshots/
```

Folder name: `YYYY-MM-DD_HHMMSS-<topic-slug>`. Same topic across saves
→ same slug, different timestamp. Old snapshots are never overwritten
or deleted. Second-resolution collision → append 4-char random suffix.

## `context.md` frontmatter (mandatory)

```yaml
---
schema: context-save/v3
topic: <topic-slug>            # stable identity across snapshots
title: <stable human title>    # changes only on workstream pivot
summary: "<≤200 chars; restore routes on this line>"
keywords: [<3-7 routing tokens>]
created: <ISO-8601>
last_updated: <ISO-8601>
session_number: <N>            # parent.session_number + 1, or 1
project_slug: <informational only — origin working dir>
repo_path: <abs path>
current_branch: <branch or empty>
head_commit: <7-char or empty>
related_branches: [<union of parent + current>]
related_commits: [<union, cap last 50>]
parent_snapshot: <prior folder basename, or empty>
status: in-progress | resolved | abandoned
---
```

## `context.md` body (mandatory, ≤500 lines, fixed section order)

```markdown
# <title>

> **Summary:** <verbatim mirror of frontmatter summary>

## Topic identity
<1-3 sentences: what, why, definition of done>

## Quick state
- Branch: <current_branch>
- Commit: <head_commit>
- Session: <N>
- Status: <status>
- Last updated: <last_updated>

## Environment / Init commands
*(Restore offers but never auto-runs these. User decides per-command. Omit section if none. NOT for one-shot validation — that's RESULTS.md.)*

- `<exact command>` — <purpose>. Required: <yes | recommended | optional>. Side effects: <none | mutates local DB | starts long-running server | network downloads | …>. Est: <Ns>.

## What's in this snapshot
- `DECISIONS.md` — <count>; `PROGRESS.md` — <X done / Y open / Z blocked>; `RESULTS.md` — <K>; `artifacts/` — <present | empty>

## Active decisions (top 5) — see `DECISIONS.md` for full log
- <one-line> — *(session K)*

## Open work (top 5) — see `PROGRESS.md` for full backlog
- <one-line> — *(opened session J)*

## Recently resolved (top 5)
- ~~<item>~~ `[done session K]` — <date>

## Notable gotchas / constraints
- <one-line>

## How to resume
1. <concrete next action>

## Routing hints
- **Matches if task involves:** <keywords + summary>
- **Does NOT match if task involves:** <anti-keywords>
- **Adjacent topics:** <folder names, or "none">
```

`context.md` is for routing + orientation, not exhaustive detail. Hard cap **500 lines**; Step 7f enforces.

## Siblings — shape

- **`DECISIONS.md`** — newest session first. Per item: `- <decision>. **Why:** … **Tradeoff:** …`. Supersession: `- ~~<old>~~ → <new>. Superseded session N because …`. Carry-forward verbatim; never delete.
- **`PROGRESS.md`** — sections `## Done` / `## In progress` / `## Open / next steps` / `## Blocked` + `## Session log` table. Resolved items: `[done session K, <date>]`; never deleted.
- **`RESULTS.md`** — per session, blocks of `### <name>` with Command / Output head (≤20 lines) / Verdict / Full output path (if logged to `artifacts/logs/`).
- **`artifacts/`** — optional. `logs/`, `patches/`, `research/`, `snapshots/`. Everything referenced from a sibling `.md`.

---

## Detect command

`/context-save [<title>]` → save. `/context-save list` → list. `/context-save merge <a> <b>` → merge topics. `/context-save resume|restore` → tell user "Use `/context-restore`".

---

## Save flow

### Step 1: Resolve paths + gather state

```bash
CHECKPOINT_DIR=~/.claude/projects/checkpoints
mkdir -p "$CHECKPOINT_DIR"
eval "$(~/.claude/skills/gstack/bin/gstack-slug 2>/dev/null)" 2>/dev/null || SLUG=$(basename "$PWD")
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
HEAD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "")
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
NOW_FOLDER=$(date +"%Y-%m-%d_%H%M%S")
REPO_PATH=$(pwd -P)
git status --short; git diff --stat; git diff --cached --stat; git log --oneline -10
```

### Step 2: Infer session content

From the conversation, infer:
- `session_topic_title` — short, stable, goal-oriented. NOT branch-derived.
- `session_topic_slug` — lowercase-kebab, ≤60 chars, alnum + hyphen.
- `session_summary` — ≤200 chars, plain English, stable across sessions.
- `session_keywords` — 3-7 routing tokens.
- `session_goal` — 1-3 sentences.
- `session_decisions` — with reasons + tradeoffs.
- `session_resolved` / `session_open` / `session_blocked` / `session_gotchas`.
- `session_files` — files modified.
- `session_results` — `{name, command, output_head, verdict}` entries.
- `session_init_commands` — env / bring-up commands a future agent should re-run to resume cleanly. Examples: `pnpm install`, `docker compose up`, `make dev`, dev-server starts, schema/migration commands, login helpers. Each entry: `{command, purpose, required, side_effects, est_seconds}`.
  - `required`: `yes` (env unusable without) | `recommended` (smoke test) | `optional`
  - `side_effects`: terse — `none`, `mutates local DB`, `starts long-running server`, `network downloads`, `kills port N listeners`. **Required field.** Empty / `unknown` means restore refuses auto-run.
  - Exclude one-shot validation commands (those go to RESULTS.md). Init answers "is env ready?", not "did it work?".
  - Carry forward from parent unless explicitly retired this session.

### Step 3: Enumerate prior snapshots + group by topic

Read `context.md` frontmatter only (`rg -m 1` per field). Build
`topic | folder | last_updated | status | title | summary | keywords | branches | abs_path` per snapshot. Latest per topic = sort folder desc, dedup on topic. Also enumerate legacy v2 `CURRENT-*.md` files for parenting fallback.

If both lists empty → `MATCH_MODE=new_topic`, skip to Step 5.

### Step 4: Topic-match decision

For each candidate (latest v3 + legacy v2), score five signals:

| Signal | Strong | Weak |
|--------|--------|------|
| Title overlap | verbatim / near-prefix / paraphrase | one common noun only |
| Goal overlap | same problem | same domain different problem |
| File-path overlap | ≥1 exact match OR ≥2 share non-trivial dir prefix | only top-level dir |
| Branch/commit overlap | **exact string match** in `related_branches` / `related_commits` | none (visual similarity = zero signal) |
| Keyword overlap | ≥2 matches | 1 match |

Decide:

| Outcome | When | Action |
|---------|------|--------|
| `clear_match` | Exactly one candidate has strong title AND strong goal, OR exact branch/commit. | Inherit topic slug; that candidate is `parent_snapshot`. |
| `ambiguous_match` | 2+ candidates strong, OR mixed strong+weak, OR signals contradict. | AskUserQuestion — list candidates + "New topic". |
| `new_topic` | No strong overlap on title/goal/exact branch. Single shared common noun is NOT ambiguous. | New slug, no parent. |

Bias: toward `clear_match` (branch/commit-hop is normal); against silent merge into wrong topic; single-word noun coincidence = `new_topic`.

### Step 5: Resolve target folder path

```bash
TOPIC_SLUG=$MATCHED_TOPIC_SLUG   # or kebab(session_topic_title), ≤60 chars
TARGET_FOLDER="$CHECKPOINT_DIR/${NOW_FOLDER}-${TOPIC_SLUG}"
[ -e "$TARGET_FOLDER" ] && TARGET_FOLDER="${TARGET_FOLDER}-$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 4)"
TMP_FOLDER="${TARGET_FOLDER}.tmp.$$"
mkdir -p "$TMP_FOLDER"
```

### Step 6: Read parent in full (mandatory unless `new_topic`)

Use `Read` line-by-line on parent's `context.md`, `DECISIONS.md`,
`PROGRESS.md`, `RESULTS.md`. Do NOT summarize from memory. Do NOT
dispatch a sub-agent — sub-agent digests silently drop items.

For legacy v2 single-file parent: read once, map sections —
`## Goal` → `context.md ## Topic identity`; `## Active decisions` → `DECISIONS.md`; `## Open remaining work` → `PROGRESS.md`; `## Notes & gotchas` → `context.md ## Notable gotchas`; `## Files modified` + `## Session timeline` → `PROGRESS.md` session log. **Do NOT delete or modify the v2 file** — leave as backup.

### Step 7: Write four files into `$TMP_FOLDER` via `Write`

**7a `context.md`** — frontmatter from Step 2 + parent unions. `title` / `summary` inherited unless workstream pivoted. `keywords` = union (cap 7). `session_number` = parent + 1 or 1. `related_branches` / `related_commits` = union with current (commits cap last 50; older roll to `related_commits_archived`). Body per template above.

**7b `DECISIONS.md`** — new session block on top, parent verbatim below (or seeded from v2 `## Active decisions`).

**7c `PROGRESS.md`** — union of parent sections + new items. Session log row prepended to parent rows. Resolved items get `[done session N, <date>]`; never deleted.

**7d `RESULTS.md`** — new session block on top, parent verbatim below. Outputs >20 lines write to `$TMP_FOLDER/artifacts/logs/<name>-<ts>.log`, referenced inline.

**7e Carry-forward checklist (mandatory):**
- [ ] Every parent decision present (verbatim or marked superseded).
- [ ] Every parent progress item present (open OR `[done session N]`).
- [ ] Every parent results entry present.
- [ ] Session log: parent rows + new prepended.
- [ ] `session_number` incremented (or 1 if new).
- [ ] `related_branches` / `related_commits` are unions with current.
- [ ] `parent_snapshot` set (empty only when `new_topic`).
- [ ] `context.md` ≤500 lines.
- [ ] `summary:` ≤200 chars, `keywords:` 3-7 entries.
- [ ] Every parent **Init command** present in `## Environment / Init commands` (unless user explicitly retired one — record retirement in `DECISIONS.md`).

**7f Mechanical sanity check:**
```bash
if [ -n "$PARENT_SNAPSHOT_PATH" ]; then
  case "$PARENT_KIND" in v3_folder) DIR="$PARENT_SNAPSHOT_PATH";; esac
  P_DEC=$(rg -c '^- ' "$DIR/DECISIONS.md" 2>/dev/null||echo 0); N_DEC=$(rg -c '^- ' "$TMP_FOLDER/DECISIONS.md"||echo 0)
  P_PROG=$(rg -c '^- ' "$DIR/PROGRESS.md"||echo 0);  N_PROG=$(rg -c '^- ' "$TMP_FOLDER/PROGRESS.md"||echo 0)
  P_RES=$(rg -c '^### ' "$DIR/RESULTS.md"||echo 0);   N_RES=$(rg -c '^### ' "$TMP_FOLDER/RESULTS.md"||echo 0)
  [ "$N_DEC" -lt "$P_DEC" ] || [ "$N_PROG" -lt "$P_PROG" ] || [ "$N_RES" -lt "$P_RES" ] && { echo "ERROR: draft dropped entries — STOP, do NOT publish"; exit 1; }
fi
[ "$(wc -l < "$TMP_FOLDER/context.md")" -gt 500 ] && { echo "ERROR: context.md >500 lines — push detail into siblings"; exit 1; }
```

### Step 8: Atomic publish

```bash
mv "$TMP_FOLDER" "$TARGET_FOLDER"   # atomic on same filesystem
```

### Step 9: Confirm — print topic / slug / folder / match-mode / parent / session # / branch / commit / counts / context.md lines / artifacts status. Tell user "Resume with /context-restore".

---

## list / merge flows

`/context-save list` — same enumeration as Step 3, present as `TOPIC | LATEST FOLDER | SESSIONS | STATUS | SUMMARY`. `--all` lists every snapshot.

`/context-save merge <a> <b>` — AskUserQuestion for canonical slug, read both latest folders, write a new snapshot under canonical with merged content + `parent_snapshot` = loser's latest. Move loser folders to `$CHECKPOINT_DIR/archived/<folder>--merged-into-<canonical>-<date>/` (never delete).

---

## Important rules

- Never modify code — read-only on repo; write only into checkpoint folder.
- Topic is the partition. Folder name = topic slug + timestamp. Branches/commits live as lists in `context.md`.
- Never skip topic-match (Step 4 is load-bearing).
- Never skip parent read — full, line-by-line, in main context.
- Carry forward verbatim. No paraphrase. No silent deletion of resolved/superseded.
- Atomic publish via `.tmp.$$` + `mv`.
- Bias toward merging into matched topic — branch/commit hop is normal.
- `context.md` is for routing — ≤500 lines, scannable.
- All snapshot material stays inside the folder.

## Anti-pattern: never parallel sub-agents on save

Save is sequential. Parent must be read literally, line by line, in
main context. Sub-agent digest = summary; summaries drop items.

---

## Red flags — STOP and restart the step

- "Branch is `feat/auth-b`, last save was `feat/auth-a`, must be new topic." → STOP. Branches don't define topics. Re-check Step 4.
- "I remember parent's `DECISIONS.md`, no need to Read." → STOP. Read.
- "Two candidates match weakly, pick closer." → STOP. Ambiguous → ask.
- "Topic slug almost matches, just create new file." → STOP. Slug match is one signal; check title + goal + files + keywords + branches.
- "Resolved items are clutter, drop them." → STOP. `[done session N]` + strike-through, never delete.
- "context.md hit 700 lines, leave it." → STOP. Push detail to siblings.
- "Sub-agent in parallel for the merge." → STOP. Save is sequential.
- "Skip `summary:` / `keywords:` — title is enough." → STOP. Restore routes on these.
- "Write `RESULTS.md` outside the snapshot folder." → STOP. All snapshot material stays inside.
- "Overwrite parent v2 `CURRENT-<topic>.md` while migrating." → STOP. Leave in place as backup.
- "No init commands worth recording — env is obvious." → STOP. If session ran any `install` / `compose up` / `make dev` / dev-server start / migration, record it. Future-agent has zero visibility otherwise.
- "Skip `side_effects` field, it's tedious." → STOP. Restore uses it to gate auto-run. Missing = restore refuses to include in any auto-run set.
