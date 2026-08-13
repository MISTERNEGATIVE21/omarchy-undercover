local active_border_color = "rgba(00000022)"
local inactive_border_color = "rgba(00000010)"
local active_shadow_color = "rgba(00000033)"
local inactive_shadow_color = "rgba(0000001a)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
  decoration = {
    rounding = 12,
    shadow = {
      enabled = true,
      range = 24,
      render_power = 4,
      color = active_shadow_color,
      color_inactive = inactive_shadow_color,
    },
  },
})
