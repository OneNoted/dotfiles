-- QML language support (Qt/Quickshell)
-- qmlls: configured via vim.lsp.config() in lsp.lua
-- Note: qmlls is provided by Qt, not Mason (install qt6-languageserver or equivalent)
-- This file: treesitter parser + filetype detection

return {
  -- QML treesitter parser
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "qmljs" })
      end
    end,
  },

  -- Filetype detection for .qml files
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.filetype.add({
        extension = {
          qml = "qml",
        },
      })
    end,
  },
}
