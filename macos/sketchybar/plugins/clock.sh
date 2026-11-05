#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
sketchybar --set "$NAME" label="$(date '+%a %d %b  %H:%M')"
