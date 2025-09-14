#!/usr/bin/env bash
set -euo pipefail

CRIT=80

tooltip=""
max_temp=0

for zone in /sys/class/thermal/thermal_zone*; do
  [ -e "$zone/temp" ] || continue
  name=$(cat "$zone/type" 2>/dev/null || echo "zone")
  temp=$(awk '{printf "%d", $1/1000}' "$zone/temp")
  tooltip+=$(printf "%3d°C | %s" "$temp" "$name")
  tooltip+="\n"

  if (( $(echo "$temp > $max_temp" | bc -l) )); then
    max_temp=$temp
  fi
done

for temp_file in /sys/class/hwmon/hwmon*/temp*_input; do
  [ -e "$temp_file" ] || continue

  dir="${temp_file%/*}"
  if [ -r "$dir/name" ]; then
    name=$(cat "$dir/name" 2>/dev/null || echo "hwmon")
  else
    name="hwmon"
  fi

  label_file="${temp_file%_input}_label"
  if [ -r "$label_file" ]; then
    label=$(cat "$label_file" 2>/dev/null || echo "sensor")
  else
    label=$(basename "${temp_file%_*}")
  fi

  temp=$(awk '{printf "%d", $1/1000}' "$temp_file")
  tooltip+=$(printf "%3d°C | %s (%s)" "$temp" "$label" "$name")
  tooltip+="\n"

  if (( temp > max_temp )); then
    max_temp=$temp
  fi
done

tooltip="${tooltip%\\n}"

perc=$(printf "%.0f" "$max_temp")
if (( perc < 0 )); then perc=0; fi
if (( perc > 100 )); then perc=100; fi

cls=""
if (( $(echo "$max_temp >= $CRIT" | bc -l) )); then
  cls="critical"
fi

printf '{"text":"%s°C","tooltip":"%s","percentage":%d,"class":"%s"}\n' \
  "$(printf "%d" $max_temp)" "$tooltip" "$perc" "$cls"
