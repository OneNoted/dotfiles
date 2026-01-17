return {
  -- Copilot core
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          accept = "<M-l>",
          accept_word = "<M-k>",
          accept_line = "<M-j>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      panel = {
        enabled = false, -- Using cmp integration instead
      },
      filetypes = {
        markdown = true,
        help = false,
        gitcommit = true,
        gitrebase = false,
        ["."] = false,
      },
    },
  },

  -- Copilot as cmp source (optional - can use ghost text instead)
  {
    "zbirenbaum/copilot-cmp",
    dependencies = "copilot.lua",
    opts = {},
    config = function(_, opts)
      local copilot_cmp = require("copilot_cmp")
      copilot_cmp.setup(opts)

      -- Add copilot to cmp sources if cmp is loaded
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function()
          local cmp_ok, cmp = pcall(require, "cmp")
          if cmp_ok then
            local config = cmp.get_config()
            table.insert(config.sources, 1, { name = "copilot", group_index = 1 })
            cmp.setup(config)
          end
        end,
        once = true,
      })
    end,
  },
}
