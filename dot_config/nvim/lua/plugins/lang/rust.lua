return {
  -- Rust LSP (replaces rust-tools.nvim)
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false, -- Plugin handles lazy loading itself
    ft = { "rust" },
    init = function()
      vim.g.rustaceanvim = {
        tools = {
          hover_actions = {
            auto_focus = true,
          },
        },
        server = {
          on_attach = function(_, bufnr)
            -- Rust-specific keymaps
            local map = function(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
            end

            map("n", "<leader>ca", function() vim.cmd.RustLsp("codeAction") end, "Code Action (Rust)")
            map("n", "<leader>dr", function() vim.cmd.RustLsp("debuggables") end, "Debuggables")
            map("n", "<leader>rr", function() vim.cmd.RustLsp("runnables") end, "Runnables")
            map("n", "<leader>re", function() vim.cmd.RustLsp("explainError") end, "Explain Error")
            map("n", "K", function() vim.cmd.RustLsp({ "hover", "actions" }) end, "Hover Actions")
          end,
          settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = { enable = true },
              },
              checkOnSave = {
                command = "clippy",
              },
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
            },
          },
        },
      }
    end,
  },

  -- Cargo.toml dependency management
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        cmp = { enabled = true },
      },
    },
  },

  -- Add Rust to treesitter (toml handled in lang/toml.lua)
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "rust" })
      end
    end,
  },
}
