-- Neovim configuration entry point
-- Load order: options -> lazy (plugins) -> keymaps -> autocmds

-- Silence deprecated vim.lsp.get_buffers_by_client_id (removed in 0.13, noisy in 0.12 nightly)
vim.lsp.get_buffers_by_client_id = function(client_id)
  local client = vim.lsp.get_client_by_id(client_id)
  return client and vim.tbl_keys(client.attached_buffers) or {}
end

do
  local treesitter_start = vim.treesitter.start
  vim.treesitter.start = function(bufnr, lang)
    bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or (bufnr or vim.api.nvim_get_current_buf())
    local path = vim.api.nvim_buf_get_name(bufnr)
    local readme_help_dir = vim.fn.stdpath("state") .. "/lazy/readme/doc/"
    if path:find("^" .. vim.pesc(readme_help_dir)) and (lang == nil or lang == "markdown") then
      return false
    end
    return treesitter_start(bufnr, lang)
  end
end

require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
