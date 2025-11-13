---
alwaysApply: true
---

# Waybar config rules

These rules are instructions for Cursor when editing Waybar configs.

## Allowed edit locations

Cursor may edit:

- ~/dotfiles/waybar/.config/waybar/config.jsonc  
- ~/dotfiles/waybar/.config/waybar/style.css  
- Any additional files under ~/dotfiles/waybar/.config/waybar

Cursor must not edit:

- ~/.config/waybar/* directly  
- Any Waybar related file under ~/.config/omarchy or ~/.local/share/omarchy  

## Jsonc style

Waybar config is jsonc:

- Use double quotes for keys and string values  
- Keep indentation consistent with the existing file  
- Use comments to label sections if appropriate  

Example:

```jsonc
{
  "layer": "top",
  "position": "top",

  // Left modules
  "modules-left": [
    "hyprland/workspaces",
    "hyprland/window"
  ],

  // Center modules
  "modules-center": [
    "clock"
  ],

  // Right modules
  "modules-right": [
    "pulseaudio",
    "cpu",
    "memory",
    "network",
    "tray"
  ]
}
```

Cursor should preserve existing keys and only add or adjust as requested.

## CSS style

Waybar CSS lives in style.css.

Cursor may:

- Add new classes  
- Tweak colors and spacing  
- Introduce variables following existing patterns  

Cursor should:

- Keep colors consistent with the chosen theme, for example Tokyo Night  
- Use padding and margins similar to existing ones  
- Avoid extreme values unless explicitly requested  

Example:

```css
window#waybar {
  background: rgba(26, 27, 38, 0.95);
  color: #c0caf5;
}

#clock {
  padding: 0 10px;
}
```

## Theme awareness

If the user is using a specific Omarchy theme, Cursor should align custom Waybar colors with that palette when possible. Do not reference Omarchy theme files directly from the Waybar config. Keep Waybar config self contained inside the dotfiles repo.
