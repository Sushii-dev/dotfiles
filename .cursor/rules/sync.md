---
alwaysApply: true
---

# Sync and architecture rules

These rules are instructions for Cursor. Follow them when working in this repository.

## Core model

This project uses a strict separation between

- System and Omarchy internals  
- User configs in the dotfiles repo  
- Per device overrides  

Cursor must always respect this separation.

## Forbidden paths

Cursor must NEVER edit, delete, move, or create files in these locations:

- /etc  
- /usr  
- /opt  

Most important:

- ~/.config/omarchy  
- ~/.local/share/omarchy  

These belong to Omarchy and are not part of the dotfiles sync system.

## Dotfiles architecture

All user configs live in:

- ~/dotfiles

Configs are arranged as stow packages:

- ~/dotfiles/<package>/.config/<package>/...

Examples of allowed edit locations:

- dotfiles/alacritty/.config/alacritty/alacritty.toml  
- dotfiles/waybar/.config/waybar/config.jsonc  
- dotfiles/nvim/.config/nvim/init.lua  

Cursor is allowed to edit only files inside the dotfiles repo.

Cursor must avoid editing the linked locations under ~/.config directly, even if they are symlinks into dotfiles.

## Stow usage

Deployment of configs to the actual system is handled with stow, not manual symlinks.

When you need to apply a package, prefer commands like:

```bash
cd ~/dotfiles
stow alacritty
stow waybar
stow nvim
stow scripts
```

Cursor must never suggest creating symlinks with ln.

Cursor should always recommend stow for new packages.

## Hypr sync model

Hypr configs use a safe model.

Canonical location in repo:

- ~/dotfiles/hypr/.config/hypr/

Live location on system:

- ~/.config/hypr

The canonical config is copied to the live config using the helper script:

```bash
omarchy-sync-hypr
```

This script:

- Backs up ~/.config/hypr to ~/.config/hypr_backup_YYYY-MM-DD-HHMMSS if it exists  
- Copies ~/dotfiles/hypr/.config/hypr to ~/.config/hypr  
- Tries to run hyprctl reload  

Cursor must not suggest manually copying Hypr configs. Always prefer omarchy-sync-hypr.

## Monitors and per device overrides

Monitor configs are per device and must NOT be tracked in git.

The repo must not contain:

- hypr/.config/hypr/monitors.conf  
- hypr/.config/hypr/monitors_desktop.conf  
- hypr/.config/hypr/monitors_laptop.conf  

These files live only in:

- ~/.config/hypr/monitors.conf

and are excluded via .gitignore.

Cursor must not create or edit monitor configs inside the repo.

## Sync scripts

There are two main helpers.

Pushing changes from this machine:

```bash
dotfiles-sync push
```

Pulling changes onto another machine:

```bash
dotfiles-sync pull
omarchy-sync-hypr
```

Cursor should use these scripts instead of raw git commands when referring to everyday workflows, unless the user explicitly asks for low level git instructions.

## Bootstrap for new installs

A new Omarchy install is set up with:

```bash
cd ~
git clone git@github.com:YOUR_USERNAME/dotfiles.git
cd dotfiles
./bootstrap-omarchy.sh
```

bootstrap-omarchy.sh:

- Backs up existing configs into ~/.config_backup_omarchy  
- Stows a safe set of packages  
- Stows scripts so helper commands are available in PATH  
- Applies Hypr config using omarchy-sync-hypr if present  

Cursor must not duplicate this logic in other locations. Improvements to new install behavior must go into bootstrap-omarchy.sh.
