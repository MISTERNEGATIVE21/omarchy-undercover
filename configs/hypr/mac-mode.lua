-- =============================================================================
-- Omarchy Undercover - Apple macOS Sequoia Mode for Hyprland (Lua module)
-- =============================================================================

local home = os.getenv("HOME")
local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local candidate_settings = {
  home .. "/omarchy-undercover/settings.conf",
  home .. "/.config/omarchy/plugins/omarchy-undercover/settings.conf",
  home .. "/.config/omarchy/plugins/undercover/settings.conf",
  script_dir and (script_dir .. "../../settings.conf"),
  "/usr/share/omarchy-undercover/settings.conf",
}
local settings_path = candidate_settings[1]
for _, p in ipairs(candidate_settings) do
  if p then
    local f = io.open(p, "r")
    if f then
      f:close()
      settings_path = p
      break
    end
  end
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
local variant = get_setting("THEME_VARIANT", "dark")
local state_paths = {
  home .. "/omarchy-undercover/state",
  home .. "/.config/omarchy/plugins/omarchy-undercover/state",
  home .. "/.config/omarchy/plugins/undercover/state",
}
for _, sp in ipairs(state_paths) do
  local sf = io.open(sp, "r")
  if sf then
    local s = sf:read("*l")
    sf:close()
    if s then
      if s:find("light") then variant = "light"
      elseif s:find("dark") then variant = "dark" end
      if s:find("mac") or s:find("ios") then mode = "mac" end
      break
    end
  end
end

if mode ~= "mac" and mode ~= "ios" then return end

-- ---------------------------------------------------------------------------
-- Script resolver: ensures commands resolve to plugin scripts if not in PATH
-- ---------------------------------------------------------------------------
local function find_script(name)
  local dirs = {
    home .. "/omarchy-undercover/scripts",
    script_dir and (script_dir .. "../../scripts"),
    home .. "/.config/omarchy/plugins/omarchy-undercover/scripts",
    home .. "/.config/omarchy/plugins/undercover/scripts",
    "/usr/share/omarchy-undercover/scripts",
  }
  for _, dir in ipairs(dirs) do
    if dir then
      local path = dir .. "/" .. name
      local f = io.open(path, "r")
      if f then
        f:close()
        return path
      end
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

local plugin_scripts = home .. "/omarchy-undercover/scripts"
local current_path = os.getenv("PATH") or "/usr/local/bin:/usr/bin:/bin"
if not current_path:find(plugin_scripts, 1, true) then
  hl.env("PATH", plugin_scripts .. ":" .. current_path)
end

local is_light = (variant == "light")
local bar_bg = is_light and "rgb(ececed)" or "rgb(282828)"
local bar_text = is_light and "rgb(1d1d1f)" or "rgb(f5f5f7)"
local active_border = is_light and "rgba(00000024)" or "rgba(ffffff20)"
local inactive_border = "rgba(00000000)"
local shadow_color = is_light and "rgba(00000028)" or "rgba(00000066)"

hl.config({
  general = {
    gaps_in = 6,
    gaps_out = 12,
    border_size = 1,
    col = {
      active_border = active_border,
      inactive_border = inactive_border,
    },
    layout = "dwindle",
  },
  decoration = {
    rounding = 16,
    active_opacity = is_light and 0.99 or 0.98,
    inactive_opacity = is_light and 0.94 or 0.92,
    fullscreen_opacity = 1.0,
    shadow = {
      enabled = true,
      range = is_light and 32 or 42,
      render_power = 4,
      color = shadow_color,
    },
    blur = {
      enabled = true,
      size = 16,
      passes = 4,
      special = true,
      noise = 0.015,
      contrast = is_light and 1.1 or 1.25,
      brightness = is_light and 1.0 or 1.05,
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
  animations = {
    enabled = true,
  },
})

-- Apple macOS Sequoia / Tahoe Spring & Fluid Animation Physics
hl.curve("macFluid", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })
hl.curve("macSpring", { type = "bezier", points = { { 0.1, 0.9 }, { 0.2, 1.0 } } })
hl.curve("macEase", { type = "bezier", points = { { 0.25, 1.0 }, { 0.5, 1.0 } } })
hl.curve("macFade", { type = "bezier", points = { { 0.0, 0.0 }, { 0.2, 1.0 } } })
hl.curve("macGenie", { type = "bezier", points = { { 0.2, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "global", enabled = true, speed = 5, bezier = "macFluid" })
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "macFluid" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "macSpring", style = "popin 82%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "macEase", style = "popin 82%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "macFluid" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "macFluid" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "macFade" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "macFade" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 3, bezier = "macFade" })
hl.animation({ leaf = "layers", enabled = true, speed = 5, bezier = "macFluid" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "macSpring", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "macEase", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "macEase", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 5, bezier = "macEase", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 4, bezier = "macEase", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "macFluid", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 5, bezier = "macSpring", style = "slide bottom" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 4, bezier = "macEase", style = "slide bottom" })

-- ---------------------------------------------------------------------------
-- Dedicated Undercover toggle shortcuts (non-conflicting with base bindings)
-- ---------------------------------------------------------------------------
if hl and hl.bind then
  local toggle_key = get_setting("BIND_UNDERCOVER_TOGGLE", "SUPER + ALT + U")
  hl.bind(toggle_key, exec_cmd("omarchy-undercover --toggle"), { description = "Toggle Undercover Mode" })
  hl.bind("SUPER + ALT + B", exec_cmd("omarchy-undercover-autohide --toggle"), { description = "Toggle Edge Auto-Hide Daemon" })
end

-- Suppress stock Omarchy dock in Undercover mode (use only undercover extensions)
if hl and hl.keyword then
  hl.keyword("layerrule", "ignorezero, omarchy-dock")
  hl.keyword("layerrule", "ignorealpha 1.0, omarchy-dock")
end

-- Rebind Omarchy's native file manager shortcut to use the disguised undercover variant
if o and o.rebind then
  o.rebind("SUPER + SHIFT + F", "File manager", exec_cmd("omarchy-undercover-filemanager"))
  o.rebind("SUPER + ALT + SHIFT + F", "File manager (cwd)", exec_cmd("omarchy-undercover-filemanager " .. home))
end

-- ---------------------------------------------------------------------------
-- Configurable macOS Sequoia Keybindings
-- ---------------------------------------------------------------------------
local keybindings_enabled = get_setting("ENABLE_KEYBINDINGS", "false") == "true"
local override_omarchy = get_setting("OVERRIDE_DEFAULT_KEYBINDINGS", "false") == "true"

if keybindings_enabled and hl and hl.bind then
  local function bind_key(setting_key, default_key, action, desc, extra_opts)
    local key = get_setting(setting_key, default_key)
    if key and key ~= "" and key:lower() ~= "none" and key:lower() ~= "disabled" then
      -- Strictly protect Omarchy defaults unless user explicitly opted into overriding them
      if not override_omarchy then
        if key == "SUPER + W" or key == "SUPER + SPACE" then
          return
        end
      end

      local opts = { description = desc }
      if extra_opts then
        for k, v in pairs(extra_opts) do opts[k] = v end
      end
      if key ~= "SUPER + W" and key ~= "SUPER + Q" then
        pcall(function() hl.unbind(key) end)
      end
      hl.bind(key, action, opts)
    end
  end

  -- macOS Spotlight Search (Safe combo Super+Alt+Space by default so Omarchy Super+Space is never touched)
  local default_spotlight = override_omarchy and "SUPER + SPACE" or "SUPER + ALT + SPACE"
  bind_key("BIND_MAC_SPOTLIGHT", default_spotlight, exec_cmd("omarchy-undercover-launcher"), "macOS Spotlight Search")
  -- Mission Control: SUPER+ALT+TAB avoids conflict with Omarchy's SUPER+TAB (next workspace)
  bind_key("BIND_MAC_MISSIONCONTROL", "SUPER + ALT + TAB", exec_cmd("rofi -show window -theme ~/.config/rofi/mac.rasi"), "macOS Mission Control")
  bind_key("BIND_MAC_WIDGETS", "SUPER + N", exec_cmd("omarchy-mac-widgets"), "macOS Notification Center & Widgets")
  bind_key("BIND_MAC_SETTINGS", "SUPER + COMMA", exec_cmd("uwsm-app -- omarchy-undercover-settings"), "macOS System Settings")
  bind_key("BIND_MAC_FINDER", "SUPER + E", exec_cmd("omarchy-undercover-filemanager"), "macOS Finder")
  bind_key("BIND_MAC_MINIMIZE", "SUPER + M", exec_cmd("omarchy-undercover-minimize"), "Minimize window")
  bind_key("BIND_MAC_DESKTOP", "SUPER + D", exec_cmd("omarchy-undercover-show-desktop"), "Show desktop")
  local lock_cmd_str = "qs -p /usr/share/omarchy/shell ipc call omarchy-undercover-service lock 2>/dev/null || qs ipc call omarchy-undercover-service lock 2>/dev/null || " .. find_script("omarchy-mac-screensaver") .. " --lock || omarchy-system-lock || hyprlock || loginctl lock-session"
  bind_key("BIND_MAC_LOCK", "SUPER + CTRL + Q", hl.dsp.exec_cmd(lock_cmd_str), "Lock screen (macOS shortcut)", { locked = true })
  bind_key("BIND_LINUX_LOCK", "SUPER + CTRL + L", hl.dsp.exec_cmd(lock_cmd_str), "Lock screen (Linux shortcut)", { locked = true })
  bind_key("BIND_MAC_ACTIVITYMONITOR", "SUPER + ALT + ESCAPE", exec_cmd("omarchy-mac-activitymonitor"), "Activity Monitor / Force Quit")
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

-- ---------------------------------------------------------------------------
-- Free Roam / Floating Window Controls: Apple macOS Traffic Lights (Hyprbars)
-- ---------------------------------------------------------------------------
local function configure_mac_titlebars()
  if not hl or not hl.config then return end

  local TITLEBARS = "/usr/lib/omarchy-hyprland-titlebars/titlebars.so"
  local f = io.open(TITLEBARS, "r")
  local plugin_available = false
  if f then
    f:close()
    if hl.plugin and hl.plugin.load then
      pcall(function() hl.plugin.load(TITLEBARS) end)
    end
    plugin_available = true
  else
    if hl.plugin and hl.plugin.hyprbars then
      plugin_available = true
    end
  end

  if not plugin_available then return end

  local mac_hyprbars = {
    enabled = true,
    workspace_tag = "omarchy-floating-workspace",
    bar_height = 28,
    bar_color = bar_bg,
    col = { text = bar_text },
    bar_text_font = "SF Pro Display",
    bar_text_size = 11,
    bar_text_align = "center",
    bar_buttons_alignment = "left",
    bar_padding = 12,
    bar_button_padding = 8,
    button_rounding = 10,
    icon_on_hover = true,
    inactive_button_color = is_light and "rgba(00000020)" or "rgba(ffffff20)",
    bar_part_of_window = true,
    bar_precedence_over_border = true,
  }

  hl.config({
    plugin = {
      hyprbars = mac_hyprbars,
    },
  })

  -- Intercept hl.config so that when workspace-modes.lua configures titlebars,
  -- macOS traffic light settings take precedence over standard right-aligned buttons.
  if not hl._orig_config_undercover then
    hl._orig_config_undercover = hl.config
  end
  hl.config = function(tbl)
    if tbl and tbl.plugin and tbl.plugin.hyprbars then
      local hb = tbl.plugin.hyprbars
      hb.enabled = true
      hb.workspace_tag = "omarchy-floating-workspace"
      hb.bar_height = 28
      hb.bar_color = bar_bg
      hb.col = { text = bar_text }
      hb.bar_buttons_alignment = "left"
      hb.button_rounding = 10
      hb.bar_text_align = "center"
      hb.icon_on_hover = true
      hb.bar_button_padding = 8
      hb.bar_padding = 12
      hb.bar_part_of_window = true
      hb.bar_precedence_over_border = true
    end
    return hl._orig_config_undercover(tbl)
  end

  -- Directly register authentic macOS traffic lights on the left:
  -- Red dot (Close), Yellow dot (Minimize), Green dot (Maximize / Zoom)
  if hl.plugin and hl.plugin.hyprbars and hl.plugin.hyprbars.add_button then
    local window_target = 'window = "address:%WINDOW%"'
    pcall(function()
      -- 1. Close: Red dot (#ff5f56)
      hl.plugin.hyprbars.add_button({
        bg_color = "rgb(ff5f56)",
        fg_color = "rgb(4d0000)",
        size = 13,
        icon = "×",
        action = "hyprctl dispatch 'hl.dsp.window.close({ " .. window_target .. " })'",
      })
      -- 2. Minimize: Yellow dot (#ffbd2e)
      hl.plugin.hyprbars.add_button({
        bg_color = "rgb(ffbd2e)",
        fg_color = "rgb(5c3b00)",
        size = 13,
        icon = "−",
        action = "omarchy-hyprland-window-minimize %WINDOW%",
      })
      -- 3. Maximize / Zoom: Green dot (#27c93f)
      hl.plugin.hyprbars.add_button({
        bg_color = "rgb(27c93f)",
        fg_color = "rgb(004d11)",
        size = 13,
        icon = "+",
        action = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\", " .. window_target .. " })'",
      })
    end)

    -- Intercept subsequent calls from workspace-modes.lua to prevent monotone button pollution
    hl.plugin.hyprbars.add_button = function(spec)
      return
    end
  end

  -- Hook into workspace-modes.apply so mode stays locked to macOS on workspace layout changes
  local ok, wm = pcall(require, "default.hypr.workspace-modes")
  if ok and wm and wm.apply then
    if not wm._orig_apply_undercover then
      wm._orig_apply_undercover = wm.apply
    end
    wm.apply = function(...)
      local res = wm._orig_apply_undercover(...)
      if hl and hl.config then
        hl.config({
          plugin = {
            hyprbars = mac_hyprbars,
          },
        })
      end
      return res
    end
  end
end

configure_mac_titlebars()



