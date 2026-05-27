local wezterm = require("wezterm")
local act = wezterm.action
local downloads = {}

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
  local function downloads_dir()
    return (os.getenv("HOME") or ".") .. "/Downloads"
  end

  local function mkdir_p(path)
    wezterm.run_child_process({ "/bin/mkdir", "-p", path })
  end

  local function open_folder(path)
    if (wezterm.target_triple or ""):find("darwin", 1, true) then
      wezterm.run_child_process({ "/usr/bin/open", path })
    end
  end

  local function safe_basename(path)
    local basename = path:gsub("\\", "/"):match("([^/]+)$") or "download"
    basename = basename:gsub("[%z/\\:]", "_")
    if basename == "" or basename == "." or basename == ".." then
      return "download"
    end
    return basename
  end

  local function available_path(dir, name)
    local path = dir .. "/" .. name
    local file = io.open(path, "rb")
    if not file then
      return path
    end
    file:close()

    local stem, ext = name:match("^(.*)(%.[^.]*)$")
    if not stem or stem == "" then
      stem = name
      ext = ""
    end

    local i = 1
    while true do
      path = string.format("%s/%s %d%s", dir, stem, i, ext)
      file = io.open(path, "rb")
      if not file then
        return path
      end
      file:close()
      i = i + 1
    end
  end

  local function base64_decode(data)
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    data = data:gsub("[^" .. alphabet .. "=]", "")
    return (
      data
        :gsub(".", function(char)
          if char == "=" then
            return ""
          end
          local bits = ""
          local value = alphabet:find(char, 1, true) - 1
          for i = 6, 1, -1 do
            bits = bits .. (value % 2 ^ i - value % 2 ^ (i - 1) > 0 and "1" or "0")
          end
          return bits
        end)
        :gsub("%d%d%d?%d?%d?%d?%d?%d?", function(bits)
          if #bits ~= 8 then
            return ""
          end
          local value = 0
          for i = 1, 8 do
            value = value + (bits:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
          end
          return string.char(value)
        end)
    )
  end

  local function write_download(id)
    local entry = downloads[id]
    if not entry then
      return
    end

    local dir = downloads_dir()
    mkdir_p(dir)
    local path = available_path(dir, entry.name)

    local file = io.open(path, "wb")
    if not file then
      window:toast_notification("download", "failed to write " .. path, nil, 5000)
      downloads[id] = nil
      return
    end

    for i = 0, entry.total - 1 do
      file:write(entry.chunks[i] or "")
    end
    file:close()

    open_folder(dir)

    window:toast_notification("download", path, nil, 3000)
    downloads[id] = nil
  end

  if name == "download-start" then
    local id, filename, total = uri:match("^([^\t]+)\t([^\t]+)\t(%d+)$")
    if not id then
      return
    end

    downloads[id] = {
      name = safe_basename(filename),
      total = tonumber(total) or 0,
      chunks = {},
      received = 0,
    }

    if downloads[id].total == 0 then
      write_download(id)
    end
    return
  end

  local id, seq = name:match("^download%-chunk%-(%d+)%-(%d+)$")
  if id then
    local entry = id and downloads[id] or nil
    seq = tonumber(seq)
    if not entry or not seq or seq < 0 or seq >= entry.total or entry.chunks[seq] then
      return
    end

    entry.chunks[seq] = base64_decode(uri)
    entry.received = entry.received + 1
    if entry.received == entry.total then
      write_download(id)
    end
    return
  end

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

  leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 },

  keys = {
    {
      key = "b",
      mods = "LEADER|CTRL",
      action = act.SendKey({ key = "b", mods = "CTRL" }),
    },
    {
      key = "c",
      mods = "LEADER",
      action = act.SpawnTab("CurrentPaneDomain"),
    },
    {
      key = "%",
      mods = "LEADER|SHIFT",
      action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
    },
    {
      key = '"',
      mods = "LEADER|SHIFT",
      action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
    },
    {
      key = "z",
      mods = "LEADER",
      action = act.TogglePaneZoomState,
    },
    {
      key = "LeftArrow",
      mods = "LEADER",
      action = act.ActivatePaneDirection("Left"),
    },
    {
      key = "DownArrow",
      mods = "LEADER",
      action = act.ActivatePaneDirection("Down"),
    },
    {
      key = "UpArrow",
      mods = "LEADER",
      action = act.ActivatePaneDirection("Up"),
    },
    {
      key = "RightArrow",
      mods = "LEADER",
      action = act.ActivatePaneDirection("Right"),
    },
    {
      key = "¥",
      mods = "ALT",
      action = act.SendString("\\"),
    },
    {
      key = "Enter",
      mods = "ALT",
      action = act.SendKey({ key = "Enter", mods = "ALT" }),
    },
  },

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
