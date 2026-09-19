-- =============================================================================
-- Omarchy Undercover - Hyprland Dynamic Mode Toggle
-- Automatically loaded by Omarchy's ~/.local/state/omarchy/toggles/hypr/
-- =============================================================================

local home = os.getenv("HOME")

-- Locate active plugin root directory
local function get_plugin_dir()
  local dirs = {
    home .. "/.config/omarchy/plugins/omarchy-undercover",
    home .. "/.config/omarchy/plugins/undercover",
    home .. "/.config/omarchy-undercover",
    "/usr/share/omarchy-undercover",
  }
  for _, d in ipairs(dirs) do
    local f = io.open(d .. "/manifest.json", "r")
    if f then
      f:close()
      return d
    end
  end
  return home .. "/.config/omarchy/plugins/omarchy-undercover"
end

local plugin_dir = get_plugin_dir()

-- Detect active undercover mode
local function get_active_mode()
  -- Check state file first (highest precedence)
  local state_paths = {
    plugin_dir .. "/state",
    home .. "/.config/omarchy/plugins/undercover/state",
    home .. "/.config/omarchy-undercover/state",
  }
  for _, sp in ipairs(state_paths) do
    local f = io.open(sp, "r")
    if f then
      local line = f:read("*l")
      f:close()
      if line and line ~= "" then
        line = line:lower()
        if line:find("win") or line:find("windows") then return "windows" end
        if line:find("mac") or line:find("ios") then return "mac" end
        if line:find("omarchy") then return "omarchy" end
      end
    end
  end

  -- Check settings.conf
  local settings_paths = {
    plugin_dir .. "/settings.conf",
    home .. "/.config/omarchy/plugins/undercover/settings.conf",
    home .. "/.config/omarchy-undercover/settings.conf",
  }
  for _, sp in ipairs(settings_paths) do
    local f = io.open(sp, "r")
    if f then
      for line in f:lines() do
        local k, v = line:match("^([%w_]+)%s*=%s*(.*)$")
        if k == "MODE" and v ~= "" then
          f:close()
          v = v:lower()
          if v:find("win") or v:find("windows") then return "windows" end
          if v:find("mac") or v:find("ios") then return "mac" end
          return v
        end
      end
      f:close()
    end
  end

  return "omarchy"
end

local function find_script(name)
  local dirs = {
    plugin_dir .. "/scripts",
    home .. "/.local/bin",
    "/usr/share/omarchy-undercover/scripts",
  }
  for _, dir in ipairs(dirs) do
    local path = dir .. "/" .. name
    local f = io.open(path, "r")
    if f then
      f:close()
      return path
    end
  end
  return name
end

-- Always bind the main camouflage toggle shortcut so user can switch anytime
if hl and hl.bind then
  hl.bind("SUPER + ALT + U", hl.dsp.exec_cmd(find_script("omarchy-undercover") .. " --toggle"), { description = "Toggle Undercover Mode" })
end

local mode = get_active_mode()

if mode == "windows" then
  local win_lua = plugin_dir .. "/configs/hypr/windows-mode.lua"
  local f = io.open(win_lua, "r")
  if f then
    f:close()
    dofile(win_lua)
  end
elseif mode == "mac" then
  local mac_lua = plugin_dir .. "/configs/hypr/mac-mode.lua"
  local f = io.open(mac_lua, "r")
  if f then
    f:close()
    dofile(mac_lua)
  end
end

