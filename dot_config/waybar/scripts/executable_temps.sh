#!/usr/bin/env bash
set -euo pipefail

CRIT=80
tooltip=""
max_temp=0

read_sys() {
  cat "$1" 2>/dev/null
}

for zone in /sys/class/thermal/thermal_zone*; do
  [[ -e "$zone/temp" ]] || continue

  name=$(read_sys "$zone/type") || name="unknown"
  raw_temp=$(read_sys "$zone/temp") || continue
  temp=$(( raw_temp / 1000 ))

  tooltip+="$(printf "%3d°C | %s\n" "$temp" "$name")"$'\n'

  if (( temp > max_temp )); then
    max_temp=$temp
  fi
done

for temp_file in /sys/class/hwmon/hwmon*/temp*_input; do
  [[ -e "$temp_file" ]] || continue

  dir="${temp_file%/*}"
  name=$(read_sys "$dir/name") || name="unknown"

  label_file="${temp_file%_input}_label"
  if [[ -r "$label_file" ]]; then
    label=$(read_sys "$label_file") || label=$(basename "${temp_file%_*}")
  else
    label=$(basename "${temp_file%_*}")
  fi

  raw_temp=$(read_sys "$temp_file") || continue
  temp=$(( raw_temp / 1000 ))

  tooltip+="$(printf "%3d°C | %s (%s)\n" "$temp" "$label" "$name")"$'\n'

  if (( temp > max_temp )); then
    max_temp=$temp
  fi
done

perc=$max_temp
(( perc < 0 )) && perc=0
(( perc > 100 )) && perc=100

cls=""
(( max_temp >= CRIT )) && cls="critical"

printf "%s" "$tooltip" | jq -c -Rs \
  --arg text "${max_temp}°C" \
  --argjson percentage "$perc" \
  --arg class "$cls" \
  '{text: $text, tooltip: (sub("\n$"; "")), percentage: $percentage, class: $class}'
