-- ~/.config/nvim/lua/plugins/python.lua
return {
  {
    "neovim/nvim-lspconfig", -- already installed via go.lua; not called directly here
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      local capabilities = ok and cmp_lsp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()

      local function root(bufnr)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        return vim.fs.root(fname ~= "" and fname or 0, { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" })
      end

      -- pyright: types, hover, autocomplete
      local function make_pyright_config(bufnr)
        return {
          name = "pyright",
          cmd = { "pyright-langserver", "--stdio" },
          root_dir = root(bufnr),
          filetypes = { "python" },
          capabilities = capabilities,
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
              },
            },
          },
        }
      end

      -- ruff: lint + format (via its native LSP)
      local function make_ruff_config(bufnr)
        return {
          name = "ruff",
          cmd = { "ruff", "server" },
          root_dir = root(bufnr),
          filetypes = { "python" },
          capabilities = capabilities,
        }
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function(args)
          local bufnr = args.buf
          if #vim.lsp.get_clients({ bufnr = bufnr, name = "pyright" }) == 0 then
            vim.lsp.start(make_pyright_config(bufnr))
          end
          if #vim.lsp.get_clients({ bufnr = bufnr, name = "ruff" }) == 0 then
            vim.lsp.start(make_ruff_config(bufnr))
          end

          local map = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc }) end
          map("gd", vim.lsp.buf.definition, "Python: definition")
          map("K", vim.lsp.buf.hover, "Python: hover docs")
          map("<leader>rn", vim.lsp.buf.rename, "Python: rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Python: code action")
        end,
      })

      -- format on save (ruff only; pyright doesn't support formatting)
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.py",
        callback = function()
          vim.lsp.buf.format({ async = false, filter = function(c) return c.name == "ruff" end })
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "python") then
        table.insert(opts.ensure_installed, "python")
      end
    end,
  },
}
