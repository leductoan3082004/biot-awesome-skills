---
name: deep-investigate
description: Use when debugging, investigating, troubleshooting, OR walking through code/control flow. Two modes — (a) evidence-driven investigation, and (b) MANDATORY response shape for any code explanation. **Shape A** (inline-narrated code): ~5–15 line pruned snippet, `//` comment on EVERY non-trivial line, cmd-clickable `/abs/path:N` anchor above. **Shape B** (ASCII tree): `├── └── │` + `#` comment per node for branching/fan-out/call-hierarchy/decision-logic. A code block with zero inline comments is a violation. Numbered post-block "1./2./3." re-narration is forbidden, even disguised as "Where to look next", "Three states", "N places to check". Triggers — "debug this", "investigate why", "walk me through", "trace flow", "show me how X works", "what calls what", "decision logic", "fan-out".
---

# Deep Investigate

Two modes, both enforced:

1. **Investigation methodology** — evidence-driven, never stop at hypothesis.
2. **Response shape for code explanations** — MUST follow rules below. This is the most-violated part; check the self-check before submitting.

**Core principle:** A plausible code path that *could* produce a symptom is NOT evidence that it *does*. Prove causation.

---

## Response Format for Code & Control Flow (MUST FOLLOW)

Any response that explains or walks through on-disk code MUST pick one of two shapes. Refusing to produce code by describing in prose when the user asks "walk me through `<function>`" is a bypass — forbidden.

| Topic | Shape |
|---|---|
| Branching, fan-out, call hierarchy, decision logic, "what calls what", "which branch wins" | **Shape B — ASCII tree** |
| A specific transformation, syntax-dependent bug, or one function's literal behavior | **Shape A — inline-narrated code** |
| Cross-service hop sequence | Arrow chain `A → B → C` |

Default to Shape B when unsure. Trees show more in less space.

### Shape A — Inline-Narrated Code

REQUIRED structure (all five rules):

1. **Summary sentence above the anchor** — one sentence naming branches/flow (for branching functions) OR the function's purpose (for non-branching functions like mappers/transforms). NEVER skip this — the anchor must not be the first thing on the line. Examples: "Three branches: bad-input, not-found, happy path." OR "Maps gRPC `X.AsObject` to GraphQL `XType` shape — every field is a rename, call, or conversion."
2. **Cmd-clickable anchor** above the block in backticks: `` `/abs/path/file.ext:N` ``. Absolute path, single-line `:N` (NOT `:N-M`), no `[label](file://...)` wrapper.
3. **Fenced `` ```<lang> `` block, ~5–15 lines.** Prune to relevant lines; replace skipped regions with `// ...` (or `#`, `--`, `;` per language).
4. **`//` comment on EVERY non-trivial line.** This is the core mechanic — a code block without comments is forbidden, equivalent to a verbatim dump. Count: `(non-trivial code lines) == (// comments)`. **Non-trivial includes:** any field mapping inside a return object (`id: personnel.personnelId` is a rename — comment it), any function call (`convertAccess(x)` — comment what the call does or why), any type conversion (`getISOString(x)` — comment the conversion), any guard / branch / loop. **Skip only truly trivial:** bare `return x`, plain `if err != nil { return err }`, plain `}`, plain language keywords with no semantic action. When in doubt, comment it. **Object-literal special rule: EVERY field inside a `return { ... }` literal earns a comment — no exceptions for "obvious" pass-throughs, "obvious" timestamps, or "obvious" renames.** Use `// pass-through` for identity copies, `// rename <a> → <b>` for renamed fields, `// <type-conversion>` for transforms. Skipping even one field violates A4.
5. **No numbered post-block re-narration.** Post-block prose is for NEW info only (gotchas, dormant paths, cross-cutting insights). NO `1. … 2. … 3. …` under any heading — including disguises like "Where to look next", "To fix: 1./2./3.", "Two places to check", "N steps", "Three states".

✅ Example (note one `//` comment per non-trivial line, including return-object field mappings):

Three branches: bad-input rejection, not-found rejection, happy path.

`` `/Users/<user>/Developer/<repo>/<path>/foo.ts:42` ``:

```ts
export async function foo({ id }, ctx) {
  // Guard: reject empty id before any RPC
  if (!id) throw new Error('bad input')
  // Fetch from downstream service
  const result = await ctx.svc.fetch(id)
  // Empty = not found; throw so callers don't get a silent null
  if (!result) throw new Error('not found')
  return result
}
```

✅ Example for a mapping/transform function (note the summary sentence above the anchor, AND every field including pass-throughs has a `//` comment):

Maps gRPC `X.AsObject` to GraphQL `XType` — every field is a rename, function call, type conversion, or annotated pass-through.

`` `/Users/<user>/Developer/<repo>/responses.ts:132` ``:

```ts
function convertX(x: X.AsObject): XType {
  return {
    access: convertAccess(x.access),       // pivot flat proto enum → list-of-pairs
    body: tryParseJSON(x.body),            // JSON string from gRPC → object (null on parse fail)
    id: x.xId,                             // rename xId → id for GraphQL shape
    txid: x.txid,                          // pass-through; same name on both sides
    createdAt: getISOString(x.createdAt),  // epoch int → ISO 8601 string
    user: convertUser(x.userInfo),         // delegate sub-object transform
  }
}
```

The pass-through line (`txid: x.txid`) still gets a `//` annotation noting that it's unchanged. **Every line inside the `return {}` literal earns a comment — no exceptions.**

### Shape B — ASCII Tree / Flow Diagram

REQUIRED structure (all four rules):

1. **Fenced ASCII block** using `├──` `└──` `│` for hierarchy, `→` `↓` for sequence. NOT markdown bullets, NOT bold paragraphs, NOT a two-column `│`+`─` table layout (that's a table, not a tree).
2. **`#` comment after EVERY non-leaf node**, explaining what it does or which branch it represents. `#` regardless of host language. **Substitutes are FORBIDDEN:** `[brackets]` for file refs are wrong — use `# <file>:<N>`. Parenthetical descriptions `(creates both stubs)` are wrong — use `# creates both stubs`. The `→` arrow shows flow, not explanation — `node → next` still needs `# what node does`.
3. **Decision branches** labeled `├── yes → <action>` / `└── no → <action>`. Predicate (`X == nil ?`) goes on the parent node; children carry the resolved values. Raw condition expressions as branch labels (`├── X == nil`) are wrong — even for sequential `if`-chains in source code, the tree representation MUST nest. **This applies to N-way decisions too: flattening multiple mutually-exclusive conditions into a single-level list is FORBIDDEN.** Example: source code `if A == nil { ... } if B == nil { ... } /* else fallthrough */` becomes:

```
A == nil ?
├── yes → <action when A is nil>
└── no
    └── B == nil ?
        ├── yes → <action when only B is nil>
        └── no  → <fallthrough action>
```

NOT this flat form (forbidden, even though the three branches are mutually exclusive):

```
├── A == nil                  # WRONG — flat condition label
├── A != nil && B == nil      # WRONG — flat compound label
└── both != nil               # WRONG — should be the `└── no → no` leaf of nested tree
```

If your decision tree has 3+ branches, build the nested form — do NOT flatten.
4. **One line per node.** Function name (or condition) + one-phrase intent. Multi-step actions chain with `→` on the same line OR nest as further children. NEVER as a column of `→ stepN` lines under the same branch.

✅ Example fan-out:

```
GetPersonnel(userId)
├── komrade.GetUser(target)          # identity lookup
│   └── komrade.GetUser(supervisor)  # only if target.supervisor set
├── records.GetPersonnelEntities     # user + personnel entity
│   ├── BatchGetBranchEntities       # by user id
│   └── BatchGetRelated              # follow UserPersonnel edge
└── makePersonnelProfile             # auto-provision + access mask
```

✅ Example decision tree (note: predicate as parent, `yes/no` as children):

```
caller whitelisted ?
├── yes → return full access map; done
└── no
    ├── caller.UserID == nil → InvalidInputError
    └── load caller groups + CH tree → compute access mask
```

### Forbidden Bypasses (DO NOT produce any of these)

| Bypass shape | Why wrong | What to use instead |
|---|---|---|
| Verbatim function + `1. … 2. … 3. …` prose below | Reader maps prose↔line | Shape A with inline `//` |
| Code block with **zero** `//` comments | Comments ARE Shape A | Shape A — add `//` per non-trivial line |
| Bulleted summary of field mappings (`- foo → bar.baz`) instead of code block | Bullets aren't Shape A | Actual fenced code block with comments |
| Plain-text list inside a fenced block ("`access, body, createdAt, ...`") instead of source code | A list of names is not Shape A | Real `` ```ts `` block with the function body + `//` per line |
| Refusing to show code by describing in prose when user asks "walk me through `<function>`" | Code-walks require a code block | Shape A — produce the fenced block |
| Numbered list anywhere after a code block / tree, under ANY heading ("Where to look next", "To fix: 1./2./3.", "Three states", "Two places", "Key points 1./2./3.", "N triggering conditions") | Disguised re-narration | Single prose paragraph of NEW info, or extend the tree |
| Anchor `` `funcName` (lines N–M) `` or relative path | Not cmd-clickable | `/abs/path:N` |
| Tree with `[brackets]` for file refs | Skill mandates `#` | `# <file>:<N>` |
| Tree node with parenthetical description `node (does X)` instead of `# does X` | Parens are NOT `#` syntax — skill requires `#` | `node  # does X` |
| Code block of `return { ... }` object literal without `//` on each field | Each mapping is non-trivial (renames/calls/conversions) | `field: source, // explanation` per line |
| Tree decision branches as raw conditions (`├── X == nil`) | Decision tree must root at predicate | Predicate parent → `├── yes → ...` / `└── no → ...` |
| Tree node action chains as column of `→ stepN` lines | Wrap into single-line chain or nest | One-line chain `→ A → B` OR nested children |
| Markdown table with `│ ─` separators for branching | Table ≠ tree | Tree with `├── └──` |

### Self-Check Before Submitting (MANDATORY — run mentally before every response)

- [ ] If response has a fenced source-code block: every non-trivial line has a `//` (or host-language) comment? Count matches?
- [ ] If response has a tree: every non-leaf node has a `# <intent>`? `[brackets]` replaced with `# ...`?
- [ ] If response has a decision tree: parent is a predicate ending with `?`, children are `yes/no`?
- [ ] After the block/tree: any `1. … 2. … 3. …` under any heading? If yes — rewrite as prose paragraph.

If any check fails: rewrite. Do not submit.

### When neither shape applies

Skip both ONLY for copy-paste configs, API request/response shape examples, minimal repros, one-line commands, or generated artifacts. For these, keep the block clean and narrate above.

---

## Investigation Methodology (when debugging hard problems)

### The Three Laws

1. **Work until done** — don't stop at hypothesis. Keep going until fix is verified.
2. **Never assume** — missing context → ask. Think you know what a function does → read it.
3. **Prove, don't pattern-match** — code that *could* produce a symptom is a *lead*, not a conclusion. Demonstrate the specific path is actually triggered with the actual wrong values.

### Phases

1. **Understand** — reproduce, define delta (actual vs expected), scope, gather context. Exit: can state problem in one precise paragraph.
2. **Map** — read the actual code, trace data flow entry-to-exit, identify boundaries (most common failure points). Exit: complete mental model of data flow.
3. **Narrow** — add instrumentation (`console.log` at boundaries), bisect (correct entering X? Yes → bug after X; No → bug before X), one variable at a time. Exit: narrowed to specific location where correct data enters and incorrect exits.
4. **Prove** — demonstrate THIS code with THIS input produces THIS wrong output. Explain the mechanism. Write a minimal failing test. Rule out alternatives. Exit: "Root cause is [X] because [evidence]. Verified by [test/observation]. Ruled out [alternatives] by [how]."
5. **Fix** — at the source, minimal change, verify reproduction now passes.
6. **Validate** — re-run repro, check edge cases, run related tests, confirm with user.

### Red Flags — STOP and re-investigate

| Red flag | Do instead |
|---|---|
| "Code path could produce this symptom, so this is the bug" | LEAD not conclusion — prove it IS triggered |
| "Root cause is clear" (without reading source) | Read the actual code first |
| "I found something similar" | Similar ≠ same — verify the specific path |
| "I think the issue is..." (no evidence) | Replace "I think" with "I verified by [action]" |
| "Based on my analysis of the code..." (without executing) | Static analysis insufficient — run/log/watch |
| Listing multiple possible causes | Pick one, prove or disprove, then next |
| "I'm pretty confident" / "most likely" / "probably" | Confidence without evidence = guessing |
| Reading descriptions instead of source | Descriptions omit edge cases — read the code |

### When stuck

Widen scope (re-examine Map assumptions) → add more instrumentation → ask user for what you need → trace backward from symptom.

NEVER: conclude without proof, propose multiple causes for user to pick, give up and suggest workaround before proving root cause, stop because "investigated for a while."

### Self-check before concluding the investigation

- [ ] Read the actual code (not descriptions)?
- [ ] Executed/instrumented to verify runtime behavior?
- [ ] Proved this code path triggers in the failing case (not just *could*)?
- [ ] Ruled out alternatives with evidence?
- [ ] Reproduced the bug with a minimal test?
- [ ] Fix matches stated root cause?

If any unchecked: keep investigating.

---

## Related Skills

- **superpowers:systematic-debugging** — 4-phase debugging framework. Deep-investigate adds stricter evidence requirements.
- **context-save** — checkpoint state during long sessions.
- **clickable-file-anchors** — spec for the cmd-clickable anchor format used in Shape A above.
