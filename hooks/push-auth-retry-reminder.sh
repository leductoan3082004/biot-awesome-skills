#!/bin/bash
# PostToolUse hook (Bash): when a `git push` fails on a permission/403 error,
# inject a reminder to switch to a github.com account that has access and retry.
# Generic — reads the live `gh auth status` account list, hardcodes no usernames.

cat | python3 -c '
import sys, json, re, subprocess

try:
    d = json.loads(sys.stdin.read(), strict=False)
except Exception:
    sys.exit(0)

cmd = d.get("tool_input", {}).get("command", "")
resp = json.dumps(d.get("tool_response", ""))

# Must be a git push (matches "git ... push", incl. "git -C <path> push").
if not re.search(r"\bgit\b.*\bpush\b", cmd):
    sys.exit(0)
# Must be an auth/permission failure.
if not re.search(r"403|denied to|Permission to|fatal: unable to access|authentication failed", resp, re.I):
    sys.exit(0)

# Who got denied / which repo (best-effort, for context).
denied = (re.search(r"denied to (\S+?)[.\"]", resp) or [None, None])[1]
repo = (re.search(r"Permission to (\S+?\.git)", resp) or [None, None])[1]

# Live account list — no hardcoded usernames, works for any number of accounts.
try:
    accounts = subprocess.run(
        ["gh", "auth", "status", "-h", "github.com"],
        capture_output=True, text=True, timeout=10
    ).stdout.strip() or "(could not read gh auth status)"
except Exception:
    accounts = "(gh not available — check `gh auth status`)"

lines = ["git push FAILED on auth/permission (403)."]
if denied:
    lines.append(f"Active account `{denied}` has no access" + (f" to {repo}." if repo else "."))
lines += [
    "Switch to a github.com account that DOES have access, then retry the SAME push, then switch back.",
    "",
    "Current github.com accounts (gh auth status):",
    accounts,
    "",
    "Steps:",
    "  gh auth switch -h github.com -u <ACCOUNT_WITH_ACCESS>",
    f"  {cmd}",
    "  gh auth switch -h github.com -u <PREVIOUS_ACTIVE_ACCOUNT>   # restore when done",
    "",
    "Pick <ACCOUNT_WITH_ACCESS> from the list above (the one that owns/can write the repo). Do not leave commits unpushed.",
]

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": "\n".join(lines),
    }
}))
'
