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

`install.sh` links **every** file in `bin/` into `~/.local/bin`, so anything
dropped there becomes a user-facing command — not a scratch directory.
Current contents:

| Script | | |
|---|---|---|
| `term-theme` | bash | flips Alacritty light/dark |
| `term-contrast` | python **3.11+** (needs `tomllib`) | audits theme contrast |

`term-contrast` exits with a clear message on older Python rather than
traceback, and `install.sh --check` does *not* test for 3.11 — if these
dotfiles land somewhere with an older interpreter, that check is the gap.

`alacritty/themes/` is a vendored copy of the alacritty-theme collection,
tracked as plain files (not a submodule). `theme-light.toml` and
`theme-dark.toml` are standalone — they do **not** import from `themes/`,
and neither is an upstream theme any more: the dark one is generated, the
light one started from GitHub Light High Contrast and was re-solved.

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

Note the scope of point 1: it is about a file that **did not exist at
startup**. A `theme-*.toml` that *was* present when Alacritty launched is in
the watch list and live-reloads on edit like any other config file. Verified
with `-vv` — `touch alacritty/theme-dark.toml` logs a reload immediately:

```
Configuration files loaded from:
  "~/.config/alacritty/alacritty.toml"
  "~/.config/alacritty/theme-dark.toml"      <- imports are watched too
[5.003s] Reloading configuration file: ".../alacritty/alacritty.toml"
```

This corrects an earlier claim here that editing `theme-*.toml` required
toggling twice or restarting. It does not. See "Lessons learned" — that
claim was asserted rather than measured, and was wrong for the same reason
the contrast claim below was.

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
python3 -m py_compile bin/term-contrast            # python syntax
python3 -c "import tomllib,sys; [tomllib.load(open(f,'rb')) for f in sys.argv[1:]]" alacritty/*.toml
./bin/term-contrast --quiet                        # theme contrast floors
./bin/term-theme status >/dev/null; echo "exit=$?" # must be 0, see bin/ notes
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

## Shell scripts in `bin/`: the last command sets the exit status

These scripts run `set -euo pipefail`, which means **the script's exit
status is whatever the last command returned** — including a trailing
best-effort step that nobody intended to be load-bearing.

`term-theme` ended with an optional tmux notification. With no tmux server
running, `tmux list-clients` exits 1; `pipefail` promoted that to the
pipeline's status, and being last, it became the script's status. So
`term-theme light` wrote the config correctly, printed success, and exited
**1** — breaking `term-theme light && ...` for anything scripted. The
keybinding path hid it completely, because Alacritty discards the output.

Two rules:

- End these scripts with an explicit `exit 0` after the real work, so no
  notification or cleanup added later can decide the status.
- Put `|| true` on best-effort pipelines, not just on the commands inside
  them. `cmd 2>/dev/null | while ...; do x || true; done` still fails when
  `cmd` fails — the `|| true` has to be on the pipeline.

Check exit codes, not just output, when testing a `bin/` script:

```bash
./bin/term-theme light; echo "exit=$?"   # a working switch must be 0
```

## Lessons learned

Recorded because each of these cost real time here, and none announced
itself as an error.

1. **A claim in a comment is not a verification.** Two assertions in this
   file were simply false: that both themes cleared 7:1 (ANSI black was at
   1.80:1, light cyan at 3.87:1) and that editing `theme-*.toml` needed a
   double toggle (imports are watched; it reloads). Both read as settled
   fact. If an invariant matters, encode it in something runnable and list
   it under "Verifying changes" — that is what `bin/term-contrast` is for.
2. **Contrast and font size are properties of a relationship, not of a
   value.** A hex is only AAA *against one background*; a point size only
   looks right *for one font's x-height*. The light theme's grey really was
   7.0:1 — against `#ffffff`, which had stopped being the background.
   Nothing copied from an upstream theme or another font transfers.
3. **Reputation is not measurement.** Atkinson Hyperlegible is a
   legibility typeface, and its x-height is *smaller* than JetBrains
   Mono's (496 vs 550 per em). Swapping families at the same point size
   made the terminal smaller while "improving legibility".
4. **Ask the renderer, not the file.** An OS/2 table, CoreText, and
   Alacritty can disagree. CoreText is what actually resolves a
   family/style pair, and an unmatched one falls back to a system font
   silently. `alacritty --config-file X -vv` is what proves a font loaded.
5. **Confirm the process re-read the config before judging a visual
   change.** A new window is not a reload (see "Verifying changes"). A
   change that looks like it did nothing is usually being viewed through a
   stale process.
6. **Fix the target, not just the arithmetic.** The first font attempt was
   measured correctly and still wrong, because it aimed to *preserve* the
   old apparent size when the request was to increase it. Correct maths
   against the wrong goal still fails.

## Conventions

- Don't commit or push unless asked.
- Keep unrelated changes in separate commits.
- `*.bak*` and editor/tool logs are gitignored; don't add them.
