# AGENTS.md

Guidance for AI agents working in this repo.

## What this is

Personal dotfiles for Neovim, Alacritty, tmux and zsh. Config is symlinked
into place by `install.sh` — the repo is the source of truth, and
`~/.config/nvim`, `~/.config/alacritty`, `~/.config/tmux`, `~/.zshrc`,
`~/.zprofile` and `~/.zshenv` are symlinks to files here. Editing either
path touches the same file.

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
| `zsh/zshenv` | `~/.zshenv` | **every** zsh, including `zsh -c` |
| `zsh/zprofile` | `~/.zprofile` | login shell; sets `HOMEBREW_PREFIX` |
| `zsh/zshrc` | `~/.zshrc` | interactive shell |
| `bin/` | each file into `~/.local/bin` | already on `PATH` |

The three zsh files land in `$HOME`, not `$XDG_CONFIG_HOME`, because zsh
only looks at `$ZDOTDIR` — and setting that before login needs
`/etc/zshenv`, which is outside this repo.

`install.sh` links **every** file in `bin/` into `~/.local/bin`, so anything
dropped there becomes a user-facing command — not a scratch directory.
Current contents:

| Script | | |
|---|---|---|
| `term-theme` | bash | flips Alacritty light/dark |
| `term-contrast` | python **3.11+** (needs `tomllib`) | audits theme contrast |

`term-contrast` exits with a clear message on older Python rather than a
traceback, and `install.sh --check` covers it as an *optional* dep — the
terminal and editor do not depend on it, only the contrast audit does.

That check tests the capability (`python3 -c 'import tomllib'`), not a
version string, for two reasons worth preserving: `python3 --version`
output carries distro suffixes that break parsing (`3.11.2+`,
`3.9.6 (default, ...)`), and a `python3.12` binary is often installed while
`python3` still resolves to something older — the exact case a version
check is supposed to catch. When `python3` is too old it also looks for a
newer versioned binary already on `PATH` and names it, since that is
usually cheaper than installing anything.

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

## zsh: six things that fail quietly

`zsh/zshrc` is builtins only — no framework, no plugin manager, no prompt
binary — and that is a constraint to preserve, not an accident. These are
also the files most likely to break in a way you only notice three sessions
later, because nothing in a shell startup reports an error you can't see.

1. **`${VAR:+...}` ends at the first `}`, and `%F{yellow}` supplies one.**
   `PROMPT='${SSH_CONNECTION:+%F{yellow}%n@%m%f }...'` does not do what it
   reads as: the conditional closes after `yellow`, and `%n@%m%f }` falls
   outside it, so every local prompt printed `user@host` and a stray ` }`.
   Build anything containing a colour escape *outside* the prompt string —
   it is static per session anyway.

2. **The last line of `zshrc` sets `$?` for the first prompt.** The file
   ends with `[[ -r ~/.zshrc.local ]] && source ...`, which fails on any
   machine without that file. The prompt then drew its red `1 ❯` failure
   marker on a brand-new shell, and `zsh -ic exit` returned 1. Hence the
   bare `true` at the bottom. Same trap as `bin/term-theme` below — check
   `zsh -ic exit; echo $?` after touching the end of that file.

3. **`local x=$(cmd)` discards `cmd`'s exit status** — the status is
   `local`'s, which is always 0. `+vi-git-ahead-behind` declares and
   assigns on separate lines for exactly this reason; collapse them and the
   no-upstream case stops returning early and reads a garbage count.

4. **`compinit -C` trusts a dump up to 24 hours stale.** That is what keeps
   startup near 50 ms with Homebrew's ~100 completion files on `fpath`, and
   the cost is that a completion installed today may not appear until
   tomorrow. Before concluding a tool ships no completion:
   `rm -f ~/.cache/zsh/zcompdump-* && exec zsh -l`.

5. **`extended_glob` is why `no_nomatch` is set.** `extended_glob` makes
   `^` a pattern character, and zsh's default aborts a command whose glob
   matched nothing — so `git show HEAD^` fails with "no matches found"
   before git runs at all, as does any unquoted URL with a `?`. The two
   options are a pair; dropping `no_nomatch` breaks ordinary git usage.

6. **`zshrc` is not read by `zsh -c`.** Which of the three files a setting
   goes in is a correctness question, not tidiness. `zshenv` is read by
   every zsh, `zprofile` only by login shells, `zshrc` only by interactive
   ones — so an environment variable that a git hook, a script, an editor
   or an agent depends on is *inert* in `zshrc`, while still looking
   correct in your own terminal. That is why `GITSIGN_REKOR_MODE` and
   `GITSIGN_CREDENTIAL_CACHE` are in `zshenv`: git never invokes gitsign
   from an interactive shell, so in `zshrc` every scripted commit would
   silently sign in online mode with no credential cache. The flip side:
   `zshenv` runs on every `zsh -c`, so it must stay free of command
   lookups and subshells.

The prompt uses ANSI slot names (`%F{magenta}`), never hex, so it follows
`term-theme` light/dark — the same palette `bin/term-contrast` holds to a
contrast floor. A hex colour here would look correct in one theme and
disappear in the other. This is the contrast rule above applied to the
shell: the prompt's legibility is a property of the pair, so let the
terminal supply one half of it.

Costs worth knowing before adding to the prompt: `check-for-changes` stats
the whole worktree on every prompt, and the untracked hook uses
`git ls-files --error-unmatch`, which exits as soon as one untracked path
exists, rather than `git status | grep '??'`, which formats the entire
status first. `git rev-list --count` for ahead/behind only walks commit
objects, so it is cheap. The escape hatch for a huge repo is
`zstyle ':vcs_info:*' disable-patterns`, not turning the indicator off.

## Verifying changes

```bash
bash -n install.sh bin/term-theme                  # shell syntax
zsh -n zsh/zshrc zsh/zprofile zsh/zshenv           # zsh syntax
python3 -m py_compile bin/term-contrast            # python syntax
python3 -c "import tomllib,sys; [tomllib.load(open(f,'rb')) for f in sys.argv[1:]]" alacritty/*.toml
./bin/term-contrast --quiet                        # theme contrast floors
./bin/term-theme status >/dev/null; echo "exit=$?" # must be 0, see bin/ notes
tmux -L test new-session -d 'read x'; tmux -L test show -g mouse; tmux -L test kill-server
./install.sh --check                               # every binary the config needs
nvim --headless +qa                                # startup errors (silence = clean)
```

A zsh change has to be tested in a *real* interactive startup, in a
throwaway `$ZDOTDIR` so a broken file cannot lock you out of your own
shell. `zsh -n` only parses; most of what breaks here is runtime:

```bash
T=$(mktemp -d); for f in zshrc zprofile zshenv; do cp "zsh/$f" "$T/.$f"; done
ZDOTDIR="$T" zsh -lic exit; echo "exit=$?"     # must be 0, and print nothing
for i in 1 2 3; do /usr/bin/time -p env ZDOTDIR="$T" zsh -lic exit; done 2>&1 |
    awk '/real/{print $2"s"}'                  # ~0.05s; a regression is obvious
```

The prompt itself needs a pty — `print -P $PROMPT` will not show you what a
real session draws, and neither will a non-interactive shell:

```bash
printf 'false\nexit\n' | ZDOTDIR="$T" script -q /dev/null zsh -li |
    sed 's/\x1b\[[0-9;]*m/|/g' | cat -v       # `|` marks each colour change
```

Read that output for what should *not* be there as much as what should: the
`${VAR:+...}` bug above showed up as a `user@host` and a stray ` }` on a
local shell, and neither is an error.

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
6. **Some bugs only exist in a pty.** Both zsh prompt bugs above —
   `user@host` on a local shell, and a red `1 ❯` on a brand-new one — were
   invisible to `zsh -n` and to `print -P`, and appeared on the first
   `script -q /dev/null zsh -li` run. A config that loads without
   complaint has not been tested; drive the thing the way a person does.
7. **Fix the target, not just the arithmetic.** The first font attempt was
   measured correctly and still wrong, because it aimed to *preserve* the
   old apparent size when the request was to increase it. Correct maths
   against the wrong goal still fails.

## Conventions

- Don't commit or push unless asked.
- Keep unrelated changes in separate commits.
- `*.bak*` and editor/tool logs are gitignored; don't add them.
