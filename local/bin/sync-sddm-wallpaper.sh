#!/bin/bash
WALLPAPER=$(qs -c noctalia-shell ipc call wallpaper get "eDP-1")

if [ -f "$WALLPAPER" ]; then
    sudo cp "$WALLPAPER" /usr/share/sddm/themes/simple_sddm_2/Backgrounds/default
    wal -i "$WALLPAPER" -n -s -t -q
fi
