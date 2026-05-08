#!/usr/bin/env python3
"""
UserPromptSubmit hook: detect user patterns, preferences, corrections,
and positive confirmations.

Signal types:
  CORRECTION  — user correcting Claude's behavior → capture lesson
  PREFERENCE  — user declaring a working style/convention → capture rule
  POSITIVE    — user confirming a non-obvious approach → capture pattern
  SKILL-EDIT  — corrections piling up near a skill → suggest editing skill

Behavior model:
  - Lesson capture runs PARALLEL with the main task; user does NOT wait.
  - Agent SELF-EVALUATES worthiness; no confirmation prompt.
  - Compact bullet format with ❌ Bad / ✅ Good examples.
  - Synced across ~/.claude/CLAUDE.md AND
    ~/Developer/biot-awesome-skills/AGENTS.md.
"""

import json
import os
import re
import sys
import tempfile
import time

STATE_DIR = os.path.expanduser("~/.claude/hooks/.state")
STATE_FILE = os.path.join(STATE_DIR, "skill-usage.json")
LESSONS_FILES = [
    os.path.expanduser("~/.claude/CLAUDE.md"),
    os.path.expanduser("~/Developer/biot-awesome-skills/AGENTS.md"),
]
LESSONS_HEADER = "## Lessons"

SKILL_WINDOW_SECONDS = 300  # 5 min window for "recently active" skill
SKILL_CORRECTION_THRESHOLD = 2  # corrections before suggesting skill edit

# ── Correction patterns ─────────────────────────────────────────────
CORRECTION_PATTERNS = [
    r"\bno,\s",
    r"^\s*no[.!\s]",
    r"\bnope\b",
    r"\bstop (doing|that|it|saying|using)\b",
    r"\bwrong\b",
    r"\bincorrect\b",
    r"\bthat'?s wrong\b",
    r"\bdon'?t\b",
    r"\bdo not\b",
    r"\bshouldn'?t (have|do)\b",
    r"\bshould have\b",
    r"\bshould'?ve\b",
    r"\bshould not have\b",
    r"\bthat'?s not\b",
    r"\bthat is not what\b",
    r"\bnot what i (asked|wanted|meant|said)\b",
    r"\bwhy (did|are) you\b",
    r"\bundo (that|this|your)\b",
    r"\brevert (that|this|your)\b",
    r"\brollback\b",
    r"\binstead of\b",
    r"\byou (missed|forgot|misunderstood|broke|misread|ignored)\b",
    r"\byou should (have|'?ve)\b",
    r"\bmistake\b",
    r"\bnot quite\b",
    r"\bactually,?\s",
    r"\bi (told|said|asked) you\b",
    r"\bplease (don'?t|stop)\b",
    r"\b(re-?do|redo) (it|that|this)\b",
]

CORRECTION_SUPPRESSORS = (
    "no problem", "no worries", "no issue", "no rush",
    "no big deal", "no thanks", "no thank",
)

# ── Preference / style declaration patterns ─────────────────────────
PREFERENCE_PATTERNS = [
    r"\bi (always|prefer|like to|want you to|need you to)\b",
    r"\bfrom now on\b",
    r"\bremember (that|this|to)\b",
    r"\bnever (do|use|add|include|generate|write|create|put)\b",
    r"\balways (do|use|add|include|generate|write|create|put)\b",
    r"\bmy (style|pattern|workflow|preference|convention) is\b",
    r"\bthis is how i (work|do|want|like)\b",
    r"\bgoing forward\b",
    r"\bin (the )?future,?\s",
    r"\bmake sure (to|you)\b",
    r"\bi expect you to\b",
    r"\bwhen i say .+ i mean\b",
    r"\bevery time\b",
    r"\beach time\b",
    r"\bwhenever i\b",
    r"\bthe way i want\b",
    r"\bfollow (my|this) (pattern|style|convention)\b",
]

PREFERENCE_SUPPRESSORS = (
    "i always thought", "i always wondered", "i always forget",
    "remember when", "remember that time", "i prefer to ask",
)

# ── Positive confirmation patterns ──────────────────────────────────
POSITIVE_PATTERNS = [
    r"\byes,?\s*exactly\b",
    r"\bperfect[,.]?\s*(keep|that'?s|this is)\b",
    r"\bthat'?s (right|correct|what i want|exactly)\b",
    r"\bkeep doing (that|this|it)\b",
    r"\bgood (approach|call|decision|choice|pattern)\b",
    r"\bnice[,.]?\s*(that|this|approach)\b",
    r"\byes[,.]?\s*(this|that) is (what|how)\b",
    r"\bexactly what i (want|need|mean)\b",
    r"\bspot on\b",
    r"\bnailed it\b",
    r"\byes,?\s*like that\b",
    r"\bthis is (perfect|great|correct)\b",
]


# ── State helpers ───────────────────────────────────────────────────

def load_state():
    try:
        with open(STATE_FILE, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {"recent_skills": [], "skill_corrections": {}}


def save_state(state):
    os.makedirs(STATE_DIR, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=STATE_DIR, suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as f:
            json.dump(state, f, indent=2)
        os.rename(tmp, STATE_FILE)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass


def get_recent_skills(state, session_id=None):
    now = time.time()
    cutoff = now - SKILL_WINDOW_SECONDS
    skills = set()
    for entry in state.get("recent_skills", []):
        if entry.get("timestamp", 0) >= cutoff:
            if session_id is None or entry.get("session_id") == session_id:
                skills.add(entry.get("skill", ""))
    return list(skills)


def scrub(text, suppressors):
    result = text
    for s in suppressors:
        result = result.replace(s, "__suppressed__")
    return result


def matches(text, patterns):
    return any(re.search(p, text) for p in patterns)


# ── Context builders ────────────────────────────────────────────────

_FILES_LIST = "\n".join(f"       - {p}" for p in LESSONS_FILES)

_SHARED_RULES = (
    "DO THE USER'S MAIN TASK FIRST — DO NOT BLOCK ON LESSON CAPTURE.\n"
    "Lesson capture runs IN PARALLEL with the main task (or right after a\n"
    "natural pause). User must NOT wait on it.\n\n"
    "Self-evaluate worthiness silently. Save only if ALL hold:\n"
    "  - Cross-session / cross-repo applicable (not one-off task detail).\n"
    "  - Non-obvious (a fresh session would default differently).\n"
    "  - Not already captured (scan existing bullets first).\n"
    "If not worthy: skip silently. No acknowledgment.\n\n"
    "Do NOT ask the user to confirm. Auto-save. Only ask if the rule is\n"
    "genuinely ambiguous AND you cannot form a clear bad/good example.\n\n"
    "Storage — append a single compact bullet to BOTH files (keep in sync):\n"
    f"{_FILES_LIST}\n"
    f"under the `{LESSONS_HEADER}` section. If a `## Lessons Learned` section\n"
    "already exists in the file, USE THAT existing section instead of creating\n"
    "a new `## Lessons` (do not duplicate sections). If neither exists, create\n"
    f"`{LESSONS_HEADER}` at the end of the file.\n"
    "DO NOT use the old verbose template (### title / **Rule:** / **Why:** /\n"
    "**How to apply:** / **Date:**). DO NOT create any new sub-section.\n\n"
    "Bullet format (one line, then bad/good on indented sub-bullets):\n"
    "  - **<short title>** — <one-sentence rule>.\n"
    "    - ❌ Bad: <one-line bad example/output>.\n"
    "    - ✅ Good: <one-line good example/output>.\n\n"
    "If a similar bullet already exists, UPDATE it in-place; do not duplicate.\n"
    "Newest bullets first within the section.\n\n"
    "FALSE POSITIVES — skip silently (no message to user):\n"
    "  - Quoted error / log content.\n"
    "  - Discussion of a third party's mistake.\n"
    "  - Trivial agreement (\"ok\", \"sounds good\", \"thanks\").\n"
    "  - Phrases like \"no problem\", \"no worries\".\n"
)


def correction_context(skill_signal=None):
    ctx = (
        "LESSON-CAPTURE TRIGGER (correction signal detected).\n\n"
        + _SHARED_RULES
    )
    if skill_signal:
        ctx += f"\n\n{skill_signal}"
    return ctx


def preference_context():
    return (
        "LESSON-CAPTURE TRIGGER (preference / convention declared).\n\n"
        + _SHARED_RULES
    )


def positive_context():
    return (
        "LESSON-CAPTURE TRIGGER (positive confirmation of non-obvious approach).\n\n"
        + _SHARED_RULES
        + "\nExtra gate for positive signals: only capture if the confirmed\n"
        "approach is reusable beyond this task. Trivial confirmations skip silently.\n"
    )


def skill_edit_signal(skill_name, count):
    return (
        f"SKILL-EDIT SIGNAL: user corrected behavior {count} times while the\n"
        f"`{skill_name}` skill was recently active. The skill itself likely\n"
        "produces output the user doesn't want.\n\n"
        "After handling the immediate correction (in parallel with main task):\n"
        f"  1. Locate the `{skill_name}` skill file.\n"
        "  2. Propose a specific minimal edit that fixes the recurring pattern.\n"
        "  3. Apply after the user approves the edit (skill files ARE worth\n"
        "     confirming — different from lesson bullets).\n"
    )


# ── Main ────────────────────────────────────────────────────────────

def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0

    prompt = data.get("prompt", "") or ""
    session_id = data.get("session_id", "")
    if not prompt.strip():
        return 0

    lower = prompt.lower()
    state = load_state()

    # Detect signals (priority: correction > preference > positive)
    is_correction = matches(scrub(lower, CORRECTION_SUPPRESSORS), CORRECTION_PATTERNS)
    is_preference = matches(scrub(lower, PREFERENCE_SUPPRESSORS), PREFERENCE_PATTERNS)
    is_positive = matches(lower, POSITIVE_PATTERNS)

    # Skill correction tracking
    skill_signal = None
    if is_correction:
        recent = get_recent_skills(state, session_id)
        if recent:
            corrections = state.get("skill_corrections", {})
            for sk in recent:
                entry = corrections.get(sk, {"count": 0, "alerted": False})
                entry["count"] = entry.get("count", 0) + 1
                entry["last_correction"] = time.time()
                entry["session_id"] = session_id
                if entry["count"] >= SKILL_CORRECTION_THRESHOLD and not entry.get("alerted"):
                    skill_signal = skill_edit_signal(sk, entry["count"])
                    entry["alerted"] = True
                corrections[sk] = entry
            state["skill_corrections"] = corrections
            save_state(state)

    # Pick context by priority
    ctx = None
    if is_correction:
        ctx = correction_context(skill_signal)
    elif is_preference and not is_correction:
        ctx = preference_context()
    elif is_positive and not is_correction and not is_preference:
        ctx = positive_context()

    if not ctx:
        return 0

    out = {
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": ctx,
        }
    }
    sys.stdout.write(json.dumps(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
