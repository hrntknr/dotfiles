local wezterm = require("wezterm")
local act = wezterm.action

wezterm.on("gui-startup", function(cmd)
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

wezterm.on("format-tab-title", function(tab)
  local width = 24
  local title = tab.tab_title ~= "" and tab.tab_title or tab.active_pane.title
  title = " " .. wezterm.truncate_right(title, width - 2) .. " "

  local padding = width - wezterm.column_width(title)
  if padding > 0 then
    title = title .. string.rep(" ", padding)
  end

  return title
end)

wezterm.on("user-var-changed", function(window, pane, name, uri)
  if name ~= "open-uri" then
    return
  end

  local scheme = uri:match("^([%a][%w+.-]*):")
  if not scheme then
    return
  end

  if scheme == "http" or scheme == "https" or scheme == "vscode" or scheme == "vscode-insiders" then
    wezterm.open_with(uri)
    return
  end

  window:perform_action(
    act.PromptInputLine({
      description = "Open external URI? Type 'open' to continue: " .. uri,
      action = wezterm.action_callback(function(_, _, line)
        if line == "open" then
          wezterm.open_with(uri)
        end
      end),
    }),
    pane
  )
end)

return {
  colors = {
    foreground = "#abb2bf",
    background = "#21252b",
    cursor_bg = "#abb2bf",
    cursor_fg = "#21252b",
    selection_fg = "#abb2bf",
    selection_bg = "#323844",
    ansi = {
      "#21252b",
      "#e06c75",
      "#98c379",
      "#e5c07b",
      "#61afef",
      "#c678dd",
      "#56b6c2",
      "#abb2bf",
    },
    brights = {
      "#767676",
      "#e06c75",
      "#98c379",
      "#e5c07b",
      "#61afef",
      "#c678dd",
      "#56b6c2",
      "#abb2bf",
    },
    tab_bar = {
      active_tab = {
        bg_color = "#3a4152",
        fg_color = "#f1f5f9",
      },
    },
  },
  font = wezterm.font_with_fallback({
    "Fira Mono for Powerline",
    "Hiragino Sans",
  }),
  font_size = 13.0,
  line_height = 1.12,

  window_frame = {
    font_size = 14.0,
  },

  default_cursor_style = "SteadyBlock",

  keys = {
    {
      key = "¥",
      mods = "ALT",
      action = act.SendString("\\"),
    },
  },

  ssh_domains = {
    {
      name = "pm1",
      remote_address = "pm1.hrntknr.net:9443",
      ssh_option = {
        proxycommand = "qrelay nc --connect pm1.hrntknr.net:9443 --fingerprint 3d:d9:c1:f9:33:03:db:10:86:78:8e:58:0e:82:95:4c:2e:ed:d3:14:7e:c1:a1:4c:62:10:a6:dd:a6:64:96:f7",
      },
    },
  },
  ssh_backend = "Ssh2",

  use_fancy_tab_bar = true,
  hide_tab_bar_if_only_one_tab = false,
  window_decorations = "INTEGRATED_BUTTONS|RESIZE",

  window_padding = {
    left = 10,
    right = 10,
    top = 4,
    bottom = 4,
  },
}
