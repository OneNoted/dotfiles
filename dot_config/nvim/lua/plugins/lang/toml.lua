return {
  -- TOML treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "toml" })
      end
    end,
  },

  -- Note: taplo LSP is configured in lsp.lua ensure_installed
  -- Note: taplo formatting is in formatting.lua
}
