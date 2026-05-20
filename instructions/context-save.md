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

**Layout (v3, topic-snapshot folders):**
```
~/.gstack/projects/<slug>/checkpoints/
  YYYY-MM-DD_HHMMSS-<topic-slug>/
    context.md          # ≤500 lines, routing + summary
    DECISIONS.md        # full decision log (carry-forward + new)
    PROGRESS.md         # done / in-progress / open / blocked + session log
    RESULTS.md          # test outputs, validations, command results
    artifacts/          # optional: logs/ patches/ research/ snapshots/
```

Each save creates a NEW timestamped snapshot folder. The skill matches
the current session to an existing topic automatically (across
branches and commits) and carries forward decisions / progress /
results / notes verbatim. Restore picks the latest folder per topic.

**How to save:** invoke the `/context-save` skill. Topic
match is automatic; if the match is genuinely ambiguous the skill
will AskUserQuestion. Otherwise it merges silently.

**How to resume:** invoke `/context-restore`. It scores
candidate topics against the current task signal (summary +
keywords + branch + recency), auto-loads when the winner is clear,
and AskUserQuestions when ambiguous. Sibling files (DECISIONS /
PROGRESS / RESULTS / artifacts) are lazy-loaded only after you opt
in — `context.md` alone is read by default.

Legacy single-file gstack checkpoint audits and v2 rolling
`CURRENT-<topic-slug>.md` files are still readable by restore as
fallbacks; new saves always write the v3 folder layout. Legacy files
are never deleted by the save flow.

