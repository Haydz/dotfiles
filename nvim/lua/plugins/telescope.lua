return {
  "nvim-telescope/telescope.nvim",
  tag = "0.1.8",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local telescope = require("telescope")

    telescope.setup({
      defaults = {
        layout_strategy = "flex",
        sorting_strategy = "ascending",
        prompt_prefix = "   ",
        selection_caret = " ",
        layout_config = { prompt_position = "top" },
        mappings = {
          i = { ["<C-k>"] = "move_selection_previous", ["<C-j>"] = "move_selection_next" },
        },
      },
    })

    local builtin = require("telescope.builtin")
    vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Find files" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })

    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
  end,
}

