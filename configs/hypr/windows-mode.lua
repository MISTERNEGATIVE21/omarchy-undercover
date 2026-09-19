-- =============================================================================
-- Omarchy Undercover - Windows 11 Mode for Hyprland (Lua config module)
-- License: GPL-3.0-or-later
--
-- This module is `require`d from the end of ~/.config/hypr/hyprland.lua by the
-- omarchy-undercover CLI. It transforms Hyprland into a Windows 11 experience:
-- Fluent visuals/animations, Windows keybindings, Win11 wallpaper persistence
-- and system-wide theming environment. All settings are read from
-- ~/.config/omarchy-undercover/settings.conf so the settings app can change
-- them live (apply with `hyprctl reload`).
--
-- It must stay safe to load in any order - the `o` and `hl` globals are
-- provided by Omarchy's hyprland.lua bootstrap.
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
  if not file then
    return default
  end

  local value = default
  for line in file:lines() do
    local k, v = line:match("^([%w_]+)%s*=%s*(.*)$")
    if k == key and v ~= "" then
      value = v
    end
  end
  file:close()
  return value
end

local accent        = get_setting("ACCENT", "0078d4")
local animations_on = get_setting("ANIMATIONS", "1") == "1"
local blur_on       = get_setting("BLUR", "1") == "1"
local is_trans      = get_setting("WIN11_TRANSPARENCY", "true") == "true"
local cursor_size   = tonumber(get_setting("CURSOR_SIZE", "24")) or 24
local mode          = get_setting("MODE", "windows")

-- Check state file first (highest precedence)
local state_path = home .. "/.config/omarchy/plugins/omarchy-undercover/state"
local state_file = io.open(state_path, "r") or io.open(home .. "/.config/omarchy/plugins/undercover/state", "r") or io.open(home .. "/.config/omarchy-undercover/state", "r")
if state_file then
  local s = state_file:read("*l")
  state_file:close()
  if s and (s:find("win") or s:find("windows")) then mode = "windows" end
  if s and (s:find("mac") or s:find("ios") or s:find("omarchy")) then mode = s end
end

-- Bail out gracefully if the user turned windows mode off but left the file.
if mode ~= "windows" and mode ~= "w11" and mode ~= "win11" then
  return
end

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

-- ---------------------------------------------------------------------------
-- System-wide environment (cursor, theme, platform theming)
-- ---------------------------------------------------------------------------
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", tostring(cursor_size))
hl.env("HYPRCURSOR_SIZE", tostring(cursor_size))
hl.env("GTK_THEME", "Win11-Dark")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

-- ---------------------------------------------------------------------------
-- Windows 11 wallpaper persistence (survives login/relog)
-- ---------------------------------------------------------------------------
o.exec_on_start(find_script("omarchy-undercover-wallpaper"))

-- ---------------------------------------------------------------------------
-- Fluent visuals
-- ---------------------------------------------------------------------------
hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 1,
    col = {
      active_border = {
        colors = { "rgba(" .. accent .. "ff)", "rgba(00b7c3ff)" },
        angle = 45,
      },
      inactive_border = "rgba(00000000)",
    },
    layout = "dwindle",
  },

  decoration = {
    rounding = 10,
    active_opacity = is_trans and 0.96 or 1.0,
    inactive_opacity = is_trans and 0.88 or 1.0,

    shadow = {
      enabled = true,
      range = 24,
      render_power = 3,
      color = "rgba(00000066)",
    },

    blur = {
      enabled = blur_on and is_trans,
      size = 8,
      passes = 2,
      special = true,
      brightness = 0.70,
      contrast = 0.90,
      vibrancy = 0.20,
      popups = true,
    },
  },

  misc = {
    focus_on_activate = true,
    mouse_move_enables_dpms = true,
    animate_manual_resizes = true,
    disable_hyprland_logo = true,
  },

  input = {
    follow_mouse = 1,
    mouse_refocus = true,
    float_switch_override_focus = 1,
  },
})

-- ---------------------------------------------------------------------------
-- Fluent / Windows 11 animation curves
-- Fluent "Standard" easing: cubic-bezier(0.1, 0.9, 0.2, 1.0)
-- ---------------------------------------------------------------------------
hl.curve("fluent", { type = "bezier", points = { { 0.1, 0.9 }, { 0.2, 1 } } })
hl.curve("fluentExit", { type = "bezier", points = { { 0.2, 1 }, { 0.1, 1 } } })
hl.curve("fluentSnap", { type = "bezier", points = { { 0.1, 0.9 }, { 0.2, 1 } } })

if animations_on then
  hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "fluent" })
  hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "fluent" })
  hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "fluent" })
  hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "fluent", style = "popin 90%" })
  hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "fluentExit", style = "popin 85%" })
  hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "fluentSnap" })
  hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "fluent" })
  hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "fluent" })
  hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, bezier = "fluent" })
  hl.animation({ leaf = "layers", enabled = true, speed = 6, bezier = "fluent" })
  hl.animation({ leaf = "layersIn", enabled = true, speed = 5, bezier = "fluent", style = "fade" })
  hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "fluent", style = "fade" })
  hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "fluent" })
  hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "fluent", style = "slidevert" })
  hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 5, bezier = "fluent", style = "slide bottom" })
  hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 4, bezier = "fluentExit", style = "slide bottom" })
  hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, bezier = "fluent", style = "fade" })
  hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "fluent", style = "fade" })
else
  hl.animation({ leaf = "global", enabled = false })
end

-- ---------------------------------------------------------------------------
-- Window behaviour
-- ---------------------------------------------------------------------------
-- Prefer floating when dialogs/GTK file pickers open (Windows-like).
hl.window_rule({
  match = { class = "(dialog|file_progress|confirmreset|polkit.*)" },
  float = true,
  center = true,
  size = { "monitor_w * 0.5", "monitor_h * 0.6" },
})

-- File Explorer / File Manager window rules
hl.window_rule({
  match = { class = "(com.thisisgm.flea|flea|org.gnome.Nautilus|thunar|org.kde.dolphin|nemo|pcmanfm)" },
  float = true,
  center = true,
  size = { 1080, 680 },
  rounding = 10,
})

if o and o.window then
  o.window({ class = "^(com.thisisgm.flea|flea|org.gnome.Nautilus|thunar|org.kde.dolphin|nemo|pcmanfm)$" }, {
    float = true,
    center = true,
    size = { 1080, 680 },
    rounding = 10,
  })
end

-- Windows do not need a visible border when inactive (Win11 "flat" windows).
hl.window_rule({
  match = { class = ".*" },
  border_color = { colors = { "rgba(" .. accent .. "ff)", "rgba(00b7c3ff)" }, angle = 45 },
})

-- ---------------------------------------------------------------------------
-- Dedicated Undercover toggle shortcuts (non-conflicting with base bindings)
-- ---------------------------------------------------------------------------
if hl and hl.bind then
  hl.bind("SUPER + ALT + U", exec_cmd("omarchy-undercover --toggle"), { description = "Toggle undercover mode" })
  hl.bind("SUPER + ALT + B", exec_cmd("omarchy-undercover-autohide --toggle"), { description = "Toggle edge auto-hide" })
end

-- ---------------------------------------------------------------------------
-- Configurable Windows 11 Keybindings
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

  -- Windows Start menu (Win key tap release)
  local tap_start = get_setting("BIND_WIN_START_TAP", "true") == "true"
  if tap_start then
    pcall(function()
      hl.bind("SUPER + SUPER_L", exec_cmd("omarchy-undercover-launcher"), { release = true, description = "Start menu" })
    end)
  end

  bind_key("BIND_WIN_START", "SUPER + SPACE", exec_cmd("omarchy-undercover-launcher"), "Start menu")
  bind_key("BIND_WIN_EXPLORER", "SUPER + E", exec_cmd("omarchy-undercover-filemanager"), "File explorer")
  bind_key("BIND_WIN_TASKVIEW", "SUPER + TAB", exec_cmd("rofi -show window -theme ~/.config/rofi/windows11.rasi"), "Task view")
  bind_key("BIND_WIN_ACTIONCENTER", "SUPER + A", exec_cmd("omarchy-win11-actioncenter"), "Quick Settings & Action Center")
  bind_key("BIND_WIN_NOTIFICATIONS", "SUPER + N", exec_cmd("omarchy-win11-notifications"), "Notification Center & Calendar")

  -- Widgets Board uses SUPER + ALT + W by default to avoid conflicting with Omarchy's SUPER + W (Close window)
  bind_key("BIND_WIN_WIDGETS", "SUPER + ALT + W", exec_cmd("omarchy-win11-widgets"), "Windows 11 Widgets Board")

  bind_key("BIND_WIN_SETTINGS", "SUPER + I", exec_cmd("uwsm-app -- omarchy-undercover-settings"), "Settings")
  bind_key("BIND_WIN_DESKTOP", "SUPER + D", exec_cmd("omarchy-undercover-show-desktop"), "Show desktop")
  bind_key("BIND_WIN_SNAP", "SUPER + Z", exec_cmd("omarchy-undercover-snap menu"), "Windows 11 Snap Layouts Menu")
  bind_key("BIND_WIN_SCREENSHOT", "SUPER + SHIFT + S", exec_cmd("omarchy capture screenshot region copy"), "Region screenshot")
  bind_key("BIND_WIN_CLIPBOARD", "SUPER + V", exec_cmd("omarchy-launch-walker -m clipboard"), "Clipboard history")
  bind_key("BIND_WIN_LOCK", "SUPER + L", exec_cmd("hyprlock || swaylock || loginctl lock-session"), "Lock screen", { locked = true })
  bind_key("BIND_WIN_RUN", "SUPER + R", exec_cmd("rofi -show run -theme ~/.config/rofi/windows11.rasi"), "Run dialog")
  bind_key("BIND_WIN_MINIMIZE", "SUPER + M", exec_cmd("omarchy-undercover-minimize"), "Minimize window")
  bind_key("BIND_WIN_CLOSE", "ALT + F4", hl.dsp.window.close(), "Close window")

  -- Windows 11 Snap Assist & Tiling Shortcuts
  bind_key("BIND_WIN_SNAP_LEFT", "SUPER + LEFT", exec_cmd("omarchy-undercover-snap left"), "Snap Window Left (50%)")
  bind_key("BIND_WIN_SNAP_RIGHT", "SUPER + RIGHT", exec_cmd("omarchy-undercover-snap right"), "Snap Window Right (50%)")
  bind_key("BIND_WIN_SNAP_UP", "SUPER + UP", exec_cmd("omarchy-undercover-snap up"), "Maximize / Zoom Window")
  bind_key("BIND_WIN_SNAP_DOWN", "SUPER + DOWN", exec_cmd("omarchy-undercover-snap down"), "Restore / Minimize Window")
end


-- Compositor blur & mica styling for Quickshell surfaces and legacy components
hl.layer_rule({ match = { namespace = "omarchy-bar" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-menu" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-notifications" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-osd" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-keyboard-panel" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-clipboard" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-image-selector" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "omarchy-emojis" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = true })

-- Windows 11 Settings Window Rules
if o and o.window then
  o.window({ class = "^org.quickshell$", title = "^Settings$" }, {
    float = true,
    center = true,
    size = { 980, 640 },
    tag = "-default-opacity",
    opacity = "1 1",
  })
end
