#!/usr/bin/env bash
# Simple dotfiles installer using manual symlinks

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
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

# Symlink tmux
backup_if_exists "$CONFIG_DIR/tmux"
ln -sfn "$DOTFILES_DIR/tmux" "$CONFIG_DIR/tmux"
echo "✓ Linked tmux config"

# Symlink scripts into ~/.local/bin (already on PATH)
mkdir -p "$HOME/.local/bin"
for script in "$DOTFILES_DIR"/bin/*; do
    [ -f "$script" ] || continue
    ln -sf "$script" "$HOME/.local/bin/$(basename "$script")"
    echo "✓ Linked $(basename "$script")"
done

echo "Done! Your dotfiles are now linked."
