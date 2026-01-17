return {
  -- SchemaStore for JSON/YAML schemas
  {
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false,
  },

  -- YAML treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "yaml" })
      end
    end,
  },

  -- Mason: ensure yamlls is installed
  {
    "williamboman/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "yamlls" })
    end,
  },

  -- Configure yamlls to use SchemaStore
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Get cmp capabilities if available
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
      end

      -- Configure yamlls with SchemaStore
      vim.lsp.config("yamlls", {
        capabilities = capabilities,
        settings = {
          yaml = {
            schemaStore = {
              enable = false, -- Disable built-in schemaStore
              url = "", -- Avoid fetching from URL
            },
            schemas = require("schemastore").yaml.schemas(),
          },
        },
        on_attach = function(client, bufnr)
          -- Kubernetes file detection
          local filename = vim.api.nvim_buf_get_name(bufnr)
          if filename:match("kubernetes") or filename:match("k8s") then
            client.config.settings.yaml.schemas["kubernetes"] = filename
          end
        end,
      })
    end,
  },
}
