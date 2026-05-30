---
name: context-restore
description: |
  Use when the user wants to resume work from a prior /context-save
  snapshot, or says "restore context", "where was I", "resume", "pick
  up where I left off", "continue the topic", "/context-restore".
allowed-tools: [Bash, Read, Glob, Grep, AskUserQuestion, Agent]
---

# /context-restore — parallel-fold resume (v4)

## Overview

Resume a workstream from its append-only event-log snapshot **without pulling
raw logs into this session**. Route to a topic via `INDEX.json`, then dispatch
**parallel sub-agents** that each read one log, fold it to current state, and
return only a small digest. You stitch those digests into a resume briefing.

**Core principle: THE MAIN SESSION NEVER READS A LOG. SUB-AGENTS FOLD; YOU
STITCH.**

Logs grow unbounded; the whole point of v4 is that heavy reads live in
sub-agents so your context stays lean. Fold grammar: **REQUIRED REFERENCE**
`../context-save/reference/eventlog-format.md`. Schemas: `../context-save/reference/index-schema.md`.

## HARD GATES

1. **Main session never reads a `.log` file.** Not with Read, not `cat`, not
   `jq`, not `head`, not `rg`. Logs are folded ONLY inside sub-agents. The main
   session reads only `INDEX.json`, the chosen `meta.json`, and the agents'
   returned digests.
2. **Apparent size is irrelevant.** "It's only N lines, I'll just read it" is
   forbidden — you cannot know the real size from the index, and the rule does
   not bend for small logs.
3. **Fold agents are dispatched in ONE message** (parallel), not sequentially.
4. **Adjacent topics are pointers, never auto-folded.** Fold only the primary
   topic unless the user opts in to a specific related topic.
5. **Never auto-run init commands.** Offer; the user decides per command.

## Restore flow

### Step 1 — Route (read INDEX.json only)
```bash
CKPT="${CONTEXT_CHECKPOINT_DIR:-$HOME/.claude/projects/checkpoints}"; INDEX="$CKPT/INDEX.json"
# First-ever v4 run, or missing INDEX → rebuild-index first (imports legacy v3
# folders as routable legacy-v3 rows; without this, existing topics are invisible).
[ -f "$INDEX" ] || echo "INDEX missing — run /context-save rebuild-index, then re-route"
jq -r '.topics | to_entries[] | "\(.key)\t\(.value.status)\t\(.value.last_updated)\t\(.value.summary)"' "$INDEX"
```
Score rows against the task signal (summary + keywords + branch + recency).
- **Clear winner** → that topic.
- **Ambiguous** (2+ comparable) → AskUserQuestion listing top candidates + "None — start fresh".
- **Index missing, or matched folder absent on disk** → run
  `/context-save rebuild-index` (self-heal), then re-route.
- **No signal (bare command)** → pick most-recently-updated; say it was by recency.

Read the winner's `meta.json` (header + `active_items` — small, allowed).

### Step 2 — Fan out: parallel per-file fold agents (ONE message)
Dispatch these as sub-agents **together in a single message** so they run in
parallel. Each returns ONLY a capped digest (≤40 lines) — never raw log lines.

- **Agent A — decisions:** fold `<topic>/decisions.log` → active
  (non-superseded) decisions + count.
- **Agent B — progress:** fold `<topic>/progress.log` → open + blocked items
  + done-in-last-2-sessions + counts.
- **Agent C — results:** fold `<topic>/results.log` → latest verdict per check.
- **Agent D — artifacts** (only if `<topic>/artifacts/` non-empty): list files,
  one line each.

Fold-agent prompt template (substitute the absolute paths + log name):
> Read `<ABS>/context-save/reference/eventlog-format.md`, then read
> `<ABS topic>/<log>.log` IN FULL and apply that log type's fold algorithm.
> Return ONLY the folded current state — each surviving item with its `#id` —
> plus a one-line count header (e.g. `active decisions: 3`). Hard cap 40 lines:
> if the fold is larger, write the full fold to
> `<ABS topic>/artifacts/fold-<log>-<ts>.md` and return a pointer + counts
> instead. Do NOT return raw log lines.

**Legacy fallback:** if `meta.format == "legacy-v3"`, point the agents at the
old files (`DECISIONS.md` / `PROGRESS.md` / `RESULTS.md`) — same contract.

### Step 3 — Stitch the briefing
Assemble: `meta` header (title / summary / sessions / status / branch) +
Agent A/B/C/D digests + init-commands from meta. Sanity-check each agent's
reported counts against `meta.active_items` size; if they diverge wildly, note
it (active_items may be stale — the fold is authoritative). Present as one
RESUMING-CONTEXT briefing.

### Step 4 — Init commands + cross-topic pointers
- **Init commands:** present each verbatim with Required / Side effects / Est;
  AskUserQuestion before running ANY. Never auto-run. A failed init command is
  a STOP — surface exit + stdout tail, do not retry or auto-debug.
- **Cross-topic:** list the winner's `related_topics` as a short pointer list
  (`<slug> — <summary>`). Do NOT fold them. If the user picks one, re-run
  Step 2 on that topic.

## Subcommands

- `/context-restore [fragment]` — route + parallel fold + stitch.
- `/context-restore list` — `jq` over `INDEX.json`: `TOPIC | SESSIONS | STATUS | SUMMARY`.
- `/context-restore <fragment>` — match fragment vs slug/title/keywords first.

## Red flags — STOP

| Thought | Reality |
|---------|---------|
| "The logs are small, I'll just read them here." | STOP. Gate 1+2. Main never reads a log; size is irrelevant. Dispatch fold agents. |
| "I'll fold it myself, faster than spawning agents." | STOP. Folding in main = the flood this skill prevents. Dispatch agents. |
| "Let me read the log to double-check the agent's digest." | STOP. Trust the digest + counts; re-dispatch if you doubt it. |
| "I'll dispatch the fold agents one after another." | STOP. One message, parallel. |
| "The related topic looks relevant, fold it too." | STOP. Pointer only, unless the user opts in. |
| "Two topics match — pick the more recent." | STOP. Ambiguous → AskUserQuestion. |
| "Init commands look safe — run them so the user doesn't wait." | STOP. Offer only; per-command opt-in. |

## Common mistakes
- Reading `meta.json` is fine; reading any `.log` in main is not.
- A fold agent returning raw log lines instead of folded state + counts.
- Forgetting Agent D guard (skip when `artifacts/` is empty).
- Folding related topics without the user asking.
