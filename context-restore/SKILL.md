---
name: context-restore
description: |
  Use when user wants to resume work from a prior /context-save
  snapshot, or says "restore context", "where was I", "resume", "pick
  up where I left off", "/context-restore". Reads structured
  topic-snapshot folders (v3 layout) and routes to best match via
  frontmatter scoring. When ambiguous, LISTS candidates and ASKS rather
  than guessing. Lazy-loads sibling files (DECISIONS / PROGRESS /
  RESULTS / artifacts) only after user opts in.
allowed-tools: [Bash, Read, Grep, Glob, Skill, AskUserQuestion]
---

# /context-restore — Snapshot Restore (v3)

Route the right prior snapshot to the current task. Snapshots are
folders; each contains a structured `context.md` + siblings. Pick
**deterministically when signal is clear**, **ask when it isn't**.

**HARD GATES:**
1. No code changes — read-only.
2. When candidate selection is ambiguous, do NOT auto-pick. Surface candidates and ask. Wrong restore contaminates context.
3. Do NOT eager-load sibling files. Read `context.md` of the chosen snapshot; load `DECISIONS.md` / `PROGRESS.md` / `RESULTS.md` / artifacts only on user opt-in.
4. NEVER auto-execute init commands. Always AskUserQuestion first. Restore is read-only by default.

---

## Detect command

| Form | Meaning |
|------|---------|
| `/context-restore` | Relevance-route to best topic for current task |
| `/context-restore <fragment>` | Match against topic-slug / title / keywords |
| `/context-restore --related <branch-or-sha>` | Exact match on `related_branches` / `related_commits` |
| `/context-restore --snapshot <folder>` | Direct load, skip scoring |
| `/context-restore list` | List snapshots grouped by topic |
| `/context-restore diff <a> <b>` | Diff two snapshots of same topic |
| `/context-restore save` | Tell user "Use `/context-save`". Exit. |

---

## Restore flow

### Step 1: Resolve paths

```bash
CHECKPOINT_DIR=~/.claude/projects/checkpoints
eval "$(~/.claude/skills/gstack/bin/gstack-slug 2>/dev/null)" 2>/dev/null || SLUG=$(basename "$PWD")
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
HEAD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "")
```

`SLUG` is informational only — does NOT scope the search.

### Step 2: Enumerate — frontmatter only

**Hard rule:** read frontmatter via `grep -m1` / bounded `awk`. NEVER load full `context.md` bodies during enumeration. The whole point of `summary:` + `keywords:` is one-line routing without burning context on N bodies.

```bash
> /tmp/all-snapshots.txt
for d in $(find "$CHECKPOINT_DIR" -mindepth 1 -maxdepth 1 -type d -name "20*-*"); do
  CTX="$d/context.md"; [ -f "$CTX" ] || continue
  T=$(grep -m1 '^topic:' "$CTX" | sed 's/topic: *//')
  # ... title, summary, keywords, last_updated, status, session_number, related_branches, related_commits
  printf '%s|%s|...\n' "$T" "$(basename "$d")" ... >> /tmp/all-snapshots.txt
done
# Latest per topic: sort folder desc, dedup on topic.
sort -t'|' -k1,1 -k2,2r /tmp/all-snapshots.txt | awk -F'|' '!seen[$1]++' > /tmp/latest-per-topic.txt
```

If no v3 folders → fall back to legacy v2 `CURRENT-*.md`. If still nothing → tell user "no snapshots; run `/context-save`".

### Step 3: Acquire task signal

In priority order:
1. Explicit `<fragment>` arg → matches `topic-slug` / `title` / `keywords`.
2. `--related <branch-or-sha>` → exact match in `related_branches` / `related_commits`.
3. `--snapshot <folder>` → direct load, skip scoring.
4. Most recent user message describing intent.
5. `CURRENT_BRANCH` (weak hint).
6. Bare command, no signal.

### Step 4: Score candidates

Per topic, score five signals against task:

| Signal | Strong | Weak | None |
|--------|--------|------|------|
| Summary overlap | ≥1 domain noun **and** verb/intent | 1 common noun only | no overlap |
| Keywords overlap | ≥2 matches | exactly 1 | 0 |
| Branch overlap | exact match in `related_branches` | shared prefix (`feat/auth-a` vs `feat/auth-b`) | none |
| Commit overlap | task SHA matches `related_commits` exactly (7-char prefix) | none | none |
| Recency | last_updated within 7 days | within 30 days | older |

Per topic: `score_strong = count(strong)`, `score_weak = count(weak)`.

Status modifier: `in-progress` no change. `resolved` demotes one strong → weak. `abandoned` strips all strong (never auto-pick).

Order by `(score_strong DESC, score_weak DESC, last_updated DESC)`.

### Step 5: Decision logic

**Explicit modes:**

- **A. `--snapshot <folder>`** — validate exists. Hit → load. Miss → tell user, list nearest, exit.
- **B. `<fragment>` arg** — case-insensitive match on `topic-slug` / `title` / `keywords`. 1 match → load. 2+ → AskUserQuestion (parallel-digest if ≥3). 0 → tell user "no match"; offer most-recently-updated as fallback. DO NOT auto-load.
- **C. `--related <branch-or-sha>`** — exact match. 1 topic → load. 2+ → AskUserQuestion. 0 → tell user, offer fallback. DO NOT auto-load.

**Relevance-scored (default):**

- **D. Clear winner** — top.strong ≥ 2 AND top.strong > second.strong → **AUTO-LOAD**.
- **E. Good-enough winner** — top.strong == 1 AND top.weak ≥ 2 AND top.{strong+weak} > second.{strong+weak} → **AUTO-LOAD**.
- **F. Tie at strong** — top.strong ≥ 1 AND second.strong == top.strong → AMBIGUOUS → AskUserQuestion (parallel-digest if ≥3). Include "None — start fresh".
- **G. Strong + conflicting weak** — strong title but weak goal contradicts; OR strong branch but no other strong signal → AMBIGUOUS → AskUserQuestion.
- **H. Weak task signal, no strong matches** → tell user "no strong match"; surface top 3 candidates with summaries; offer most-recently-updated fallback. DO NOT auto-load.
- **I. No task signal (bare command)** → load most-recently-updated topic. Tell user it was selected by recency, not relevance.
- **J. No topic files at all** → fall back to legacy v2 `CURRENT-*.md` (read inline). Still nothing → newest timestamped audit. Still nothing → tell user.

### Step 6: Multi-candidate digest via parallel sub-agents

When AskUserQuestion fires AND there are 3+ candidates, dispatch `superpowers:dispatching-parallel-agents` — one sub-agent per candidate. Each gets: absolute path to that candidate's `context.md`, task description verbatim from user's most-recent message, and output contract: folder, last_updated, status, one-line summary, 1-2 reasons it might match, 1-2 reasons it might NOT, confidence (high/medium/low), ≤150 words.

Main agent merges digests into AskUserQuestion options. Always include "None — start fresh".

For 2 candidates: inline `Read` on both `context.md` (no parallel — overhead exceeds savings).

### Step 7: Load chosen snapshot — `context.md` only

Use `Read` on `<chosen>/context.md`. Present verbatim — no truncation. Header:

```
RESUMING CONTEXT (v3 topic-snapshot)
Topic / slug / snapshot folder / status / last_updated / session# /
branch (now) vs branch (saved) / related branches / related commits /
parent_snapshot
```

Then full body — Topic identity, Quick state, Environment/Init commands, Active decisions, Open work, Recently resolved, Notable gotchas, How to resume, Routing hints.

### Step 8: Branch-mismatch nudge (non-blocking)

If `CURRENT_BRANCH` is non-empty AND not in `related_branches`, append (do NOT block):

```
[BRANCH NOT IN SNAPSHOT'S RELATED LIST]
Current branch:    <CURRENT_BRANCH>
Snapshot branches: <list>
Consider /context-restore --related <CURRENT_BRANCH> or `list`.
```

### Step 8.5: Offer to verify environment (init commands)

Parse restored `context.md` for `## Environment / Init commands`. Missing / empty → skip silently.

If present, opt-in BEFORE anything runs. Re-running can mutate state, download deps, start servers. User may already know env is healthy.

**HARD GATE:** Never auto-execute. Always AskUserQuestion first.

Present each command verbatim with Required / Side effects / Est, then ask:

```
Restore captured <N> init command(s). Re-verify env now?
  A) Run all <N> in order, stop on first failure
  B) Run only `required: yes` subset
  C) Pick a subset myself (multi-select)
  D) Skip — I know env is fine, just continue
  E) Show commands with side effects first, then ask again
```

Branch handling:

- **A** — execute sequentially via `Bash`. For each: print `▶ <cmd>`, run, capture exit + stdout tail (≤20 lines). Stop on first non-zero. Report table: command | exit | seconds.
- **B** — same as A, filter to `required: yes`.
- **C** — multi-select AskUserQuestion listing every command; run only the chosen subset, A-style execution.
- **D** — proceed to Step 9. Note "env verification: skipped by user".
- **E** — print full list with `side_effects` per line, then re-ask A/B/C/D.

**HARD GATE:** Any command marked `side_effects: mutates …` or `side_effects: starts long-running server` MUST be surfaced before being run, even if user picked A. Re-confirm those specific commands inline before executing them.

**HARD GATE:** A failed init command is a STOP, not a retry. Tell user `init failed at <cmd>: exit <code>`; surface stdout tail; leave the broken state visible. Do NOT loop. Do NOT propose fixes unless user explicitly asks.

If `side_effects` is missing / `unknown`, refuse to include in A/B's auto-run set. Surface under option E only; require per-command opt-in.

### Step 9: Offer next actions (lazy-load siblings)

AskUserQuestion:

- A) Continue from first open item in `PROGRESS.md` → load `PROGRESS.md`
- B) Read full decision log → load `DECISIONS.md`
- C) Read validation results → load `RESULTS.md`
- D) Browse artifacts → list `<folder>/artifacts/` if present
- E) Switch to different snapshot → `list` or new `<fragment>`
- F) Diff against previous snapshot for this topic → run `diff`
- G) Re-run env init commands now (offered only if Step 8.5 was skipped) → re-enter Step 8.5
- H) Just needed context.md → exit

Siblings only `Read` after the user picks the corresponding option.

---

## `--snapshot` flow (direct load)

```bash
TARGET="$CHECKPOINT_DIR/$ARG"
if [ ! -d "$TARGET" ] || [ ! -f "$TARGET/context.md" ]; then
  echo "Snapshot not found: $ARG"
  find "$CHECKPOINT_DIR" -mindepth 1 -maxdepth 1 -type d -name "*$(echo $ARG | head -c 16)*" | head -5
  exit 0
fi
```

Skip scoring. Load `<folder>/context.md` directly. Proceed to Step 7.

## `diff` flow

`/context-restore diff <folder-a> <folder-b>` — read both `context.md`. Present: decisions added in B; decisions newly superseded; progress moved Open → Done; newly opened; newly blocked; `related_branches` / `related_commits` added; `session_number` + `last_updated` deltas.

## `list` flow

Sorted by `last_updated` desc. Columns: `TOPIC | LATEST FOLDER | SESSIONS | STATUS | SUMMARY`. `--all` lists every snapshot, not just latest per topic.

---

## Legacy compatibility

When no v3 folder exists for a requested topic, fall back in order: (1) legacy v2 `CURRENT-<topic>.md` — read inline; (2) legacy gstack timestamped audit `20YYMMDD-HHMMSS-*.md` — read newest. Always tell user which layer the data came from. Encourage `/context-save` to upgrade.

---

## Important rules

- **Frontmatter routing first.** Never load bodies during enumeration. Bodies load only for the chosen target.
- **Ask when ambiguous.** Wrong restore = context contamination.
- **Parallel sub-agents for 3+ candidate digests.** Inline `Read` for ≤2.
- **Lazy-load siblings.** `context.md` first; `DECISIONS.md` / `PROGRESS.md` / `RESULTS.md` / artifacts only on user opt-in.
- **Branch mismatch = informational, not blocking.** A topic can span branches.
- **Resolved / abandoned topics demote in scoring** but still appear in `list`. User can explicitly resume.
- **No truncation on chosen body.** `context.md` is capped at 500 lines — show all.
- **Init commands are opt-in.** Never run any command from `## Environment / Init commands` without explicit user approval. Some mutate state, start servers, or take minutes — user may already know env is healthy.
- **Stop on first init failure.** Do NOT auto-debug. Do NOT retry. Do NOT propose fixes unless asked. Surface failure and yield.

---

## Red flags — STOP and re-read this skill

- "Two topics partially match — pick more recent." → STOP. Ambiguous → AskUserQuestion.
- "Read every `context.md` in full to find the right one." → STOP. Frontmatter scoring; load only chosen body.
- "Read `DECISIONS.md` eagerly for richer presentation." → STOP. Lazy-load. User opts in.
- "Frontmatter `summary:` missing; read body to infer." → STOP. Fall back to first ~200 chars of `## Topic identity`, OR skip with warning, OR ask. Never silently fabricate.
- "All scores 0; auto-pick newest." → STOP. Tell user "no strong match"; offer most-recent as fallback; let them decide.
- "Three candidates — read all inline." → STOP. ≥3 → parallel agents.
- "`--snapshot foo` folder missing — grab next-closest." → STOP. Tell user, list near matches, let them pick.
- "Resolved topic is top hit — auto-load." → STOP. Resolved demotes one strong → weak. Only auto-load if it still wins after demotion.
- "Current branch not in `related_branches` — auto-switch topics." → STOP. Surface mismatch; do not block; user decides.
- "Init commands look safe — run them so user doesn't wait." → STOP. Restore is read-only by default. AskUserQuestion first, every time.
- "Init command ran earlier this session — no need to ask before re-running." → STOP. Ask. Idempotence is the command's job to prove, not yours.
- "Init command failed — try `npm install --force` instead." → STOP. Do not auto-debug. Surface exit code + stdout tail and yield.
- "`side_effects` field empty — probably none." → STOP. Empty / `unknown` = treat as unsafe. Refuse to auto-run; surface under E only.
- "User picked A — just execute all 4." → STOP. `mutates …` and `starts long-running server` require inline per-command re-confirm even after A. `unknown` is refused from A/B entirely.
