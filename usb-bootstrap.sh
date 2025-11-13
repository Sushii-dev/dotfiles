#!/usr/bin/env bash
set -e

# USB Stick Bootstrap for Omarchy
# Copy this script to a USB stick and run it on any fresh Omarchy install
# It will set up SSH, clone your dotfiles, and apply all rice configs

GITHUB_USER="Sushii-dev"
REPO_NAME="dotfiles"
EMAIL="your_email@example.com"

echo "=========================================="
echo "   Omarchy Rice USB Bootstrap"
echo "=========================================="
echo ""

# Step 1: Check if SSH keys exist
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  echo "[1/5] Creating SSH key..."
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
  echo "✓ SSH key created"
else
  echo "[1/5] SSH key already exists"
fi

# Step 2: Start SSH agent and add key
echo ""
echo "[2/5] Setting up SSH agent..."
eval "$(ssh-agent -s)" > /dev/null
ssh-add ~/.ssh/id_ed25519 2>/dev/null
echo "✓ SSH agent configured"

# Step 3: Display public key and wait for GitHub setup
echo ""
echo "[3/5] Add this SSH key to GitHub:"
echo "=========================================="
cat ~/.ssh/id_ed25519.pub
echo "=========================================="
echo ""
echo "Go to: https://github.com/settings/keys"
echo "Click: 'New SSH key'"
echo "Paste the key above and save it"
echo ""
read -p "Press ENTER once you've added the key to GitHub..."

# Step 4: Test SSH connection
echo ""
echo "[4/5] Testing GitHub connection..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo "✓ GitHub connection successful"
else
  echo "Testing connection (this is expected to show 'Hi $GITHUB_USER')..."
  ssh -T git@github.com 2>&1 || true
fi

# Step 5: Clone dotfiles and run bootstrap
echo ""
echo "[5/5] Cloning dotfiles and running bootstrap..."

if [ -d "$HOME/dotfiles" ]; then
  echo "⚠️  ~/dotfiles already exists. Options:"
  echo "  1. Remove and re-clone (recommended for fresh install)"
  echo "  2. Pull latest changes (if already set up)"
  echo "  3. Cancel"
  read -p "Choose [1/2/3]: " choice
  
  case $choice in
    1)
      rm -rf "$HOME/dotfiles"
      cd ~
      git clone git@github.com:$GITHUB_USER/$REPO_NAME.git
      ;;
    2)
      cd "$HOME/dotfiles"
      git pull
      ;;
    3)
      echo "Cancelled."
      exit 0
      ;;
    *)
      echo "Invalid choice. Cancelled."
      exit 1
      ;;
  esac
else
  cd ~
  git clone git@github.com:$GITHUB_USER/$REPO_NAME.git
fi

cd "$HOME/dotfiles"
echo ""
echo "Running bootstrap..."
./bootstrap-omarchy.sh

echo ""
echo "=========================================="
echo "   ✓ Setup Complete!"
echo "=========================================="
echo ""
echo "Your Omarchy rice is now fully synced!"
echo ""
echo "To sync changes in the future, use:"
echo "  dotfiles-sync pull"
echo "  omarchy-sync-hypr"
echo ""

