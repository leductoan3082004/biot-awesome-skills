# Context save policy

> Loaded on demand from `AGENTS.md` router. Read this file before invoking /context-save.


After every meaningful unit of work this turn, invoke
`/context-save` **before your final response**. Binding rule —
not advisory.

**A "meaningful unit of work" is any of:**
- a code edit, write, or new file landed
- an architectural / design / scope decision made or reversed
- a bug reproduced, root-caused, or fixed
- a refactor phase completed
- an investigation or research thread closed with concrete findings
- a working patch produced
- behavior validated with tests, commands, or runtime observation
- a clear stopping point before switching tasks
- an important constraint, blocker, or hidden cost discovered

If **any** of those happened this turn, save.

**Do NOT save for:**
- clarifying questions back to the user
- confirmation requests before doing something
- trivial replies (single fact, short answer, status check)
- read-only exploration with no conclusions yet
- a follow-up tweak to work already saved earlier this session

When in doubt, lean toward **skipping**. Over-saving creates noise.
Missing one save is recoverable from git + memory; mis-saving every
turn poisons the snapshot store with churn.

**Layout (v4, append-only event-log — ONE folder per topic):**

Single global checkpoint dir. One stable folder per topic (NOT per save —
that was v3's folder explosion). Each save appends a dated block to the logs
and patches one row in `INDEX.json`. Override the dir with
`CONTEXT_CHECKPOINT_DIR` (for tests).

```
~/.claude/projects/checkpoints/
  INDEX.json                 # routing table — restore reads this, never scans folders
  <topic-slug>/
    meta.json                # title, summary, sessions, next_id, active_items, format
    decisions.log            # append-only event blocks
    progress.log             # append-only (open/done/block by stable #id)
    results.log              # append-only (latest verdict per check)
    artifacts/               # logs/ patches/ snapshots/
```

Save is **O(1)**: append only, never re-read or re-write history. It learns
prior item ids from `meta.json.active_items` (never from the logs). Current
state is computed by `/context-restore` folding the logs (last-state-wins by
`#id`).

**How to save:** invoke `/context-save`. Routes via `INDEX.json` (no folder
scan); clear match → append; ambiguous → AskUserQuestion; no match → new topic
folder. First-ever v4 run bootstraps `INDEX.json` and should
`rebuild-index` to import existing topics.

**How to resume:** invoke `/context-restore`. Routes via `INDEX.json` only,
then dispatches **parallel sub-agents** that each fold one log and return a
capped digest — the main session never reads a raw `.log`. Related topics are
surfaced as pointers, folded only on opt-in. Init commands are offered, never
auto-run.

**Migration from v3/legacy:** existing v3 folders (with `context.md`, no
`meta.json`) are imported by `rebuild-index` as routable `format:"legacy-v3"`
rows. The first save/restore that touches one triggers a one-time lazy-convert
to the event-log layout; the original v3 files are never deleted.

