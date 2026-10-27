-- Processes started once when Hyprland launches.
hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd("mako")
end)
