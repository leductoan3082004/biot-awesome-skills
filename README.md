# biot-awesome-skills

Personal Claude Code skills for session management and productivity.

## Setup

Skills are symlinked into `~/.claude/skills/` (Claude Code) and `~/.agents/skills/` (Codex). Cursor CLI requires **real directories** under `~/.cursor/skills/` (symlinks outside that tree are ignored for security).

```bash
# Link all skills into Claude Code and Codex (run from repo root)
mkdir -p "$HOME/.claude/skills" "$HOME/.agents/skills" "$HOME/.cursor/skills"
for skill in */; do
  if [ -f "$skill/SKILL.md" ]; then
    ln -sfn "$(pwd)/$skill" "$HOME/.claude/skills/${skill%/}"
    ln -sfn "$(pwd)/$skill" "$HOME/.agents/skills/${skill%/}"
    rsync -a --delete "$skill/" "$HOME/.cursor/skills/${skill%/}/"
  fi
done
```

## Skills

| Skill | Description |
|-------|-------------|
| `context-save` | Snapshot session state (branch, decisions, findings) to `~/.claude/contexts/` |
| `context-restore` | Search and load saved contexts to resume prior work |
| `deep-investigate` | Evidence-driven investigation for hard bugs — enforces prove-don't-pattern-match |
| `deep-understand` | Deep understanding of existing code/systems — WHY it exists, how it flows, what shaped it |
| `estimating-tasks` | Defensible work-day estimates — multi-solution worst-case + 30–40% buffer, scope-locked, no assumptions |
| `mapping-product-to-code` | Product-side questions get a product↔code mapping table first, then a walkthrough — asks when a product term is ambiguous, never blends product vocab with code identifiers in one sentence |
| `branch-commit-pr` | Branch + commit + push + PR as one flow — skips already-done steps, never creates a PR without showing the drafted title/description for approval first |

## Adding a new skill

1. Create a directory: `mkdir my-skill`
2. Add `my-skill/SKILL.md` with YAML frontmatter (`name`, `description`) + instructions
3. Install for all agents:
   ```bash
   ln -sfn "$(pwd)/my-skill" ~/.claude/skills/my-skill
   ln -sfn "$(pwd)/my-skill" ~/.agents/skills/my-skill
   rsync -a --delete my-skill/ ~/.cursor/skills/my-skill/
   ```
4. Commit and push

## Agent operating rules

`AGENTS.md` holds the cross-agent engineering discipline rules (anti-rationalization checklist, verification gate, five non-negotiables). `CLAUDE.md` is a symlink to `AGENTS.md` so any agent — Claude Code, Codex, Cursor, etc. — reads the same instructions. Edit `AGENTS.md`; the symlink keeps `CLAUDE.md` in sync.
