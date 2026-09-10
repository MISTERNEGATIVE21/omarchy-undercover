-- =============================================================================
-- Omarchy Undercover - Apple macOS Sequoia Mode for Hyprland (Lua module)
-- =============================================================================

local settings_path = os.getenv("HOME") .. "/.config/omarchy-undercover/settings.conf"

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
local state_file = io.open(os.getenv("HOME") .. "/.config/omarchy-undercover/state", "r")
if state_file then
  local s = state_file:read("*l")
  state_file:close()
  if s and (s:find("mac") or s:find("ios")) then mode = "mac" end
end

if mode ~= "mac" and mode ~= "ios" then return end

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

-- System & Spotlight Keybindings
hl.unbind("SUPER + SPACE")
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("rofi -show drun -theme ~/.config/rofi/mac.rasi"), { description = "macOS Spotlight Search" })
hl.unbind("SUPER + TAB")
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/mac.rasi"), { description = "macOS Mission Control" })
hl.bind("SUPER + M", hl.dsp.exec_cmd("omarchy-undercover-minimize"), { description = "Minimize window" })
hl.bind("SUPER + N", hl.dsp.exec_cmd("omarchy-mac-widgets"), { description = "macOS Notification Center & Widgets" })
hl.bind("SUPER + D", hl.dsp.exec_cmd("omarchy-undercover-show-desktop"), { description = "Show desktop" })
hl.bind("SUPER + B", hl.dsp.exec_cmd("omarchy-undercover-toggle-bar"), { description = "Toggle Dock/Taskbar Visibility" })
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("omarchy-undercover-autohide --toggle"), { description = "Toggle Edge Auto-Hide Daemon" })
hl.bind("SUPER + ALT + U", hl.dsp.exec_cmd("omarchy-undercover --toggle"), { description = "Toggle Undercover Mode" })

-- macOS Sequoia Native Window Tiling Shortcuts (Fn / Ctrl + Super + Arrows)
hl.bind("SUPER + CTRL + LEFT", hl.dsp.exec_cmd("omarchy-undercover-snap left"), { description = "macOS Tile Left Half" })
hl.bind("SUPER + CTRL + RIGHT", hl.dsp.exec_cmd("omarchy-undercover-snap right"), { description = "macOS Tile Right Half" })
hl.bind("SUPER + CTRL + UP", hl.dsp.exec_cmd("omarchy-undercover-snap up"), { description = "macOS Maximize / Zoom Window" })
hl.bind("SUPER + CTRL + DOWN", hl.dsp.exec_cmd("omarchy-undercover-snap down"), { description = "macOS Restore Window" })
hl.bind("SUPER + CTRL + RETURN", hl.dsp.exec_cmd("omarchy-undercover-snap fullscreen"), { description = "macOS Full Screen Toggle" })
hl.bind("SUPER + CTRL + C", hl.dsp.exec_cmd("omarchy-undercover-snap center"), { description = "macOS Center Window" })
hl.bind("SUPER + CTRL + 1", hl.dsp.exec_cmd("omarchy-undercover-snap top-left"), { description = "macOS Tile Top-Left" })
hl.bind("SUPER + CTRL + 2", hl.dsp.exec_cmd("omarchy-undercover-snap top-right"), { description = "macOS Tile Top-Right" })
hl.bind("SUPER + CTRL + 3", hl.dsp.exec_cmd("omarchy-undercover-snap bottom-left"), { description = "macOS Tile Bottom-Left" })
hl.bind("SUPER + CTRL + 4", hl.dsp.exec_cmd("omarchy-undercover-snap bottom-right"), { description = "macOS Tile Bottom-Right" })
hl.bind("SUPER + CTRL + SPACE", hl.dsp.exec_cmd("omarchy-undercover-snap menu"), { description = "macOS Window Tiling Menu" })

-- Smooth Mouse Window Interactions
hl.bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

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
if o and o.window then
  o.window({ class = "^org.quickshell$", title = "^System Settings$" }, {
    float = true,
    center = true,
    size = { 980, 640 },
    tag = "-default-opacity",
    opacity = "1 1",
  })
end
