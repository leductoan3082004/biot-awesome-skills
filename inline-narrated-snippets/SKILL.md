---
name: inline-narrated-snippets
description: Use when explaining source code in a walkthrough, code review, debugging trace, or any "walk me through X / how does Y work / trace this logic / explain this flow" response — the explanation must live as inline comments inside a PRUNED code snippet, not as a separate enumerated list of steps after the block. Triggers whenever a response would otherwise place a fenced source-code block followed by a numbered "1. … 2. … 3. …" prose breakdown of the same lines. Designed to remove the prose↔line mapping friction the reader otherwise pays per block.
---

# Inline-Narrated Snippets

## Overview

When walking through code, the **inline comments inside the snippet** carry the explanation. Pure code blocks followed by a separately enumerated list of steps force the reader to map "1." back to a specific line, then "2." to another line, etc. — that mapping is friction the reader pays per block, multiplied across the dozens of blocks in a real walkthrough.

Inline narration removes the mapping step: each line's explanation sits on the line itself.

Pair with the `clickable-file-anchors` skill so the anchor above each block is cmd-clickable to the source.

## Required Shape

For each code-walk segment:

1. **One-line context sentence (optional)** above the anchor, naming the branches / control flow at a high level — e.g. "Three branches: bad-input rejection, not-found rejection, happy path."
2. **Clickable anchor** in backticks: `` `/abs/path/file.ext:N` ``.
3. **Pruned code block** containing only the lines that carry the explanation. Replace skipped regions with `// ...` (or the language's comment syntax). Aim for ≤ ~15 lines per block; split long functions into phase-named sub-blocks.
4. **Inline comments at every non-trivial line**, explaining WHAT the line does and (when not obvious) WHY. Comments must use the host language's syntax — `//` for Go/TS/JS/Rust/Java, `#` for Python/Shell/Ruby, `--` for SQL/Lua, `;` for Lisp/Clojure.
5. **No post-block enumerated narration** that re-describes lines already commented in the snippet.

Post-block prose is reserved strictly for content that is NOT in the snippet:

- gotchas and edge cases the snippet doesn't show,
- cross-cutting insights ("this caller path is dormant in prod"),
- the bridge to the next callee being inlined below,
- a small `Input → Output` example for non-trivial transforms (see realistic-fixtures lesson).

## Canonical Example

### ❌ Before (the friction pattern)

```ts
export async function basePersonnel({ userId }, { auth, dataSources }) {
  if (!userId || !UUID_LIKE_REGEX.test(userId)) {
    throw new UserInputError(`Invalid user ID: ${userId}`)
  }
  const personnels = await dataSources.personnelService.getPersonnels({ auth, userIds: [userId] })
  if (personnels.length === 0) {
    return Promise.reject(new UserInputError(`Personnel not found for userId: ${userId}`))
  }
  return personnels[0]
}
```

Four parts:
1. Validates UUID shape, throws on bad input.
2. Calls the plural service method with a one-element array.
3. Rejects on empty result.
4. Returns the singleton.

The reader has to map `1. → line 2`, `2. → line 5`, `3. → line 6`, `4. → line 9`. Four context switches per block, hundreds of blocks per real walkthrough.

### ✅ After (inline-narrated)

Three branches: bad-input rejection, not-found rejection, happy path.

`` `/Users/toale/Developer/<repo>/src/gql/resolvers/queries/personnel.ts:18` ``:

```ts
export async function basePersonnel({ userId }, { auth, dataSources }) {
  // Guard: reject non-UUID-shaped input before issuing any RPC
  if (!userId || !UUID_LIKE_REGEX.test(userId)) {
    throw new UserInputError(`Invalid user ID: ${userId}`)
  }
  // PLURAL endpoint even for a single-id read — DataLoader batches singletons across resolvers
  const personnels = await dataSources.personnelService.getPersonnels({ auth, userIds: [userId] })
  // Empty list = not found; reject so Apollo surfaces UserInputError instead of returning null
  if (personnels.length === 0) {
    return Promise.reject(new UserInputError(`Personnel not found for userId: ${userId}`))
  }
  return personnels[0]   // singleton happy path
}
```

Each line carries its own explanation. No post-block re-narration.

## When to Use

Apply to every code block in a:

- code walkthrough ("walk me through X"),
- function explanation ("how does Y work"),
- control-flow trace ("trace the request from A to B"),
- code review where the reviewer needs to know what each line does,
- debugging post-mortem quoting the offending lines.

## When NOT to Use

Skip inline narration for blocks where the code IS the answer and per-line meaning doesn't apply:

- copy-paste configuration snippets meant to be pasted verbatim,
- API request/response shape examples,
- minimal repros where lines have no individual meaning,
- one-line commands,
- generated artifacts (codegen, proto output) where added comments would mislead.

For these, keep the block clean and any explanation in prose above.

## Quick Reference

| Situation | Shape |
|---|---|
| Function body walk | Pruned function, branches named above, inline `//` on each non-trivial line |
| Showing one branch of a switch / if-chain | Quote only that arm; comment the predicate and the body; `// ...` for siblings |
| Long function (>40 lines) | Multiple pruned blocks, one per logical phase, phase name above each anchor |
| Function calls a helper worth inlining | Finish parent's inline narration first, then a new anchor + block for the helper |
| Dead / dormant code path | Inline `// dead in prod — <reason>` directly on the relevant line |
| Shape transform (input ≠ output) | Inline comments + a fenced `Input → Output` example block AFTER |

## Common Mistakes

| ❌ Wrong | ✅ Right |
|---|---|
| Paste verbatim 30-line function, then `1. Does X. 2. Does Y.` re-narrating each line | Prune to ~8 relevant lines; inline `//` comment each non-trivial line |
| Comment every single line including obvious ones (`// return x`) | Comment only non-trivial lines; let `return x` and `if err != nil { ... }` speak for themselves |
| Move the explanation back to post-block prose because "comments interfere with copy-paste" | The block is for reading, not for pasting; comments ARE the explanation |
| Leave skipped regions blank between the kept lines | Use `// ...` (or language equivalent) to make the prune visible |
| Use markdown / HTML comments inside the code block | Use the host language's comment syntax (`//`, `#`, `--`, `;`) — markdown comments don't render inside fenced blocks |
| One mega-block of 60+ lines with comments scattered | Split into phase-named sub-blocks with their own anchors |

## Red Flags — STOP and Rewrite

- A code block is followed by `1. ... 2. ... 3. ...` describing what the block does line-by-line.
- A code block has zero `//` (or `#`) comments and a paragraph below restates the code in English.
- A code block is a verbatim file paste — every line included regardless of relevance.
- Two adjacent blocks overlap because the second one re-quotes the first "to show the missing piece" — instead, prune the first to exclude what the second covers.
- Comments use a syntax the host language doesn't recognize (e.g. `//` in a Python block).

## Rationalizations to Reject

| Excuse | Reality |
|---|---|
| "Inline comments clutter the code" | The block is *pedagogical*, not pasteable. Comments here are signal, not clutter. |
| "The numbered list mirrors the code 1:1, same information" | 1:1 mirror means a mandatory mapping step for the reader. That mapping is the friction this skill removes. |
| "User can read the code themselves" | Then why include the snippet at all? If self-evident, skip the snippet and the narration both. |
| "I want the code to look like the file" | If you need an archival quote, do it elsewhere. Walk-blocks exist to teach, not to mirror disk. |
| "The function is too short to need inline comments" | Then it's also too short to need a separate numbered narration. Drop the narration, leave the snippet bare. |
| "Inline comments belong only in source, not in explanations" | This is an explanation USING code as a substrate. The substrate's comment syntax is the natural carrier of explanation. |

## Composability

- **Pair with `clickable-file-anchors`** — anchor above the block (cmd-clickable), inline narration inside the block. The two skills together cover "where" and "what".
- **Pair with the realistic-fixtures lesson** — if the block is a non-trivial transform, follow it with a small `Input → Output` example block. The `Input → Output` block is one of the few legitimate post-block additions.

## Real-World Impact

A walkthrough with 20 code blocks in the old shape costs the reader ~20 × 4 = 80 prose-to-line mappings. With inline narration, that drops to zero. The walkthrough also becomes shorter (no duplicated content) and easier to skim — readers can scan inline comments without descending into code, then drop into a specific block when something interesting catches their eye.
