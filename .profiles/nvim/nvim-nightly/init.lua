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

-- Keep netrw available for scp:// and sftp:// editing from Yazi VFS.
-- Leader }}}

------------------------------------------------------------
-- Options
------------------------------------------------------------
do -- {{{1
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
	if vim.env.SSH_CONNECTION then
		vim.g.clipboard = "osc52"
	else
		opt.clipboard = "unnamedplus"
	end
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
-- Prose Buffers
------------------------------------------------------------
do -- {{{1
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("nightly_wrap_spell", { clear = true }),
		pattern = { "text", "mail", "plaintex", "typst", "gitcommit", "markdown" },
		callback = function()
			vim.opt_local.wrap = true
			vim.opt_local.linebreak = true
			vim.opt_local.breakindent = true
			vim.opt_local.spell = true
		end,
	})
end
-- Prose Buffers }}}

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

		-- UI
		gh("akinsho/bufferline.nvim"),

		-- Treesitter
		gh("nvim-treesitter/nvim-treesitter"),
		gh("nvim-treesitter/nvim-treesitter-textobjects"),

		-- LSP
		gh("neovim/nvim-lspconfig"),
		gh("b0o/SchemaStore.nvim"),

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
		gh("cosmicbuffalo/eyeliner.nvim"),
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
-- Pack Management
------------------------------------------------------------
do -- {{{1
	local function pack_args(command)
		return #command.fargs > 0 and command.fargs or nil
	end

	local function pack_names(arg_lead)
		local ok, plugins = pcall(vim.pack.get, nil, { info = false })
		if not ok then
			return {}
		end

		local names = vim
			.iter(plugins)
			:map(function(plugin)
				return plugin.spec.name
			end)
			:filter(function(name)
				return name:find("^" .. vim.pesc(arg_lead)) ~= nil
			end)
			:totable()
		table.sort(names)
		return names
	end

	local function pack_command_alias(alias, command)
		vim.cmd(
			("cnoreabbrev <expr> %s getcmdtype() ==# ':' && getcmdline() ==# %q ? %q : %q"):format(
				alias,
				alias,
				command,
				alias
			)
		)
	end

	vim.api.nvim_create_user_command("PackUpdate", function(command)
		vim.pack.update(pack_args(command), { force = command.bang })
	end, {
		bang = true,
		complete = pack_names,
		desc = "Update vim.pack plugins; ! applies without confirmation",
		nargs = "*",
	})

	vim.api.nvim_create_user_command("PackStatus", function(command)
		vim.pack.update(pack_args(command), { offline = true, force = command.bang })
	end, {
		bang = true,
		complete = pack_names,
		desc = "Open vim.pack status without fetching; ! applies queued local changes",
		nargs = "*",
	})

	vim.api.nvim_create_user_command("PackLockfile", function(command)
		vim.pack.update(pack_args(command), { target = "lockfile", force = command.bang })
	end, {
		bang = true,
		complete = pack_names,
		desc = "Sync vim.pack plugins to lockfile revisions; ! applies without confirmation",
		nargs = "*",
	})

	vim.api.nvim_create_user_command("PackDelete", function(command)
		vim.pack.del(command.fargs, { force = command.bang })
	end, {
		bang = true,
		complete = pack_names,
		desc = "Delete vim.pack plugins from disk; ! allows active plugins",
		nargs = "+",
	})

	vim.api.nvim_create_user_command("PackLog", function()
		vim.cmd.edit(vim.fs.joinpath(vim.fn.stdpath("log"), "nvim-pack.log"))
	end, { desc = "Open the vim.pack log" })

	pack_command_alias("packupdate", "PackUpdate")
	pack_command_alias("packstatus", "PackStatus")
	pack_command_alias("packlockfile", "PackLockfile")
	pack_command_alias("packdelete", "PackDelete")
	pack_command_alias("packlog", "PackLog")
end
-- Pack Management }}}

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
			local function textobject_move(callback)
				return function()
					local ok, parser = pcall(vim.treesitter.get_parser, 0)
					if not ok or not parser then
						return
					end
					callback()
				end
			end

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

			vim.keymap.set({ "n", "x", "o" }, "]f", textobject_move(function()
				move.goto_next_start("@function.outer", "textobjects")
			end), { desc = "Next Function" })
			vim.keymap.set({ "n", "x", "o" }, "[f", textobject_move(function()
				move.goto_previous_start("@function.outer", "textobjects")
			end), { desc = "Prev Function" })
			vim.keymap.set({ "n", "x", "o" }, "]C", textobject_move(function()
				move.goto_next_start("@class.outer", "textobjects")
			end), { desc = "Next Class" })
			vim.keymap.set({ "n", "x", "o" }, "[C", textobject_move(function()
				move.goto_previous_start("@class.outer", "textobjects")
			end), { desc = "Prev Class" })
			vim.keymap.set({ "n", "x", "o" }, "]a", textobject_move(function()
				move.goto_next_start("@parameter.inner", "textobjects")
			end), { desc = "Next Parameter" })
			vim.keymap.set({ "n", "x", "o" }, "[a", textobject_move(function()
				move.goto_previous_start("@parameter.inner", "textobjects")
			end), { desc = "Prev Parameter" })
		end
	else
		vim.schedule(function()
			vim.notify("nvim-treesitter is still installing; restart Neovim to enable Treesitter", vim.log.levels.WARN)
		end)
	end
end
-- Treesitter }}}

------------------------------------------------------------
-- LSP
------------------------------------------------------------
do -- {{{1
	local mason_bin_dir = vim.fn.stdpath("data") .. "/mason/bin"
	if
		vim.fn.isdirectory(mason_bin_dir) == 1
		and not vim.tbl_contains(vim.split(vim.env.PATH or "", ":", { plain = true }), mason_bin_dir)
	then
		vim.env.PATH = mason_bin_dir .. ":" .. vim.env.PATH
	end

	local capabilities = vim.lsp.protocol.make_client_capabilities()
	local ok_cmp_lsp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
	if ok_cmp_lsp then
		capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
	end

	local json_schemas = {}
	local yaml_schemas = {}
	local ok_schemastore, schemastore = pcall(require, "schemastore")
	if ok_schemastore then
		json_schemas = schemastore.json.schemas()
		yaml_schemas = schemastore.yaml.schemas()
	end

	vim.filetype.add({
		filename = {
			["compose.yaml"] = "yaml.docker-compose",
			["compose.yml"] = "yaml.docker-compose",
			["docker-compose.yaml"] = "yaml.docker-compose",
			["docker-compose.yml"] = "yaml.docker-compose",
		},
	})

	local function enable_lsp(name, executable, opts)
		if executable and vim.fn.executable(executable) ~= 1 then
			return
		end

		vim.lsp.config(name, vim.tbl_deep_extend("force", { capabilities = capabilities }, opts or {}))
		vim.lsp.enable(name)
	end

	local function command_succeeds(cmd)
		local ok, result = pcall(function()
			return vim.system(cmd, { text = true }):wait()
		end)

		return ok and result and result.code == 0
	end

	local function rust_analyzer_cmd()
		if vim.fn.executable("rust-analyzer") == 1 and command_succeeds({ "rust-analyzer", "--version" }) then
			return { "rust-analyzer" }
		end

		if vim.fn.executable("rustup") == 1 and command_succeeds({ "rustup", "+stable", "which", "rust-analyzer" }) then
			return { "rustup", "run", "stable", "rust-analyzer" }
		end
	end

	enable_lsp("jsonls", "vscode-json-language-server", {
		filetypes = { "json", "jsonc" },
		init_options = {
			provideFormatter = true,
		},
		settings = {
			json = {
				schemas = json_schemas,
				validate = { enable = true },
			},
		},
	})

	enable_lsp("lua_ls", "lua-language-server", {
		settings = {
			Lua = {
				runtime = { version = "LuaJIT" },
				diagnostics = { globals = { "vim" } },
				workspace = { checkThirdParty = false },
				telemetry = { enable = false },
			},
		},
	})

	enable_lsp("gopls", "gopls", {
		settings = {
			gopls = {
				analyses = { unusedparams = true },
				staticcheck = true,
			},
		},
	})

	local rust_analyzer = rust_analyzer_cmd()
	if rust_analyzer then
		enable_lsp("rust_analyzer", nil, {
			cmd = rust_analyzer,
		})
	end

	enable_lsp("ts_ls", "typescript-language-server", {
		settings = {
			javascript = {
				inlayHints = {
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayParameterNameHints = "all",
					includeInlayPropertyDeclarationTypeHints = true,
				},
			},
			typescript = {
				inlayHints = {
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayParameterNameHints = "all",
					includeInlayPropertyDeclarationTypeHints = true,
				},
			},
		},
	})

	enable_lsp("jdtls", "jdtls")

	enable_lsp("yamlls", "yaml-language-server", {
		settings = {
			yaml = {
				completion = true,
				hover = true,
				schemaStore = {
					enable = false,
					url = "",
				},
				schemas = yaml_schemas,
				validate = true,
			},
		},
	})

	enable_lsp("taplo", "taplo")
	enable_lsp("dockerls", "docker-langserver")
	enable_lsp("docker_compose_language_service", "docker-compose-langserver")
	enable_lsp("terraformls", "terraform-ls")
	enable_lsp("tofu_ls", "tofu-ls")
	enable_lsp("tflint", "tflint")
	enable_lsp("bashls", "bash-language-server")
	enable_lsp("marksman", "marksman")
	enable_lsp("nil_ls", "nil")
	enable_lsp("zls", "zls")
	enable_lsp("helm_ls", "helm_ls")
	enable_lsp("ansiblels", "ansible-language-server")
end
-- LSP }}}

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

	-- Keep one insert-mode Enter owner: completion first, then MiniPairs.
	local function nightly_insert_enter()
		local ok_cmp, cmp = pcall(require, "cmp")
		if ok_cmp and cmp.visible() then
			return vim.api.nvim_replace_termcodes("<Cmd>lua require('cmp').confirm({ select = true })<CR>", true, false, true)
		end

		if _G.MiniPairs and type(MiniPairs.cr) == "function" then
			return MiniPairs.cr()
		end

		return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
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
	vim.keymap.set("i", "<CR>", nightly_insert_enter, {
		expr = true,
		replace_keycodes = false,
		desc = "Confirm completion or insert newline",
	})
	vim.keymap.set("i", "<NL>", nightly_insert_enter, {
		expr = true,
		replace_keycodes = false,
		desc = "Confirm completion or insert newline",
	})
	vim.keymap.set("i", "<kEnter>", nightly_insert_enter, {
		expr = true,
		replace_keycodes = false,
		desc = "Confirm completion or insert newline",
	})
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
	require("mini.jump").setup({
		silent = true,
	})
	require("eyeliner").setup({
		default_keymaps = false,
		case_sensitive = false,
		disabled_filetypes = { "help" },
		disabled_buftypes = { "nofile", "prompt", "terminal" },
	})
	vim.api.nvim_create_autocmd("User", {
		group = vim.api.nvim_create_augroup("nightly_eyeliner", { clear = true }),
		pattern = "MiniJumpGetTarget",
		callback = function()
			if vim.b.eyelinerDisabled then
				return
			end

			require("eyeliner").highlight({
				forward = not MiniJump.state.backward,
				case_sensitive = not vim.o.ignorecase,
			})
		end,
	})

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
		{ "<leader>b", group = "buffer" },
		{ "<leader>S", group = "search" },
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
-- Load netrw's remote protocol handlers before Oil disables its file explorer.
vim.g.netrw_silent = 1
vim.cmd("packadd netrw")
vim.cmd("runtime autoload/netrw.vim")

require("oil").setup({ -- {{{1
	default_file_explorer = true,
	keymaps = {
		["<NL>"] = "actions.select",
		["<kEnter>"] = "actions.select",
	},
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
		if client:supports_method(method, bufnr) then
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

local function nightly_substitute_cword(range, visual)
	local word = vim.fn.expand("<cword>")
	if word == "" then
		return "<Ignore>"
	end

	local pattern = vim.fn.escape(word, [=[\/.*$^~[]]=])
	local prefix = visual and ":<C-u>" or ":"
	local visual_atom = visual and [[\%V]] or ""
	return ("%s%ss/%s\\<%s\\>//gI<Left><Left><Left>"):format(prefix, range, visual_atom, pattern)
end

vim.keymap.set("n", "<leader>s", function()
	return nightly_substitute_cword("%", false)
end, { expr = true, desc = "Substitute word in file" })
vim.keymap.set("x", "<leader>s", function()
	return nightly_substitute_cword([['<,'>]], true)
end, { expr = true, desc = "Substitute word in selection" })
vim.keymap.set("n", "<C-s>", "<Cmd>write<CR>", { desc = "Save buffer" })
vim.keymap.set("i", "<C-s>", "<C-o><Cmd>write<CR>", { desc = "Save buffer" })
vim.keymap.set("x", "<C-s>", "<Esc><Cmd>write<CR>gv", { desc = "Save buffer" })
vim.keymap.set("n", "<leader>?", function()
	require("snacks").picker.keymaps()
end, { desc = "Keymaps" })
vim.keymap.set("n", "<leader><space>", function()
	require("snacks").picker.files()
end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>,", function()
	require("snacks").picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>/", function()
	require("snacks").picker.grep()
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>Sj", function()
	require("snacks").picker.jumps()
end, { desc = "Jumps" })
vim.keymap.set("n", "<leader>Sk", function()
	require("snacks").picker.keymaps()
end, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>St", function()
	require("snacks").picker.treesitter()
end, { desc = "Treesitter Symbols" })
vim.keymap.set("n", "<leader>Ss", nightly_picker_symbols, { desc = "Symbols" })
vim.keymap.set("n", "<leader>SS", nightly_picker_workspace_symbols, { desc = "Workspace Symbols" })
vim.keymap.set("n", "<leader>ff", function()
	require("snacks").picker.files()
end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fb", function()
	require("snacks").picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<S-h>", "<Cmd>bprevious<CR>", { desc = "Prev buffer" })
vim.keymap.set("n", "<S-l>", "<Cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "[b", "<Cmd>bprevious<CR>", { desc = "Prev buffer" })
vim.keymap.set("n", "]b", "<Cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bb", function()
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

vim.keymap.set("i", "kj", "<Esc>", { desc = "Exit insert mode", remap = true })
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

local function nightly_set_mini_jump_highlight()
	local colors = require("catppuccin.palettes").get_palette("mocha")
	vim.api.nvim_set_hl(0, "MiniJump", { fg = colors.text, bg = colors.surface2, bold = true })
end

vim.cmd.colorscheme("catppuccin")
nightly_set_mini_jump_highlight()
vim.api.nvim_create_autocmd("ColorScheme", {
	group = vim.api.nvim_create_augroup("nightly_mini_jump_highlight", { clear = true }),
	pattern = "catppuccin*",
	callback = nightly_set_mini_jump_highlight,
})
-- Colorscheme }}}

------------------------------------------------------------
-- bufferline.nvim
------------------------------------------------------------
do -- {{{1
	local diag_icons = {
		error = " ",
		warning = " ",
	}

	local function bufdelete(bufnr)
		require("mini.bufremove").delete(bufnr, false)
	end

	if vim.F then
		vim.F.if_nil = vim.nonnil
	end

	require("bufferline").setup({
		highlights = require("catppuccin.special.bufferline").get_theme(),
		options = {
			close_command = bufdelete,
			right_mouse_command = bufdelete,
			diagnostics = "nvim_lsp",
			always_show_bufferline = false,
			diagnostics_indicator = function(_, _, diag)
				local parts = {}
				if diag.error and diag.error > 0 then
					parts[#parts + 1] = diag_icons.error .. diag.error
				end
				if diag.warning and diag.warning > 0 then
					parts[#parts + 1] = diag_icons.warning .. diag.warning
				end
				return table.concat(parts, " ")
			end,
			offsets = {
				{
					filetype = "snacks_layout_box",
				},
			},
			---@param opts bufferline.IconFetcherOpts
			get_element_icon = function(opts)
				if _G.MiniIcons then
					local icon, hl = MiniIcons.get("filetype", opts.filetype)
					return icon, hl
				end
			end,
		},
	})

	vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
		group = vim.api.nvim_create_augroup("nightly_bufferline", { clear = true }),
		callback = function()
			vim.schedule(function()
				pcall(vim.cmd.redrawtabline)
			end)
		end,
	})
end
-- bufferline.nvim }}}

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
