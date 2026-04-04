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

local has_chezmoi = vim.fn.executable("chezmoi") == 1
local source_path_cache = {}
local target_path_cache = {}
local watched_chezmoi_buffers = {}
local redirecting_targets = {}

local function normalize_path(path)
	if path == nil or path == "" then
		return nil
	end

	return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local function run_chezmoi_path_command(command, path)
	if not has_chezmoi then
		return nil
	end

	local args = { "chezmoi", command }
	if path then
		table.insert(args, normalize_path(path))
	end

	local result = vim.fn.systemlist(args)
	if vim.v.shell_error ~= 0 or result[1] == nil or result[1] == "" then
		return nil
	end

	return normalize_path(result[1])
end

local chezmoi_source_root = run_chezmoi_path_command("source-path")

local function is_chezmoi_source_file(path)
	local normalized = normalize_path(path)
	if not normalized or not chezmoi_source_root then
		return false
	end

	return normalized == chezmoi_source_root
		or normalized:sub(1, #chezmoi_source_root + 1) == chezmoi_source_root .. "/"
end

local function managed_source_path(path)
	local normalized = normalize_path(path)
	if not normalized or is_chezmoi_source_file(normalized) then
		return nil
	end

	local cached = source_path_cache[normalized]
	if cached ~= nil then
		return cached or nil
	end

	local source_path = run_chezmoi_path_command("source-path", normalized)
	if not source_path or source_path == normalized then
		source_path_cache[normalized] = false
		return nil
	end

	source_path_cache[normalized] = source_path
	return source_path
end

local function managed_target_path(path)
	local normalized = normalize_path(path)
	if not normalized or not is_chezmoi_source_file(normalized) then
		return nil
	end

	local cached = target_path_cache[normalized]
	if cached ~= nil then
		return cached or nil
	end

	local target_path = run_chezmoi_path_command("target-path", normalized)
	if not target_path then
		target_path_cache[normalized] = false
		return nil
	end

	target_path_cache[normalized] = target_path
	return target_path
end

if has_chezmoi then
	vim.g["chezmoi#use_tmp_buffer"] = 1
	vim.g["chezmoi#use_external"] = 1
end

vim.pack.add({
	-- Colorscheme
	{ src = gh("catppuccin/nvim"), name = "catppuccin" },

	-- Treesitter
	gh("nvim-treesitter/nvim-treesitter"),
	gh("nvim-treesitter/nvim-treesitter-textobjects"),

	-- LSP
	gh("neovim/nvim-lspconfig"),

	-- Chezmoi
	gh("alker0/chezmoi.vim"),
	gh("xvzc/chezmoi.nvim"),

	-- Presence
	{ src = gh("vyfor/cord.nvim"), name = "cord.nvim" },

	-- Completion
	{ src = gh("yetone/avante.nvim"), name = "avante.nvim" },

	-- Editing & navigation
	gh("echasnovski/mini.nvim"),
	gh("folke/flash.nvim"),

	-- Diagnostics

	-- Git

	-- Picker
	gh("mikavilpas/yazi.nvim"),

	-- Formatting
	gh("stevearc/conform.nvim"),

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
		elseif ev.data.spec.name == "cord.nvim" and (ev.data.kind == "install" or ev.data.kind == "update") then
			vim.schedule(function()
				vim.cmd("Cord update")
			end)
		end
	end,
})

------------------------------------------------------------
-- Chezmoi
------------------------------------------------------------
if has_chezmoi and chezmoi_source_root then
	local chezmoi_group = vim.api.nvim_create_augroup("nightly_chezmoi_integration", { clear = true })

	local function watch_source_buffer(bufnr)
		if watched_chezmoi_buffers[bufnr] then
			return
		end

		local filepath = vim.api.nvim_buf_get_name(bufnr)
		if not managed_target_path(filepath) then
			return
		end

		watched_chezmoi_buffers[bufnr] = true
		vim.schedule(function()
			if not vim.api.nvim_buf_is_valid(bufnr) then
				watched_chezmoi_buffers[bufnr] = nil
				return
			end

			local ok, edit = pcall(require, "chezmoi.commands.__edit")
			if ok and type(edit.watch) == "function" then
				edit.watch(bufnr)
			end
		end)
	end

	local function redirect_target_buffer(event)
		local filepath = normalize_path(vim.api.nvim_buf_get_name(event.buf))
		if not filepath or is_chezmoi_source_file(filepath) or redirecting_targets[filepath] then
			return
		end

		if vim.bo[event.buf].buftype ~= "" or vim.fn.isdirectory(filepath) == 1 then
			return
		end

		local source_path = managed_source_path(filepath)
		if not source_path then
			return
		end

		local winid = vim.fn.bufwinid(event.buf)
		if winid == -1 then
			return
		end

		redirecting_targets[filepath] = true
		vim.schedule(function()
			local current_winid = vim.fn.bufwinid(event.buf)
			if current_winid ~= -1 then
				vim.api.nvim_win_call(current_winid, function()
					vim.cmd({ cmd = "edit", args = { source_path } })
				end)
			end

			redirecting_targets[filepath] = nil
		end)
	end

	vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
		group = chezmoi_group,
		callback = function(event)
			local filepath = vim.api.nvim_buf_get_name(event.buf)
			if is_chezmoi_source_file(filepath) then
				watch_source_buffer(event.buf)
				return
			end

			redirect_target_buffer(event)
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		group = chezmoi_group,
		callback = function(event)
			watched_chezmoi_buffers[event.buf] = nil
		end,
	})

	vim.api.nvim_create_user_command("ChezmoiRefreshCache", function()
		source_path_cache = {}
		target_path_cache = {}
		vim.notify("Chezmoi source/target path caches cleared", vim.log.levels.INFO)
	end, { desc = "Refresh chezmoi path caches" })
end

------------------------------------------------------------
-- kitty-scrollback.nvim
------------------------------------------------------------
require("kitty-scrollback").setup()

------------------------------------------------------------
-- cord.nvim
------------------------------------------------------------
require("cord").setup({
	display = {
		theme = "catppuccin",
		flavor = "dark",
	},

	editor = {
		client = "neovim",
		tooltip = "I know what I'm doing some of the time maybe probably hopefully",
		icon = require("cord.api.icon").get("neovim", "atom"),
	},

	text = {
		editing = function(_)
			return "Editing a file"
		end,
		viewing = "Viewing a file",
		workspace = "",
	},

	hooks = {
		post_activity = function(_, activity)
			activity.type = "competing"
			activity.status_display_type = "name"
			activity.details = activity.details or "wawa"
			activity.state = activity.state or "Neovim"
			return activity
		end,
	},

	idle = {
		enabled = false,
	},

	assets = {},
})

------------------------------------------------------------
-- Mini plugins
------------------------------------------------------------

-- Text editing
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
require("mini.align").setup()

require("mini.comment").setup()

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

require("mini.operators").setup()

local mini_pairs_mapping = function(action, pair, neigh_pattern, opts)
	return vim.tbl_extend("force", {
		action = action,
		pair = pair,
		neigh_pattern = neigh_pattern,
	}, opts or {})
end

require("mini.pairs").setup({
	modes = { insert = true, command = false, terminal = false },
	mappings = {
		[")"] = mini_pairs_mapping("close", "()", "[^\\]."),
		["]"] = mini_pairs_mapping("close", "[]", "[^\\]."),
		["}"] = mini_pairs_mapping("close", "{}", "[^\\]."),
		["["] = mini_pairs_mapping("open", "[]", ".[%s%z%)}%]]", { register = { cr = false } }),
		['"'] = mini_pairs_mapping("closeopen", '""', "[^%w\\][^%w]", { register = { cr = false } }),
	},
})

require("mini.snippets").setup({
	mappings = {
		expand = "<M-j>",
		jump_next = "<C-l>",
		jump_prev = "<C-h>",
		stop = "<C-c>",
	},
	snippets = {
		require("mini.snippets").gen_loader.from_lang(),
	},
})

require("mini.splitjoin").setup()

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

-- General workflow

require("mini.clue").setup({
	triggers = {
		-- Leader triggers
		{ mode = { "n", "x" }, keys = "<Leader>" },

		-- `[` and `]` keys
		{ mode = "n", keys = "[" },
		{ mode = "n", keys = "]" },

		-- Built-in completion
		{ mode = "i", keys = "<C-x>" },

		-- `g` key
		{ mode = { "n", "x" }, keys = "g" },

		-- Marks
		{ mode = { "n", "x" }, keys = "'" },
		{ mode = { "n", "x" }, keys = "`" },

		-- Registers
		{ mode = { "n", "x" }, keys = '"' },
		{ mode = { "i", "c" }, keys = "<C-r>" },

		-- Window commands
		{ mode = "n", keys = "<C-w>" },

		-- `z` key
		{ mode = { "n", "x" }, keys = "z" },
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

require("mini.jump").setup()

require("flash").setup({
	modes = {
		search = { enabled = false },
		char = { enabled = false },
	},
})

-- Appearance

require("mini.icons").setup()
require("mini.notify").setup()
require("mini.statusline").setup()

------------------------------------------------------------
-- Keymaps
------------------------------------------------------------

vim.keymap.set("n", "<C-s>", "<Cmd>write<CR>", { desc = "Save buffer" })
vim.keymap.set("i", "<C-s>", "<C-o><Cmd>write<CR>", { desc = "Save buffer" })
vim.keymap.set("x", "<C-s>", "<Esc><Cmd>write<CR>gv", { desc = "Save buffer" })

-- mini.pairs
------------------------------------------------------------

-- Enter aliases for terminals/keyboards that don't send plain <CR>
vim.keymap.set("i", "<NL>", "v:lua.MiniPairs.cr()", {
	expr = true,
	replace_keycodes = false,
	desc = "MiniPairs <NL>",
})

vim.keymap.set("i", "<kEnter>", "v:lua.MiniPairs.cr()", {
	expr = true,
	replace_keycodes = false,
	desc = "MiniPairs <kEnter>",
})

------------------------------------------------------------
-- flash.nvim
------------------------------------------------------------

-- General motion and selection
vim.keymap.set({ "n", "x", "o" }, "s", function()
	require("flash").jump()
end, { desc = "Flash" })

vim.keymap.set({ "n", "x", "o" }, "S", function()
	require("flash").treesitter()
end, { desc = "Flash Treesitter" })

-- Operator-pending and visual selection
vim.keymap.set("o", "r", function()
	require("flash").remote()
end, { desc = "Remote Flash" })

vim.keymap.set({ "o", "x" }, "R", function()
	require("flash").treesitter_search()
end, { desc = "Treesitter Search" })

------------------------------------------------------------
-- Diagnostics
------------------------------------------------------------

------------------------------------------------------------
-- Formatting
------------------------------------------------------------
require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		rust = { "rustfmt", lsp_format = "fallback" },
	},
	format_on_save = {
		timeout_ms = 1000,
	},
})

------------------------------------------------------------
-- Statusline
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
		treesitter = true,
		flash = true,
	},
})

vim.cmd.colorscheme("catppuccin")

------------------------------------------------------------
-- avante.nvim
------------------------------------------------------------

require("avante").setup({
	provider = "codex",
	behaviour = {
		auto_suggestions = false,
	},
	acp_providers = {
		codex = {
			command = "codex-acp",
			args = {},
			env = {
				NODE_NO_WARNINGS = "1",
				HOME = os.getenv("HOME"),
				PATH = os.getenv("PATH"),
			},
		},
	},
})

do
	local avante = require("avante")
	local acp_config_selector = require("avante.acp_config_selector")
	local original_open = acp_config_selector.open

	acp_config_selector.open = function(category, prompt_label)
		local sidebar = avante.get(false)
		if not sidebar or not sidebar:is_open() then
			avante.open_sidebar({ ask = false })
			sidebar = avante.get(false)
		end

		if not sidebar or not sidebar:is_open() then
			vim.notify("Unable to open Avante sidebar for ACP selection", vim.log.levels.WARN)
			return
		end

		return original_open(category, prompt_label)
	end
end

------------------------------------------------------------
-- Autocommands
------------------------------------------------------------
