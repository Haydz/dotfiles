-- ~/.config/nvim/lua/plugins/init.lua
--
-- Every plugin file in this directory must be listed here. lazy.nvim is
-- pointed at the `plugins` module (see core/lazy.lua), and because this
-- init.lua exists it is what gets imported — a new file dropped in beside it
-- is NOT picked up automatically. go.lua and autopairs.lua were missing from
-- this list for a while and simply never loaded.

return {
  -- Load the theme first to avoid white flash
  { import = "plugins.theme" },

  -- Then the rest
  { import = "plugins.treesitter" },
  { import = "plugins.telescope" },
  { import = "plugins.obsidian" },
  { import = "plugins.lsp" },        -- all language servers (Go, Python)
  { import = "plugins.go" },         -- Go formatting/linting + :Go* commands
  { import = "plugins.cmp" },
  { import = "plugins.autopairs" },
}
