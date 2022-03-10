local wezterm = require 'wezterm';

return {
  font = wezterm.font_with_fallback({
    "Firge35 Console",
  }),
  font_dirs = {"fonts"},
  font_size = 11,
  use_ime = true,
  adjust_window_size_when_changing_font_size = false,

  use_fancy_tab_bar=false,
  hide_tab_bar_if_only_one_tab = true,

  enable_wayland = true,
  window_background_opacity = 0.9,
  window_decorations = "RESIZE",
  window_padding = {
    left = 4,
    right = 4,
    top = 0,
    bottom = 0,
  },
  window_close_confirmation = "NeverPrompt",
  exit_behavior = "Close",

  color_scheme = "OneHalfDark",
  colors = {
    foreground = "white",
    background = "black",
    ansi = {"black", "maroon", "green", "olive", "navy", "purple", "teal", "silver"},
    brights = {"grey", "red", "lime", "yellow", "blue", "fuchsia", "aqua", "white"},
  },
}
