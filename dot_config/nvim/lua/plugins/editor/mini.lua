-- Mini.* editing plugins ecosystem
-- Note: mini.snippets is configured in completion.lua (part of nvim-cmp setup)

return {
  -- Enhanced text objects: vif, vaf, vaq, va), etc.
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    opts = { n_lines = 500 },
    config = function(_, opts)
      local ai = require("mini.ai")
      ai.setup(vim.tbl_deep_extend("force", opts, {
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
        },
      }))
    end,
  },

  -- Surround: saiw", sd", sr"', etc.
  -- Note: mini.surround uses sa/sd/sr NOT vim-surround style ys/ds/cs
  {
    "echasnovski/mini.surround",
    event = "VeryLazy",
    opts = {
      -- Default mappings:
      -- sa = add, sd = delete, sr = replace, sf = find, sF = find left, sh = highlight
      mappings = {
        add = "gsa", -- Add surrounding
        delete = "gsd", -- Delete surrounding
        find = "gsf", -- Find surrounding (right)
        find_left = "gsF", -- Find surrounding (left)
        highlight = "gsh", -- Highlight surrounding
        replace = "gsr", -- Replace surrounding
        update_n_lines = "gsn", -- Update n_lines
      },
    },
  },

  -- Comments: gcc, gc{motion}
  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    opts = {},
  },

  -- Auto pairs: (), {}, [], "", ''
  {
    "echasnovski/mini.pairs",
    event = "InsertEnter",
    opts = {},
  },

  -- Move lines/selections: Alt+h/j/k/l
  {
    "echasnovski/mini.move",
    event = "VeryLazy",
    opts = {
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
    },
  },

  -- Inline git diff (signs and overlay)
  {
    "echasnovski/mini.diff",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      view = {
        style = "sign",
        signs = { add = "+", change = "~", delete = "-" },
      },
    },
  },

  -- Highlight patterns (colors, TODOs)
  {
    "echasnovski/mini.hipatterns",
    event = { "BufReadPost", "BufNewFile" },
    opts = function()
      local hi = require("mini.hipatterns")
      return {
        highlighters = {
          fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
          hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
          todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
          note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
          hex_color = hi.gen_highlighter.hex_color(),
        },
      }
    end,
  },
}
