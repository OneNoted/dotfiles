-- JavaScript/TypeScript language support
-- ts_ls: configured via vim.lsp.config() in lsp.lua
-- prettier: configured in formatting.lua
-- This file: treesitter parsers

return {
  -- JS/TS treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "javascript", "typescript", "tsx", "jsdoc" })
      end
    end,
  },
}
