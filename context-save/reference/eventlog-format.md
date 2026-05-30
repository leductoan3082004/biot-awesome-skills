# Event-log format (context-save v4)

The canonical grammar for the three append-only logs and the fold algorithm
that restore uses to compute current state. Both `context-save` and
`context-restore` reference this file — keep it the single source of truth.

## Logs

Each topic folder holds three append-only logs. Every save **appends** one
dated block per log; existing block content is **never** edited or re-read.

```
<topic-slug>/
  decisions.log
  progress.log
  results.log
```

## Block header (all three logs)

```
## session <N> — <ISO8601-UTC> — branch <branch> @ <commit7>
```

`<N>` = `meta.json.sessions + 1`. Branch/commit empty-safe (`@ ` with blank
commit is allowed off-git).

## Item ids

- Progress items and decisions carry a stable id `#N`, `N` monotonic **per
  topic**, sourced from `meta.json.next_id` (bump after assigning).
- Cross-session reference to an item created in an earlier session: `sK#N`
  (session K, item N). Within the same session, `#N` is sufficient.
- Save learns the ids of still-active items from `meta.json.active_items`
  (id → one-line text) — it does **not** read the logs to find them.

## decisions.log events

```
- [decision] #<N> <text>. why: <reason>. tradeoff: <tradeoff>.
- [supersede s<K>#<M>] <text explaining the reversal>.
```

- `[decision]` adds an active decision.
- `[supersede sK#M]` marks the referenced decision inactive (it stays on disk;
  fold drops it from the active set).

## progress.log events

```
- [open]  #<N> <text>
- [done]  #<N> — <text> (was opened s<K>)
- [block] #<N> <text> — blocked on <reason>
```

- `[open]` adds an open item. `[done]` closes it (last status per id wins).
- `[block]` marks it blocked. Re-opening = a later `[open]` for the same id.

## results.log events

```
- [result] <check-name> — <PASS|FAIL|verdict>
```

- Output > 20 lines: write the full output to
  `artifacts/logs/<check-name>-<ts>.log` and reference it:
  `- [result] <check-name> — PASS (full: artifacts/logs/<check-name>-<ts>.log)`.
- Last verdict per `<check-name>` wins on fold.

## Fold algorithm (restore)

Given one log, compute current state:

1. Read the whole log (this happens inside a fold sub-agent, never in main).
2. Walk blocks **oldest → newest**.
3. Keep a map keyed by item id; each event overwrites the prior entry for
   that id (last-write-wins).
4. **decisions.log**: `[decision] #N` sets id N active; `[supersede sK#M]`
   sets id M inactive. Emit only active decisions.
5. **progress.log**: last status per id wins. Emit `open` + `block` items,
   plus `done` items closed within the last 2 sessions (recency window).
6. **results.log**: last verdict per check name wins. Emit one line per check.
7. Each emitted item keeps its id (`#N`) so the digest carries ids back to
   main — needed for sanity-checks and for save's active_items rebuild.
8. **Cap**: digest ≤ 40 lines. On overflow, write the full fold to
   `artifacts/fold-<log>-<ts>.md` and return a pointer + counts instead of
   inlining.
9. Return counts in the digest header, e.g. `active decisions: 3` /
   `open: 5, blocked: 1` — lets main sanity-check nothing was silently dropped.

## active_items invariant

After any save, `meta.json.active_items` MUST equal the fold of progress
(open + blocked) ∪ fold of decisions (active). Restore rebuilds it from the
fold as self-heal. Save maintains it incrementally:
- add new `[open]`/`[decision]` ids,
- drop ids it just `[done]`/`[supersede]`d.
