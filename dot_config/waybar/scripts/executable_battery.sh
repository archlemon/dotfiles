#!/usr/bin/env bash

set -euo pipefail

BAT="${BAT:-/sys/class/power_supply/BAT0}"
AC="${AC:-/sys/class/power_supply/AC0}"
ARMOURY="${ARMOURY:-/sys/class/firmware-attributes/asus-armoury/attributes}"
WAYBAR_SIG="${WAYBAR_SIG:-11}"
WARNING="${WARNING:-30}"
CRITICAL="${CRITICAL:-15}"

read_attr() {
  cat "$1" 2>/dev/null || true
}

duration() {
  awk -v e="$1" -v p="$2" 'BEGIN { m = int(e / p * 60); printf "%dh %02dm", m / 60, m % 60 }'
}

make_json() {
  local capacity status online now full design power limit
  capacity="$(read_attr "$BAT/capacity")"
  capacity="${capacity:-0}"
  status="$(read_attr "$BAT/status")"
  online="$(read_attr "$AC/online")"
  now="$(read_attr "$BAT/energy_now")"
  full="$(read_attr "$BAT/energy_full")"
  design="$(read_attr "$BAT/energy_full_design")"
  power="$(read_attr "$BAT/power_now")"
  power="${power:-0}"
  limit="$(read_attr "$BAT/charge_control_end_threshold")"
  limit="${limit:-100}"

  local alt="default"
  local classes="${status,,}"
  classes="${classes// /-}"

  if [[ "$status" == "Charging" ]]; then
    alt="charging"
  elif [[ "$online" == "1" && "$status" != "Full" ]]; then
    alt="plugged"
    classes+=" plugged"
  fi

  if (( capacity <= CRITICAL )); then
    classes+=" critical"
  elif (( capacity <= WARNING )); then
    classes+=" warning"
  fi

  local lines=("Battery: ${capacity}% (${status:-Unknown})")

  if (( power > 0 )); then
    if [[ "$status" == "Discharging" ]]; then
      lines+=("Time left: $(duration "$now" "$power")")
    elif [[ "$status" == "Charging" ]]; then
      local target=$(( full * limit / 100 ))
      if (( target > now )); then
        lines+=("Time to ${limit}%: $(duration $(( target - now )) "$power")")
      fi
    fi
    lines+=("Power: $(awk -v p="$power" 'BEGIN { printf "%.1f W", p / 1e6 }')")
  fi

  lines+=("Charge limit: ${limit}%")

  if [[ -n "$full" && -n "$design" ]]; then
    lines+=("Health: $(awk -v f="$full" -v d="$design" 'BEGIN { printf "%.0f%% (%.1f / %.1f Wh)", f / d * 100, f / 1e6, d / 1e6 }')")
  fi

  local profiles
  profiles="$(asusctl profile get 2>/dev/null || true)"
  if [[ -n "$profiles" ]]; then
    lines+=(
      ""
      "Profile: $(awk -F': ' '/^Active profile/ { print $2 }' <<<"$profiles")"
      "AC profile: $(awk '/^AC profile/ { print $NF }' <<<"$profiles")"
      "Battery profile: $(awk '/^Battery profile/ { print $NF }' <<<"$profiles")"
    )
  fi

  if [[ -r "$ARMOURY/ppt_pl1_spl/current_value" ]]; then
    lines+=("Power limits: $(read_attr "$ARMOURY/ppt_pl1_spl/current_value") / $(read_attr "$ARMOURY/ppt_pl2_sppt/current_value") / $(read_attr "$ARMOURY/ppt_pl3_fppt/current_value") W")
  fi

  local tooltip
  tooltip="$(printf '%s\n' "${lines[@]}")"

  jq -cn \
    --arg text "$capacity" \
    --arg alt "$alt" \
    --arg tooltip "$tooltip" \
    --arg class "$classes" \
    --argjson percentage "$capacity" \
    '{text: $text, alt: $alt, tooltip: $tooltip, class: ($class | split(" ") | map(select(length > 0))), percentage: $percentage}'
}

set_default() {
  local flag="$1" online="$2" profile="$3" active
  active="$(asusctl profile get 2>/dev/null | awk -F': ' '/^Active profile/ { print $2 }')"
  asusctl profile set "$flag" "$profile" >/dev/null
  if [[ -n "$active" && "$(read_attr "$AC/online")" != "$online" ]]; then
    asusctl profile set "$active" >/dev/null
  fi
}

refresh() {
  pkill -SIGRTMIN+"$WAYBAR_SIG" waybar 2>/dev/null || true
}

case "${1:-}" in
  profile)         asusctl profile set "$2" >/dev/null; refresh ;;
  ac-profile)      set_default -a 1 "$2"; refresh ;;
  battery-profile) set_default -b 0 "$2"; refresh ;;
  limit)           asusctl battery limit "$2" >/dev/null; refresh ;;
  oneshot)         asusctl battery oneshot >/dev/null; refresh ;;
  *)               make_json ;;
esac
