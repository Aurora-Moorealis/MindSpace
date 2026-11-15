# Tasks

## 1. HUD único de barras

- [x] 1.1 Eliminar `game/scenes/ui/game_hud/` (escena, script y `.uid`).
- [x] 1.2 Añadir al HUD de barras el prompt de interacción (`Prompt`, `PromptLabel`) y enlazarlo a `Astronaut.interaction_target_changed`, reevaluando visibilidad cada frame.
- [x] 1.3 Añadir los controles de tiempo (`PauseButton`, `SpeedDownButton`, `SpeedUpButton`, `SpeedValue`) y sincronizarlos con `GameSim`.
- [x] 1.4 Deshabilitar los controles de tiempo con la partida terminada y mantener las teclas `pause`/`speed_up`/`speed_down`.
- [x] 1.5 `run_ui.gd`: enganchar el astronauta al HUD con `bind_astronaut`.
- [x] 1.6 `evaluation.gd`: declarar `class_name Evaluation` y tipar el campo de `run_ui`.

## 2. Contenido de items

- [x] 2.1 Mover los tres `.tres` de `game/resources/items/` a `game/content/items/<id>/`.
- [x] 2.2 Mover los tres PNG y sus `.import` de `game/assets/images/items/` a la misma carpeta.
- [x] 2.3 Actualizar las rutas de icono de los `.tres` y comprobar que cargan.

## 3. Estación de hidroponía

- [x] 3.1 Montar `hydroponics_rack.png` en el `Sprite2D` de la estación y quitar el placeholder.
- [x] 3.2 Dibujar solo el puerto de cable en `HydroponicsStation._draw()`.
- [x] 3.3 Permitir retirar celdas maduras en `HydroponicsState.remove()` y ajustar panel y demo (QUITAR).
- [x] 3.4 Recrear el estado de cultivo con la semilla de la partida en `game_reset`.

## 4. Regresión

- [x] 4.1 Actualizar la aserción de filas de `machines_smoke` a 54 y comprobar que la suite pasa.

## 5. Verificación y cierre

- [x] 5.1 Pasar `check-gdscript.sh -p game --strict`.
- [x] 5.2 Pasar `sim_smoke`, `machines_smoke`, `events_check` y `events_runtime_check`.
- [x] 5.3 Arrancar `res://scenes/base/base.tscn` en headless sin errores.
- [x] 5.4 Capturas a 1280×720 y 850×480 con prompt, controles y rack.
- [x] 5.5 `openspec validate --specs --strict` y archivar este cambio.
