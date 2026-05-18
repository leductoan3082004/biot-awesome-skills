---
name: checkpoint-save
description: Use when the user invokes "/checkpoint-save <task>" or bare "/checkpoint-save", or asks to "do this and then checkpoint", "wrap and save", "task then context-save". Runs the inline task in the foreground, then invokes the context-save skill in the foreground as well. No background dispatch, no trailing notification. Do not use for bare /context-save requests — call that skill directly.
---

# Checkpoint Save

## Overview

Foreground wrapper. Two phases run from one user message, both in the main session:

1. **Main task** — execute the prompt the user passed as args, exactly as if they had typed it without the wrapper. Normal output. If args is empty, skip this phase.
2. **Context save** — after the main task is finished (or immediately, if args is empty), invoke the `context-save` skill via the `Skill` tool. The main session answers any interactive prompts itself, using the conversation it just had.

There is no background sub-agent. There is no separate "done" notification. The user sees normal task output, then context-save's normal output. That is the whole skill.

## When to Use

- User typed `/checkpoint-save <prompt>` with an inline task.
- User typed `/checkpoint-save` with no args — treat as "checkpoint the conversation so far, no foreground task." Skip Step 1, jump to Step 2.
- User said "do X and then checkpoint", "task then context-save", or otherwise asked to chain a task with an auto context-save.

**Don't use when:**
- User asked for `/context-save` alone — call that skill directly, no wrapper.
- The "main task" is itself `/context-save` or another checkpoint variant — collapse to a direct call.

## Workflow

### Step 1 — Execute the main task

Treat the argument string as the user's real request. Apply the normal output style for that task. Do not announce that a checkpoint will follow. The reader should not be able to tell from the body of the answer that a wrapper was used.

**If args is empty**, skip Step 1 entirely. Do not ask the user for a task. Do not invent one. Proceed to Step 2.

### Step 2 — Invoke context-save in the foreground

Dispatch is unconditional — fire context-save after every wrapped invocation, regardless of how trivial the main task was, and regardless of whether the main task succeeded. A failed-mid-task state is often the *most* valuable state to checkpoint.

Call the `Skill` tool with `skill: context-save` and no args. Let the gstack `context-save` skill run normally in the main session. When it issues interactive prompts (decisions made, remaining work, branch summary, etc.), answer them yourself using the conversation context you already have — files touched, decisions reached, todos still open. Do not block on the user to answer those prompts unless the conversation truly does not contain the information.

### Step 3 — No extra notification

When `context-save` finishes its run, the turn ends. Do **not** add a "checkpoint done" line, a summary of what was saved, an emoji, or any other trailing acknowledgment. The visibility of the context-save output is the receipt.

## Quick Reference

| Stage | Action | Visible output |
|-------|--------|----------------|
| Pre   | Parse args as the real task. | (none) |
| Main  | Do the task in normal style. **Skip if args empty.** | Full task answer (or nothing if args empty) |
| Save  | Invoke `context-save` via the `Skill` tool, foreground. Answer its interactive prompts from session knowledge. | Whatever `context-save` prints |
| End   | Nothing. | (none) |

## Anti-Patterns

- ❌ Background dispatch via `Agent(run_in_background: true)` — earlier wrapper version tried this; the bg sub-agent had no transcript and stalled on context-save's interactive prompts. Foreground is required.
- ❌ Pre-announcing the checkpoint ("I'll run context-save after this") — pollutes the main task framing.
- ❌ Trailing "done checkpoint" line — context-save's own output is the receipt.
- ❌ Asking the user "which task should I wrap?" when args is empty — never ask, just invoke context-save.
- ❌ Skipping context-save because "task was trivial" or "task failed" — dispatch is unconditional.
- ❌ Suppressing context-save's output to make the wrapper "silent" — that requires bypassing the skill and writing checkpoint files directly, which is brittle. Let context-save print.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Background sub-agent for context-save | Use the `Skill` tool directly in main session. |
| Asking user for a task on empty args | Skip Step 1, go straight to context-save. |
| Context-save asks for decisions, you ask the user | Answer yourself using the conversation. Only escalate if the answer is genuinely not in session memory. |
| Adding a trailing acknowledgment | End the turn after context-save returns. No extra line. |

## Notes on Foreground Behavior

- `context-save` (gstack flavor) prints a preamble with branch / proactive / telemetry flags before its interactive flow. That output is expected and not pollution from this wrapper.
- The main session must answer interactive prompts in-line. Treat context-save's prompts the same way you would treat a user message that says "tell me your recent decisions" — respond with the actual decisions reached during this conversation.
- If context-save errors or refuses to run (no repo, missing config, etc.), surface the error briefly and stop. Do not retry. Do not silently swallow.
