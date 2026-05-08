#!/usr/bin/env python3
"""
PostToolUse hook: track Skill tool invocations.

Records which skills are invoked and when, so pattern-observer
can detect correction patterns near skill usage and signal
that the skill itself may need editing.
"""

import json
import os
import sys
import tempfile
import time

STATE_DIR = os.path.expanduser("~/.claude/hooks/.state")
STATE_FILE = os.path.join(STATE_DIR, "skill-usage.json")

MAX_AGE_SECONDS = 1800  # prune entries older than 30 min


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


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0

    tool_name = data.get("tool_name", "")
    if tool_name != "Skill":
        return 0

    tool_input = data.get("tool_input", {})
    skill_name = tool_input.get("skill", "")
    session_id = data.get("session_id", "")

    if not skill_name:
        return 0

    state = load_state()
    now = time.time()

    # Prune old entries
    cutoff = now - MAX_AGE_SECONDS
    state["recent_skills"] = [
        e for e in state.get("recent_skills", [])
        if e.get("timestamp", 0) >= cutoff
    ]
    state["skill_corrections"] = {
        k: v for k, v in state.get("skill_corrections", {}).items()
        if v.get("last_correction", 0) >= cutoff
    }

    # Record this skill invocation
    state["recent_skills"].append({
        "skill": skill_name,
        "timestamp": now,
        "session_id": session_id,
    })

    save_state(state)
    return 0


if __name__ == "__main__":
    sys.exit(main())
