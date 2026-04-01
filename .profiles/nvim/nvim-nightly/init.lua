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
  { src = gh("yetone/avante.nvim"), name = "avante.nvim" },

  -- Editing & navigation
  gh("echasnovski/mini.nvim"),


  -- Diagnostics

  -- Git
  
  -- Formatting

  -- Dependencies
  gh("mikesmithgh/kitty-scrollback.nvim"),
  gh("nvim-lua/plenary.nvim"),
  gh("MunifTanjim/nui.nvim"),
  gh("rafamadriz/friendly-snippets"),

})

------------------------------------------------------------
-- Plugin hooks
------------------------------------------------------------

local function build_avante(path)
  if vim.fn.executable("make") ~= 1 then
    vim.schedule(function()
      vim.notify("avante.nvim needs `make` to build", vim.log.levels.WARN)
    end)
    return
  end

  local result = vim.system({ "make" }, { cwd = path, text = true }):wait()
  if result.code == 0 then
    return
  end

  local output = (result.stderr and result.stderr ~= "") and result.stderr or (result.stdout or "")
  vim.schedule(function()
    vim.notify("Failed to build avante.nvim\n" .. output, vim.log.levels.ERROR)
  end)
end

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    if ev.data.spec.name == "avante.nvim" and (ev.data.kind == "install" or ev.data.kind == "update") then
      build_avante(ev.data.path)
    end
  end,
})

------------------------------------------------------------
-- kitty-scrollback.nvim
------------------------------------------------------------
require('kitty-scrollback').setup()

------------------------------------------------------------
-- Mini plugins
------------------------------------------------------------
require("mini.comment").setup()
require("mini.pairs").setup()

require("mini.surround").setup({
  mappings = {
    add = "gsa",
    delete = "gsd",
    replace = "gsr",
    find = "gsf",
    find_left = "gsF",
    highlight = "gsh",
    update_n_lines = "gsn",
  },
})

local ai = require("mini.ai")
ai.setup({
  n_lines = 500,
  custom_textobjects = {
    o = ai.gen_spec.treesitter({
      a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    }, {}),
    f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
    c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
  },
})

require("mini.move").setup({
  mappings = {
    left = "<M-h>",
    right = "<M-l>",
    down = "<M-j>",
    up = "<M-k>",
    line_left = "<M-h>",
    line_right = "<M-l>",
    line_down = "<M-j>",
    line_up = "<M-k>",
  },
})

require("mini.diff").setup({
  view = {
    style = "sign",
    signs = { add = "+", change = "~", delete = "-" },
  },
})

local hipatterns = require("mini.hipatterns")
hipatterns.setup({
  highlighters = {
    fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
    hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
    todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
    note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
    hex_color = hipatterns.gen_highlighter.hex_color(),
  },
})

require("mini.snippets").setup({
  snippets = {
    require("mini.snippets").gen_loader.from_lang(),
  },
})


------------------------------------------------------------
-- Keymaps
------------------------------------------------------------



------------------------------------------------------------
-- Diagnostics
------------------------------------------------------------



------------------------------------------------------------
-- Colorscheme
------------------------------------------------------------

require("catppuccin").setup({
  flavour = "mocha",
  styles = {
    comments = { "italic" },
    conditionals = { "italic" },
  },
  integrations = {
    mini = { enabled = true },
  },
})

vim.cmd.colorscheme("catppuccin")

------------------------------------------------------------
-- avante.nvim
------------------------------------------------------------

require("avante").setup({
  provider = "codex",
  behaviour = {
    -- ACP-backed suggestions are noisy and expensive in a tiny nightly config.
    auto_suggestions = false,
  },
  acp_providers = {
    codex = {
      command = "codex-acp",
      env = {
        HOME = os.getenv("HOME"),
        PATH = os.getenv("PATH"),
        OPENAI_API_KEY = os.getenv("OPENAI_API_KEY"),
        CODEX_API_KEY = os.getenv("CODEX_API_KEY"),
      },
    },
  },
})

------------------------------------------------------------
-- Autocommands
------------------------------------------------------------
