local wezterm = require 'wezterm';

return {
  use_ime = true,
  use_fancy_tab_bar=false,
  font_size = 11.5,
  hide_tab_bar_if_only_one_tab = true,
  adjust_window_size_when_changing_font_size = false,
  window_background_opacity = 0.9,
  enable_wayland = true,
  window_decorations = "RESIZE",
  window_padding = {
    left = 4,
    right = 4,
    top = 0,
    bottom = 0,
  },
  color_scheme = "OneHalfDark",
  exit_behavior = "Close",
  window_close_confirmation = "NeverPrompt",
  colors = {
    foreground = "white",
    background = "black",
    ansi = {"black", "maroon", "green", "olive", "navy", "purple", "teal", "silver"},
    brights = {"grey", "red", "lime", "yellow", "blue", "fuchsia", "aqua", "white"},
  },
}
