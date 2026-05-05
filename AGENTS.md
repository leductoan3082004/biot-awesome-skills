# Agent Operating Instructions

Shared instructions for any coding agent working in this repository (Claude Code, Codex, Cursor, etc.).

`CLAUDE.md` is a symlink to this file so Anthropic-specific tooling and cross-agent tooling read the exact same rules. Edit `AGENTS.md` — `CLAUDE.md` follows automatically.

---

## Engineering Discipline (High Priority)

These principles govern how you approach every task. They are non-negotiable — apply them before, during, and after all work. Sourced from battle-tested agent workflow patterns.

### Anti-rationalization

Before skipping any process step, check this table. If your reasoning matches the left column, you are rationalizing — do the right column instead.

| Thought | Reality |
|---------|---------|
| "This is just a simple change" | Simple changes break things. Follow the process. |
| "I know what the bug is, I'll just fix it" | Reproduce first. You're right 70% of the time; the other 30% costs hours. |
| "I'll test it all at the end" | Bugs compound. A bug in step 1 makes steps 2–5 wrong. Test each slice. |
| "It's faster to do it all at once" | It *feels* faster until something breaks and you can't find which of 500 changed lines caused it. |
| "The failing test is probably wrong" | Verify that assumption. If the test is wrong, fix it. Don't skip it. |
| "I'll add the feature flag later" | If the feature isn't complete, it shouldn't be user-visible. Add the flag now. |
| "Let me just quickly add this too" | Scope creep. Finish the current task first. |
| "I need more context first" | Skills and workflows tell you HOW to gather context. Follow them. |
| "This doesn't need a formal process" | If a workflow exists for it, use it. |

### Process over prose

Workflows with concrete steps and checkpoints beat reference essays. When approaching any non-trivial task:

1. **Pick the workflow** — match task → reference file or skill.
2. **Follow the steps in order** — don't skip verification steps.
3. **Hit every checkpoint** — a step isn't done until its verification passes.
4. **Chain workflows** — a bug fix might need: debugging → test-driven → code-review, in sequence.

### Verification as hard exit criterion

A task is **not complete** until verification passes. "Seems right" is never sufficient.

- Tests pass (not just "I think they'd pass").
- Build succeeds (not just "it should build").
- Runtime behavior matches expectations (not just "the code looks correct").
- Lint/type-check clean.

If you cannot verify, say so explicitly — do not claim completion.

### Progressive disclosure

Load only the context you need, when you need it. Don't front-load everything.

- Match the task to the right reference file/skill, then read only that.
- Don't read every reference file at session start.
- Delegate to sub-agents to keep the main context window lean.

### Five non-negotiables

These apply at all times, across all tasks:

1. **Surface assumptions** — Before building anything non-trivial, state your assumptions explicitly. Wrong silent assumptions are the most common failure mode.
2. **Stop when confused** — Don't guess through ambiguity. Name the confusion, ask, wait. Plowing ahead when lost wastes everyone's time.
3. **Push back when warranted** — Sycophancy is a failure mode. "Of course!" followed by implementing a bad idea helps no one. Point out problems directly, propose alternatives, accept override with full information.
4. **Prefer boring** — Ask: can this be done in fewer lines? Would a staff engineer say "why didn't you just..."? Three similar lines > premature abstraction. Naive obviously-correct version > clever fragile version.
5. **Scope discipline** — Touch only what the task requires. No drive-by refactors, no unsolicited cleanup, no "while I'm here" changes. If you notice something worth improving outside scope, note it — don't fix it.
