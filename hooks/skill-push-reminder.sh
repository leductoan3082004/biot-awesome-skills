#!/bin/bash
# PostToolUse hook: remind to commit+push when biot-awesome-skills files are
# edited (directly OR via the ~/.claude/{CLAUDE.md,hooks/...} symlinks).

SKILLS_REPO="$HOME/Developer/biot-awesome-skills"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

# Resolve symlinks so edits via ~/.claude/* still trigger when the real file
# lives inside the biot repo.
if [ -n "$FILE_PATH" ] && [ -e "$FILE_PATH" ]; then
    REAL_PATH=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$FILE_PATH" 2>/dev/null)
else
    REAL_PATH="$FILE_PATH"
fi

if [[ "$REAL_PATH" == "$SKILLS_REPO"* ]]; then
    cd "$SKILLS_REPO" || exit 0
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        echo "BIOT EDIT: $REAL_PATH lives in biot-awesome-skills. Commit + push to remote (leductoan3082004/biot-awesome-skills) once edits are done — keeps hooks/AGENTS.md in sync across machines."
    fi
fi
