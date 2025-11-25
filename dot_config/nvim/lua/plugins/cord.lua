return {
  "vyfor/cord.nvim",
  lazy = false,
  build = ":Cord update",
  opts = function()
    return {
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
        editing = function(opts)
          -- return "Editing a file in " .. opts.filetype
          return "Editing a file"
        end,
        viewing = "Viewing a file",
        workspace = "",
      },

      -- Thank you ChatGPT
      hooks = {
        post_activity = function(opts, activity)
          activity.type = "watching" -- 'playing' | 'listening' | 'watching' | 'competing'
          activity.status_display_type = "name" -- 'name' | 'state' | 'details'
          activity.details = activity.details or "wawa"
          activity.state = activity.state or "Neovim"
          return activity
        end,
      },
      assets = {},
    }
  end,
}
