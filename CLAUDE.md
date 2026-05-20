# Claude Code Operating Instructions

Claude-specific layer on top of the vendor-neutral baseline. The baseline is auto-imported below.

@AGENTS.md

`~/.claude/CLAUDE.md` is a symlink to this file. Edit this file; the symlink follows. Anything vendor-neutral belongs in `AGENTS.md`, not here.

**Hook + global-rule sync:** When any file under `hooks/`, this file, `AGENTS.md`, or `instructions/` is modified, commit + push to the biot remote in the same turn so other machines/sessions stay in sync.

---

## Always-on Claude rules

- **Model gates** — Delegate hard tasks to **Opus 4.7** at xhigh reasoning effort. Use **Sonnet 4.6** for easy/mechanical work, then have Opus 4.7 review when correctness matters. Never use any model other than {Opus 4.7, Sonnet 4.6} for delegated agents.
- **Trust-but-verify** — Never trust a sub-agent response immediately. Treat every answer as a draft until independently validated.
- **`/browse` for all web browsing** — gstack's `/browse` skill replaces `mcp__claude-in-chrome__*` tools. Never invoke the Chrome MCP tools directly.
- **Hook + rule edits sync to biot** — See preamble.
- **Authorship + verification + 5 non-negotiables + save trigger + one-feature-at-a-time** inherit from `AGENTS.md` always-on rules — apply them too.

---

## On-demand Claude instructions

Read these files **before acting** in the relevant scope.

| Topic | File | Read when |
|---|---|---|
| Agent delegation (model selection, trust/verify policy) | `instructions/agent-delegation.md` | About to spawn a sub-agent via the Agent tool |
| Operating rules (the 12) | `instructions/operating-rules.md` | Starting a non-trivial task — read once per session |
| gstack skills index | `instructions/gstack-skills.md` | Considering any `/gstack-*` (or related) skill invocation |

---

## Always-on vendor-neutral rules

Pulled in via `@AGENTS.md` above. The high-priority ones restated for visibility:

- **Authorship**: never add an AI assistant as `Co-Authored-By` or generator footer on any commit.
- **Five non-negotiables**: surface assumptions, stop when confused, push back when warranted, prefer boring, scope discipline.
- **Save trigger**: invoke `/context-save` before final response after substantive work; skip for trivial replies.
- **Verification gate**: task incomplete until tests pass, build succeeds, runtime behavior matches expectations, lint/type-check is clean.
- **One feature at a time**: finish + e2e verify feature A before starting feature B; no opportunistic refactors mid-feature.

For full text of any of these, see `instructions/commit-policy.md`, `instructions/engineering-discipline.md`, or `instructions/context-save.md` via the `AGENTS.md` routing table.
