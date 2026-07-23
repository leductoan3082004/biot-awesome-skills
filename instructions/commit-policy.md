# Git Commit Message Policy

> Loaded on demand from `AGENTS.md` router. Read this file before composing any commit message.


Every commit must follow simplified Conventional Commits:

```
<type>: <short descriptive subject>
```

Allowed types (at minimum): `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

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

### Hard rule
**Never** commit with a non-compliant message. If the first draft is vague or off-pattern, rewrite it until it complies. Prefer clarity over brevity.

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

