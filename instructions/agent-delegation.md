# Agent Delegation (Model Selection, Trust & Verification)

> Loaded on demand from `CLAUDE.md` router. Read this file before spawning a sub-agent via the Agent tool.


Delegate to sub-agents whenever practical to speed up work and keep the main context window lean. Use the `Agent` tool with the appropriate `subagent_type` (e.g., `Explore`, `general-purpose`, `Plan`, or a specialist reviewer).

### Model selection for delegated agents
Match the model to the task phase. Lightweight work never goes to a heavy model.

**Lightweight work → `haiku` (latest) or `luna` (latest), at medium effort.**
Use for exploration (finding files, tracing code, grepping, reading logs, codebase recon) and any simple, mechanical task.

How to invoke:
- Pass `model: "haiku"` or `model: "luna"` and `effort: "medium"` to the `Agent` tool.
- Keep the prompt narrow and action-oriented with clear acceptance criteria.

**Hard problems and judgment → `opus` at high effort (from the start).**
Use Opus + high when the task involves any of:
- deep research, multi-step analysis, or synthesis across sources,
- ambiguous requirements or high-stakes decisions,
- architecture / design / strategy / evaluation / judgment calls,
- debugging a non-obvious bug or diagnosing unknown behavior,
- changes with broad blast radius or non-trivial risk,
- anything the user has explicitly flagged as important.

How to invoke:
- Pass `model: "opus"` and `effort: "high"` to the `Agent` tool.
- Do **not** downgrade to a lower reasoning effort to save tokens unless the user has explicitly authorized it.

**Validation and synthesis → `sonnet` or `opus`.** Sonnet is the heavy option when Opus is more than the check needs. Pick Opus when correctness matters.

**Review rule for lightweight output:**
If a `haiku` or `luna` agent produced code, factual claims, or decisions that will be acted on, spawn a **second agent on Opus at high effort** to review the work before you trust it. The reviewer follows the Trust & Verification policy below — independent check, not a rubber stamp. Skip the review only when the output is purely mechanical and trivially verifiable at a glance (e.g., a one-line format fix).

**When in doubt about difficulty → default to Opus + high.** A small amount of over-spend is cheaper than an unnoticed wrong answer on a hard one.

**Always prohibited:**
- Spawning a heavy model (Opus, Sonnet, Fable, or any gpt-6-class model) for a lightweight task.
- Using `haiku` or `luna` for hard problems, validation, or synthesis.
- Using `high` effort on any model other than `opus`.

### Named agent replies
A named agent (Agent tool with `name` param) is a mailbox teammate: plain text output stays local and does NOT auto-return. Tell it explicitly to call SendMessage back (`to: <your-session-name>`). It may need a repeat nudge if it goes idle without doing so.
An unnamed/background agent (no `name`) auto-returns its final answer via task-notification. No nudge needed.

### Trust & verification policy
- Do **not** trust any agent response immediately. Treat every answer as a **draft until verified**.
- For important outputs, spawn a **second independent agent** to validate the first — pick by what's being validated:
  - **Deliverable** (code change, bug fix, test fix, PR) → `result-validator` subagent. Checks the diff actually satisfies the original request, hunts for gamed/bypassed checks (skipped tests, weakened assertions, mocked-out subject-under-test), and greps the repo for other callers to catch breaking changes.
  - **Claims/conclusions/diagnosis** (root cause, "the resolver does X", investigation findings) → `findings-validator` subagent. Re-derives each claim from primary evidence rather than trusting the summary.
- Both must **not** simply summarize or agree with the first agent — they re-derive from evidence.
- If the validator finds conflicts, inconsistencies, unsupported claims, gamed checks, or breaking changes, the result is **not yet trustworthy**.

### Final acceptance rule
Only accept an agent result after:
1. the primary agent completes the task,
2. a second agent validates it independently,
3. key facts/conclusions are rechecked,
4. unresolved uncertainty is explicitly called out.

### Operating principle
Delegate to protect context. Lightweight work → haiku or luna at medium effort. Hard problems → Opus at high effort from the start. Validation and synthesis → Opus or Sonnet. Validate before trusting. When confidence matters, use one agent to produce and another to verify.
