return {
  -- Load the theme first to avoid white flash
  { import = "plugins.theme" },


  -- Then the rest of your plugins
  { import = "plugins.treesitter" },
  { import = "plugins.telescope" },
  { import = "plugins.obsidian" },
}

