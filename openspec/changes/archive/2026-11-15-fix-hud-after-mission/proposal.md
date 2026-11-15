# Proposal

## Why

Al terminar la misión, la evaluación se abre **debajo** del HUD: la vida, los
recursos y la hotbar quedan encima del resumen y tapan sus botones de reinicio y
menú. Además la hotbar ocupa un tercio del ancho del lienzo de 850x480, más de lo
que pide su función.

## What Changes

- El HUD se oculta cuando la partida termina y vuelve a mostrarse al empezar una
  partida nueva, de modo que la evaluación quede sola en pantalla.
- La hotbar se reduce al 75 % de su tamaño actual (marco y espacios) y sigue
  centrada abajo, con cinco espacios y separación uniforme.
- Sin cambios en la simulación, el inventario ni el arte: solo el montaje del HUD.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `game-hud`: el HUD deja de mostrarse con la partida terminada; el escenario
  «Partida terminada» pasa de «deja de refrescar» a «se oculta».

## Impact

- `game/scenes/ui/hud.gd`: escucha `game_over` y `game_reset` para ocultar y
  mostrar la capa.
- `game/scenes/ui/hud.tscn`: geometría de la hotbar al 75 %.

## Fuera de alcance

- Controles de velocidad y pausa, prompt de interacción, banners de evento y
  aviso de comunicaciones: siguen pospuestos.
- Rehacer el arte de la hotbar a otra escala o añadir más espacios.
- Cambiar la disposición de vida, recursos o Sol.
