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

# Must be an actual git push invocation (anchored, incl. "git -C <path> push"
# and env-prefixed like "GH_HOST=... git ... push"). Avoids firing on any
# command whose output merely mentions push/403.
if not re.search(r"(^|[;&|]\s*|\s)git\b[^;&|]*\bpush\b", cmd):
    sys.exit(0)
# Must be an auth/permission failure.
if not re.search(r"403|denied to|Permission to|fatal: unable to access|authentication failed", resp, re.I):
    sys.exit(0)

# Who got denied / which repo (best-effort, for context).
denied = (re.search(r"denied to (\S+?)[.\"]", resp) or [None, None])[1]
repo = (re.search(r"Permission to (\S+?\.git)", resp) or [None, None])[1]

# Live account list across ALL hosts (github.com, git.taservs.net, ...) — no
# hardcoded usernames or hosts, works for any number of accounts.
try:
    accounts = subprocess.run(
        ["gh", "auth", "status"],
        capture_output=True, text=True, timeout=10
    ).stdout.strip() or "(could not read gh auth status)"
except Exception:
    accounts = "(gh not available — check `gh auth status`)"

# Best-effort host from the push URL in the error (github.com, git.taservs.net…).
host = (re.search(r"https?://([^/\\\"]+)/", resp) or [None, "<HOST>"])[1]

lines = ["git push FAILED on auth/permission (403)."]
if denied:
    lines.append(f"Active account `{denied}` has no access" + (f" to {repo}." if repo else "."))
lines += [
    f"Switch to a `{host}` account that DOES have access, then retry the SAME push, then switch back.",
    "",
    "Current accounts (gh auth status, all hosts):",
    accounts,
    "",
    "Steps:",
    f"  gh auth switch -h {host} -u <ACCOUNT_WITH_ACCESS>",
    f"  {cmd}",
    f"  gh auth switch -h {host} -u <PREVIOUS_ACTIVE_ACCOUNT>   # restore when done",
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
