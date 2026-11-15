# Tasks

## 1. Punto de partida

- [x] 1.1 Confirmar el worktree y la rama: `pwd` en `../MindSpace-worktrees/connect-playable-loop`, `git branch --show-current` = `connect-playable-loop`, árbol limpio y rama salida de `origin/features`. Ejecutar el checker como línea base. (≤ 30 min)
- [x] 1.2 Commitear los artefactos de planificación (`proposal.md`, `specs/`, `design.md`, `tasks.md`) en la rama del módulo antes de tocar `game/`. (≤ 15 min)

## 2. Refugio y exposición

- [x] 2.1 En `game/content/entities/astronaut/astronaut.gd`, poner `starts_outside` a `true` por defecto, añadir `_shelter_areas`, unificar `_on_zone_entered`/`_on_zone_exited` y `_on_game_reset` en `_apply_zone_state()` con la prioridad refugio > exterior, y añadir `set_input_locked(bool)` que corte movimiento e interacción. Comprobar con el checker. (≤ 1 h)
- [x] 2.2 En `game/scenes/base/base.gd`, quitar `GameSim.state.is_outside = true` y dejar que el refugio y el astronauta decidan el estado de zona. (≤ 20 min)
- [x] 2.3 En `game/content/outpost/outpost.tscn`, añadir un `Area2D` de capa 8, grupo `shelter_zones` y forma rectangular que cubra el recinto del outpost, y comprobar en una escena temporal que entrar y salir cambia `GameSim.state.is_outside`. (≤ 45 min)

## 3. Estaciones

- [x] 3.1 Crear `game/content/machines/machine_station.gd` (`extends MachineBase`) con `machine_id` exportado, `_draw()` de silueta con colores de la paleta, etiqueta con el nombre humanizado y `refresh_from_state()` que distinga sana, averiada y apagada. (≤ 1 h 30 min)
- [x] 3.2 Crear `game/content/machines/machine_station.tscn` con el script, un `Sprite2D` con `PlaceholderTexture2D`, la etiqueta y un `StaticBody2D` de colisión. Verificar que la silueta se ve en ejecución, no solo el hueco de textura. (≤ 45 min)
- [x] 3.3 Crear `game/content/outpost/outpost.tscn` con las ocho estaciones (la hidroponía con su estación de cultivo), la batería, el panel solar, el refugio y el `PowerGridController`; colocar las estaciones en anillo alrededor del spawn con separación suficiente para que cada una sea el objetivo más cercano en su puerto. (≤ 2 h)
- [x] 3.4 Crear `game/content/outpost/outpost.gd` con el arranque diferido de un frame, el aviso de desarrollo para ids duplicados o desconocidos (`SimState.MACHINE_IDS`), y el refresco tras `GameSim.game_reset`. (≤ 1 h)
- [x] 3.5 Instanciar el outpost en `game/scenes/base/base.tscn` y comprobar que la escena jugable arranca con ocho estaciones visibles y interactuables. (≤ 30 min)

## 4. Red eléctrica

- [x] 4.1 Cablear en `outpost.tscn` un cable `solar_array → battery_1` y siete cables `battery_1 → máquina` con `game/content/machines/power_cable/power_cable.tscn`, ajustando `endpoint_a`, `endpoint_b`, `port_offset` y `horizontal_first` de cada estación. (≤ 2 h)
- [x] 4.2 Verificar en una escena temporal que las nueve conexiones forman una sola red, que cada consumidora tiene camino hasta la batería y que quitar un cable deja a su máquina sin carga en el tick siguiente. (≤ 1 h)

## 5. Panel de máquina

- [x] 5.1 Crear `game/scripts/ui/ui_text.gd` (`class_name UiText`) con el nombre humanizado desde `display_name_key`, la etiqueta de una mejora (`effect_stat` + `delta`), la etiqueta de arquetipo de evento, la etiqueta de la causa del fin y el motivo de una acción deshabilitada en inglés. (≤ 1 h)
- [x] 5.2 Crear `game/scenes/ui/machine_panel/machine_panel.gd` y su `.tscn` con nombre, pista, salud, encendida/apagada, avería, progreso de reparación, mejoras aplicadas y una fila por mejora con su coste. Refrescar en `GameSim.tick_advanced`. (≤ 2 h)
- [x] 5.3 Conectar reparar y mejorar a `GameSim.start_repair()`/`GameSim.apply_upgrade()` usando `can_start_repair()`/`can_apply_upgrade()` para habilitar, y mostrar el motivo cuando estén deshabilitadas. (≤ 1 h 30 min)
- [x] 5.4 Crear `game/scenes/ui/machine_panel/machine_panel_controller.gd` que espere un frame, conecte `interaction_requested` de cada nodo en el grupo `interactables`, abra o cambie el panel, bloquee la entrada con `Astronaut.set_input_locked(true)` y cierre con `ui_cancel` o al terminar o reiniciar la partida. (≤ 1 h 30 min)

## 6. HUD y controles de tiempo

- [x] 6.1 Añadir a `game/project.godot` las acciones `speed_up` (`=`), `speed_down` (`-`), `pause` (`Space`) y `debug_end_run` (`F10`), sin pisar las existentes. (≤ 30 min)
- [x] 6.2 Crear `game/scenes/ui/game_hud/game_hud.gd` y su `.tscn` con energía, oxígeno, agua, comida, salud, radiación, hambre, sed, tick, sol y fase, refrescados en `tick_advanced`, `game_reset` y `game_over`. (≤ 2 h)
- [x] 6.3 Añadir al HUD los controles de velocidad y pausa con `focus_mode = NONE`, conectados a `GameSim.set_speed()` y `GameSim.set_paused()`, y deshabilitarlos cuando la partida termina. (≤ 1 h)
- [x] 6.4 Añadir el prompt de interacción desde `Astronaut.interaction_target_changed`, el banner de eventos activos con su procedencia y el aviso de comunicaciones cortadas. (≤ 1 h 30 min)
- [x] 6.5 Crear `game/scenes/ui/run_ui.tscn` y `.gd` como `CanvasLayer` que reúne HUD, panel de máquina y evaluación, e instanciarlo en `base.tscn`. (≤ 45 min)

## 7. Hidroponía

- [x] 7.1 Reescribir `game/content/machines/hydroponics/hydroponics_state.gd` como clase instanciable con doce celdas, progreso en ticks, intervalo determinista por hash de semilla, índice y tick de plantado, y API de plantar, retirar, cosechar y consultar etapa. (≤ 2 h)
- [x] 7.2 Añadir `game/databases/economy_rows/hydroponics_harvest_food.tres` y su entrada en `game/databases/economy.tres`, y una función en `game/scripts/autoloads/game_sim.gd` que añada un recurso acotado por su capacidad. (≤ 45 min)
- [x] 7.3 Crear `game/content/machines/hydroponics/hydroponics_station.gd` y `.tscn` (`extends MachineBase`) que instancie el estado, escuche `GameSim.tick_advanced`, avance solo con la máquina sana y encendida y exponga `extra_panel_scene`. (≤ 1 h 30 min)
- [x] 7.4 Crear `game/content/machines/hydroponics/panel/hydroponics_panel.gd` y su `.tscn` con la rejilla 3×4, las texturas de etapa existentes y las acciones plantar, cosechar y retirar, con el botón de volver al panel de máquina. (≤ 2 h)
- [x] 7.5 Añadir al panel de máquina el botón de abrir el panel extra cuando la estación lo declare. (≤ 45 min)
- [x] 7.6 Adaptar `game/content/machines/hydroponics/visual/growth_demo/growth_demo.gd` y `growth_interface/growth_interface.gd` a una instancia propia del estado que avanza por temporizador, sin `Time.get_ticks_msec()` ni `randf()`. (≤ 1 h 30 min)

## 8. Evaluación y fin forzado

- [x] 8.1 Añadir `GameSim.force_end_run()` en `game/scripts/autoloads/game_sim.gd`: sin efecto si la partida ya terminó, causa `debug`, un único hecho `GAME_OVER`, pausa y emisión de `game_over`. (≤ 1 h)
- [x] 8.2 Crear `game/scenes/evaluation/evaluation.gd` y su `.tscn` con los cinco contadores de `EventLog.get_summary()`, los recursos finales, la causa y las acciones de volver a jugar y volver al menú. (≤ 2 h)
- [x] 8.3 Conectar la evaluación a `GameSim.game_over` en `run_ui.gd`, añadir el botón de fin forzado solo con `OS.is_debug_build()` y enlazarlo a `GameSim.force_end_run()` y a la acción `debug_end_run`. (≤ 1 h)

## 9. Validación e integración

- [x] 9.1 Crear en `game/tests/` (ignorada por git) una escena de humo del outpost que compruebe estaciones presentes, celdas transitables y alcanzables, objetivo más cercano por estación y partición de red al cortar un cable. (≤ 2 h)
- [x] 9.2 Crear en `game/tests/` una escena de humo de hidroponía que compruebe determinismo con la misma semilla, pausa del crecimiento con la máquina averiada y tope de comida al cosechar con la reserva llena. (≤ 1 h 30 min)
- [x] 9.3 Revisar el HUD, el panel y la evaluación en ejecución a 1280×720 y 1920×1080, y comprobar que el prompt y el banner no tapan los recursos. (≤ 1 h)
- [x] 9.4 Ejecutar el checker en modo estricto (`check-gdscript.sh -p game --strict`) y la escena jugable en headless, sin `ERROR` ni `SCRIPT ERROR`. (≤ 45 min)
- [x] 9.5 Ejecutar `openspec validate connect-playable-loop --strict`, archivar el cambio con `openspec archive connect-playable-loop --yes`, commitear y subir la rama, y abrir el Pull Request contra `features`. (≤ 45 min) — validado y archivado en `openspec/changes/archive/2026-11-15-connect-playable-loop/`; el commit, el push y el PR los hace el agente `git`.
