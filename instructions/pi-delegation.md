# Pi delegation

> Loaded on demand from `AGENTS.md` router. Read this file before delegating work to the `pi` CLI.

Pi (`pi`, verified on v1.0.2) is a separate coding agent with read, bash, edit, and write tools. Use it instead of a built-in subagent when the delegated work may take a long time or need several follow-up messages, because a Pi session persists on disk and can be resumed by ID.

## Running a task

```bash
pi -p --session-id <stable-task-id> --tools <allowlist> "<prompt>"
```

- `-p` / `--print` runs one prompt non-interactively and exits. The worker's final reply goes to stdout; warnings go to stderr.
- `--session-id <id>` creates the session on first use (stderr then shows `Warning: No project session found with id '<id>'; creating a new session with that id.`) and resumes it on every later call, so follow-ups keep the earlier context. Pick an ID that names the task (e.g. `audit-ingest-retry`) and record it in your working state.
- Sessions are stored per working directory under `~/.pi/agent/sessions/<encoded-cwd>/`, so run follow-ups from the same cwd as the first call. `--session-dir <dir>` overrides the location; `--no-session` runs ephemerally.

## Permissions — there is no approval prompt

In `-p` mode Pi runs its tools without asking. With the default tool set (read, bash, edit, write) a prompt that asks for a file gets it written with no confirmation. The tool allowlist is the reliable guard, so set it on every call:

| Work | Flag |
|---|---|
| Read-only (investigation, review) | `--tools read,grep,find,ls` |
| Edits authorized by the user | `--tools read,grep,find,ls,edit,write`; add `bash` only when commands must run |

Omitting `--tools` also enables every extension and MCP tool Pi has configured, so always list tools explicitly. `bash` can mutate anything, so leave it out of read-only runs.

`--approve` / `-a` does **not** approve tool calls. Per `pi --help` it only trusts project-local files for that run. Add it only when the project ships Pi resources you trust; otherwise leave it off.

## What the worker sees

Pi loads `AGENTS.md` / `CLAUDE.md` from the working directory, so the worker follows the same always-on rules as you, including the Write gate, which only allows writes the current prompt explicitly requests — so name the authorized writes in the prompt. `--no-context-files` / `-nc` starts it without those files.

The worker has none of your conversation. Give it the full task, the constraints, the authorization boundary, and the shape of the answer you need.

## Model and effort

Without `--model`, Pi uses its configured default; the `model_change` entry in the session file records which model ran. Pass `--model openroad/<model>` per call, and `--thinking <off|minimal|low|medium|high|xhigh|max>` on models that support thinking. Models available here (`pi --list-models`, 2026-10-04):

| Model | Max output | Thinking | Use for |
|---|---|---|---|
| `kimi-k2-fast` | 1.0K | no | Codebase exploration: finding files, grepping, "where is X" |
| `kimi-light` | 4.1K | no | |
| `kimi-standard` | 8.2K | no | |
| `kimi-k2` | 2.0K | yes | |
| `kimi-extended` | 16.4K | yes | |
| `kimi-deep` | 16.4K | no | |
| `claude-axonk-2-6` | 2.0K | yes | Current default |

All have a 225.3K context and no image input. For exploration use `kimi-k2-fast` with a read-only allowlist:

```bash
pi -p --session-id <id> --model openroad/kimi-k2-fast --tools read,grep,find,ls "<question>"
```

Its replies are capped at about 1K tokens, so ask for a file:line list or a short table rather than a long write-up, and split broad sweeps into several questions. Move synthesis and judgment to a stronger model.

Foreground shell calls time out (Claude Code's Bash caps at 10 minutes), so run long Pi jobs in the background with stdout redirected to a file.

## Trusting the result

Stdout is the worker's report, not evidence. Verify every claim you pass on — re-read the cited files, re-run the decisive command, and check `git status` / `git diff` after any run that had write tools — before you deliver it.

## Not yet verified here

`--mode json` and `--mode rpc` (a long-running bidirectional worker) exist per `pi --help` but have not been exercised; test before relying on them.
