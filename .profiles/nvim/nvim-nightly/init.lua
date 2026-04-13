-- ==========================================================================
-- Notes Nightly Neovim Configuration
-- Single-file init.lua using vim.pack
-- ==========================================================================
-- vim: set foldmethod=marker foldlevel=0 foldenable:

------------------------------------------------------------
-- Leader
------------------------------------------------------------
vim.g.mapleader = " " -- {{{1
vim.g.maplocalleader = "\\"

-- Let yazi.nvim take over directory opens like `nvim .`.
vim.g.loaded_netrwPlugin = 1
-- Leader }}}

------------------------------------------------------------
-- Options
------------------------------------------------------------
do -- {{{1
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
	if vim.env.SSH_CONNECTION then
		vim.g.clipboard = "osc52"
	end
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
-- Options }}}

------------------------------------------------------------
-- Packages
------------------------------------------------------------
do -- {{{1
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
		-- { src = gh("yetone/avante.nvim"), name = "avante.nvim" },
		gh("zbirenbaum/copilot.lua"),
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
		gh("monaqa/dial.nvim"),
		gh("gbprod/yanky.nvim"),

		-- Picker
		gh("mikavilpas/yazi.nvim"),
		gh("stevearc/oil.nvim"),

		-- Formatting
		gh("stevearc/conform.nvim"),

		-- Dependencies
		gh("mikesmithgh/kitty-scrollback.nvim"),
		gh("nvim-lua/plenary.nvim"),
		gh("MunifTanjim/nui.nvim"),
		gh("rafamadriz/friendly-snippets"),
	})
end
-- Packages }}}

------------------------------------------------------------
-- Plugin Hooks
------------------------------------------------------------
-- do -- {{{1
-- 	local function build_avante(path)
-- 		if vim.fn.executable("make") ~= 1 then
-- 			vim.schedule(function()
-- 				vim.notify("avante.nvim needs `make` to build", vim.log.levels.WARN)
-- 			end)
-- 			return
-- 		end
--
-- 		local result = vim.system({ "make" }, { cwd = path, text = true }):wait()
-- 		if result.code == 0 then
-- 			return
-- 		end
--
-- 		local output = (result.stderr and result.stderr ~= "") and result.stderr or (result.stdout or "")
-- 		vim.schedule(function()
-- 			vim.notify("Failed to build avante.nvim\n" .. output, vim.log.levels.ERROR)
-- 		end)
-- 	end
--
-- 	vim.api.nvim_create_autocmd("PackChanged", {
-- 		callback = function(event)
-- 			local pack_event = event.data or {}
-- 			local spec = pack_event.spec or {}
-- 			local name = spec.name
-- 			local kind = pack_event.kind
--
-- 			if name == "avante.nvim" and (kind == "install" or kind == "update") then
-- 				build_avante(pack_event.path)
-- 				return
-- 			end
--
-- 			if name == "cord.nvim" and (kind == "install" or kind == "update") then
-- 				vim.schedule(function()
-- 					vim.cmd("Cord update")
-- 				end)
-- 			end
-- 		end,
-- 	})
-- end
-- Plugin Hooks }}}

------------------------------------------------------------
-- Chezmoi
------------------------------------------------------------
do -- {{{1
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
require("kitty-scrollback").setup() -- {{{1
-- kitty-scrollback.nvim }}}

------------------------------------------------------------
-- cord.nvim
------------------------------------------------------------
require("cord").setup({ -- {{{1
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
-- cord.nvim }}}

------------------------------------------------------------
-- Treesitter
------------------------------------------------------------
do -- {{{1
	local ok = pcall(require, "nvim-treesitter")
	if ok then
		local mason_bin_dir = vim.fn.stdpath("data") .. "/mason/bin"
		local tree_sitter_bin = mason_bin_dir .. "/tree-sitter"
		if vim.fn.executable("tree-sitter") == 0 and vim.fn.executable(tree_sitter_bin) == 1 then
			vim.env.PATH = mason_bin_dir .. ":" .. vim.env.PATH
		end

		local function is_lazy_readme_help(bufnr)
			local path = vim.api.nvim_buf_get_name(bufnr)
			local readme_help_dir = vim.fn.stdpath("state") .. "/lazy/readme/doc/"
			return path:find("^" .. vim.pesc(readme_help_dir)) ~= nil
		end

		local languages = {
			"bash",
			"diff",
			"fish",
			"go",
			"git_config",
			"gitcommit",
			"gitignore",
			"hyprlang",
			"javascript",
			"jsdoc",
			"json",
			"kdl",
			"lua",
			"markdown",
			"markdown_inline",
			"nix",
			"nu",
			"query",
			"regex",
			"rust",
			"toml",
			"tmux",
			"tsx",
			"typescript",
			"vim",
			"vimdoc",
			"yaml",
			"zig",
		}

		vim.treesitter.language.register("json", { "jsonc" })

		local configured_languages = {}
		for _, language in ipairs(languages) do
			configured_languages[language] = true
		end

		local function get_treesitter_language(bufnr)
			local filetype = vim.bo[bufnr].filetype
			if filetype == "" then
				return nil
			end

			return vim.treesitter.language.get_lang(filetype) or filetype
		end

		local function has_treesitter_parser(language)
			return language ~= nil and pcall(vim.treesitter.language.inspect, language)
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("nightly_treesitter", { clear = true }),
			callback = function(event)
				local lang = get_treesitter_language(event.buf)
				if
					vim.bo[event.buf].buftype == ""
					and not is_lazy_readme_help(event.buf)
					and configured_languages[lang]
					and has_treesitter_parser(lang)
				then
					pcall(vim.treesitter.start, event.buf)
				end
			end,
		})

		vim.api.nvim_create_user_command("NightlyTreesitterStatus", function()
			local missing = {}
			for _, language in ipairs(languages) do
				if not has_treesitter_parser(language) then
					table.insert(missing, language)
				end
			end

			if #missing == 0 then
				vim.notify("All configured Tree-sitter parsers are available", vim.log.levels.INFO)
				return
			end

			vim.notify(
				"Missing Tree-sitter parsers: " .. table.concat(missing, ", "),
				vim.log.levels.WARN,
				{ title = "NightlyTreesitterStatus" }
			)
		end, { desc = "Show configured Tree-sitter parser coverage" })

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
-- Treesitter }}}

------------------------------------------------------------
-- Mini Plugins
------------------------------------------------------------
do -- {{{1
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
-- Mini Plugins }}}

------------------------------------------------------------
-- AI inline completion
------------------------------------------------------------
do -- {{{1
	local ok, copilot = pcall(require, "copilot")
	if ok then
		copilot.setup({
			panel = {
				enabled = false,
			},
			suggestion = {
				enabled = true,
				auto_trigger = true,
				hide_during_completion = true,
				debounce = 60,
				keymap = {
					accept = "<C-l>",
				},
			},
			filetypes = {
				markdown = false,
				help = false,
				gitcommit = false,
			},
		})
	else
		vim.schedule(function()
			vim.notify(
				"copilot.lua is still installing; restart Neovim to enable AI inline completion",
				vim.log.levels.WARN
			)
		end)
	end
end
-- AI inline completion }}}

------------------------------------------------------------
-- nvim-cmp
------------------------------------------------------------
do -- {{{1
	local ok, cmp = pcall(require, "cmp")
	if ok then
		local has_copilot_suggestion, copilot_suggestion = pcall(require, "copilot.suggestion")
		local primary_sources = {
			{ name = "nvim_lsp" },
			{ name = "mini_snippets" },
		}

		cmp.setup({
			snippet = {
				expand = function(args)
					local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
					insert({ body = args.body })
					cmp.resubscribe({ "TextChangedI", "TextChangedP" })
					require("cmp.config").set_onetime({ sources = {} })
				end,
			},
			sources = cmp.config.sources(primary_sources, {
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
					if has_copilot_suggestion and copilot_suggestion.is_visible() then
						copilot_suggestion.accept()
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

		if has_copilot_suggestion then
			cmp.event:on("menu_opened", function()
				vim.b.copilot_suggestion_hidden = true
			end)

			cmp.event:on("menu_closed", function()
				vim.b.copilot_suggestion_hidden = false
			end)
		end
	else
		vim.schedule(function()
			vim.notify("nvim-cmp is still installing; restart Neovim to enable completion", vim.log.levels.WARN)
		end)
	end
end
-- nvim-cmp }}}

------------------------------------------------------------
-- which-key.nvim
------------------------------------------------------------
require("which-key").setup({ -- {{{1
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
		{ "<leader>s", group = "search" },
		{ "[", group = "prev" },
		{ "]", group = "next" },
		{ "g", group = "goto" },
		{ "gs", group = "surround" },
		{ "z", group = "fold/spell" },
		{ "<C-w>", group = "windows" },
		{ "<C-x>", group = "completion", mode = "i" },
	},
})
-- which-key.nvim }}}

------------------------------------------------------------
-- dial.nvim
------------------------------------------------------------
local function dial(increment, g) -- {{{1
	local mode = vim.fn.mode(true)
	local is_visual = mode == "v" or mode == "V" or mode == "\22"
	local func = (increment and "inc" or "dec") .. (g and "_g" or "_") .. (is_visual and "visual" or "normal")
	local group = (vim.g.dials_by_ft or {})[vim.bo.filetype] or "default"
	return require("dial.map")[func](group)
end

do
	local augend = require("dial.augend")
	local logical_alias = augend.constant.new({
		elements = { "&&", "||" },
		word = false,
		cyclic = true,
	})
	local ordinal_numbers = augend.constant.new({
		elements = {
			"first",
			"second",
			"third",
			"fourth",
			"fifth",
			"sixth",
			"seventh",
			"eighth",
			"ninth",
			"tenth",
		},
		word = false,
		cyclic = true,
	})
	local months = augend.constant.new({
		elements = {
			"January",
			"February",
			"March",
			"April",
			"May",
			"June",
			"July",
			"August",
			"September",
			"October",
			"November",
			"December",
		},
		word = true,
		cyclic = true,
	})
	local dials_by_ft = {
		css = "css",
		javascript = "typescript",
		javascriptreact = "typescript",
		json = "json",
		lua = "lua",
		markdown = "markdown",
		python = "python",
		sass = "css",
		scss = "css",
		typescript = "typescript",
		typescriptreact = "typescript",
		vue = "vue",
	}
	local groups = {
		default = {
			augend.integer.alias.decimal,
			augend.integer.alias.decimal_int,
			augend.integer.alias.hex,
			augend.date.alias["%Y/%m/%d"],
			augend.constant.alias.en_weekday,
			augend.constant.alias.en_weekday_full,
			ordinal_numbers,
			months,
			augend.constant.alias.bool,
			augend.constant.alias.Bool,
			logical_alias,
		},
		vue = {
			augend.constant.new({ elements = { "let", "const" } }),
			augend.hexcolor.new({ case = "lower" }),
			augend.hexcolor.new({ case = "upper" }),
		},
		typescript = {
			augend.constant.new({ elements = { "let", "const" } }),
		},
		css = {
			augend.hexcolor.new({ case = "lower" }),
			augend.hexcolor.new({ case = "upper" }),
		},
		markdown = {
			augend.constant.new({
				elements = { "[ ]", "[x]" },
				word = false,
				cyclic = true,
			}),
			augend.misc.alias.markdown_header,
		},
		json = {
			augend.semver.alias.semver,
		},
		lua = {
			augend.constant.new({
				elements = { "and", "or" },
				word = true,
				cyclic = true,
			}),
		},
		python = {
			augend.constant.new({
				elements = { "and", "or" },
			}),
		},
	}

	for name, group in pairs(groups) do
		if name ~= "default" then
			vim.list_extend(group, groups.default)
		end
	end

	require("dial.config").augends:register_group(groups)
	vim.g.dials_by_ft = dials_by_ft
end
-- dial.nvim }}}

------------------------------------------------------------
-- yanky.nvim
------------------------------------------------------------
require("yanky").setup({ -- {{{1
	system_clipboard = {
		sync_with_ring = not vim.env.SSH_CONNECTION,
	},
	highlight = {
		timer = 150,
	},
})
-- yanky.nvim }}}

------------------------------------------------------------
-- snacks.nvim
------------------------------------------------------------
require("snacks").setup({ -- {{{1
	indent = { enabled = true },
	input = { enabled = true },
	notifier = { enabled = true },
	picker = {
		enabled = true,
		win = {
			input = {
				keys = {
					["<NL>"] = { "confirm", mode = { "n", "i" } },
					["<kEnter>"] = { "confirm", mode = { "n", "i" } },
				},
			},
			list = {
				keys = {
					["<NL>"] = "confirm",
					["<kEnter>"] = "confirm",
				},
			},
		},
	},
	scope = { enabled = true },
	words = { enabled = true },
})
-- snacks.nvim }}}

------------------------------------------------------------
-- yazi.nvim
------------------------------------------------------------
require("yazi").setup({ -- {{{1
	open_for_directories = false,
	integrations = {
		grep_in_directory = "snacks.picker",
		grep_in_selected_files = "snacks.picker",
		picker_add_copy_relative_path_action = "snacks.picker",
	},
})
-- yazi.nvim }}}

------------------------------------------------------------
-- oil.nvim
------------------------------------------------------------
require("oil").setup({ -- {{{1
	default_file_explorer = true,
})
-- oil.nvim }}}

------------------------------------------------------------
-- flash.nvim
------------------------------------------------------------
require("flash").setup({ -- {{{1
	modes = {
		search = { enabled = false },
		char = { enabled = false },
	},
})
-- flash.nvim }}}

------------------------------------------------------------
-- Keymaps
------------------------------------------------------------
local function nightly_lsp_supports(method, bufnr) -- {{{1
	bufnr = bufnr or 0
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		if client.supports_method(method) then
			return true
		end
	end
	return false
end

local function nightly_picker_symbols()
	if nightly_lsp_supports("textDocument/documentSymbol") then
		require("snacks").picker.lsp_symbols()
		return
	end

	require("snacks").picker.treesitter()
end

local function nightly_picker_workspace_symbols()
	if nightly_lsp_supports("workspace/symbol") then
		require("snacks").picker.lsp_workspace_symbols()
		return
	end

	vim.notify("No attached LSP client with workspace symbol support", vim.log.levels.WARN)
end

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
vim.keymap.set("n", "<leader>sj", function()
	require("snacks").picker.jumps()
end, { desc = "Jumps" })
vim.keymap.set("n", "<leader>st", function()
	require("snacks").picker.treesitter()
end, { desc = "Treesitter Symbols" })
vim.keymap.set("n", "<leader>ss", nightly_picker_symbols, { desc = "Symbols" })
vim.keymap.set("n", "<leader>sS", nightly_picker_workspace_symbols, { desc = "Workspace Symbols" })
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
vim.keymap.set({ "n", "x" }, "<leader>p", function()
	local ok, snacks = pcall(require, "snacks")
	if ok and snacks.picker and snacks.picker.yanky then
		snacks.picker.yanky()
	else
		vim.cmd("YankyRingHistory")
	end
end, { desc = "Open Yank History" })
vim.keymap.set({ "n", "v" }, "<C-a>", function()
	return dial(true)
end, { expr = true, desc = "Increment" })
vim.keymap.set({ "n", "v" }, "<C-x>", function()
	return dial(false)
end, { expr = true, desc = "Decrement" })
vim.keymap.set({ "n", "x" }, "g<C-a>", function()
	return dial(true, true)
end, { expr = true, desc = "Increment (g)" })
vim.keymap.set({ "n", "x" }, "g<C-x>", function()
	return dial(false, true)
end, { expr = true, desc = "Decrement (g)" })
vim.keymap.set({ "n", "x" }, "y", "<Plug>(YankyYank)", { desc = "Yank Text" })
vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)", { desc = "Put Text After Cursor" })
vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)", { desc = "Put Text Before Cursor" })
vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)", { desc = "Put Text After Selection" })
vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)", { desc = "Put Text Before Selection" })
vim.keymap.set("n", "[y", "<Plug>(YankyCycleForward)", { desc = "Cycle Forward Through Yank History" })
vim.keymap.set("n", "]y", "<Plug>(YankyCycleBackward)", { desc = "Cycle Backward Through Yank History" })
vim.keymap.set("n", "]p", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "Put Indented After Cursor (Linewise)" })
vim.keymap.set("n", "[p", "<Plug>(YankyPutIndentBeforeLinewise)", { desc = "Put Indented Before Cursor (Linewise)" })
vim.keymap.set("n", "]P", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "Put Indented After Cursor (Linewise)" })
vim.keymap.set("n", "[P", "<Plug>(YankyPutIndentBeforeLinewise)", { desc = "Put Indented Before Cursor (Linewise)" })
vim.keymap.set({ "x", "o" }, "ii", function()
	require("snacks").scope.textobject({
		min_size = 2,
		edge = false,
		cursor = false,
		treesitter = { blocks = { enabled = false } },
	})
end, { desc = "Inner Scope" })
vim.keymap.set({ "x", "o" }, "ai", function()
	require("snacks").scope.textobject({
		cursor = false,
		min_size = 2,
		treesitter = { blocks = { enabled = false } },
	})
end, { desc = "Around Scope" })
vim.keymap.set({ "n", "x", "o" }, "[i", function()
	require("snacks").scope.jump({
		min_size = 1,
		bottom = false,
		cursor = false,
		edge = true,
		treesitter = { blocks = { enabled = false } },
	})
end, { desc = "Scope Top" })
vim.keymap.set({ "n", "x", "o" }, "]i", function()
	require("snacks").scope.jump({
		min_size = 1,
		bottom = true,
		cursor = false,
		edge = true,
		treesitter = { blocks = { enabled = false } },
	})
end, { desc = "Scope Bottom" })
vim.keymap.set({ "n", "t" }, "]]", function()
	require("snacks").words.jump(vim.v.count1)
end, { desc = "Next Reference" })
vim.keymap.set({ "n", "t" }, "[[", function()
	require("snacks").words.jump(-vim.v.count1)
end, { desc = "Prev Reference" })
vim.keymap.set("n", ">p", "<Plug>(YankyPutIndentAfterShiftRight)", { desc = "Put and Indent Right" })
vim.keymap.set("n", "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", { desc = "Put and Indent Left" })
vim.keymap.set("n", ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", { desc = "Put Before and Indent Right" })
vim.keymap.set("n", "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", { desc = "Put Before and Indent Left" })
vim.keymap.set("n", "=p", "<Plug>(YankyPutAfterFilter)", { desc = "Put After Applying a Filter" })
vim.keymap.set("n", "=P", "<Plug>(YankyPutBeforeFilter)", { desc = "Put Before Applying a Filter" })
-- vim.keymap.set({ "n", "v" }, "<leader>-", "<Cmd>Yazi<CR>", { desc = "Yazi" })
vim.keymap.set({ "n", "v" }, "<leader>e", "<Cmd>Yazi<CR>", { desc = "Yazi" })
vim.keymap.set("n", "<leader>E", "<Cmd>Yazi cwd<CR>", { desc = "Yazi (cwd)" })
vim.keymap.set("n", "<C-Up>", "<Cmd>Yazi toggle<CR>", { desc = "Resume Yazi" })
vim.keymap.set({ "n", "v" }, "<leader>-", "<Cmd>Oil<CR>", { desc = "Oil" })
vim.keymap.set("n", "gd", function()
	require("snacks").picker.lsp_definitions()
end, { desc = "Goto Definition" })
vim.keymap.set("n", "gD", function()
	require("snacks").picker.lsp_declarations()
end, { desc = "Goto Declaration" })
vim.keymap.set("n", "gr", function()
	require("snacks").picker.lsp_references()
end, { nowait = true, desc = "References" })
vim.keymap.set("n", "gI", function()
	require("snacks").picker.lsp_implementations()
end, { desc = "Goto Implementation" })
vim.keymap.set("n", "gy", function()
	require("snacks").picker.lsp_type_definitions()
end, { desc = "Goto Type Definition" })

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
-- Keymaps }}}

------------------------------------------------------------
-- Debug
------------------------------------------------------------
vim.api.nvim_create_user_command("NightlyInspectKey", function() -- {{{1
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
-- Debug }}}

------------------------------------------------------------
-- Formatting
------------------------------------------------------------
require("conform").setup({ -- {{{1
	formatters_by_ft = {
		lua = { "stylua" },
		rust = { "rustfmt", lsp_format = "fallback" },
	},
	format_on_save = {
		timeout_ms = 1000,
	},
})
-- Formatting }}}

------------------------------------------------------------
-- Colorscheme
------------------------------------------------------------
require("catppuccin").setup({ -- {{{1
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
-- Colorscheme }}}

------------------------------------------------------------
-- avante.nvim
------------------------------------------------------------
-- do -- {{{1
-- 	require("avante").setup({
-- 		provider = "codex",
-- 		behaviour = {
-- 			auto_suggestions = false,
-- 		},
-- 		acp_providers = {
-- 			codex = {
-- 				command = "codex-acp",
-- 				args = {},
-- 				env = {
-- 					NODE_NO_WARNINGS = "1",
-- 					HOME = os.getenv("HOME"),
-- 					PATH = os.getenv("PATH"),
-- 				},
-- 			},
-- 		},
-- 	})
--
-- 	local avante = require("avante")
-- 	local acp_config_selector = require("avante.acp_config_selector")
-- 	local original_open = acp_config_selector.open
--
-- 	acp_config_selector.open = function(category, prompt_label)
-- 		local sidebar = avante.get(false)
-- 		if not sidebar or not sidebar:is_open() then
-- 			avante.open_sidebar({ ask = false })
-- 			sidebar = avante.get(false)
-- 		end
--
-- 		if not sidebar or not sidebar:is_open() then
-- 			vim.notify("Unable to open Avante sidebar for ACP selection", vim.log.levels.WARN)
-- 			return
-- 		end
--
-- 		return original_open(category, prompt_label)
-- 	end
-- end
-- avante.nvim }}}
