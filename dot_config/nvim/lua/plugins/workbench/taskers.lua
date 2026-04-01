return {
  {
    dir = "/home/notes/Projects/plugins/neovim/taskers",
    name = "taskers.nvim",
    build = "lua build.lua",
    cmd = {
      "TaskersOpen",
      "TaskersClose",
      "TaskersNew",
      "TaskersSwitch",
      "TaskersSend",
      "TaskersAttach",
      "TaskersOpenLink",
      "TaskersAddImage",
      "TaskersClearImages",
      "TaskersRename",
      "TaskersArchive",
      "TaskersRefresh",
      "TaskersRefreshSession",
      "TaskersRebuildIndex",
      "TaskersToggleTerminal",
      "TaskersToggleInspector",
    },
    keys = {
      { "<leader>to", "<cmd>TaskersOpen<cr>", desc = "Taskers Open" },
      { "<leader>tn", "<cmd>TaskersNew<cr>", desc = "Taskers New Session" },
      { "<leader>ts", "<cmd>TaskersSwitch<cr>", desc = "Taskers Switch Session" },
      { "<leader>tr", "<cmd>TaskersRefreshSession<cr>", desc = "Taskers Refresh Session" },
      { "<leader>ta", "<cmd>TaskersAttach<cr>", desc = "Taskers Attach Session" },
      { "<leader>tt", "<cmd>TaskersToggleTerminal<cr>", desc = "Taskers Toggle Terminal" },
      { "<leader>ti", "<cmd>TaskersToggleTerminal<cr>", desc = "Taskers Toggle Terminal" },
    },
    opts = {
      index_path = "/home/notes/.local/state/nvim/taskers/index.sqlite3",
      state_path = "/home/notes/.local/state/nvim/taskers/metadata.json",
    },
    config = function(_, opts)
      require("taskers").setup(opts)
    end,
  },
}
