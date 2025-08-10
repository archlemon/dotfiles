#!/bin/bash

options="Brave Search\nGoogle Search\ngh GitHub Search\nyt YouTube Search"

selection=$(echo -e "$options" | wofi --dmenu --prompt "Search type:" --conf ~/.config/wofi/config --style ~/.config/wofi/mocha.css)

[[ -z "$selection" ]] && exit 0

query=$(wofi --dmenu --prompt "Search:" --conf ~/.config/wofi/config --style ~/.config/wofi/mocha.css)
[[ -z "$query" ]] && exit 0

case "$selection" in
    "Brave Search")
        firefox "https://search.brave.com/search?q=${query// /+}" &
        ;;
    "Google Search")
        firefox "https://www.google.com/search?q=${query// /+}" &
        ;;
    "gh GitHub Search")
        firefox "https://github.com/search?q=${query// /+}" &
        ;;
    "yt YouTube Search")
        firefox "https://www.youtube.com/results?search_query=${query// /+}" &
        ;;
    *)
        notify-send "Unknown search type"
        ;;
esac

