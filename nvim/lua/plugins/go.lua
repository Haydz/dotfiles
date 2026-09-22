-- ~/.config/nvim/lua/plugins/go.lua
--
-- Go formatting/linting and the :Go* commands.
--
-- The gopls language server is NOT set up here — it lives in lsp.lua with
-- every other server. Do not re-add a `neovim/nvim-lspconfig` spec to this
-- file: lazy merges same-plugin specs and keeps only one `config`, so a second
-- one here would silently cancel out the Python setup (or be cancelled by it).
-- See the header of lsp.lua.

return {
  ---------------------------------------------------------------------------
  -- Formatting & linting (none-ls / null-ls)
  ---------------------------------------------------------------------------
  {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local null = require("null-ls")
      local sources = {
        null.builtins.formatting.goimports,
        null.builtins.formatting.gofmt,
        -- optional: enable if you installed gofumpt
        -- null.builtins.formatting.gofumpt,
      }

      -- golangci-lint is an optional dependency. Registering the source when
      -- the binary is absent makes none-ls raise on every Go buffer read.
      if vim.fn.executable("golangci-lint") == 1 then
        table.insert(sources, null.builtins.diagnostics.golangci_lint)
      end

      null.setup({ sources = sources })
      -- Format-on-save for *.go is registered in lsp.lua, so that it can pick
      -- deterministically between null-ls and gopls.
    end,
  },

  ---------------------------------------------------------------------------
  -- Build / Run / Test commands
  ---------------------------------------------------------------------------
  {
    "nvim-lua/plenary.nvim",
    lazy = true,
    init = function()
      vim.api.nvim_create_user_command("GoBuild", function() vim.cmd("!go build ./...") end, {})
      vim.api.nvim_create_user_command("GoRun", function()
        local target = (vim.fn.filereadable("main.go") == 1) and "main.go" or "%"
        vim.cmd("!go run " .. target)
      end, {})
      vim.api.nvim_create_user_command("GoTest", function() vim.cmd("!go test ./...") end, {})

      -- Buffer-local would be wrong here: these are :commands, not LSP
      -- features, and they should work from a Go project's quickfix or
      -- terminal buffer too.
      local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { desc = desc }) end
      map("<leader>gb", ":GoBuild<CR>", "Go: build ./...")
      map("<leader>gr", ":GoRun<CR>", "Go: run main.go (or current file)")
      map("<leader>gt", ":GoTest<CR>", "Go: test ./...")
    end,
  },
}
