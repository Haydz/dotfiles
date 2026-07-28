# AGENTS.md

Guidance for AI agents working in this repo.

## What this is

Personal dotfiles for Neovim, Alacritty and tmux. Config is symlinked into
place by `install.sh` — the repo is the source of truth, and `~/.config/nvim`,
`~/.config/alacritty` and `~/.config/tmux` are symlinks to directories here.
Editing either path touches the same file.

## The one hard constraint: macOS *and* Linux

This repo is checked out on both. **No absolute platform paths in config
files.** Before adding anything, grep it:

```bash
grep -rnE "/Users/|/home/|/opt/homebrew|/Applications" --include="*.toml" --include="*.conf" .
```

Platform-specific binary locations belong in ordered fallback lists inside
scripts, never in config files.

Patterns already used here, reuse them rather than reinventing:

- **Alacritty does not expand `~`, `$HOME` or `$PATH`** in the `program` field
  of `shell` or of a keybinding `command`. Go through `/bin/sh`, which exists
  on both platforms:
  `program = "/bin/sh", args = ["-c", "exec \"$HOME/.local/bin/foo\""]`
- **Alacritty aliases `Command` to Super/Meta**, so a `Command` binding becomes
  a Super binding on Linux, where window managers usually grab it. Define both
  `Command|Shift` and `Control|Shift`. They are different combos, so only one
  can match a press — never bind the *same* combo twice to a toggle, or it
  fires twice and appears to do nothing.
- **The shell is `$SHELL`, resolved at runtime**, not a hardcoded path.

## Layout

| Path | Symlinked to | Notes |
|---|---|---|
| `nvim/` | `~/.config/nvim` | lazy.nvim |
| `alacritty/` | `~/.config/alacritty` | see below |
| `tmux/` | `~/.config/tmux` | needs tmux 3.1+ for this path |
| `bin/` | each file into `~/.local/bin` | already on `PATH` |

`alacritty/themes/` is a vendored copy of the alacritty-theme collection,
tracked as plain files (not a submodule). `theme-light.toml` and
`theme-dark.toml` are standalone — they do **not** import from `themes/`.

## Alacritty theming

`alacritty.toml` imports either `theme-light.toml` or `theme-dark.toml`.
`bin/term-theme` switches which, by rewriting the filename on the `import`
line in place. Three non-obvious reasons it works the way it does:

1. **It edits `alacritty.toml`, not a separate `theme-active.toml`.** Alacritty
   builds its config file-watch list at startup. A file created later is never
   watched, so writing to it changes nothing until Alacritty restarts.
   `alacritty.toml` is always watched.
2. **It truncates and rewrites (`cat tmp > file`) rather than `mv`-ing** a temp
   file into place, preserving the inode so the watcher keeps tracking it.
3. **The `sed` skips comment lines.** The docs above the import line name both
   theme files; a global substitution corrupts them, and then reading the mode
   back returns documentation instead of configuration.

Corollary for anyone editing `theme-*.toml` directly: the change will not
appear until you toggle twice, or restart Alacritty.

Colours are chosen against measured WCAG contrast, and both themes keep every
ANSI colour at or above the 7:1 AAA bar. Each theme file carries a ladder of
alternative background shades with measured values in its header comment.
If you change a colour, recompute — don't eyeball it.

## Verifying changes

```bash
bash -n install.sh bin/term-theme                  # shell syntax
python3 -c "import tomllib,sys; [tomllib.load(open(f,'rb')) for f in sys.argv[1:]]" alacritty/*.toml
tmux -L test new-session -d 'read x'; tmux -L test show -g mouse; tmux -L test kill-server
```

To test a config change without disturbing the running terminal, launch a
throwaway instance: `alacritty --config-file <path> -vv`. Add `-vv` to see
config load and reload events, which are silent at the default log level.

## Conventions

- Don't commit or push unless asked.
- Keep unrelated changes in separate commits.
- `*.bak*` and editor/tool logs are gitignored; don't add them.
