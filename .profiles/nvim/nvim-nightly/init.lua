-- ==========================================================================
-- Notes Nightly Neovim Configuration
-- Single-file init.lua using vim.pack
-- ==========================================================================
-- vim: set foldmethod=marker foldlevel=0 foldenable:

------------------------------------------------------------
-- Leader
------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Let yazi.nvim take over directory opens like `nvim .`.
vim.g.loaded_netrwPlugin = 1

------------------------------------------------------------
-- Options
------------------------------------------------------------
do
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
	opt.clipboard = "unnamedplus"
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

	-- Splits
	opt.splitbelow = true
	opt.splitright = true
end

------------------------------------------------------------
-- Packages
------------------------------------------------------------
do
	local function gh(repo)
		return "https://github.com/" .. repo
	end

	if vim.fn.executable("chezmoi") == 1 then
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
		gh("hrsh7th/nvim-cmp"),
		gh("hrsh7th/cmp-nvim-lsp"),
		gh("hrsh7th/cmp-buffer"),
		gh("hrsh7th/cmp-path"),
		gh("abeldekat/cmp-mini-snippets"),

		-- Editing & navigation
		gh("echasnovski/mini.nvim"),
		gh("folke/flash.nvim"),
		gh("folke/snacks.nvim"),
		gh("folke/which-key.nvim"),

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
end

------------------------------------------------------------
-- Plugin Hooks {{{1
------------------------------------------------------------
do
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
		callback = function(event)
			local pack_event = event.data or {}
			local spec = pack_event.spec or {}
			local name = spec.name
			local kind = pack_event.kind

			if name == "avante.nvim" and (kind == "install" or kind == "update") then
				build_avante(pack_event.path)
				return
			end

			if name == "cord.nvim" and (kind == "install" or kind == "update") then
				vim.schedule(function()
					vim.cmd("Cord update")
				end)
			end
		end,
	})
end
-- Plugin Hooks }}}

------------------------------------------------------------
-- Chezmoi {{{1
------------------------------------------------------------
do
	local has_chezmoi = vim.fn.executable("chezmoi") == 1
	local source_path_cache = {}
	local target_path_cache = {}
	local watched_buffers = {}
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
			local normalized = normalize_path(path)
			if not normalized then
				return nil
			end

			table.insert(args, normalized)
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

	if has_chezmoi and chezmoi_source_root then
		local group = vim.api.nvim_create_augroup("nightly_chezmoi_integration", { clear = true })

		local function watch_source_buffer(bufnr)
			if watched_buffers[bufnr] then
				return
			end

			local filepath = vim.api.nvim_buf_get_name(bufnr)
			if not managed_target_path(filepath) then
				return
			end

			watched_buffers[bufnr] = true
			vim.schedule(function()
				if not vim.api.nvim_buf_is_valid(bufnr) then
					watched_buffers[bufnr] = nil
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
			group = group,
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
			group = group,
			callback = function(event)
				watched_buffers[event.buf] = nil
			end,
		})

		vim.api.nvim_create_user_command("ChezmoiRefreshCache", function()
			source_path_cache = {}
			target_path_cache = {}
			vim.notify("Chezmoi source/target path caches cleared", vim.log.levels.INFO)
		end, { desc = "Refresh chezmoi path caches" })
	end
end
-- Chezmoi }}}

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
		editing = function()
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
-- Treesitter
------------------------------------------------------------
do
	local ok, treesitter = pcall(require, "nvim-treesitter")
	if ok then
		local languages = {
			"bash",
			"diff",
			"go",
			"git_config",
			"gitcommit",
			"gitignore",
			"javascript",
			"jsdoc",
			"json",
			"lua",
			"markdown",
			"markdown_inline",
			"nix",
			"query",
			"regex",
			"rust",
			"toml",
			"tsx",
			"typescript",
			"vim",
			"vimdoc",
			"yaml",
			"zig",
		}

		treesitter.setup({})
		vim.treesitter.language.register("json", { "jsonc" })
		vim.g.nightly_treesitter_languages = languages

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("nightly_treesitter", { clear = true }),
			callback = function(event)
				local ok_start = pcall(vim.treesitter.start, event.buf)
				if ok_start and vim.bo[event.buf].buftype == "" then
					vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})

		local ok_textobjects, textobjects = pcall(require, "nvim-treesitter-textobjects")
		if ok_textobjects then
			textobjects.setup({
				select = {
					lookahead = true,
				},
				move = {
					set_jumps = true,
				},
			})

			local select = require("nvim-treesitter-textobjects.select")
			local move = require("nvim-treesitter-textobjects.move")

			vim.keymap.set({ "x", "o" }, "af", function()
				select.select_textobject("@function.outer", "textobjects")
			end, { desc = "Select Function" })
			vim.keymap.set({ "x", "o" }, "if", function()
				select.select_textobject("@function.inner", "textobjects")
			end, { desc = "Select Inner Function" })
			vim.keymap.set({ "x", "o" }, "ac", function()
				select.select_textobject("@class.outer", "textobjects")
			end, { desc = "Select Class" })
			vim.keymap.set({ "x", "o" }, "ic", function()
				select.select_textobject("@class.inner", "textobjects")
			end, { desc = "Select Inner Class" })
			vim.keymap.set({ "x", "o" }, "aa", function()
				select.select_textobject("@parameter.outer", "textobjects")
			end, { desc = "Select Parameter" })
			vim.keymap.set({ "x", "o" }, "ia", function()
				select.select_textobject("@parameter.inner", "textobjects")
			end, { desc = "Select Inner Parameter" })

			vim.keymap.set({ "n", "x", "o" }, "]f", function()
				move.goto_next_start("@function.outer", "textobjects")
			end, { desc = "Next Function" })
			vim.keymap.set({ "n", "x", "o" }, "[f", function()
				move.goto_previous_start("@function.outer", "textobjects")
			end, { desc = "Prev Function" })
			vim.keymap.set({ "n", "x", "o" }, "]C", function()
				move.goto_next_start("@class.outer", "textobjects")
			end, { desc = "Next Class" })
			vim.keymap.set({ "n", "x", "o" }, "[C", function()
				move.goto_previous_start("@class.outer", "textobjects")
			end, { desc = "Prev Class" })
			vim.keymap.set({ "n", "x", "o" }, "]a", function()
				move.goto_next_start("@parameter.inner", "textobjects")
			end, { desc = "Next Parameter" })
			vim.keymap.set({ "n", "x", "o" }, "[a", function()
				move.goto_previous_start("@parameter.inner", "textobjects")
			end, { desc = "Prev Parameter" })
		end
	else
		vim.schedule(function()
			vim.notify("nvim-treesitter is still installing; restart Neovim to enable Treesitter", vim.log.levels.WARN)
		end)
	end
end

------------------------------------------------------------
-- Mini Plugins
------------------------------------------------------------
do
	local ai = require("mini.ai")
	local hipatterns = require("mini.hipatterns")
	local snippets = require("mini.snippets")

	local function mini_pairs_mapping(action, pair, neigh_pattern, opts)
		return vim.tbl_extend("force", {
			action = action,
			pair = pair,
			neigh_pattern = neigh_pattern,
		}, opts or {})
	end

	-- Text editing
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
	snippets.setup({
		mappings = {
			expand = "<M-j>",
			jump_next = "<C-l>",
			jump_prev = "<C-h>",
			stop = "<C-c>",
		},
		snippets = {
			snippets.gen_loader.from_lang(),
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

	-- Workflow
	require("mini.diff").setup({
		view = {
			style = "sign",
			signs = { add = "+", change = "~", delete = "-" },
		},
	})
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

	-- Appearance
	require("mini.icons").setup()
	require("mini.notify").setup()
	require("mini.statusline").setup()
end

------------------------------------------------------------
-- nvim-cmp
------------------------------------------------------------
do
	local ok, cmp = pcall(require, "cmp")
	if ok then
		cmp.setup({
			snippet = {
				expand = function(args)
					local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
					insert({ body = args.body })
					cmp.resubscribe({ "TextChangedI", "TextChangedP" })
					require("cmp.config").set_onetime({ sources = {} })
				end,
			},
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "mini_snippets" },
			}, {
				{ name = "buffer", keyword_length = 3 },
				{ name = "path" },
			}),
			mapping = cmp.mapping.preset.insert({
				["<C-n>"] = cmp.mapping.select_next_item(),
				["<C-p>"] = cmp.mapping.select_prev_item(),
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({ select = true }),
				["<Tab>"] = cmp.mapping(function(fallback)
					if vim.lsp.inline_completion and vim.lsp.inline_completion.get and vim.lsp.inline_completion.get() then
						vim.lsp.inline_completion.accept()
					elseif cmp.visible() then
						cmp.select_next_item()
					else
						fallback()
					end
				end, { "i", "s" }),
				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					else
						fallback()
					end
				end, { "i", "s" }),
			}),
			formatting = {
				format = function(entry, vim_item)
					vim_item.menu = ({
						nvim_lsp = "[LSP]",
						mini_snippets = "[Snip]",
						buffer = "[Buf]",
						path = "[Path]",
					})[entry.source.name]
					return vim_item
				end,
			},
			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},
		})
	else
		vim.schedule(function()
			vim.notify("nvim-cmp is still installing; restart Neovim to enable completion", vim.log.levels.WARN)
		end)
	end
end

------------------------------------------------------------
-- which-key.nvim
------------------------------------------------------------
require("which-key").setup({
	preset = "helix",
	delay = 200,
	plugins = {
		marks = true,
		registers = true,
		spelling = {
			enabled = true,
			suggestions = 20,
		},
		presets = {
			operators = true,
			motions = true,
			text_objects = true,
			windows = true,
			nav = true,
			z = true,
			g = true,
		},
	},
	triggers = {
		-- Auto triggers cover plugin and user mappings; built-ins still need manual entries.
		{ "<auto>", mode = "nixsotc" },
		{ "'", mode = { "n", "x" } },
		{ "`", mode = { "n", "x" } },
		{ '"', mode = { "n", "x" } },
		{ "<C-r>", mode = { "i", "c" } },
		{ "<C-w>", mode = "n" },
		{ "<C-x>", mode = "i" },
		{ "[", mode = "n" },
		{ "]", mode = "n" },
		{ "g", mode = { "n", "x" } },
		{ "z", mode = { "n", "x" } },
	},
	spec = {
		{ "[", group = "prev" },
		{ "]", group = "next" },
		{ "g", group = "goto" },
		{ "gs", group = "surround" },
		{ "z", group = "fold/spell" },
		{ "<C-w>", group = "windows" },
		{ "<C-x>", group = "completion", mode = "i" },
	},
})

------------------------------------------------------------
-- snacks.nvim
------------------------------------------------------------
require("snacks").setup({
	input = { enabled = true },
	notifier = { enabled = true },
	picker = { enabled = true },
})

------------------------------------------------------------
-- yazi.nvim
------------------------------------------------------------
require("yazi").setup({
	open_for_directories = true,
	integrations = {
		grep_in_directory = "snacks.picker",
		grep_in_selected_files = "snacks.picker",
		picker_add_copy_relative_path_action = "snacks.picker",
	},
})

------------------------------------------------------------
-- flash.nvim
------------------------------------------------------------
require("flash").setup({
	modes = {
		search = { enabled = false },
		char = { enabled = false },
	},
})

------------------------------------------------------------
-- Keymaps
------------------------------------------------------------
vim.keymap.set("n", "<C-s>", "<Cmd>write<CR>", { desc = "Save buffer" })
vim.keymap.set("i", "<C-s>", "<C-o><Cmd>write<CR>", { desc = "Save buffer" })
vim.keymap.set("x", "<C-s>", "<Esc><Cmd>write<CR>gv", { desc = "Save buffer" })
vim.keymap.set("n", "<leader>?", function()
	require("which-key").show({ global = false })
end, { desc = "Buffer local keymaps" })
vim.keymap.set("n", "<leader><space>", function()
	require("snacks").picker.files()
end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>,", function()
	require("snacks").picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>/", function()
	require("snacks").picker.grep()
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>ff", function()
	require("snacks").picker.files()
end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fb", function()
	require("snacks").picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fr", function()
	require("snacks").picker.recent()
end, { desc = "Recent Files" })
vim.keymap.set("n", "<leader>fg", function()
	require("snacks").picker.git_files()
end, { desc = "Git Files" })
vim.keymap.set({ "n", "v" }, "<leader>-", "<Cmd>Yazi<CR>", { desc = "Yazi" })
vim.keymap.set({ "n", "v" }, "<leader>e", "<Cmd>Yazi<CR>", { desc = "Yazi" })
vim.keymap.set("n", "<leader>E", "<Cmd>Yazi cwd<CR>", { desc = "Yazi (cwd)" })
vim.keymap.set("n", "<C-Up>", "<Cmd>Yazi toggle<CR>", { desc = "Resume Yazi" })

-- Enter aliases for terminals and keyboards that don't send plain <CR>.
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

vim.keymap.set({ "n", "x", "o" }, "s", function()
	require("flash").jump()
end, { desc = "Flash" })
vim.keymap.set({ "n", "x", "o" }, "S", function()
	require("flash").treesitter()
end, { desc = "Flash Treesitter" })
vim.keymap.set("o", "r", function()
	require("flash").remote()
end, { desc = "Remote Flash" })
vim.keymap.set({ "o", "x" }, "R", function()
	require("flash").treesitter_search()
end, { desc = "Treesitter Search" })

------------------------------------------------------------
-- Debug
------------------------------------------------------------
vim.api.nvim_create_user_command("NightlyInspectKey", function()
	vim.api.nvim_echo({ { "Press a key to inspect...", "Question" } }, false, {})

	local key = vim.fn.getcharstr()
	local bytes = {}
	for i = 1, #key do
		bytes[#bytes + 1] = string.byte(key, i)
	end

	vim.notify(
		string.format(
			"keytrans=%s raw=%s bytes=%s",
			vim.inspect(vim.fn.keytrans(key)),
			vim.inspect(key),
			vim.inspect(bytes)
		),
		vim.log.levels.INFO,
		{ title = "NightlyInspectKey" }
	)
end, { desc = "Inspect the next key Neovim receives" })

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
		snacks = true,
		treesitter = true,
		flash = true,
		which_key = true,
	},
})

vim.cmd.colorscheme("catppuccin")

------------------------------------------------------------
-- avante.nvim
------------------------------------------------------------
do
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
