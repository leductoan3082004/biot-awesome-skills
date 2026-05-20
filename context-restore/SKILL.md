---
name: context-restore
description: |
  Use when the user wants to resume work from a prior
  /context-save snapshot, or says "restore context", "where
  was I", "resume", "pick up where I left off",
  "/context-restore". Reads structured topic-snapshot folders
  (v3 layout) and routes to the best match via frontmatter scoring.
  When the match is ambiguous, LISTS candidates and ASKS rather than
  guessing. Lazy-loads sibling files (DECISIONS / PROGRESS / RESULTS /
  artifacts) only after the user opts in.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Skill
  - AskUserQuestion
---

# /context-restore — Structured Snapshot Restore (v3)

You are a Staff Engineer routing the right prior snapshot to the
current task. Snapshots are folders; each contains a structured
`context.md` + siblings. Default behavior: pick the right snapshot
**deterministically when the signal is clear**, and **ask the user
when it isn't**.

**HARD GATE:** No code changes. Read-only.

**HARD GATE:** When candidate selection is ambiguous, DO NOT auto-pick.
Surface candidates and ask. Wrong restore = the agent resumes the
wrong workstream and contaminates context.

**HARD GATE:** Do NOT eager-load sibling files. Read `context.md` of
the chosen snapshot; load `DECISIONS.md` / `PROGRESS.md` /
`RESULTS.md` / artifacts only when the user opts in.

---

## Detect command

| Form | Meaning |
|------|---------|
| `/context-restore` | Relevance-route to best topic for current task signal |
| `/context-restore <fragment>` | Match against topic-slug / title / keywords |
| `/context-restore --related <branch-or-sha>` | Match `related_branches` / `related_commits` (exact) |
| `/context-restore --snapshot <folder-name>` | Direct load of a specific snapshot folder (skip scoring) |
| `/context-restore list` | List snapshot folders grouped by topic |
| `/context-restore diff <folder-a> <folder-b>` | Diff two snapshots of same topic |
| `/context-restore save` | Tell user "Use `/context-save`". Exit. |

---

## Restore flow

### Step 1: Resolve paths

```bash
eval "$(~/.claude/skills/gstack/bin/gstack-slug 2>/dev/null)" 2>/dev/null || SLUG=$(basename "$PWD")
CHECKPOINT_DIR=~/.gstack/projects/$SLUG/checkpoints
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
HEAD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "")
echo "SLUG=$SLUG"
echo "CHECKPOINT_DIR=$CHECKPOINT_DIR"
echo "CURRENT_BRANCH=$CURRENT_BRANCH"
echo "HEAD_COMMIT=$HEAD_COMMIT"
```

### Step 2: Enumerate snapshot folders — frontmatter only

**Hard rule:** Step 2 reads frontmatter via `grep -m1` / bounded
`awk`. NEVER load full `context.md` bodies in this step. The whole
point of the `summary:` + `keywords:` fields is that routing can be
judged from one line + a short list per folder — without burning
context on N×bodies.

```bash
> /tmp/all-snapshots.txt
for d in $(find "$CHECKPOINT_DIR" -mindepth 1 -maxdepth 1 -type d -name "20*-*" 2>/dev/null); do
  CTX="$d/context.md"
  [ -f "$CTX" ] || continue
  T=$(grep -m1 '^topic:' "$CTX" | sed 's/topic: *//')
  TITLE=$(grep -m1 '^title:' "$CTX" | sed 's/title: *//')
  SUM=$(grep -m1 '^summary:' "$CTX" | sed 's/summary: *//' | sed 's/^"//; s/"$//')
  KEYS=$(grep -m1 '^keywords:' "$CTX" | sed 's/keywords: *//')
  LU=$(grep -m1 '^last_updated:' "$CTX" | sed 's/last_updated: *//')
  STATUS=$(grep -m1 '^status:' "$CTX" | sed 's/status: *//')
  SN=$(grep -m1 '^session_number:' "$CTX" | sed 's/session_number: *//')
  RB=$(awk '/^related_branches:/{flag=1; next} flag && /^[a-z_]+:/{flag=0} flag' "$CTX" | grep '^  - ' | sed 's/^  - //' | tr '\n' ',' | sed 's/,$//')
  RC=$(awk '/^related_commits:/{flag=1; next} flag && /^[a-z_]+:/{flag=0} flag' "$CTX" | grep '^  - ' | sed 's/^  - //' | tr '\n' ',' | sed 's/,$//')
  printf '%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n' \
    "$T" "$(basename "$d")" "$LU" "$STATUS" "$SN" "$TITLE" "$SUM" "$KEYS" "$RB" "$RC" >> /tmp/all-snapshots.txt
done

# Layout: topic | folder | last_updated | status | session_n | title | summary | keywords | branches | commits
# Latest snapshot per topic = first row per topic when sorted by folder name desc.
sort -t'|' -k1,1 -k2,2r /tmp/all-snapshots.txt | awk -F'|' '!seen[$1]++' > /tmp/latest-per-topic.txt

echo "--- LATEST PER TOPIC ---"
cat /tmp/latest-per-topic.txt
```

If no v3 folders exist, fall back to legacy v2 files (`CURRENT-*.md`):

```bash
LEGACY_V2=$(find "$CHECKPOINT_DIR" -maxdepth 1 -name "CURRENT-*.md" -type f 2>/dev/null)
LEGACY_AUDIT_NEWEST=$(find "$CHECKPOINT_DIR" -maxdepth 1 -name "20*.md" -type f 2>/dev/null | sort -r | head -1)
echo "LEGACY_V2 files: $LEGACY_V2"
echo "LEGACY_AUDIT_NEWEST: $LEGACY_AUDIT_NEWEST"
```

If no v3 AND no legacy → tell user "no snapshots; run `/context-save` first".

### Step 3: Acquire task signal

In priority order:

1. Explicit `<fragment>` arg → matches against `topic-slug`, `title`, `keywords`.
2. `--related <branch-or-sha>` arg → exact match against `related_branches` / `related_commits`.
3. `--snapshot <folder-name>` arg → direct-load mode; skip scoring entirely.
4. Most recent user message in this conversation describing intent (e.g. "I'm fixing auth redirects" → task tokens = `auth, redirects, fix`).
5. `CURRENT_BRANCH` (weak hint).
6. None — bare `/context-restore` with no signal at all.

### Step 4: Score candidates

For each "latest per topic" row, score five signals against the task signal:

| Signal | Strong | Weak | None |
|--------|--------|------|------|
| Summary text overlap | shares ≥1 domain noun **and** verb/intent | shares 1 common noun only | no overlap |
| Keywords overlap | ≥2 keyword matches | exactly 1 keyword match | 0 |
| Branch overlap | task-supplied branch OR `CURRENT_BRANCH` appears exactly in `related_branches` | shared prefix only (e.g. `feat/auth-a` vs `feat/auth-b`) | none |
| Commit overlap | task-supplied SHA matches a `related_commits` entry exactly (7-char prefix) | none | none |
| Recency | `last_updated` within last 7 days | within 30 days | older |

Per topic:

- `score_strong = count(strong signals)`
- `score_weak   = count(weak signals)`

Status modifier:
- `status: in-progress` → no change
- `status: resolved` → demote one strong → weak (we usually don't resume resolved work)
- `status: abandoned` → strip all strong signals (never auto-pick abandoned)

Order topics by `(score_strong DESC, score_weak DESC, last_updated DESC)`.

### Step 5: Decision logic

```
EXPLICIT MODES
==============
A. --snapshot <folder>
   - Validate folder exists in CHECKPOINT_DIR.
   - On hit → load. On miss → tell user, list nearest matches, exit.

B. <fragment> arg
   - Match against (topic-slug, title, keywords) case-insensitive.
   - 1 match    → load.
   - 2+ matches → AskUserQuestion (parallel-digest if ≥3).
   - 0 matches  → tell user "no match for <fragment>"; offer most-recently-updated
                  topic as fallback. DO NOT auto-load.

C. --related <branch-or-sha>
   - Search `related_branches` / `related_commits` for exact match.
   - 1 topic contains it    → load.
   - 2+ topics contain it   → AskUserQuestion (parallel-digest if ≥3).
   - 0                      → tell user; offer fallback. DO NOT auto-load.

RELEVANCE-SCORED MODE (default, when no explicit arg)
=====================================================
Compute (score_strong, score_weak) per topic. Order desc.

D. Clear winner
   - top.score_strong ≥ 2 AND top.score_strong > second.score_strong
   - → AUTO-LOAD top.

E. Good-enough winner
   - top.score_strong == 1 AND top.score_weak ≥ 2 AND
     top.{strong+weak} > second.{strong+weak}
   - → AUTO-LOAD top.

F. Tie at strong
   - top.score_strong ≥ 1 AND second.score_strong == top.score_strong
   - → AMBIGUOUS → AskUserQuestion (parallel-digest if ≥3 candidates).
   - Include "None of these — start fresh" option.

G. Strong + conflicting weak
   - top has strong title but weak goal contradicts; OR strong branch
     but no other strong signal
   - → AMBIGUOUS → AskUserQuestion.

H. Weak task signal, no strong matches
   - task signal exists but no topic scores ≥1 strong
   - → tell user "no strong match for <task>"; surface top 3 weak/none
     candidates with summaries; offer most-recently-updated as fallback.
   - DO NOT auto-load.

I. No task signal at all (bare command)
   - load most-recently-updated topic (the legacy default).
   - tell user it was selected by recency, not relevance.

J. No topic files at all
   - fall back to legacy v2 CURRENT-*.md (read inline).
   - if still nothing, fall back to newest timestamped audit file.
   - if still nothing, tell user.
```

### Step 6: Multi-candidate digest via parallel agents

When AskUserQuestion is triggered AND there are 3+ candidates,
dispatch `superpowers:dispatching-parallel-agents` — one sub-agent
per candidate folder. Each sub-agent receives:

1. Absolute path to that candidate's `context.md`.
2. Task description (verbatim from the user's most-recent message).
3. Output contract:
   - folder name
   - last_updated
   - status
   - one-line topic summary (echoed)
   - 1-2 reasons this **might match** the task
   - 1-2 reasons this **might NOT match**
   - confidence: high / medium / low
   - ≤150 words total

Main agent merges digests into AskUserQuestion options.

```
Multiple snapshots might match your task. Pick one:

  A) <folder-a>  (status: in-progress, updated 2 days ago)
     "<summary>"
     Might match: <reason>
     Might NOT match: <reason>
     Confidence: high

  B) <folder-b>  (status: in-progress, updated 6 days ago)
     "<summary>"
     Might match: <reason>
     Might NOT match: <reason>
     Confidence: medium

  C) <folder-c>  ...

  D) None of these — start fresh without restoring.
```

For 2 candidates, do inline `Read`s on both `context.md` files (no
parallel dispatch — overhead exceeds savings).

### Step 7: Load the chosen snapshot — `context.md` only

Use `Read` on `<chosen-folder>/context.md`. Present verbatim — no
truncation, no condensing.

```
RESUMING CONTEXT (rolling v3, topic-snapshot)
═════════════════════════════════════════════
Topic:           {title}
Topic slug:      {topic-slug}
Snapshot:        {folder name}
Status:          {status}
Last updated:    {last_updated, human-readable}
Session #:       {session_number}
Branch (now):    {CURRENT_BRANCH or "(none)"}
Branch (saved):  {current_branch from frontmatter}
Related branches:{list}
Related commits: {list}
Parent snapshot: {parent_snapshot or "(new topic)"}
═════════════════════════════════════════════

[body of context.md verbatim — Topic identity, Quick state, Active
decisions (top 5), Open work (top 5), Recently resolved, Notable
gotchas, How to resume, Routing hints]
```

### Step 8: Branch-mismatch nudge (non-blocking)

If `CURRENT_BRANCH` is non-empty AND not in the snapshot's
`related_branches`, append (do NOT block):

```
[BRANCH NOT IN SNAPSHOT'S RELATED LIST]
Current branch:    {CURRENT_BRANCH}
Snapshot branches: {list}
This snapshot might be the wrong workstream for what you're about to do.
Consider /context-restore --related {CURRENT_BRANCH} or
/context-restore list to pick a different topic.
```

### Step 9: Offer next actions (lazy-load siblings)

AskUserQuestion:

- A) Continue from the first open item in `PROGRESS.md` → load `PROGRESS.md`
- B) Read full decision log → load `DECISIONS.md`
- C) Read validation results → load `RESULTS.md`
- D) Browse artifacts → list `<folder>/artifacts/` (if present)
- E) Switch to a different snapshot → run `list` or accept new `<fragment>`
- F) Diff this snapshot against the previous one for this topic → run `diff`
- G) Just needed context.md, thanks → exit

Siblings are only `Read` after the user picks the corresponding
option. Conserves context window.

---

## `--snapshot` flow (direct load)

`/context-restore --snapshot <folder-name>`

```bash
TARGET="$CHECKPOINT_DIR/$ARG"
if [ ! -d "$TARGET" ] || [ ! -f "$TARGET/context.md" ]; then
  echo "Snapshot folder not found: $ARG"
  # Suggest nearest matches by edit-distance or prefix
  find "$CHECKPOINT_DIR" -mindepth 1 -maxdepth 1 -type d -name "*$(echo $ARG | head -c 16)*" | head -5
  exit 0
fi
```

Skip scoring. Load `<folder>/context.md` directly. Proceed to Step 7.

## `--diff` flow

`/context-restore diff <folder-a> <folder-b>`

Read both `context.md` files. Present:

- Decisions: added in B, removed (impossible — superseded only), newly superseded
- Progress: items moved from Open → Done; items newly opened; items newly blocked
- `related_branches` / `related_commits`: added in B
- `session_number` delta
- `last_updated` delta

Useful for "what changed between yesterday's snapshot and today's".

## `list` flow

```
TOPIC                   LATEST FOLDER                               SESSIONS  STATUS         SUMMARY
auth-middleware-rewrite 2026-05-20_143022-auth-middleware-rewrite  5         in-progress    Replace legacy session-token middleware...
checkout-perf           2026-05-19_090112-checkout-perf            3         resolved       Cut p95 from 1200ms to 300ms by removing N+1
context-save-v3         2026-05-20_171545-context-save-v3          2         in-progress    Upgrade rolling save/restore to topic-snapshot folders
```

Sorted by `last_updated` desc. Add `--all` to list every snapshot (not just latest per topic).

---

## Legacy compatibility

When v3 folders don't exist for a topic the user is asking about,
fall back in order:

1. Legacy v2 `CURRENT-<topic-slug>.md` — read inline.
2. Legacy gstack timestamped audit `20YYMMDD-HHMMSS-*.md` — read newest.

Always tell the user which layer the data came from. Encourage running
`/context-save` to upgrade the topic to v3 on next save (the
save skill auto-detects v2 parents and migrates seamlessly).

---

## Important rules

- **Frontmatter routing first.** Never load bodies during enumeration. Bodies are loaded only for the **chosen** target.
- **Ask when ambiguous.** Wrong restore = context contamination across workstreams.
- **Parallel agents for 3+ candidate digests.** Inline `Read` for ≤2.
- **Lazy-load siblings.** Read `context.md` first; load `DECISIONS.md` / `PROGRESS.md` / `RESULTS.md` / artifacts only on user opt-in.
- **Branch mismatch = informational, not blocking.** A topic can legitimately span branches.
- **Resolved / abandoned topics demote in scoring but still appear in `list`.** User can explicitly resume them.
- **No truncation on the chosen body.** `context.md` is already capped at 500 lines — show all of it.

---

## Red flags — STOP and re-read this skill

- "Two topics partially match — I'll pick the more recent one." → STOP. Ambiguous → AskUserQuestion.
- "I'll read every `context.md` in full to find the right one." → STOP. Use frontmatter scoring; load only the chosen body.
- "I'll read `DECISIONS.md` eagerly to give a richer presentation." → STOP. Lazy-load. User opts in.
- "Frontmatter `summary:` is missing on this folder; I'll read the body to infer." → STOP. Either fall back to first ~200 chars of `## Topic identity`, or skip with a warning, or ask. Never silently fabricate.
- "Score is 0 strong / 0 weak across all topics; I'll auto-pick the newest." → STOP. Tell user "no strong match"; offer most-recent as fallback; let them decide.
- "Three candidates, I'll just read them all inline." → STOP. ≥3 → parallel agents.
- "User passed `--snapshot foo`, folder doesn't exist, I'll grab the next-closest." → STOP. Tell user, list near matches, let them pick.
- "Resolved topic is the top hit — auto-load it." → STOP. Resolved status demotes by one strong → weak. Only auto-load if it still wins after demotion.
- "Current branch isn't in the snapshot's `related_branches`, I'll auto-switch topics." → STOP. Surface the mismatch, do not block, let the user decide.
