# tiling-setup

Un mismo flujo de trabajo para **macOS** y **Linux (i3 sobre X11)**: escritorios con
atajos de teclado, mosaico o pestañas, y una barra con **pomodoro** y **cronómetro**
que registran tu tiempo.

El gestor de ventanas no puede ser el mismo en los dos sistemas (AeroSpace solo existe
en macOS), pero la lógica del pomodoro y el cronómetro sí es **un único archivo**:
`shared/timer-core.sh`.

| | macOS | Linux |
|---|---|---|
| Ventanas y escritorios | AeroSpace | i3 |
| Barra | SketchyBar (arriba) | i3bar + i3blocks (abajo) |
| Pomodoro y cronómetro | `shared/timer-core.sh` | `shared/timer-core.sh` |

## Estructura

```
install.sh                      instala según el sistema
shared/timer-core.sh            pomodoro y cronómetro (macOS y Linux)
macos/aerospace.toml            atajos, escritorios y reglas por app
macos/sketchybar/               barra superior (escritorios, pestañas con título, timer)
linux/i3/tiling-setup.conf      atajos del timer para i3
linux/i3/barra.conf             bloque bar { } para la barra de abajo
linux/i3blocks/config           pomodoro, cronómetro, carga, memoria, disco y fecha
```

## Instalación

```
git clone <este repositorio>
cd tiling-setup
./install.sh --paquetes     # --paquetes instala también los programas (brew o apt)
```

Cada archivo que ya existía se guarda como `archivo.bak-FECHA` antes de reemplazarse.

### macOS
1. `./install.sh --paquetes` (instala AeroSpace y SketchyBar con Homebrew).
2. Dale permiso a AeroSpace en *Ajustes del Sistema → Privacidad y seguridad →
   Device Control and Data Access* (el nombre varía según la versión de macOS).
3. `aerospace reload-config` y `sketchybar --reload`.
4. Recomendado: oculta la barra de menú de macOS (Ajustes → Menu Bar → ocultar
   automáticamente → Siempre) y deja una sola pantalla de Mission Control.

El archivo usa rutas de Apple Silicon (`/opt/homebrew/bin`). En un Mac con Intel
cámbialas a `/usr/local/bin` en `macos/aerospace.toml`.

### Linux (Debian / Ubuntu, i3 en X11)
1. `./install.sh --paquetes --tocar-i3`
   - `--paquetes` instala i3blocks, notify-send, zenity y sonidos.
   - `--tocar-i3` edita tu `~/.config/i3/config`: guarda una copia `.bak-FECHA`, comenta
     tus bloques `bar { ... }` actuales (con el prefijo `# (tiling-setup)`), y agrega al
     final el `include` y la barra de abajo. No se aplica dos veces.
2. Recarga con `Mod+Shift+r`.

Para hacerlo a mano en vez de usar `--tocar-i3`:
```
echo 'include ~/.config/i3/tiling-setup.conf' >> ~/.config/i3/config
```
y reemplaza tu bloque `bar { ... }` por el de `linux/i3/barra.conf` (si dejas los dos,
verás dos barras). El `include` necesita i3 4.20 o más nuevo; si tu tecla Mod no es
Super, cambia `Mod4` en `tiling-setup.conf`.

Si i3 avisa de un `Duplicate keybinding`, ese atajo ya lo tenías: borra el viejo o el de
`tiling-setup.conf`.

## Atajos

En macOS `⌘⌥` es Command + Option; en Linux `Mod` es Super.

| Acción | macOS | Linux (i3) |
|---|---|---|
| Ir al escritorio 1 a 4 | `⌘⇧ 1…4` o `⌘⌥ 1…4` | `Mod+1…4` (ya viene en i3) |
| Mandar la ventana al escritorio | `⌘⌥⇧ 1…4` | `Mod+Shift+1…4` (ya viene) |
| Vista de pestañas | `⌘⌥ W` | `Mod+w` (ya viene) |
| Vista de mosaico | `⌘⌥ E` | `Mod+e` (ya viene) |
| Pomodoro: iniciar o pausar | `⌘⌥ P` | `Mod+p` |
| Pomodoro: reiniciar | `⌘⌥⇧ P` | `Mod+Shift+p` |
| Pomodoro: cambiar de tiempos | `⌘⌥ M` | `Mod+m` |
| Pomodoro: tiempos propios | `⌘⌥⇧ M` | `Mod+Shift+m` |
| Pomodoro: +10 min | `⌘⌥⇧ E` | `Mod+x` |
| Cronómetro: iniciar o pausar | `⌘⌥ S` | `Mod+t` |
| Cronómetro: reiniciar | `⌘⌥⇧ S` | `Mod+Shift+t` |

En Linux no se reutilizan algunas letras del Mac porque i3 ya las usa
(`Mod+s` es la vista apilada y `Mod+Shift+e` sale de i3).

En la barra también se puede hacer clic: izquierdo inicia o pausa, derecho reinicia y,
en el pomodoro, el central (Linux) o `⇧`+clic (macOS) cambia de tiempos.

## Pomodoro y cronómetro

- Por defecto 50 minutos de trabajo y 15 de descanso. Tiempos predefinidos:
  `50/15`, `50/20`, `90/20` y `25/5`. También puedes escribir los tuyos.
- Al terminar un bloque suena y sale una notificación. El descanso no arranca solo ni
  empieza otro bloque automáticamente.
- `+10 min` extiende el bloque actual cuando estás en foco.
- Los bloques terminados y los cronómetros reiniciados se anotan en `~/timer_log.csv`,
  y la barra muestra cuántos bloques llevas hoy (`✓3`).
- Funciona desde la terminal: `timer-core.sh pomo set 60 10`, `timer-core.sh sw toggle`.
- Íconos distintos: `TIMER_ICON_POMO`, `TIMER_ICON_BREAK` y `TIMER_ICON_SW`.

## Estado de las pruebas

La lógica del timer se probó en Linux con clics y avisos simulados. La instalación se
probó en directorios de prueba para los dos sistemas. La configuración de AeroSpace,
SketchyBar e i3 todavía hay que verificarla en una máquina real; si algo falla, abre
un issue con la salida del error.

## Licencia

MIT. Cambia `<TU NOMBRE>` en `LICENSE` antes de publicar.
