# Memory Index

## Dotfiles & Chezmoi
- Managed with chezmoi, repo: `Sushii-dev/dotfiles` (private, SSH)
- Source dir: `~/.local/share/chezmoi/`
- Multi-device: CLAUDE.md templated per hostname, settings.json merged via modify script
- Desktop hostname: `Sushitop`, user: `sushii`
- Laptop user: `markusmi` (hostname unknown — add to CLAUDE.md template when discovered)
- GitHub CLI (`gh`) authenticated via SSH
- Git identity: `Sushii-dev <markus@rindahl.me>`
- SSH key: `~/.ssh/id_ed25519` — no passphrase
- See [terminal-setup.md](terminal-setup.md) for full terminal/niri config details

## Carepackages
- `~/carepackages/` — directory for care packages sent to partner via Discord
- See [terraria-multiplayer.md](terraria-multiplayer.md) for tModLoader setup details

## Partner
- On same local network (LAN), connects via 192.168.1.102
- She is on Wi-Fi, sushii is wired
- Has Claude CLI available for troubleshooting

## DMS Greeter / Greetd
- See `~/.claude-context/projects/greetd-dms/STATE.md` for full context
- Multi-monitor bug: DMS greeter auth fails when `Quickshell.screens[0]` isn't the screen the user interacts with
- Fix: disable secondary monitor in `/etc/greetd/niri/dms.kdl` (set `off`)

## Hardware
- Samsung Odyssey G85SB ultrawide (3440x1440@175Hz) — DP-2 in niri
- AOC 27G1G4 portrait (1920x1080@120Hz, rotated 90°) — DP-1 in niri
- Elgato Wave XLR (audio interface)

## Desktop Environment
- **Compositor:** Niri (scrollable tiling Wayland), NOT Hyprland
- **Dotfiles:** DMS (Quickshell-based), NOT End-4 HyprDots
- **Terminal:** Ghostty 1.2.3 with custom "dankcolors" theme
- **Shell:** fish (primary), zsh also installed
- **Font:** JetBrainsMono Nerd Font (`~/.local/share/fonts/JetBrainsMono/`)
- See [terminal-setup.md](terminal-setup.md) for full terminal customization details
