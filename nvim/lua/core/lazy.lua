-----------------------------------------------------------
-- Bootstrap and Setup lazy.nvim
-----------------------------------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Bootstrap lazy.nvim if not installed

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  print("Installing lazy.nvim...")
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end

vim.opt.rtp:prepend(lazypath)

-- Load plugins (ordered via lua/plugins/init.lua)
require("lazy").setup({
  spec = { import = "plugins" },  -- this uses lua/plugins/init.lua
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = true },
  change_detection = { notify = false },
})

