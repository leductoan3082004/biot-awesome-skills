# Agent Operating Instructions

**Sync rule:** When this file or anything under `/Users/toale/Developer/biot-awesome-skills/instructions/` is modified, commit + push to the remote in the same turn so other machines/sessions stay in sync.

---

## Always-on rules

- **Authorship** — NEVER add an AI assistant as `Co-Authored-By` or generator footer on any commit. Author/committer must be the user's own git identity. Applies to every commit, amend, rebase, squash.
- **Five non-negotiables** — (1) Surface assumptions before non-trivial work. (2) Stop when confused — name the confusion, ask. (3) Push back when warranted — sycophancy is a failure mode. (4) Prefer boring — fewer lines, naive-correct over clever-fragile. (5) Scope discipline — touch only what the task requires.
- **Save trigger** — Invoke the save-context workflow before the final response after substantive work (code edit / decision / fix / refactor / finding). Skip for trivial replies, clarifying questions, read-only exploration. When in doubt → skip.
- **Verification gate** — Task is incomplete until tests pass, build succeeds, runtime behavior matches expectations, lint/type-check is clean. "Seems right" is never sufficient.
- **Completion discipline** — Verify with evidence before declaring done: structure → behavior → end-to-end path. Report what you changed, what you verified, what passed, what remains unverified. Full rules: `/Users/toale/Developer/biot-awesome-skills/instructions/completion-discipline.md`.
- **Clean session state** — Session not done until 5-dim Clean State Exit Check passes: verification + tests/checks + progress recorded + artifacts cleaned + startup path works. Emit Clean State Exit Report at session end. Full rules: `/Users/toale/Developer/biot-awesome-skills/instructions/clean-session-state.md`.
- **Process over prose** — Pick the workflow / skill that matches the task. Follow steps in order. Hit every checkpoint.
- **One feature at a time** — Finish + end-to-end verify feature A before starting feature B. No opportunistic "also refactor" of unrelated code mid-feature.

---

## On-demand instructions

Read these files **before acting** in the relevant scope. Paths are absolute — readable from any cwd by any agent tool with filesystem access.

| Topic | File | Read when |
|---|---|---|
| Git commit policy (full text, examples, validation checklist) | `/Users/toale/Developer/biot-awesome-skills/instructions/commit-policy.md` | Composing any commit message |
| PR creation policy (template handling, accuracy rules, examples) | `/Users/toale/Developer/biot-awesome-skills/instructions/pr-policy.md` | Opening or updating a PR |
| Engineering discipline (anti-rationalization table, process-over-prose, verification, progressive disclosure, 5 non-negotiables expanded) | `/Users/toale/Developer/biot-awesome-skills/instructions/engineering-discipline.md` | Starting non-trivial work — read once per session |
| Completion discipline (verification checklist, definition of done, completion-report shape) | `/Users/toale/Developer/biot-awesome-skills/instructions/completion-discipline.md` | Before declaring any task complete |
| Clean session state (5-dim exit check, exit-report template, completion gate) | `/Users/toale/Developer/biot-awesome-skills/instructions/clean-session-state.md` | Before ending a session or marking a task complete |
| Context save policy (full trigger criteria, v3 layout, restore flow) | `/Users/toale/Developer/biot-awesome-skills/instructions/context-save.md` | Before invoking the save-context workflow |
| Clickable file anchors (Markdown link for **Codex** chat UI, backticked path for **Claude Code** terminal CLI, spaces wrapping, no ranges/`file://`) | `/Users/toale/Developer/biot-awesome-skills/instructions/clickable-file-anchors.md` | Before emitting any file reference the user is meant to click |
