-- =============================================================================
-- Omarchy Undercover - Apple macOS Mode for Hyprland (Lua module)
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
    gaps_in = 8,
    gaps_out = 16,
    border_size = 1,
    col = {
      active_border = "rgba(007aff88)",
      inactive_border = "rgba(ffffff18)",
    },
    layout = "dwindle",
  },
  decoration = {
    rounding = 14,
    active_opacity = 0.94,
    inactive_opacity = 0.88,
    fullscreen_opacity = 1.0,
    shadow = { enabled = true, range = 36, render_power = 4, color = "rgba(00000088)" },
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
  input = { repeat_rate = 25, repeat_delay = 600 },
})

hl.curve("macSpring", { type = "bezier", points = { { 0.1, 0.9 }, { 0.2, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 6, bezier = "macSpring" })

hl.unbind("SUPER + SPACE")
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("rofi -show drun -theme ~/.config/rofi/mac.rasi"), { description = "macOS Spotlight Search" })
hl.unbind("SUPER + TAB")
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/mac.rasi"), { description = "macOS Mission Control" })
hl.bind("SUPER + N", hl.dsp.exec_cmd("omarchy-mac-widgets"), { description = "macOS Notification Center & Widgets" })
hl.bind("SUPER + D", hl.dsp.exec_cmd("omarchy-undercover-show-desktop"), { description = "Show desktop" })
hl.bind("SUPER + B", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"), { description = "Toggle Dock/Taskbar Autohide" })
hl.bind("SUPER + ALT + U", hl.dsp.exec_cmd("omarchy-undercover --toggle"), { description = "Toggle Undercover Mode" })

-- Compositor frosted glass blur layer rules
hl.layer_rule({ match = { namespace = "mac-topbar" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "mac-dock" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = true })
hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, blur = true, ignore_alpha = true })
