-- lua/utils/greeting.lua

local M = {}

---@param str string
---@return string
local function capitalize(str)
  if str == nil or str == "" then
    return ""
  end
  return str:sub(1, 1):upper() .. str:sub(2)
end

---@return { main: table, late: table|nil }
function M.get_greeting()
  local hour = tonumber(os.date("%H"))
  local user = capitalize(os.getenv("USER") or "user")
  local hostname = capitalize(vim.fn.hostname())

  local greeting
  local icon
  if hour >= 5 and hour < 12 then
    greeting = "Good morning"
    icon = " "
  elseif hour >= 12 and hour < 18 then
    greeting = "Good afternoon"
    icon = "  "
  else
    greeting = "Good evening"
    icon = " "
  end

  local main = {
    { icon, hl = "SnacksDashboardIcon" },
    { greeting .. " ", hl = "SnacksDashboardDesc" },
    { user, hl = "Keyword" },
    { ", welcome to ", hl = "SnacksDashboardDesc" },
    { hostname, hl = "Keyword" },
    { "  ", hl = "Keyword" },
  }

  local late = nil
  if hour >= 20 or hour < 5 then
    late = {
      { "󰤄 It's getting late, consider catching some sleep! 󰒲 ", hl = "DiagnosticWarn" },
    }
  end

  return { main = main, late = late }
end

return M
