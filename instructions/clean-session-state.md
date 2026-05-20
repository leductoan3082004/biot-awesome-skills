# Clean Session State Harness (High Priority)

> Loaded on demand from `AGENTS.md` router. Read before ending any session or declaring a task complete.

## Rule

A session is not complete until the project is left in a clean, verified, restartable state.

The agent must not say the task is done, complete, finished, or ready unless the Clean State Exit Check passes.

Implementing the requested change is not enough.

## Clean State Exit Check

Before ending a session, the agent must verify all five dimensions:

1. Verification passes.
2. Relevant tests and checks pass.
3. Progress is recorded.
4. Temporary or ambiguous artifacts are removed.
5. The standard startup or continuation path still works.

If any dimension fails, the session is not clean.

If any dimension cannot be checked, it must be reported as unverified. Unverified does not mean passed.

## 1. Verification

The agent must run the project's standard verification command.

This may include build, compile, type-check, package validation, or another project-specific verification step.

The agent must use the command documented by the project, not assume a command based on language or framework.

Look for the correct command in places such as:

- README
- contributor guide
- build scripts
- task runner configuration
- CI configuration
- project harness instructions
- existing developer documentation

Example only:

```bash
npm run build
```

If no standard verification command exists, the agent must use the closest available verification method and report that no standard command was found.

## 2. Tests and Checks

The agent must run the relevant tests and checks for the work performed.

This may include:

- unit tests
- integration tests
- end-to-end tests
- lint checks
- formatting checks
- static analysis
- schema validation
- generated artifact checks
- compatibility checks
- migration checks
- security checks, if relevant

The agent must prefer repository-documented commands over generic guesses.

Example only:

```bash
npm test
```

If a test or check fails, the agent must report:

- the command that failed
- the failure summary
- whether the failure appears related to the current change
- the recommended next action

The agent must not ignore failing tests or checks.

## 3. Progress

The agent must record what changed and what remains.

The progress record must include:

- what was completed
- what files, modules, or areas changed
- what was verified
- what remains unfinished
- known risks
- follow-up tasks
- commands that were run
- commands that were not run and why

Use the project's existing progress artifact if one exists, such as:

- task file
- feature list
- issue tracker
- pull request description
- handoff note
- status document
- project board
- session log
- repository-specific progress file

If no progress artifact exists, the agent must include a concise handoff note in the final response.

## 4. Artifacts

The agent must remove temporary, stale, or ambiguous artifacts created during the session.

The project must not be left with files or code that make the next session guess whether something is intentional.

Clean up items such as:

- temporary files
- scratch scripts
- debug logs
- local test output
- commented-out experiments
- unused helper code
- stray debug statements
- temporary configuration changes
- abandoned TODOs introduced by the session
- generated files that should not be committed
- local-only environment modifications

If an artifact must remain, the agent must document why it remains and whether it is expected to be committed.

## 5. Startup or Continuation Path

The agent must verify that the next session can start from the resulting state.

The standard development, execution, or continuation path should still work.

Depending on the project, this may mean verifying that:

- the application starts
- the service boots
- the CLI runs
- the package loads
- the workspace initializes
- the development server starts
- the local environment starts
- the documented quickstart still works
- the next task can be picked up without manual rescue

Example only:

```bash
npm run dev
```

The exact command is project-specific.

If the startup or continuation path cannot be checked, the agent must report it as unverified.

## Required Final Response

At the end of every session, the agent must include this report:

```markdown
## Clean State Exit Report

### 1. Verification
- Command run:
- Result:

### 2. Tests and Checks
- Command(s) run:
- Result:

### 3. Progress Recorded
- Updated artifact:
- Summary:

### 4. Artifacts Cleaned
- Removed or reverted:
- Remaining intentional artifacts:

### 5. Startup / Continuation
- Command or path checked:
- Result:

### Final Status
- Clean state: Yes / No

### If Not Clean
- What failed:
- Why it remains unresolved:
- Recommended next action:
```

## Completion Gate

The agent may only mark the task complete if:

- verification passed
- relevant tests and checks passed
- progress was recorded
- temporary artifacts were cleaned
- startup or continuation path was verified

If any item failed or was unverified, the agent must mark:

```markdown
Clean state: No
```

A task with unverified clean state is incomplete.

## Core Lesson

A coding session is not complete when the change is written.

A coding session is complete only when the next session can safely continue from a verified, documented, clean state.
