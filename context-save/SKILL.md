---
name: context-save
description: |
  Use when the user finished a meaningful unit of work (code edit,
  decision, bug fix, completed investigation, validated behavior,
  refactor phase, stopping point before switch, blocker discovered)
  AND a structured snapshot is needed for resume. Also when the user
  says "save progress", "save state", "save my work", "context save",
  "/context-save".
allowed-tools: [Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion]
---

# /context-save — append-only event-log save (v4)

## Overview

Persist the current workstream as an **append-only event log**, one folder
per topic. Each save **appends** one dated block to the logs and patches one
row in `INDEX.json`. Saves are O(1): you never re-read or re-write history.

**Core principle: APPEND, NEVER REWRITE. ROUTE VIA INDEX, NEVER SCAN.**

History lives in the logs (nothing is ever deleted). Current state is computed
later by `/context-restore` folding the logs. You do **not** need to read the
logs to save — `meta.json.active_items` already tells you the live ids.

Grammar + fold algorithm: **REQUIRED REFERENCE:** read
`reference/eventlog-format.md`. Schemas + jq recipes: `reference/index-schema.md`.

## HARD GATES

1. **No code changes.** Snapshot only; read-only on the repo.
2. **Append only.** Never re-read or re-write existing log content. New
   sessions add a block at the end; old blocks stay byte-identical.
3. **Never read the logs to save.** To reference/close prior items, read
   `meta.json.active_items` — NOT `decisions.log`/`progress.log`/`results.log`.
4. **Route via `INDEX.json`.** Never list/scan the checkpoint folders to find
   a topic.

## Layout

```
~/.claude/projects/checkpoints/
  INDEX.json                 # routing table — read this, never scan folders
  <topic-slug>/
    meta.json                # title, summary, sessions, next_id, active_items, format, ...
    decisions.log            # append-only
    progress.log             # append-only
    results.log              # append-only
    artifacts/               # logs/ patches/ snapshots/
```

## Save flow (5 steps)

### Step 1 — Gather state
Run git + infer this session's content:
```bash
CKPT="${CONTEXT_CHECKPOINT_DIR:-$HOME/.claude/projects/checkpoints}"; INDEX="$CKPT/INDEX.json"
mkdir -p "$CKPT"
[ -f "$INDEX" ] || echo '{"schema":"context-save/v4","topics":{}}' > "$INDEX"
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null||echo ""); COMMIT=$(git rev-parse --short HEAD 2>/dev/null||echo "")
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```
Infer: decisions (+ why/tradeoff), progress (open/done/blocked), results
(check → verdict), init-commands, session summary/keywords.

### Step 2 — Route topic (read INDEX.json only)
**First-run migration:** if `INDEX.json` was just bootstrapped empty but topic
folders already exist on disk, run `rebuild-index` first (it imports existing
v3 folders as routable `legacy-v3` rows). Skipping this makes an existing topic
look "new" and spawns a duplicate.
```bash
jq -r '.topics | to_entries[] | "\(.key)\t\(.value.summary)\t\(.value.keywords|join(","))"' "$INDEX"
```
Match this session vs rows by slug / keyword / summary overlap.
- **Clear match** → that topic. Read its `meta.json` for `active_items` +
  `next_id` (this is the ONLY file you read to learn prior ids — NOT the logs).
- **Ambiguous** (2+ plausible) → AskUserQuestion listing candidates + "New topic".
- **No match** → new topic (kebab slug ≤60 chars; create folder + empty logs +
  `meta.json` with `next_id:1`, `active_items:{}`, `format:"eventlog"`).

### Step 3 — Lazy-convert legacy topic (only if matched topic is `format:"legacy-v3"`)
One-time: read the old `context.md`/`DECISIONS.md`/`PROGRESS.md`/`RESULTS.md`,
fold them (per `reference/eventlog-format.md`) into `decisions.log` /
`progress.log` / `results.log` as a single `## session <n>` block, build
`active_items` from the fold, set `format:"eventlog"`. Leave the old v3 files
in place (never delete). Then proceed.

### Step 4 — Append event blocks
Append one `## session <N>` block (N = `meta.sessions + 1`) to each log that
has new content. Assign new ids from `next_id` (bump as you go). Reference
prior ids from `active_items` (e.g. close `#3` with `[done] #3 …`, reverse a
decision with `[supersede sK#M] …`). Block grammar: `reference/eventlog-format.md`.
**Append at end only — do not rewrite existing lines.**

### Step 5 — Update meta + index + confirm
- `meta.json`: bump `next_id`, set `active_items` (add new open items + active
  decisions, drop ids you just `[done]`/`[supersede]`d), `sessions += 1`,
  update `last_updated`, union `branches`/`commits`. jq recipe in `reference/index-schema.md`.
- `INDEX.json`: upsert this topic's row (sessions, status, last_updated,
  branches, summary, keywords, related_topics, format).
- Confirm: print topic / slug / session N / branch / commit / folder.

## Subcommands

- `/context-save [title]` — save (default).
- `/context-save list` — `jq` over `INDEX.json`, print `TOPIC | SESSIONS | STATUS | SUMMARY`.
- `/context-save merge <a> <b>` — AskUserQuestion for canonical slug; append a
  merge block referencing both; move loser folder to `archived/`; update INDEX
  + `related_topics`. Never delete.
- `/context-save rebuild-index` — regenerate `INDEX.json` by scanning folders
  once (recipe in `reference/index-schema.md`). The ONLY command allowed to scan.

## Red flags — STOP

| Thought | Reality |
|---------|---------|
| "Let me read the logs to see current state before saving." | STOP. Save never reads logs. `meta.json.active_items` has the live ids. |
| "I'll read all the logs to find the id of the item I'm closing." | STOP. The id is in `active_items`. Reading logs to save is the v3 mistake this skill removes. |
| "Cleaner to rewrite the log into one tidy block." | STOP. Append only. Rewriting destroys history + breaks fold. |
| "I'll scan the folders to find the topic." | STOP. Read `INDEX.json`. Only `rebuild-index` scans. |
| "The logs look small, re-reading is cheap." | STOP. Size is irrelevant — append-only is the rule, and logs grow unbounded. |
| "No prior topic matches, but two are close — pick the closer." | STOP. 2+ plausible = ambiguous → AskUserQuestion. |

## Common mistakes
- Editing an old `## session` block instead of appending a new one.
- Forgetting to drop a `[done]`/`[supersede]`d id from `active_items` (leaves
  it falsely "open" — restore self-heals, but keep meta correct).
- Writing snapshot material outside the topic folder. Everything stays inside.
