#!/bin/bash
# timer-core.sh: pomodoro + cronómetro, igual en macOS y Linux.
#
# Uso:
#   timer-core.sh pomo <toggle|reset|cycle|custom|extend|set TRABAJO DESCANSO|click>
#   timer-core.sh sw   <toggle|reset|click>
#   timer-core.sh tick                 (avisa cuando termina un bloque)
#   timer-core.sh show <pomo|sw>       (salida para i3blocks, 3 líneas)
#
# Interfaces:
#   TIMER_UI=sketchybar  -> actualiza la barra de SketchyBar (macOS)
#   timer-core.sh show   -> i3blocks (Linux); clic izq. inicia/pausa,
#                           derecho reinicia, central cambia de tiempos.
#
# Estado en ~/.cache/sbtimer, registro de bloques en ~/timer_log.csv.
# Variables opcionales: TIMER_ICON_POMO, TIMER_ICON_BREAK, TIMER_ICON_SW.

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
case "$(uname -s)" in Darwin) OS=mac ;; *) OS=linux ;; esac

S="${XDG_CACHE_HOME:-$HOME/.cache}/sbtimer"; mkdir -p "$S"
LOG="$HOME/timer_log.csv"
now=$(date +%s)

ICON_POMO=${TIMER_ICON_POMO:-🍅}
ICON_BREAK=${TIMER_ICON_BREAK:-☕}
ICON_SW=${TIMER_ICON_SW:-⏱}

rd(){ cat "$S/$1" 2>/dev/null || echo "$2"; }
wr(){ printf '%s' "$2" > "$S/$1"; }

# Tiempos (en minutos). Por defecto 50 de trabajo y 15 de descanso.
WORK_MIN=$(rd cfg_work 50)
BREAK_MIN=$(rd cfg_break 15)
WORK=${POMO_WORK_SEC:-$((WORK_MIN*60))}
BREAK=${POMO_BREAK_SEC:-$((BREAK_MIN*60))}
PRESETS=("50 15" "50 20" "90 20" "25 5")   # "trabajo descanso"
EXTEND=600                                  # "+10 min" cuando estás en foco

# ---------------------------------------------------- diferencias por sistema
fdate(){
  if [ "$OS" = mac ]; then date -r "$1" '+%Y-%m-%d %H:%M'
  else date -d "@$1" '+%Y-%m-%d %H:%M'; fi
}
notify(){
  if [ "$OS" = mac ]; then
    command -v osascript >/dev/null && osascript -e "display notification \"$2\" with title \"$1\"" >/dev/null 2>&1
    command -v afplay >/dev/null && { afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1 & }
  else
    command -v notify-send >/dev/null && notify-send "$1" "$2" >/dev/null 2>&1
    if command -v canberra-gtk-play >/dev/null; then { canberra-gtk-play -i complete >/dev/null 2>&1 & }
    elif command -v paplay >/dev/null; then { paplay /usr/share/sounds/freedesktop/stereo/complete.oga >/dev/null 2>&1 & }
    fi
  fi
  return 0
}
ask_minutes(){   # pide "trabajo descanso"; imprime la respuesta
  local def="$WORK_MIN $BREAK_MIN"
  if [ "$OS" = mac ]; then
    osascript -e "text returned of (display dialog \"Minutos de trabajo y de descanso (por ejemplo: 50 15)\" default answer \"$def\" with title \"Pomodoro\")" 2>/dev/null
  elif command -v zenity >/dev/null; then
    zenity --entry --title="Pomodoro" --text="Minutos de trabajo y de descanso (por ejemplo: 50 15)" --entry-text="$def" 2>/dev/null
  elif command -v rofi >/dev/null; then
    echo "$def" | rofi -dmenu -p "trabajo descanso" 2>/dev/null
  else
    return 1
  fi
}

fmt(){ local s=$1; [ "$s" -lt 0 ] && s=0
  if [ "$s" -ge 3600 ]; then printf '%d:%02d:%02d' $((s/3600)) $(((s%3600)/60)) $((s%60))
  else printf '%02d:%02d' $((s/60)) $((s%60)); fi; }
log(){ [ -f "$LOG" ] || echo "tipo,inicio,duracion,segundos" > "$LOG"
       printf '%s,%s,%s,%s\n' "$1" "$(fdate "$2")" "$(fmt "$3")" "$3" >> "$LOG"; }

# ------------------------------------------------------------ cronómetro
sw_elapsed(){ local acc; acc=$(rd sw_acc 0)
  if [ "$(rd sw_state stopped)" = running ]; then echo $((acc + now - $(rd sw_start "$now"))); else echo "$acc"; fi; }
sw_toggle(){
  case "$(rd sw_state stopped)" in
    running) wr sw_acc "$(sw_elapsed)"; wr sw_state paused ;;
    paused)  wr sw_start "$now"; wr sw_state running ;;
    *)       wr sw_acc 0; wr sw_began "$now"; wr sw_start "$now"; wr sw_state running ;;
  esac; }
sw_reset(){ local t; t=$(sw_elapsed)
  [ "$t" -gt 0 ] && log cronometro "$(rd sw_began "$now")" "$t"
  wr sw_state stopped; wr sw_acc 0; }

# -------------------------------------------------------------- pomodoro
pm_dur(){ if [ "$(rd pm_mode work)" = work ]; then echo "$WORK"; else echo "$BREAK"; fi; }
pm_left(){ if [ "$(rd pm_state idle)" = running ]; then echo $(($(rd pm_end "$now") - now)); else rd pm_left "$(pm_dur)"; fi; }
pm_toggle(){
  case "$(rd pm_state idle)" in
    running) wr pm_left "$(pm_left)"; wr pm_state paused ;;
    *)       local l; l=$(rd pm_left "$(pm_dur)"); wr pm_end $((now + l))
             if [ "$(rd pm_mode work)" = work ] && [ "$(rd pm_state idle)" = idle ]; then
               wr pm_began "$now"; wr pm_total "$l"; fi
             wr pm_state running ;;
  esac; }
pm_reset(){ wr pm_mode work; wr pm_state idle; wr pm_left "$WORK"; }
pm_set(){ wr cfg_work "$1"; wr cfg_break "$2"
          WORK_MIN=$1; BREAK_MIN=$2; WORK=$(($1*60)); BREAK=$(($2*60)); pm_reset; }
pm_cycle(){ local cur="$WORK_MIN $BREAK_MIN" i idx=-1
  for i in "${!PRESETS[@]}"; do [ "${PRESETS[$i]}" = "$cur" ] && idx=$i; done
  idx=$(( (idx+1) % ${#PRESETS[@]} ))
  set -- ${PRESETS[$idx]}; pm_set "$1" "$2"; }
pm_custom(){ local ans
  ans=$(ask_minutes) || return 0
  set -- $(printf '%s' "$ans" | tr -c '0-9\n' ' ')
  if [ -n "$1" ] && [ -n "$2" ] && [ "$1" -ge 1 ] && [ "$1" -le 600 ] && [ "$2" -ge 1 ] && [ "$2" -le 600 ]; then
    pm_set "$1" "$2"; fi; }
pm_extend(){   # +10 min al bloque actual (útil cuando estás en foco)
  case "$(rd pm_state idle)" in
    running) wr pm_end $(($(rd pm_end "$now") + EXTEND)) ;;
    *)       wr pm_left $(($(pm_left) + EXTEND)) ;;
  esac
  [ "$(rd pm_mode work)" = work ] && wr pm_total $(($(rd pm_total "$WORK") + EXTEND)); return 0; }
pm_tick(){
  [ "$(rd pm_state idle)" = running ] || return 0
  [ "$(pm_left)" -le 0 ] || return 0
  if [ "$(rd pm_mode work)" = work ]; then
    log pomodoro "$(rd pm_began "$now")" "$(rd pm_total "$WORK")"
    notify "Bloque terminado" "Descansa de verdad: aléjate de la pantalla $((BREAK/60)) min."
    wr pm_mode break; wr pm_left "$BREAK"
  else
    notify "Descanso terminado" "Cuando estés listo, inicia el siguiente bloque."
    wr pm_mode work; wr pm_left "$WORK"
  fi
  wr pm_state idle; }

# ----------------------------------------------------------- presentación
# Colores en RRGGBB (verde, amarillo, gris, rojo)
compute(){
  local e st l pst icon extra="" cnt="" n=0
  [ -f "$LOG" ] && n=$(grep -c "^pomodoro,$(date +%Y-%m-%d)" "$LOG")
  [ "$n" -gt 0 ] && cnt="  ✓$n"
  e=$(sw_elapsed); st=$(rd sw_state stopped)
  case "$st" in running) SW_COLOR=9ece6a ;; paused) SW_COLOR=e0af68 ;; *) SW_COLOR=7a84a8 ;; esac
  SW_LABEL="$ICON_SW $(fmt "$e")"
  l=$(pm_left); pst=$(rd pm_state idle)
  if [ "$(rd pm_mode work)" = work ]; then icon=$ICON_POMO; else icon=$ICON_BREAK; fi
  case "$pst" in
    running) if [ "$(rd pm_mode work)" = work ]; then PM_COLOR=f7768e; else PM_COLOR=9ece6a; fi ;;
    paused)  PM_COLOR=e0af68 ;;
    *)       PM_COLOR=7a84a8; [ "$(rd pm_mode work)" = work ] && extra="  ${WORK_MIN}/${BREAK_MIN}" ;;
  esac
  PM_LABEL="$icon $(fmt "$l")$extra$cnt"
}
render_sketchybar(){
  command -v sketchybar >/dev/null || return 0
  compute
  sketchybar --set sw label="$SW_LABEL" label.color=0xff$SW_COLOR \
             --set pomo label="$PM_LABEL" label.color=0xff$PM_COLOR
}

# ------------------------------------------------------------- despacho
case "$1" in
  tick) pm_tick ;;
  show)   # i3blocks: línea 1 texto, 2 texto corto, 3 color
    what="$2"
    if [ -n "$BLOCK_BUTTON" ]; then
      case "$what:$BLOCK_BUTTON" in
        pomo:1) pm_toggle ;; pomo:3) pm_reset ;; pomo:2) pm_cycle ;;
        sw:1)   sw_toggle ;; sw:3)   sw_reset ;;
      esac
    fi
    pm_tick; compute
    if [ "$what" = sw ]; then label=$SW_LABEL color=$SW_COLOR; else label=$PM_LABEL color=$PM_COLOR; fi
    printf '%s\n%s\n#%s\n' "$label" "$label" "$color"
    exit 0 ;;
  sw)
    act="$2"
    [ "$act" = click ] && { [ "$BUTTON" = right ] && act=reset || act=toggle; }
    [ "$act" = reset ] && sw_reset || sw_toggle ;;
  pomo)
    act="$2"
    if [ "$act" = click ]; then
      if [ "$MODIFIER" = shift ]; then act=cycle
      elif [ "$BUTTON" = right ]; then act=reset
      else act=toggle; fi
    fi
    case "$act" in
      reset)  pm_reset ;;
      cycle)  pm_cycle ;;
      custom) pm_custom ;;
      extend) pm_extend ;;
      set)    pm_set "$3" "$4" ;;
      *)      pm_toggle ;;
    esac ;;
esac
[ "${TIMER_UI:-}" = sketchybar ] && render_sketchybar
exit 0
