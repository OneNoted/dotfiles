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

      -- Configure yamlls with SchemaStore (includes kubernetes schemas automatically)
      vim.lsp.config("yamlls", {
        capabilities = capabilities,
        settings = {
          yaml = {
            schemaStore = {
              enable = false, -- Disable built-in schemaStore
              url = "", -- Avoid fetching from URL
            },
            schemas = require("schemastore").yaml.schemas({
              extra = {
                -- Add kubernetes schema for common k8s file patterns
                {
                  description = "Kubernetes",
                  fileMatch = { "**/kubernetes/**/*.yaml", "**/k8s/**/*.yaml", "*.k8s.yaml" },
                  name = "kubernetes",
                  url = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.0-standalone-strict/all.json",
                },
              },
            }),
          },
        },
      })
    end,
  },
}
