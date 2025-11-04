return {
  "vyfor/cord.nvim",
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
          return "Editing a file in " .. opts.filetype
        end,
        viewing = "Viewing a file",
        workspace = "",
      },
      hooks = {
        -- called after Cord builds the activity but before sending
        post_activity = function(opts, activity)
          -- try to set the activity type to 'listening'
          activity.type = "watching" -- 'playing' | 'listening' | 'watching' | 'competing'
          -- optionally tweak which field is shown in the member list
          activity.status_display_type = "name" -- 'name' | 'state' | 'details'
          -- you can also adjust the details/state strings
          activity.details = activity.details or "wawa"
          activity.state = activity.state or "Neovim"
          return activity
        end,
      },
      -- asset overrides
      assets = {},
    }
  end,
}
