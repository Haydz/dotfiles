-- ~/.config/nvim/lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  -- Pin to master explicitly. Upstream moved its default branch to `main`,
  -- which is a rewrite that drops `require("nvim-treesitter.configs")` — the
  -- API this file uses. Without this pin lazy follows the default branch and
  -- the setup() call below fails on the next update. Rewrite for `main` before
  -- removing it.
  branch = "master",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" }, -- load when you open a file

  -- Every parser is listed here, in one place. Per-language files used to
  -- append to this list with `opts = function(_, opts) ... end`, but two of
  -- them did it at once and lazy keeps only the last `opts` function for a
  -- given plugin — so gomod and gowork were silently never installed. Add
  -- parsers to this list rather than extending the spec from elsewhere.
  opts = {
    ensure_installed = {
      "lua", "go", "gomod", "gowork", "python", "vim", "vimdoc", "query",
      "markdown", "markdown_inline", "bash", "json", "yaml", "toml",
      "hcl",
    },
    highlight = {
      enable = true,
      -- Enable regex fallback for markdown so code blocks get highlighted
      -- even if Tree-sitter fails for nested languages
      additional_vim_regex_highlighting = { "markdown" },
    },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "gnn",
        node_incremental = "grn",
        scope_incremental = "grc",
        node_decremental = "grm",
      },
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}

