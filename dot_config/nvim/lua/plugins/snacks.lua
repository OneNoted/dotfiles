return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = function()
      local get_header = require("utils.dashboard-headers")
      local greeting = require("utils.greeting")
      local header_art = get_header(nil, true)
      local greeting_data = greeting.get_greeting()

      -- Get chezmoi source path
      local chezmoi_source = vim.fn.system("chezmoi source-path"):gsub("%s+$", "")
      if vim.v.shell_error ~= 0 or chezmoi_source == "" then
        chezmoi_source = vim.fn.expand("~/.local/share/chezmoi")
      end

      -- Check if in a git repo
      local is_git_repo = vim.fn.isdirectory(".git") == 1
        or vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):match("true")

      -- Check window width for layout (threshold: 160 columns for side-by-side)
      local is_wide_window = vim.o.columns >= 160

      -- Info box section (date + plugins + startup time in bordered box)
      local function info_box_section(pane_num)
        return function()
          local date_text = "󰃭 " .. os.date("Today is %a %d %b")
          local stats = require("lazy").stats()
          local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
          local plugins_text = "󰒲 " .. tostring(stats.loaded) .. "/" .. tostring(stats.count) .. " plugins loaded in " .. ms .. "ms"

          -- Center the shorter line by adding equal padding on both sides
          local max_len = math.max(#date_text, #plugins_text)
          local date_diff = max_len - #date_text
          local date_left_pad = string.rep(" ", math.floor(date_diff / 2))
          local date_right_pad = string.rep(" ", math.ceil(date_diff / 2))
          local plugins_diff = max_len - #plugins_text
          local plugins_left_pad = string.rep(" ", math.floor(plugins_diff / 2))
          local plugins_right_pad = string.rep(" ", math.ceil(plugins_diff / 2))

          local section = {
            align = "center",
            padding = 1,
            text = {
              { "┌  ", hl = "SnacksDashboardDesc" },
              { date_left_pad .. date_text .. date_right_pad, hl = "SnacksDashboardDesc" },
              { "  ┐\n", hl = "SnacksDashboardDesc" },
              { "└  ", hl = "SnacksDashboardDesc" },
              { plugins_left_pad .. plugins_text .. plugins_right_pad, hl = "SnacksDashboardDesc" },
              { "  ┘", hl = "SnacksDashboardDesc" },
            },
          }
          if pane_num then
            section.pane = pane_num
          end
          return section
        end
      end

      -- final dashboard sections
      local dashboard_sections
      if is_git_repo and is_wide_window then
        -- Wide window + git repo: Two-pane layout (header left, onefetch right)
        dashboard_sections = {
          { pane = 1, section = "header" },
          { pane = 1, text = greeting_data.main, align = "center", gap = 1, padding = 1 },
        }
        if greeting_data.late then
          table.insert(dashboard_sections, { pane = 1, text = greeting_data.late, align = "center", padding = 0.5 })
        end
        table.insert(dashboard_sections, info_box_section(1))
        table.insert(dashboard_sections, { pane = 1, section = "keys", gap = 1, padding = 1 })
        -- Git info on pane 2
        table.insert(dashboard_sections, {
          pane = 2,
          section = "terminal",
          cmd = "onefetch --no-color-palette",
          ttl = 0,
          width = 80,
          height = 25,
          padding = 1,
        })
      elseif is_git_repo then
        -- Narrow window + git repo: onefetch replaces header
        dashboard_sections = {
          { section = "terminal", cmd = "onefetch --no-color-palette", ttl = 0, width = 80, height = 20, padding = 1 },
          { text = greeting_data.main, align = "center", gap = 1, padding = 1 },
        }
        if greeting_data.late then
          table.insert(dashboard_sections, { text = greeting_data.late, align = "center", padding = 0.5 })
        end
        table.insert(dashboard_sections, info_box_section(nil))
        table.insert(dashboard_sections, { section = "keys", gap = 1, padding = 1 })
      else
        -- Not in git repo: normal dashboard with header
        dashboard_sections = {
          { section = "header" },
          { text = greeting_data.main, align = "center", gap = 1, padding = 1 },
        }
        if greeting_data.late then
          table.insert(dashboard_sections, { text = greeting_data.late, align = "center", padding = 0.5 })
        end
        table.insert(dashboard_sections, info_box_section(nil))
        table.insert(dashboard_sections, { section = "keys", gap = 1, padding = 1 })
      end

      return {
        bigfile = { enabled = true },
        dashboard = {
          enabled = true,
          width = 40,
          preset = {
            keys = {
              { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.files()" },
              { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
              { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
              { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.picker.grep()" },
              { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
              {
                icon = " ",
                key = "c",
                desc = "Config",
                action = ":lua Snacks.picker.files({ cwd = vim.fn.stdpath('config') })",
              },
              {
                icon = "󱆃 ",
                key = "C",
                desc = "Chezmoi",
                action = function()
                  Snacks.picker.files({ cwd = chezmoi_source })
                end,
              },
              { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
              { icon = " ", key = "q", desc = "Quit", action = ":qa" },
            },
            header = table.concat(header_art, "\n"),
          },
          sections = dashboard_sections,
        },
        explorer = {
          enabled = true,
          replace_netrw = true,
        },
        indent = { enabled = true },
        input = { enabled = true },
        notifier = { enabled = true },
        picker = { enabled = true },
        quickfile = { enabled = true },
        scope = { enabled = true },
        scroll = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
      }
    end,
    keys = {
      -- Picker
      {
        "<leader><space>",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>,",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>/",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>fg",
        function()
          Snacks.picker.git_files()
        end,
        desc = "Git Files",
      },
      {
        "<leader>fr",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent",
      },
      {
        "<leader>fb",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      -- Search
      {
        "<leader>sg",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>sw",
        function()
          Snacks.picker.grep_word()
        end,
        desc = "Word",
        mode = { "n", "x" },
      },
      {
        "<leader>sd",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics",
      },
      {
        "<leader>sh",
        function()
          Snacks.picker.help()
        end,
        desc = "Help Pages",
      },
      {
        "<leader>sk",
        function()
          Snacks.picker.keymaps()
        end,
        desc = "Keymaps",
      },
      {
        "<leader>sm",
        function()
          Snacks.picker.marks()
        end,
        desc = "Marks",
      },
      -- Git
      {
        "<leader>gc",
        function()
          Snacks.picker.git_log()
        end,
        desc = "Git Log",
      },
      {
        "<leader>gs",
        function()
          Snacks.picker.git_status()
        end,
        desc = "Git Status",
      },
      {
        "<leader>gg",
        function()
          Snacks.terminal("gitui", { cwd = vim.fn.getcwd() })
        end,
        desc = "GitUI",
      },
      -- Explorer
      {
        "<leader>e",
        function()
          Snacks.explorer()
        end,
        desc = "Explorer",
      },
      -- Notifications
      {
        "<leader>un",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "Notification History",
      },
      {
        "<leader>uN",
        function()
          Snacks.notifier.hide()
        end,
        desc = "Dismiss Notifications",
      },
    },
  },
}
