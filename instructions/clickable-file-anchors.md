# Clickable File Anchors

File references must be **cmd-clickable** so the user jumps straight into the editor at the right line. The right format depends on **which agent is rendering the response**, because the click is handled by a different layer in each case.

Pick the surface that matches the agent you're running as.

---

## Surface A — Codex (web / desktop chat UIs)

Applies to: Codex web, Codex desktop, claude.ai conversation UI, and any other agent whose responses render through an HTML DOM.

The chat app parses Markdown and turns `[label](url)` into a real `<a href>` element. The app itself intercepts the click and opens `path:line` in the editor. So emit a **Markdown local link** whose target is a bare absolute path with a single-integer line anchor:

```
[label](/absolute/path/to/file:line)
```

For paths containing spaces, **wrap the link target in angle brackets** so Markdown parses the URL correctly:

```
[My File.md](</absolute/path with spaces/My File.md:12>)
```

### Why not backticked raw paths in Codex?

`` `/abs/path:line` `` renders as **inline code** — visually distinct but **not a link**. No `<a href>`, no click handler.

### Why not `file://` URLs?

The chat app does not resolve `file://` URIs. Bare absolute path is what the click handler expects.

---

## Surface B — Claude Code (terminal CLI)

Applies to: Claude Code, and any other agent that streams plain text to a terminal (iTerm2 / Warp / Terminal.app).

Claude Code does **not** handle the click itself — the **terminal's semantic-history feature** does, by regex-matching visible text for path-like tokens and forwarding the click to VSCode / Cursor / Neovim. Markdown brackets and parens **break** that regex, so a Markdown link is not clickable here. A **bare backticked absolute path** + `:line` is what the terminal detects:

```
`/absolute/path/to/file:line`
```

Place the anchor on its own line, **directly above the fenced block** it introduces, with a trailing colon and **no prose between** anchor and block. The fenced block preserves the line range visually.

### Canonical code-walk shape (Claude Code)

````markdown
`/Users/toale/Developer/<repo>/<path>:<first-line-of-quoted-span>`:

```<lang>
<quoted lines>
```
````

### Inline mentions in Claude Code

When the reference is not introducing a fenced block (e.g., just pointing at a line), the same bare backticked form is still the right click target: `` `/Users/toale/Developer/iris/packages/iris/src/foo.ts:42` ``.

---

## Why the surfaces differ

| Surface | Click handler | Sees | Needs |
|---|---|---|---|
| Codex chat UI | The chat app (HTML link click) | Parsed Markdown → `<a href>` | Valid Markdown link `[label](/abs/path:N)` |
| Claude Code CLI | The terminal (semantic-history regex) | Raw rendered text | Bare backticked `/abs/path:N` |

A Markdown link emitted into Claude Code renders as styled text but the brackets/parens prevent the terminal from recognizing the path. A bare backticked path emitted into Codex renders as inline code and produces no click handler. The formats are **not interchangeable** — pick by agent.

---

## Universal rules (both surfaces)

- Target **MUST** be an absolute path starting with `/`.
- Line anchor **MUST** be a single integer. Range syntax (`:172-176`) does not parse in either Markdown link targets or terminal semantic-history.
- **No** `file://` URLs — terminals ignore the wrapper, chat apps do not resolve them.
- Range info is conveyed by the **fenced block's contents**, never by the anchor.
- Apply to any reference the user is meant to click — inline prose mentions AND code-walk anchors.

---

## Quick reference

| Agent | Format | Example |
|---|---|---|
| Codex | `[label](/abs/path:N)` | `[foo.ts](/Users/toale/Developer/iris/packages/iris/src/foo.ts:42)` |
| Codex, path has spaces | `[label](</abs/path with spaces:N>)` | `[Notes.md](</Users/toale/Developer/zeke/My Notes/Notes.md:7>)` |
| Claude Code | `` `/abs/path:N` `` (own line above fenced block, or inline) | `` `/Users/toale/Developer/personnel/svc.go:150` `` |

---

## Wrong → Right

| ❌ Wrong | ✅ Right | Why |
|---|---|---|
| `packages/iris/src/foo.ts:42` (any agent) | absolute path | Relative path not resolvable |
| `[foo.ts](/abs/path/foo.ts:42)` in **Claude Code** | `` `/abs/path/foo.ts:42` `` | Markdown brackets break terminal semantic-history regex |
| `` `/abs/path/foo.ts:42` `` in **Codex** | `[foo.ts](/abs/path/foo.ts:42)` | Backticks render as inline code, no `<a href>` produced |
| `[foo.ts](file:///abs/path/foo.ts#L42)` (any agent) | `[foo.ts](/abs/path/foo.ts:42)` (Codex) or `` `/abs/path/foo.ts:42` `` (Claude Code) | `file://` not resolved; `#L42` not the anchor format |
| `` `/abs/path/svc.go:150-197` `` | `` `/abs/path/svc.go:150` `` | Range syntax does not parse |
| Anchor with prose between it and the fenced block | Anchor on its own line, immediately above the block | Breaks the visual "click here to see this exact span" affordance |

---

## When this rule does NOT apply

- Bulleted file lists in summaries / punch lists — keep terse.
- Markdown table cells listing files — anchor format is overkill.
- Brief inline mentions where the user does not need to click ("…see also `helper.ts`…").

The rule binds anchors that the user is **meant** to click. Everything else stays terse.
