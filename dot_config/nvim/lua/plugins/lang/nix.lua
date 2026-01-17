return {
  -- Nix treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "nix" })
      end
    end,
  },

  -- Note: nil_ls LSP configuration is in lsp.lua
  -- Note: nixfmt formatting is in formatting.lua
}
