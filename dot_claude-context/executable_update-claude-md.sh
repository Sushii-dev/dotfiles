#!/bin/bash
# Updates ~/CLAUDE.md with current active projects from ~/.claude-context/projects/
# Preserves the system structure section

CONTEXT_DIR="$HOME/.claude-context"
CLAUDE_MD="$HOME/CLAUDE.md"

# Build project table
PROJECT_TABLE=""
for state_file in "$CONTEXT_DIR/projects/"*/STATE.md; do
    if [ -f "$state_file" ]; then
        project_dir=$(dirname "$state_file")
        project_name=$(basename "$project_dir")

        # Extract status from STATE.md (looks for **Status:** line)
        status=$(grep -m1 "^\*\*Status:\*\*" "$state_file" | sed 's/\*\*Status:\*\* //' || echo "Unknown")

        PROJECT_TABLE="$PROJECT_TABLE| $project_name | $status | \`~/.claude-context/projects/$project_name/STATE.md\` |\n"
    fi
done

# If no projects found
if [ -z "$PROJECT_TABLE" ]; then
    PROJECT_TABLE="| (none) | - | - |\n"
fi

# Write CLAUDE.md with full system info
cat > "$CLAUDE_MD" << 'HEADER'
# Claude Auto-Context

This file is automatically read by Claude Code at session start.

## System Structure

### Machine
- **Hostname:** Sushimus
- **OS:** CachyOS (Arch-based, kernel 6.17.x)
- **Desktop:** Hyprland (Wayland compositor)
- **Dotfiles:** End-4 HyprDots (ags/eww widgets, themed)
- **User:** sushii

### Storage Layout

| Drive | Size | Mount | Label | Purpose |
|-------|------|-------|-------|---------|
| nvme1n1p2 | 892GB | `/` `/home` | (root) | System drive - OS, home directory |
| nvme1n1p1 | 2GB | `/boot` | - | Boot partition |
| nvme0n1p1 | 3.6TB | `/mnt/Tsukiji` | Tsukiji | Games & large files (Steam, ComfyUI, Modding) |
| nvme2n1p1 | 931GB | `/mnt/Noren` | Noren | AI projects & models |
| USB | varies | `/run/media/sushii/*` | varies | Removable drives auto-mount here |

### Key Directories

| Path | Purpose |
|------|---------|
| `/home/sushii/` | Home directory |
| `/home/sushii/.claude-context/` | Claude context persistence system |
| `/mnt/Tsukiji/` | Large storage - games, backups, media |
| `/mnt/Noren/AI/` | AI projects and models |
| `/run/media/sushii/` | USB/removable drives mount here |

### Desktop Environment
- **Compositor:** Hyprland (Wayland)
- **Dotfiles:** End-4 HyprDots (`~/.config/hypr/`, ags widgets)
- **Shell:** zsh (with .zshrc) and bash available
- **Config location:** `~/.config/` (hypr, ags, waybar, etc.)

---

## Context System

Check for active projects and context at:
```
~/.claude-context/
```

### Quick Commands

- **List active projects:** `ls ~/.claude-context/projects/`
- **Read project state:** `cat ~/.claude-context/projects/{name}/STATE.md`
- **Update this file:** `~/.claude-context/update-claude-md.sh`

## Active Projects

| Project | Status | Context Path |
|---------|--------|--------------|
HEADER

# Append the project table
echo -e "$PROJECT_TABLE" >> "$CLAUDE_MD"

# Append the footer
cat >> "$CLAUDE_MD" << 'FOOTER'

## On Session Start

If resuming work, read the relevant STATE.md file for full context including:
- What's been completed
- What's in progress
- Next steps
- Important paths and commands

## User Preferences

- User: sushii
- Primary work directories: `/home/sushii/`, USB drives at `/run/media/sushii/`
- Large file storage: `/mnt/Tsukiji/`
- AI/ML projects: `/mnt/Noren/AI/`
- Context storage: `~/.claude-context/`
FOOTER

echo "Updated $CLAUDE_MD"
