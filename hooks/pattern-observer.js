#!/usr/bin/env node
/**
 * UserPromptSubmit hook (Codex variant): detect user patterns, preferences,
 * corrections, and positive confirmations.
 *
 * This is the JavaScript twin of biot/hooks/pattern-observer.py — same
 * detection logic, same compact-bullet capture model, but writes to
 * Codex-side files instead of Claude-side ones.
 *
 * Signal types:
 *   CORRECTION  — user correcting behavior → capture lesson
 *   PREFERENCE  — user declaring a working style → capture rule
 *   POSITIVE    — user confirming a non-obvious approach → capture pattern
 *   SKILL-EDIT  — corrections piling up near a skill → suggest editing skill
 *
 * Behavior model:
 *   - Lesson capture runs PARALLEL with the main task; user does NOT wait.
 *   - Agent SELF-EVALUATES worthiness; no confirmation prompt.
 *   - Compact bullet format with ❌ Bad / ✅ Good examples.
 *   - Examples MUST be generic (no project codenames, ticket IDs, or
 *     internal artifact names) — pattern-level placeholders only.
 *   - Routing:
 *       Codex-specific lesson → ~/.codex/AGENTS.md
 *       Agent-neutral lesson  → biot/AGENTS.md
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// State is shared with the Claude variant so skill-correction counts
// accumulate across agents.
const STATE_DIR = path.join(os.homedir(), '.claude', 'hooks', '.state');
const STATE_FILE = path.join(STATE_DIR, 'skill-usage.json');

const LESSONS_FILE_CODEX = path.join(os.homedir(), '.codex', 'AGENTS.md');
const LESSONS_FILE_UNIVERSAL = path.join(
  os.homedir(),
  'Developer',
  'biot-awesome-skills',
  'AGENTS.md'
);
const LESSONS_HEADER = '## Lessons';

const SKILL_WINDOW_SECONDS = 300;
const SKILL_CORRECTION_THRESHOLD = 2;

// ── Correction patterns ─────────────────────────────────────────────
const CORRECTION_PATTERNS = [
  /\bno,\s/,
  /^\s*no[.!\s]/,
  /\bnope\b/,
  /\bstop (doing|that|it|saying|using)\b/,
  /\bwrong\b/,
  /\bincorrect\b/,
  /\bthat'?s wrong\b/,
  /\bdon'?t\b/,
  /\bdo not\b/,
  /\bshouldn'?t (have|do)\b/,
  /\bshould have\b/,
  /\bshould'?ve\b/,
  /\bshould not have\b/,
  /\bthat'?s not\b/,
  /\bthat is not what\b/,
  /\bnot what i (asked|wanted|meant|said)\b/,
  /\bwhy (did|are) you\b/,
  /\bundo (that|this|your)\b/,
  /\brevert (that|this|your)\b/,
  /\brollback\b/,
  /\binstead of\b/,
  /\byou (missed|forgot|misunderstood|broke|misread|ignored)\b/,
  /\byou should (have|'?ve)\b/,
  /\bmistake\b/,
  /\bnot quite\b/,
  /\bactually,?\s/,
  /\bi (told|said|asked) you\b/,
  /\bplease (don'?t|stop)\b/,
  /\b(re-?do|redo) (it|that|this)\b/,
];

const CORRECTION_SUPPRESSORS = [
  'no problem', 'no worries', 'no issue', 'no rush',
  'no big deal', 'no thanks', 'no thank',
];

// ── Preference / style declaration patterns ─────────────────────────
const PREFERENCE_PATTERNS = [
  /\bi (always|prefer|like to|want you to|need you to)\b/,
  /\bfrom now on\b/,
  /\bremember (that|this|to)\b/,
  /\bnever (do|use|add|include|generate|write|create|put)\b/,
  /\balways (do|use|add|include|generate|write|create|put)\b/,
  /\bmy (style|pattern|workflow|preference|convention) is\b/,
  /\bthis is how i (work|do|want|like)\b/,
  /\bgoing forward\b/,
  /\bin (the )?future,?\s/,
  /\bmake sure (to|you)\b/,
  /\bi expect you to\b/,
  /\bwhen i say .+ i mean\b/,
  /\bevery time\b/,
  /\beach time\b/,
  /\bwhenever i\b/,
  /\bthe way i want\b/,
  /\bfollow (my|this) (pattern|style|convention)\b/,
];

const PREFERENCE_SUPPRESSORS = [
  'i always thought', 'i always wondered', 'i always forget',
  'remember when', 'remember that time', 'i prefer to ask',
];

// ── Positive confirmation patterns ──────────────────────────────────
const POSITIVE_PATTERNS = [
  /\byes,?\s*exactly\b/,
  /\bperfect[,.]?\s*(keep|that'?s|this is)\b/,
  /\bthat'?s (right|correct|what i want|exactly)\b/,
  /\bkeep doing (that|this|it)\b/,
  /\bgood (approach|call|decision|choice|pattern)\b/,
  /\bnice[,.]?\s*(that|this|approach)\b/,
  /\byes[,.]?\s*(this|that) is (what|how)\b/,
  /\bexactly what i (want|need|mean)\b/,
  /\bspot on\b/,
  /\bnailed it\b/,
  /\byes,?\s*like that\b/,
  /\bthis is (perfect|great|correct)\b/,
];

// ── State helpers ───────────────────────────────────────────────────

function loadState() {
  try {
    return JSON.parse(fs.readFileSync(STATE_FILE, 'utf8'));
  } catch {
    return { recent_skills: [], skill_corrections: {} };
  }
}

function saveState(state) {
  fs.mkdirSync(STATE_DIR, { recursive: true });
  const tmp = STATE_FILE + '.tmp.' + process.pid;
  fs.writeFileSync(tmp, JSON.stringify(state, null, 2));
  fs.renameSync(tmp, STATE_FILE);
}

function getRecentSkills(state, sessionId) {
  const cutoff = Date.now() / 1000 - SKILL_WINDOW_SECONDS;
  const seen = new Set();
  for (const entry of (state.recent_skills || [])) {
    if ((entry.timestamp || 0) >= cutoff) {
      if (!sessionId || entry.session_id === sessionId) {
        seen.add(entry.skill);
      }
    }
  }
  return [...seen];
}

function scrub(text, suppressors) {
  let result = text;
  for (const s of suppressors) result = result.split(s).join('__suppressed__');
  return result;
}

function matches(text, patterns) {
  return patterns.some((p) => p.test(text));
}

function getPromptText(input) {
  const p = input.prompt ?? input.user_prompt ?? input.message ?? '';
  if (typeof p === 'string') return p;
  if (Array.isArray(p)) {
    return p
      .map((i) => (typeof i === 'string' ? i : (i?.text ?? '')))
      .join('\n');
  }
  if (p?.text) return p.text;
  return '';
}

// ── Context builders ────────────────────────────────────────────────

const SHARED_RULES = [
  `DO THE USER'S MAIN TASK FIRST — DO NOT BLOCK ON LESSON CAPTURE.`,
  `Lesson capture runs IN PARALLEL with the main task (or right after a`,
  `natural pause). User must NOT wait on it.`,
  ``,
  `Self-evaluate worthiness silently. Save only if ALL hold:`,
  `  - Cross-session / cross-repo applicable (not one-off task detail).`,
  `  - Non-obvious (a fresh session would default differently).`,
  `  - Not already captured (scan existing bullets first).`,
  `If not worthy: skip silently. No acknowledgment.`,
  ``,
  `Do NOT ask the user to confirm. Auto-save. Only ask if the rule is`,
  `genuinely ambiguous AND you cannot form a clear bad/good example.`,
  ``,
  `Storage — append a single compact bullet to ONE file based on scope:`,
  `  Codex-specific (default) → ${LESSONS_FILE_CODEX}`,
  `  Agent-neutral            → ${LESSONS_FILE_UNIVERSAL}`,
  `Pick the universal file ONLY if the rule references no Codex-specific`,
  `tools, paths, or hook system — i.e. it would apply identically under`,
  `any other coding agent (Claude, Cursor, etc.). Otherwise default to`,
  `the Codex AGENTS.md.`,
  `Append under the \`${LESSONS_HEADER}\` section. If a \`## Lessons Learned\``,
  `section already exists in the file, USE THAT existing section instead`,
  `of creating a new \`## Lessons\` (do not duplicate). If neither exists,`,
  `create \`${LESSONS_HEADER}\` at the end of the file.`,
  `DO NOT create any sub-section. DO NOT use the old verbose template`,
  `(### title / **Rule:** / **Why:** / **How to apply:** / **Date:**).`,
  ``,
  `Bullet format (one line, then bad/good on indented sub-bullets):`,
  `  - **<short title>** — <one-sentence rule>.`,
  `    - ❌ Bad: <one-line bad example/output>.`,
  `    - ✅ Good: <one-line good example/output>.`,
  ``,
  `EXAMPLES MUST BE GENERIC. Do NOT use project codenames, ticket IDs,`,
  `internal artifact names, partner/agency names, or domain-specific`,
  `identifiers. Use pattern-level placeholders any reader on any project`,
  `would understand (e.g. \`<SomeFeatureFlag>\`, \`<SomeDialogComponent>\`,`,
  `\`<some-helper>\`, \`<feature-x>\`). If the rule cannot be illustrated`,
  `without naming a specific project artifact, the lesson is too`,
  `project-specific for the global file — capture it in the project's`,
  `own AGENTS.md instead, or skip.`,
  ``,
  `If a similar bullet already exists, UPDATE it in-place; do not duplicate.`,
  `Newest bullets first within the section.`,
  ``,
  `FALSE POSITIVES — skip silently (no message to user):`,
  `  - Quoted error / log content.`,
  `  - Discussion of a third party's mistake.`,
  `  - Trivial agreement ("ok", "sounds good", "thanks").`,
  `  - Phrases like "no problem", "no worries".`,
].join('\n');

function correctionContext(skillSignal) {
  let ctx = `LESSON-CAPTURE TRIGGER (correction signal detected).\n\n${SHARED_RULES}`;
  if (skillSignal) ctx += `\n\n${skillSignal}`;
  return ctx;
}

function preferenceContext() {
  return `LESSON-CAPTURE TRIGGER (preference / convention declared).\n\n${SHARED_RULES}`;
}

function positiveContext() {
  return [
    `LESSON-CAPTURE TRIGGER (positive confirmation of non-obvious approach).`,
    ``,
    SHARED_RULES,
    ``,
    `Extra gate for positive signals: only capture if the confirmed`,
    `approach is reusable beyond this task. Trivial confirmations skip silently.`,
  ].join('\n');
}

function skillEditSignal(skillName, count) {
  return [
    `SKILL-EDIT SIGNAL: user corrected behavior ${count} times while the`,
    `\`${skillName}\` skill was recently active. The skill itself likely`,
    `produces output the user doesn't want.`,
    ``,
    `After handling the immediate correction (in parallel with main task):`,
    `  1. Locate the \`${skillName}\` skill file.`,
    `  2. Propose a specific minimal edit that fixes the recurring pattern.`,
    `  3. Apply after the user approves the edit (skill files ARE worth`,
    `     confirming — different from lesson bullets).`,
  ].join('\n');
}

// ── Main ────────────────────────────────────────────────────────────

function main() {
  let input;
  try {
    const raw = fs.readFileSync(0, 'utf8').slice(0, 128 * 1024);
    input = JSON.parse(raw);
  } catch {
    return;
  }

  const promptText = getPromptText(input);
  const sessionId = input.session_id ?? '';
  if (!promptText.trim()) return;

  const lower = promptText.toLowerCase();
  const state = loadState();

  const isCorrection = matches(scrub(lower, CORRECTION_SUPPRESSORS), CORRECTION_PATTERNS);
  const isPreference = matches(scrub(lower, PREFERENCE_SUPPRESSORS), PREFERENCE_PATTERNS);
  const isPositive = matches(lower, POSITIVE_PATTERNS);

  let skillSignal = null;
  if (isCorrection) {
    const recentSkills = getRecentSkills(state, sessionId);
    if (recentSkills.length > 0) {
      const corrections = state.skill_corrections || {};
      for (const sk of recentSkills) {
        const entry = corrections[sk] || { count: 0, alerted: false };
        entry.count = (entry.count || 0) + 1;
        entry.last_correction = Date.now() / 1000;
        entry.session_id = sessionId;
        if (entry.count >= SKILL_CORRECTION_THRESHOLD && !entry.alerted) {
          skillSignal = skillEditSignal(sk, entry.count);
          entry.alerted = true;
        }
        corrections[sk] = entry;
      }
      state.skill_corrections = corrections;
      try { saveState(state); } catch { /* non-fatal */ }
    }
  }

  let ctx = null;
  if (isCorrection) {
    ctx = correctionContext(skillSignal);
  } else if (isPreference) {
    ctx = preferenceContext();
  } else if (isPositive) {
    ctx = positiveContext();
  }

  if (!ctx) return;

  process.stdout.write(JSON.stringify({
    hookSpecificOutput: {
      hookEventName: 'UserPromptSubmit',
      additionalContext: ctx,
    },
  }));
}

main();
