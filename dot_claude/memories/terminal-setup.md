# Terminal Setup (2026-03-06)

## DMS Dynamic Color Pipeline
DMS generates colors from wallpaper → `~/.cache/DankMaterialShell/dms-colors.json`
A Python script reads this and regenerates configs for tools that DMS doesn't natively template.

### Script: `~/.local/bin/dms-update-starship`
- Reads `dms-colors.json`, applies to templates, outputs:
  - `~/.config/starship.toml` (from `~/.config/matugen/templates/starship.toml`)
  - `~/.config/fish/conf.d/dms-colors.fish` (fish syntax highlighting colors)
- **IMPORTANT:** Template uses Python f-string with Unicode escapes for powerline glyphs (U+E0B0).
  The Write tool strips these characters — must use Python/Bash to write the template file.

### Auto-trigger: systemd path watcher
- `~/.config/systemd/user/dms-starship.path` — watches `dms-colors.json` for changes
- `~/.config/systemd/user/dms-starship.service` — runs the script
- Enabled: `systemctl --user enable --now dms-starship.path`

### DMS matugen user templates
- `~/.config/matugen/config.toml` points to starship template
- DMS has `runUserMatugenTemplates: true` in settings
- BUT standalone `dms matugen generate` requires many internal flags — Python script approach is simpler
- `dank16.*` variables are DMS-only, not available in standalone matugen

## Starship Prompt
- Style: Tokyo Night preset adapted with DMS colors
- Palette: light→dark gradient (primary → color4 → secondary_container → color5 → background)
- OS symbol: 🍣 sushi emoji (not Arch icon)
- Two-line: segments on line 1, `❯` character on line 2
- Template at `~/.config/matugen/templates/starship.toml`

## Fish Shell
- Config: `~/.config/fish/config.fish` (sources cachyos defaults, inits zoxide, atuin, starship)
- Environment: `~/.config/fish/conf.d/environment.fish` (EDITOR=nvim, bat theme, vivid LS_COLORS)
- DMS colors: `~/.config/fish/conf.d/dms-colors.fish` (auto-generated, fish_color_* variables)
- Yazi wrapper: `~/.config/fish/functions/y.fish`

## Ghostty Config (`~/.config/ghostty/config`)
- Font: JetBrainsMono Nerd Font, size 13, ligatures enabled
- Cursor: block style, no blink, cursor_warp.glsl shader for trail effect
- `adjust-cursor-height = -4` — shrinks block cursor height (does NOT work for bar cursors)
- `adjust-cell-height = 4` — adds line spacing
- Background: opacity 0.5, blur radius 32
- `copy-on-select = clipboard` — selecting text auto-copies to system clipboard (not `true`, which copies to primary selection only)
- Keybinds: Ctrl+V=paste, Ctrl+Shift+C=copy, shift+arrows=adjust_selection
- Theme: `dankcolors` (DMS-generated)
- `gtk-single-instance = true` — config changes need full restart (close all windows)
- `performable:` keybind prefix is NOT valid in Ghostty 1.2.3
- Dotfiles managed with chezmoi, repo: `Sushii-dev/dotfiles` (private, SSH)

## Niri Tweaks (from this session)
- `focus-follows-mouse` enabled
- Gradient borders: yellow→pink, `relative-to="window"` in `~/.config/niri/dms/colors.kdl`
- Gaps: 8, border/focus-ring width: 1 in `~/.config/niri/dms/layout.kdl`
- Per-monitor layouts in `~/.config/niri/dms/outputs.kdl`
- Keybinds in `~/.config/niri/dms/binds.kdl`: Mod+S screenshot, Mod+Shift+S region, Mod+E dolphin

## Git
- Delta as pager with side-by-side disabled, line numbers, syntax theme Coldark-Dark
- Config at `~/.gitconfig`

## Optional Future Ideas
- fzf theming to match DMS colors
- Fastfetch greeting customization
- Fish abbreviations for common commands
- DMS color templates for bat, delta, fzf
