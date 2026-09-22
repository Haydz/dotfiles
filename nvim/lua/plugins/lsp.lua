-- ~/.config/nvim/lua/plugins/lsp.lua
--
-- ALL language servers are configured here, in a single nvim-lspconfig spec.
--
-- This file exists because they cannot be split per-language. lazy.nvim merges
-- every spec naming the same plugin into one, and `config` is a single value,
-- not a list — so two files each declaring
--
--     { "neovim/nvim-lspconfig", config = function() ... end }
--
-- silently resolve to whichever one lazy merges last. That is exactly what
-- used to happen: go.lua and python.lua both did it, python.lua won, and gopls
-- never started on a Go buffer. There was no error; the Go keymaps just did
-- nothing. Adding a server means adding it below, not adding another spec.
--
-- Servers are started by hand via vim.lsp.start rather than through
-- lspconfig's framework — the plugin is here for its capabilities helpers and
-- because other specs expect it on the runtimepath.

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "hrsh7th/cmp-nvim-lsp" },
  config = function()
    local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
    local capabilities = ok and cmp_lsp.default_capabilities()
      or vim.lsp.protocol.make_client_capabilities()

    -- Walk up from the buffer to the nearest project marker.
    local function root(bufnr, markers)
      local fname = vim.api.nvim_buf_get_name(bufnr)
      return vim.fs.root(fname ~= "" and fname or 0, markers)
    end

    -- Attach the shared keymaps to this buffer only. Buffer-local matters:
    -- a global `gd` would also fire in buffers with no LSP attached.
    local function on_attach(bufnr, lang)
      local map = function(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = lang .. ": " .. desc })
      end
      map("gd", vim.lsp.buf.definition, "definition")
      map("K", vim.lsp.buf.hover, "hover docs")
      map("<leader>rn", vim.lsp.buf.rename, "rename symbol")
      map("<leader>ca", vim.lsp.buf.code_action, "code action")
      map("<leader>f", function() vim.lsp.buf.format({ async = true }) end, "format buffer")
    end

    -- start_once <bufnr> <config> — never stack two clients on one buffer.
    local function start_once(bufnr, cfg)
      if #vim.lsp.get_clients({ bufnr = bufnr, name = cfg.name }) == 0 then
        vim.lsp.start(cfg)
      end
    end

    local GO_MARKERS = { "go.work", "go.mod", ".git" }
    local PY_MARKERS = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" }

    ---------------------------------------------------------------------- Go --
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "go", "gomod", "gowork", "gotmpl" },
      callback = function(args)
        local bufnr = args.buf
        start_once(bufnr, {
          name = "gopls",
          cmd = { "gopls" },
          root_dir = root(bufnr, GO_MARKERS),
          filetypes = { "go", "gomod", "gowork", "gotmpl" },
          capabilities = capabilities,
          settings = {
            gopls = {
              analyses = { unusedparams = true },
              staticcheck = true,
            },
          },
        })
        on_attach(bufnr, "Go")
      end,
    })

    ------------------------------------------------------------------ Python --
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "python",
      callback = function(args)
        local bufnr = args.buf
        -- pyright: types, hover, completion
        start_once(bufnr, {
          name = "pyright",
          cmd = { "pyright-langserver", "--stdio" },
          root_dir = root(bufnr, PY_MARKERS),
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
        })
        -- ruff: lint + format, via its native LSP
        start_once(bufnr, {
          name = "ruff",
          cmd = { "ruff", "server" },
          root_dir = root(bufnr, PY_MARKERS),
          filetypes = { "python" },
          capabilities = capabilities,
        })
        on_attach(bufnr, "Python")
      end,
    })

    -- Format on save, pinned to one formatter per language. Without the
    -- filter, two attached clients that both advertise formatting make
    -- vim.lsp.buf.format prompt for which to use on every single write.
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.py",
      callback = function()
        -- pyright has no formatting capability; ruff is the one that does.
        vim.lsp.buf.format({
          async = false,
          filter = function(c) return c.name == "ruff" end,
        })
      end,
    })

    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.go",
      callback = function()
        -- goimports/gofmt come through none-ls (see go.lua), which registers
        -- itself as the "null-ls" client. Prefer it over gopls so imports get
        -- fixed up on save, but fall back to gopls if none-ls is not attached.
        local has_null_ls = #vim.lsp.get_clients({ bufnr = 0, name = "null-ls" }) > 0
        vim.lsp.buf.format({
          async = false,
          filter = function(c)
            if has_null_ls then return c.name == "null-ls" end
            return c.name == "gopls"
          end,
        })
      end,
    })
  end,
}
