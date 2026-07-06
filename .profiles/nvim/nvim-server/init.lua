-- ==========================================================================
--  Notes Server Neovim Configuration
--  Single-file init.lua using vim.pack
-- ==========================================================================

------------------------------------------------------------
-- Leader
------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

------------------------------------------------------------
-- Options
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

-- Splits
opt.splitbelow = true
opt.splitright = true

-- UX
opt.scrolloff = 4
opt.sidescrolloff = 8
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200
opt.timeoutlen = 300
opt.confirm = true
opt.completeopt = "menu,menuone,noselect"
opt.smoothscroll = true
opt.spelllang = { "en" }

-- Disable builtins
for _, p in ipairs({ "gzip", "tar", "tarPlugin", "zip", "zipPlugin", "netrw", "netrwPlugin", "tutor", "tohtml" }) do
  vim.g["loaded_" .. p] = 1
end

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
  gh("hrsh7th/nvim-cmp"),
  gh("hrsh7th/cmp-nvim-lsp"),
  gh("hrsh7th/cmp-buffer"),
  gh("hrsh7th/cmp-path"),

  -- Editing & navigation
  gh("echasnovski/mini.nvim"),
  gh("folke/flash.nvim"),
  gh("folke/which-key.nvim"),
  gh("folke/snacks.nvim"),

  -- Diagnostics
  gh("folke/trouble.nvim"),
  gh("folke/todo-comments.nvim"),

  -- Git
  gh("lewis6991/gitsigns.nvim"),

  -- Formatting
  gh("stevearc/conform.nvim"),

  -- Dependencies
  gh("nvim-lua/plenary.nvim"),
})

------------------------------------------------------------
-- Plugin hooks
------------------------------------------------------------
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name = ev.data.spec.name
    local kind = ev.data.kind
    if name == "nvim-treesitter" and kind == "update" then
      vim.schedule(function()
        vim.cmd("TSUpdate")
      end)
    end
  end,
})

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
    cmp = true,
    gitsigns = true,
    treesitter = true,
    which_key = true,
    flash = true,
    mason = false,
    mini = { enabled = true },
    snacks = true,
  },
})
vim.cmd.colorscheme("catppuccin")

------------------------------------------------------------
-- Treesitter
------------------------------------------------------------

-- Install parsers
local ts_parsers = {
  "bash",
  "lua",
  "vim",
  "vimdoc",
  "query",
  "regex",
  "yaml",
  "toml",
  "json",
  "jsonc",
  "nix",
  "go",
  "python",
  "rust",
  "markdown",
  "markdown_inline",
  "dockerfile",
  "git_config",
  "gitcommit",
  "git_rebase",
  "gitignore",
  "diff",
}

-- Parsers are compiled from source on install. Run :TSInstall manually
-- on first setup rather than blocking startup. This command installs
-- all parsers from the list above that are not yet on disk:
vim.api.nvim_create_user_command("TSInstallAll", function()
  local installed = require("nvim-treesitter.config").get_installed()
  local missing = vim.tbl_filter(function(p)
    return not vim.tbl_contains(installed, p)
  end, ts_parsers)
  if #missing == 0 then
    vim.notify("All treesitter parsers already installed", vim.log.levels.INFO)
  else
    vim.notify("Installing " .. #missing .. " parsers...", vim.log.levels.INFO)
    require("nvim-treesitter.install").install(missing)
  end
end, { desc = "Install all missing treesitter parsers" })

-- Enable treesitter highlighting and indent for buffers with parsers
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    if pcall(vim.treesitter.start, ev.buf) then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Textobjects: select
require("nvim-treesitter-textobjects").setup({ select = { lookahead = true } })
local ts_select = require("nvim-treesitter-textobjects.select")
for _, binding in ipairs({
  { { "x", "o" }, "af", "@function.outer", "Around function" },
  { { "x", "o" }, "if", "@function.inner", "Inside function" },
  { { "x", "o" }, "ac", "@class.outer", "Around class" },
  { { "x", "o" }, "ic", "@class.inner", "Inside class" },
  { { "x", "o" }, "aa", "@parameter.outer", "Around parameter" },
  { { "x", "o" }, "ia", "@parameter.inner", "Inside parameter" },
}) do
  vim.keymap.set(binding[1], binding[2], function()
    ts_select.select_textobject(binding[3])
  end, { desc = binding[4] })
end

-- Textobjects: move
local ts_move = require("nvim-treesitter-textobjects.move")
for _, binding in ipairs({
  { { "n", "x", "o" }, "]f", ts_move.goto_next_start, "@function.outer", "Next function start" },
  { { "n", "x", "o" }, "]c", ts_move.goto_next_start, "@class.outer", "Next class start" },
  { { "n", "x", "o" }, "]a", ts_move.goto_next_start, "@parameter.inner", "Next parameter" },
  { { "n", "x", "o" }, "]F", ts_move.goto_next_end, "@function.outer", "Next function end" },
  { { "n", "x", "o" }, "]C", ts_move.goto_next_end, "@class.outer", "Next class end" },
  { { "n", "x", "o" }, "[f", ts_move.goto_previous_start, "@function.outer", "Prev function start" },
  { { "n", "x", "o" }, "[c", ts_move.goto_previous_start, "@class.outer", "Prev class start" },
  { { "n", "x", "o" }, "[a", ts_move.goto_previous_start, "@parameter.inner", "Prev parameter" },
  { { "n", "x", "o" }, "[F", ts_move.goto_previous_end, "@function.outer", "Prev function end" },
  { { "n", "x", "o" }, "[C", ts_move.goto_previous_end, "@class.outer", "Prev class end" },
}) do
  vim.keymap.set(binding[1], binding[2], function()
    binding[3](binding[4])
  end, { desc = binding[5] })
end

------------------------------------------------------------
-- LSP
------------------------------------------------------------

-- Server configurations (vim.lsp.config, Neovim 0.11+)
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
      diagnostics = { globals = { "vim" } },
    },
  },
})

vim.lsp.config("gopls", {
  settings = {
    gopls = {
      analyses = { unusedparams = true },
      staticcheck = true,
    },
  },
})

vim.lsp.config("nil_ls", {
  settings = {
    ["nil"] = {
      formatting = { command = { "nixfmt" } },
    },
  },
})

-- Enable LSP servers (install them via system package manager)
vim.lsp.enable({
  "lua_ls",
  "gopls",
  "nil_ls",
  "taplo",
  "jsonls",
  "yamlls",
  "bashls",
})

-- LSP attach keymaps
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
    end

    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    map("n", "gr", vim.lsp.buf.references, "References")
    map("n", "gI", vim.lsp.buf.implementation, "Go to implementation")
    map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "gK", vim.lsp.buf.signature_help, "Signature help")
    map("i", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
    map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
    map("n", "]d", function()
      vim.diagnostic.jump({ count = 1 })
    end, "Next diagnostic")
    map("n", "[d", function()
      vim.diagnostic.jump({ count = -1 })
    end, "Prev diagnostic")
  end,
})

------------------------------------------------------------
-- Completion
------------------------------------------------------------
local cmp = require("cmp")

cmp.setup({
  snippet = {
    expand = function(args)
      vim.snippet.expand(args.body)
    end,
  },
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "path" },
  }, {
    { name = "buffer", keyword_length = 3 },
  }),
  mapping = cmp.mapping.preset.insert({
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if vim.snippet.active({ direction = 1 }) then
        vim.snippet.jump(1)
      elseif cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if vim.snippet.active({ direction = -1 }) then
        vim.snippet.jump(-1)
      elseif cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, { "i", "s" }),
  }),
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
})

------------------------------------------------------------
-- Mini plugins
------------------------------------------------------------
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

require("mini.ai").setup({
  n_lines = 500,
  custom_textobjects = {
    o = require("mini.ai").gen_spec.treesitter({
      a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    }),
    f = require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    c = require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
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

require("mini.hipatterns").setup({
  highlighters = {
    fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
    hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
    todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
    note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
    hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),
  },
})

require("mini.icons").setup()
require("mini.statusline").setup()

------------------------------------------------------------
-- Flash
------------------------------------------------------------
require("flash").setup()

vim.keymap.set({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "S", function()
  require("flash").treesitter()
end, { desc = "Flash treesitter" })
vim.keymap.set("o", "r", function()
  require("flash").remote()
end, { desc = "Remote flash" })
vim.keymap.set({ "o", "x" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Treesitter search" })

------------------------------------------------------------
-- Which Key
------------------------------------------------------------
require("which-key").setup({
  preset = "classic",
  delay = 200,
  spec = {
    { "<leader>f", group = "file/find" },
    { "<leader>g", group = "git" },
    { "<leader>h", group = "hunks" },
    { "<leader>s", group = "search" },
    { "<leader>b", group = "buffer" },
    { "<leader>c", group = "code" },
    { "<leader>x", group = "diagnostics" },
    { "<leader>u", group = "ui" },
    { "<leader>q", group = "quit" },
    { "<leader>w", group = "windows" },
    { "[", group = "prev" },
    { "]", group = "next" },
    { "g", group = "goto" },
    { "gs", group = "surround" },
  },
})

------------------------------------------------------------
-- Snacks
------------------------------------------------------------
local Snacks = require("snacks")
Snacks.setup({
  picker = { enabled = true },
  explorer = { enabled = true },
  notifier = { enabled = true },
  indent = { enabled = true },
  statuscolumn = { enabled = true },
  words = { enabled = true },
  scope = { enabled = true },
})

-- Pickers: files
vim.keymap.set("n", "<leader><space>", function()
  Snacks.picker.files()
end, { desc = "Find files" })
vim.keymap.set("n", "<leader>,", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>/", function()
  Snacks.picker.grep()
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>:", function()
  Snacks.picker.command_history()
end, { desc = "Command history" })
vim.keymap.set("n", "<leader>ff", function()
  Snacks.picker.files()
end, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", function()
  Snacks.picker.git_files()
end, { desc = "Git files" })
vim.keymap.set("n", "<leader>fr", function()
  Snacks.picker.recent()
end, { desc = "Recent files" })
vim.keymap.set("n", "<leader>fb", function()
  Snacks.picker.buffers()
end, { desc = "Buffers" })

-- Pickers: search
vim.keymap.set("n", "<leader>sg", function()
  Snacks.picker.grep()
end, { desc = "Grep" })
vim.keymap.set({ "n", "v" }, "<leader>sw", function()
  Snacks.picker.grep_word()
end, { desc = "Grep word" })
vim.keymap.set("n", "<leader>sd", function()
  Snacks.picker.diagnostics()
end, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>sh", function()
  Snacks.picker.help()
end, { desc = "Help pages" })
vim.keymap.set("n", "<leader>sk", function()
  Snacks.picker.keymaps()
end, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>sm", function()
  Snacks.picker.marks()
end, { desc = "Marks" })

-- Pickers: git
vim.keymap.set("n", "<leader>gc", function()
  Snacks.picker.git_log()
end, { desc = "Git log" })
vim.keymap.set("n", "<leader>gs", function()
  Snacks.picker.git_status()
end, { desc = "Git status" })

-- Explorer
vim.keymap.set("n", "<leader>e", function()
  Snacks.explorer()
end, { desc = "Explorer" })

-- Notifications
vim.keymap.set("n", "<leader>un", function()
  Snacks.notifier.show_history()
end, { desc = "Notification history" })
vim.keymap.set("n", "<leader>uN", function()
  Snacks.notifier.hide()
end, { desc = "Dismiss notifications" })

------------------------------------------------------------
-- Trouble
------------------------------------------------------------
require("trouble").setup()

vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics" })
vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols" })
vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list" })
vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list" })

------------------------------------------------------------
-- Todo Comments
------------------------------------------------------------
require("todo-comments").setup()

vim.keymap.set("n", "]t", function()
  require("todo-comments").jump_next()
end, { desc = "Next todo" })
vim.keymap.set("n", "[t", function()
  require("todo-comments").jump_prev()
end, { desc = "Prev todo" })
vim.keymap.set("n", "<leader>xt", "<cmd>Trouble todo toggle<cr>", { desc = "Todos" })

------------------------------------------------------------
-- Gitsigns
------------------------------------------------------------
require("gitsigns").setup({
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "-" },
    changedelete = { text = "~" },
    untracked = { text = "|" },
  },
  on_attach = function(buf)
    local gs = require("gitsigns")
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
    end

    map("n", "]h", function()
      gs.nav_hunk("next")
    end, "Next hunk")
    map("n", "[h", function()
      gs.nav_hunk("prev")
    end, "Prev hunk")
    map({ "n", "v" }, "<leader>hs", gs.stage_hunk, "Stage hunk")
    map({ "n", "v" }, "<leader>hr", gs.reset_hunk, "Reset hunk")
    map("n", "<leader>hS", gs.stage_buffer, "Stage buffer")
    map("n", "<leader>hR", gs.reset_buffer, "Reset buffer")
    map("n", "<leader>hu", gs.undo_stage_hunk, "Undo stage")
    map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
    map("n", "<leader>hb", function()
      gs.blame_line({ full = true })
    end, "Blame line")
    map("n", "<leader>hB", gs.toggle_current_line_blame, "Toggle blame")
    map("n", "<leader>hd", gs.diffthis, "Diff this")
    map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
  end,
})

------------------------------------------------------------
-- Conform (formatting)
------------------------------------------------------------
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    go = { "goimports", "gofmt" },
    nix = { "nixfmt" },
    yaml = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    markdown = { "prettier" },
    toml = { "taplo" },
    bash = { "shfmt" },
    sh = { "shfmt" },
  },
  format_on_save = {
    timeout_ms = 1000,
    lsp_fallback = true,
  },
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format" })

------------------------------------------------------------
-- Diagnostics
------------------------------------------------------------
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },
  virtual_text = { spacing = 4, prefix = "●" },
  severity_sort = true,
  float = { border = "rounded" },
})

------------------------------------------------------------
-- Keymaps
------------------------------------------------------------
local map = vim.keymap.set

-- Escape
map("i", "jj", "<Esc>", { desc = "Escape" })
map("i", "jk", "<Esc>", { desc = "Escape" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Save / quit
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<CR><Esc>", { desc = "Save" })
map("n", "<leader>qq", "<cmd>qa<CR>", { desc = "Quit all" })

-- Centered scrolling
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up" })
map("n", "n", "nzzzv", { desc = "Next match" })
map("n", "N", "Nzzzv", { desc = "Prev match" })

-- Windows
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase width" })
map("n", "<leader>-", "<C-w>s", { desc = "Split below" })
map("n", "<leader>|", "<C-w>v", { desc = "Split right" })
map("n", "<leader>wd", "<C-w>c", { desc = "Delete window" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "[b", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "]b", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bb", "<cmd>e #<CR>", { desc = "Other buffer" })

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Package management
map("n", "<leader>pp", function()
  vim.pack.update()
end, { desc = "Update plugins" })
map("n", "<leader>pi", function()
  vim.print(vim.pack.get())
end, { desc = "Plugin info" })

------------------------------------------------------------
-- Autocommands
------------------------------------------------------------
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Equalize splits on resize
autocmd("VimResized", {
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Restore cursor position
autocmd("BufReadPost", {
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Close special buffers with q
autocmd("FileType", {
  pattern = { "help", "qf", "checkhealth", "man", "notify", "lspinfo" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
  end,
})

-- Wrap and spell in text buffers
autocmd("FileType", {
  group = vim.api.nvim_create_augroup("server_wrap_spell", { clear = true }),
  pattern = { "text", "mail", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.spell = true
  end,
})

-- Auto-create parent directories
autocmd("BufWritePre", {
  callback = function(ev)
    if ev.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
