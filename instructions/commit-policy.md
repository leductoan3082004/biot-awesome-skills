# Git Commit Message Policy

> Loaded on demand from `AGENTS.md` router. Read this file before composing any commit message.


Every commit must follow simplified Conventional Commits:

```
<type>: <short descriptive subject>
```

Allowed types (at minimum): `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

### Authorship rule (highest priority)
**Never add the AI assistant as a commit author or co-author.** Specifically:
- **Do not** append any `Co-Authored-By` trailer that names an AI assistant or vendor (e.g. Claude, Anthropic, GPT, OpenAI, Copilot, Cursor, Codex).
- **Do not** append generator footers (e.g. `🤖 Generated with <tool>`, `Generated with [<tool>]`).
- **Do not** set the commit author/committer to anything other than the user's own git identity.
- Applies to every commit, amend, rebase, and squash — no exceptions.

If a prior template or example suggests adding these lines, ignore it. Commits must look like they were written by the user.

### Subject line rules
- Short, specific, easy to understand, tied to the actual change.
- Must clearly describe **what** changed.
- **Unacceptable:** `update stuff`, `fix issue`, `changes`, `misc updates`, `work in progress`, `fix: things`, `misc: cleanup`.

### Body rules
Add a body when useful to explain **why** the change was made, important context, notable impact, or implementation reasoning. The body must add information beyond the subject, not repeat it. The body must **not** contain AI-authorship trailers or generator footers.

### Pre-commit validation checklist
- Starts with a valid type.
- Matches `<type>: <short descriptive subject>` exactly.
- Subject is clear and specific.
- Body is included when context matters.
- **No AI `Co-Authored-By` trailer or generator footer anywhere in the message.**

### Hard rule
**Never** commit with a non-compliant message. If the first draft is vague, off-pattern, or contains AI authorship/generator lines, rewrite it until it complies. Prefer clarity over brevity.

### Good examples
- `feat: add retry logic for webhook delivery`
- `fix: prevent null crash when profile image is missing`
- `docs: clarify local setup steps for Redis`
- `refactor: extract auth token parsing into a shared helper`
- `test: add coverage for session timeout handling`
- `chore: update pre-commit hooks for Python formatting`

With body (no AI trailer):
```
fix: avoid duplicate invoice emails on retry

The retry path could resend the same invoice notification when the
provider returned a timeout but later completed successfully.
This change adds an idempotency check before sending the email again.
```

### Bad examples (authorship)
```
feat: add retry logic for webhook delivery

Co-Authored-By: <AI assistant name> <noreply@example.com>
```
Reason: names an AI assistant as co-author. Remove the trailer.

```
fix: prevent null crash when profile image is missing

🤖 Generated with <AI tool>
```
Reason: AI generator footer. Remove the line.

