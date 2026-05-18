---
name: checkpoint-save
description: Use when the user invokes "/checkpoint-save <task>" or bare "/checkpoint-save", or asks to "do this and then checkpoint", "wrap and save", "task then context-save". Runs the inline task in the foreground, invokes the context-save skill in the foreground, then consolidates the saved file into a single rolling per-project file at `~/.gstack/projects/<slug>/CONTEXT.md`. No background dispatch, no trailing notification. Do not use for bare /context-save requests — call that skill directly.
---

# Checkpoint Save

## Overview

Foreground wrapper. Three phases run from one user message, all in the main session:

1. **Main task** — execute the prompt the user passed as args, exactly as if they had typed it without the wrapper. Normal output. If args is empty, skip this phase.
2. **Context save** — after the main task is finished (or immediately, if args is empty), invoke the `context-save` skill via the `Skill` tool. The main session answers any interactive prompts itself, using the conversation it just had.
3. **Consolidate to single file** — after `context-save` writes its dated file under `~/.gstack/projects/<slug>/checkpoints/`, move that content into one canonical file at `~/.gstack/projects/<slug>/CONTEXT.md` (overwriting) and delete the dated file. Each project ends up with exactly **one** context file at any time.

There is no background sub-agent. There is no separate "done" notification. The user sees normal task output, then context-save's normal output, then nothing.

**Tradeoff acknowledged:** gstack's `/context-restore` scans `checkpoints/*.md` for dated files. After this wrapper runs, that directory is empty and `CONTEXT.md` lives one level up. `/context-restore` in its current form will not find the saved state. If the user wants to resume, they read `CONTEXT.md` directly or this skill grows a sibling `checkpoint-restore` that reads the canonical path. This is a deliberate choice by the user to keep state in one file.

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

### Step 3 — Consolidate into one file per project

`context-save` writes a timestamped file under `~/.gstack/projects/<slug>/checkpoints/<TIMESTAMP>-<title>.md`. After it returns, run a bash block that:

1. Resolves the project slug via `eval "$(~/.claude/skills/gstack/bin/gstack-slug 2>/dev/null)"`.
2. Finds the newest file under `~/.gstack/projects/$SLUG/checkpoints/` (the one `context-save` just wrote).
3. Moves it to `~/.gstack/projects/$SLUG/CONTEXT.md`, overwriting any previous CONTEXT.md.
4. Deletes any remaining files under `~/.gstack/projects/$SLUG/checkpoints/` so the directory stays empty.

Concrete bash:

```bash
eval "$(~/.claude/skills/gstack/bin/gstack-slug 2>/dev/null)"
_PROJ="$HOME/.gstack/projects/${SLUG:-unknown}"
_CHK="$_PROJ/checkpoints"
if [ -d "$_CHK" ]; then
  _LATEST=$(find "$_CHK" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort -r | head -1)
  if [ -n "$_LATEST" ]; then
    mv -f "$_LATEST" "$_PROJ/CONTEXT.md"
  fi
  # Sweep any leftover dated files so the dir stays empty.
  find "$_CHK" -maxdepth 1 -name "*.md" -type f -delete 2>/dev/null || true
fi
```

If `context-save` produced no file (e.g. it errored), skip the consolidation silently. If `CONTEXT.md` already exists from a previous turn, overwrite it — only the latest checkpoint is retained. History is preserved by the user's git commits, not by accumulating files.

### Step 4 — No extra notification

When consolidation finishes, the turn ends. Do **not** add a "checkpoint done" line, a summary of what was saved, an emoji, or any other trailing acknowledgment. The visibility of `context-save`'s own output is the receipt; the consolidation is silent.

## Quick Reference

| Stage | Action | Visible output |
|-------|--------|----------------|
| Pre         | Parse args as the real task. | (none) |
| Main        | Do the task in normal style. **Skip if args empty.** | Full task answer (or nothing if args empty) |
| Save        | Invoke `context-save` via the `Skill` tool, foreground. Answer its interactive prompts from session knowledge. | Whatever `context-save` prints |
| Consolidate | Move newest `checkpoints/*.md` to `<proj>/CONTEXT.md`; sweep `checkpoints/` empty. | (none) |
| End         | Nothing. | (none) |

## Anti-Patterns

- ❌ Background dispatch via `Agent(run_in_background: true)` — earlier wrapper version tried this; the bg sub-agent had no transcript and stalled on context-save's interactive prompts. Foreground is required.
- ❌ Pre-announcing the checkpoint ("I'll run context-save after this") — pollutes the main task framing.
- ❌ Trailing "done checkpoint" line — context-save's own output is the receipt.
- ❌ Asking the user "which task should I wrap?" when args is empty — never ask, just invoke context-save.
- ❌ Skipping context-save because "task was trivial" or "task failed" — dispatch is unconditional.
- ❌ Suppressing context-save's output to make the wrapper "silent" — that requires bypassing the skill and writing checkpoint files directly, which is brittle. Let context-save print.
- ❌ Leaving dated files behind in `checkpoints/` after the consolidation — the directory must end up empty so future invocations have an unambiguous "newest file" target.
- ❌ Appending the new save to `CONTEXT.md` instead of overwriting — the design is a rolling single file, not an append-only log. History lives in git.
- ❌ Skipping the consolidation when there's already a `CONTEXT.md` — overwrite it. Latest save wins.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Background sub-agent for context-save | Use the `Skill` tool directly in main session. |
| Asking user for a task on empty args | Skip Step 1, go straight to context-save. |
| Context-save asks for decisions, you ask the user | Answer yourself using the conversation. Only escalate if the answer is genuinely not in session memory. |
| Adding a trailing acknowledgment | End the turn after consolidation. No extra line. |
| Forgetting Step 3 consolidation | Run the bash block after every successful `context-save`. Without it, `checkpoints/` accumulates files turn over turn. |
| Trying to merge old CONTEXT.md into the new one | Overwrite it. History lives in git, not in stacked frontmatter. |

## Auto-restore at session boundaries

A companion `SessionStart` hook (`hooks/inject-checkpoint-context.sh`, wired in `~/.claude/settings.json` with matcher `startup|resume|clear|compact`) auto-injects the project's `CONTEXT.md` into the new session's context whenever Claude Code starts up, resumes, clears, or compacts. The agent reads it before the user's first turn, so a session that begins after `/clear`, after `/compact`, or in a fresh window continues from the most recent checkpoint instead of starting clean.

The hook:
- Reads `CLAUDE_PROJECT_DIR` to find the active project.
- Resolves the gstack slug via `~/.claude/skills/gstack/bin/gstack-slug`.
- Looks for `~/.gstack/projects/$SLUG/CONTEXT.md`.
- Prints a header + the file content to stdout. Claude Code injects stdout as additional context.
- Exits 0 silently when there is no slug, no file, or no gstack — never fails the session start.

This means the writer half (this skill) and the reader half (the SessionStart hook) form one closed loop: every save goes to a known canonical path, every new session reads from that same path. There is no separate "restore" command to run.

If the user explicitly asks something unrelated as their first turn, abandon the restored context — the header tells the agent so. Otherwise resume from the **Remaining Work** list.

## Notes on Foreground Behavior

- `context-save` (gstack flavor) prints a preamble with branch / proactive / telemetry flags before its interactive flow. That output is expected and not pollution from this wrapper.
- The main session must answer interactive prompts in-line. Treat context-save's prompts the same way you would treat a user message that says "tell me your recent decisions" — respond with the actual decisions reached during this conversation.
- If context-save errors or refuses to run (no repo, missing config, etc.), surface the error briefly and stop. Do not retry. Do not silently swallow. Skip Step 3 when there is no new file to consolidate.
- The consolidation step is intentionally not part of upstream gstack — it is a user preference that overrides gstack's default many-file design. If a future gstack upgrade changes the `checkpoints/` layout, revisit Step 3.
