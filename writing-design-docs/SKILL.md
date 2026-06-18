---
name: writing-design-docs
description: Use when writing, drafting, or filling in an Axon engineering design doc, 1:3:1 document, decision doc, RFC, or any technical document that frames a problem and weighs solution options before a review — including starting from the Engineering 1:3:1 Quip template or preparing a doc for #rms-design-doc-review.
---

# Writing Design Docs (Axon 1:3:1)

## Overview

A 1:3:1 document states **1 problem**, weighs **3 options**, lands **1 recommendation**. It exists to drive a *decision* in review, not to narrate work.

Two rules govern every such doc:

1. **Interview the author before drafting.** You cannot write a good doc until you know its audience and scope. This is a hard gate — do not draft prose until the interview is answered.
2. **Organize top-down on the ladder of abstraction.** Start at the highest rung (why this matters) and descend in order to the lowest (how, concretely). Never drop the reader into a middle rung — a solution detail, a schema, a Kafka topic — before the rungs above it exist. A reader who lands mid-ladder is missing the context to understand what they're reading.

The full fill-in skeleton is in [template.md](template.md).

## When to Use

- Writing/drafting an Axon Engineering 1:3:1 doc or any "problem → options → recommendation" decision doc.
- Preparing a doc for design review (#rms-design-doc-review) or for L10+/EM/PM/InfoSec approval.
- Someone hands you a half-written doc that "jumps straight to the solution" and asks you to fix or finish it.

**Not for:** READMEs, API reference, runbooks, tutorials (different shape — no options/recommendation). For pure intent-discovery before *any* creative work, run superpowers:brainstorming first, then this skill to shape the doc.

### First: is a 1:3:1 even the right doc?

A 1:3:1 is **optional** — write one to drive a *design decision*, especially a complex one that benefits from extra reviewers and JIRA tracking. It is **not** a design document and does not replace one. If the chosen option meets the bar for a design doc, write that design doc afterward (the 1:3:1 picks the approach; the design doc details it). Other doc types may fit better:

- **Problem Explanation** — surface an issue others may not know exists, to get it into planning.
- **Design Document** — detailed approach for *one* chosen solution.
- **Documentation** — explain an existing feature.

If the author's need is one of those, say so before drafting a 1:3:1.

## The Hard Gate: Interview Before Drafting

**Do not write a single section of prose until you have answers to the audience and scope questions below.** "I know enough to start" is the failure this gate prevents — a doc written before its scope is known wanders, and the first page (the hardest page, the only page many approvers read) comes out wrong.

Ask all of these. More answers = clearer intent. Block on 1–9; gather 10–11 during outlining.

**Audience & purpose**
1. Who must approve and read this? (Architecture L10+, Team EM, PM, team engineers, InfoSec, i18n, mobile, observers.) What decision does each need to make?
2. What does the reader already know going in? What should they be able to decide after the first page?

**Scope & problem** (feeds Background + Problem Statement)
3. What is the problem, and what is the customer's pain point?
4. Why must we solve it *now*? (Background.)
5. What requirements must the solution meet?
6. What are the non-goals — what are we explicitly *not* solving?
7. How is the problem quantified, and how will we measure that it's solved?

**Options** (feeds Options + Recommendation)
8. What are the candidate options? Aim for ≥3. Name any you already know are unviable and why.
9. Which do you lean toward, and why?

**Logistics**
10. Is there a Document Authoring JIRA? Related links / product spec / docs on the existing experience?
11. What terms, backend services, frontend tooling, or acronyms need a Glossary entry? (Test: could a non-Axon engineer read this?)

## The Ladder: Organize High → Low

Each 1:3:1 section sits on a rung. Lay each rung before the one beneath it. Within a section, descend the same way: state the abstract point, drop to a concrete example, climb back to connect it to the problem ("work both ends of the ladder").

| Rung | Answers | 1:3:1 section |
|---|---|---|
| Top — *Why* | Why does this matter? Why now? | Background |
| | What exactly is wrong? What must a fix satisfy? How is it measured? | Problem Statement (pain, requirements, non-goals, metrics) |
| Middle — *What* | What shapes could a solution take? | Options (overviews) |
| Lower — *How* | How does each option work? Cost? Pros/cons? | Option detail + Pros/Cons + cost estimate |
| Bottom — *Concrete* | The supporting detail | Appendix (diagrams, code) |
| Climb back up — *Decide* | Which one, and exactly why? | Recommendation → Decision |

**Options stop at the approach altitude — they are NOT three full designs.** A 1:3:1 gives a high-level approach per option, enough to compare and decide, not a fleshed-out implementation. Descending an option to design-doc depth is the most common altitude error. The detailed design comes *after*, in a separate design doc.

**Glossary sits beside the ladder, not on it.** It defines the rung labels so any low-rung detail is legible. Fill it so the reader never meets an undefined term while descending.

## Evaluating Options (the review bar)

This is where 1:3:1 docs pass or fail review. Three rules:

1. **Unbiased assessment.** Give every option a fair shake: real *support* for options you don't prefer, real *drawbacks* for the one you do. An option with only pros is a strawman or wishful thinking.
2. **Rough cost estimate per option.** A short outline of steps with abbreviated time, enough to explain why one approach costs more than another. **If you don't cost all options, you cannot use time as an argument** for any of them.
3. **Only valid engineering arguments.** Pros/cons must stand on engineering merit, not taste. Valid axes:
   - Correctness
   - Requirements met (and if not all — what's missing and how much it matters)
   - Risk
   - Simplicity / complexity
   - Maintainability
   - Consistency with existing implementations
   - Extensibility
   - Performance
   - Scalability
   - Cost to implement

Aim for **≥3 options**, ideally all viable and ones you'd be willing to code. Two is acceptable when there's no genuine third. Note any clearly-unviable option briefly with *why* it's bad.

## Workflow

1. **Interview (gate).** Collect answers to the question set. Do not draft prose yet.
2. **Outline for approval.** Produce the section skeleton: each section as a heading with a one-line statement of intent and the reader-need it serves, ordered top→bottom of the ladder. Get the author's sign-off on the outline *before* writing full prose.
3. **Draft top-down.** Fill from the highest rung down. Background → Problem Statement → Options → Recommendation → Appendix. Within each section, descend then reconnect.
4. **Self-check** against Common Mistakes. Cut any section that doesn't serve the problem statement (if it veers off-scope, refocus the section or change the scope — don't leave it).

## Quick Reference — Section Order

Glossary → Background → Problem Statement → Related Links → Options (≥3, each with overview + honest Pros/Cons) → Recommendation → Decision (filled after review) → Appendix.

## Common Mistakes

- **Opening mid-ladder.** Doc starts at "Option 2 uses a Kafka consumer" before the reader has Background + Problem + Requirements. Reader is lost. Start at the top rung.
- **One real option dressed as three.** 1:3:1, not 1:1:1. Two strawmen + a favorite is not three options. Give genuine alternatives.
- **Pros with no cons.** Every option needs honest drawbacks, and the options you *don't* prefer need honest support. A con-free favorite or a pro-free alternative is a biased assessment — reviewers will reject it.
- **No cost estimates.** Each option needs a rough cost (steps + abbreviated time). Skipped costs mean you can't argue on time at all.
- **Options at design-doc depth.** Fleshing one option into a full implementation. Keep options at the approach altitude; the detailed design is a separate doc.
- **Unmeasurable problem.** Problem Statement with no way to quantify the pain or verify the fix. Add metrics.
- **Buried recommendation.** Reader can't find what you're actually proposing. State it plainly in Recommendation; record the chosen option in Decision.
- **Skipped Glossary "because the reader is technical."** Reader ≠ author. Define services, acronyms, and tooling anyway.
- **Off-scope drift.** A section that doesn't serve the problem statement. Cut it or refocus it.

## Red Flags — STOP

- "I'll just start writing the Background, I know enough." → STOP. Run the interview first.
- Writing an option's implementation before the Problem Statement exists. → STOP. You're on a low rung with no rung above it.
- "It's obvious which option wins, I'll skip the others." → STOP. The doc's job is to *show the comparison*, not just the conclusion.
- "The reader is senior, skip the Glossary / skip the why." → STOP. Missing context = reader fills gaps wrong.
