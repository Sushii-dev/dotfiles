# kde-dank

Make KDE Plasma 6 feel like niri/Hyprland, with the same Material You aesthetic as DankMaterialShell. Built for a dual-session setup where niri + DMS is the daily driver and Plasma is the HDR gaming session, so the two should share muscle memory and palette.

## What you get

- **Dynamic tiling** via Krohnkite (the actively maintained anametologin fork on Codeberg), dwm-style master/stack with monocle and floating layouts, gaps included
- **niri/Hyprland keybindings**: Meta+1..9 workspaces, Meta+Shift+1..9 move window, Meta+Q close, Meta+Return terminal, Meta+D launcher, Meta+HJKL focus, Meta+Shift+HJKL move tiles, Meta+Ctrl+HJKL resize
- **Borderless tiles**: a global KWin window rule strips titlebars, gaps and rounded corners do the visual separation instead
- **Blur and antialiased rounded corners** via Better Blur DX (the maintained successor to taj-ny's Better Blur, which is archived)
- **Material You colors from your wallpaper** via a matugen template that plugs into the same matugen pipeline DMS already uses
- **A slim floating top bar** (optional) that approximates the DMS bar layout
- Snappy animations, sane multi-monitor focus, and a full uninstaller

## Requirements

- KDE Plasma 6 on Wayland (CachyOS or any Arch derivative works fine)
- `kwriteconfig6`, `kreadconfig6`, `qdbus6` (qt6-tools), `curl`, `jq`
- Optional but recommended: `paru -S kwin-effects-better-blur-dx` for blur and rounded corners
- Optional: matugen, if you want wallpaper-driven colors

## Install

```bash
chmod +x install.sh
# Edit the Tweakables block at the top first:
#   TERMINAL_DESKTOP  -> your terminal's .desktop id (default konsole)
#   GAP, CORNER_RADIUS, ANIM_SPEED, DESKTOP_COUNT
./install.sh
```

Then log out and back in. Krohnkite and the shortcut daemon need a fresh session.

After first login:

1. If duplicate or ghost KWin shortcuts appear (a known Plasma quirk when scripts register shortcuts), clean them once:

   ```bash
   qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.cleanUp
   ```

2. Open System Settings > Shortcuts > KWin and search for "Krohnkite" to confirm the hjkl bindings landed. Krohnkite registers its actions at runtime, and action names occasionally change between releases, so if a binding is empty just assign it there once. The script pre-seeds the names used by current releases.

3. Do not toggle the Krohnkite script on and off in System Settings. Per the project's own docs that can spawn multiple instances. If you change Krohnkite settings, restart the session instead.

## Keybinding reference

| Keys | Action |
|---|---|
| Meta+Return | Terminal |
| Meta+D | Launcher (KRunner) |
| Meta+Q | Close window |
| Meta+1..9 | Switch workspace |
| Meta+Shift+1..9 | Move window to workspace |
| Meta+H / J / K / L | Focus left / down / up / right |
| Meta+Shift+H/J/K/L | Move tile |
| Meta+Ctrl+H/J/K/L | Resize tile |
| Meta+F | Toggle float on focused window |
| Meta+Shift+Space | Float all (floating layout) |
| Meta+M | Promote to master |
| Meta+T | Monocle layout |
| Meta+\ | Cycle layouts |
| Meta+W | Overview |
| Meta+Shift+F | Fullscreen |
| Ctrl+Alt+L | Lock screen (moved off Meta+L, which tiling needs) |

## Material You colors (matugen)

The template maps Material 3 roles to KDE color roles the same way DMS builds its palette: `surface` for views, `surface_container_low` for window chrome, `surface_container_high` for buttons, `primary` for selection and focus accents, `error` for negatives, `inverse_surface` for tooltips.

Setup:

```bash
cp matugen/templates/kde-dank.colors ~/.config/matugen/templates/
# Append the [templates.kde] block from matugen/matugen-kde.toml
# to your existing ~/.config/matugen/config.toml
matugen image /path/to/wallpaper.png
```

Two ways to run it:

- **From inside Plasma**: the post_hook applies the scheme live (it flips to BreezeDark first because `plasma-apply-colorscheme` refuses to re-apply a scheme with an unchanged name).
- **From niri**: drop the post_hook. matugen still writes `~/.local/share/color-schemes/DankMatugen.colors`, and Plasma picks up the file on next login if DankMatugen is the selected scheme. This keeps both sessions on the same wallpaper palette with one matugen run.

Pair it with a flat window-decoration-free look: titlebars are already gone, so the scheme mostly drives widgets, the panel, and app chrome.

## Top bar (optional)

`extras/dank-panel.js` rebuilds your primary panel as a slim floating top bar: launcher and pager on the left, centered clock, system tray on the right. Translucent so Better Blur can frost it.

```bash
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(cat extras/dank-panel.js)"
```

Warning: it removes the panel's existing widgets before rebuilding. If you have custom widgets you care about, skip this or note them first.

## Gaming session notes

- Fullscreen windows are not blurred or rounded, so games are untouched. `steam` and `gamescope` are on Krohnkite's ignore list and will float.
- HDR: nothing here touches color management or the HDR pipeline. Better Blur DX only affects SDR desktop surfaces; if you ever see weirdness in an HDR fullscreen title, the effect can be disabled per window class in its settings, but fullscreen exclusion normally covers it.
- The squash minimize animation is disabled because Krohnkite's docs flag it as buggy with tiling; Magic Lamp is used instead.

## Uninstall

```bash
./uninstall.sh
```

Reverts shortcuts, removes the window rule, uninstalls Krohnkite, restores 4 desktops and default animation speed. Remove `kwin-effects-better-blur-dx` with your package manager if you no longer want it. Log out and back in afterwards.

## File map

```
kde-dank/
├── install.sh                      everything, idempotent
├── uninstall.sh                    full revert
├── matugen/
│   ├── templates/kde-dank.colors   matugen template -> KDE color scheme
│   └── matugen-kde.toml            config block for your matugen config
└── extras/
    └── dank-panel.js               plasmashell script, DMS-style top bar
```
