-- Nightly Neovim profile scaffold
-- Fill this in once the nightly-specific config is ready.

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.notify("Using the nvim-nightly scaffold profile", vim.log.levels.WARN, { title = "nvim profile" })
  end,
})
