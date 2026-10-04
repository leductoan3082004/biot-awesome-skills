# Pi delegation

> Loaded on demand from `AGENTS.md` router. Read this file before delegating work to the `pi` CLI.

Pi (`pi`, verified on v1.0.2) is a separate coding agent with read, bash, edit, and write tools. Use it instead of a built-in subagent when the delegated work may take a long time or need several follow-up messages, because a Pi session persists on disk and can be resumed by ID.

## Running a task

```bash
pi -p --session-id <stable-task-id> --tools <allowlist> "<prompt>"
```

- `-p` / `--print` runs one prompt non-interactively and exits. Stdout is the worker's final reply.
- `--session-id <id>` creates the session on first use (stdout then starts with `Warning: No project session found with id '<id>'; creating a new session with that id.`) and resumes it on every later call, so follow-ups keep the earlier context. Pick an ID that names the task (e.g. `audit-ingest-retry`) and record it in your working state.
- Sessions are stored per working directory under `~/.pi/agent/sessions/<encoded-cwd>/`, so run follow-ups from the same cwd as the first call. `--session-dir <dir>` overrides the location; `--no-session` runs ephemerally.

## Permissions — there is no approval prompt

In `-p` mode Pi runs its tools without asking. With the default tool set (read, bash, edit, write) a prompt that asks for a file gets it written with no confirmation. The tool allowlist is the reliable guard, so set it on every call:

| Work | Flag |
|---|---|
| Read-only (investigation, review) | `--tools read,grep,find,ls` |
| Edits authorized by the user | omit `--tools`, or list exactly what is needed |

`bash` can mutate anything, so leave it out of read-only runs. `--exclude-tools <list>` removes single tools from the default set.

`--approve` / `-a` does **not** approve tool calls. Per `pi --help` it only trusts project-local files for that run. Add it only when the project ships Pi resources you trust; otherwise leave it off.

## What the worker sees

Pi loads `AGENTS.md` / `CLAUDE.md` from the working directory, so the worker follows the same always-on rules as you, including the Write gate, which only allows writes the current prompt explicitly requests — so name the authorized writes in the prompt. `--no-context-files` / `-nc` starts it without those files.

The worker has none of your conversation. Give it the full task, the constraints, the authorization boundary, and the shape of the answer you need.

## Model and effort

Without `--model`, Pi uses its configured default; the `model_change` entry in the session file records which model ran. Override per call with `--model <provider/id>` and `--thinking <off|minimal|low|medium|high|xhigh|max>`; `pi --list-models [search]` lists what is available. Apply the AGENTS.md model-selection rule: cheap model for exploration, strong model for judgment.

## Trusting the result

Stdout is the worker's report, not evidence. Verify every claim you pass on — re-read the cited files, re-run the decisive command, and check `git status` / `git diff` after any run that had write tools — before you deliver it.

## Not yet verified here

`--mode json` and `--mode rpc` (a long-running bidirectional worker) exist per `pi --help` but have not been exercised; test before relying on them.
