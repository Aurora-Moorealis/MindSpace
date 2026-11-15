# Design

## Contexto

La escena jugable monta un solo HUD (`run_ui.tscn` → `scenes/ui/hud.tscn`). El HUD
de barras nació en el cambio `add-hotbar-inventory`, que **retiró a propósito** el
prompt, los controles de tiempo, los banners y la línea de comunicaciones para
cerrar el alcance. Este cambio recupera solo los dos primeros: son los que el
jugador necesita para jugar y los que el resto del código ya soporta.

## Decisiones

### 1. Un único HUD

El HUD numérico (`game_hud`) se elimina. Motivos:

- `run_ui.tscn` ya no lo instancia desde `add-hotbar-inventory`; solo queda su
  código y sus texturas.
- Duplica la responsabilidad de "leer la simulación y pintarla", con dos estilos y
  dos listas de valores distintas (números vs barras).
- La spec vigente es `openspec/specs/hud/spec.md` (barras); `game-hud` describe el
  contrato de capa, no un segundo diseño.

Lo que se recupera de `game_hud` es **comportamiento**, no estilo: el prompt y los
controles de tiempo se reimplementan sobre el HUD de barras usando sus mismas
texturas y el tema `pixel_theme.tres`.

### 2. Dónde vive el prompt

- Señal de entrada: `Astronaut.interaction_target_changed(target: Node)`, que ya
  existe y se emite al entrar y salir del sensor.
- Además hay que reevaluar la visibilidad cada frame porque el bloqueo de input
  (`Astronaut.set_input_locked`) no tiene señal: con el panel de máquina abierto el
  prompt debe ocultarse aunque el objetivo siga en rango.
- Texto: `E  <nombre>` con `UiText.display_name()` para no inventar nombres.
- Se coloca centrado encima de la hotbar, con un `PanelContainer` y un `Label`
  (`Prompt`, `PromptLabel`), sin capturar ratón.

### 3. Dónde viven los controles de tiempo

- Arriba a la derecha, debajo/debajo-izquierda del reloj, con tres `Button` y un
  `Label` (`SpeedValue`) que muestre `x1`, `x5` o `x10`; el reloj sigue mostrando el
  multiplicador, no se duplica en otro sitio.
- Motivo de botones y no solo teclas: la partida se juega con ratón en la hotbar y
  en los paneles; exigir `Space`/`+`/`-` sin pista visual es una trampa.
- `_process` refresca el estado de los botones (texto `Pause`/`Resume` y
  `disabled`), porque la pausa puede cambiar sin tick (de hecho, pausar impide el
  siguiente tick y el HUD se quedaría congelado).
- Las teclas se mantienen: `pause`, `speed_up`, `speed_down` siguen gestionadas por
  `_unhandled_input`.
- Con la partida terminada los tres botones quedan deshabilitados y el HUD se
  oculta (comportamiento que ya existe).

### 4. Estación de hidroponía con sprite

- El sprite aprobado es `hydroponics_rack.png` (96×64) con ancla declarada
  "bottom-center" en el README del pack. La estación, sin embargo, se compone
  alrededor del origen como el resto de estaciones (huella 112×72 centrada), así que
  el sprite se coloca **centrado** (`centered = true`, `offset = Vector2.ZERO`) para
  no desplazar cables, etiqueta ni colisión.
- `HydroponicsStation._draw()` deja de pintar la silueta genérica y pinta solo el
  puerto del cable (`port_offset`), que es información funcional de la red.
- No se toca `MachineStation`: las otras siete estaciones siguen con su silueta.

### 5. Retirar una celda madura

`HydroponicsState.remove()` rechazaba las celdas en etapa final. Eso dejaba dos
callejones sin salida:

- el botón QUITAR del panel de cultivo se dibujaba sobre una celda madura y no hacía
  nada (y el sprite se ocultaba igualmente, con lo que "reaparecía");
- una celda madura en una máquina averiada no se podía cosechar (exige máquina
  operativa) ni retirar (la rechazaba el estado), así que solo se recuperaba
  reparando.

Decisión: retirar vale para **cualquier** celda plantada. No produce comida, que es
justo la diferencia con cosechar; el jugador siempre puede limpiar una celda. La
cosecha sigue exigiendo máquina operativa.

### 6. Semilla del cultivo en el reinicio

`hydroponics_station.gd` creaba el estado una vez con `GameSim.state.run_seed` y en
`game_reset` solo llamaba `reset()`, que conserva la semilla. Hoy no se nota porque
`SimState.reset_from_economy()` fija la semilla constante, pero la spec de
hidroponía promete determinismo **por semilla de partida**. Se recrea el estado en
cada reinicio.

### 7. Items fuera de `resources/` y `assets/`

Regla del repo: el contenido vive en `content/<tipo>/<nombre>/`; `resources/` es
solo para clases `Resource` y `assets/` para arte compartido. Los tres items de
muestra son contenido de una sola feature, así que pasan a
`content/items/<id>/` con su PNG. La clase `ItemData` se queda en
`resources/items/item_data.gd` (es una clase, no una instancia).

## Alternativas descartadas

- **Mantener `game_hud` y montar los dos**: dos capas pintando los mismos valores,
  más coste de mantenimiento y riesgo de divergencia.
- **Reimplementar el prompt con un `Label` hijo del astronauta**: se movería con el
  mundo y se escalaría con la cámara; el prompt es UI de pantalla.
- **Escalar el sprite del rack a 112×72**: rompe la rejilla de 32 px del arte.
- **Prohibir retirar celdas maduras y ocultar QUITAR**: no resuelve el bloqueo en
  máquina averiada.

## Riesgos

- El HUD de barras tiene un layout fijo; añadir el prompt y los botones puede tapar
  la hotbar o el reloj en 850×480. Mitigación: anclas y capturas a 1280×720 y
  850×480.
- Los botones nuevos consumen clics; hay que actualizar la spec de `game-hud` para
  que "solo la hotbar consume clics" no quede desmentida por el código.
