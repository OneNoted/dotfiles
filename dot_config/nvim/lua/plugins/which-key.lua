return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "classic",
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
      spec = {
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "harpoon" },
        { "<leader>s", group = "search" },
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>t", group = "test" },
        { "<leader>u", group = "ui" },
        { "<leader>x", group = "diagnostics/quickfix" },
        { "<leader>q", group = "quit/session" },
        { "<leader>w", group = "windows" },
        { "<leader><tab>", group = "tabs" },
        { "[", group = "prev" },
        { "]", group = "next" },
        { "g", group = "goto" },
        { "z", group = "fold" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Local Keymaps",
      },
    },
  },
}
