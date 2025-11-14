# Dotfiles for Omarchy  
A clean and safe setup for syncing ricing, Hyprland config, terminal styling, and app themes between devices.

## 🚀 Quick Install (One-Liner)

On a fresh Omarchy install, run this single command:

```bash
curl -fsSL https://raw.githubusercontent.com/Sushii-dev/dotfiles/main/install.sh | bash
```

**That's it!** ✨ The script will:
- Clone this repo to `~/dotfiles`
- Backup any existing configs to `~/.config_backup_omarchy`
- Apply all rice settings using GNU Stow
- Sync Hyprland configs (if available)

Your system will be identical to mine in seconds.

---

## 🔄 Keeping Configs in Sync

Once installed, use these commands to stay up-to-date:

```bash
# Pull latest changes from this repo
cd ~/dotfiles && git pull && ./bootstrap-omarchy.sh

# Or use the included sync script
dotfiles-sync pull

# Sync Hyprland config specifically
omarchy-sync-hypr

# Reload Hyprland manually
hyprctl reload
```

---

## 🛠️ For Contributors / Pushing Changes

If you want to **push your own config changes** back to your fork or make modifications:

### 1. Set up SSH keys

```bash
# Generate a new SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key
cat ~/.ssh/id_ed25519.pub
```

### 2. Add key to GitHub
1. Go to [GitHub SSH Settings](https://github.com/settings/keys)
2. Click "New SSH key"
3. Paste your public key and save

### 3. Change remote to SSH

```bash
cd ~/dotfiles
git remote set-url origin git@github.com:Sushii-dev/dotfiles.git
```

Now you can push changes:

```bash
dotfiles-sync push
```

---

## 📦 What's Included

This repo contains **user configs only**. Omarchy system directories are not synced for safety.

### ✅ Included
- 🎨 Hyprland user configs
- ⚙️ Neovim
- 📊 Waybar
- 🖥️ Terminal configs (Kitty, Alacritty, Ghostty)
- 🔧 Systemd user units
- 🔤 Fonts & fontconfig
- 📸 Fastfetch
- 🚀 Starship prompt
- 🔍 Walker launcher
- 📈 Btop
- 📄 Mimeapps
- 🛠️ Custom scripts (`~/.local/bin`)
- And many more...

### ❌ Not Included
- Omarchy system config
- `.local/share/omarchy/`
- `.config/omarchy/`
- Hardware-specific monitor configs (`monitors.conf`, `monitors_desktop.conf`)
