-- Miscellaneous language support (thin configs consolidated)
-- Covers: Nix, TOML, JavaScript/TypeScript, QML

return {
  -- Treesitter parsers for all misc languages
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "nix",
          "toml",
          "qmljs",
          "javascript", "typescript", "tsx", "jsdoc",
        })
      end
    end,
  },

  -- QML filetype detection
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.filetype.add({ extension = { qml = "qml" } })
    end,
  },
}
