-- LSP configuration with Mason 2.0 

return {
  -- Lua LSP enhancement (Neovim API completion)
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },

  -- Mason: LSP/tool installer
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = {},
  },

  -- Bridge between Mason and lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile", "VeryLazy" },
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      -- Get cmp-nvim-lsp capabilities and merge with default
      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities()
      )

      -- Configure servers via vim.lsp.config() BEFORE mason-lspconfig.setup()
      vim.lsp.config("lua_ls", {
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      vim.lsp.config("gopls", {
        capabilities = capabilities,
        settings = {
          gopls = {
            analyses = { unusedparams = true },
            staticcheck = true,
          },
        },
      })

      vim.lsp.config("nil_ls", {
        capabilities = capabilities,
        settings = {
          ["nil"] = {
            formatting = { command = { "nixfmt" } },
          },
        },
      })

      -- Note: yamlls full config is in lang/yaml.lua with SchemaStore
      vim.lsp.config("zls", { capabilities = capabilities })
      vim.lsp.config("taplo", { capabilities = capabilities })

      -- TypeScript/JavaScript LSP
      vim.lsp.config("ts_ls", {
        capabilities = capabilities,
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
            },
          },
        },
      })

      -- JSON LSP (SchemaStore configured in lang/json.lua)
      vim.lsp.config("jsonls", { capabilities = capabilities })

      -- QML LSP (for Qt/Quickshell)
      vim.lsp.config("qmlls", {
        capabilities = capabilities,
        cmd = { "qmlls6" }, -- Qt6 binary name on most distros
        filetypes = { "qml", "qmljs" },
      })

      -- Setup Mason
      require("mason").setup()

      -- Setup mason-lspconfig with Mason 2.0 automatic_enable
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "gopls", "nil_ls", "zls", "taplo", "ts_ls", "jsonls" },
        automatic_enable = {
          exclude = { "rust_analyzer" }, -- rustaceanvim handles Rust (Plan 03-09)
        },
      })

      -- LSP keymaps via LspAttach autocmd
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
          end

          -- Common LSP keymaps
          map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
          map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
          map("n", "gr", vim.lsp.buf.references, "References")
          map("n", "gI", vim.lsp.buf.implementation, "Implementation")
          map("n", "gy", vim.lsp.buf.type_definition, "Type Definition")
          map("n", "K", vim.lsp.buf.hover, "Hover")
          map("n", "gK", vim.lsp.buf.signature_help, "Signature Help")
          map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature Help")
          map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
          map("n", "<leader>cd", vim.diagnostic.open_float, "Line Diagnostics")
          map("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
          map("n", "[d", vim.diagnostic.goto_prev, "Prev Diagnostic")

          -- Go-specific keymaps
          if client and client.name == "gopls" then
            map("n", "<leader>gt", function()
              local file = vim.fn.expand("%:p")
              local alt
              if file:match("_test%.go$") then
                alt = file:gsub("_test%.go$", ".go")
              else
                alt = file:gsub("%.go$", "_test.go")
              end
              if vim.fn.filereadable(alt) == 1 then
                vim.cmd.edit(alt)
              else
                vim.notify("Alternate file not found: " .. alt, vim.log.levels.WARN)
              end
            end, "Toggle Test File")

            map("n", "<leader>gi", function()
              local params = vim.lsp.util.make_range_params()
              params.context = { only = { "source.organizeImports" } }
              local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
              for _, res in pairs(result or {}) do
                for _, r in pairs(res.result or {}) do
                  if r.edit then
                    vim.lsp.util.apply_workspace_edit(r.edit, "utf-8")
                  end
                end
              end
            end, "Organize Imports")
          end

          -- Zig-specific keymaps
          if client and client.name == "zls" then
            map("n", "<leader>zb", "<cmd>!zig build<cr>", "Zig Build")
            map("n", "<leader>zt", "<cmd>!zig build test<cr>", "Zig Test")
          end
        end,
      })
    end,
  },

  -- nvim-lspconfig (loaded by mason-lspconfig)
  {
    "neovim/nvim-lspconfig",
    lazy = true,
  },
}
