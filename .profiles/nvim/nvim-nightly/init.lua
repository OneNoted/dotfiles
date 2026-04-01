-- ==========================================================================
--  Notes Nightly Neovim Configuration
--  Single-file init.lua using vim.pack
-- ==========================================================================

------------------------------------------------------------
-- Leader
------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
------------------------------------------------------------ Options
------------------------------------------------------------
local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true
opt.showmode = false
opt.laststatus = 3
opt.pumheight = 10
opt.pumblend = 10

-- UX
vim.opt.clipboard = "unnamedplus"
opt.scrolloff = 4
opt.sidescrolloff = 8
opt.mouse = "a"
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200
opt.timeoutlen = 300
opt.confirm = true
opt.completeopt = "menu,menuone,noselect"
opt.smoothscroll = true
opt.spelllang = { "en" }

-- Editing
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.shiftround = true
opt.wrap = false
opt.conceallevel = 2

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.grepprg = "rg --vimgrep"
opt.grepformat = "%f:%l:%c:%m"

-- splits
opt.splitbelow = true
opt.splitright = true

------------------------------------------------------------
-- Packages
------------------------------------------------------------
local gh = function(x)
	return "https://github.com/" .. x
end

vim.pack.add({
  -- Colorscheme
  { src = gh("catppuccin/nvim"), name = "catppuccin" },

  -- Treesitter
  gh("nvim-treesitter/nvim-treesitter"),
  gh("nvim-treesitter/nvim-treesitter-textobjects"),
  
  -- LSP
  gh("neovim/nvim-lspconfig"),

  -- Completion

  -- Editing & navigation

  -- Diagnostics

  -- Git
  
  -- Formatting

  -- Dependencies
  gh("nvim-lua/plenary.nvim"),

})


------------------------------------------------------------
-- avante.nvim
------------------------------------------------------------




------------------------------------------------------------
-- Keymaps
------------------------------------------------------------



------------------------------------------------------------
-- Diagnostics
------------------------------------------------------------



------------------------------------------------------------
-- Colorscheme
------------------------------------------------------------

vim.cmd.colorscheme("catppuccin")

------------------------------------------------------------
-- Autocommands
------------------------------------------------------------
