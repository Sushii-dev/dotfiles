---
alwaysApply: true
---

# Application config rules

These rules are instructions for Cursor when editing app configs.

## Terminals

Alacritty config:

- Repo location: dotfiles/alacritty/.config/alacritty/alacritty.toml  

Kitty config:

- Repo location: dotfiles/kitty/.config/kitty/kitty.conf  

Ghostty config:

- Repo location: dotfiles/ghostty/.config/ghostty/config  

Cursor may:

- Adjust fonts, sizes, paddings  
- Tweak colors to fit the theme  
- Add keybindings  

Cursor must not edit terminal configs directly under ~/.config. Always edit the files in the dotfiles repo.

## Neovim

Neovim config lives under:

- dotfiles/nvim/.config/nvim/

Key files include:

- init.lua  
- lua/config/*.lua  
- lua/plugins/*.lua  

Cursor should:

- Respect the existing plugin manager and layout  
- Add plugins using the same pattern that is already in use  
- Avoid large scale rewrites unless the user explicitly asks for that  

## Systemd user services

Systemd user units live in:

- dotfiles/systemd/.config/systemd/user/

Cursor may:

- Add new user level services and timers  
- Suggest enabling them with systemctl --user when appropriate  

Cursor must not create or edit system level units in /etc/systemd.

## Other apps

Each app with a package in this repo follows the pattern:

- dotfiles/<package>/.config/<package>/

Examples:

- dotfiles/fastfetch/.config/fastfetch/config.jsonc  
- dotfiles/lazygit/.config/lazygit/config.yml  
- dotfiles/qalculate/.config/qalculate/qalc.cfg  
- dotfiles/walker/.config/walker/config.toml  
- dotfiles/xournalpp/.config/xournalpp/settings.xml  

Cursor may safely edit these configs as long as changes stay inside the repo.
