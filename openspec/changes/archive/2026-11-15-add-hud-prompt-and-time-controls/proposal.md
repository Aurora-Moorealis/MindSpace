# Proposal

## Why

El cambio `add-hotbar-inventory` cerró el HUD de partida con la escena de barras
(`game/scenes/ui/hud.tscn`) y dejó **pospuestos** el prompt de interacción y los
controles de pausa y velocidad. Al montar ese HUD en la escena jugable, el jugador
se quedó sin dos cosas que necesita para jugar:

- **No hay prompt**: el astronauta publica `interaction_target_changed` cuando hay
  una máquina en rango, pero ninguna capa lo dibuja, así que nada indica que se
  interactúa con `E` ni con qué máquina.
- **No hay controles de tiempo**: la pausa y las velocidades existen en el input
  map (`pause`, `speed_up`, `speed_down`) y en `GameSim`, pero solo se ven por
  teclado y el HUD únicamente muestra el multiplicador dentro del reloj.

Además, el HUD numérico anterior (`game/scenes/ui/game_hud/`) sigue en el árbol sin
consumidor desde que `run_ui.tscn` monta el HUD de barras: es código muerto que
duplica la responsabilidad del HUD y confunde sobre cuál es el vigente.

Por último, la estación de hidroponía del outpost se dibuja con la silueta genérica
de `MachineStation` aunque su pack de arte aprobado ya incluye el sprite del rack, y
la acción de retirar de su panel deja de responder en una celda madura porque el
estado rechaza retirar plantas completas.

## What Changes

- El HUD de barras pasa a ser el **único** HUD de partida: se elimina
  `game/scenes/ui/game_hud/` (escena, script y `.uid`).
- El HUD de barras gana:
  - un **prompt de interacción** que aparece cuando el astronauta tiene una máquina
    en rango y desaparece al abrir un panel modal, al terminar la partida o al
    alejarse;
  - **controles de tiempo**: botón de pausa/reanudar y botones de subir/bajar la
    velocidad, además del multiplicador que ya muestra el reloj.
- `run_ui.gd` vuelve a enganchar el astronauta al HUD (`bind_astronaut`) y tipa la
  evaluación con `class_name Evaluation`, sin cambiar su API.
- La estación de hidroponía del outpost se dibuja con el sprite aprobado
  `content/machines/hydroponics/art/sprites/hydroponics_rack.png`, conservando su
  huella y su puerto de cable.
- Retirar una celda de cultivo deja de rechazar las celdas maduras: retirar siempre
  vacía la celda y nunca produce comida.
- Un reinicio de partida vuelve a crear el estado de cultivo con la semilla de la
  partida nueva.
- **Refactor interno sin cambio de comportamiento:** los tres items de muestra se
  mueven de `game/resources/items/*.tres` y `game/assets/images/items/` a
  `game/content/items/<id>/`, y la aserción de filas de `machines_smoke` se
  actualiza a la economía real (54 filas).

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `hud`: se añaden el indicador de interacción y los controles de tiempo del HUD de
  partida.
- `game-hud`: el HUD deja de ser estrictamente de solo lectura; sus tres botones de
  tiempo consumen clics.
- `hydroponics`: retirar deja de limitarse a las celdas inmaduras y la estación se
  dibuja con su sprite aprobado.

## Impact

- `game/scenes/ui/hud.gd`, `game/scenes/ui/hud.tscn` (prompt y controles).
- `game/scenes/ui/run_ui.gd` (enlace del astronauta y tipo de la evaluación).
- `game/scenes/evaluation/evaluation.gd` (`class_name Evaluation`).
- `game/scenes/ui/game_hud/` (se elimina).
- `game/content/machines/hydroponics/hydroponics_station.{gd,tscn}` (sprite y
  semilla), `hydroponics_state.gd` (retirar), `panel/hydroponics_panel.gd` y
  `visual/growth_interface/growth_interface.gd` (QUITAR en celda madura).
- `game/content/items/` (nuevo), `game/resources/items/`, `game/assets/images/items/`.
- `game/scripts/dev/machines_smoke.gd` (aserción de la economía).

## Fuera de alcance

- Banners de evento y línea de comunicaciones en el HUD: siguen pospuestos.
- Reencendido de máquinas apagadas por blackout: es una decisión de balance y toca
  el núcleo de simulación; se tratará en su propio cambio.
- Traducir al inglés los textos preexistentes en español de la demo de cultivo.
- Mover las texturas del HUD a la carpeta de su escena.
