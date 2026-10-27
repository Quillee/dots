-- Keybindings. See https://wiki.hypr.land/Configuring/Basics/Binds/

local mod = "SUPER"

local terminal = "kitty"
local fileManager = "dolphin"
local menu = "rofi -modi drun -show drun -config ~/.config/rofi/rofidmenu.rasi"

-- Applications
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + W", hl.dsp.exec_cmd("firefox"))
hl.bind(mod .. " + N", hl.dsp.exec_cmd("thunar"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mod .. " + D", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + T", hl.dsp.exec_cmd("rofi -show window -config ~/.config/rofi/rofidmenu.rasi"))

-- Session
hl.bind(mod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind(mod .. " + grave", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("~/.config/rofi/powermenu.sh"))

-- Layout
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SPACE", hl.dsp.window.cycle_next())

-- Focus (hjkl) and move window (SHIFT + hjkl), plus arrow-key equivalents
local directions = {
  { "H", "left", "l" },
  { "J", "down", "d" },
  { "K", "up", "u" },
  { "L", "right", "r" },
}
for _, d in ipairs(directions) do
  local letter, arrow, dir = d[1], d[2], d[3]
  hl.bind(mod .. " + " .. letter, hl.dsp.focus({ direction = dir }))
  hl.bind(mod .. " + " .. arrow, hl.dsp.focus({ direction = dir }))
  hl.bind(mod .. " + SHIFT + " .. letter, hl.dsp.window.move({ direction = dir }))
  hl.bind(mod .. " + SHIFT + " .. arrow, hl.dsp.window.move({ direction = dir }))
end

-- Workspaces (switch + move active window)
for ws = 1, 10 do
  local key = ws == 10 and "0" or tostring(ws)
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = tostring(ws) }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(ws) }))
end

-- Workspaces (cycle)
hl.bind(mod .. " + TAB", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))

-- Resize submap (SUPER+R to enter, Return/Escape to exit)
hl.bind(mod .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
  local step = 20
  hl.bind("H", hl.dsp.window.resize({ x = -step, y = 0, relative = true }), { repeating = true })
  hl.bind("J", hl.dsp.window.resize({ x = 0, y = step, relative = true }), { repeating = true })
  hl.bind("K", hl.dsp.window.resize({ x = 0, y = -step, relative = true }), { repeating = true })
  hl.bind("L", hl.dsp.window.resize({ x = step, y = 0, relative = true }), { repeating = true })
  hl.bind("left", hl.dsp.window.resize({ x = -step, y = 0, relative = true }), { repeating = true })
  hl.bind("down", hl.dsp.window.resize({ x = 0, y = step, relative = true }), { repeating = true })
  hl.bind("up", hl.dsp.window.resize({ x = 0, y = -step, relative = true }), { repeating = true })
  hl.bind("right", hl.dsp.window.resize({ x = step, y = 0, relative = true }), { repeating = true })
  hl.bind("Return", hl.dsp.submap("reset"))
  hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Mouse (drag/resize floating windows)
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pamixer --default-source -t"))
hl.bind(mod .. " + XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 1"))
hl.bind(mod .. " + XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 1"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +10%"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"))

-- Screenshots
hl.bind(
  mod .. " + SHIFT + S",
  hl.dsp.exec_cmd([[mkdir -p ~/Pictures/screenshots && grim -g "$(slurp)" - | tee ~/Pictures/screenshots/$(date +%Y-%m-%d-%H-%M-%S)-screenshot.png | wl-copy && notify-send "Screenshot saved & copied"]])
)

-- Groups (tabbed/stacked windows)
hl.bind(mod .. " + G", hl.dsp.group.toggle())
hl.bind(mod .. " + bracketright", hl.dsp.group.next())
hl.bind(mod .. " + bracketleft", hl.dsp.group.prev())
