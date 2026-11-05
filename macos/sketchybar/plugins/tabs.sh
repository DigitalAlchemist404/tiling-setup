#!/bin/bash
# Una "pestaña" por ventana, ordenadas por escritorio (1, 2, 3...).
#   SHOW_ALL=1  -> todas las ventanas de todos los escritorios (por defecto)
#   SHOW_ALL=0  -> solo las del escritorio actual
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
SHOW_ALL=${SHOW_ALL:-1}
MAX=10
TITLE_LEN=18

FOCUSED_WIN=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null | tr -d '[:space:]')
CUR_WS=$(aerospace list-workspaces --focused 2>/dev/null | tr -d '[:space:]')

args=()
for n in 1 2 3 4; do
  if [ "$n" = "$CUR_WS" ]; then
    args+=(--set ws.$n background.drawing=on background.color=0xff3b4261 label.color=0xff7dcfff)
  else
    args+=(--set ws.$n background.drawing=off label.color=0xff7a84a8)
  fi
done

if [ "$SHOW_ALL" = 1 ]; then SCOPE="--all"; else SCOPE="--workspace focused"; fi

i=1
while IFS='|' read -r ws id app title; do
  [ -z "$id" ] && continue
  [ "$i" -gt "$MAX" ] && break
  short=$(printf '%s' "$title" | cut -c1-$TITLE_LEN)
  if [ -n "$short" ] && [ "$short" != "$app" ]; then label="$ws $app · $short"; else label="$ws $app"; fi
  printf '%s' "$id" > "/tmp/sbtab.$i"
  if [ "$id" = "$FOCUSED_WIN" ]; then
    args+=(--set tab.$i drawing=on label="$label" label.color=0xffffffff \
           background.drawing=on background.color=0xff3b4261)
  elif [ "$ws" = "$CUR_WS" ]; then
    args+=(--set tab.$i drawing=on label="$label" label.color=0xffa9b1d6 background.drawing=off)
  else
    args+=(--set tab.$i drawing=on label="$label" label.color=0xff565f89 background.drawing=off)
  fi
  i=$((i+1))
done < <(aerospace list-windows $SCOPE --format '%{workspace}|%{window-id}|%{app-name}|%{window-title}' 2>/dev/null \
         | sort -t'|' -k1,1n -k2,2n)

while [ "$i" -le "$MAX" ]; do
  args+=(--set tab.$i drawing=off)
  i=$((i+1))
done

sketchybar "${args[@]}"
