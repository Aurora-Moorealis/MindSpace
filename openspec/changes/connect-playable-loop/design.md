# Design

## Context

`features` ya tiene el núcleo por ticks, las fichas de las ocho máquinas, la red
eléctrica, el astronauta con traje y zonas, y el scheduler de eventos. Lo que
falta es la capa que los pone en el mundo y los hace legibles para el jugador:
ver `proposal.md` → Why.

Restricciones que condicionan el diseño:

- No hay base de salas ni airlock jugable: las estaciones se colocan al aire
  sobre y alrededor de la plataforma de aterrizaje.
- No hay arte de estación: se entrega con textura de reemplazo.
- El mapa se genera con semilla fija; una posición puede caer sobre roca o
  cráter, así que la colocación se valida con una escena de humo.
- GDScript con tipos explícitos, sin `:=`, y avisos estrictos activos.
- No se añaden autoloads nuevos: `GameSim`, `EventLog` y `MachineDatabase`
  bastan.

## Goals / Non-Goals

**Goals**

- Un outpost jugable que se pueda recorrer, con las ocho máquinas, su red
  eléctrica y un refugio que corta la radiación.
- Una interfaz mínima que haga visible el estado y accionable la reparación y
  las mejoras.
- Hidroponía atada al tick y determinista, sin reloj de pared ni `randf()`.
- Cierre del loop: fin de partida, resultado y reinicio, con un atajo de
  depuración para probarlo.

**Non-Goals**

- Cambiar el contrato del tick de `simulation-core`: el crecimiento de la
  hidroponía y las acciones del jugador se aplican fuera del tick, igual que
  reparaciones y mejoras.
- Añadir datos de misión, informes, POIs o submisiones.
- Arte definitivo, animaciones o sonido.
- Sustituir `airlock_zone` por la base de `base-and-craters`.

## Decisions

### D1. Un solo outpost como escena, estaciones colocadas a mano

`game/content/outpost/outpost.tscn` contiene las ocho estaciones, la batería, el
panel solar, los cables y el área de refugio. `game/content/outpost/outpost.gd`
solo resuelve el orden de arranque: espera un frame, deja que
`PowerGridController` reconstruya la red, avisa de estaciones duplicadas o con id
desconocido y expone el área de refugio.

Se descarta una capa de datos (`outpost_layout.tres` con filas de posición):
`PowerCable` ya está pensado para cablearse por `NodePath` desde el editor y,
cuando llegue `base-and-craters`, mover estaciones es editar la escena, no
mantener un recurso paralelo. Un layout data-driven sería útil con colocación
libre por el jugador, que está fuera de alcance.

Topología inicial: estrella sobre la batería. Un cable
`solar_array → battery_1` y un cable `battery_1 → cada una de las otras siete
máquinas`, ocho cables en total. Es la topología más simple que deja a todas las
consumidoras en la misma red y permite romper una sola rama para ver el efecto.

### D2. Una estación genérica y dos escenas existentes

Seis máquinas no tienen escena (`lights`, `water_recycler`, `o2_system`,
`comms_console`, `repair_bench`, `storm_shelter`). En vez de seis escenas
idénticas, se crea `game/content/machines/machine_station.tscn` con
`game/content/machines/machine_station.gd` (`extends MachineBase`), un
`machine_id` exportado y el área de interacción que ya hereda de la base.

El panel solar y la batería conservan sus escenas y su arte. La hidroponía tiene
su propia escena porque añade el estado de cultivo (D8).

**Textura de reemplazo.** Cada estación lleva un `Sprite2D` con
`PlaceholderTexture2D` para reservar el hueco del arte, pero
`PlaceholderTexture2D` no dibuja nada en ejecución. Por eso la estación se pinta
además con `_draw()`: un cuerpo rectangular con el color de acento de su tipo,
un contorno oscuro y el nombre en inglés debajo. Los colores salen de la paleta
de `art-style`; no se commitea ningún PNG nuevo y no hace falta auditoría de
arte.

### D3. El refugio vive en el astronauta, no en `base.gd`

`game/content/entities/astronaut/astronaut.gd` pasa a tener dos diccionarios de
áreas, `_exterior_areas` y `_shelter_areas`, y una única función
`_apply_zone_state()` que calcula:

```
inside = not _shelter_areas.is_empty()
outside = starts_outside or not _exterior_areas.is_empty()
GameSim.set_outside(outside and not inside)
```

`starts_outside` pasa a valer `true` por defecto: la superficie es exterior
aunque no haya ninguna zona. Así se elimina el `GameSim.state.is_outside = true`
hardcodeado de `game/scenes/base/base.gd`, que era la única razón por la que hoy
no existe un interior.

El área de refugio es un `Area2D` en la capa 8 (la que ya enmascara el
`ZoneSensor`), en el grupo `shelter_zones`, del tamaño del recinto del outpost.
Se descarta reutilizar `exterior_zones` para el interior: un área de exterior
que se desactiva al entrar en otra obliga a llevar cuenta de orden de entrada y
salida, y el refugio como grupo propio se resuelve con una comprobación de
prioridad.

### D4. Panel de máquina construido desde datos, con motivos explícitos

`game/scenes/ui/machine_panel/machine_panel.tscn` y `.gd` reciben el id de la
máquina y se construyen con `GameSim.get_machine_data()` y
`GameSim.get_machine_state()`. El estado se refresca al conectar
`GameSim.tick_advanced`. Las acciones llaman a `GameSim.start_repair()` y
`GameSim.apply_upgrade()`; la habilitación usa `can_start_repair()` y
`can_apply_upgrade()`, de modo que el panel no duplica reglas.

Los motivos de una acción deshabilitada se calculan en un helper estático
`game/scripts/ui/machine_text.gd` a partir del mismo estado, en este orden:
partida terminada, datos ausentes, reparación en curso, salud completa, energía
insuficiente, mejora ya aplicada. El nombre visible se obtiene humanizando
`display_name_key` (`water_recycler` → `Water recycler`) porque el proyecto
todavía no tiene catálogo de traducciones; cuando lo tenga, el helper es el
único sitio que cambia.

Se descarta un modelo de vista propio con señales por acción: el panel es el
único consumidor y ya se refresca por tick.

### D5. Una capa de interfaz por partida, sin autoload

`game/scenes/ui/run_ui.tscn` es un `CanvasLayer` que instancia el HUD, el panel
de máquina y la evaluación. Lo instancia `base.tscn`, así que desaparece al
salir de la partida y no queda ningún atajo activo en el menú.

Se descarta un autoload de UI: la interfaz es de la partida, no del juego, y un
singleton obligaría a limpiar estado al cambiar de escena.

### D6. El HUD lee el estado; el astronauta solo aporta el prompt

`game/scenes/ui/game_hud/game_hud.gd` se refresca con `GameSim.tick_advanced`,
`GameSim.game_reset` y `GameSim.game_over`. Lee recursos, salud, radiación,
hambre, sed, tick y eventos activos de `GameSim.state`. El prompt de interacción
viene de `Astronaut.interaction_target_changed`, que ya existe.

El reloj se calcula con `state.get_sol_length(economy)` para el número de sol y
`state.get_phase(economy)` para día o noche; no se inventa un reloj paralelo. Los
recursos que falten en el estado se muestran como no disponibles (`--`), nunca
como un cero que parezca un dato real. La velocidad y la pausa llaman a
`GameSim.set_speed()` y `GameSim.set_paused()`; **no** se usa
`get_tree().paused`, porque congelaría también la interfaz y el panel dejaría de
refrescarse.

Los botones del HUD usan `focus_mode = NONE` para que `Space` (pausa) no active
además el último botón enfocado.

### D7. Hidroponía: estado por partida, intervalos deterministas

`game/content/machines/hydroponics/hydroponics_state.gd` deja de ser estático y
pasa a ser una clase instanciable (`extends RefCounted`) con doce celdas. Cada
celda guarda `planted`, `accumulated_ticks`, `interval_ticks` y etapa.

- El intervalo se sortea al plantar con un hash estable de
  `(state.run_seed, cell_index, planted_tick)` mapeado a 3–6 ticks. No se usa
  `RandomNumberGenerator` global ni `randf()`, así que dos partidas con la misma
  semilla y las mismas acciones coinciden.
- `game/content/machines/hydroponics/hydroponics_station.tscn` y `.gd`
  (`extends MachineBase`) escuchan `GameSim.tick_advanced` y, solo si la máquina
  está sana y encendida, suman un tick a cada celda plantada. Si la etapa
  resultante sube, se notifica al panel.
- `game/content/machines/hydroponics/panel/hydroponics_panel.tscn` y `.gd` es un
  `Control` que dibuja la rejilla 3×4 con las texturas de etapa existentes y
  ofrece plantar, cosechar y retirar. Se abre desde el panel de máquina con una
  acción extra que la estación declara (`extra_panel_scene`), sin comprobar ids
  a mano.
- La cosecha llama a una función de `GameSim` que añade
  `hydroponics_harvest_food` a la comida y la acota por capacidad; es una acción
  del jugador, fuera del tick, igual que una reparación. Se añade la fila
  `game/databases/economy_rows/hydroponics_harvest_food.tres` y su entrada en
  `game/databases/economy.tres`.
- `visual/growth_demo` y `visual/growth_interface` se adaptan para usar una
  instancia propia del estado y avanzar ticks desde su temporizador; dejan de
  depender de `Time.get_ticks_msec()`.

Se descarta mover el crecimiento al interior de `SimTick`: el tick es
determinista y puro, y hacerlo mutar células de contenido obligaría a versionar
el guardado de una máquina concreta. Mantenerlo en un nodo suscrito al tick deja
el núcleo intacto y sigue siendo determinista.

### D8. Evaluación como superposición y reinicio por recarga de escena

`game/scenes/evaluation/evaluation.tscn` y `.gd` es un `Control` dentro del
mismo `CanvasLayer`, oculto hasta que `GameSim.game_over` se emite. Se muestra
sobre la escena congelada, que es lo que pide la spec; cambiar de escena
descargaría el mundo y perdería el fondo.

- Contadores: `EventLog.get_summary()` (`reports_sent`, `submissions_completed`,
  `peak_radiation`, `shelter_uses`, `sols_elapsed`). Aunque informes y
  submisiones no se puedan producir en este cambio, se muestran en cero porque
  el ledger ya los agrega.
- Recursos finales: `state.resources` del estado congelado.
- Causa: `state.death_cause` traducida por `machine_text.gd`.
- Volver a jugar: `GameSim.new_game()` y `get_tree().reload_current_scene()`.
- Volver al menú: `get_tree().change_scene_to_file("res://scenes/welcome/welcome.tscn")`.

### D9. Fin de misión forzado en `GameSim`

`game/scripts/autoloads/game_sim.gd` añade `force_end_run()`. Si
`state.game_over` ya está activo devuelve `false` sin escribir nada; si no,
marca la partida, fija `death_cause = &"debug"`, registra un único hecho
`GAME_OVER` con el mismo payload que el tick, pausa el reloj y emite
`game_over`. El botón vive en el HUD y solo se instancia cuando
`OS.is_debug_build()` es cierto; el atajo es la acción `debug_end_run`.

Se descarta matar al astronauta con daño artificial: ensuciaría los contadores
de radiación y de salud del resultado, que es justo lo que se quiere revisar.

### D10. Entrada

`game/project.godot` añade tres acciones: `speed_up` (`=`), `speed_down` (`-`) y
`pause` (`Space`), más `debug_end_run` (`F10`). El cierre de paneles usa el
`ui_cancel` existente. El astronauta gana `set_input_locked(bool)` para que el
panel capture el movimiento sin desactivar su física ni su sensor.

## Risks / Trade-offs

- **Posiciones sobre terreno no transitable o fuera de alcance** → escena de humo
  que comprueba que cada estación está en una celda transitable y alcanzable
  desde el spawn, y que en su `port_position()` es el objetivo más cercano. Si
  falla, se mueve la estación en `outpost.tscn`; el diseño no cambia.
- **Áreas de interacción solapadas** → el astronauta ya elige el objetivo más
  cercano; el humo comprueba que cada estación gana en su propio puerto.
- **Textura de reemplazo invisible** → el `PlaceholderTexture2D` se acompaña
  siempre de la silueta dibujada; la spec exige que se vea.
- **Doble producción de comida** (salida pasiva del tick más cosecha manual) →
  la fila de cosecha se mantiene pequeña y editable; si descompensa, se ajusta
  sin tocar código. Es una decisión de balance, no un defecto.
- **HUD que tapa el juego** → el HUD se ancla a los bordes con márgenes seguros y
  se revisa a 1280×720 y 1920×1080.
- **Panel desincronizado con el tick** → el panel se refresca en cada tick y
  vuelve a preguntar a `GameSim` si la acción es válida antes de ejecutarla.
- **Cables por encima del mapa** → el outpost usa su propia capa de dibujo por
  encima del render lunar; el orden se fija en `outpost.tscn`.
- **Botón de depuración visible en release** → se comprueba `OS.is_debug_build()`
  al crear el HUD, no al pulsar.

## Migration Plan

No hay datos persistidos ni partidas guardadas que migrar. La escena jugable es
la única que cambia de composición; el resto de escenas no se tocan. El cambio
se valida en su worktree con el checker en modo estricto y las escenas de humo,
y se integra en `features` por Pull Request como el resto de módulos.

## Open Questions

- Las posiciones definitivas de las estaciones llegarán con
  `base-and-craters`. Este cambio solo necesita que las actuales pasen el humo;
  moverlas después es editar `outpost.tscn`.
