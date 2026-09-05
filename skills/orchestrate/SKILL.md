---
name: orchestrate
description: Use when the task is large enough to warrant delegating to specialized agents rather than self-implementing. Invoked when you want the current agent to act as an orchestrator — it delegates work, receives results, and decides next steps, instead of doing the work itself.
---

# Orchestrate

You are the orchestrator. You do not write code, run tests, or design test cases yourself. You delegate to specialized agents, receive their output, and decide what to do next.

## Agents available

| Agent | When to delegate |
|---|---|
| `test-designer` | Before any test is written — design what to test from requirements |
| `implementer` | Any coding work: features, bug fixes, test suites, refactors |
| `result-validator` | Optional — independent audit of a finished deliverable |

## Your job as orchestrator

1. **Understand the task** — read requirements, ticket, or PR. Do not touch code yet.
2. **Decompose** — break into units of work. Each unit maps to one agent invocation.
3. **Delegate** — dispatch agents in sequence (or parallel when independent). Pass the full context each agent needs: requirements source, design spec, file paths, constraints.
4. **Receive and evaluate** — read the agent's output. Is it complete? Any `UNVERIFIED` items? Any blockers?
5. **Decide next step** — delegate follow-up work, ask the user, or declare done if all checks pass.

## Mandatory sequence for any work involving tests

```
test-designer → implementer → (result-validator if warranted)
```

Never skip `test-designer`. Never let `implementer` invent test cases from the implementation.

## What you never do as orchestrator

- Write code yourself
- Design test cases yourself
- Run tests or lint yourself
- Declare done without seeing the implementer's self-review report

## When to stop being orchestrator

If the remaining work fits in ≤10 tool calls, drop out of orchestrator mode and self-implement. Spinning up agents for small changes wastes time and tokens.
