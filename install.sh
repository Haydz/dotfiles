#!/bin/bash
# Simple dotfiles installer using manual symlinks

set -e

DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"

# Ensure .config exists
mkdir -p "$CONFIG_DIR"

# Backup existing configs if they exist
backup_if_exists() {
    if [ -e "$1" ]; then
        echo "Backing up existing $1..."
        mv "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

# Symlink nvim
backup_if_exists "$CONFIG_DIR/nvim"
ln -sf "$DOTFILES_DIR/nvim" "$CONFIG_DIR/nvim"
echo "✓ Linked nvim config"

# Symlink alacritty
backup_if_exists "$CONFIG_DIR/alacritty"
ln -sf "$DOTFILES_DIR/alacritty" "$CONFIG_DIR/alacritty"
echo "✓ Linked alacritty config"

echo "Done! Your dotfiles are now linked."
