-- Go language support
-- gopls: configured via vim.lsp.config() in tools/lsp.lua
-- Go-specific keymaps: consolidated in tools/lsp.lua LspAttach
-- goimports + gofmt: configured in tools/formatting.lua
-- golangci-lint: configured in tools/linting.lua

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "go", "gomod", "gosum", "gowork" })
      end
    end,
  },
}
