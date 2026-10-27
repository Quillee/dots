-- Hyprland configuration entrypoint (native Lua config, Hyprland >= 0.55).
-- Launch with: Hyprland --config ~/.config/hypr/hyprland.lua
-- API reference: https://wiki.hypr.land/

-- Resolve `require("hypr.<module>")` to ~/.config/hypr/<module>.lua
package.path = os.getenv("HOME") .. "/.config/?.lua;" .. package.path

hl.config({
    cursor = {
        no_hardware_cursors = false
    }
})

require("hypr.looknfeel")
require("hypr.windowrules")
require("hypr.bindings")
require("hypr.autostart")
