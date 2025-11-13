---
alwaysApply: true
---

# Theming rules

These rules are instructions for Cursor when working on themes across apps.

## Theme source

Omarchy themes live in:

- ~/.config/omarchy/themes/<theme_name>  
- ~/.config/omarchy/current/theme

Cursor must NOT modify anything in these paths.

Instead, user configs in the repo should:

- Import or align with the theme where possible  
- Use colors that match the chosen theme palette  

## Terminals

Alacritty

- Main config in repo: dotfiles/alacritty/.config/alacritty/alacritty.toml  
- Omarchy theme colors may be imported via a file such as ~/.config/omarchy/current/theme/alacritty.toml if the user has configured that  

Kitty

- Config in repo: dotfiles/kitty/.config/kitty/kitty.conf  

Ghostty

- Config in repo: dotfiles/ghostty/.config/ghostty/config  

Cursor may extend user configs but must not break existing import behavior that pulls theme colors from Omarchy provided files.

## Color choices

When adjusting colors, Cursor should:

- Prefer the palette from the current Omarchy theme (for example Tokyo Night)  
- Prefer colors already used in other user configs in this repo  

Cursor should avoid mixing unrelated color schemes unless the user explicitly requests it.

## Neovim theme

Neovim config lives under:

- dotfiles/nvim/.config/nvim/

Cursor should try to keep Neovim color scheme aligned with the system theme when applicable, for example by:

- Selecting a matching colorscheme plugin  
- Adjusting background and highlight groups to fit the theme  

## No direct writes into Omarchy theme folders

Cursor must never write to:

- ~/.config/omarchy/themes  
- ~/.config/omarchy/current/theme

All custom theming must happen in user configs stored in the dotfiles repo.
