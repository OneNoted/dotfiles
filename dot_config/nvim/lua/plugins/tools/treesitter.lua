-- Treesitter: AST-based syntax highlighting, indentation, and text objects
-- Foundation for all code intelligence features
-- Silly LLM written comments
local function is_lazy_readme_help(bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)
	local readme_help_dir = vim.fn.stdpath("state") .. "/lazy/readme/doc/"
	return path:find("^" .. vim.pesc(readme_help_dir)) ~= nil
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		version = false, -- main branch
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		config = function()
			-- Use treesitter.configs.setup(), NOT treesitter.setup()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					-- Target languages
					"rust",
					"go",
					"nix",
					"yaml",
					"toml",
					"zig",
					-- Git-related
					"git_config",
					"gitcommit",
					"git_rebase",
					"gitignore",
					"diff",
					-- Core
					"lua",
					"vim",
					"vimdoc",
					"query",
					"regex",
					-- Common languages
					"bash",
					"markdown",
					"markdown_inline",
					"json",
					"jsonc",
				},
				highlight = {
					enable = true,
					disable = function(_, bufnr)
						return is_lazy_readme_help(bufnr)
					end,
				},
				indent = {
					enable = true,
				},
				textobjects = {
					select = {
						enable = true,
						lookahead = true, -- Automatically jump to next textobject
						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
							["aa"] = "@parameter.outer",
							["ia"] = "@parameter.inner",
						},
					},
					move = {
						enable = true,
						set_jumps = true, -- Add to jumplist
					},
				},
			})

			local ok_move, move = pcall(require, "nvim-treesitter-textobjects.move")
			if ok_move then
				local function textobject_move(callback)
					return function()
						local ok, parser = pcall(vim.treesitter.get_parser, 0)
						if not ok or not parser then
							return
						end
						callback()
					end
				end

				vim.keymap.set(
					{ "n", "x", "o" },
					"]f",
					textobject_move(function()
						move.goto_next_start("@function.outer", "textobjects")
					end),
					{ desc = "Next Function" }
				)
				vim.keymap.set(
					{ "n", "x", "o" },
					"[f",
					textobject_move(function()
						move.goto_previous_start("@function.outer", "textobjects")
					end),
					{ desc = "Prev Function" }
				)
				vim.keymap.set(
					{ "n", "x", "o" },
					"]C",
					textobject_move(function()
						move.goto_next_start("@class.outer", "textobjects")
					end),
					{ desc = "Next Class" }
				)
				vim.keymap.set(
					{ "n", "x", "o" },
					"[C",
					textobject_move(function()
						move.goto_previous_start("@class.outer", "textobjects")
					end),
					{ desc = "Prev Class" }
				)
				vim.keymap.set(
					{ "n", "x", "o" },
					"]a",
					textobject_move(function()
						move.goto_next_start("@parameter.inner", "textobjects")
					end),
					{ desc = "Next Parameter" }
				)
				vim.keymap.set(
					{ "n", "x", "o" },
					"[a",
					textobject_move(function()
						move.goto_previous_start("@parameter.inner", "textobjects")
					end),
					{ desc = "Prev Parameter" }
				)
			end
		end,
	},
}
