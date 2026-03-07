# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). CachyOS (Arch-based), Niri compositor, DMS Quickshell widgets.

## Stack

| Component | Tool | Config |
|-----------|------|--------|
| Compositor | Niri | `.config/niri/` |
| Widgets | DMS (Quickshell) | `.config/niri/dms/` |
| Terminal | Ghostty | `.config/ghostty/` |
| Shell | fish | `.config/fish/` |
| Prompt | Starship | `.config/starship.toml` |
| Font | JetBrainsMono Nerd Font | — |
| Git pager | Delta | `.gitconfig` |
| AI | Claude Code | `CLAUDE.md`, `.claude/` |

## DMS Color Pipeline

Wallpaper → DMS generates `~/.cache/DankMaterialShell/dms-colors.json` → Python script regenerates Starship + fish syntax colors.

- Script: `.local/bin/dms-update-starship`
- Template: `.config/matugen/templates/starship.toml`
- Auto-trigger: systemd path watcher (`.config/systemd/user/dms-starship.*`)

## Setup

```sh
pacman -S chezmoi
chezmoi init --apply git@github.com:Sushii-dev/dotfiles.git
```

## Sync

```sh
# Push local changes
chezmoi re-add
cd ~/.local/share/chezmoi
git add -A && git commit -m "description" && git push

# Pull on other devices
chezmoi update
```
