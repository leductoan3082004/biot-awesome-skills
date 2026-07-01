# Pull Request Creation Policy

> Loaded on demand from `AGENTS.md` router. Read this file before opening or updating a PR.

### Branch check — before touching any PR (open, update, or resolve a comment on)
Before writing code, committing, or pushing in response to a PR (including a PR review-comment URL), verify the local checked-out branch **is** that PR's actual head branch.

- `gh pr view <number> --json headRefName,headRefOid` (or parse the PR URL) → compare against `git branch --show-current` and `git rev-parse HEAD`.
- Repos can have multiple branches stacked on top of each other with near-identical names/history. A stacked/downstream branch is NOT the PR's branch even if it shares ancestry.
- Mismatch → stop. Do not edit, commit, or push. Either switch/checkout the correct branch (stash any local uncommitted work first, restore after) or tell the user the branches don't match and ask how to proceed.
- Never assume "current branch" == "PR branch" from context alone (chat history, branch name similarity, `git log` showing the same commit message). Confirm with an actual `gh` lookup every time before the first write action against that PR.

**Why:** Pushed fixes to a stacked-but-different branch than the PR under review; replied on the PR thread claiming the fix landed when it hadn't. Had to hard-reset + force-push to undo it.

Every PR must give reviewers enough context to understand **what** changed, **why**, **how risky** it is, **how it was tested**, and **where to focus**. Optimize for reviewer usefulness, not form completion.

### PR title
Clear, specific, accurate. Reflects the actual change; does not overstate or understate scope. Avoid `updates`, `fixes`, `cleanup`, `changes`, `misc improvements`.

### PR body — required content
Include:
- scope of the change,
- why the change was made,
- risk level or potential impact,
- testing performed,
- reviewer notes / areas needing attention,
- follow-ups, limitations, or known unknowns when relevant.

### If a PR template exists
**Use it.** Fill each relevant section thoughtfully. If a section is not applicable, mark it `N/A` with a short reason. Do not leave useful sections blank. The template does not lower the quality bar.

### If no PR template exists
Produce a structured body with at minimum:
- Summary
- Why
- Risk / Impact
- Testing
- Reviewer Notes (if applicable)

### Accuracy rules
- Title and body must accurately reflect the actual changes.
- Do **not** claim work or testing that was not performed.
- Do **not** omit caveats or risk signals.
- If a detail cannot be verified, state that explicitly. **Do not fabricate.** Label assumptions and unknowns clearly.

### Reviewer-context rules
Write for the reviewer. They should easily answer: What changed? Why? How risky? How validated? Where to focus? Add more context for risky/broad/behavior-changing PRs; keep small PRs concise but still specific.

### Pre-submit validation
- Title clear and accurate.
- Body matches the actual work.
- Template used if one exists.
- Relevant sections filled meaningfully.
- Assumptions/unknowns labeled.
- No vague or misleading statements.

### Hard rule
**Never** submit a low-information, misleading, or carelessly filled PR. Revise until accurate, clear, and reviewer-friendly.

### Example — good PR body
```
## Summary
Add an idempotency check before sending invoice emails during webhook retry handling.

## Why
A timeout from the delivery provider could trigger a retry even when the original request later succeeded, risking duplicate invoice emails.

## Risk / Impact
Low to medium. Affects the retry path for invoice notifications.

## Testing
- Added unit tests for duplicate-send prevention
- Verified existing retry tests still pass
- Manually reviewed the retry flow for idempotency coverage

## Reviewer Notes
Please pay special attention to the retry branch and the idempotency key lookup logic.

## Follow-up / Unknowns
None.
```

### Example — handling unknowns honestly
```
## Unknowns / Assumptions
I did not verify behavior against the legacy admin entry point because that environment was not available in this run.
```
