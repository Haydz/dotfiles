-- ~/.config/nvim/lua/plugins/treesitter.lua
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" }, -- load when you open a file
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "lua", "go", "python", "vim", "vimdoc", "query",
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
    })
  end,
}

