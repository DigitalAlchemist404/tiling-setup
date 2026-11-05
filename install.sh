#!/bin/bash
# Instala la configuración según el sistema (macOS o Linux).
# Uso: ./install.sh [--paquetes] [--tocar-i3]
#   --paquetes  instala también los programas necesarios (brew o apt)
#   --tocar-i3  (Linux) agrega el include y la barra de abajo a tu config de i3
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
OS="${INSTALL_OS:-$(uname -s)}"
STAMP=$(date +%Y%m%d-%H%M%S)
PAQUETES=0
TOCAR_I3=0
for arg in "$@"; do
  case "$arg" in
    --paquetes)  PAQUETES=1 ;;
    --tocar-i3)  TOCAR_I3=1 ;;
  esac
done

# Copia un archivo; si el destino existe y es distinto, guarda una copia .bak-FECHA
place(){
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && ! cmp -s "$src" "$dst"; then
    cp "$dst" "$dst.bak-$STAMP"
    echo "  copia de seguridad: $dst.bak-$STAMP"
  fi
  cp "$src" "$dst"
}

case "$OS" in
Darwin|mac)
  echo "== macOS: AeroSpace + SketchyBar =="
  if [ "$PAQUETES" = 1 ]; then
    brew install --cask nikitabobko/tap/aerospace
    brew tap FelixKratz/formulae
    brew install sketchybar
  fi
  SB="$HOME/.config/sketchybar"
  place "$ROOT/macos/aerospace.toml" "$HOME/.aerospace.toml"
  place "$ROOT/macos/sketchybar/sketchybarrc" "$SB/sketchybarrc"
  for f in "$ROOT"/macos/sketchybar/plugins/*.sh; do place "$f" "$SB/plugins/$(basename "$f")"; done
  place "$ROOT/shared/timer-core.sh" "$SB/plugins/timer-core.sh"
  chmod +x "$SB/sketchybarrc" "$SB"/plugins/*.sh
  echo "Listo. Ahora:"
  echo "  1) aerospace reload-config"
  echo "  2) sketchybar --reload   (o: brew services restart sketchybar)"
  ;;
Linux)
  echo "== Linux: i3 + i3blocks =="
  if [ "$PAQUETES" = 1 ]; then
    sudo apt install -y i3blocks libnotify-bin zenity pulseaudio-utils sound-theme-freedesktop
  fi
  D="$HOME/.local/share/tiling-setup"
  place "$ROOT/shared/timer-core.sh" "$D/timer-core.sh"
  chmod +x "$D/timer-core.sh"
  place "$ROOT/linux/i3blocks/config" "$HOME/.config/i3blocks/config"
  place "$ROOT/linux/i3/tiling-setup.conf" "$HOME/.config/i3/tiling-setup.conf"
  for dep in i3blocks notify-send zenity; do
    command -v "$dep" >/dev/null || echo "  falta '$dep' (instálalo con: ./install.sh --paquetes)"
  done
  if [ "$TOCAR_I3" = 1 ]; then
    CFG="$HOME/.config/i3/config"; [ -f "$CFG" ] || CFG="$HOME/.i3/config"
    if [ ! -f "$CFG" ]; then
      echo "  no encuentro tu config de i3 (~/.config/i3/config)"; exit 1
    elif grep -q 'tiling-setup.conf' "$CFG"; then
      echo "  tu config de i3 ya tiene el include; no se toca"
    else
      cp "$CFG" "$CFG.bak-$STAMP"; echo "  copia de seguridad: $CFG.bak-$STAMP"
      # comenta tus bloques bar { ... } actuales (cuenta las llaves)
      awk '
        /^[[:space:]]*bar[[:space:]]*\{/ && !inbar { inbar=1; depth=0 }
        { if (inbar) { l=$0; o=gsub(/\{/,"{",l); c=gsub(/\}/,"}",l); depth+=o-c
                       print "# (tiling-setup) " $0; if (depth<=0) inbar=0 }
          else print }' "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"
      { printf '\n# --- tiling-setup ---\ninclude ~/.config/i3/tiling-setup.conf\n\n'
        cat "$ROOT/linux/i3/barra.conf"; } >> "$CFG"
      echo "  agregado el include y la barra de abajo a $CFG"
    fi
    echo "Listo. Recarga con Mod+Shift+r (o: i3-msg restart)."
  else
    echo "Listo. Para que i3 use todo esto, corre de nuevo con --tocar-i3, o a mano:"
    echo "  1) agrega la línea:  include ~/.config/i3/tiling-setup.conf"
    echo "  2) reemplaza tu bloque bar { ... } por el de: $ROOT/linux/i3/barra.conf"
    echo "Luego recarga con Mod+Shift+r (o: i3-msg restart)."
  fi
  ;;
*)
  echo "Sistema no soportado: $OS"; exit 1 ;;
esac
