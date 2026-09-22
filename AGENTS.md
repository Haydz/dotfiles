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

## Alacritty colours: run the audit, don't trust the comment

Both themes are generated against measured contrast rather than inherited
from an upstream theme. **`bin/term-contrast` is the source of truth** —
run it after touching any colour:

```bash
./bin/term-contrast          # full table, both themes
./bin/term-contrast --quiet  # failures only, exits non-zero
```

This tool exists because the previous claim here — "both themes keep every
ANSI colour at or above the 7:1 AAA bar" — was false in both themes:

- the light theme's grey carried a comment asserting 7.0:1. That was
  measured against `#ffffff`; against the `#e0e4ec` actually in use it was
  **5.51:1**, and ANSI cyan sat at **3.87:1**, below even AA.
- the dark theme (Catppuccin Mocha) had ANSI black at **1.80:1** —
  invisible — which is the slot ls, git, delta, bat and most prompts use
  for comments. Its `normal` and `bright` were also byte-identical for all
  six hues, so no program could render emphasis.

Two rules follow, and they are why copying values from a theme gallery
does not work here:

1. **Contrast is a property of a pair.** A hex value is not "AAA"; it is
   AAA *against one background*. Change the background and every colour
   needs re-solving. Nothing transfers.
2. **The policy is not "everything at AAA".** A terminal needs a readable
   dim tier — comments that cannot be de-emphasised are their own
   legibility problem — so the dim slots have deliberately lower floors.
   `term-contrast` encodes the per-slot floors; edit them there, in one
   place, rather than arguing with the numbers in a file comment.

Note the two themes move in opposite directions: on the dark theme
`bright` is *lighter* than `normal`, on the light theme it is *darker*,
because on a light ground lighter means less contrast.

Each theme file also carries a ladder of alternative background shades with
measured values in its header comment. If you change a colour, recompute —
don't eyeball it.

## Neovim: two lazy.nvim traps that fail silently

Both of these have already bitten this repo. Neither produces an error.

1. **One plugin, one spec.** lazy merges every spec naming the same plugin
   into a single plugin, and `config` / `opts`-as-a-function are single
   values, not lists — so two files both declaring
   `{ "neovim/nvim-lspconfig", config = ... }` resolve to whichever lazy
   merges last, and the other is discarded. `go.lua` and `python.lua` each
   did this; python won, and **gopls never started** — the Go keymaps just
   did nothing. All language servers now live in one spec in `lsp.lua`, and
   all treesitter parsers in one `ensure_installed` list in
   `treesitter.lua`. Add to those lists; do not add a second spec.

2. **`lua/plugins/init.lua` is the whole import list.** `core/lazy.lua` does
   `import = "plugins"`, and because `lua/plugins/init.lua` exists, *that
   file* is what gets imported — a new `lua/plugins/foo.lua` is **not**
   picked up until it is listed there. `go.lua` and `autopairs.lua` were
   missing from the list.

Also: `nvim-treesitter` is pinned to `branch = "master"` on purpose. Upstream
moved its default branch to `main`, a rewrite with no
`require("nvim-treesitter.configs")` — the API `treesitter.lua` calls. Drop
the pin only together with rewriting that file.

`obsidian.nvim` is gated behind `cond` on `~/secondbrain` existing. Its
`setup()` raises when the vault is absent, and it loads on `VeryLazy`, so
without the gate a machine that has not synced the vault gets an error box
on every startup.

## Verifying changes

```bash
bash -n install.sh bin/term-theme                  # shell syntax
python3 -c "import tomllib,sys; [tomllib.load(open(f,'rb')) for f in sys.argv[1:]]" alacritty/*.toml
./bin/term-contrast --quiet                        # theme contrast floors
tmux -L test new-session -d 'read x'; tmux -L test show -g mouse; tmux -L test kill-server
./install.sh --check                               # every binary the config needs
nvim --headless +qa                                # startup errors (silence = clean)
```

Assert on behaviour, not on the plugin being in the spec — the traps above
all leave the spec looking correct. To check a language server really
attaches:

```bash
nvim --headless /path/to/file.go -c 'lua
  vim.wait(8000, function() return #vim.lsp.get_clients({bufnr=0,name="gopls"})>0 end)
  print(vim.inspect(vim.tbl_map(function(c) return c.name end,
    vim.lsp.get_clients({bufnr=0}))))' -c qa
```

Note that `ruff` registers formatting *dynamically*: its
`server_capabilities.documentFormattingProvider` is nil, and only
`client:supports_method("textDocument/formatting")` reports it, once the
registration lands. Waiting merely for the client to exist before `:w` races
it, so format-on-save looks broken in a scripted test while being fine in use.

To test a config change without disturbing the running terminal, launch a
throwaway instance: `alacritty --config-file <path> -vv`. Add `-vv` to see
config load and reload events, which are silent at the default log level.

**A new window (`Cmd+N`, `CreateNewWindow`) does not re-read the config.**
It is a new window in the *same* process, so it inherits the config already
in memory. Only the file watcher firing, or fully quitting and relaunching
Alacritty, picks up an edit. This bites hardest when judging a font or size
change: the new window looks wrong, the config looks right, and neither is
lying. Quit and relaunch before concluding a visual change did not work.

For font changes specifically, don't eyeball the point size — measure
x-height, which is what perceived size actually tracks. Point sizes are not
comparable across families (Atkynson's x-height is 496/1000 em, JetBrains
Mono's is 550), so a same-number swap silently resizes the terminal. macOS
has no `fc-list`; ask CoreText via `CTFontGetXHeight`, and note it also
reveals whether a family/style pair resolves at all — an unmatched one falls
back to a system font with no error.

## Conventions

- Don't commit or push unless asked.
- Keep unrelated changes in separate commits.
- `*.bak*` and editor/tool logs are gitignored; don't add them.
