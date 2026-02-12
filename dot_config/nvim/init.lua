-- Neovim configuration entry point
-- Load order: options -> lazy (plugins) -> keymaps -> autocmds

-- Silence deprecated vim.lsp.get_buffers_by_client_id (removed in 0.13, noisy in 0.12 nightly)
vim.lsp.get_buffers_by_client_id = function(client_id)
  local client = vim.lsp.get_client_by_id(client_id)
  return client and vim.tbl_keys(client.attached_buffers) or {}
end

require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
