return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,      -- load before everything else
  lazy = false,         -- start immediately to avoid white flash
  opts = {
    transparent_background = false,
    flavour = "mocha",  -- latte | frappe | macchiato | mocha

    integrations = {

      treesitter = true,
      telescope = { enabled = true },
      which_key = true,

      gitsigns = true,
      markdown = true,
      cmp = true,
      native_lsp = { enabled = true },
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}

