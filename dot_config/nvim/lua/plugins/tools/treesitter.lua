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
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]C"] = "@class.outer", -- Capital C to avoid conflict with treesitter-context [c
              ["]a"] = "@parameter.inner",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[C"] = "@class.outer", -- Capital C to avoid conflict with treesitter-context [c
              ["[a"] = "@parameter.inner",
            },
          },
        },
      })
    end,
  },
}
