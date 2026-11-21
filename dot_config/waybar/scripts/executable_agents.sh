#!/usr/bin/env bash
set -euo pipefail

grove forest status --json | jq -c '
  def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
  def pad($n): if $n > 0 then " " * $n else "" end;
  def span($color; $s): "<span color=\"\($color)\">\($s)</span>";
  def rank: {needs_attention: 0, running: 1, idle: 2}[.] // 3;
  def color: {needs_attention: "#f38ba8", running: "#f9e2af", idle: "#6c7086"}[.] // "#a6adc8";
  def age:
    if . < 60 then "now"
    elif . < 3600 then "\(. / 60 | floor)m"
    elif . < 86400 then "\(. / 3600 | floor)h"
    else "\(. / 86400 | floor)d" end;

  now as $now
  | [.[] | .name as $g | (.sessions // [])[] | select(.live)
     | {grove: $g, name, kind, status,
        idle_for: ($now - (.updated_at | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601))}] as $all
  | [$all[] | select(.kind != "terminal")] as $s
  | ($all | length) - ($s | length) as $terms
  | (if any($s[]; .status == "needs_attention") then "attention"
     elif any($s[]; .status == "running") then "working" else "idle" end) as $class
  | ([$s[] | .name | length] | max // 0) as $w
  | {
      text: "\({attention: "", working: "", idle: ""}[$class]) \($s | length)",
      class: $class,
      tooltip: (
        ($s
         | group_by(.grove)
         | map(sort_by((.status | rank), .idle_for))
         | sort_by((.[0].status | rank), (map(.idle_for) | min))
         | map(
             "<b>\(.[0].grove | esc)</b>\n"
             + (map(
                 (.idle_for | age) as $a
                 | (.status == "idle" and .idle_for > 86400) as $stale
                 | "  " + span(.status | color; "●") + " "
                   + ((.name | esc) + pad($w - (.name | length)) + "  " + pad(3 - ($a | length)) + $a
                      | if $stale then span("#6c7086"; .) else . end)
               ) | join("\n"))
           )
         | join("\n")
         | if . == "" then "No live agents" else . end)
        + (if $terms > 0 then "\n\n" + span("#6c7086"; "\($terms) terminal\(if $terms == 1 then "" else "s" end)") else "" end)
      )
    }'
