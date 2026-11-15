# Tasks

## 1. Integración con el tick actual

- [x] 1.1 Rebasear `events` sobre `features` y resolver los conflictos de `game/scripts/autoloads/game_sim.gd` y `game/scripts/simulation/sim_tick.gd`, conservando el registro de máquinas y añadiendo el de eventos.
- [x] 1.2 Fijar el orden del tick en producción → consumo → degradación → trabajos de máquina → eventos → consecuencias → muerte → calendario en `game/scripts/simulation/sim_tick.gd`.
- [x] 1.3 Actualizar la firma a `step(state, economy, machines, events)` y la llamada de `GameSim` en `game/scripts/autoloads/game_sim.gd`.

## 2. Estado y ciclo de vida

- [x] 2.1 Añadir `active_event.gd` y `pending_event.gd` con el tick real de inicio y el tick mínimo de la cola.
- [x] 2.2 Añadir a `sim_state.gd` el cursor, los activos, la cola, el flag de comunicaciones y la semilla; limpiarlos en `reset_from_economy`.
- [x] 2.3 Implementar la expiración, el encolado por ventana y el arranque con solape mutuo en `sim_tick.gd`.
- [x] 2.4 Emitir `EVENT_STARTED` y `EVENT_ENDED` y ampliar `log_entry.gd` con esos tipos.

## 3. Efectos

- [x] 3.1 Implementar la avería con clamp de salud, apagado y hecho `MACHINE_BREAKDOWN` al cruzar cero.
- [x] 3.2 Implementar caída de producción y pico de consumo como resta neta del recurso objetivo, sin bajar de cero.
- [x] 3.3 Implementar la radiación solo en el exterior y el corte de comunicaciones como flag sin efecto numérico.

## 4. Integración, modo degradado y validación

- [x] 4.1 Cargar `events.tres` en `GameSim` y dejar la partida sin eventos, con advertencia, si falta o es inválido.
- [x] 4.2 Rechazar en `event_data.gd` las ventanas que terminan después de los 300 ticks de misión y añadir el caso sintético en `events_check.gd`.
- [x] 4.3 Añadir `events_runtime_check.gd` con el registro de máquinas real y las comprobaciones de ciclo de vida, cola, efectos, determinismo y reinicio.
- [x] 4.4 Actualizar `game/resources/events/README.md` con el scheduler, la tabla de efectos y el comando del checker de runtime.

## 5. Verificación

- [x] 5.1 `godot --headless --path game --script res://scripts/dev/events_check.gd` → 121 checks, OK.
- [x] 5.2 `godot --headless --path game --script res://scripts/dev/events_runtime_check.gd` → 27 checks, OK.
- [x] 5.3 `godot --headless --path game --script res://scripts/dev/sim_smoke.gd` → 88 checks, OK.
- [x] 5.4 `godot --headless --path game --script res://scripts/dev/machines_smoke.gd` → 348 checks, 0 fallos.
- [x] 5.5 `godot --headless --path game --script res://content/map/lunar/lunar_map_render_smoke.gd` → 62 checks, 0 fallos.
- [x] 5.6 `check-gdscript.sh -p game --strict` → 39 archivos, 0 errores, 0 avisos.
- [x] 5.7 `godot --headless --path game --quit` → arranque sin `ERROR` ni `SCRIPT ERROR`.
- [x] 5.8 `openspec validate add-events-scheduler --strict` y archivado del cambio con sincronización de `openspec/specs/events/spec.md`.
