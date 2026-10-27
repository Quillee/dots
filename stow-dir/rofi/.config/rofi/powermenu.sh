#!/usr/bin/env bash
# Rofi power menu for Hyprland. Theme: ~/.config/rofi/powermenu.rasi

theme="$HOME/.config/rofi/powermenu.rasi"

lock="  Lock"
logout="  Logout"
suspend="  Suspend"
reboot="  Reboot"
shutdown="  Shutdown"

chosen=$(printf '%s\n' "$lock" "$logout" "$suspend" "$reboot" "$shutdown" \
    | rofi -dmenu -i -p "Power" -theme "$theme")

case "$chosen" in
    "$lock")     hyprlock ;;
    "$logout")   hyprctl dispatch exit ;;
    "$suspend")  systemctl suspend ;;
    "$reboot")   systemctl reboot ;;
    "$shutdown") systemctl poweroff ;;
esac
