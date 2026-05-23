# Clickable File Anchors

File references in agent responses must be **cmd-clickable** so the user can jump straight into the editor / IDE at the right line. There are two rendering surfaces and each needs a different format. Pick the one that matches the surface you are rendering into.

---

## Surface A — Claude Code / Codex chat UI (Markdown-rendered)

This is the default surface for normal conversational responses. The UI renders Markdown, so emit a **Markdown local link** whose target is a bare absolute path with a single-integer line anchor:

```
[label](/absolute/path/to/file:line)
```

For paths containing spaces, **wrap the link target in angle brackets** so Markdown parses the URL correctly:

```
[My File.md](</absolute/path with spaces/My File.md:12>)
```

### Why not backticked raw paths?

`` `/abs/path:line` `` renders as **inline code** in this UI — visually distinct but **not clickable**. The Markdown link wrapper is what makes the path a click target.

### Why not `file://` URLs?

The UI does **not** resolve `file://` URIs. Use a bare absolute path instead.

---

## Surface B — Terminal cmd-click (iTerm2 / Warp / Terminal → VSCode / Cursor / Neovim)

Use this surface for code-walk anchors that introduce a fenced code block, debugging traces, or anywhere the terminal's semantic-history feature does the cmd-click handoff. The terminal does **not** parse Markdown link wrappers — only a **bare backticked absolute path** + `:line` triggers the IDE handoff:

```
`/absolute/path/to/file:line`
```

Place the anchor on its own line, **directly above the fenced block**, with a trailing colon and **no prose between** anchor and block. The fenced block preserves the line range visually.

### Canonical code-walk shape

````markdown
`/Users/toale/Developer/<repo>/<path>:<first-line-of-quoted-span>`:

```<lang>
<quoted lines>
```
````

---

## Universal rules (both surfaces)

- Target **MUST** be an absolute path starting with `/`.
- Line anchor **MUST** be a single integer. Range syntax (`:172-176`) does not parse in either Markdown link targets or terminal semantic-history.
- **No** `file://` URLs — terminals ignore the wrapper, UI does not resolve them.
- Range info is conveyed by the **fenced block's contents**, never by the anchor.
- Apply to any reference the user is meant to click — inline prose mentions AND code-walk anchors.

---

## Quick reference

| Surface | Format | Example |
|---|---|---|
| Chat UI (Markdown) | `[label](/abs/path:N)` | `[foo.ts](/Users/toale/Developer/iris/packages/iris/src/foo.ts:42)` |
| Chat UI, path has spaces | `[label](</abs/path with spaces:N>)` | `[Notes.md](</Users/toale/Developer/zeke/My Notes/Notes.md:7>)` |
| Terminal code-walk | `` `/abs/path:N` `` directly above fenced block | `` `/Users/toale/Developer/personnel/svc.go:150` `` |

---

## Wrong → Right

| ❌ Wrong | ✅ Right | Why |
|---|---|---|
| `packages/iris/src/foo.ts:42` | `[foo.ts](/Users/toale/Developer/iris/packages/iris/src/foo.ts:42)` (chat) | Relative path → not resolvable |
| `` `packages/iris/src/foo.ts:42` `` (chat UI) | `[foo.ts](/Users/toale/Developer/iris/packages/iris/src/foo.ts:42)` | Backticked raw paths are not clickable in this UI |
| `[foo.ts](file:///abs/path/foo.ts#L42)` | `[foo.ts](/abs/path/foo.ts:42)` | `file://` not resolved; `#L42` not the anchor format |
| `` `/Users/toale/.../svc.go:150-197` `` | `` `/Users/toale/.../svc.go:150` `` | Range syntax doesn't parse |
| Anchor with prose between it and the fenced block | Anchor on its own line, immediately above the block | Breaks the visual "click here to see this exact span" affordance |

---

## When this rule does NOT apply

- Bulleted file lists in summaries / punch lists — keep terse.
- Markdown table cells listing files — anchor format is overkill.
- Brief inline mentions where the user does not need to click ("…see also `helper.ts`…").

The rule binds anchors that the user is **meant** to click. Everything else stays terse.
