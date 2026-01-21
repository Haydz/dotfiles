-----------------------------------------------------------
-- General Neovim Options
-----------------------------------------------------------

-- Leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- UI
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.wrap = false

-- Tabs & indentation
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Searching

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = false

-- Scrolling & split behavior
vim.opt.scrolloff = 8
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Command line completion
vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildoptions = "pum"
vim.opt.pumblend = 10

-- Disable automatic comment continuation
vim.opt.formatoptions:remove({ "c", "r", "o" })

-- Mouse support
vim.opt.mouse = "a"

-- System clipboard integration
vim.opt.clipboard = "unnamedplus"

-- Encoding
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
-- Obsidian UI needs conceallevel >= 1
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.conceallevel = 2        -- 1 or 2 both OK; 2 hides more
    vim.opt_local.concealcursor = "nc"    -- optional: no conceals in insert mode
  end,

})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = "nc"
  end,

})

