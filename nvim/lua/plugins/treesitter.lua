-- ~/.config/nvim/lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" }, -- load when you open a file
  opts = {
    ensure_installed = {
      "lua", "go", "python", "vim", "vimdoc", "query",
      "markdown", "markdown_inline", "bash", "json", "yaml", "toml",
    },
    highlight = { enable = true },

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

