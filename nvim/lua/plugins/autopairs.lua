-- ~/.config/nvim/lua/plugins/autopairs.lua

return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = function()
    require("nvim-autopairs").setup({
      check_ts = true,             -- treesitter-aware pairs
      enable_moveright = true,     -- 👈 typing } or ) moves over the same char on the right
      enable_check_bracket_line = true, -- avoid adding a second closer if one is already ahead
      disable_filetype = { "TelescopePrompt", "vim" },
      fast_wrap = {},              -- optional: <A-e> to wrap selected text quickly

      -- You can tweak this if movers fire in places you don't want:
      -- ignored_next_char = "[%w%.]" -- default: don’t auto-close before word/number/dot
    })

    -- OPTIONAL: integrate with nvim-cmp so confirming a completion inserts () and places cursor inside
    local ok_cmp, cmp = pcall(require, "cmp")
    if ok_cmp then
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end
  end,
}

