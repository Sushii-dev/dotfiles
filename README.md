# Dotfiles for Omarchy  
A clean and safe setup for syncing ricing, Hyprland config, terminal styling, and app themes between devices.

## SSH Setup  
You need SSH keys so your devices can pull and push from your GitHub repo.

### 1. Create a new SSH key  
ssh-keygen -t ed25519 -C "your_email@example.com"

Press Enter for all prompts.

### 2. Add the key to the SSH agent  
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

### 3. Copy the public key to your clipboard  
cat ~/.ssh/id_ed25519.pub

Copy the entire line.

### 4. Add the key to GitHub  
Open GitHub  
Go to Settings  
Go to SSH and GPG keys  
Select New SSH key  
Paste the key and save it

## First time setup on a fresh Omarchy install  
Run these commands on a new machine.

### 1. Install dependencies  
Omarchy already includes stow and git so you do not need extra tools.

### 2. Clone the repo with SSH  
cd ~
git clone git@github.com:YOUR_USERNAME/dotfiles.git
cd dotfiles

### 3. Run the bootstrap  
./bootstrap-omarchy.sh

The system is now ready and synced.

## Sync workflow between devices  
This gives you a clean loop so both devices stay identical.

### From the device where you make changes  
dotfiles-sync push

### On the other device  
dotfiles-sync pull
omarchy-sync-hypr

## Manual Hyprland reload  
hyprctl reload

## Structure of this repo  
Only user configs are included.  
Omarchy system directories are not synced and are ignored for safety.

Included  
• Hyprland user configs  
• Neovim  
• Waybar  
• Kitty and Alacritty  
• Ghostty  
• Systemd user units  
• Fonts  
• Fastfetch  
• All scripts in the scripts folder  
• Starship prompt  
• Walker  
• Btop  
• Mimeapps  
• Many others

Not included  
• Omarchy system config  
• Any file inside .local/share/omarchy  
• Any file inside .config/omarchy  
• Hardware specific monitor config files such as monitors.conf and monitors_desktop.conf
