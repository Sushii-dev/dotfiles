# System Recovery — TTY Boot Instructions

## If greeter/greetd fails — switch back to SDDM
From TTY (`Ctrl+Alt+F2`):
```bash
sudo systemctl disable greetd
sudo systemctl enable sddm
sudo reboot
```

## If you need to switch back to greetd after SDDM
```bash
sudo systemctl disable sddm
sudo systemctl enable greetd
sudo reboot
```

## greetd config location
- `/etc/greetd/config.toml`

## Key packages (DMS + niri stack)
- `niri` — scrollable-tiling Wayland compositor
- `dms-shell-bin` — DMS shell (Quickshell-based desktop environment)
- `greetd` — login manager daemon
- `greetd-dms-greeter-git` — DMS greeter for greetd
- `quickshell` — Qt Quick-based shell toolkit (DMS dependency)
