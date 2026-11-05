#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
INFO=$(pmset -g batt)
PCT=$(printf '%s' "$INFO" | grep -Eo '[0-9]+%' | head -1)
[ -z "$PCT" ] && { sketchybar --set "$NAME" drawing=off; exit 0; }
if printf '%s' "$INFO" | grep -q 'AC Power'; then SUF=" ⚡"; else SUF=""; fi
sketchybar --set "$NAME" drawing=on label="🔋 ${PCT}${SUF}"
