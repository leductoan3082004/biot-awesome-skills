# Composer subagent policy

**Rule:** For a large/non-trivial subagent task, dispatch to `@composer`
(Cursor Composer, run through the local `agent` CLI) instead of spawning a
builtin Claude Code subagent (Agent tool). **Exception:** Haiku 4.5 — spawn it
freely via the builtin Agent tool, no need to route through Composer.

Rationale (from Axon #ai-tools-ask, Jul 9 2026, Ging Nguyen): on PR-review-style
tasks, Composer gave the best balance of depth/breadth/severity calibration at
~1/10 the cost of frontier models (Opus, Grok). Opus has stronger per-finding
depth but auto-prunes reviewer scope and needs to be forced to keep breadth.
For max recall on high-stakes work, run 2-3 agents (multi-model or same agent
re-run) — Composer alone is the *default*, not the only tool.

## Mechanism

The `agent` CLI is Cursor's CLI (binary name `agent`, aka `cursor-agent`).

- Installed at `~/.local/bin/agent` (confirmed via `which agent`).
- Auth: `agent status` → `✓ Logged in as toale@axon.com`. If not logged in,
  run `agent login` (interactive, opens browser/device auth) before dispatch
  will work.
- Live model ids (confirmed via `agent models`, Jul 10 2026): `composer-2.5`
  (current/default), `composer-2.5-fast`. Older slugs like `composer-2` /
  `composer-1.5` referenced in older docs are **not** currently live — do not
  assume they exist; always resolve against `agent models` at call time.
- Headless dispatch pattern:
  ```bash
  agent -p --yolo --sandbox disabled --model composer-2.5 --output-format text "<prompt>"
  ```

## Subagent profile

The actual dispatcher lives at `~/.claude/agents/composer.md` (global, so it
works in every repo/session — not committed to any single project). It:

- Triggers on `@composer [<version>] <prompt>` (e.g.
  `@composer review this PR <pr-url>`, `@composer 2.5-fast summarize this diff`).
- Validates the requested version against a live `agent models` call and falls
  back to the nearest available `composer-*` slug if the exact one is missing
  — never silently substitutes a non-Composer model.
- Installs the `agent` CLI itself if missing, then stops and asks the user to
  `agent login` (can't complete interactive login on its own).
- Relays the CLI's stdout verbatim — it does not re-review or reformat.

See that file for the full step-by-step spec.
