# Tasks

## 1. Reloj y multiplicadores

- [x] 1.1 Añadir `X100`, `X1000` y `X10000` al enum `GameSim.Speed`, devolver 100.0/1000.0/10000.0 en `get_rate()` y subir `MAX_TICKS_PER_FRAME` a 400 en `game/scripts/autoloads/game_sim.gd`. Verificar con `clock_check` que las tasas son correctas y que el cap de un frame es 400.
- [x] 1.2 Añadir `x100`, `x1000` y `x10000` a `_speed_text()` y encadenar los seis valores en `_step_speed()` de `game/scenes/ui/hud.gd`. Verificar que subir desde x10 llega a x100 y que en x10000 subir no cambia el valor.

## 2. Presentación en el HUD

- [x] 2.1 Ensanchar `ClockLabel.offset_left` a 690 y `SpeedValue.custom_minimum_size.x` a 40 en `game/scenes/ui/hud.tscn`. Verificar con una captura a 850×480 en x10000 que el reloj y el marcador muestran `x10000` sin recortes ni solapamientos.

## 3. Verificación y cierre

- [x] 3.1 Actualizar `game/tests/clock_check.gd` (ignorado) para las seis velocidades, el cap de 400 y las 55 filas de economía; ejecutarlo y exigir exit 0. Ejecutar `check-gdscript.sh -p game --strict` y `godot --headless --path game --quit` sin errores.
- [x] 3.2 Ejecutar `openspec validate add-high-speed-multipliers --strict`, archivar el cambio, revisar `git status` y commitear en `win-condition`.

## Workflow follow-up

- Commit con el código y el cambio archivado.
- Mantener el checkout principal en `win-condition` para la prueba del usuario.
