---
name: estimating-tasks
description: Use when user asks to estimate effort, size a ticket, or commit to a timeline. Triggers on "estimate this", "how long will X take", "size this ticket", "effort estimate", "work days for", "give me a timeline", "ticket sizing", "scoping", or before committing to sprint deadlines.
---

# Estimating Tasks

## Overview

Produce defensible work-day estimates by drafting multiple solutions, picking the **worst-case** subtotal among them, then buffering 30–40% for unknowns. Never assume scope — clarify with the user, or close the gap by reading docs/code.

**Core principle:** A safe overestimate beats a missed deadline. Pick the worst feasible solution's cost and pad it.

**Work day = 5 productive hours.** Not 8. Accounts for meetings, reviews, breaks, context switching.

## When to Use

- User asks "how long will this take?"
- Sizing a Jira / Linear / GitHub ticket
- Sprint planning, capacity estimates
- Committing to a deadline
- Comparing solution trade-offs by cost

## When NOT to Use

- One-line fixes, mechanical refactors (just do them)
- Pure exploration with no deliverable
- User explicitly says "rough ballpark, no rigor needed" before scope is clear — ask for scope first; Light Mode only applies after scope is clear

## Process — Rigid. Follow In Order.

This is a **discipline skill**. No shortcuts. Each step has a hard exit criterion. Skipping a step invalidates the estimate.

## Unclear Scope Response — Mandatory

If the request is vague, missing the ticket/link, missing acceptance criteria, or asks you to "just assume" scope, **do not estimate**.

Allowed output only:

```
I can't estimate this yet because the scope is not locked.

Need one of:
- ticket/link or acceptance criteria
- expected behavior and current behavior
- affected repo/service boundary

After that I can estimate with solution options, tests, regression budget, and buffer.
```

Forbidden:

- giving a "quick number"
- saying "assuming normal flow"
- treating pressure as permission to guess
- offering Light Mode before scope is clear
- replacing the missing scope with prior memory

### Step 1 — Scope Lock. Zero Assumptions.

Read the ticket / request fully. Before estimating anything, write out:

- User-facing outcome
- Systems / services touched
- Inputs and outputs
- Acceptance criteria — what does "done" look like
- Hard constraints (deadline, dependency, agency-specific behavior)
- Critical-path? (auth, payments, billing, data integrity, shared component) → regression budget required

**If ANY item above is unclear → STOP. Ask the user. Do not provide a work-day number.**

Do not guess. Do not pick "the most likely interpretation." Do not invent acceptance criteria.

User pressure does not weaken this rule. If the user says "I need the number now", "just assume", "normal flow", or "roughly", answer with the blocking question(s), not an estimate.

If user unavailable, close the gap by reading: linked Jira/Linear, design docs (Quip/Confluence), related code, prior PRs. Only after exhausting these may you proceed with explicitly-labeled assumptions — and you MUST surface them in the final output.

**Exit criterion:** Written scope statement. All open questions either answered by user or backed by a cited doc/code reference.

### Step 2 — Deep Understanding. Required.

Invoke one of:
- `deep-investigate` — bugs, broken behavior, hard / unknown problems
- `deep-understand` — new feature area, unfamiliar code, architectural questions

Goal: understand the **whole** problem — data flow, side effects, callers, integration points, edge cases. Not just the surface.

Skipping this is the #1 cause of bad estimates.

**Exit criterion:** You can explain to a colleague (a) where the change goes, (b) every system it touches, (c) what realistically can go wrong — without hedging.

### Step 3 — Draft Multiple Solutions

Produce **2–4 distinct solution approaches**. Genuinely different, not cosmetic variants.

Examples of meaningfully different:
- Surgical patch vs. refactor + patch
- Frontend-only vs. backend contract change vs. shared schema rev
- Synchronous vs. queued / async
- Reuse existing pattern vs. new abstraction

For each solution document:
- Approach (2–3 sentences)
- Files / services touched
- Risk / blast radius
- Trade-offs (perf, maintainability, future flexibility, complexity)

**Not allowed as a "solution":**
- "Do all of A + B + C in parallel" — that's a delivery plan, not a distinct architectural approach. Solutions must differ on at least one architectural axis (where the change goes, what contract changes, sync vs async, reuse vs new abstraction). Stacking unrelated work to inflate the worst-case is gaming the process — strip it back to the largest single architectural variant.
- "Same approach, just slower / faster" — speed is not an architectural axis.
- "Hire more people" — capacity is not an axis.

**Exit criterion:** Each solution clearly distinct on at least one architectural axis. No solution is a superset of another.

### Step 4 — Estimate Each Solution in Work Days

For every solution, break work into a flat list of concrete tasks. Estimate each in work days (5h/day). Round up, never down. Use whole or half days.

Categories — include if applicable:

| Category | When required |
|----------|---------------|
| Implementation | Always |
| Unit tests | Always |
| Integration / e2e tests | If touches >1 service or user-facing flow |
| **Regression test budget** | **Critical path: auth, payments, billing, data integrity, shared components** |
| Code review iteration | Always (assume ≥1 round of revisions) |
| Manual QA / verification | If user-facing |
| Deploy + post-deploy monitor | If production-affecting |
| Doc / runbook updates | If public API, runbook, or onboarding-relevant |
| Migration / backfill | If schema or data shape changes |

**Investigation-only tickets** (deliverable is a writeup / decision / spike — not shipped code) use a different category set:

| Category | When required |
|----------|---------------|
| Discovery / data gathering | Always |
| Reproduction (if bug investigation) | If a reproducible failure is in scope |
| Diagnosis / hypothesis testing | Always |
| Spike code (throwaway, to prove feasibility) | If runtime evidence required |
| Recommendation / writeup | Always |
| Stakeholder review iteration | Always (assume ≥1 round) |

No unit / integration / regression budget unless the investigation ships code. If the investigation produces a recommendation that *will* be implemented, **re-run this skill on the implementation as a separate estimate** — do not bundle.

**Output format — required for every solution:** flat task list, one task per line, each with its own day estimate. Bottom-line subtotal alone is **not acceptable** — the breakdown is the audit trail. If a category from the table above is not in your list, state explicitly why it was dropped.

Sum to per-solution subtotal.

**Exit criterion:** Subtotal computed; no category silently dropped.

### Step 5 — Pick the Worst Estimate

Among the solutions, select the one with the **highest subtotal**. That is the defensive base.

Rationale: protects against optimistic anchoring, leaves room for trade-off conversation, lets the team come in under (which builds trust). Coming in over destroys it.

If a cheaper solution dominates on every dimension (cheaper AND better trade-offs), flag that — but still report worst-case so stakeholders see the full range and the chosen approach explicitly.

### Step 6 — Apply 30–40% Buffer

Multiply worst-case subtotal by **1.30 – 1.40**:

- **30%** — well-understood domain, familiar codebase, low integration risk
- **35%** — typical
- **40%** — unfamiliar code, multi-team coordination, vague upstream, first-of-its-kind work

Buffer absorbs: surprise bugs, environment issues, review back-and-forth, blocking dependencies, mid-work scope clarifications.

**Buffer is not negotiation padding. Do not let stakeholders strip it.** If pressured, return to scope and remove deliverables instead.

**If Step 2 (deep investigation) was waived or skimmed:** the worst-case is built on incomplete understanding, so the standard 30–40% band underestimates risk. Use **50%+ buffer** and label the estimate **"pre-investigation — quality will improve after deep-understand / deep-investigate runs."** Do not commit a deadline against a pre-investigation estimate; offer it as a placeholder only.

### Step 7 — Outline Final Estimate

Produce structured output. No prose narrative.

## Output Template

```
# Estimate — <ticket / task name>

## Scope
<one paragraph — the locked scope from Step 1>

## Acceptance Criteria
- <bullet>
- <bullet>

## Open Assumptions (if any)
- <assumption> — backed by <doc / code / conversation reference>

## Deep Understanding Summary
<3–6 bullets: what the change touches, why, key edge cases>

## Solutions Considered

### Solution A — <name>
- Approach: …
- Touches: …
- Trade-offs: …
- Breakdown:
  - <task> — N days
  - <task> — N days
- Subtotal: **X work days**

### Solution B — <name>
- (same shape)
- Subtotal: **Y work days**

(repeat for C, D as needed)

## Worst-Case Selection
Solution <X> at <N> work days — selected because <reason>.

## Buffer
Worst-case <N> × <1.30 / 1.35 / 1.40> = **<final> work days**
Buffer rationale: <why this multiplier>

## Final Estimate: <final> work days
(work day = 5 productive hours; ≈ <final × 5> productive hours)

## Risks / Things That Could Blow This Up
- <risk>
- <risk>

## Recommended Solution (if not the worst-case)
<only if a cheaper option dominates — name it and justify>
```

## Quick Reference

| Step | Output | Hard exit criterion |
|------|--------|---------------------|
| 1. Scope lock | Written scope + acceptance criteria | Zero open ambiguities |
| 2. Deep understand | Full mental model | Can explain without hedging |
| 3. Draft solutions | 2–4 distinct approaches | Each genuinely different |
| 4. Estimate each | Per-solution subtotal in work days | Test + regression budget included where applicable |
| 5. Pick worst | Worst subtotal selected | Justified |
| 6. Buffer | × 1.30–1.40 | Multiplier rationale stated |
| 7. Outline | Structured doc using template | All sections filled or marked N/A |

## Light Mode (Only After Scope Is Clear)

Light Mode is allowed only when BOTH are true:

1. The user explicitly says ballpark / rough estimate is acceptable.
2. Step 1 scope is clear enough to write the scope statement without inventing facts.

If scope is not clear, Light Mode is forbidden. Ask the blocking question instead.

If Light Mode is allowed, run an abbreviated version — but never skip Step 1 or Step 6.

- Step 1 — still ask if scope ambiguous; no number until answered
- Step 2 — skim instead of full deep-investigate
- Step 3 — single solution OK
- Step 4 — coarse breakdown
- Step 5 — N/A
- Step 6 — **still apply buffer**, default 35%
- Step 7 — short estimate, mark "ballpark — not commit-quality"

If user later wants to commit, run the full process before agreeing.

## Pressure Test Examples

### Vague ticket under deadline pressure

User:

> estimate this copy report ticket, I need the number now, just assume the normal Iris flow

Required response:

```
I can't estimate this yet because the scope is not locked.

Need one of:
- ticket/link or acceptance criteria
- expected behavior and current behavior
- whether this is Iris-only or Iris + Hermes

After that I can estimate with solution options, tests, regression budget, and buffer.
```

Do not give a fallback number. Do not say "assuming normal flow".

### Concrete task with local source available

Use source to close scope gaps, then estimate. Must include:

- 2–4 solution options
- per-option work-day subtotal
- worst-case selection
- explicit 30–40% buffer math
- tests/regression budget
- `work day = 5 productive hours`

### Critical bug

Use `deep-investigate` behavior first. Critical data-loss, auth, billing, permissions, or cross-service bugs require regression budget and 40% buffer unless evidence supports lower risk.

## Common Mistakes

- **Skipping scope lock.** Vague ticket → guaranteed-wrong estimate. Ask first.
- **One solution only.** No comparison → no defensible worst-case.
- **Picking the median.** Defeats the purpose.
- **Forgetting regression budget on critical paths.** Auth / payments / data integrity always need it.
- **8-hour days.** Nobody codes 8h/day. Use 5.
- **Stripping the buffer to "look fast."** Deadlines slip.
- **Estimating without `deep-investigate` / `deep-understand`.** Surface read = surface estimate.
- **Burying assumptions.** Surface them or they bite.

## Red Flags — STOP and Restart the Violated Step

- "I'll just assume the scope is X" → ask the user.
- "One solution is fine, I know the right one" → draft alternatives anyway.
- "Buffer feels excessive, trim it" → only with stated rationale.
- "I'll skip deep-investigate, I know this code" → confidence ≠ correctness.
- "Tests aren't critical here" → verify with user; default = include.
- "8 hours per day is fine" → no.
- "User wants a number now, no time for process" → ask the blocking scope question; no number.

## Anti-Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Scope is obvious" | Ask anyway. 30 seconds saves days. |
| "User wants a quick number, not rigor" | Ask "ballpark or commit-quality?" Use Light for ballpark, full for commit. |
| "One solution is clearly right" | Drafting alternatives reveals trade-offs you missed. |
| "Worst-case makes me look slow" | Missing deadlines makes you look unreliable. Trust > speed. |
| "30% buffer is excessive" | Software estimates are systematically optimistic. Stats disagree. |
| "I already know the codebase" | Familiarity ≠ full understanding. Run `deep-understand`. |
| "Skip regression tests, low risk" | If you can't define "low risk" precisely, include the budget. |
| "5h/day is too low" | Track yourself for a week. It's not. |
| "I'll add the buffer at the end mentally" | Make it explicit in the output or it disappears under pressure. |

## Alignment With Repo Operating Rules (`AGENTS.md`)

This skill enforces the five non-negotiables defined in `AGENTS.md`:

- **Surface assumptions** → Step 1 requires explicit assumption labeling in the output.
- **Stop when confused** → Hard stop in Step 1 if scope is ambiguous.
- **Push back when warranted** → Worst-case + buffer is structural pushback against optimistic pressure.
- **Prefer boring** → Solution drafting favors simple / proven patterns; complex solutions must justify their cost.
- **Scope discipline** → Estimate covers only the locked scope. Drive-by additions = re-scope, re-estimate.

It also follows: process over prose, verification as hard exit (each step gates the next), progressive disclosure (template + tables for scanning), anti-rationalization (red flags + table).

## Discipline Type

**Rigid.** Follow exactly. Do not adapt the process away to "save time" — the process *is* the value.
