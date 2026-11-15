# Tasks

## 1. Recuperación del blackout

- [x] 1.1 Añadir en `game/scripts/simulation/sim_tick.gd` una función `_restore_machines()` que, cuando `network.total_charge(state) > 0.0`, encienda hasta `blackout_steps_per_tick` máquinas apagadas en orden inverso a `SimState.BLACKOUT_ORDER`, saltando las averiadas, y llamarla desde `_apply_energy_consequences()`. Verificar con el checker estricto y una prueba temporal de que el O₂ se enciende primero.
- [x] 1.2 Añadir a `game/scripts/dev/sim_smoke.gd` el check `_check_blackout_recovery`: forzar batería a 0 y comprobar el apagado; devolver carga y comprobar el encendido gradual en orden inverso, una máquina por tick, y que una máquina averiada no se enciende. Ejecutar `sim_smoke` y exigir 0 fallos.

## 2. Balance y victoria real

- [x] 2.1 Subir `game/databases/economy_rows/solar_output_per_tick.tres` a 4.0 y `game/databases/economy_rows/capacity_energy.tres` a 26.0; bajar `game/databases/economy_rows/hunger_drain_per_tick.tres` y `thirst_drain_per_tick.tres` a 0.3. Ejecutar un diagnóstico headless temporal de 300 ticks con la economía real (sin eventos) y comprobar que el run llega vivo al tick 300 con hambre y sed por encima de 0; borrar el temporal.
- [x] 2.2 Cambiar `_check_300_ticks` en `game/scripts/dev/sim_smoke.gd` para exigir `VICTORY` con la economía real (sin eventos). Ejecutar `sim_smoke` y `machines_smoke`; exigir exit 0 y 0 fallos en ambos.

## 3. Verificación e integración

- [x] 3.1 Ejecutar `sim_smoke`, `machines_smoke`, `events_check` y `events_runtime_check`; exigir exit 0. Ejecutar `check-gdscript.sh -p game --strict` y `godot --headless --path game --quit` sin `ERROR` ni `SCRIPT ERROR`. Ejecutar el diagnóstico pasivo con eventos y reportar si llega al tick 300 o si exige reparaciones.
- [x] 3.2 Ejecutar `openspec validate fix-energy-recovery --strict` y revisar `git status` para confirmar que no quedan temporales ni `game/tests/` con archivos.

## Workflow follow-up

- Archivar `add-mission-victory` antes de `fix-energy-recovery` (el segundo depende del primero).
- Archivar `fix-energy-recovery` en el commit que cierre el trabajo.
- Abrir el PR de la rama `win-condition` contra `features`.
