-- =============================================================================
-- Omarchy Undercover - Hyprland Dynamic Mode Toggle
-- Automatically loaded by Omarchy's ~/.local/state/omarchy/toggles/hypr/
-- =============================================================================

local home = os.getenv("HOME")

-- Locate active plugin root directory
local function get_plugin_dir()
  local dirs = {
    home .. "/omarchy-undercover",
    home .. "/.config/omarchy/plugins/omarchy-undercover",
    home .. "/.config/omarchy/plugins/undercover",
    "/usr/share/omarchy-undercover",
  }
  for _, d in ipairs(dirs) do
    local f = io.open(d .. "/manifest.json", "r")
    if f then
      f:close()
      return d
    end
  end
  return nil
end

local plugin_dir = get_plugin_dir()
if not plugin_dir then
  -- Plugin was removed or uninstalled: self-cleanup toggle files so Hyprland stays clean
  pcall(function()
    os.remove(home .. "/.local/state/omarchy/toggles/hypr/undercover.lua")
    os.remove(home .. "/.local/state/omarchy/toggles/hypr/undercover.conf")
  end)
  return
end

local function get_setting(key, default)
  local settings_paths = {
    plugin_dir .. "/settings.conf",
    home .. "/.config/omarchy/plugins/omarchy-undercover/settings.conf",
    home .. "/.config/omarchy/plugins/undercover/settings.conf",
  }
  for _, sp in ipairs(settings_paths) do
    local f = io.open(sp, "r")
    if f then
      for line in f:lines() do
        local k, v = line:match("^([%w_]+)%s*=%s*(.*)$")
        if k == key and v and v ~= "" then
          f:close()
          v = v:gsub("[\r\n]", ""):gsub("^[\"']", ""):gsub("[\"']$", "")
          return v
        end
      end
      f:close()
    end
  end
  return default
end

-- Detect active undercover mode
local function get_active_mode()
  -- Check state file first (highest precedence)
  local state_paths = {
    plugin_dir .. "/state",
    home .. "/.config/omarchy/plugins/omarchy-undercover/state",
    home .. "/.config/omarchy/plugins/undercover/state",
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
  local val = get_setting("MODE", "omarchy"):lower()
  if val:find("win") or val:find("windows") then return "windows" end
  if val:find("mac") or val:find("ios") then return "mac" end
  if val:find("omarchy") then return "omarchy" end

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
local toggle_key = get_setting("BIND_UNDERCOVER_TOGGLE", "SUPER + ALT + U")
local toggle_script = find_script("omarchy-undercover")
local toggle_cmd = toggle_script .. " --toggle"

if hl and hl.bind then
  hl.bind(toggle_key, hl.dsp.exec_cmd(toggle_cmd), { description = "Toggle Undercover Mode" })
elseif o and o.bind then
  o.bind(toggle_key, "Toggle Undercover Mode", toggle_cmd)
end

-- If disguise persistence is disabled, revert to Omarchy on session boot/login
if o and o.exec_on_start then
  local pers = get_setting("DISGUISE_PERSISTENT", "false")
  if pers ~= "true" then
    o.exec_on_start(toggle_script .. " --startup")
  end
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

