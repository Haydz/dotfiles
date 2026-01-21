# Dotfiles

My personal configuration files for Neovim and Alacritty.

## Contents

- `nvim/` - Neovim configuration
- `alacritty/` - Alacritty terminal configuration

## Installation

### Quick Install

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Manual Installation

If you prefer to do it manually:

```bash
mkdir -p ~/.config
ln -s ~/dotfiles/nvim ~/.config/nvim
ln -s ~/dotfiles/alacritty ~/.config/alacritty
```

## Requirements

- Neovim 0.9+
- Alacritty
- Lazy.nvim (auto-installed by Neovim config)
