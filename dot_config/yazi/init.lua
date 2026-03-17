local EXTERNAL_PACKAGES = {
  { id = "yazi-rs/plugins:mount", entry = "plugins/mount.yazi/main.lua" },
  { id = "dedukun/relative-motions", entry = "plugins/relative-motions.yazi/main.lua" },
  { id = "boydaihungst/restore", entry = "plugins/restore.yazi/main.lua" },
  { id = "dedukun/bookmarks", entry = "plugins/bookmarks.yazi/main.lua" },
}

local function file_exists(path)
  local file = io.open(path, "r")
  if file == nil then
    return false
  end

  file:close()
  return true
end

local function yazi_config_dir()
  local direct = os.getenv("YAZI_CONFIG_HOME")
  if direct ~= nil and direct ~= "" then
    return direct
  end

  local xdg = os.getenv("XDG_CONFIG_HOME")
  if xdg ~= nil and xdg ~= "" then
    return xdg .. "/yazi"
  end

  return os.getenv("HOME") .. "/.config/yazi"
end

local function ensure_external_packages()
  local config_dir = yazi_config_dir()
  local missing = {}

  for _, package in ipairs(EXTERNAL_PACKAGES) do
    local entry = string.format("%s/%s", config_dir, package.entry)
    if not file_exists(entry) then
      table.insert(missing, package.id)
    end
  end

  if #missing == 0 then
    return
  end

  local cmd = "ya pkg add " .. table.concat(missing, " ")
  local ok, why, code = os.execute(cmd)
  if ok ~= true and ok ~= 0 then
    error(string.format("Failed to install Yazi packages via `%s` (%s: %s)", cmd, tostring(why), tostring(code)))
  end
end

ensure_external_packages()

-- Relative Vim Motions
require("relative-motions"):setup({ show_numbers = "relative", show_motion = true, enter_mode = "first" })

require("folder-rules"):setup()

-- dedukun/bookmarks
require("bookmarks"):setup({
  last_directory = { enable = false, persist = false, mode = "dir" },
  persist = "vim",
  desc_format = "full",
  file_pick_mode = "parent",
  custom_desc_input = false,
  show_keys = true,
  notify = {
    enable = true,
    timeout = 1,
    message = {
      new = "New bookmark '<key>' -> '<folder>'",
      delete = "Deleted bookmark in '<key>'",
      delete_all = "Deleted all bookmarks",
    },
  },
})

-- Date & Time Linemode Function
function Linemode:size_and_mtime()
  local time = math.floor(self._file.cha.mtime or 0)
  if time == 0 then
    time = ""
  elseif os.date("%Y", time) == os.date("%Y") then
    time = os.date("%b %d %H:%M", time)
  else
    time = os.date("%b %d  %Y", time)
  end

  local size = self._file:size()
  return string.format("%s %s", size and ya.readable_size(size) or "-", time)
end

require("restore"):setup({
  -- Set the position for confirm and overwrite prompts.
  -- Don't forget to set height: `h = xx`
  -- https://yazi-rs.github.io/docs/plugins/utils/#ya.input
  position = { "center", w = 70, h = 40 }, -- Optional

  -- Show confirm prompt before restore.
  -- NOTE: even if set this to false, overwrite prompt still pop up
  show_confirm = true, -- Optional

  -- Suppress success notification when all files or folder are restored.
  suppress_success_notification = true, -- Optional

  -- colors for confirm and overwrite prompts
  theme = { -- Optional
    -- Default using style from your flavor or theme.lua -> [confirm] -> title.
    -- If you edit flavor or theme.lua you can add more style than just color.
    -- Example in theme.lua -> [confirm]: title = { fg = "blue", bg = "green"  }
    title = "blue", -- Optional. This value has higher priority than flavor/theme.lua

    -- Default using style from your flavor or theme.lua -> [confirm] -> content
    -- Sample logic as title above
    header = "green", -- Optional. This value has higher priority than flavor/theme.lua

    -- header color for overwrite prompt
    -- Default using color "yellow"
    header_warning = "yellow", -- Optional
    -- Default using style from your flavor or theme.lua -> [confirm] -> list
    -- Sample logic as title and header above
    list_item = { odd = "blue", even = "blue" }, -- Optional. This value has higher priority than flavor/theme.lua
  },
})
