#!/usr/bin/env bash
set -euo pipefail

CRIT=80

tooltip=""
max_temp=0

for zone in /sys/class/thermal/thermal_zone*; do
  [ -e "$zone/temp" ] || continue
  name=$(cat "$zone/type" 2>/dev/null || echo "zone")
  temp=$(awk '{printf "%d", $1/1000}' "$zone/temp")
  tooltip+="$name: ${temp}°C\n"

  if (( $(echo "$temp > $max_temp" | bc -l) )); then
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
