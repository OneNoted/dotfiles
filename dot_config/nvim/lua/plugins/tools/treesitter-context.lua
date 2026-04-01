return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      enable = true,
      max_lines = 3,
      min_window_height = 0,
      line_numbers = true,
      multiline_threshold = 20,
      trim_scope = "outer",
      mode = "cursor",
      separator = nil,
      zindex = 20,
      on_attach = function(buf)
        if vim.bo[buf].buftype == "help" then
          return false
        end
        local readme_help_dir = vim.fn.stdpath("state") .. "/lazy/readme/doc/"
        return not vim.api.nvim_buf_get_name(buf):find("^" .. vim.pesc(readme_help_dir))
      end,
    },
    keys = {
      {
        "[c",
        function()
          require("treesitter-context").go_to_context(vim.v.count1)
        end,
        desc = "Go to Context",
      },
    },
  },
}
