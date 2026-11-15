# Tasks

## 1. Preparación del módulo

- [x] 1.1 Crear el worktree `../MindSpace-worktrees/playable-world` desde `features` actualizado y la rama `playable-world`; llevar `openspec/changes/integrate-playable-world/` al worktree y commitearlo en la rama del módulo antes de tocar `game/`. Verificar `pwd`, la rama y que el árbol queda limpio. (≤ 30 min) — Hecho por `git`: worktree `/home/ian/Documents/remote/github/MindSpace-worktrees/playable-world`, rama `playable-world`, commit `4c4f5c6`; árbol limpio.
- [x] 1.2 Confirmar que las rutas base existen y están limpias: `game/scenes/intro/intro.tscn`, `game/scenes/worlds/worlds.tscn`, `game/content/map/lunar/lunar_map_world.tscn`, `game/content/entities/astronaut/astronaut_4dir.png`, `game/scripts/autoloads/game_sim.gd` y `game/project.godot`. No tocar `game/tests/` más allá de los harnesses de este cambio. (≤ 15 min) — Verificado con `ls -l` en el worktree.

## 2. Input map

- [x] 2.1 Añadir a `game/project.godot` las acciones `move_left`, `move_right`, `move_up` y `move_down`, cada una con su tecla WASD y su flecha (`A`/`Left`, `D`/`Right`, `W`/`Up`, `S`/`Down`). Verificar con un script headless que `InputMap.has_action()` es verdadero para las cuatro y que el proyecto arranca sin errores. (≤ 45 min) — Hecho por build-input: 4 acciones con 2 eventos cada una, 16 PASS; boot headless sin `ERROR`; checker `checked=33 parse_errors=0 style_issues=0`.

## 3. Astronauta

- [x] 3.1 Crear `game/content/entities/astronaut/astronaut.gd` (`class_name Astronaut`, `extends CharacterBody2D`) con: `setup(map: LunarMap) -> void` para fijar el mapa y la posición en el centro del spawn; `move(direction: Vector2, delta: float) -> void` con velocidad `@export base_speed = 160.0` multiplicada por `GameSim.state.player.move_speed_multiplier`, movimiento por ejes, subpasos de 8 px y colisión por las cuatro esquinas de una caja de 12×12 contra `LunarMap.is_walkable` y los límites; orientación con frames 0=abajo, 1=arriba, 2=izquierda, 3=derecha; y guard `if GameSim.is_paused(): return` en `_physics_process`. (≤ 2 h)
- [x] 3.2 Crear `game/content/entities/astronaut/astronaut.tscn` con raíz `CharacterBody2D` (script de 3.1), `Sprite2D` con `astronaut_4dir.png` y `hframes = 4`, `CollisionShape2D` rectangular de 12×12 px y `Camera2D` hija con `position_smoothing_enabled = false` y `zoom = Vector2(1, 1)`. Verificar que la escena carga en headless sin errores. (≤ 45 min)
- [x] 3.3 Verificar el astronauta aislado con un script headless temporal en `game/tests/` (ignorado por Git): mapa sintético 16×16 todo transitable, spawn en el centro; 1 s a la derecha = 160 px; diagonal con la misma velocidad; una celda `ROCK` bloquea el avance; el borde del mapa detiene; el frame cambia con la dirección y se conserva al parar. Borrar el script temporal al terminar. (≤ 1 h)

## 4. Escena jugable

- [x] 4.1 Crear `game/scenes/base/base.gd` (`extends Node2D`) y `game/scenes/base/base.tscn` con la instancia de `res://content/map/lunar/lunar_map_world.tscn` y la instancia de `res://content/entities/astronaut/astronaut.tscn`. En `_ready`: obtener el `LunarMap` con `LunarMapWorld.get_map()`, llamar a `Astronaut.setup(map)`, fijar `limit_left/top/right/bottom` de la cámara a `0, 0, world_size.x, world_size.y`, hacer current la cámara del astronauta, llamar a `GameSim.start_run()`, marcar `GameSim.state.is_outside = true` y arrancar el reloj. En `_exit_tree`: `GameSim.stop_run()`. Si el mapa es nulo, avisar y no arrancar la partida. (≤ 2 h)
- [x] 4.2 Verificar en headless que `base.tscn` se instancia, que el astronauta está en el centro del tile de spawn, que la cámara del astronauta es la current, que la partida empieza en tick 0 con el ledger vacío y que `is_outside` es verdadero. (≤ 45 min)

## 5. Ciclo de partida en GameSim

- [x] 5.1 Modificar `game/scripts/autoloads/game_sim.gd`: `paused` por defecto en `true`; añadir `start_run()` (`new_game()` y `paused = false`) y `stop_run()` (`paused = true` y `state.is_outside = false`); en `advance_tick()`, tras emitir `GAME_OVER`, poner `paused = true`. No cambiar la semántica de `new_game()`. Ejecutar `clock_check`, `tick_check`, `full_run_check` y `machines_api_check` para confirmar que no hay regresiones. (≤ 1 h 30 min)

## 6. Transición desde la introducción

- [x] 6.1 Modificar `game/scenes/intro/intro.gd`: constante `GAME_SCENE = "res://scenes/base/base.tscn"`, guard `_starting`, `GameSim.set_paused(true)` en `_ready`, y en `_on_accept_pressed()` deshabilitar el botón, mantener el texto de confirmación, esperar 0.8 s y cambiar de escena; si la escena no existe, avisar y rehabilitar el botón. Ignorar `_go_back()` y la tecla de cancelar mientras `_starting` es verdadero. Ejecutar `intro_skip_check` e `intro_default_check`. (≤ 1 h)

## 7. Verificación headless

- [x] 7.1 Crear `game/tests/playable_world_check.gd` (SceneTree) con: movimiento del astronauta sobre un mapa sintético (recto, diagonal, roca, borde, orientación); integración de `base.tscn` (spawn, cámara current, tick 0, ledger vacío, `is_outside`); un tick avanza la dosis y registra hechos; una muerte forzada deja `game_over` y `paused`; al descargar la escena, `stop_run()` deja el reloj pausado y `is_outside` desactivado. Ejecutarlo con `godot --headless --path game --script res://tests/playable_world_check.gd` y exigir exit 0. (≤ 2 h)
- [x] 7.2 Crear `game/tests/playable_flow_check.gd` (SceneTree): instanciar `scenes/intro/intro.tscn`, llamar a `_on_accept_pressed()`, esperar el cambio de escena y comprobar que la escena actual es `base.tscn` con tick 0 y ledger vacío. Si el cambio de escena headless resulta inestable, dejar constancia en el informe y verificar la transición en el playtest manual de 8.4. Ejecutarlo con `godot --headless --path game --script res://tests/playable_flow_check.gd`. (≤ 1 h 30 min)

## 8. Verificación final

- [x] 8.1 Ejecutar `bash ~/.config/opencode/skills/godot/scripts/check-gdscript.sh -p game --strict` y corregir todos los errores y warnings de tipado. (≤ 30 min)
- [x] 8.2 Ejecutar `godot --headless --path game --quit` y comprobar que no aparecen `ERROR` ni `SCRIPT ERROR`. (≤ 15 min)
- [x] 8.3 Ejecutar la regresión existente que pueda verse afectada: `clock_check`, `tick_check`, `full_run_check`, `machines_api_check`, `machines_smoke`, `intro_skip_check`, `intro_default_check`, `worlds_form_check`, `world_store_check` y los harnesses de `lunar_map_*`; exigir exit 0 en todos. (≤ 1 h)
- [x] 8.4 Playtest manual con el proyecto abierto desde el worktree: menú → mundo → saltar intro → aceptar → mapa; mover al astronauta con WASD y flechas en las ocho direcciones, comprobar colisión con rocas y límites, seguimiento y clamp de cámara. Sacar una captura del mapa con el astronauta visible y adjuntarla al informe. (≤ 1 h)

## 9. Cierre

- [x] 9.1 Ejecutar `openspec validate integrate-playable-world --strict` y corregir lo que reporte. (≤ 15 min)
- [x] 9.2 Actualizar este `tasks.md` con la evidencia de cada tarea, revisar `git status`/`git diff` para confirmar que solo cambian archivos del módulo, commitear en `playable-world` y abrir Pull Request hacia `features`. Archivar el cambio OpenSpec tras la integración. (≤ 30 min)

## Evidencia de la implementación

| Tarea | Evidencia |
| --- | --- |
| 1.1 | Worktree `../MindSpace-worktrees/playable-world`, rama `playable-world`, commit `4c4f5c6`; árbol limpio. |
| 1.2 | Rutas base verificadas con `ls -l` en el worktree. |
| 2.1 | `game/project.godot`: 4 acciones con 2 eventos; comprobación temporal 16 PASS; boot sin `ERROR`; checker `checked=33 parse_errors=0 style_issues=0`. |
| 3.1 | `astronaut.gd` con `setup`/`move`, caja 12×12, subpasos de 8 px y frames 0–3; checker `checked=34 parse_errors=0 style_issues=0`. |
| 3.2 | `astronaut.tscn` con `Sprite2D` (`hframes=4`), `CollisionShape2D` 12×12 y `Camera2D`; `ResourceLoader` OK. |
| 3.3 | Harness temporal 37 asserts: 160 px recto/diagonal, `ROCK`, bordes y frames; borrado al terminar. |
| 4.1 | `base.tscn` con `LunarMapWorld` + `Astronaut`; `base.gd` hace spawn, límites de cámara, `start_run`, `is_outside` y `stop_run` al salir. |
| 4.2 | `base_scene_check_tmp` 12 PASS: mapa, spawn, cámara current, tick 0, ledger vacío, fuera y parada al salir. |
| 5.1 | `paused=true`, `start_run`/`stop_run` y auto-pausa en `GAME_OVER`; `clock_check` 32, `full_run_check` 18, `machines_api_check` 104, lifecycle 13; `tick_check` reparado 106. |
| 6.1 | `intro.gd` con `GAME_SCENE`, guard `_starting`, espera de 0.8 s y `GameSim.set_paused(true)`; `intro_skip_check` e `intro_default_check` OK. |
| 7.1 | `playable_world_check.gd`: 53 checks, 0 failures. |
| 7.2 | `playable_flow_check.gd`: 15 checks, 0 failed; 3 ejecuciones consecutivas. |
| 8.1 | Checker estricto `checked=35 parse_errors=0 style_issues=0`. |
| 8.2 | Boot headless sin `ERROR` ni `SCRIPT ERROR`. |
| 8.3 | 21 harnesses exit 0; `tick_check` 106 y `empty_economy_check` 37 reparados, con copia actualizada en la raíz. |
| 8.4 | Captura real Xvfb 850×480 en `/tmp/opencode/playable-world-capture.png`; `06-map-before`/`07-map-after` muestran movimiento y seguimiento de cámara. |
| 9.1 | `openspec validate integrate-playable-world --strict` → `Change 'integrate-playable-world' is valid`. |
| 9.2 | Evidencia actualizada y `git status`/`git diff` revisados (solo rutas del módulo y `tasks.md`); commit/PR/archivo pendientes de confirmación. |
