#!/usr/bin/env bash

chosen=$(echo -e "  Power Off\n  Reboot\n  Lock\n  Logout\n  Suspend" | rofi -dmenu -i -p "Power Menu")

case "$chosen" in
    *Power\ Off) systemctl poweroff ;;
    *Reboot) systemctl reboot ;;
    *Lock) loginctl lock-session ;;
    *Logout) hyprctl dispatch exit ;;
    *Suspend) systemctl suspend ;;
esac