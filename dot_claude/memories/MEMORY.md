# Memory Index

## Carepackages
- `~/carepackages/` — directory for care packages sent to partner via Discord
- See [terraria-multiplayer.md](terraria-multiplayer.md) for tModLoader setup details

## Partner
- On same local network (LAN), connects via 192.168.1.102
- She is on Wi-Fi, sushii is wired
- Has Claude CLI available for troubleshooting

## DMS Greeter / Greetd
- See `~/.claude-context/projects/greetd-dms/STATE.md` for full context
- Multi-monitor bug: DMS greeter auth fails when `Quickshell.screens[0]` isn't the screen the user interacts with. `isPrimaryScreen` check gates auth handler, `passwordSubmitRequested` is per-instance local state.
- Fix: disable secondary monitor in `/etc/greetd/niri/dms.kdl` (set `off`)
- Niri output order (DP-1, DP-2) doesn't match physical/config order — AOC is DP-1, Samsung is DP-2
- Quickshell logs at `/run/user/954/quickshell/by-id/*/log.log` (per-boot, greeter user)
- Debugging approach: strace on quickshell PID, filter for greetd socket writes

## Hardware
- Samsung Odyssey G85SB ultrawide (3440x1440@175Hz) — DP-2 in niri
- AOC 27G1G4 portrait (1920x1080@120Hz, rotated 90°) — DP-1 in niri
- Elgato Wave XLR (audio interface)

## Desktop Environment
- **Compositor:** Niri (scrollable tiling Wayland), NOT Hyprland
- **Dotfiles:** DMS (Quickshell-based), NOT End-4 HyprDots
- **Terminal:** Ghostty 1.2.3 with custom "dankcolors" theme
- **Shell:** fish 4.5.0 (primary), zsh also installed with Powerlevel10k (wizard disabled)
- **Font:** JetBrainsMono Nerd Font (installed to ~/.local/share/fonts/JetBrainsMono/)
- CLAUDE.md previously had wrong compositor/dotfiles info -- corrected 2026-03-06
- See [terminal-setup.md](terminal-setup.md) for full terminal customization details
