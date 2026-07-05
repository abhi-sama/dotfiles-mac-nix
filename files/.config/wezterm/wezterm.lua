local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

local is_windows = os.getenv("OS") and os.getenv("OS"):lower():find("windows")
local is_macos = wezterm.target_triple:lower():find("darwin") ~= nil

-- ─────────────────────────────────────────────────────────────────────────
-- Appearance
-- ─────────────────────────────────────────────────────────────────────────
config.color_scheme = "rose-pine-moon"
config.max_fps = 120
config.font = wezterm.font("Hack Nerd Font", { weight = "DemiBold" })
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_padding = { left = 12, right = 12, top = 10, bottom = 6 }
config.scrollback_lines = 10000
-- keep all panes fully visible (no dimming of the inactive pane)
config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 1.0,
}

-- rose-pine-moon palette (used by the custom tab/status bar below)
local palette = {
  base = "#232136",
  surface = "#2a273f",
  overlay = "#393552",
  muted = "#6e6a86",
  text = "#e0def4",
  love = "#eb6f92",
  gold = "#f6c177",
  rose = "#ea9a97",
  pine = "#3e8fb0",
  foam = "#9ccfd8",
  iris = "#c4a7e7",
}

-- ─────────────────────────────────────────────────────────────────────────
-- Tab bar (slim, custom, powerline-ish)
-- ─────────────────────────────────────────────────────────────────────────
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32
config.window_frame = {
  font = wezterm.font("Hack Nerd Font", { weight = "Bold" }),
}
config.colors = {
  tab_bar = {
    background = palette.base,
    new_tab = { bg_color = palette.base, fg_color = palette.muted },
    new_tab_hover = { bg_color = palette.overlay, fg_color = palette.text },
  },
}

-- Shorten a path/title for the tab
local function tab_title(tab)
  local title = tab.tab_title
  if title and #title > 0 then
    return title
  end
  -- fall back to the foreground process / cwd basename
  local pane = tab.active_pane
  local proc = pane.foreground_process_name or ""
  proc = proc:gsub("(.*[/\\])(.*)", "%2")
  if proc == "" or proc == "zsh" or proc == "bash" or proc == "-zsh" then
    local cwd = pane.current_working_dir
    if cwd then
      local p = cwd.file_path or tostring(cwd)
      return p:gsub("(.*/)(.*)", "%2")
    end
  end
  return proc
end

wezterm.on("format-tab-title", function(tab, _, _, _, hover)
  local i = tab.tab_index + 1
  local title = tab_title(tab)
  local active = tab.is_active
  local bg = active and palette.iris or (hover and palette.overlay or palette.surface)
  local fg = active and palette.base or palette.text
  local edge = palette.base
  local LEFT = wezterm.nerdfonts.pl_left_hard_divider  --
  local RIGHT = wezterm.nerdfonts.pl_right_hard_divider --
  return {
    { Background = { Color = edge } },
    { Foreground = { Color = bg } },
    { Text = LEFT },
    { Background = { Color = bg } },
    { Foreground = { Color = fg } },
    { Text = " " .. i .. " " .. title .. " " },
    { Background = { Color = edge } },
    { Foreground = { Color = bg } },
    { Text = RIGHT },
  }
end)

-- ─────────────────────────────────────────────────────────────────────────
-- Status bar (right side): workspace · battery · date/time
-- ─────────────────────────────────────────────────────────────────────────
wezterm.on("update-right-status", function(window, _)
  local cells = {}

  -- workspace (leader mode indicator)
  local ws = window:active_workspace()
  if window:leader_is_active() then
    ws = "LEADER " .. ws
  end
  table.insert(cells, { fg = palette.foam, text = wezterm.nerdfonts.cod_terminal .. " " .. ws })

  -- battery
  for _, b in ipairs(wezterm.battery_info()) do
    local pct = math.floor(b.state_of_charge * 100)
    local icon = wezterm.nerdfonts.md_battery
    if b.state == "Charging" then
      icon = wezterm.nerdfonts.md_battery_charging
    elseif pct <= 20 then
      icon = wezterm.nerdfonts.md_battery_alert
    end
    table.insert(cells, { fg = palette.gold, text = icon .. " " .. pct .. "%" })
  end

  -- clock
  table.insert(cells, { fg = palette.rose, text = wezterm.nerdfonts.md_clock_outline .. " " .. wezterm.strftime("%a %b %d  %H:%M") })

  local elements = {}
  for i, cell in ipairs(cells) do
    if i > 1 then
      table.insert(elements, { Foreground = { Color = palette.muted } })
      table.insert(elements, { Text = "  " .. wezterm.nerdfonts.ple_left_half_circle_thick .. " " })
    end
    table.insert(elements, { Foreground = { Color = cell.fg } })
    table.insert(elements, { Text = cell.text })
  end
  table.insert(elements, { Text = "  " })
  window:set_right_status(wezterm.format(elements))
end)

-- ─────────────────────────────────────────────────────────────────────────
-- Keybindings — tmux-style leader (CTRL-a)
-- ─────────────────────────────────────────────────────────────────────────
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1500 }
config.keys = {
  -- Cmd+Shift+V → send Ctrl+V so Claude Code's image-from-clipboard paste
  -- triggers with a mac-native key, while plain Cmd+V keeps normal text paste.
  { key = "v", mods = "CMD|SHIFT", action = act.SendKey({ key = "v", mods = "CTRL" }) },

  -- splits
  { key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

  -- pane navigation (vim keys)
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

  -- pane resize
  { key = "LeftArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Left", 5 }) },
  { key = "DownArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Down", 5 }) },
  { key = "UpArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Up", 5 }) },
  { key = "RightArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Right", 5 }) },

  -- pane management
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

  -- tabs
  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
  { key = "&", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },

  -- workspaces (built-in multiplexer)
  { key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
  { key = "s", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },

  -- misc
  { key = "f", mods = "LEADER", action = act.ToggleFullScreen },
  { key = "r", mods = "LEADER", action = act.ReloadConfiguration },
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
}

-- leader + <number> jumps to that tab
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "LEADER",
    action = act.ActivateTab(i - 1),
  })
end

-- ─────────────────────────────────────────────────────────────────────────
-- Platform-specific
-- ─────────────────────────────────────────────────────────────────────────
if is_windows then
  config.win32_system_backdrop = "Acrylic"
  config.window_background_opacity = 0.7
  config.window_frame.font_size = 10.0
end

if is_macos then
  config.window_background_opacity = 0.8
  config.macos_window_background_blur = 50
  config.font_size = 15.0
  config.window_frame.font_size = 13.0
end

return config
