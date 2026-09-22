-- ~/.config/nvim/lua/plugins/obsidian.lua

-- The vault is personal data, not something this repo can install. On a
-- machine where it has not been synced yet, obsidian.nvim's setup() raises
-- "At least one workspace is required!" — and because this plugin loads on
-- VeryLazy, that error box appears on *every* startup, on a machine whose
-- owner may not even use Obsidian. Gate the whole plugin on the directory
-- existing so a fresh checkout is quiet; it activates once the vault is there.
local VAULT = vim.fn.expand("~/secondbrain")

return {
  "obsidian-nvim/obsidian.nvim",

  version = "*",

  cond = function()
    return vim.fn.isdirectory(VAULT) == 1
  end,

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
      { name = "secondbrain", path = VAULT },
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

