# Instruction Router Split — Design Spec

**Date**: 2026-05-20 (revised after /autoplan review + user clarification)
**Topic**: Convert monolithic `CLAUDE.md` + `AGENTS.md` into short router files + on-demand topic files in `instructions/`. **Drop accumulated lesson bullets** as part of the cut; capture continues into separate inbox files, promoted back into routers later by a future user-built hook.
**Reference**: [walkinglabs lecture 04 — "Why One Giant Instruction File Fails"](https://walkinglabs.github.io/learn-harness-engineering/en/lectures/lecture-04-why-one-giant-instruction-file-fails/)

---

## 1. Problem

Today's setup auto-loads ~580 lines of agent instructions on every turn:

| File | Lines | Bytes | Loaded on |
|---|---|---|---|
| `~/.claude/CLAUDE.md` → `biot-awesome-skills/CLAUDE.md` | 214 | 12.1K | every Claude Code turn |
| `biot-awesome-skills/AGENTS.md` (imported via `@AGENTS.md`) | 366 | 28.8K | every Claude Code turn |

Symptoms of "one giant file" anti-pattern:

- Token bloat on every turn — even trivial replies pay the full cost.
- No progressive disclosure — sections like "Git commit policy" load when the task has nothing to do with git.
- Drift risk — sections grow independently, accumulate contradictions silently.
- Hard to scope to a topic — finding the relevant rule requires re-reading the whole file.
- One stale `@RTK.md` import at bottom of `CLAUDE.md` pointing to a file that does not exist.
- Lesson bullets grew organically and now dominate the file. User wants a fresh start with a curated promotion model rather than a passive accumulation pile.

## 2. Goal

Adopt walkinglabs lecture 04's router pattern, with a deliberate lessons reset:

1. Keep `CLAUDE.md` and `AGENTS.md` short (~60–70 lines each).
2. Always-on content in router = critical non-negotiables only.
3. All reference material (policies, examples, skill lists) moves to `instructions/<topic>.md`, read on demand via the `Read` tool.
4. Router contains a routing table mapping topic → file path → "read when X" trigger.
5. **Existing lesson bullets are dropped** from routers (preserved in git history). The `pattern-observer.py` hook continues to capture new bullets, routing them to `instructions/lessons-captured-claude.md` and `instructions/lessons-captured-universal.md` as inbox sinks. A future user-built hook will classify captured lessons and promote only **critical/significant** ones back into routers as **file references** — never inline bullets.

## 3. Non-Goals

- Not rewriting any retained rule text — verbatim relocation only for the kept sections.
- Not changing the symlink chain (`~/.claude/CLAUDE.md` → `biot-awesome-skills/CLAUDE.md`).
- Not introducing a new agent file (`CODEX.md` etc.) in this change.
- Not building the future lesson-promotion hook here. That is a follow-up the user owns.
- Not preserving the 24+ accumulated lesson bullets in any topic file. Fresh start. (They remain available in git history.)

## 4. Target Structure

```
biot-awesome-skills/
├── CLAUDE.md                          # router (Claude-specific) — ~70 lines
├── AGENTS.md                          # router (vendor-neutral)  — ~60 lines
└── instructions/                      # NEW dir, topic files loaded on demand
    ├── commit-policy.md               # AGENTS § 1 verbatim
    ├── pr-policy.md                   # AGENTS § 2 verbatim
    ├── engineering-discipline.md      # AGENTS § 3 verbatim
    ├── context-save.md                # AGENTS § 4 verbatim
    ├── agent-delegation.md            # CLAUDE § 1 verbatim
    ├── operating-rules.md             # CLAUDE § 2 verbatim
    ├── gstack-skills.md               # CLAUDE gstack section verbatim
    ├── lessons-captured-claude.md     # NEW empty capture sink (pattern-observer writes here)
    └── lessons-captured-universal.md  # NEW empty capture sink (pattern-observer writes here)
```

Capture sinks are NOT referenced from routers. The agent does not auto-read them. A future user-built hook is the only path that promotes specific captured lessons back into routers as `instructions/<promoted-lesson>.md` file references.

**Total reduction**: ~580 lines auto-loaded today → ~130 lines auto-loaded after split.

## 5. Router Contract

Each router file MUST contain, in this order:

1. **One-line purpose statement** — what the file is, what it imports.
2. **Always-on section** — critical non-negotiables, expressed as one-liners.
3. **Routing table** — markdown table: `| Topic | File | Read when |`.
4. **Hook-sync note** — short reminder that edits under `hooks/`, this file, or any `instructions/` file must be committed + pushed to biot remote in the same turn.

The router MUST NOT contain examples, full policy text, or lesson bullets.

### 5.1 CLAUDE.md router — always-on rules

- Delegate to Opus 4.7 + xhigh on hard tasks; Sonnet 4.6 on easy tasks with Opus review when correctness matters.
- Never use any model other than {Opus 4.7, Sonnet 4.6} for delegated agents.
- Trust-but-verify all sub-agent output before acting on it.
- Hook + global-rule edits → commit + push to biot remote in same turn.
- Use `/browse` for all web browsing; never use `mcp__claude-in-chrome__*` directly.

### 5.2 CLAUDE.md router — routing table

| Topic | File | Read when |
|---|---|---|
| Agent delegation (model gates, trust/verify) | `instructions/agent-delegation.md` | About to spawn a sub-agent via the Agent tool |
| Operating rules (12) | `instructions/operating-rules.md` | Starting a non-trivial task — read once per session |
| gstack skills index | `instructions/gstack-skills.md` | Considering any `/gstack-*` or related skill invocation |

### 5.3 AGENTS.md router — always-on rules

- **Authorship**: NEVER add an AI assistant as `Co-Authored-By` or generator footer on any commit.
- **Five non-negotiables**: surface assumptions, stop when confused, push back when warranted, prefer boring, scope discipline.
- **Save trigger**: invoke `/context-save` before the final response after substantive work (code edit / decision / fix / refactor / finding). Skip for trivial replies, clarifying questions, read-only exploration.
- **Verification gate**: task is incomplete until tests pass, build succeeds, runtime behavior matches expectations, lint/type-check is clean.

### 5.4 AGENTS.md router — routing table

| Topic | File | Read when |
|---|---|---|
| Git commit policy | `instructions/commit-policy.md` | Composing any commit message |
| PR creation policy | `instructions/pr-policy.md` | Opening or updating a PR |
| Engineering discipline | `instructions/engineering-discipline.md` | Starting non-trivial work — read once per session |
| Context save policy | `instructions/context-save.md` | Before invoking `/context-save` |

## 6. Hook Impact

`hooks/pattern-observer.py` writes lesson capture prompts to the agent referencing target files. After the split, the target files are the new **capture sinks**, not the routers.

Required hook changes:

- `pattern-observer.py`:
  - `LESSONS_FILE_CLAUDE` → `~/Developer/biot-awesome-skills/instructions/lessons-captured-claude.md`
  - `LESSONS_FILE_UNIVERSAL` → `~/Developer/biot-awesome-skills/instructions/lessons-captured-universal.md`
  - Update **all** prose mentions of `CLAUDE.md` and `AGENTS.md` in the emitted agent prompt to the new sink filenames. (Audit lines 18–21 docstring, lines 33–37 routing comment, lines 192–198 prompt body, line 211 fallback prose. The "prefix match" claim from the prior spec draft was inaccurate — the hook does not parse headers in Python; it emits LLM instructions to append under a `## Lessons` heading. As long as each capture sink contains exactly one such heading, the LLM behavior is preserved.)
- `inject-checkpoint-reminder.sh` — update prose reference from `~/.claude/CLAUDE.md § "Context save policy"` to `biot-awesome-skills/instructions/context-save.md`. Preserve existing `/context-save` command name (no drift to `/context-save-rolling`).
- `skill-push-reminder.sh` — extend echo string to mention `instructions/` in addition to `CLAUDE.md`/`AGENTS.md`.

## 7. Migration Steps

1. Capture restore-point snapshots of `CLAUDE.md` and `AGENTS.md` to a `/tmp/` location and to `~/.gstack/projects/<slug>/`. Restore path is preserved in the plan file's restore-point comment.
2. Create `instructions/` directory and two empty capture sinks (`lessons-captured-claude.md` and `lessons-captured-universal.md`), each containing exactly one `## Lessons` heading so the hook's LLM-driven append finds its target.
3. For each retained topic, create the corresponding `instructions/<topic>.md` and copy the relevant section text **verbatim** from the source router. No content edits. Lessons sections are NOT extracted.
4. Rewrite `CLAUDE.md` to the router shape from § 5.1–5.2. Drop the stale `@RTK.md` import. Drop the entire `## Lessons (Claude-specific)` section.
5. Rewrite `AGENTS.md` to the router shape from § 5.3–5.4. Drop both `## Lessons (universal)` sections.
6. Update `hooks/pattern-observer.py` per § 6.
7. Update prose strings in `inject-checkpoint-reminder.sh` and `skill-push-reminder.sh` per § 6.
8. Smoke-test the hook: dispatch `correction_context()` (via `importlib.util`, since the filename is hyphenated and cannot be `import`-ed) and verify the emitted prompt names both new capture-sink files and contains no stale CLAUDE.md/AGENTS.md references. The hook itself never writes files — this test verifies prompt emission, not file mutation.
9. Atomic commit + push to biot remote. On commit-hook failure, restore from the snapshots taken in step 1 and re-attempt.

## 8. Acceptance Criteria

- `CLAUDE.md` ≤ 90 lines, contains no lesson bullets, no `@RTK.md`.
- `AGENTS.md` ≤ 80 lines, contains no lesson bullets.
- Every retained section heading from today's `CLAUDE.md` / `AGENTS.md` is reachable via the routing table.
- `instructions/lessons-captured-claude.md` and `instructions/lessons-captured-universal.md` exist with exactly one `## Lessons` heading each.
- `pattern-observer.py` emits paths pointing at the new capture sinks. Verified via `correction_context()` prompt-emission test — no occurrence of `biot-awesome-skills/CLAUDE.md` or `biot-awesome-skills/AGENTS.md` in the emitted prompt.
- All edits committed + pushed to biot remote in one atomic commit, with snapshot-based rollback path if commit-hooks fail.

## 9. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Sub-agent skips routing table → misses an on-demand rule (e.g., commit policy) | Always-on section in router covers the critical non-negotiables (authorship, save trigger, verification gate). Routing table failures degrade gracefully. |
| Dropping accumulated lesson bullets eliminates passive behavioral nudges they provided | Acknowledged trade-off. User direction: fresh start, then promote critical lessons back via the future hook as file references. Until that hook lands, the agent runs on routers + on-demand instructions only. |
| Hook regression — captures go to wrong file or land outside any `## Lessons` heading | Smoke test in migration step 8 confirms emitted prompt references new sinks. Each sink is seeded with exactly one `## Lessons` heading. |
| Pre-commit hook fails mid-migration | Snapshots captured in step 1. Step 9 includes restore + re-attempt branch. |
| Drift between router's always-on summary and the full topic file | Always-on lines are one-liners; topic file owns details. Reviewer verifies both align when editing either. |

## 10. Open Questions

None at spec time. Lessons direction confirmed by user. The future promotion hook is explicitly out of scope for this change.
