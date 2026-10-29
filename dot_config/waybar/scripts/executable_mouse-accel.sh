#!/usr/bin/env bash

set -euo pipefail

WAYBAR_SIG="${WAYBAR_SIG:-10}"
SHOW_NOTIFY="${SHOW_NOTIFY:-1}"

get_profile() {
  hyprctl -j getoption input:accel_profile 2>/dev/null \
    | jq -r '.str // empty | if . == "" or . == "[[EMPTY]]" then "adaptive" else . end'
}

set_profile() {
  local profile="$1" # "flat" or "adaptive"
  hyprctl eval "hl.config({ input = { accel_profile = \"${profile}\" } })" >/dev/null
}

make_json() {
  local profile="$1" # flat | adaptive | (empty if unknown)
  local status icon cls tip

  case "$profile" in
    flat)
      status="off"
      icon="󰍽"
      cls="off"
      ;;
    adaptive)
      status="on"
      icon="󰍽"
      cls="on"
      ;;
    *)
      status="?"
      icon=""
      cls="unknown"
      ;;
  esac

  tip="Mouse acceleration: ${status}\nProfile: ${profile:-unknown}"

  # with text
  # printf '{"text":"%s %s","tooltip":"%s","class":["mouse-accel","%s"]}\n' "$icon" "$status" "$tip" "$cls"

  # without text
  printf '{"text":"%s","tooltip":"%s","class":["mouse-accel","%s"]}\n' "$icon" "$tip" "$cls"
}

do_toggle() {
  local current
  current="$(get_profile)"

  local next
  if [[ "$current" == "flat" ]]; then
    next="adaptive"
  else
    next="flat"
  fi

  set_profile "$next"

  if [[ "$SHOW_NOTIFY" == "1" ]]; then
    command -v notify-send >/dev/null 2>&1 && \
      notify-send -t 1200 "Mouse acceleration" "Now: ${next}"
  fi

  pkill -SIGRTMIN+"$WAYBAR_SIG" waybar 2>/dev/null || true
}

case "${1:-}" in
  toggle) do_toggle ;;
  *)       make_json "$(get_profile)" ;;
esac

