-- Just go with the flooooow --
return {
  -- Copilot via native LSP inline completion
  {
    "neovim/nvim-lspconfig",
    config = function()
      if vim.fn.executable("copilot-language-server") ~= 1 then
        return
      end
      -- Configure copilot LSP
      vim.lsp.config("copilot", {
        cmd = { "copilot-language-server", "--stdio" },
        filetypes = { "*" },
        root_markers = { ".git" },
      })

      -- Enable "copilot"
      vim.lsp.enable("copilot")

      -- Enable native inline completion
      if vim.lsp.inline_completion and vim.lsp.inline_completion.enable then
        vim.schedule(function()
          vim.lsp.inline_completion.enable(true)
        end)
      end

      -- Keymaps for cycling suggestions
      if vim.lsp.inline_completion and vim.lsp.inline_completion.select then
        vim.keymap.set({ "i", "n" }, "<M-]>", function()
          vim.lsp.inline_completion.select({ count = 1 })
        end, { desc = "Next Copilot Suggestion" })

        vim.keymap.set({ "i", "n" }, "<M-[>", function()
          vim.lsp.inline_completion.select({ count = -1 })
        end, { desc = "Prev Copilot Suggestion" })
      end
    end,
  },
  -- 99
  {
    "ThePrimeagen/99",
    config = function()
      local _99 = require("99")
      _99.setup({
        logger = {
          level = _99.DEBUG,
          path = "/tmp/project.99.debug",
          print_on_error = true,
        },
        completion = {
          source = "cmp",
        },
        md_files = { "AGENT.md" },
      })

      vim.keymap.set("n", "<leader>9f", _99.fill_in_function, { desc = "99: Fill in function" })
      vim.keymap.set("v", "<leader>9v", _99.visual, { desc = "99: Visual" })
      vim.keymap.set("n", "<leader>9s", _99.stop_all_requests, { desc = "99: Stop all requests" })
    end,
  },
}
