#!/bin/bash
# Envoltorio: usa el núcleo compartido con la salida para SketchyBar.
DIR="$(cd "$(dirname "$0")" && pwd)"
TIMER_UI=sketchybar exec "$DIR/timer-core.sh" "$@"
