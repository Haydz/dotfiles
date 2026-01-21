-- ~/.config/nvim/lua/plugins/obsidian.lua
return {
  "obsidian-nvim/obsidian.nvim",

  version = "*",

  -- Make commands like :Obsidian new work from anywhere (even in [No Name])
  cmd = { "Obsidian" },
  -- Also lazy-load shortly after startup so keymaps feel instant
  event = "VeryLazy",

  dependencies = {

    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
    "nvim-telescope/telescope.nvim",
  },

  opts = {
    workspaces = {
      { name = "secondbrain", path = "~/secondbrain" },
    },


    -- Daily notes live in: ~/secondbrain/daily/YYYY-MM-DD.md
    daily_notes = {
      folder = "daily",
      date_format = "%Y-%m-%d",
    },


    -- Use the new (space-separated) commands; silence legacy warnings
    legacy_commands = false,

    -- Completions for [[links]] and #tags via nvim-cmp
    completion = { nvim_cmp = true },

    -- Nice UI for Markdown (requires conceallevel >= 1; set below)
    ui = { enable = true },
  },

  -- Minimal, consistent keymaps
  keys = {
    { "<leader>on", "<cmd>Obsidian new<CR>",       desc = "Obsidian: New note" },
    { "<leader>os", "<cmd>Obsidian search<CR>",    desc = "Obsidian: Search notes" },
    { "<leader>ot", "<cmd>Obsidian today<CR>",     desc = "Obsidian: Today's note" },
    { "<leader>ob", "<cmd>Obsidian backlinks<CR>", desc = "Obsidian: Backlinks" },
    -- Works in NORMAL and VISUAL mode (highlight text → Space o l)
    { "<leader>ol", "<cmd>Obsidian link<CR>",      mode = { "n", "v" }, desc = "Obsidian: Link selection" },
  },

  config = function(_, opts)

    require("obsidian").setup(opts)

    -- Ensure Obsidian's extra syntax looks right in Markdown buffers only
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        -- conceallevel 1 or 2 is required for pretty wiki-links, checkboxes, etc.
        vim.opt_local.conceallevel = 2
        vim.opt_local.concealcursor = "nc"
      end,
    })
  end,
}

