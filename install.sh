#!/usr/bin/env bash
# Dotfiles installer: symlink config into place, then report missing deps.
#
#   ./install.sh          link everything, then run the dependency check
#   ./install.sh --check  only run the dependency check, change nothing
#
# Linking is idempotent — a link that already points here is left alone, so
# re-running does not pile up backup copies. Anything else in the way is
# moved to <path>.backup.<timestamp> first.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

CHECK_ONLY=0
[ "${1:-}" = "--check" ] || [ "${1:-}" = "-c" ] && CHECK_ONLY=1

# ---------------------------------------------------------------- linking ---

# link <source> <dest> <label>
#
# -n on ln is load-bearing: without it, `ln -sf dir existing-symlink-to-dir`
# creates the link *inside* the target directory instead of replacing it.
link() {
    src="$1"; dest="$2"; label="$3"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "= $label already linked"
        return
    fi

    # -e is false for a broken symlink, so test -L too, or the stale link
    # survives unbacked-up.
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        backup="$dest.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$dest" "$backup"
        echo "  backed up existing $dest -> $backup"
    fi

    ln -sfn "$src" "$dest"
    echo "✓ Linked $label"
}

if [ "$CHECK_ONLY" -eq 0 ]; then
    mkdir -p "$CONFIG_DIR" "$HOME/.local/bin"

    link "$DOTFILES_DIR/nvim"      "$CONFIG_DIR/nvim"      "nvim config"
    link "$DOTFILES_DIR/alacritty" "$CONFIG_DIR/alacritty" "alacritty config"
    link "$DOTFILES_DIR/tmux"      "$CONFIG_DIR/tmux"      "tmux config"

    for script in "$DOTFILES_DIR"/bin/*; do
        [ -f "$script" ] || continue
        name="$(basename "$script")"
        link "$script" "$HOME/.local/bin/$name" "$name"
    done

    echo "Done! Your dotfiles are now linked."
    echo
fi

# ------------------------------------------------------------ dep checking ---

missing_required=0
missing_optional=0

case "$(uname -s)" in
    Darwin) PLATFORM=macos ;;
    *)      PLATFORM=linux ;;
esac

# hint <macos-command> <linux-note>
hint() {
    if [ "$PLATFORM" = macos ]; then echo "      $1"; else echo "      $2"; fi
}

# need <binary> <what it is> <macos install> <linux install>
need() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "  ✓ $1"
    else
        echo "  ✗ $1 — $2"
        hint "$3" "$4"
        missing_required=$((missing_required + 1))
    fi
}

# want <binary> <what it is> <macos install> <linux install>
want() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "  ✓ $1"
    else
        echo "  · $1 — $2"
        hint "$3" "$4"
        missing_optional=$((missing_optional + 1))
    fi
}

echo "Checking dependencies ($PLATFORM)..."
echo
echo "Core:"
need nvim  "the editor these configs are for" \
    "brew install neovim" "your package manager: neovim (0.9+)"
need tmux  "terminal multiplexer" \
    "brew install tmux" "your package manager: tmux (3.1+)"
need git   "lazy.nvim clones plugins with it" \
    "xcode-select --install" "your package manager: git"
need cc    "treesitter compiles parsers on install" \
    "xcode-select --install" "your package manager: build-essential / base-devel"

echo
echo "Terminal:"
# The GUI app can be installed without `alacritty` being on PATH, which is
# fine — nothing here shells out to it. Check both so the report is honest.
if command -v alacritty >/dev/null 2>&1; then
    echo "  ✓ alacritty ($(alacritty --version 2>/dev/null))"
elif [ -d /Applications/Alacritty.app ]; then
    echo "  ✓ alacritty (app installed; CLI not on PATH)"
else
    echo "  ✗ alacritty — the terminal these themes are for"
    hint "brew install --cask alacritty" "your package manager: alacritty (0.13+)"
    missing_required=$((missing_required + 1))
fi

# No fc-list on macOS, so look in the font directories directly.
font_found=0
if command -v fc-list >/dev/null 2>&1; then
    fc-list : family 2>/dev/null | grep -qi "JetBrainsMono Nerd Font" && font_found=1
else
    for d in "$HOME/Library/Fonts" /Library/Fonts /System/Library/Fonts; do
        [ -d "$d" ] || continue
        ls "$d" 2>/dev/null | grep -qi "JetBrainsMono" && { font_found=1; break; }
    done
fi
if [ "$font_found" -eq 1 ]; then
    echo "  ✓ JetBrainsMono Nerd Font"
else
    echo "  ✗ JetBrainsMono Nerd Font — alacritty.toml names it; without it"
    echo "      the terminal silently falls back to a default font"
    hint "brew install --cask font-jetbrains-mono-nerd-font" \
         "see README.md for the per-distro font install"
    missing_required=$((missing_required + 1))
fi

echo
echo "Neovim plugin dependencies (optional — nvim starts without these,"
echo "the matching feature is just dead):"
want rg "telescope live_grep (<leader>fg)" \
    "brew install ripgrep" "your package manager: ripgrep"
want go "the Go plugin config in nvim/lua/plugins/go.lua" \
    "brew install go" "your package manager: go"
want gopls "Go LSP — gd, K, rename, code actions" \
    "go install golang.org/x/tools/gopls@latest" \
    "go install golang.org/x/tools/gopls@latest"
want goimports "Go format-on-save via none-ls" \
    "go install golang.org/x/tools/cmd/goimports@latest" \
    "go install golang.org/x/tools/cmd/goimports@latest"
want golangci-lint "Go diagnostics via none-ls" \
    "brew install golangci-lint" "your package manager: golangci-lint"
want pyright-langserver "Python LSP — types, hover, completion" \
    "brew install pyright" "npm install -g pyright"
want ruff "Python lint + format-on-save" \
    "brew install ruff" "your package manager: ruff"

echo
echo "Neovim plugin data:"
vault="$HOME/secondbrain"
if [ -d "$vault" ]; then
    echo "  ✓ $vault (obsidian.nvim workspace)"
else
    echo "  · $vault missing — obsidian.nvim errors on startup without it."
    echo "      mkdir -p ~/secondbrain/daily    (or point it elsewhere in"
    echo "      nvim/lua/plugins/obsidian.lua)"
    missing_optional=$((missing_optional + 1))
fi

echo
case "$PATH" in
    *"$HOME/.local/bin"*) echo "  ✓ ~/.local/bin is on PATH (term-theme is callable)" ;;
    *) echo "  ✗ ~/.local/bin is NOT on PATH — term-theme will not be found."
       echo "      add to your shell rc: export PATH=\"\$HOME/.local/bin:\$PATH\""
       missing_required=$((missing_required + 1)) ;;
esac

echo
if [ "$missing_required" -gt 0 ]; then
    echo "$missing_required required item(s) missing — install those before use."
elif [ "$missing_optional" -gt 0 ]; then
    echo "All required dependencies present. $missing_optional optional item(s) missing."
else
    echo "All dependencies present."
fi
