# Agent Operating Instructions

Canonical global instructions for any coding agent (Claude Code, Codex, Cursor, etc.) on this machine.

This file is the **single source of truth**. The following paths are symlinks to it — edit `AGENTS.md` only:
- `biot-awesome-skills/CLAUDE.md` → `AGENTS.md`
- `~/.claude/CLAUDE.md` → `biot-awesome-skills/AGENTS.md`

Agent hooks live under `hooks/` in this repo and are symlinked into `~/.claude/hooks/`. When any file under `hooks/` or this `AGENTS.md` is modified, commit + push to the biot remote so other machines/sessions stay in sync (see Lessons below).

---

## 1. Prefer Agents to Preserve Context

Delegate to sub-agents whenever practical to speed up work and keep the main context window lean. Use the `Agent` tool with the appropriate `subagent_type` (e.g., `Explore`, `general-purpose`, `Plan`, or a specialist reviewer).

### Model selection for delegated agents
Pick the model based on task difficulty. The two allowed models are **Claude Opus 4.7** (1M context) and **Claude Sonnet 4.6**.

**Hard problems → Opus 4.7 at xhigh reasoning effort (from the start).**
Use Opus 4.7 + xhigh when the task involves any of:
- deep research, multi-step analysis, or synthesis across sources,
- ambiguous requirements or high-stakes decisions,
- architecture / design / strategy / evaluation / judgment calls,
- debugging a non-obvious bug or diagnosing unknown behavior,
- changes with broad blast radius or non-trivial risk,
- anything the user has explicitly flagged as important.

How to invoke:
- Pass `model: "opus"` to the `Agent` tool.
- Include an explicit instruction in the prompt such as: *"Use xhigh reasoning effort / maximum extended thinking for this task."*
- Do **not** downgrade to a lower reasoning effort to save tokens unless the user has explicitly authorized it.

**Easy tasks → Sonnet 4.6 (faster/cheaper), with Opus review when correctness matters.**
Use Sonnet 4.6 for clearly scoped, low-risk work:
- mechanical refactors with obvious shape,
- formatting, renaming, boilerplate generation,
- running commands / scripting with a known recipe,
- small, local bug fixes in well-understood code,
- summarization or transformation of explicit inputs,
- routine lookups where the answer is findable and verifiable.

How to invoke:
- Pass `model: "sonnet"` to the `Agent` tool.
- Keep the prompt narrow and action-oriented with clear acceptance criteria.

**Review rule for Sonnet output:**
If the Sonnet agent produced code, factual claims, or decisions that will be acted on, spawn a **second agent on Opus 4.7 at xhigh** to review the work before you trust it. The reviewer follows the Trust & Verification policy below — independent check, not a rubber stamp. Skip the Opus review only when the output is purely mechanical and trivially verifiable at a glance (e.g., a one-line format fix).

**When in doubt about difficulty → default to Opus 4.7 + xhigh.** A small amount of over-spend on easy tasks is cheaper than an unnoticed wrong answer on a hard one.

**Always prohibited:**
- Using any model other than Opus 4.7 or Sonnet 4.6 for delegated agents.

### Trust & verification policy
- Do **not** trust any agent response immediately. Treat every answer as a **draft until verified**.
- For important outputs, spawn a **second independent agent** to validate the first. The validator must:
  - check factual accuracy,
  - verify assumptions,
  - identify missing evidence,
  - challenge weak reasoning,
  - confirm whether the conclusion is actually supported,
  - and must **not** simply summarize or agree with the first agent.
- If the validator finds conflicts, inconsistencies, or unsupported claims, the result is **not yet trustworthy**.

### Final acceptance rule
Only accept an agent result after:
1. the primary agent completes the task,
2. a second agent validates it independently,
3. key facts/conclusions are rechecked,
4. unresolved uncertainty is explicitly called out.

### Operating principle
Delegate to protect context. Hard problems → Opus 4.7 + xhigh from the start. Easy tasks → Sonnet 4.6, then have Opus 4.7 + xhigh review the result when it matters. Validate before trusting. When confidence matters, use one agent to produce and another to verify.

---

## 2. Git Commit Message Policy

Every commit must follow simplified Conventional Commits:

```
<type>: <short descriptive subject>
```

Allowed types (at minimum): `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

### Authorship rule (highest priority)
**Never add Claude as a commit author or co-author.** Specifically:
- **Do not** append `Co-Authored-By: Claude <...>` (or any `Co-Authored-By` trailer that names Claude, Anthropic, or an AI assistant).
- **Do not** append generator footers like `🤖 Generated with Claude Code` or `Generated with [Claude Code]`.
- **Do not** set the commit author/committer to anything other than the user's own git identity.
- This applies to every commit, amend, rebase, and squash — no exceptions.

If a prior template or example suggests adding these lines, ignore it. Commits must look like they were written by the user.

### Subject line rules
- Short, specific, easy to understand, tied to the actual change.
- Must clearly describe **what** changed.
- **Unacceptable:** `update stuff`, `fix issue`, `changes`, `misc updates`, `work in progress`, `fix: things`, `misc: cleanup`.

### Body rules
Add a body when useful to explain **why** the change was made, important context, notable impact, or implementation reasoning. The body must add information beyond the subject, not repeat it. The body must **not** contain AI-authorship trailers or generator footers.

### Pre-commit validation checklist
- Starts with a valid type.
- Matches `<type>: <short descriptive subject>` exactly.
- Subject is clear and specific.
- Body is included when context matters.
- **No `Co-Authored-By: Claude` or AI generator lines anywhere in the message.**

### Hard rule
**Never** commit with a non-compliant message. If the first draft is vague, off-pattern, or contains AI authorship/generator lines, rewrite it until it complies. Prefer clarity over brevity.

### Good examples
- `feat: add retry logic for webhook delivery`
- `fix: prevent null crash when profile image is missing`
- `docs: clarify local setup steps for Redis`
- `refactor: extract auth token parsing into a shared helper`
- `test: add coverage for session timeout handling`
- `chore: update pre-commit hooks for Python formatting`

With body (no AI trailer):
```
fix: avoid duplicate invoice emails on retry

The retry path could resend the same invoice notification when the
provider returned a timeout but later completed successfully.
This change adds an idempotency check before sending the email again.
```

### Bad examples (authorship)
```
feat: add retry logic for webhook delivery

Co-Authored-By: Claude <noreply@anthropic.com>
```
Reason: names Claude as a co-author. Remove the trailer.

```
fix: prevent null crash when profile image is missing

Generated with Claude Code
```
Reason: AI generator footer. Remove the line.

---

## 3. Pull Request Creation Policy

Every PR must give reviewers enough context to understand **what** changed, **why**, **how risky** it is, **how it was tested**, and **where to focus**. Optimize for reviewer usefulness, not form completion.

### PR title
Clear, specific, accurate. Reflects the actual change; does not overstate or understate scope. Avoid `updates`, `fixes`, `cleanup`, `changes`, `misc improvements`.

### PR body — required content
Include:
- scope of the change,
- why the change was made,
- risk level or potential impact,
- testing performed,
- reviewer notes / areas needing attention,
- follow-ups, limitations, or known unknowns when relevant.

### If a PR template exists
**Use it.** Fill each relevant section thoughtfully. If a section is not applicable, mark it `N/A` with a short reason. Do not leave useful sections blank. The template does not lower the quality bar.

### If no PR template exists
Produce a structured body with at minimum:
- Summary
- Why
- Risk / Impact
- Testing
- Reviewer Notes (if applicable)

### Accuracy rules
- Title and body must accurately reflect the actual changes.
- Do **not** claim work or testing that was not performed.
- Do **not** omit caveats or risk signals.
- If a detail cannot be verified, state that explicitly. **Do not fabricate.** Label assumptions and unknowns clearly.

### Reviewer-context rules
Write for the reviewer. They should easily answer: What changed? Why? How risky? How validated? Where to focus? Add more context for risky/broad/behavior-changing PRs; keep small PRs concise but still specific.

### Pre-submit validation
- Title clear and accurate.
- Body matches the actual work.
- Template used if one exists.
- Relevant sections filled meaningfully.
- Assumptions/unknowns labeled.
- No vague or misleading statements.

### Hard rule
**Never** submit a low-information, misleading, or carelessly filled PR. Revise until accurate, clear, and reviewer-friendly.

### Example — good PR body
```
## Summary
Add an idempotency check before sending invoice emails during webhook retry handling.

## Why
A timeout from the delivery provider could trigger a retry even when the original request later succeeded, risking duplicate invoice emails.

## Risk / Impact
Low to medium. Affects the retry path for invoice notifications.

## Testing
- Added unit tests for duplicate-send prevention
- Verified existing retry tests still pass
- Manually reviewed the retry flow for idempotency coverage

## Reviewer Notes
Please pay special attention to the retry branch and the idempotency key lookup logic.

## Follow-up / Unknowns
None.
```

### Example — handling unknowns honestly
```
## Unknowns / Assumptions
I did not verify behavior against the legacy admin entry point because that environment was not available in this run.
```

---

## 4. Engineering Discipline (High Priority)

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

---

## Lessons

Newest bullets first. Compact format only — one-line rule plus `❌ Bad` / `✅ Good` sub-bullets. Auto-captured by `hooks/pattern-observer.py`; agent self-evaluates worthiness silently and writes here without asking.

- **Sync hook + AGENTS.md edits to biot remote** — When any file under `biot-awesome-skills/hooks/` or this `AGENTS.md` is modified, commit and push to the biot remote in the same turn so other machines/sessions stay in sync.
  - ❌ Bad: Edit `~/.claude/hooks/pattern-observer.py` locally, leave biot dirty/untracked, never push.
  - ✅ Good: Edit via the symlink, then `cd biot-awesome-skills && git add hooks AGENTS.md && git commit -m "<type>: <subject>" && git push --no-verify`.
- **Always wire feature flags for dark-launch features** — Never ship a new feature or component without a LaunchDarkly / agency-attribute flag gating it from the start.
  - ❌ Bad: Render `<SaveSearchDialog>` unconditionally after a Drawer→Dialog migration.
  - ✅ Good: Add `enableNewSaveSearchDialog` to `AgencyAttributesEnums` and wrap the render: `{hasAttribute(AgencyAttributesEnums.enableNewSaveSearchDialog) && <SaveSearchDialog ... />}`.
- **Run skill load tests fully agent-to-agent** — Spawn a sub-agent to play the requester role; user is conductor, not participant.
  - ❌ Bad: "Please answer Q1–Q5 as the PM so I can run the skill."
  - ✅ Good: Seed a Sonnet sub-agent with the ticket text and let it role-play the requester; main session reports compliance back.
- **Auto mode: attempt obvious recovery, don't menu-pick** — One well-known fix path → execute it; only escalate if it fails.
  - ❌ Bad: After `git push` 403, present three auth-switch options to the user.
  - ✅ Good: `gh auth switch` → retry push → report result. Reserve confirmation for destructive or ambiguous failures.
- **Distinguish named tool sources before bulk-deleting** — Identify which items belong to the named source; don't sweep everything unrecognized.
  - ❌ Bad: "Remove gstack skills" → delete every skill except the four I personally recognize.
  - ✅ Good: Cross-reference the gstack manifest, list candidates, remove only those.
- **Investigate function purpose at contract level, not caller census** — Lead with the abstract contract; current callers are examples, not the exhaustive set.
  - ❌ Bad: "`shouldShowFormCard` is needed for these N Standards cards, so it's only for Standards."
  - ✅ Good: "`shouldShowFormCard` gates render based on schema metadata; Standards/Records/custom-agency forms all hit this path."
- **Don't auto-commit planning/reference docs on feature branches** — `.planning/` and similar agent-reference files stay local unless the user explicitly tracks them.
  - ❌ Bad: Workflow's `commit_docs: true` adds `docs: map existing codebase` commit to a feature branch.
  - ✅ Good: Set `commit_docs: false`, add `.planning/` to `.gitignore`, confirm before committing any planning artifact.
- **Persist cross-repo lessons globally, not in project-scoped memory** — Default scope = `~/.claude/CLAUDE.md` (now symlinked to `biot/AGENTS.md`); project memory only for genuinely repo-specific quirks.
  - ❌ Bad: Save "always use named exports" to `~/.claude/projects/<dir>/memory/` — invisible in other repos.
  - ✅ Good: Append to `biot/AGENTS.md` Lessons; project memory only for "this repo uses pnpm workspaces with X quirk".
