# Proposal

## Why

El panel que abre hoy la acción «Open panel» de la hidroponía es una rejilla
funcional de 12 celdas (`content/machines/hydroponics/panel/hydroponics_panel`),
mientras el proyecto ya tiene una interfaz de invernadero mucho más trabajada
(`content/machines/hydroponics/visual/growth_interface`): vitrina con las celdas
en perspectiva, panel lateral con contadores y menú de acciones por celda.

Esa interfaz se construyó como demo visual (escena suelta, estado propio y ticks
propios), así que el jugador nunca la ve al jugar. El objetivo es que sea la
interfaz real de cultivo de la máquina en la partida.

## What Changes

- La acción «Open panel» de la hidroponía pasa a abrir la interfaz de invernadero
  a pantalla completa sobre la partida, en lugar de la rejilla.
- `growth_interface` gana un modo «enganchado a la partida»: usa el estado de
  cultivo de la estación, deja de avanzar ticks por su cuenta (los pone `GameSim`)
  y ejecuta plantar, cosechar y retirar a través de la estación, con sus
  comprobaciones de energía y salud.
- La interfaz añade una acción de volver que cierra y devuelve al panel de máquina
  (hoy su botón lleva a la demo).
- Los textos visibles pasan a inglés, como exige la regla de UI del repo.
- Se elimina la rejilla antigua (`panel/hydroponics_panel`), que queda sin uso.
- La demo visual sigue funcionando igual cuando la interfaz no está enganchada.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `hydroponics`: la interfaz de cultivo pasa a ser la del invernadero, se abre
  también con la máquina averiada y solo ofrece las acciones que la estación
  acepta en cada momento.

## Impact

- `game/content/machines/hydroponics/visual/growth_interface/growth_interface.gd`.
- `game/content/machines/hydroponics/panel/` (nueva escena envoltorio; se retira
  la rejilla antigua).
- `game/content/machines/hydroponics/hydroponics_station.tscn` (escena extra).
- `game/content/machines/hydroponics/visual/growth_demo/` (sin cambios de
  comportamiento: sigue abriendo la interfaz en modo demo).

## Fuera de alcance

- Cambiar el arte de la interfaz o el diseño de la vitrina.
- Añadir animaciones, sonido o feedback nuevo.
- Tocar el modelo de crecimiento, la economía o la simulación.
