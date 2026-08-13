local active_border_color = { colors = { "rgba(0078d4ee)", "rgba(60cdffee)" }, angle = 45 }
local inactive_border_color = "rgba(45454580)"
local active_shadow_color = "rgba(0078d466)"
local inactive_shadow_color = "rgba(00000044)"

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
    rounding = 8,
    shadow = {
      enabled = true,
      range = 16,
      render_power = 3,
      color = active_shadow_color,
      color_inactive = inactive_shadow_color,
    },
  },
})
