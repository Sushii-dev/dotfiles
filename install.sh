#!/usr/bin/env bash
set -e

# Omarchy Dotfiles One-Liner Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/dotfiles/main/install.sh | bash

GITHUB_USER="Sushii-dev"  # Change this to your GitHub username
REPO_NAME="dotfiles"
DOTFILES_DIR="$HOME/dotfiles"

echo "=========================================="
echo "   Omarchy Dotfiles Installer"
echo "=========================================="
echo ""

# Check if stow is installed (should be on Omarchy)
if ! command -v stow &> /dev/null; then
    echo "❌ Error: stow is not installed"
    echo "   Install it with: sudo pacman -S stow"
    exit 1
fi

# Clone or update the repo
if [ -d "$DOTFILES_DIR" ]; then
    echo "📦 Dotfiles directory already exists at $DOTFILES_DIR"
    echo ""
    echo "Options:"
    echo "  1. Pull latest changes and re-run bootstrap (recommended)"
    echo "  2. Remove and re-clone (fresh start)"
    echo "  3. Just run bootstrap with existing files"
    echo "  4. Cancel"
    read -p "Choose [1/2/3/4]: " choice
    
    case $choice in
        1)
            echo "📥 Pulling latest changes..."
            cd "$DOTFILES_DIR"
            git pull
            ;;
        2)
            echo "🗑️  Removing old dotfiles..."
            rm -rf "$DOTFILES_DIR"
            echo "📥 Cloning repository..."
            git clone "https://github.com/$GITHUB_USER/$REPO_NAME.git" "$DOTFILES_DIR"
            cd "$DOTFILES_DIR"
            ;;
        3)
            echo "▶️  Using existing files..."
            cd "$DOTFILES_DIR"
            ;;
        4)
            echo "Cancelled."
            exit 0
            ;;
        *)
            echo "Invalid choice. Cancelled."
            exit 1
            ;;
    esac
else
    echo "📥 Cloning repository..."
    git clone "https://github.com/$GITHUB_USER/$REPO_NAME.git" "$DOTFILES_DIR"
    cd "$DOTFILES_DIR"
fi

echo ""
echo "🚀 Running bootstrap script..."
echo ""

# Run the bootstrap script
if [ -f "$DOTFILES_DIR/bootstrap-omarchy.sh" ]; then
    "$DOTFILES_DIR/bootstrap-omarchy.sh"
else
    echo "❌ Error: bootstrap-omarchy.sh not found"
    exit 1
fi

echo ""
echo "=========================================="
echo "   ✓ Installation Complete!"
echo "=========================================="
echo ""
echo "🎨 Your Omarchy rice is now fully synced!"
echo ""
echo "💡 Useful commands:"
echo "   dotfiles-sync pull    - Pull latest config changes"
echo "   omarchy-sync-hypr     - Sync Hyprland config"
echo "   hyprctl reload        - Reload Hyprland"
echo ""
echo "📁 Dotfiles location: $DOTFILES_DIR"
echo "💾 Backup location: $HOME/.config_backup_omarchy"
echo ""

