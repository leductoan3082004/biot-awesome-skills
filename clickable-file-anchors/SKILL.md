---
name: clickable-file-anchors
description: Use when quoting source code in a walkthrough, code review, debugging trace, or explanation — the file reference that introduces each quoted block must be cmd-clickable in iTerm2 so the user can jump straight into VSCode/Cursor at that line. Triggers on any response that includes fenced code blocks of source quoted from an on-disk file, or any "where is X defined / show me Y" style answer that anchors back to specific lines.
---

# Clickable File Anchors

## Overview

When quoting source code in a response, the file reference that **introduces the quoted block** must be a single absolute path with a line anchor that iTerm2 + VSCode/Cursor recognize as cmd-clickable.

Relative paths (`packages/iris/src/foo.ts:42`) are **not** clickable in iTerm2's Semantic History. Markdown links to `file://` URIs are not clickable either — iTerm2 ignores the markdown wrapper. Only **bare absolute paths with `:line`** trigger the open-in-editor handoff.

## Required Format

```
`/Users/toale/Developer/<repo>/<path-from-repo-root>:<start-line>`:
```

- Wrap in single backticks so the path renders as inline code.
- Path **must** be absolute and **must** start with `/Users/toale/Developer/` (or another absolute root the user has on disk).
- Line anchor is **a single integer** = the first line of the quoted span. Do **not** use range syntax (`:172-176`) — iTerm2 + VSCode parse `:line`, not `:line-line`.
- Follow the inline-code anchor with a colon, then the fenced code block on the next line. No prose between anchor and block.
- The fenced block itself shows the full range, so range info is preserved visually without breaking clickability.

### Canonical example

````markdown
`/Users/toale/Developer/personnel/service/personnel.go:150`:

```go
func (s *PersonnelSvc) GetPersonnel(
  ctx context.Context, req *pb.GetPersonnelRequest,
) (*pb.GetPersonnelResponse, error) {
  funcName := "GetPersonnel"
  // ...
}
```
````

## When to Use

Apply **only** to the inline anchor that introduces a fenced code block quoted from a real on-disk file. Specifically:

- Code-walk responses (file → function → callee, quote-and-narrate style).
- Debugging traces that quote the offending line.
- Code reviews that quote the diff context.
- "Show me where X is defined" answers.

## When NOT to Use

Keep these references in whatever short form reads naturally — they are **not** clickable anchors:

- Inline prose mentions ("…handled by `personnel.go`'s `GetPersonnel` handler…").
- Markdown table cells listing files.
- Function/symbol references without an attached quoted block.
- Bulleted file lists in summaries or punch lists.
- Generated/virtual paths (`~/go/pkg/mod/...` is fine if it resolves on disk; pure placeholder paths are not).

The rule is scoped to **anchors that immediately precede a fenced code block**. Anything else stays terse.

## Quick Reference

| Situation | Anchor format |
|---|---|
| Quoting a function body | `` `/Users/toale/Developer/<repo>/<path>:<first-line-of-fn>` `` |
| Quoting a range of lines | Anchor = **first** line of the range; range shown by the block itself |
| Quoting a single line | `` `/Users/toale/Developer/<repo>/<path>:<line>` `` |
| Quoting from `~/go/pkg/mod/...` (Go module cache) | Expand `~` to `/Users/toale/go/pkg/mod/...` (it's a real on-disk path) |
| Quoting a generated file the user doesn't have | Skip this skill — note "generated, not on disk" instead |

## Common Mistakes

| ❌ Wrong | ✅ Right | Why |
|---|---|---|
| `` `packages/iris/src/shared/routes/routes.ts:172-176` `` | `` `/Users/toale/Developer/iris/packages/iris/src/shared/routes/routes.ts:172` `` | Relative path → not clickable. Range → not parsed. |
| `` `personnel/service/personnel.go:150-197` `` | `` `/Users/toale/Developer/personnel/service/personnel.go:150` `` | Repo-relative is not absolute. iTerm2 cannot resolve. |
| `[personnel.go:150](file:///Users/toale/Developer/personnel/service/personnel.go#L150)` | `` `/Users/toale/Developer/personnel/service/personnel.go:150` `` | Markdown link to `file://` URI: iTerm2 ignores the wrapper. Bare path inside backticks works. |
| `` `/Users/toale/Developer/personnel/service/personnel.go` `` (no line) | `` `/Users/toale/Developer/personnel/service/personnel.go:150` `` | No line anchor → opens at top of file, defeats the purpose. |
| Anchor with prose between it and the code block | Anchor directly before the fenced block | Visually breaks the "click here to see this exact span" affordance. |

## Red Flags — STOP and Fix Before Sending

- A fenced code block is preceded by a path that does **not** start with `/`.
- An anchor uses `:NNN-MMM` range syntax.
- An anchor is wrapped in a markdown link `[label](file://...)`.
- A file reference and its code block are separated by a sentence of prose.

All four mean: rewrite the anchor as a bare absolute path with a single-line suffix in backticks, placed directly above the block.

## Rationalizations to Reject

| Excuse | Reality |
|---|---|
| "Relative path is shorter and the repo is obvious from context" | iTerm2 does not infer workspace root. Relative = not clickable. |
| "I'll use a markdown link to make it explicit" | iTerm2 ignores markdown link wrappers; the inner URI never gets handed to the editor. Bare path wins. |
| "Range syntax `:172-176` reads better" | VSCode/Cursor `--goto` parses `file:line[:col]` only. Range → cmd-click no-op or opens file at line 1. |
| "The user can see the lines in the block, anchor format doesn't matter" | The whole point of the anchor is jumping into the editor at the right place. If it doesn't click, the skill fails its purpose. |
| "This file is only mentioned in passing, not quoted" | Then the skill does **not** apply — leave the inline mention in its natural short form. |

## Real-World Impact

Before this skill, a code-walk response anchors blocks with `packages/iris/src/.../foo.ts:42-58`. User has to read the path, mentally prepend the workspace root, open VSCode, `Cmd+P` the file, then jump to line 42. ~10 seconds of friction per anchor, dozens of times per walkthrough.

After this skill, every block is preceded by a bare absolute path ending in `:N`. Cmd-click in iTerm2 hands the path to VSCode/Cursor's URL handler, which opens the file scrolled to the exact line. Zero friction.
