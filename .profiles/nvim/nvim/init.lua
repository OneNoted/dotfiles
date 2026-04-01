-- Default Neovim profile scaffold
-- Intended to stay minimal until expanded.

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.notify("Using the default nvim scaffold profile", vim.log.levels.INFO, { title = "nvim profile" })
  end,
})
