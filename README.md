# Dotfiles

My personal configuration files for Neovim and Alacritty.

Works on macOS and Linux — no absolute platform paths in any config.

## Contents

- `nvim/` - Neovim configuration
- `alacritty/` - Alacritty terminal configuration
- `tmux/` - tmux configuration (mouse scrolling enabled)
- `bin/` - scripts, symlinked into `~/.local/bin`

## Installation

### Quick Install

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` symlinks the config, then checks for every binary the config
needs and prints the install command for anything missing. Linking is
idempotent — re-running leaves existing correct links alone rather than
piling up backups. Anything else in the way is moved to
`<path>.backup.<timestamp>` first.

To check dependencies without changing anything:

```bash
./install.sh --check
```

### Manual Installation

If you prefer to do it manually:

```bash
mkdir -p ~/.config ~/.local/bin
ln -s ~/dotfiles/nvim ~/.config/nvim
ln -s ~/dotfiles/alacritty ~/.config/alacritty
ln -s ~/dotfiles/tmux ~/.config/tmux
ln -s ~/dotfiles/bin/term-theme ~/.local/bin/term-theme
```

## Terminal theme

Alacritty is tuned for readability: JetBrains Mono Medium, and light/dark
themes whose colours all clear the WCAG AAA 7:1 contrast bar.

Switch between them with `term-theme`, or with a keybinding:

| | |
|---|---|
| `term-theme` | toggle |
| `term-theme light` | white-ish bg, matches a bright browser beside the terminal |
| `term-theme dark` | Catppuccin Mocha |
| `term-theme status` | print current mode |
| `Cmd+Shift+T` / `Ctrl+Shift+T` | toggle (macOS / Linux) |

Both themes carry a documented ladder of background shades in their header
comments, with measured contrast values, if you want to tune brightness.

Note: after editing `theme-light.toml` or `theme-dark.toml` directly, toggle
twice to apply. Alacritty builds its config file-watch list at startup, so
imports are only live-reloaded once they existed when Alacritty launched.

## Requirements

`./install.sh --check` reports all of this for the machine you're on, with
the install command for anything missing.

Required:

- Neovim 0.10+ — the config uses `vim.fs.root`, `vim.snippet` and `vim.uv`
- Alacritty 0.13+ (TOML config)
- tmux 3.1+ (for the `~/.config/tmux/` path)
- A C compiler — nvim-treesitter compiles parsers on install
- AtkynsonMono Nerd Font
- Lazy.nvim (auto-installed by the Neovim config)

Optional — Neovim starts fine without these, the matching feature is just
inert:

| Tool | Enables |
|---|---|
| `ripgrep` | telescope `live_grep` (`<leader>fg`) |
| `gopls` | Go LSP: `gd`, `K`, rename, code actions |
| `goimports` | Go format-on-save |
| `golangci-lint` | Go diagnostics |
| `pyright` | Python types, hover, completion |
| `ruff` | Python lint + format-on-save |
| `~/secondbrain` | obsidian.nvim; the plugin stays off until it exists |

### Fonts

`alacritty.toml` names **`AtkynsonMono Nerd Font`**. Mind the three
different spellings of the same thing — they are not typos:

| | |
|---|---|
| Homebrew cask | `font-atkynson-mono-nerd-font` |
| Nerd Fonts release asset | `AtkinsonHyperlegibleMono.zip` (**i**, not **y**) |
| Family Alacritty matches on | `AtkynsonMono Nerd Font` (**y**, with a space) |

```bash
# macOS
brew install --cask font-atkynson-mono-nerd-font

# Linux — no distro package in any repo (not Arch, not Debian), and the
# release asset is spelled differently from the family it installs.
mkdir -p ~/.local/share/fonts && cd ~/.local/share/fonts
curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/AtkinsonHyperlegibleMono.zip
unzip -o AtkinsonHyperlegibleMono.zip && rm AtkinsonHyperlegibleMono.zip && fc-cache -f
```

Confirm it actually resolved, rather than trusting that it installed —
a family Alacritty cannot match falls back to a system font *silently*:

```bash
fc-list : family | grep -i atkynson          # Linux
./install.sh --check | grep -i atkynson      # either platform
```

Previous font, still a good choice and the one to fall back to if you want
narrower columns — swap the `family` on all four lines in
`alacritty/alacritty.toml`. Note the size does **not** carry over: match
x-height, not point size, so the equivalent of Atkynson at `20.0` is
JetBrains Mono at `18.0` (see the ladder in that file):

```bash
brew install --cask font-jetbrains-mono-nerd-font   # macOS
sudo pacman -S ttf-jetbrains-mono-nerd              # Arch
```
