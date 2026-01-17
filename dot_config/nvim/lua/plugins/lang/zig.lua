return {
  -- Zig treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "zig" })
      end
    end,
  },

  -- Zig-specific keymaps
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_zig_lsp", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == "zls" then
            local map = function(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
            end

            map("n", "<leader>zb", "<cmd>!zig build<cr>", "Zig Build")
            map("n", "<leader>zt", "<cmd>!zig build test<cr>", "Zig Test")
          end
        end,
      })
    end,
  },

  -- Note: zls LSP is configured in lsp.lua ensure_installed
  -- Note: zigfmt formatting is in formatting.lua
}
