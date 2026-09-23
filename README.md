# Dotfiles

My personal configuration files for Neovim, Alacritty and zsh.

Works on macOS and Linux — no absolute platform paths in any config.

## Contents

- `nvim/` - Neovim configuration
- `alacritty/` - Alacritty terminal configuration
- `tmux/` - tmux configuration (mouse scrolling enabled)
- `zsh/` - shell configuration, symlinked to `~/.zshrc`, `~/.zprofile` and `~/.zshenv`
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
ln -s ~/dotfiles/zsh/zshrc ~/.zshrc
ln -s ~/dotfiles/zsh/zprofile ~/.zprofile
ln -s ~/dotfiles/zsh/zshenv ~/.zshenv
```

## Shell

`zsh/zshrc` uses zsh builtins only — no framework, no plugin manager, no
prompt binary — so a fresh clone works immediately on any machine that has
zsh. Startup is around 50 ms.

The prompt puts context on one line and your cursor on the next, so a deep
path or a long branch name never costs you typing room:

```
~/code/dotfiles  fix-nvim-lsp-and-installer ✚ ⇡2
❯
```

| | |
|---|---|
| `✚` | tracked files modified |
| `●` | changes staged |
| `?` | untracked files present |
| `⇡2` `⇣1` | commits ahead of / behind upstream |
| `(rebase-i)` | mid rebase, merge or cherry-pick |
| `42 ❯` in red | the last command exited non-zero |

Its colours are ANSI slot names, not hex, so it re-colours itself when
`term-theme` flips light/dark.

What else is set up:

| | |
|---|---|
| Up / Down | search history for what you have already typed |
| Tab | menu completion, case-insensitive, coloured like `ls` |
| `^X^E` | edit the current command line in `$EDITOR` |
| Alt-Backspace | delete one path segment |
| `..` , `../..` | `cd` without typing `cd`; `cd -2` walks the stack |
| `g` `gs` `gd` `gl` `gb` `gp` `gco` | short git aliases; `ll` `la` `v` `reload` |

Machine-specific settings — work tokens, one-off PATH entries — go in
`~/.zshrc.local` (or `~/.zprofile.local`), which are sourced last and are
not in this repo.

In a very large repository the per-prompt worktree scan behind `✚` gets
slow. Exclude those repos by path rather than dropping the indicator
everywhere:

```zsh
zstyle ':vcs_info:*' disable-patterns "$HOME/some/huge/repo(|/*)"
```

Completions installed today may not be offered until tomorrow — `compinit`
does its full `fpath` rescan at most once a day, which is what keeps
startup fast. To pick one up now:

```bash
rm -f ~/.cache/zsh/zcompdump-* && exec zsh -l
```

## Commit signing

Chainguard repos need every commit both **signed** (gitsign, keyless via
Sigstore) and **signed off** (a `Signed-off-by` trailer). Two aliases in
`zsh/zshrc` cover the second half:

```zsh
gcm "message"   # git commit -s -m  — signed off
gca             # git commit --amend --no-edit -s  — fix a missed signoff
```

`-s` is in the alias because there is no config for it. `commit.signoff` is
**not** a real git option — set it and git silently ignores it. The
alternative, a global `core.hooksPath` pointing at a `prepare-commit-msg`
hook, would apply everywhere but also disable each repo's own `.git/hooks`,
which the repos that require the signoff tend to rely on.

Signing itself lives in `~/.gitconfig`, which this repo does not manage (it
holds an email address and is per-machine):

```bash
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global gpg.format x509
git config --global gpg.x509.program "$(command -v gitsign)"
git config --global gitsign.connectorID https://accounts.google.com
```

`zsh/zshenv` supplies the two settings that have no git-config equivalent,
`GITSIGN_REKOR_MODE=offline` and `GITSIGN_CREDENTIAL_CACHE`. They are in
`zshenv` rather than `zshrc` on purpose: `zshrc` is skipped for
non-interactive shells, and git never invokes gitsign from an interactive
one, so putting them in `zshrc` means commits from hooks, scripts and editors
silently sign in online mode with no cache.

The cache needs a daemon holding its socket open; without it you get a
browser auth per commit, which makes `git rebase` painful. `install.sh
--check` reports whether it is running. On macOS, as a LaunchAgent at
`~/Library/LaunchAgents/dev.sigstore.gitsign-credential-cache.plist`:

```xml
<key>ProgramArguments</key>
<array><string>/opt/homebrew/bin/gitsign-credential-cache</string></array>
<key>RunAtLoad</key><true/>
<key>KeepAlive</key><true/>
```

```bash
launchctl load -w ~/Library/LaunchAgents/dev.sigstore.gitsign-credential-cache.plist
```

On Linux, `systemctl --user start gitsign-credential-cache.socket`.

To verify the whole chain end to end — all three lines must say `true`:

```bash
gitsign verify --certificate-identity=you@chainguard.dev \
  --certificate-oidc-issuer=https://accounts.google.com HEAD
```

GitHub will still show these commits as "Unverified". That is expected: the
Sigstore CA is not in GitHub's trust root, and gitsign's ephemeral certs need
Rekor to validate they were live at signing time.

## Terminal theme

Alacritty is tuned for readability: Atkinson Hyperlegible Mono Medium — the
Braille Institute's low-vision typeface — and light/dark themes whose colours
are generated against measured contrast rather than borrowed from a theme
gallery. All body text clears the WCAG AAA 7:1 bar; the dim tier has its own
lower floors on purpose, since a comment colour you can't de-emphasise is
its own readability problem.

Switch between them with `term-theme`, or with a keybinding:

| | |
|---|---|
| `term-theme` | toggle |
| `term-theme light` | white-ish bg, matches a bright browser beside the terminal |
| `term-theme dark` | dark neutral, generated palette |
| `term-theme status` | print current mode |
| `Cmd+Shift+T` / `Ctrl+Shift+T` | toggle (macOS / Linux) |

Both themes carry a documented ladder of background shades in their header
comments, with measured contrast values, if you want to tune brightness.
If you change a colour, re-run the audit rather than trusting the comment:

```bash
term-contrast            # full table for both themes
term-contrast --quiet    # failures only; exits non-zero
```

Changing the background means re-solving every colour against it — contrast
is a property of a *pair*, so no hex value is portable between backgrounds.

Editing `theme-light.toml` or `theme-dark.toml` directly applies straight
away — they are imported, and Alacritty watches imported files as well as
`alacritty.toml`. The startup caveat only affects a theme file that did
*not* exist when Alacritty launched: it never enters the watch list, so it
stays inert until a restart.

What genuinely does not pick up a change is a **new window** (`Cmd+N`) —
that shares the running process's in-memory config. Quit and relaunch when
a font or colour change looks like it did nothing.

## Requirements

`./install.sh --check` reports all of this for the machine you're on, with
the install command for anything missing.

Required:

- Neovim 0.10+ — the config uses `vim.fs.root`, `vim.snippet` and `vim.uv`
- Alacritty 0.13+ (TOML config)
- tmux 3.1+ (for the `~/.config/tmux/` path)
- zsh 5.8+ — and it has to be your *login* shell, or `~/.zshrc` is never
  read. `install.sh --check` says which shell you are actually on.
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
