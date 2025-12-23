#!/usr/bin/env bash

# Install:
# exec path: /home/matt/.local/bin/godot-nvim.sh
# exec flags: {file} {line} {col}

NVIM_SERVER="/tmp/godot-nvim"
FILE="$1"
LINE="$2"
COL="$3"

if ! nvr --servername "$NVIM_SERVER" --nostart --remote-expr "1" >/dev/null 2>&1; then
    kitty --class nvim-godot \
        nvim --listen "$NVIM_SERVER" &
    sleep 0.2
fi

if [[ -n "$LINE" ]]; then
    nvr --servername "$NVIM_SERVER" \
        --remote-silent +"call cursor(${LINE}, ${COL:-1})" "$FILE"
else
    nvr --servername "$NVIM_SERVER" --remote-silent "$FILE"
fi

hyprctl dispatch focuswindow class:nvim-godot >/dev/null 2>&1 || true

