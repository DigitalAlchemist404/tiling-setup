#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
N="${NAME#ws.}"
if [ "$N" = "$FOCUSED" ]; then
  sketchybar --set "$NAME" background.drawing=on background.color=0xff3b4261 label.color=0xff7dcfff
else
  sketchybar --set "$NAME" background.drawing=off label.color=0xff7a84a8
fi
