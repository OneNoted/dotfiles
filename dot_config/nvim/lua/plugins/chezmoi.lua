return {
  {
    "alker0/chezmoi.vim",
    lazy = false,
    init = function()
      vim.g["chezmoi#use_tmp_buffer"] = 1

      -- fix chezmoi.vim being evil and defaulting to "~/.local/share/chezmoi"
      vim.g["chezmoi#use_external"] = 1
    end,
  },

  {
    "xvzc/chezmoi.nvim",

    init = function()
      -- auto chezmoi apply and enter
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { vim.env.HOME .. "/Chezmoi/Source/*" },
        callback = function()
          vim.schedule(require("chezmoi.commands.__edit").watch)
        end,
      })
    end,
  },
}
