# Claude Code Operating Instructions

Claude-specific layer on top of the agent-neutral baseline. The baseline is loaded via the import below — read it as if inlined here.

@AGENTS.md

`~/.claude/CLAUDE.md` is a symlink to this file. Edit this file; the symlink follows. Anything truly agent-neutral belongs in `AGENTS.md`, not here.

Hooks live under `hooks/` in this repo and are symlinked into `~/.claude/hooks/`. When any file under `hooks/`, this file, or `AGENTS.md` is modified, commit + push to the biot remote in the same turn so other machines/sessions stay in sync.

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

## Lessons (Claude-specific)

Newest bullets first. Compact format — one-line rule plus `❌ Bad` / `✅ Good` sub-bullets. Captured automatically by `hooks/pattern-observer.py`. Examples must be generic (no project codenames, ticket IDs, internal artifacts). If a lesson is genuinely agent-neutral (no `~/.claude/*` paths, no Claude-specific models or tools, no `Agent`-tool semantics), promote it to `AGENTS.md` Lessons instead.

- **Sync hook + global rule edits to biot remote** — When any file under `biot-awesome-skills/hooks/`, this `CLAUDE.md`, or `AGENTS.md` is modified, commit and push to the biot remote in the same turn.
  - ❌ Bad: Edit `~/.claude/hooks/<some-hook>.py` locally, leave biot dirty/untracked, never push.
  - ✅ Good: Edit via the symlink, then `cd biot-awesome-skills && git add hooks AGENTS.md CLAUDE.md && git commit -m "<type>: <subject>" && git push --no-verify`.
- **Run skill load tests fully agent-to-agent, never make the user the requester** — Spawn a sub-agent to play the requester role; user is conductor, not participant.
  - ❌ Bad: "Please answer Q1–Q5 as `<role>` so I can run the skill."
  - ✅ Good: Seed a Sonnet sub-agent with the source artifact and let it role-play `<role>`; main session reports compliance back.
- **Auto mode: attempt obvious recovery, don't menu-pick** — One well-known fix path → execute it; escalate only if it fails. Reserve confirmation for destructive or ambiguous failures.
  - ❌ Bad: A push fails with an auth mismatch; present three auth-switch options to the user.
  - ✅ Good: `gh auth switch` → retry push → report result.
- **Persist cross-repo lessons globally, not in project-scoped memory** — Default scope = `~/.claude/CLAUDE.md` (symlinked to `biot/CLAUDE.md`); project memory only for genuinely repo-specific quirks.
  - ❌ Bad: Save a global preference to `~/.claude/projects/<dir>/memory/` — invisible from other repos.
  - ✅ Good: Append to `biot/CLAUDE.md` Lessons (or `biot/AGENTS.md` if agent-neutral); project memory only for `<repo>`-specific quirks.
