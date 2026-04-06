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
          test_executor = "neotest",
          hover_actions = {
            auto_focus = true,
          },
          code_actions = {
            ui_select_fallback = true,
          },
        },
        server = {
          on_attach = function(_, bufnr)
            -- Rust-specific keymaps
            local map = function(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
            end
            local rust_lsp = function(command)
              return function()
                vim.cmd.RustLsp(command)
              end
            end

            map("n", "<leader>ca", rust_lsp("codeAction"), "Code Action (Rust)")
            map("n", "<leader>dr", rust_lsp("debuggables"), "Debuggables")
            map("n", "<leader>rr", rust_lsp("runnables"), "Runnables")
            map("n", "<leader>rR", rust_lsp("renderDiagnostic"), "Render Diagnostic")
            map("n", "<leader>re", rust_lsp("explainError"), "Explain Error")
            map("n", "<leader>rd", rust_lsp("relatedDiagnostics"), "Related Diagnostics")
            map("n", "<leader>rt", rust_lsp("relatedTests"), "Related Tests")
            map("n", "<leader>rm", rust_lsp("expandMacro"), "Expand Macro")
            map("n", "<leader>rp", rust_lsp("rebuildProcMacros"), "Rebuild Proc Macros")
            map("n", "<leader>rc", rust_lsp("openCargo"), "Open Cargo.toml")
            map("n", "<leader>rO", rust_lsp("openDocs"), "Open docs.rs")
            map("n", "<leader>rM", rust_lsp("parentModule"), "Parent Module")
            map("n", "<leader>rs", rust_lsp("workspaceSymbol"), "Workspace Symbols")
            map("n", "K", function() vim.cmd.RustLsp({ "hover", "actions" }) end, "Hover Actions")

            if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
              vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
              map("n", "<leader>uh", function()
                local enabled = false
                if vim.lsp.inlay_hint.is_enabled then
                  enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
                end
                vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
              end, "Toggle Inlay Hints")
            end
          end,
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = { enable = true },
                targetDir = true,
              },
              checkOnSave = true,
              check = {
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
      on_attach = function(bufnr)
        local crates = require("crates")
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map("<leader>cp", crates.show_popup, "Crate Popup")
        map("<leader>cv", crates.show_versions_popup, "Crate Versions")
        map("<leader>cu", crates.update_crate, "Update Crate")
        map("<leader>cU", crates.update_all_crates, "Update All Crates")
        map("<leader>cH", crates.open_homepage, "Open Crate Homepage")
        map("<leader>cR", crates.open_repository, "Open Crate Repository")
        map("<leader>cD", crates.open_documentation, "Open Crate Documentation")
        map("<leader>cC", crates.open_crates_io, "Open on crates.io")
      end,
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
