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

## 2. Twelve Operating Rules

These rules apply to every task in this project unless explicitly overridden.
Bias: caution over speed on non-trivial work. Use judgment on trivial tasks.

### Rule 1 — Think Before Coding
State assumptions explicitly. If uncertain, ask rather than guess.
Present multiple interpretations when ambiguity exists.
Push back when a simpler approach exists.
Stop when confused. Name what's unclear.

### Rule 2 — Simplicity First
Minimum code that solves the problem. Nothing speculative.
No features beyond what was asked. No abstractions for single-use code.
Test: would a senior engineer say this is overcomplicated? If yes, simplify.

### Rule 3 — Surgical Changes
Touch only what you must. Clean up only your own mess.
Don't "improve" adjacent code, comments, or formatting.
Don't refactor what isn't broken. Match existing style.

### Rule 4 — Goal-Driven Execution
Define success criteria. Loop until verified.
Don't follow steps. Define success and iterate.
Strong success criteria let you loop independently.

### Rule 5 — Use the model only for judgment calls
Use me for: classification, drafting, summarization, extraction.
Do NOT use me for: routing, retries, deterministic transforms.
If code can answer, code answers.

### Rule 6 — Token budgets are not advisory
Per-task: 4,000 tokens. Per-session: 30,000 tokens.
If approaching budget, summarize and start fresh.
Surface the breach. Do not silently overrun.

### Rule 7 — Surface conflicts, don't average them
If two patterns contradict, pick one (more recent / more tested).
Explain why. Flag the other for cleanup.
Don't blend conflicting patterns.

### Rule 8 — Read before you write
Before adding code, read exports, immediate callers, shared utilities.
"Looks orthogonal" is dangerous. If unsure why code is structured a way, ask.

### Rule 9 — Tests verify intent, not just behavior
Tests must encode WHY behavior matters, not just WHAT it does.
A test that can't fail when business logic changes is wrong.

### Rule 10 — Checkpoint after every significant step
Summarize what was done, what's verified, what's left.
Don't continue from a state you can't describe back.
If you lose track, stop and restate.

### Rule 11 — Match the codebase's conventions, even if you disagree
Conformance > taste inside the codebase.
If you genuinely think a convention is harmful, surface it. Don't fork silently.

### Rule 12 — Fail loud
"Completed" is wrong if anything was skipped silently.
"Tests pass" is wrong if any were skipped.
Default to surfacing uncertainty, not hiding it.

> **Note on overlap:** Rules 1, 2, 3 reinforce the Five Non-Negotiables in `AGENTS.md` § 3 (Surface assumptions, Stop when confused, Push back, Prefer boring, Scope discipline). Treat both as authoritative; on conflict, the stricter reading wins.

---

## gstack

gstack is installed at `~/.claude/skills/gstack`. Use its `/browse` skill for **all** web browsing. **Never** use `mcp__claude-in-chrome__*` tools — `/browse` replaces them.

Available gstack skills:

- `/office-hours`
- `/plan-ceo-review`
- `/plan-eng-review`
- `/plan-design-review`
- `/design-consultation`
- `/design-shotgun`
- `/design-html`
- `/review`
- `/ship`
- `/land-and-deploy`
- `/canary`
- `/benchmark`
- `/browse`
- `/connect-chrome`
- `/qa`
- `/qa-only`
- `/design-review`
- `/setup-browser-cookies`
- `/setup-deploy`
- `/setup-gbrain`
- `/retro`
- `/investigate`
- `/document-release`
- `/codex`
- `/cso`
- `/autoplan`
- `/plan-devex-review`
- `/devex-review`
- `/careful`
- `/freeze`
- `/guard`
- `/unfreeze`
- `/gstack-upgrade`
- `/learn`

---

## Lessons (Claude-specific)

Newest bullets first. Compact format — one-line rule plus `❌ Bad` / `✅ Good` sub-bullets. Captured automatically by `hooks/pattern-observer.py`. Examples must be generic (no project codenames, ticket IDs, internal artifacts). If a lesson is genuinely agent-neutral (no `~/.claude/*` paths, no Claude-specific models or tools, no `Agent`-tool semantics), promote it to `AGENTS.md` Lessons instead.

- **Mirror personal skills across all agent skill dirs** — When installing or removing a personal skill, symlink (or remove) it in every agent's skill directory in the same turn, not just Claude Code's. Codex lives at `~/.agents/skills/`, Claude Code at `~/.claude/skills/`. Keeping them symmetric means the same `/skill-name` works no matter which agent the user opens next; missing one half silently regresses the other agent.
  - ❌ Bad: `ln -s <repo>/<skill> ~/.claude/skills/<skill>` only, then call the install done.
  - ✅ Good: Symlink into both `~/.claude/skills/<skill>` *and* `~/.agents/skills/<skill>` in the same commit; remove from both when retiring.
- **Statusline context limit: read JSON field per-update, don't hardcode** — Claude Code's statusline JSON exposes `.context_window.context_window_size` per model variant (1M for Opus 4.7 `[1m]`, 200K for Sonnet 4.6, etc.). Read it dynamically so the bar auto-recalibrates when switching models mid-session. Compute `total_input_tokens * 100 / context_window_size`; fall back chain: JSON field → `CC_CONTEXT_LIMIT` env → 200K default. Avoid `.context_window.used_percentage` directly — historically lagged.
  - ❌ Bad: `CTX_LIMIT=200000` hardcoded → bar wrong by 5× when user switches to a 1M-context model.
  - ✅ Good: `ctx_size=$(jq -r '.context_window.context_window_size // empty')` then `CTX_LIMIT="${ctx_size:-${CC_CONTEXT_LIMIT:-200000}}"`.
- **Restrict "use MCP" investigations to server/API MCPs first** — When user asks to "use MCP" to trace/debug, default to log/DB/API MCPs (Splunk, Grafana, Jira, T3). Do not silently fall back to browser-automation MCPs (Chrome) when those fail; surface the blocker (e.g. VPN) and wait for the user to unblock.
  - ❌ Bad: Splunk DNS fails -> spin up Chrome MCP and scrape data through a logged-in browser tab.
  - ✅ Good: Splunk DNS fails -> tell user "Splunk unreachable, need VPN" and pause until they reconnect.
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

@RTK.md
