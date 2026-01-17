-- Go language support configuration
-- gopls: configured via vim.lsp.config() in lsp.lua
-- goimports + gofmt: configured in formatting.lua
-- golangci-lint: configured in linting.lua
-- This file: treesitter parsers + Go-specific keymaps

return {
  -- Go-related treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "go", "gomod", "gosum", "gowork" })
      end
    end,
  },

  -- Go-specific keymaps via LspAttach
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_go_lsp", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == "gopls" then
            local map = function(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
            end

            -- Toggle between implementation and test file
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

            -- Organize imports using LSP code action
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
        end,
      })
    end,
  },
}
