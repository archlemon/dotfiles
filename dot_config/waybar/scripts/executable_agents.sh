#!/usr/bin/env bash
set -euo pipefail

grove forest status --json | jq -c '
  [.[] | .name as $g | (.sessions // [])[] | select(.live) | {grove: $g, name, status}] as $s
  | (if any($s[]; .status == "needs_attention") then "attention"
     elif any($s[]; .status == "running") then "working" else "idle" end) as $class
  | {text: "\({attention: "", working: "", idle: ""}[$class]) \($s | length)",
     class: $class,
     tooltip: ($s | map("\(.grove) · \(.name): \(.status)") | join("\n"))}'
