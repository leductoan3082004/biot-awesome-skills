# Completion Discipline (High Priority)

> Loaded on demand from `AGENTS.md` router. Read before declaring any task complete.

Do not declare a task complete based only on confidence, code changes, written output, or partial checks. Verify with objective evidence.

## Per-task checklist

1. **Confirm the requested outcome.**
   - Restate what must be true when the task is complete.
   - Identify observable success criteria.

2. **Run the lowest-cost correctness checks first.**
   - Syntax, formatting, linting, type checks, schema validation, or equivalent.
   - If any fail, stop and fix before moving on.

3. **Verify the actual behavior.**
   - Run tests, scripts, workflows, examples, queries, previews, or manual checks relevant to the task.
   - Do not rely only on inspection. The work must execute successfully.

4. **Verify the complete path.**
   - Check the task in its real context.
   - Confirm integrations, configuration, data flow, permissions, persistence, side effects, and cleanup where applicable.
   - If the task affects a user workflow, simulate or test that workflow end to end.

5. **Report evidence, not confidence.**
   - Say what was checked.
   - Say what passed.
   - Say what was not checked and why.
   - Do not hide uncertainty.

6. **Do not refactor or optimize before the core requirement is verified.**
   - First make the requested behavior correct.
   - Then improve structure, performance, or style only if it does not obscure verification.

## Definition of done

A task is complete only when the required outcome has been verified through objective checks appropriate to the project.

- "Implemented" does not mean "complete."
- "Tests passed" does not always mean "complete."
- "Looks correct" does not mean "complete."

Never declare victory early.

## Verification order

1. **Structure** — syntax, lint, types, formatting, validation.
2. **Behavior** — run the relevant tests, commands, examples, or workflows.
3. **Full outcome** — verify the real end-to-end path, including dependencies, configuration, data, integrations, side effects, and cleanup.

If any layer fails, fix it before moving forward.

## Completion report shape

When reporting completion, include:

- what you changed,
- what you verified,
- what passed,
- what remains unverified, if anything.

Rely on evidence, not confidence.
