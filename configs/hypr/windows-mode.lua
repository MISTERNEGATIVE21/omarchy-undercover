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

local settings_path = os.getenv("HOME") .. "/.config/omarchy-undercover/settings.conf"

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
local cursor_size   = tonumber(get_setting("CURSOR_SIZE", "24")) or 24
local mode          = get_setting("MODE", "windows")

-- Bail out gracefully if the user turned windows mode off but left the file.
if mode ~= "windows" then
  return
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
o.exec_on_start("omarchy-undercover-wallpaper")

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

    shadow = {
      enabled = true,
      range = 24,
      render_power = 3,
      color = "rgba(00000066)",
    },

    blur = {
      enabled = blur_on,
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
  hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "fluent", style = "popin 90%" })
  hl.animation({ leaf = "fade", enabled = true, speed = 6, bezier = "fluent" })
  hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "fluent" })
  hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, bezier = "fluent" })
  hl.animation({ leaf = "layers", enabled = true, speed = 6, bezier = "fluent" })
  hl.animation({ leaf = "layersIn", enabled = true, speed = 5, bezier = "fluent", style = "fade" })
  hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "fluent", style = "fade" })
  hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "fluent" })
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

-- Windows do not need a visible border when inactive (Win11 "flat" windows).
hl.window_rule({
  match = { class = ".*" },
  border_color = { colors = { "rgba(" .. accent .. "ff)", "rgba(00b7c3ff)" }, angle = 45 },
})

-- ---------------------------------------------------------------------------
-- Windows 11 keybindings
--
-- Conflicts with existing Omarchy binds are explicitly unbound first so these
-- behave exactly like Windows. Case matters for hl.unbind().
-- ---------------------------------------------------------------------------

-- Start menu (press-and-release the Win key opens the Start menu)
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("omarchy-undercover-launcher"), { release = true, description = "Start menu" })

-- Win + Space: also open the Start menu (used to be the Omarchy launcher)
hl.unbind("SUPER + SPACE")
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("omarchy-undercover-launcher"), { description = "Start menu" })

-- Win + Tab: Task View (window switcher)
hl.unbind("SUPER + TAB")
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("rofi -show window -theme ~/.config/rofi/windows11.rasi"), { description = "Task view" })

-- Win + D: Show desktop
hl.bind("SUPER + D", hl.dsp.exec_cmd("omarchy-undercover-show-desktop"), { description = "Show desktop" })

-- Win + E: File Explorer - opens the "My Computer" (This PC) screen with a
-- stock GNOME look but Windows app skin (Fluent) icons
hl.bind("SUPER + E", hl.dsp.exec_cmd("env GTK_THEME=Adwaita:dark GTK_ICON_THEME=Fluent-dark nautilus --new-window computer:///"), { description = "File explorer" })

-- Win + I: Settings
hl.bind("SUPER + I", hl.dsp.exec_cmd("uwsm-app -- omarchy-undercover-settings"), { description = "Settings" })

-- Win + A: Quick settings
hl.bind("SUPER + A", hl.dsp.exec_cmd("uwsm-app -- omarchy-undercover-settings --page system"), { description = "Quick settings" })

-- Win + R: Run dialog
hl.bind("SUPER + R", hl.dsp.exec_cmd("rofi -show run -theme ~/.config/rofi/windows11.rasi"), { description = "Run dialog" })

-- Win + M: Minimize active window
hl.bind("SUPER + M", hl.dsp.exec_cmd("omarchy-undercover-minimize"), { description = "Minimize window" })

-- Win + L: Lock screen (was "toggle workspace layout")
hl.unbind("SUPER + L")
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock || swaylock || loginctl lock-session"), { description = "Lock screen", locked = true })

-- Win + V: Clipboard history
hl.unbind("SUPER + V")
hl.bind("SUPER + V", hl.dsp.exec_cmd("omarchy-launch-walker -m clipboard"), { description = "Clipboard history" })

-- Win + . : Emoji / symbols picker
hl.bind("SUPER + PERIOD", hl.dsp.exec_cmd("omarchy-launch-walker -m symbols"), { description = "Emoji picker" })

-- Win + Shift + S: Region screenshot (copied to clipboard)
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("omarchy capture screenshot region copy"), { description = "Region screenshot" })

-- Alt + F4: Close window
hl.bind("ALT + F4", hl.dsp.window.close(), { description = "Close window" })

-- Win + Q: Quick assist (terminal) - handy replacement for Win+W (widgets)
hl.bind("SUPER + Q", hl.dsp.exec_cmd("xdg-terminal-exec"), { description = "Terminal (quick)" })

-- Win + B: Toggle Taskbar Visibility (Instant hide / reveal for Quickshell & Waybar)
hl.bind("SUPER + B", hl.dsp.exec_cmd("omarchy-undercover-toggle-bar"), { description = "Toggle taskbar visibility" })

-- Win + Alt + B: Toggle Intelligent Edge Auto-Hide Daemon
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd("omarchy-undercover-autohide --toggle"), { description = "Toggle edge auto-hide" })

-- Super + Alt + U: Toggle Undercover Mode
hl.bind("SUPER + ALT + U", hl.dsp.exec_cmd("omarchy-undercover --toggle"), { description = "Toggle undercover mode" })

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
