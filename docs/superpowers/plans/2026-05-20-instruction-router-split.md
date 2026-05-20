<!-- /autoplan restore point: /Users/toale/.gstack/projects/leductoan3082004-biot-awesome-skills/main-autoplan-restore-20260520-185532.md -->
# Instruction Router Split — Implementation Plan (v2, post-review)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split monolithic `CLAUDE.md` (214 lines) + `AGENTS.md` (366 lines) into short router files plus on-demand topic files under `instructions/`, per walkinglabs lecture 04 router pattern. **Drop accumulated lesson bullets entirely** (fresh-start direction from user). Repoint pattern-observer hook at new capture-sink files so future bullets still land cleanly; a follow-up user-built hook will later promote critical captures back into routers as file references.

**Architecture:** Router files keep only critical always-on rules + a routing table. Reference material lives in `instructions/<topic>.md`, loaded via the `Read` tool on demand. Lesson capture continues via `pattern-observer.py` writing to two new sink files (`instructions/lessons-captured-{claude,universal}.md`); routers do NOT reference these sinks. Two shell hooks get cosmetic prose updates.

**Tech Stack:** Markdown files, Python 3 hook, Bash hooks, git.

**Spec:** `docs/superpowers/specs/2026-05-20-instruction-router-split-design.md` (v2, post-review)

**Important constraints carried forward from review:**
- Topic file content is **verbatim** from the current router section — no rewording.
- Existing 24+ lesson bullets are **dropped** from routers (preserved in git history).
- Two new empty capture sinks (`instructions/lessons-captured-{claude,universal}.md`) MUST each contain exactly one `## Lessons` heading so the LLM-driven append finds its target. The hook does NOT parse headers in Python — it emits an instruction telling the agent to append under `## Lessons`. The seed heading is required for that LLM instruction to work.
- The hook's filename has a hyphen (`pattern-observer.py`), so `import pattern_observer` fails. All test snippets MUST use `importlib.util.spec_from_file_location`.
- Existing `/context-save` command name is preserved verbatim — do **not** drift to `/context-save-rolling`.
- All edits land in **one atomic commit + push** to `leductoan3082004/biot-awesome-skills`. On commit-hook failure, restore from snapshots captured in Task 1 and re-attempt.

---

## File Structure

**Created (12 files):**
- `instructions/commit-policy.md` — git commit policy (from AGENTS § 1)
- `instructions/pr-policy.md` — PR creation policy (from AGENTS § 2)
- `instructions/engineering-discipline.md` — anti-rationalization, 5 non-negotiables, etc. (from AGENTS § 3)
- `instructions/context-save.md` — `/context-save` policy (from AGENTS § 4)
- `instructions/agent-delegation.md` — model selection, trust/verify (from CLAUDE § 1)
- `instructions/operating-rules.md` — 12 operating rules (from CLAUDE § 2)
- `instructions/gstack-skills.md` — gstack skills index (from CLAUDE gstack section)
- `instructions/lessons-captured-claude.md` — empty capture sink (one `## Lessons` heading only)
- `instructions/lessons-captured-universal.md` — empty capture sink (one `## Lessons` heading only)
- `docs/superpowers/plans/2026-05-20-instruction-router-split.md` — this file (v2)
- `docs/superpowers/specs/2026-05-20-instruction-router-split-design.md` — v2 spec
- (Restore point file in `~/.gstack/projects/<slug>/` — already created by /autoplan)

**Modified (5 files):**
- `CLAUDE.md` — full rewrite to router shape (~70 lines, drops lessons section + stale `@RTK.md`)
- `AGENTS.md` — full rewrite to router shape (~60 lines, drops both lessons sections)
- `hooks/pattern-observer.py` — repoint `LESSONS_FILE_*` paths + update all prose mentions of CLAUDE.md/AGENTS.md
- `hooks/inject-checkpoint-reminder.sh` — update prose reference (keep `/context-save` verbatim)
- `hooks/skill-push-reminder.sh` — update prose echo

---

## Task 1: Snapshot baseline + create instructions dir

**Files:**
- Create: `/tmp/router-split-baseline-CLAUDE.md` and `/tmp/router-split-baseline-AGENTS.md` (snapshots)
- Create: `/Users/toale/Developer/biot-awesome-skills/instructions/` (directory)

- [ ] **Step 1: Capture baseline line counts**

Run:
```bash
cd /Users/toale/Developer/biot-awesome-skills
wc -l CLAUDE.md AGENTS.md
```
Expected (approximate): CLAUDE.md ~214, AGENTS.md ~366.

- [ ] **Step 2: Snapshot router files to /tmp (rollback safety)**

Run:
```bash
cp /Users/toale/Developer/biot-awesome-skills/CLAUDE.md /tmp/router-split-baseline-CLAUDE.md
cp /Users/toale/Developer/biot-awesome-skills/AGENTS.md /tmp/router-split-baseline-AGENTS.md
ls -la /tmp/router-split-baseline-*.md
```
Expected: two files exist, sizes ~12K and ~28K respectively.

- [ ] **Step 3: Verify clean git tree (ignoring untracked work)**

Run: `cd /Users/toale/Developer/biot-awesome-skills && git status --porcelain | grep -v "^??" || echo "clean"`
Expected: `clean` OR only modifications to files this plan owns (CLAUDE.md, AGENTS.md, hooks/*, docs/superpowers/*).
If tracked-file modifications exist that aren't in scope: STOP and ask user.

- [ ] **Step 4: Create instructions dir**

Run: `mkdir -p /Users/toale/Developer/biot-awesome-skills/instructions && ls -la /Users/toale/Developer/biot-awesome-skills/instructions`
Expected: empty dir.

---

## Task 2: Extract `instructions/commit-policy.md` (AGENTS § 1)

**Files:**
- Create: `/Users/toale/Developer/biot-awesome-skills/instructions/commit-policy.md`

- [ ] **Step 1: Capture source range**

Source range: `AGENTS.md` lines 11–79 (heading `## 1. Git Commit Message Policy` through end of "Bad examples (authorship)" block, before the `---` separator).

Run:
```bash
sed -n '11,79p' /Users/toale/Developer/biot-awesome-skills/AGENTS.md > /tmp/commit-policy-source.md
wc -l /tmp/commit-policy-source.md
```
Expected: 69 lines.

- [ ] **Step 2: Write target file**

Use Write tool to create `/Users/toale/Developer/biot-awesome-skills/instructions/commit-policy.md`:
- h1: `# Git Commit Message Policy`
- blockquote: `> Loaded on demand from AGENTS.md router. Read this file before composing any commit message.`
- body: paste verbatim content from `/tmp/commit-policy-source.md`, dropping the leading `## 1. Git Commit Message Policy` heading and any trailing `---` separator. Body starts at `Every commit must follow simplified Conventional Commits:`.

- [ ] **Step 3: Verify**

Run:
```bash
wc -l /Users/toale/Developer/biot-awesome-skills/instructions/commit-policy.md
grep -c "Co-Authored-By" /Users/toale/Developer/biot-awesome-skills/instructions/commit-policy.md
```
Expected: 65–75 lines; `Co-Authored-By` appears ≥ 2 times.

---

## Task 3: Extract `instructions/pr-policy.md` (AGENTS § 2)

**Files:**
- Create: `/Users/toale/Developer/biot-awesome-skills/instructions/pr-policy.md`

- [ ] **Step 1: Capture source range**

Source range: `AGENTS.md` lines 82–156.

Run:
```bash
sed -n '82,156p' /Users/toale/Developer/biot-awesome-skills/AGENTS.md > /tmp/pr-policy-source.md
wc -l /tmp/pr-policy-source.md
```
Expected: 75 lines.

- [ ] **Step 2: Write target file**

- h1: `# Pull Request Creation Policy`
- blockquote: `> Loaded on demand from AGENTS.md router. Read this file before opening or updating a PR.`
- body: verbatim from `/tmp/pr-policy-source.md`, dropping the leading `## 2. Pull Request Creation Policy` heading and any trailing `---`. Body starts at `Every PR must give reviewers enough context...`.

- [ ] **Step 3: Verify**

Run:
```bash
wc -l /Users/toale/Developer/biot-awesome-skills/instructions/pr-policy.md
grep -c "Unknowns" /Users/toale/Developer/biot-awesome-skills/instructions/pr-policy.md
```
Expected: 70–80 lines; `Unknowns` appears.

---

## Task 4: Extract `instructions/engineering-discipline.md` (AGENTS § 3)

**Files:**
- Create: `/Users/toale/Developer/biot-awesome-skills/instructions/engineering-discipline.md`

- [ ] **Step 1: Capture source range**

Source: `AGENTS.md` lines 160–216.

Run:
```bash
sed -n '160,216p' /Users/toale/Developer/biot-awesome-skills/AGENTS.md > /tmp/eng-discipline-source.md
wc -l /tmp/eng-discipline-source.md
```
Expected: 57 lines.

- [ ] **Step 2: Write target file**

- h1: `# Engineering Discipline (High Priority)`
- blockquote: `> Loaded on demand from AGENTS.md router. Read once per non-trivial task per session.`
- body: verbatim from `/tmp/eng-discipline-source.md`, dropping `## 3. ...` heading and trailing `---`.

- [ ] **Step 3: Verify**

Run:
```bash
wc -l /Users/toale/Developer/biot-awesome-skills/instructions/engineering-discipline.md
grep -c "non-negotiable" /Users/toale/Developer/biot-awesome-skills/instructions/engineering-discipline.md
```
Expected: 55–65 lines; `non-negotiable` appears.

---

## Task 5: Extract `instructions/context-save.md` (AGENTS § 4)

**Files:**
- Create: `/Users/toale/Developer/biot-awesome-skills/instructions/context-save.md`

- [ ] **Step 1: Capture source range**

Source: `AGENTS.md` lines 220–281. The current source uses the command name `/context-save`. Preserve verbatim — do NOT rename to `/context-save-rolling` (that drift was introduced in v1 of this plan and removed after /autoplan review).

Run:
```bash
sed -n '220,281p' /Users/toale/Developer/biot-awesome-skills/AGENTS.md > /tmp/context-save-source.md
wc -l /tmp/context-save-source.md
grep -c '/context-save\b' /tmp/context-save-source.md
grep -c '/context-save-rolling' /tmp/context-save-source.md
```
Expected: 62 lines; `/context-save` appears ≥ 3 times; `/context-save-rolling` appears 0 times.

- [ ] **Step 2: Write target file**

- h1: `# Context save policy`
- blockquote: `> Loaded on demand from AGENTS.md router. Read this file before invoking /context-save.`
- body: verbatim from `/tmp/context-save-source.md`, dropping `## 4. ...` heading and trailing `---`.

- [ ] **Step 3: Verify**

Run:
```bash
wc -l /Users/toale/Developer/biot-awesome-skills/instructions/context-save.md
grep -c "context-save\b" /Users/toale/Developer/biot-awesome-skills/instructions/context-save.md
```
Expected: 58–68 lines; `context-save` (the verbatim command) appears ≥ 3 times.

---

## Task 6: Extract `instructions/agent-delegation.md` (CLAUDE § 1)

**Files:**
- Create: `/Users/toale/Developer/biot-awesome-skills/instructions/agent-delegation.md`

- [ ] **Step 1: Capture source range**

Source: `CLAUDE.md` lines 13–74.

Run:
```bash
sed -n '13,74p' /Users/toale/Developer/biot-awesome-skills/CLAUDE.md > /tmp/agent-delegation-source.md
wc -l /tmp/agent-delegation-source.md
```
Expected: 62 lines.

- [ ] **Step 2: Write target file**

- h1: `# Agent Delegation (Model Selection, Trust & Verification)`
- blockquote: `> Loaded on demand from CLAUDE.md router. Read this file before spawning a sub-agent via the Agent tool.`
- body: verbatim from `/tmp/agent-delegation-source.md`, dropping `## 1. ...` heading and trailing `---`.

- [ ] **Step 3: Verify**

Run:
```bash
wc -l /Users/toale/Developer/biot-awesome-skills/instructions/agent-delegation.md
grep -c "Opus 4.7" /Users/toale/Developer/biot-awesome-skills/instructions/agent-delegation.md
grep -c "Sonnet 4.6" /Users/toale/Developer/biot-awesome-skills/instructions/agent-delegation.md
```
Expected: 58–68 lines; both model names appear multiple times.

---

## Task 7: Extract `instructions/operating-rules.md` (CLAUDE § 2)

**Files:**
- Create: `/Users/toale/Developer/biot-awesome-skills/instructions/operating-rules.md`

- [ ] **Step 1: Capture source range**

Source: `CLAUDE.md` lines 78–141.

Run:
```bash
sed -n '78,141p' /Users/toale/Developer/biot-awesome-skills/CLAUDE.md > /tmp/operating-rules-source.md
wc -l /tmp/operating-rules-source.md
```
Expected: 64 lines.

- [ ] **Step 2: Write target file**

- h1: `# Twelve Operating Rules`
- blockquote: `> Loaded on demand from CLAUDE.md router. Read once per non-trivial task per session.`
- body: verbatim from `/tmp/operating-rules-source.md`, dropping `## 2. ...` heading and trailing `---`.

- [ ] **Step 3: Verify**

Run:
```bash
wc -l /Users/toale/Developer/biot-awesome-skills/instructions/operating-rules.md
grep -c "^### Rule " /Users/toale/Developer/biot-awesome-skills/instructions/operating-rules.md
```
Expected: 60–70 lines; exactly 12 rule headings.

---

## Task 8: Extract `instructions/gstack-skills.md` (CLAUDE gstack section)

**Files:**
- Create: `/Users/toale/Developer/biot-awesome-skills/instructions/gstack-skills.md`

- [ ] **Step 1: Capture source range + count**

Source: `CLAUDE.md` lines 145–184. Verified bullet count = **34** (not 33 — corrected per /autoplan review).

Run:
```bash
sed -n '145,184p' /Users/toale/Developer/biot-awesome-skills/CLAUDE.md > /tmp/gstack-skills-source.md
wc -l /tmp/gstack-skills-source.md
grep -c '^- `/' /tmp/gstack-skills-source.md
```
Expected: 40 lines captured; 34 skill bullets.

- [ ] **Step 2: Write target file**

- h1: `# gstack Skills Index`
- blockquote: `> Loaded on demand from CLAUDE.md router. Read this file when considering any /gstack-* skill invocation.`
- body: verbatim from `/tmp/gstack-skills-source.md`, dropping `## gstack` heading and trailing `---`. Keep intro paragraph about `/browse`.

- [ ] **Step 3: Verify**

Run:
```bash
wc -l /Users/toale/Developer/biot-awesome-skills/instructions/gstack-skills.md
grep -c '^- `/' /Users/toale/Developer/biot-awesome-skills/instructions/gstack-skills.md
```
Expected: 38–48 lines; exactly **34** skill bullets.

---

## Task 9: Create empty capture sinks `instructions/lessons-captured-{claude,universal}.md`

**Files:**
- Create: `/Users/toale/Developer/biot-awesome-skills/instructions/lessons-captured-claude.md`
- Create: `/Users/toale/Developer/biot-awesome-skills/instructions/lessons-captured-universal.md`

- [ ] **Step 1: Write claude sink**

Use Write tool to create `instructions/lessons-captured-claude.md` with this exact content:

```markdown
# Captured Claude-Specific Lessons (inbox)

> **NOT auto-loaded.** Captured by `hooks/pattern-observer.py` from per-turn corrections / preferences / confirmations. Promote critical lessons to routers as file references via the (future) user-built promotion hook.

## Lessons (Claude-specific)

<!-- new lessons append here as `- **Title** — Rule.` bullets, each with ❌ Bad / ✅ Good sub-bullets. -->
```

The `## Lessons (Claude-specific)` heading MUST be present — the pattern-observer prompt instructs the agent to append under a heading starting with `## Lessons`.

- [ ] **Step 2: Write universal sink**

Use Write tool to create `instructions/lessons-captured-universal.md`:

```markdown
# Captured Universal Lessons (inbox)

> **NOT auto-loaded.** Vendor-neutral lessons captured by `hooks/pattern-observer.py`. Promote critical lessons to routers as file references via the (future) user-built promotion hook.

## Lessons (universal)

<!-- new lessons append here as `- **Title** — Rule.` bullets, each with ❌ Bad / ✅ Good sub-bullets. -->
```

- [ ] **Step 3: Verify**

Run:
```bash
for f in lessons-captured-claude lessons-captured-universal; do
  path=/Users/toale/Developer/biot-awesome-skills/instructions/$f.md
  test -f "$path" && echo "OK $f" || echo "FAIL $f"
  grep -c '^## Lessons' "$path"
done
```
Expected: 2 `OK` lines; each file has exactly **1** `## Lessons` heading.

---

## Task 10: Rewrite `CLAUDE.md` as router

**Files:**
- Modify: `/Users/toale/Developer/biot-awesome-skills/CLAUDE.md` (full rewrite)

- [ ] **Step 1: Write router using Write tool**

Use Write tool to overwrite `/Users/toale/Developer/biot-awesome-skills/CLAUDE.md` with this exact content:

````markdown
# Claude Code Operating Instructions

Claude-specific layer on top of the vendor-neutral baseline. The baseline is auto-imported below.

@AGENTS.md

`~/.claude/CLAUDE.md` is a symlink to this file. Edit this file; the symlink follows. Anything vendor-neutral belongs in `AGENTS.md`, not here.

**Hook + global-rule sync:** When any file under `hooks/`, this file, `AGENTS.md`, or `instructions/` is modified, commit + push to the biot remote in the same turn so other machines/sessions stay in sync.

---

## Always-on Claude rules

- **Model gates** — Delegate hard tasks to **Opus 4.7** at xhigh reasoning effort. Use **Sonnet 4.6** for easy/mechanical work, then have Opus 4.7 review when correctness matters. Never use any model other than {Opus 4.7, Sonnet 4.6} for delegated agents.
- **Trust-but-verify** — Never trust a sub-agent response immediately. Treat every answer as a draft until independently validated.
- **`/browse` for all web browsing** — gstack's `/browse` skill replaces `mcp__claude-in-chrome__*` tools. Never invoke the Chrome MCP tools directly.
- **Hook + rule edits sync to biot** — See preamble.
- **Authorship + verification + 5 non-negotiables + save trigger** inherit from `AGENTS.md` always-on rules — apply them too.

---

## On-demand Claude instructions

Read these files **before acting** in the relevant scope.

| Topic | File | Read when |
|---|---|---|
| Agent delegation (model selection, trust/verify policy) | `instructions/agent-delegation.md` | About to spawn a sub-agent via the Agent tool |
| Operating rules (the 12) | `instructions/operating-rules.md` | Starting a non-trivial task — read once per session |
| gstack skills index | `instructions/gstack-skills.md` | Considering any `/gstack-*` (or related) skill invocation |

---

## Always-on vendor-neutral rules

Pulled in via `@AGENTS.md` above. The high-priority ones restated for visibility:

- **Authorship**: never add an AI assistant as `Co-Authored-By` or generator footer on any commit.
- **Five non-negotiables**: surface assumptions, stop when confused, push back when warranted, prefer boring, scope discipline.
- **Save trigger**: invoke `/context-save` before final response after substantive work; skip for trivial replies.
- **Verification gate**: task incomplete until tests pass, build succeeds, runtime behavior matches expectations, lint/type-check is clean.

For full text of any of these, see `instructions/commit-policy.md`, `instructions/engineering-discipline.md`, or `instructions/context-save.md` via the `AGENTS.md` routing table.
````

- [ ] **Step 2: Verify line count + no lesson bullets + no stale imports**

Run:
```bash
wc -l /Users/toale/Developer/biot-awesome-skills/CLAUDE.md
grep -cE "^- \*\*" /Users/toale/Developer/biot-awesome-skills/CLAUDE.md
grep -E "^@" /Users/toale/Developer/biot-awesome-skills/CLAUDE.md
grep -nE "RTK\.md|## Lessons" /Users/toale/Developer/biot-awesome-skills/CLAUDE.md || echo "OK no lesson bullets, no RTK"
```
Expected: ≤ 90 lines; bullet-styled `- **` lines are router list items only (not lesson bullets); only `@AGENTS.md` import; "OK no lesson bullets, no RTK" prints.

---

## Task 11: Rewrite `AGENTS.md` as router

**Files:**
- Modify: `/Users/toale/Developer/biot-awesome-skills/AGENTS.md` (full rewrite)

- [ ] **Step 1: Write router using Write tool**

Use Write tool to overwrite `/Users/toale/Developer/biot-awesome-skills/AGENTS.md` with this exact content:

````markdown
# Agent Operating Instructions (Universal)

Vendor-neutral baseline for any coding agent (Claude Code, Codex, Cursor, etc.). Agent-specific layers (`CLAUDE.md`, future `CODEX.md`, …) `@`-import this file.

Keep this router short. If you find yourself typing vendor-specific terms (`Opus`, `Sonnet`, `Anthropic`, `~/.claude/...`, Agent tool, hook system specifics) — that content does not belong here. Move it to the relevant companion file.

---

## Always-on universal rules

- **Authorship** — NEVER add an AI assistant as `Co-Authored-By` or generator footer on any commit. Author/committer must be the user's own git identity. Applies to every commit, amend, rebase, squash.
- **Five non-negotiables** — (1) Surface assumptions before non-trivial work. (2) Stop when confused — name the confusion, ask. (3) Push back when warranted — sycophancy is a failure mode. (4) Prefer boring — fewer lines, naive-correct over clever-fragile. (5) Scope discipline — touch only what the task requires.
- **Save trigger** — Invoke `/context-save` before the final response after substantive work (code edit / decision / fix / refactor / finding). Skip for trivial replies, clarifying questions, read-only exploration. When in doubt → skip.
- **Verification gate** — Task is incomplete until tests pass, build succeeds, runtime behavior matches expectations, lint/type-check is clean. "Seems right" is never sufficient.
- **Process over prose** — Pick the workflow / skill that matches the task. Follow steps in order. Hit every checkpoint.

---

## On-demand universal instructions

Read these files **before acting** in the relevant scope.

| Topic | File | Read when |
|---|---|---|
| Git commit policy (full text, examples, validation checklist) | `instructions/commit-policy.md` | Composing any commit message |
| PR creation policy (template handling, accuracy rules, examples) | `instructions/pr-policy.md` | Opening or updating a PR |
| Engineering discipline (anti-rationalization table, process-over-prose, verification, progressive disclosure, 5 non-negotiables expanded) | `instructions/engineering-discipline.md` | Starting non-trivial work — read once per session |
| Context save policy (full trigger criteria, v3 layout, restore flow) | `instructions/context-save.md` | Before invoking `/context-save` |
````

- [ ] **Step 2: Verify line count + no lesson bullets**

Run:
```bash
wc -l /Users/toale/Developer/biot-awesome-skills/AGENTS.md
grep -nE "^## Lessons|Co-Authored-By:" /Users/toale/Developer/biot-awesome-skills/AGENTS.md || echo "OK no lessons section, no Co-Authored-By trailer leak"
```
Expected: ≤ 80 lines; "OK no lessons section, no Co-Authored-By trailer leak" prints.

---

## Task 12: Update `hooks/pattern-observer.py` paths + audit ALL stale prose

**Files:**
- Modify: `/Users/toale/Developer/biot-awesome-skills/hooks/pattern-observer.py`

- [ ] **Step 1: Update `LESSONS_FILE_*` path constants (lines 38–43)**

Use Edit tool. Target file: `/Users/toale/Developer/biot-awesome-skills/hooks/pattern-observer.py`.

Replace:
```python
LESSONS_FILE_CLAUDE = os.path.expanduser(
    "~/Developer/biot-awesome-skills/CLAUDE.md"
)
LESSONS_FILE_UNIVERSAL = os.path.expanduser(
    "~/Developer/biot-awesome-skills/AGENTS.md"
)
```

With:
```python
LESSONS_FILE_CLAUDE = os.path.expanduser(
    "~/Developer/biot-awesome-skills/instructions/lessons-captured-claude.md"
)
LESSONS_FILE_UNIVERSAL = os.path.expanduser(
    "~/Developer/biot-awesome-skills/instructions/lessons-captured-universal.md"
)
```

- [ ] **Step 2: Update routing comment block (lines 33–37)**

Use Edit tool. Replace:
```python
# Lesson routing — single canonical target per scope. The agent classifies
# the captured rule and writes to ONE of these:
#   Claude-specific (default) → biot/CLAUDE.md
#       (`~/.claude/CLAUDE.md` is a symlink to it.)
#   Agent-neutral             → biot/AGENTS.md
```

With:
```python
# Lesson routing — single canonical target per scope. The agent classifies
# the captured rule and appends to ONE of these capture sinks:
#   Claude-specific (default) → biot/instructions/lessons-captured-claude.md
#   Agent-neutral             → biot/instructions/lessons-captured-universal.md
# Routers CLAUDE.md / AGENTS.md do NOT auto-load these sinks. A separate
# user-built promotion hook will later surface critical lessons into the
# routers as file references.
```

- [ ] **Step 3: Update docstring routing block (lines 18–21)**

Use Edit tool. Replace:
```python
  Routing:
      Claude-specific lesson  → biot/CLAUDE.md (`~/.claude/CLAUDE.md`
                                 is a symlink to it).
      Agent-neutral lesson    → biot/AGENTS.md.
```

With:
```python
  Routing:
      Claude-specific lesson  → biot/instructions/lessons-captured-claude.md
      Agent-neutral lesson    → biot/instructions/lessons-captured-universal.md
```

- [ ] **Step 4: Update prompt prose (around line 192)**

Use Edit tool. Replace:
```python
    "Pick AGENTS.md ONLY if the rule references no Claude-specific tools,\n"
    "models, paths, or hook system — i.e. it would apply identically under\n"
    "any other coding agent. Otherwise default to CLAUDE.md.\n"
```

With:
```python
    "Pick lessons-captured-universal.md ONLY if the rule references no\n"
    "Claude-specific tools, models, paths, or hook system — i.e. it would\n"
    "apply identically under any other coding agent. Otherwise default to\n"
    "lessons-captured-claude.md.\n"
```

- [ ] **Step 5: Update prompt fallback prose (line 211–212)**

Use Edit tool. Replace:
```python
    "project-specific for the global file — capture it in the project's\n"
    "own CLAUDE.md instead, or skip.\n\n"
```

With:
```python
    "project-specific for the global capture sink — capture it in the\n"
    "project's own scratch notes instead, or skip.\n\n"
```

- [ ] **Step 6: Sweep remaining stale mentions**

Run:
```bash
grep -nE "biot-awesome-skills/CLAUDE\.md|biot-awesome-skills/AGENTS\.md" /Users/toale/Developer/biot-awesome-skills/hooks/pattern-observer.py
grep -nE "\bCLAUDE\.md\b|\bAGENTS\.md\b" /Users/toale/Developer/biot-awesome-skills/hooks/pattern-observer.py | grep -v "^.*#" | grep -v "instructions/"
```
Expected: first grep finds zero matches; second grep finds zero non-comment mentions of bare `CLAUDE.md` / `AGENTS.md`.

If matches remain, use Edit tool to rewrite each in context (each mention must point at the new capture-sink filenames or be removed).

- [ ] **Step 7: Verify Python file still parses**

Run:
```bash
python3 -c "import ast; ast.parse(open('/Users/toale/Developer/biot-awesome-skills/hooks/pattern-observer.py').read()); print('OK')"
```
Expected: `OK`.

---

## Task 13: Update `hooks/inject-checkpoint-reminder.sh` prose

**Files:**
- Modify: `/Users/toale/Developer/biot-awesome-skills/hooks/inject-checkpoint-reminder.sh`

- [ ] **Step 1: Update comment on line 4 + heredoc line 10**

Use Edit tool. Replace:
```bash
# ~/.claude/CLAUDE.md § "Context save policy".
```

With:
```bash
# biot-awesome-skills/instructions/context-save.md (routed from AGENTS.md).
```

Use Edit tool. Replace:
```
[context-save policy reminder — full rules in ~/.claude/CLAUDE.md § "Context save policy"]
```

With:
```
[context-save policy reminder — full rules in biot-awesome-skills/instructions/context-save.md]
```

- [ ] **Step 2: Confirm no `/context-save` → `/context-save-rolling` drift introduced**

Run:
```bash
grep -nE "/context-save-rolling" /Users/toale/Developer/biot-awesome-skills/hooks/inject-checkpoint-reminder.sh || echo "OK no rolling drift"
```
Expected: `OK no rolling drift`.

- [ ] **Step 3: Verify the hook still runs**

Run:
```bash
bash /Users/toale/Developer/biot-awesome-skills/hooks/inject-checkpoint-reminder.sh | head -2
```
Expected: first line references `instructions/context-save.md`; emitted body still uses `/context-save` (not `/context-save-rolling`).

---

## Task 14: Update `hooks/skill-push-reminder.sh` prose

**Files:**
- Modify: `/Users/toale/Developer/biot-awesome-skills/hooks/skill-push-reminder.sh:28`

- [ ] **Step 1: Update echo string**

Use Edit tool. Replace:
```bash
        echo "BIOT EDIT: $REAL_PATH lives in biot-awesome-skills. Commit + push to remote (leductoan3082004/biot-awesome-skills) once edits are done — keeps hooks/AGENTS.md in sync across machines."
```

With:
```bash
        echo "BIOT EDIT: $REAL_PATH lives in biot-awesome-skills. Commit + push to remote (leductoan3082004/biot-awesome-skills) once edits are done — keeps hooks/CLAUDE.md/AGENTS.md/instructions in sync across machines."
```

- [ ] **Step 2: Verify bash syntax**

Run:
```bash
bash -n /Users/toale/Developer/biot-awesome-skills/hooks/skill-push-reminder.sh && echo "OK"
```
Expected: `OK`.

---

## Task 15: Smoke test — prompt-emission verification (NOT a write test)

**Files:** none (test only). The hook does not write files; it emits LLM prompts. This test verifies the emitted prompt names the new capture sinks and contains no stale CLAUDE.md/AGENTS.md references.

- [ ] **Step 1: Verify capture-sink files exist and have the expected `## Lessons` heading**

Run:
```bash
for f in lessons-captured-claude lessons-captured-universal; do
  path=/Users/toale/Developer/biot-awesome-skills/instructions/$f.md
  test -s "$path" && hdr=$(grep -c '^## Lessons' "$path") && echo "$f: $hdr heading(s)"
done
```
Expected: each file shows `1 heading(s)`.

- [ ] **Step 2: Load `pattern-observer.py` via importlib (hyphenated filename can't be imported normally)**

Run:
```bash
python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('po', '/Users/toale/Developer/biot-awesome-skills/hooks/pattern-observer.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
print('LESSONS_FILE_CLAUDE:', m.LESSONS_FILE_CLAUDE)
print('LESSONS_FILE_UNIVERSAL:', m.LESSONS_FILE_UNIVERSAL)
assert m.LESSONS_FILE_CLAUDE.endswith('instructions/lessons-captured-claude.md'), 'claude path wrong'
assert m.LESSONS_FILE_UNIVERSAL.endswith('instructions/lessons-captured-universal.md'), 'universal path wrong'
print('OK — constants point at capture sinks')
"
```
Expected: prints both paths and `OK — constants point at capture sinks`.

- [ ] **Step 3: Verify emitted prompt names the new sinks and contains no stale router mentions**

Run:
```bash
python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('po', '/Users/toale/Developer/biot-awesome-skills/hooks/pattern-observer.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
out = m.correction_context()
assert 'instructions/lessons-captured-claude.md' in out, 'claude sink path missing from prompt'
assert 'instructions/lessons-captured-universal.md' in out, 'universal sink path missing from prompt'
assert 'biot-awesome-skills/CLAUDE.md' not in out, 'stale CLAUDE.md path leaked into prompt'
assert 'biot-awesome-skills/AGENTS.md' not in out, 'stale AGENTS.md path leaked into prompt'
print('OK — emitted prompt names new sinks only')
"
```
Expected: `OK — emitted prompt names new sinks only`. If any assertion fails, return to Task 12 and re-check.

- [ ] **Step 4: Verify routers stay within budget + lessons absent**

Run:
```bash
wc -l /Users/toale/Developer/biot-awesome-skills/CLAUDE.md /Users/toale/Developer/biot-awesome-skills/AGENTS.md
grep -nE "^## Lessons" /Users/toale/Developer/biot-awesome-skills/CLAUDE.md /Users/toale/Developer/biot-awesome-skills/AGENTS.md || echo "OK no lessons in routers"
```
Expected: CLAUDE.md ≤ 90, AGENTS.md ≤ 80; "OK no lessons in routers" prints.

- [ ] **Step 5: Verify all 9 instructions/ files exist and the stale `@RTK.md` is gone**

Run:
```bash
for f in instructions/commit-policy.md instructions/pr-policy.md instructions/engineering-discipline.md instructions/context-save.md instructions/agent-delegation.md instructions/operating-rules.md instructions/gstack-skills.md instructions/lessons-captured-claude.md instructions/lessons-captured-universal.md; do
  test -s "/Users/toale/Developer/biot-awesome-skills/$f" && echo "OK $f" || echo "FAIL $f"
done
grep -n "RTK" /Users/toale/Developer/biot-awesome-skills/CLAUDE.md /Users/toale/Developer/biot-awesome-skills/AGENTS.md || echo "OK no RTK"
```
Expected: 9 `OK` lines; `OK no RTK` prints.

---

## Task 16: Atomic commit + push, with snapshot rollback path

**Files:**
- Stage: routers, all `instructions/*.md`, hook updates, plan + spec docs.

- [ ] **Step 1: Stage exact paths (no `git add -A`, no broad `docs/superpowers/`)**

Run:
```bash
cd /Users/toale/Developer/biot-awesome-skills
git add CLAUDE.md AGENTS.md \
  instructions/commit-policy.md \
  instructions/pr-policy.md \
  instructions/engineering-discipline.md \
  instructions/context-save.md \
  instructions/agent-delegation.md \
  instructions/operating-rules.md \
  instructions/gstack-skills.md \
  instructions/lessons-captured-claude.md \
  instructions/lessons-captured-universal.md \
  hooks/pattern-observer.py \
  hooks/inject-checkpoint-reminder.sh \
  hooks/skill-push-reminder.sh \
  docs/superpowers/specs/2026-05-20-instruction-router-split-design.md \
  docs/superpowers/plans/2026-05-20-instruction-router-split.md
git status --short
```
Expected output (approximate):
```
M  CLAUDE.md
M  AGENTS.md
A  instructions/agent-delegation.md
A  instructions/commit-policy.md
A  instructions/context-save.md
A  instructions/engineering-discipline.md
A  instructions/gstack-skills.md
A  instructions/lessons-captured-claude.md
A  instructions/lessons-captured-universal.md
A  instructions/operating-rules.md
A  instructions/pr-policy.md
M  hooks/inject-checkpoint-reminder.sh
M  hooks/pattern-observer.py
M  hooks/skill-push-reminder.sh
A  docs/superpowers/plans/2026-05-20-instruction-router-split.md
A  docs/superpowers/specs/2026-05-20-instruction-router-split-design.md
```

- [ ] **Step 2: Commit with conventional-commit message (NO AI authorship trailer)**

Run:
```bash
cd /Users/toale/Developer/biot-awesome-skills
git commit -m "$(cat <<'EOF'
refactor: split CLAUDE.md and AGENTS.md into router + instructions/

Convert monolithic agent instruction files into the router pattern
from walkinglabs lecture 04. Routers now hold critical always-on
rules and a routing table; topic-specific content (commit policy, PR
policy, engineering discipline, context save, model selection,
operating rules, gstack skills) lives in instructions/<topic>.md and
is read on demand.

Drop accumulated lesson bullets from routers (fresh-start direction —
preserved in git history). The pattern-observer.py hook now appends
new lesson captures to instructions/lessons-captured-{claude,universal}.md
inbox sinks. A future user-built promotion hook will surface critical
lessons back into routers as file references.

Auto-loaded lines per turn drop from ~580 to ~130. No retained rule
text is reworded — topic files are verbatim extracts.

Two shell hooks get cosmetic prose updates so reminders point at the
new file paths. The stale @RTK.md import is removed. The /context-save
command name is preserved verbatim (no drift to /context-save-rolling).
EOF
)"
```
Expected: commit created; pre-commit hooks pass.

- [ ] **Step 3: Rollback path if Step 2 fails**

If the commit fails (pre-commit hook rejects, syntax error in a staged file, etc.):

```bash
# Inspect failure
cd /Users/toale/Developer/biot-awesome-skills
git status
# Restore router files from snapshots taken in Task 1:
cp /tmp/router-split-baseline-CLAUDE.md CLAUDE.md
cp /tmp/router-split-baseline-AGENTS.md AGENTS.md
# Unstage everything:
git restore --staged .
# Inspect what's wrong (hook output, syntax error, etc.), fix, then resume from the failed task.
```

Do NOT push until Step 2 succeeds.

- [ ] **Step 4: Push to biot remote**

Run:
```bash
cd /Users/toale/Developer/biot-awesome-skills
git remote -v | head -2
git push origin main
```
Expected: push succeeds. If remote name differs from `origin`, adjust.

- [ ] **Step 5: Confirm new HEAD on remote**

Run:
```bash
cd /Users/toale/Developer/biot-awesome-skills
git log -1 --oneline origin/main
```
Expected: new commit hash matches local `HEAD`.

---

## Acceptance checklist (run after Task 16)

- [ ] `CLAUDE.md` ≤ 90 lines, no `## Lessons` section, no `@RTK.md`.
- [ ] `AGENTS.md` ≤ 80 lines, no `## Lessons` section.
- [ ] All 9 `instructions/*.md` files exist (7 verbatim topic files + 2 empty capture sinks).
- [ ] `instructions/lessons-captured-{claude,universal}.md` each have exactly one `## Lessons` heading and a brief framing comment.
- [ ] `pattern-observer.py` constants and emitted prompt both point at the new sinks (Task 15 step 3 passes).
- [ ] No occurrences of `biot-awesome-skills/CLAUDE.md` or `biot-awesome-skills/AGENTS.md` in the pattern-observer source.
- [ ] No drift from `/context-save` to `/context-save-rolling` anywhere in the diff.
- [ ] `inject-checkpoint-reminder.sh` and `skill-push-reminder.sh` reference new paths in their prose.
- [ ] Single atomic commit on `main`, pushed to biot remote.
- [ ] No AI `Co-Authored-By` trailer or generator footer in the commit message.
- [ ] Snapshots `/tmp/router-split-baseline-{CLAUDE,AGENTS}.md` may be removed after successful push.
