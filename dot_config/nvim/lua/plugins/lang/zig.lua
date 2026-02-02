-- Zig language support
-- zls: configured via vim.lsp.config() in tools/lsp.lua
-- Zig-specific keymaps: consolidated in tools/lsp.lua LspAttach
-- zigfmt: configured in tools/formatting.lua

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "zig" })
      end
    end,
  },
}
