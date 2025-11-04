return {

  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  priority = 999,
  lazy = false,

  config = function()
    require("lualine").setup({
      options = {
        theme = "catppuccin",
        section_separators = { left = "", right = "" },
      },
    })
  end,
}
