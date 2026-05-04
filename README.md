# biot-awesome-skills

Personal Claude Code skills for session management and productivity.

## Setup

Skills are symlinked into `~/.claude/skills/` so Claude Code discovers them automatically.

```bash
# Link all skills (run from repo root)
for skill in */; do
  [ -f "$skill/SKILL.md" ] && ln -sfn "$(pwd)/$skill" "$HOME/.claude/skills/${skill%/}"
done
```

## Skills

| Skill | Description |
|-------|-------------|
| `context-save` | Snapshot session state (branch, decisions, findings) to `~/.claude/contexts/` |
| `context-restore` | Search and load saved contexts to resume prior work |
| `deep-investigate` | Evidence-driven investigation for hard bugs — enforces prove-don't-pattern-match |

## Adding a new skill

1. Create a directory: `mkdir my-skill`
2. Add `my-skill/SKILL.md` with YAML frontmatter (`name`, `description`) + instructions
3. Symlink: `ln -sfn "$(pwd)/my-skill" ~/.claude/skills/my-skill`
4. Commit and push
