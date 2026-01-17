-- Options are loaded before lazy.nvim startup
-- Source: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Leader keys (MUST be first, before lazy.nvim loads)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- General
vim.opt.autowrite = true          -- Auto-save before commands like :next
vim.opt.clipboard = "unnamedplus" -- Sync with system clipboard
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.conceallevel = 2          -- Hide markup in markdown
vim.opt.confirm = true            -- Confirm to save changes before exiting
vim.opt.cursorline = true         -- Highlight current line
vim.opt.expandtab = true          -- Use spaces instead of tabs
vim.opt.fillchars = {
  foldopen = "-",
  foldclose = "+",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
vim.opt.foldlevel = 99
vim.opt.formatoptions = "jcroqlnt" -- tcqj is default
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.grepprg = "rg --vimgrep"
vim.opt.ignorecase = true         -- Ignore case in search
vim.opt.inccommand = "nosplit"    -- Preview substitutions
vim.opt.jumpoptions = "view"
vim.opt.laststatus = 3            -- Global statusline
vim.opt.linebreak = true          -- Wrap at word boundaries
vim.opt.list = true               -- Show invisible characters
vim.opt.mouse = "a"               -- Enable mouse
vim.opt.number = true             -- Show line numbers
vim.opt.pumblend = 10             -- Popup transparency
vim.opt.pumheight = 10            -- Max completion items
vim.opt.relativenumber = true     -- Relative line numbers
vim.opt.ruler = false             -- Disable ruler (statusline shows it)
vim.opt.scrolloff = 4             -- Lines above/below cursor
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }
vim.opt.shiftround = true         -- Round indent to shiftwidth
vim.opt.shiftwidth = 2            -- Indent size
vim.opt.showmode = false          -- Don't show mode (statusline shows it)
vim.opt.sidescrolloff = 8         -- Columns to left/right of cursor
vim.opt.signcolumn = "yes"        -- Always show sign column
vim.opt.smartcase = true          -- Case-sensitive if uppercase in search
vim.opt.smartindent = true        -- Auto-indent new lines
vim.opt.smoothscroll = true       -- Smooth scrolling
vim.opt.spelllang = { "en" }
vim.opt.splitbelow = true         -- Horizontal splits below
vim.opt.splitkeep = "screen"      -- Keep screen position on split
vim.opt.splitright = true         -- Vertical splits right
vim.opt.tabstop = 2               -- Tab display width
vim.opt.termguicolors = true      -- True color support
vim.opt.timeoutlen = 300          -- Keymap timeout (for which-key)
vim.opt.undofile = true           -- Persistent undo
vim.opt.undolevels = 10000        -- More undo history
vim.opt.updatetime = 200          -- Faster completion
vim.opt.virtualedit = "block"     -- Allow cursor past EOL in block mode
vim.opt.wildmode = "longest:full,full"
vim.opt.winminwidth = 5           -- Min window width
vim.opt.wrap = false              -- Don't wrap lines

-- Disable unused providers (speeds up startup)
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
