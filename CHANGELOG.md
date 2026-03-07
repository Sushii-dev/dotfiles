# Changelog

## 2026-03-07

### Added
- Initial chezmoi setup with all dotfiles
- Ghostty: cursor_warp.glsl shader (neovide-like trail effect)
- Ghostty: custom cursor shaders collection
- Fish: autopair, fzf, sponge, puffer-fish plugins
- Fish: yazi wrapper function
- Fish: DMS color integration for syntax highlighting
- Niri: DMS widget configs (colors, layout, binds, outputs, cursor, window rules)
- Starship: DMS color-templated prompt with Tokyo Night style
- Systemd: path watcher for auto-regenerating starship/fish colors on wallpaper change
- Claude Code: CLAUDE.md, settings, memories, context system
- Git: delta pager config

### Changed
- Ghostty: Maple Mono NF → JetBrainsMono Nerd Font
- Ghostty: cursor bar → block (adjust-cursor-height works with block only)
- Ghostty: background opacity 0.85 → 0.5
- Ghostty: copy-on-select = clipboard (auto-copy on text selection)
- Ghostty: added adjust-cell-height = 4 for line spacing
- Niri: border gradient yellow/pink → pink/purple (#e88fb4 → #b48fe8)

### Added (multi-device)
- chezmoi template for CLAUDE.md (per-hostname rendering)
- Merge script for Claude settings.json (union permissions, device wins)
- Memory sync script (places memories in correct username-based path)
- Systemd watcher for Niri border gradient (auto-patches DMS regeneration)
- Niri: border gradient pink→purple (#f078a0 → #9060e8)

### Removed
- Ghostty: invalid `performable:` keybind prefix (not supported in 1.2.3)
- SSH key passphrase (no longer needed, simplifies multi-terminal usage)
