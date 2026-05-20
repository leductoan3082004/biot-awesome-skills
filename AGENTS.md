# Agent Operating Instructions (Universal)

Vendor-neutral baseline for any coding agent (Claude Code, Codex, Cursor, etc.). Agent-specific layers (`CLAUDE.md`, future `CODEX.md`, …) `@`-import this file.

Keep this router short. If you find yourself typing vendor-specific terms (`Opus`, `Sonnet`, `Anthropic`, `~/.claude/...`, Agent tool, hook system specifics) — that content does not belong here. Move it to the relevant companion file.

---

## Always-on universal rules

- **Authorship** — NEVER add an AI assistant as `Co-Authored-By` or generator footer on any commit. Author/committer must be the user's own git identity. Applies to every commit, amend, rebase, squash.
- **Five non-negotiables** — (1) Surface assumptions before non-trivial work. (2) Stop when confused — name the confusion, ask. (3) Push back when warranted — sycophancy is a failure mode. (4) Prefer boring — fewer lines, naive-correct over clever-fragile. (5) Scope discipline — touch only what the task requires.
- **Save trigger** — Invoke `/context-save` before the final response after substantive work (code edit / decision / fix / refactor / finding). Skip for trivial replies, clarifying questions, read-only exploration. When in doubt → skip.
- **Verification gate** — Task is incomplete until tests pass, build succeeds, runtime behavior matches expectations, lint/type-check is clean. "Seems right" is never sufficient.
- **Process over prose** — Pick the workflow / skill that matches the task. Follow steps in order. Hit every checkpoint.
- **One feature at a time** — Finish + end-to-end verify feature A before starting feature B. No opportunistic "also refactor" of unrelated code mid-feature.

---

## On-demand universal instructions

Read these files **before acting** in the relevant scope.

| Topic | File | Read when |
|---|---|---|
| Git commit policy (full text, examples, validation checklist) | `instructions/commit-policy.md` | Composing any commit message |
| PR creation policy (template handling, accuracy rules, examples) | `instructions/pr-policy.md` | Opening or updating a PR |
| Engineering discipline (anti-rationalization table, process-over-prose, verification, progressive disclosure, 5 non-negotiables expanded) | `instructions/engineering-discipline.md` | Starting non-trivial work — read once per session |
| Context save policy (full trigger criteria, v3 layout, restore flow) | `instructions/context-save.md` | Before invoking `/context-save` |
