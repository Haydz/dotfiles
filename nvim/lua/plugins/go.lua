-- ~/.config/nvim/lua/plugins/go.lua
return {
  ---------------------------------------------------------------------------
  -- 1) Go LSP setup (pure Neovim 0.11 API; no deprecated framework)
  ---------------------------------------------------------------------------
  {
    -- You can keep lspconfig installed (other servers may use it), but we don't call it here
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()

      -- Build a plain config table for gopls
      local function make_gopls_config(bufnr)
        -- find project root from current buffer
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local root = vim.fs.root(fname ~= "" and fname or 0, { "go.work", "go.mod", ".git" })
        return {
          name = "gopls",
          cmd = { "gopls" },

          root_dir = root,
          filetypes = { "go", "gomod", "gowork", "gotmpl" },
          settings = {
            gopls = {
              analyses = { unusedparams = true },

              staticcheck = true,
            },
          },
        }
      end

      -- Start (or attach) gopls when entering any Go-related buffer
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "go", "gomod", "gowork", "gotmpl" },
        callback = function(args)
          local bufnr = args.buf
          -- Avoid starting multiple clients for this buffer
          local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "gopls" })
          if #clients == 0 then
            vim.lsp.start(make_gopls_config(bufnr))
          end
        end,
      })

      -- === LSP keymaps ===
      local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { desc = desc }) end
      map("gd", vim.lsp.buf.definition,               "Go: definition")
      map("K",  vim.lsp.buf.hover,                    "Go: hover docs")
      map("<leader>rn", vim.lsp.buf.rename,           "Go: rename symbol")
      map("<leader>ca", vim.lsp.buf.code_action,      "Go: code action")
      map("<leader>f",  function() vim.lsp.buf.format({ async = true }) end, "Go: format buffer")

      -- === Build / Run / Test commands ===
      vim.api.nvim_create_user_command("GoBuild", function() vim.cmd("!go build ./...") end, {})
      vim.api.nvim_create_user_command("GoRun", function()
        local target = (vim.fn.filereadable("main.go") == 1) and "main.go" or "%"
        vim.cmd("!go run " .. target)
      end, {})
      vim.api.nvim_create_user_command("GoTest", function() vim.cmd("!go test ./...") end, {})

      map("<leader>gb", ":GoBuild<CR>", "Go: build ./...")
      map("<leader>gr", ":GoRun<CR>",   "Go: run main.go (or current file)")
      map("<leader>gt", ":GoTest<CR>",  "Go: test ./...")
    end,
  },

  ---------------------------------------------------------------------------
  -- 2) Formatting & linting (none-ls / null-ls)
  ---------------------------------------------------------------------------
  {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local null = require("null-ls")
      null.setup({
        sources = {
          -- formatters
          null.builtins.formatting.goimports,
          null.builtins.formatting.gofmt,
          -- optional: enable if you installed gofumpt
          -- null.builtins.formatting.gofumpt,
          -- diagnostics

          null.builtins.diagnostics.golangci_lint,
        },
      })
      -- Format on save for Go files
      vim.api.nvim_create_autocmd("BufWritePre", {

        pattern = "*.go",
        callback = function()
          vim.lsp.buf.format({ async = false })
        end,
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- 3) Treesitter: ensure Go parsers are installed
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      for _, lang in ipairs({ "go", "gomod", "gowork" }) do
        if not vim.tbl_contains(opts.ensure_installed, lang) then

          table.insert(opts.ensure_installed, lang)
        end
      end
    end,
  },
}

