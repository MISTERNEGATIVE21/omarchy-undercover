-- =============================================================================
-- Omarchy Undercover - Apple macOS Sequoia Mode for Hyprland (Lua module)
-- =============================================================================

local home = os.getenv("HOME")
local settings_path = home .. "/.config/omarchy/plugins/omarchy-undercover/settings.conf"
if not io.open(settings_path, "r") then
  settings_path = home .. "/.config/omarchy/plugins/undercover/settings.conf"
end
if not io.open(settings_path, "r") then
  settings_path = home .. "/.config/omarchy-undercover/settings.conf"
end

local function get_setting(key, default)
  local file = io.open(settings_path, "r")
  if not file then return default end
  local value = default
  for line in file:lines() do
    local k, v = line:match("^([%w_]+)%s*=%s*(.*)$")
    if k == key and v ~= "" then value = v end
  end
  file:close()
  return value
end

local mode = get_setting("MODE", "")
local state_path = home .. "/.config/omarchy/plugins/omarchy-undercover/state"
local state_file = io.open(state_path, "r") or io.open(home .. "/.config/omarchy/plugins/undercover/state", "r") or io.open(home .. "/.config/omarchy-undercover/state", "r")
if state_file then
  local s = state_file:read("*l")
  state_file:close()
  if s and (s:find("mac") or s:find("ios")) then mode = "mac" end
end

if mode ~= "mac" and mode ~= "ios" then return end

-- ---------------------------------------------------------------------------
-- Script resolver: ensures commands resolve to plugin scripts if not in PATH
-- ---------------------------------------------------------------------------
local function find_script(name)
  local dirs = {
    home .. "/.config/omarchy/plugins/omarchy-undercover/scripts",
    home .. "/.config/omarchy/plugins/undercover/scripts",
    home .. "/.config/omarchy-undercover/scripts",
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

local function exec_cmd(cmd)
  local resolved = cmd:gsub("([%w_-]*omarchy%-[%w_-]+)", function(name)
    return find_script(name)
  end)
  return hl.dsp.exec_cmd(resolved)
end

hl.config({
  general = {
    gaps_in = 6,
    gaps_out = 12,
    border_size = 1,
    col = {
      active_border = "rgba(007aff66)",
      inactive_border = "rgba(00000000)",
    },
    layout = "dwindle",
  },
  decoration = {
    rounding = 16,
    active_opacity = 0.98,
    inactive_opacity = 0.92,
    fullscreen_opacity = 1.0,
    shadow = {
      enabled = true,
      range = 42,
      render_power = 4,
      color = "rgba(00000066)",
    },
    blur = {
      enabled = true,
      size = 16,
      passes = 4,
      special = true,
      noise = 0.015,
      contrast = 1.25,
      brightness = 1.05,
      vibrancy = 0.40,
      vibrancy_darkness = 0.25,
      popups = true,
    },
  },
  misc = {
    animate_manual_resizes = true,
    animate_mouse_windowdragging = true,
    disable_hyprland_logo = true,
    focus_on_activate = true,
  },
  input = {
    repeat_rate = 25,
    repeat_delay = 600,
    follow_mouse = 1,
  },
})

-- macOS Sequoia Spring & Smooth Acceleration Animation Physics
hl.curve("macSpring", { type = "bezier", points = { { 0.1, 0.9 }, { 0.2, 1.0 } } })
hl.curve("macEase", { type = "bezier", points = { { 0.25, 1.0 }, { 0.5, 1.0 } } })
hl.curve("macFade", { type = "bezier", points = { { 0.0, 0.0 }, { 0.2, 1.0 } } })
hl.curve("macFluid", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })
hl.curve("macGenie", { type = "bezier", points = { { 0.2, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "global", enabled = true, speed = 6, bezier = "macFluid" })
hl.animation({ leaf = "windows", enabled = true, speed = 6, bezier = "macFluid" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 6, bezier = "macFluid", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "macEase", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "macSpring" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "macFade" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, bezier = "macFade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "macEase", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "macFluid", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 5, bezier = "macSpring", style = "slide bottom" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 4, bezier = "macEase", style = "slide bottom" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "macSpring", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "macEase", style = "fade" })

-- ---------------------------------------------------------------------------
-- Dedicated Undercover toggle shortcuts (non-conflicting with base bindings)
-- ---------------------------------------------------------------------------
if hl and hl.bind then
  hl.bind("SUPER + ALT + U", exec_cmd("omarchy-undercover --toggle"), { description = "Toggle Undercover Mode" })
  hl.bind("SUPER + ALT + B", exec_cmd("omarchy-undercover-autohide --toggle"), { description = "Toggle Edge Auto-Hide Daemon" })
end

-- ---------------------------------------------------------------------------
-- Configurable macOS Sequoia Keybindings
-- ---------------------------------------------------------------------------
local keybindings_enabled = get_setting("ENABLE_KEYBINDINGS", "true") == "true"

if keybindings_enabled and hl and hl.bind then
  local function bind_key(setting_key, default_key, action, desc, extra_opts)
    local key = get_setting(setting_key, default_key)
    if key and key ~= "" and key:lower() ~= "none" and key:lower() ~= "disabled" then
      local opts = { description = desc }
      if extra_opts then
        for k, v in pairs(extra_opts) do opts[k] = v end
      end
      -- Strictly protect Omarchy's core Close Window shortcuts from being rebound
      if key ~= "SUPER + W" and key ~= "SUPER + Q" then
        pcall(function() hl.unbind(key) end)
      end
      hl.bind(key, action, opts)
    end
  end

  -- macOS Spotlight Search (Cmd + Space)
  bind_key("BIND_MAC_SPOTLIGHT", "SUPER + SPACE", exec_cmd("rofi -show drun -theme ~/.config/rofi/mac.rasi"), "macOS Spotlight Search")
  bind_key("BIND_MAC_MISSIONCONTROL", "SUPER + TAB", exec_cmd("rofi -show window -theme ~/.config/rofi/mac.rasi"), "macOS Mission Control")
  bind_key("BIND_MAC_WIDGETS", "SUPER + N", exec_cmd("omarchy-mac-widgets"), "macOS Notification Center & Widgets")
  bind_key("BIND_MAC_SETTINGS", "SUPER + COMMA", exec_cmd("uwsm-app -- omarchy-undercover-settings"), "macOS System Settings")
  bind_key("BIND_MAC_FINDER", "SUPER + E", exec_cmd("omarchy-undercover-filemanager"), "macOS Finder")
  bind_key("BIND_MAC_MINIMIZE", "SUPER + M", exec_cmd("omarchy-undercover-minimize"), "Minimize window")
  bind_key("BIND_MAC_DESKTOP", "SUPER + D", exec_cmd("omarchy-undercover-show-desktop"), "Show desktop")
  bind_key("BIND_MAC_LOCK", "SUPER + CTRL + Q", exec_cmd("hyprlock || swaylock || loginctl lock-session"), "Lock screen", { locked = true })
  bind_key("BIND_MAC_CLOSE", "SUPER + Q", hl.dsp.window.close(), "Quit / Close window")

  -- macOS Sequoia Native Window Tiling Shortcuts (Ctrl + Super + Arrows)
  bind_key("BIND_MAC_SNAP_LEFT", "SUPER + CTRL + LEFT", exec_cmd("omarchy-undercover-snap left"), "macOS Tile Left Half")
  bind_key("BIND_MAC_SNAP_RIGHT", "SUPER + CTRL + RIGHT", exec_cmd("omarchy-undercover-snap right"), "macOS Tile Right Half")
  bind_key("BIND_MAC_SNAP_UP", "SUPER + CTRL + UP", exec_cmd("omarchy-undercover-snap up"), "macOS Maximize / Zoom Window")
  bind_key("BIND_MAC_SNAP_DOWN", "SUPER + CTRL + DOWN", exec_cmd("omarchy-undercover-snap down"), "macOS Restore Window")
  bind_key("BIND_MAC_SNAP_MENU", "SUPER + CTRL + SPACE", exec_cmd("omarchy-undercover-snap menu"), "macOS Window Tiling Menu")
end


-- Compositor frosted glass blur layer rules for Quickshell & legacy surfaces
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-menu" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-notifications" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-osd" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-keyboard-panel" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-clipboard" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-image-selector" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-emojis" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "mac-topbar" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "mac-dock" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, blur = true, ignore_alpha = true })

-- macOS System Settings Window Rules
hl.window_rule({
  match = { class = "^org.quickshell$", title = "^System Settings$" },
  float = true,
  center = true,
  size = { 980, 640 },
  focus_on_activate = true,
})
hl.window_rule({
  match = { class = "^org.omarchy.undercover.settings$" },
  float = true,
  center = true,
  size = { 1020, 700 },
  focus_on_activate = true,
})

if o and o.window then
  o.window({ class = "^org.quickshell$", title = "^System Settings$" }, {
    float = true,
    center = true,
    size = { 980, 640 },
    focus_on_activate = true,
    tag = "-default-opacity",
    opacity = "1 1",
  })
  o.window({ class = "^org.omarchy.undercover.settings$" }, {
    float = true,
    center = true,
    size = { 1020, 700 },
    focus_on_activate = true,
    tag = "-default-opacity",
    opacity = "1 1",
  })
end

-- macOS Finder / File Manager Window Rules
hl.window_rule({
  match = { class = "(com.thisisgm.flea|flea|org.gnome.Nautilus|thunar|org.kde.dolphin|nemo|pcmanfm)" },
  float = true,
  center = true,
  size = { 1060, 660 },
  rounding = 16,
})

if o and o.window then
  o.window({ class = "^(com.thisisgm.flea|flea|org.gnome.Nautilus|thunar|org.kde.dolphin|nemo|pcmanfm)$" }, {
    float = true,
    center = true,
    size = { 1060, 660 },
    rounding = 16,
  })
end

