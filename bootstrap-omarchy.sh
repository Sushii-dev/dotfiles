#!/usr/bin/env bash
set -e

REPO_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.config_backup_omarchy"

echo "[bootstrap] Starting Omarchy bootstrap using repo at $REPO_DIR"

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[bootstrap] ERROR: $REPO_DIR does not look like a git repo."
  exit 1
fi

mkdir -p "$BACKUP_DIR"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"

# Packages we consider safe to stow
safe_pkgs=(
  alacritty
  btop
  elephant
  fastfetch
  fontconfig
  ghostty
  git
  imv
  kitty
  lazygit
  mimeapps
  mise
  nvim
  qalculate
  swayosd
  systemd
  uwsm
  walker
  waybar
  xournalpp
  starship
  scripts
)

echo "[bootstrap] Backing up existing configs for safe packages (if any)"

for pkg in "${safe_pkgs[@]}"; do
  case "$pkg" in
    mimeapps)
      if [ -f "$HOME/.config/mimeapps.list" ]; then
        mv "$HOME/.config/mimeapps.list" "$BACKUP_DIR/mimeapps.list"
        echo "  - moved ~/.config/mimeapps.list to backup"
      fi
      ;;
    starship)
      if [ -f "$HOME/.config/starship.toml" ]; then
        mv "$HOME/.config/starship.toml" "$BACKUP_DIR/starship.toml"
        echo "  - moved ~/.config/starship.toml to backup"
      fi
      ;;
    scripts)
      # nothing in ~/.config for scripts
      ;;
    *)
      if [ -e "$HOME/.config/$pkg" ]; then
        mv "$HOME/.config/$pkg" "$BACKUP_DIR/$pkg"
        echo "  - moved ~/.config/$pkg to backup"
      fi
      ;;
  esac
done

echo "[bootstrap] Stowing safe packages"

cd "$REPO_DIR"

for pkg in "${safe_pkgs[@]}"; do
  if [ -d "$REPO_DIR/$pkg" ]; then
    echo "  - stow $pkg"
    stow "$pkg"
  else
    echo "  - skip $pkg (not present in repo)"
  fi
done

echo "[bootstrap] Applying Hypr config if available"

if [ -d "$REPO_DIR/hypr/.config/hypr" ]; then
  if command -v omarchy-sync-hypr >/dev/null 2>&1; then
    omarchy-sync-hypr
  else
    echo "[bootstrap] WARNING: omarchy-sync-hypr not in PATH."
    echo "            Make sure ~/.local/bin is in PATH and run: omarchy-sync-hypr"
  fi
else
  echo "[bootstrap] No hypr/.config/hypr directory in repo, skipping Hypr sync."
fi

echo "[bootstrap] Installing Posy's Improved Cursor (Black)..."
if command -v install-posy-cursor &>/dev/null; then
  install-posy-cursor
else
  echo "[bootstrap] WARNING: install-posy-cursor not in PATH yet."
  echo "            After login, run: install-posy-cursor"
fi

echo ""
echo "[bootstrap] Optional: Install NextDNS for system-wide ad blocking?"
echo "            (requires sudo to set up system service)"
read -p "Install NextDNS? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if command -v install-nextdns &>/dev/null; then
    install-nextdns
  else
    echo "[bootstrap] WARNING: install-nextdns not in PATH yet."
    echo "            After login, run: install-nextdns"
  fi
else
  echo "[bootstrap] Skipping NextDNS. You can install it later with: install-nextdns"
fi

echo ""
echo "[bootstrap] Done."
echo "[bootstrap] If anything feels off, your old configs are in: $BACKUP_DIR"
