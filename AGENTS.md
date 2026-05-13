# Agent Operating Instructions (Universal)

Instructions for **any** coding agent (Claude Code, Codex, Cursor, etc.) working on this machine.

This file holds **agent-neutral** rules only. Anything tied to a specific agent's tooling, models, file paths, or hook system lives in a matching companion file (`CLAUDE.md`, future `CODEX.md`, etc.) which `@`-imports this one.

Keep this file portable. If you find yourself typing `Opus`, `Sonnet`, `Anthropic`, `~/.claude/...`, `Agent` tool, or any other vendor-specific term — it does not belong here. Move it to the relevant companion file.

---

## 1. Git Commit Message Policy

Every commit must follow simplified Conventional Commits:

```
<type>: <short descriptive subject>
```

Allowed types (at minimum): `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

### Authorship rule (highest priority)
**Never add the AI assistant as a commit author or co-author.** Specifically:
- **Do not** append any `Co-Authored-By` trailer that names an AI assistant or vendor (e.g. Claude, Anthropic, GPT, OpenAI, Copilot, Cursor, Codex).
- **Do not** append generator footers (e.g. `🤖 Generated with <tool>`, `Generated with [<tool>]`).
- **Do not** set the commit author/committer to anything other than the user's own git identity.
- Applies to every commit, amend, rebase, and squash — no exceptions.

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
- **No AI `Co-Authored-By` trailer or generator footer anywhere in the message.**

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

Co-Authored-By: <AI assistant name> <noreply@example.com>
```
Reason: names an AI assistant as co-author. Remove the trailer.

```
fix: prevent null crash when profile image is missing

🤖 Generated with <AI tool>
```
Reason: AI generator footer. Remove the line.

---

## 2. Pull Request Creation Policy

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

## 3. Engineering Discipline (High Priority)

These principles govern how you approach every task. They are non-negotiable — apply them before, during, and after all work.

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

## Lessons (universal)

- **Code-walk anchors: absolute path + `:line` for cmd-click** — When introducing a quoted source code block in a response, the inline anchor must be a bare absolute path with a single-line suffix (`:N`) inside backticks, placed directly above the fenced block, so terminal-to-IDE handoffs (cmd-click in iTerm2/Warp/Terminal → VSCode/Cursor/Neovim) jump to the right place. No range syntax (`:N-M` does not parse), no markdown link wrapping (`[label](file://...)` is ignored by terminals). Range info is preserved visually by the quoted lines themselves.
  - ❌ Bad: `` `<repo>/<subpath>/<file>:172-176` `` (relative path, range syntax) followed by fenced block — not clickable.
  - ✅ Good: `` `/<absolute>/<repo>/<subpath>/<file>:172` `` directly before fenced block; range shown by the quoted code.
- **Show concrete I/O examples for complex transforms, not just logic prose** — When walking through a function that transforms / walks / fans out / composes / serializes data, attach a minimal realistic `Input → Output` example after the prose summary. Logic prose alone is slow to reason about; shapes are fast. Trigger when input shape ≠ output shape, recursion / tree walk, ≥2 branches with structurally different returns, joining multiple sources, or any non-obvious filtering/grouping. Use realistic fixtures (tests, sample payloads); never fabricate — write `UNKNOWN: <shape>` instead.
  - ❌ Bad: "`<some-walker>` recurses through the schema, accumulating fields that pass `<predicate>` and skipping the rest." (No shapes shown.)
  - ✅ Good: After the prose, attach `Input: <minimal schema fragment>` and `Output: <resulting columns/rows array>` in a fenced block so the reader sees the transform.
- **Code-walk default shape: quote + narrate + inline callees, no orphan refs** — When the user signals "walk me through", "explain how X works", "trace the flow", or "I won't open my IDE", default response is: quote the actual code verbatim in fenced blocks, narrate every non-trivial line in plain English, recursively inline every in-codebase callee until a framework/stdlib leaf, enumerate every branch arm, and never volunteer git history or "where to modify" unless the user asked.
  - ❌ Bad: "`<some-helper>` is called at `<file>:<line>` — see the file for details", then move on without quoting `<some-helper>`'s body.
  - ✅ Good: Quote the caller, narrate it, then immediately quote `<some-helper>`'s body and narrate that, then continue.
- **Skills stay domain-neutral unless their title scopes them** — A reusable skill must work for any codebase / stack unless its name and description explicitly scope to one (`<some-stack>-dev`, etc.). Use generic placeholders (`<repo>`, `<service>`, `<helper>`) in examples, tables, and templates; never bake real product names, ticket IDs, partner identifiers, or in-house tool names into the skill body.
  - ❌ Bad: Skill example table shows `<RealProductFrontend> → <RealProductGateway> → <RealProductBackend>` as the canonical hop pattern.
  - ✅ Good: Skill example table shows `<client-repo> → <api-repo> → <service-repo>` with generic placeholders; concrete instances go in the user's response, not in the skill.
- **Scope research to the named ticket, not the whole domain** — When the user references a specific ticket, fetch it first and scope the walkthrough to only the entities/fields/endpoints the ticket touches; do not expand into the broader domain unless asked.
  - ❌ Bad: User says "scoped to `<TICKET-ID>`" → continue producing a full domain tour of unrelated subsystems.
  - ✅ Good: Fetch `<TICKET-ID>`, extract its concrete scope, then re-frame the walkthrough strictly around those entities and explicitly mark adjacent topics as out-of-scope.
- **Use realistic fixtures before invented complexity** — When a real sample payload or schema exists, base the test on that shape and add only the complexity needed to prove behavior.
  - ❌ Bad: Test `<some-helper>` with invented nested fields that do not exist in the sample data.
  - ✅ Good: Test `<some-helper>` with the sample payload's real paths, nested arrays, ids, and untouched values.

Agent-neutral lessons. Newest first. Compact format — one-line rule plus `❌ Bad` / `✅ Good` sub-bullets. If a captured lesson references a specific agent's tooling, paths, or models, it belongs in that agent's companion file (e.g. `CLAUDE.md`), not here.

- **Separate remote services from local build failures** — When a local compile fails while pointing at a remote service, explain that the service only supplies runtime/API data unless evidence shows it changed local module resolution.
  - ❌ Bad: "Remote `<service-env>` must be broken because local `<frontend-app>` cannot compile."
  - ✅ Good: "Local `<frontend-app>` compile is failing in module resolution; `<service-env>` is only the API endpoint unless network/schema generation failed."
- **Explain semantic fault before code proof** — When reviewing a design or mapping bug, state the domain-level mistake in user terms before citing implementation details.
  - ❌ Bad: "Line `<n>` compares `<child-path>` to `<parent-path>`, so the matcher returns false."
  - ✅ Good: "`<ChildField>` should stay inside `<ParentSection>`; the current model treats it as a separate selectable section."
- **Separate proposed changes from baseline truth** — When evidence comes from a dirty branch or unmerged work, describe it as proposed/current-branch behavior, not established product or mainline behavior.
  - ❌ Bad: "`<field-a>` surely maps to `<field-b>` because the current branch adds that mapping."
  - ✅ Good: "Current branch proposes `<field-a>` -> `<field-b>`; verify mainline or product approval before treating it as certain."
- **Use generic examples in lesson bullets** — Bad/good illustrations stay pattern-level; never name project codenames, ticket IDs, partner/agency names, or internal artifacts. If the rule needs a domain artifact to make sense, it is too project-specific for this file — move it to that project's `CLAUDE.md`.
  - ❌ Bad: `Render <SaveSearchDialog> unconditionally; flag enum is AgencyAttributesEnums.enableNewSaveSearchDialog.`
  - ✅ Good: `Render <SomeFeatureDialog> unconditionally; gate behind <some-feature-flag> from the start.`
- **Always wire feature flags for dark-launch features** — Never ship a new user-visible feature without a flag (LaunchDarkly / config attribute / equivalent) gating it from the start.
  - ❌ Bad: Land `<SomeNewDialog>` unconditionally after a UI migration; cleanup deferred.
  - ✅ Good: Introduce `<some-feature-flag>` and wrap the render: `{hasFlag('<some-feature-flag>') && <SomeNewDialog ... />}`.
- **Distinguish named tool sources before bulk-deleting** — When asked to remove items belonging to a specific source, enumerate only that source's items; do not sweep everything unrecognized.
  - ❌ Bad: "Remove `<source-x>` plugins" → delete every plugin except the few personally recognized.
  - ✅ Good: Cross-reference `<source-x>`'s manifest, list candidates, remove only those.
- **Investigate function purpose at contract level, not caller census** — Lead with the abstract contract / invariant; current callers are examples, not the exhaustive set.
  - ❌ Bad: "`<helperFn>` is only used by `<KnownCallerA>` and `<KnownCallerB>`, so it exists only for that case."
  - ✅ Good: "`<helperFn>` enforces `<invariant>` over its input; current callers are examples — other call sites with the same shape may rely on it too."
- **Don't auto-commit planning / scratch docs on feature branches** — Agent-reference artifacts stay local unless the user explicitly tracks them, even if a workflow's default config says to commit.
  - ❌ Bad: Workflow's `commit_docs: true` lands a `docs: <generic title>` commit on a feature branch.
  - ✅ Good: Set `commit_docs: false`, add scratch dir to `.gitignore`, confirm before committing any planning artifact.
