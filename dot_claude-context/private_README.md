# Claude Context System

Location: `~/.claude-context/`

This folder persists context across Claude sessions and system restarts.

## Auto-Read System

Claude Code automatically reads `~/CLAUDE.md` at session start. This file:
- Lists all active projects with their status
- Points Claude to the relevant STATE.md files
- Is auto-generated from project STATE.md files

### How It Works

1. `~/CLAUDE.md` is read automatically by Claude on every session
2. It shows active projects from `~/.claude-context/projects/`
3. Claude sees the project list and can read STATE.md for full context

### Updating CLAUDE.md

Run this after changing project status:
```bash
~/.claude-context/update-claude-md.sh
```

## Directory Structure

```
~/.claude-context/
├── README.md                 # This file
├── update-claude-md.sh       # Script to refresh ~/CLAUDE.md
├── projects/                 # Active project states
│   └── {project-name}/
│       ├── STATE.md          # Current state & next steps
│       ├── BACKUPS.md        # What's backed up & where
│       └── *.md              # Additional context files
├── sessions/                 # Session logs (optional)
│   └── YYYY-MM-DD-*.md
└── guides/                   # Reusable how-to guides
    └── *.md

~/CLAUDE.md                   # Auto-read by Claude (generated)
```

## File Conventions

### STATE.md (Required for each project)
Must include near the top:
```markdown
**Status:** IN PROGRESS - Brief description
```

This status line is extracted for the CLAUDE.md project table.

Also include:
- What's been completed
- What's in progress
- Next steps
- Important paths/commands

### BACKUPS.md
- What was backed up
- Where backups are located
- How to verify/restore

## Adding New Projects

```bash
# 1. Create project folder
mkdir ~/.claude-context/projects/{name}

# 2. Create STATE.md
cat > ~/.claude-context/projects/{name}/STATE.md << 'EOF'
# Project Name

**Last Updated:** YYYY-MM-DD
**Status:** IN PROGRESS - Description

## Goal
What you're trying to accomplish

## Current State
- [x] Completed items
- [ ] Pending items

## Next Steps
1. Step one
2. Step two

## Important Paths
| Item | Location |
|------|----------|
| ... | ... |
EOF

# 3. Update CLAUDE.md
~/.claude-context/update-claude-md.sh
```

## Completing/Archiving Projects

1. Update STATE.md status to `COMPLETED` or `ARCHIVED`
2. Run `~/.claude-context/update-claude-md.sh`
3. Optionally move to an `archived/` folder

## Quick Reference

| Task | Command |
|------|---------|
| List projects | `ls ~/.claude-context/projects/` |
| Read project state | `cat ~/.claude-context/projects/{name}/STATE.md` |
| Update CLAUDE.md | `~/.claude-context/update-claude-md.sh` |
| New project | `mkdir ~/.claude-context/projects/{name}` |
