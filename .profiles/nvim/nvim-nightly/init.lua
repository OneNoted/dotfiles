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

  -- Vibe
  gh("OneNoted/avante.nvim"),

  -- Editing & navigation
  gh("nvim-mini/mini.ai"),
  gh("nvim-mini/mini.pairs"),


  -- Diagnostics

  -- Git
  
  -- Formatting

  -- Dependencies
  gh("mikesmithgh/kitty-scrollback.nvim"),
  gh("nvim-lua/plenary.nvim"),
  gh("MunifTanjim/nui.nvim"),

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
-- avante.nvim
------------------------------------------------------------
require("avante").setup({
  provider = "openai_oauth",
  auto_suggestions_provider = "openai_oauth",
  providers = {
    openai_oauth = {
      model = "gpt-5.3-codex-spark",
      use_response_api = true,
      extra_request_body = {
        reasoning_effort = "low",
      },
    },
  },

  acp_providers = {
    codex = {
      command = "codex-acp",
      env = {
        HOME = os.getenv("HOME"),
        PATH = os.getenv("PATH"),
      },
    },
  },
  behaviour = {
    auto_suggestions = true,
    auto_set_keymaps = false,
  },
  suggestion = {
    debounce = 100,
    throttle = 150,
  },
})


------------------------------------------------------------
-- kitty-scrollback.nvim
------------------------------------------------------------
require('kitty-scrollback').setup()


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

vim.api.nvim_set_hl(0, "AvanteSuggestion", {
  fg = "#7f849c",
  italic = true,
})

vim.api.nvim_set_hl(0, "AvanteToBeDeleted", {
  fg = "#f38ba8",
  bg = "NONE",
  strikethrough = true,
})

vim.api.nvim_set_hl(0, "AvanteToBeDeletedWOStrikethrough", {
  fg = "#f38ba8",
  bg = "NONE",
})

------------------------------------------------------------
-- Autocommands
------------------------------------------------------------
